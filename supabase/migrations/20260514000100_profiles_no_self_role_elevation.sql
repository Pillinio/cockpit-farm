-- Fix: profiles self-elevation via own_update policy
--
-- Vorher: own_update auf profiles erlaubte UPDATE jeder Spalte (inkl. role + farm_id)
-- solange id = auth.uid(). Damit konnte sich jeder authentifizierte User selbst
-- zum 'owner' machen:
--   update profiles set role = 'owner' where id = auth.uid();
--
-- Fix in zwei Policies:
--   1. own_update (Self) — id muss eigene sein, role + farm_id müssen unverändert
--      bleiben. Erlaubt das eigene display_name-Update.
--   2. owner_update_any — Owner darf beliebige Profile updaten (für admin.html
--      Rollen-Management). RLS-Engine ODER-kombiniert beide Policies, also greift
--      die least-restriktive — der Owner hat damit weiterhin volle Kontrolle.

drop policy if exists "own_update" on profiles;

create policy "own_update" on profiles for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role    = (select role    from profiles where id = auth.uid())
    and farm_id = (select farm_id from profiles where id = auth.uid())
  );

create policy "owner_update_any" on profiles for update to authenticated
  using (auth_role() = 'owner')
  with check (auth_role() = 'owner');
