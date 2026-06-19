-- SECURITY FIX: profiles role/farm_id self-elevation
--
-- Befund (live verifiziert 2026-06-19): die in Produktion aktive own_update-Policy
-- lautete `USING (id = auth.uid()) WITH CHECK (id = auth.uid())` und erlaubte damit
-- das Ändern JEDER Spalte der eigenen Zeile — inkl. `role`. Ein eingeloggter Manager
-- konnte sich per direktem API-Call selbst zum Owner machen:
--   update profiles set role = 'owner' where id = auth.uid();
-- Die frühere Schutz-Migration (20260514000100) war nie auf die Produktions-DB
-- angewendet worden (der Deploy-Pipeline rollt nur statische Dateien aus, keine
-- Supabase-Migrationen).
--
-- Robuste Lösung per BEFORE-UPDATE-Trigger statt nur RLS-WITH-CHECK:
--   - vergleicht OLD vs NEW direkt (kein fragiles self-referential Subquery)
--   - nur ein eingeloggter Owner darf role/farm_id ändern
--   - service_role / Superuser / Cron (auth.uid() IS NULL) bleiben unberührt,
--     damit Seed- und Admin-Skripte weiter funktionieren
-- Zusätzlich werden die RLS-Policies an den beabsichtigten Stand angeglichen.

-- 1) RLS-Policies: Self-Update der eigenen Zeile + Owner darf beliebige Zeilen
drop policy if exists "own_update" on profiles;
create policy "own_update" on profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "owner_update_any" on profiles;
create policy "owner_update_any" on profiles for update to authenticated
  using (auth_role() = 'owner')
  with check (auth_role() = 'owner');

-- 2) Trigger-Guard gegen Selbst-Eskalation (Kern des Fixes)
create or replace function prevent_profile_role_elevation()
returns trigger language plpgsql security definer
set search_path = public, extensions as $$
begin
  if (new.role is distinct from old.role
      or new.farm_id is distinct from old.farm_id) then
    -- Nur echte End-User (JWT vorhanden) und nicht-Owner werden blockiert.
    -- service_role / Superuser / Cron haben kein auth.uid() -> erlaubt.
    if auth.uid() is not null and coalesce(auth_role(), '') <> 'owner' then
      raise exception 'Nur Owner dürfen role oder farm_id ändern (versuchte Rechte-Eskalation blockiert).'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_profile_role_elevation on profiles;
create trigger trg_prevent_profile_role_elevation
  before update on profiles
  for each row execute function prevent_profile_role_elevation();
