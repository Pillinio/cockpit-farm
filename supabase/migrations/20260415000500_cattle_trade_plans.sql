-- Kauf- und Verkaufsplanung für Rinder
CREATE TABLE cattle_trade_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  trade_type text NOT NULL CHECK (trade_type IN ('sell','buy')),
  animal_category text NOT NULL CHECK (animal_category IN (
    'cows','bulls','heifers','calves','oxen','tollies','weaners','mixed'
  )),
  head_count integer NOT NULL CHECK (head_count > 0),
  target_date date,
  estimated_price_per_head numeric,
  estimated_total_nad numeric,
  destination text,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','in_progress','completed','cancelled')),
  notes text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE cattle_trade_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON cattle_trade_plans FOR SELECT TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_insert" ON cattle_trade_plans FOR INSERT TO authenticated
  WITH CHECK (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_update" ON cattle_trade_plans FOR UPDATE TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_delete" ON cattle_trade_plans FOR DELETE TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));

CREATE INDEX idx_cattle_trade_date ON cattle_trade_plans(target_date DESC);
CREATE INDEX idx_cattle_trade_status ON cattle_trade_plans(status, trade_type);
