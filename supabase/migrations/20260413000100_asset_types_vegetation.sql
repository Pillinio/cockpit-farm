-- Migration: Asset type expansion + vegetation tracking
-- Combines asset_type CHECK update, camp_vegetation, grass_species, and RPC

-- ============================================================
-- Part 1: Expand asset_type CHECK constraint on farm_assets
-- ============================================================
alter table farm_assets
  drop constraint if exists farm_assets_asset_type_check;

alter table farm_assets
  add constraint farm_assets_asset_type_check
  check (asset_type in (
    'borehole', 'dam', 'fence', 'vehicle', 'rain_station',
    'windmill', 'trough', 'house', 'hunting_blind', 'other'
  ));

-- ============================================================
-- Part 2: Camp vegetation tracking
-- ============================================================
create table camp_vegetation (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms(id) default default_farm_id(),
  camp_name text not null,
  observation_date date not null,
  -- Ampel assessment (grün/gelb/rot)
  grass_condition text not null check (grass_condition in ('green', 'yellow', 'red')),
  -- Dominant grass types
  dominant_species text[], -- e.g. ARRAY['Anthephora pubescens', 'Schmidtia pappophoroides']
  -- Grass composition
  perennial_pct integer check (perennial_pct between 0 and 100),
  bare_soil_pct integer check (bare_soil_pct between 0 and 100),
  -- Qualitative assessment
  bush_encroachment text check (bush_encroachment in ('none', 'light', 'moderate', 'heavy')),
  grazing_pressure text check (grazing_pressure in ('low', 'moderate', 'high', 'overutilized')),
  -- Notes and photos
  notes text,
  photos_ref jsonb,
  observed_by uuid references auth.users(id),
  created_at timestamptz default now(),
  unique(farm_id, camp_name, observation_date)
);

alter table camp_vegetation enable row level security;

-- ============================================================
-- Part 3: RPC function for assets with coordinates
-- ============================================================
create or replace function get_farm_assets_with_coords()
returns json language sql security definer as $$
  select coalesce(json_agg(row_to_json(t)), '[]'::json)
  from (
    select name, asset_type,
           extensions.ST_X(location) as lng,
           extensions.ST_Y(location) as lat,
           metadata, active
    from farm_assets
    where active = true and location is not null
  ) t;
$$;

-- ============================================================
-- Part 4: RLS policies for camp_vegetation
-- ============================================================
create policy "farm_read" on camp_vegetation
  for select to authenticated
  using (farm_id = (select farm_id from profiles where id = auth.uid()));

create policy "farm_insert" on camp_vegetation
  for insert to authenticated
  with check (farm_id = (select farm_id from profiles where id = auth.uid()));

create policy "farm_update" on camp_vegetation
  for update to authenticated
  using (farm_id = (select farm_id from profiles where id = auth.uid()))
  with check (farm_id = (select farm_id from profiles where id = auth.uid()));

-- ============================================================
-- Part 5: Reference grass species for Erichsfelde
-- ============================================================
create table grass_species (
  id uuid primary key default gen_random_uuid(),
  scientific_name text not null unique,
  common_name text,
  category text not null check (category in ('valuable', 'supporting', 'warning', 'annual')),
  is_perennial boolean not null,
  palatability text check (palatability in ('high', 'medium', 'low')),
  drought_tolerance text check (drought_tolerance in ('high', 'medium', 'low')),
  notes text
);

-- Seed key species for Central Namibia (from Rinderfarm-Gräser-Guide)
insert into grass_species (scientific_name, common_name, category, is_perennial, palatability, drought_tolerance, notes) values
  ('Anthephora pubescens',      'Wool Grass / Wolsgras',    'valuable',   true,  'high',   'medium', 'Schlüsselgras für gute Weide, empfindlich gegen Übernutzung'),
  ('Schmidtia pappophoroides',  'Sand Quick / Sandkweek',   'valuable',   true,  'high',   'high',   'Wertvolles Dauergras, gute Trockenheitstoleranz'),
  ('Urochloa nigropedata',      NULL,                        'valuable',   true,  'high',   'medium', 'Hochwertiges Futtergras, Indikator guter Weidequalität'),
  ('Cenchrus ciliaris',         'Buffelgras',                'valuable',   true,  'high',   'high',   'Standortabhängig wertvoll, gute Erholung'),
  ('Stipagrostis uniplumis',    'Silky Bushman Grass',       'supporting', true,  'medium', 'high',   'Tragendes Trockenheitsgras'),
  ('Stipagrostis obtusa',       NULL,                        'supporting', true,  'medium', 'high',   'Robustes Trockenheitsgras, stabile Bodenbedeckung'),
  ('Eragrostis rigidior',       NULL,                        'supporting', true,  'medium', 'medium', 'Funktionales Dauergras'),
  ('Aristida congesta',         'Steekgras',                 'warning',    false, 'low',    'medium', 'Kurzlebig, Degradationszeiger bei Dominanz'),
  ('Enneapogon cenchroides',    NULL,                        'warning',    false, 'low',    'medium', 'Annual, Pioniergras auf gestörten Flächen'),
  ('Tragus berteronianus',      'Carrot Seed Grass',         'warning',    false, 'low',    'low',    'Degradationszeiger, geringe Futterqualität'),
  ('Chloris virgata',           'Feather Top Rhodes',        'annual',     false, 'medium', 'low',    'Kurzfristiges Futter nach gutem Regen'),
  ('Urochloa trichopus',       NULL,                        'annual',     false, 'medium', 'low',    'Annual mit kurzzeitigem Futterwert');
