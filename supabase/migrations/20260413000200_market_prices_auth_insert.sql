-- Allow authenticated users to insert/update/delete market_prices
-- (market_prices is global reference data, managed by farm owners via admin UI)
create policy "authenticated_insert" on market_prices
  for insert to authenticated with check (true);

create policy "authenticated_update" on market_prices
  for update to authenticated using (true) with check (true);

create policy "authenticated_delete" on market_prices
  for delete to authenticated using (true);
