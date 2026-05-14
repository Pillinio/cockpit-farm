-- Fix: kein Trigger erzeugt profiles-Zeile beim auth.users-Insert.
--
-- Vorher: admin.html invitiert per signInWithOtp({options:{data:{role}}}),
-- role landet in auth.users.raw_user_meta_data. Es gibt aber keinen Trigger,
-- der eine profiles-Zeile erzeugt — sodass RLS für den neuen User komplett
-- fehlschlägt (auth_role() / auth_farm_id() liefern null).
--
-- Fix: Trigger auf auth.users INSERT, der eine profiles-Zeile mit Rolle aus
-- raw_user_meta_data anlegt. Whitelist gegen Privilege-Escalation via
-- self-crafted Metadata.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_role text;
  v_display_name text;
begin
  v_role := coalesce(new.raw_user_meta_data->>'role', 'viewer');
  if v_role not in ('owner', 'manager', 'viewer') then
    v_role := 'viewer';
  end if;

  v_display_name := coalesce(
    new.raw_user_meta_data->>'display_name',
    split_part(new.email, '@', 1)
  );

  insert into public.profiles (id, role, display_name)
    values (new.id, v_role, v_display_name)
    on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill: profiles-Zeile für jeden bereits existierenden auth.users-User
-- erzeugen, der noch keine hat. Defensive default role = 'viewer'; Owner
-- kann via admin.html nachträglich Rollen anpassen.
insert into public.profiles (id, role, display_name)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'role', 'viewer'),
  coalesce(u.raw_user_meta_data->>'display_name', split_part(u.email, '@', 1))
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;
