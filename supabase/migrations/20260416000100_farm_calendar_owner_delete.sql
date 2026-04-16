-- Owners (admins) can delete/update any farm_calendar entry regardless of farm_id.
-- Prior policy also required matching farm_id, which silently blocked deletes when
-- an owner tried to delete entries whose farm_id was NULL or had drifted.

drop policy if exists "farm_delete" on farm_calendar;
create policy "farm_delete" on farm_calendar for delete to authenticated
  using (
    (select role from profiles where id = auth.uid()) = 'owner'
    or (
      farm_id = (select farm_id from profiles where id = auth.uid())
      and requested_by = auth.uid()
      and status = 'requested'
    )
  );

drop policy if exists "farm_update" on farm_calendar;
create policy "farm_update" on farm_calendar for update to authenticated
  using (
    (select role from profiles where id = auth.uid()) = 'owner'
    or (
      farm_id = (select farm_id from profiles where id = auth.uid())
      and requested_by = auth.uid()
      and status = 'requested'
    )
  );
