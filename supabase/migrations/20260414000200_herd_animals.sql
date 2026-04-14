-- Individual animal tracking + weight gain configuration
-- Enables herd value estimation between weighings

CREATE TABLE herd_animals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  animal_id text NOT NULL,          -- e.g. "24-524"
  sex text NOT NULL CHECK (sex IN ('M', 'F')),
  sire text,                         -- father ID
  dam text,                          -- mother ID
  traceability_no text,
  birth_date date,
  last_weigh_date date,
  last_weight_kg numeric,
  calvings integer DEFAULT 0,
  active boolean DEFAULT true,       -- false = sold/dead
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(farm_id, animal_id)
);

ALTER TABLE herd_animals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON herd_animals FOR SELECT TO authenticated
  USING (farm_id = auth_farm_id());
CREATE POLICY "farm_insert" ON herd_animals FOR INSERT TO authenticated
  WITH CHECK (farm_id = auth_farm_id());
CREATE POLICY "farm_update" ON herd_animals FOR UPDATE TO authenticated
  USING (farm_id = auth_farm_id());

-- Daily weight gain assumptions per age/sex category
CREATE TABLE weight_gain_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  category text NOT NULL,  -- 'calf_0_6', 'young_6_18', 'heifer_18plus', 'cow_adult', 'ox_fattening', 'bull_young'
  daily_gain_kg numeric NOT NULL,
  description text,
  UNIQUE(farm_id, category)
);

ALTER TABLE weight_gain_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON weight_gain_config FOR SELECT TO authenticated
  USING (farm_id = auth_farm_id());
CREATE POLICY "farm_all" ON weight_gain_config FOR ALL TO service_role USING (true);

-- Seed default weight gain rates for Namibian cattle
INSERT INTO weight_gain_config (category, daily_gain_kg, description) VALUES
  ('calf_0_6',      0.70, 'Kalb 0-6 Monate'),
  ('young_6_18',    0.50, 'Jungrind 6-18 Monate'),
  ('heifer_18plus', 0.30, 'Faerse 18+ Monate'),
  ('cow_adult',     0.00, 'Kuh adult (stabil)'),
  ('ox_fattening',  0.40, 'Ochse Mast'),
  ('bull_young',    0.55, 'Jungbulle <24 Mon');
