-- Seasonal forecast storage (ensemble percentiles per month)
create table seasonal_forecasts (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms(id) default default_farm_id(),
  forecast_date date not null,        -- when the forecast was issued
  target_month date not null,         -- which month is forecasted (first day of month)
  variable text not null check (variable in ('precipitation_mm', 'temperature_c')),
  p5 numeric,
  p25 numeric,
  p50 numeric,   -- median
  p75 numeric,
  p95 numeric,
  climatology_mean numeric,           -- long-term average for this month
  anomaly_pct numeric,                -- median vs climatology as percentage
  outlook text check (outlook in ('well_below', 'below', 'normal', 'above', 'well_above')),
  model text default 'ecmwf-seas5',
  created_at timestamptz default now(),
  unique(farm_id, forecast_date, target_month, variable)
);

alter table seasonal_forecasts enable row level security;
create policy "authenticated_read" on seasonal_forecasts for select to authenticated using (true);
create policy "service_write" on seasonal_forecasts for insert to service_role with check (true);
create policy "service_update" on seasonal_forecasts for update to service_role using (true);
