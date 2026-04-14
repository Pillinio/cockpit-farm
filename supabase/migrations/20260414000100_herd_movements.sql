-- Herd movements: track cattle transfers between camps
CREATE TABLE herd_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  movement_date date NOT NULL,
  from_camp text,          -- NULL = birth/purchase (animals entering farm)
  to_camp text,            -- NULL = sale/death (animals leaving farm)
  head_count integer NOT NULL CHECK (head_count > 0),
  animal_category text NOT NULL CHECK (animal_category IN ('cows','bulls','heifers','calves','oxen','mixed')),
  reason text NOT NULL CHECK (reason IN ('rotation','birth','purchase','sale','death','separation','other')),
  notes text,
  recorded_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE herd_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON herd_movements FOR SELECT TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_insert" ON herd_movements FOR INSERT TO authenticated
  WITH CHECK (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_update" ON herd_movements FOR UPDATE TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_delete" ON herd_movements FOR DELETE TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));

CREATE INDEX idx_herd_movements_date ON herd_movements(movement_date DESC);
CREATE INDEX idx_herd_movements_camps ON herd_movements(from_camp, to_camp);

-- View: current camp occupancy derived from movement history
CREATE OR REPLACE VIEW camp_occupancy AS
WITH inflows AS (
  SELECT to_camp AS camp, movement_date, head_count, animal_category
  FROM herd_movements WHERE to_camp IS NOT NULL
),
outflows AS (
  SELECT from_camp AS camp, movement_date, -head_count AS head_count, animal_category
  FROM herd_movements WHERE from_camp IS NOT NULL
),
all_flows AS (
  SELECT * FROM inflows UNION ALL SELECT * FROM outflows
)
SELECT camp,
  SUM(head_count) AS current_head,
  MAX(movement_date) AS last_movement,
  (CURRENT_DATE - MAX(movement_date)) AS days_since_last_movement
FROM all_flows
GROUP BY camp
HAVING SUM(head_count) > 0
ORDER BY camp;
