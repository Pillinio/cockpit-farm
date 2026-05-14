-- Verifies: profiles.own_update darf role + farm_id NICHT verändern,
-- selbst wenn der User seine eigene Zeile updated.
--
-- Erwartet:
--   1. Viewer ändert display_name in eigener Zeile  → OK
--   2. Viewer setzt role = 'owner' in eigener Zeile → RLS-Verstoß (with check)
--   3. Viewer setzt farm_id auf fremde Farm         → RLS-Verstoß (with check)
--   4. Owner ändert role eines anderen Users        → OK (owner_update_any)

begin;

do $$
declare
  v_owner uuid   := gen_random_uuid();
  v_viewer uuid  := gen_random_uuid();
  v_farm uuid;
  v_other_farm uuid := gen_random_uuid();
  v_rows int;
begin
  -- Setup: brauchen einen Owner und einen Viewer in derselben Farm
  select id into v_farm from farms where name = 'Erichsfelde' limit 1;
  if v_farm is null then
    raise exception 'Test prerequisite: Erichsfelde farm not seeded';
  end if;

  -- Profile direkt anlegen (mit service-role-Rechten innerhalb DO-Block)
  insert into profiles (id, farm_id, role, display_name)
    values (v_owner,  v_farm, 'owner',  'Test Owner'),
           (v_viewer, v_farm, 'viewer', 'Test Viewer');

  -- ── Scenario 1: Viewer updated eigenen display_name → muss erfolgreich sein
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_viewer::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  update profiles set display_name = 'Renamed' where id = v_viewer;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'FAIL Scenario 1: viewer self-rename should affect 1 row, got %', v_rows;
  end if;

  -- ── Scenario 2: Viewer versucht role-Escalation → 0 Zeilen (RLS blockt)
  update profiles set role = 'owner' where id = v_viewer;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'CRITICAL FAIL Scenario 2: self-elevation succeeded (% rows)', v_rows;
  end if;

  -- Sicherstellen dass role wirklich nicht geändert ist (RLS-Read greift)
  reset role;
  perform set_config('request.jwt.claims', null, true);

  if (select role from profiles where id = v_viewer) <> 'viewer' then
    raise exception 'CRITICAL FAIL Scenario 2: role tatsächlich verändert!';
  end if;

  -- ── Scenario 3: Viewer versucht farm_id-Tausch → 0 Zeilen
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_viewer::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  update profiles set farm_id = v_other_farm where id = v_viewer;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL Scenario 3: farm_id swap allowed (% rows)', v_rows;
  end if;

  -- ── Scenario 4: Owner promoted Viewer → 1 Zeile (owner_update_any)
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  update profiles set role = 'manager' where id = v_viewer;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'FAIL Scenario 4: owner cannot update other profile (% rows)', v_rows;
  end if;

  raise notice 'PASS: profiles_no_self_role_elevation (4/4 scenarios)';
end;
$$;

rollback;
