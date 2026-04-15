-- Herdenwert-Konfiguration (Preise, Ausschlachtungsquote)
CREATE TABLE herd_valuation_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  price_per_kg_carcass numeric NOT NULL DEFAULT 54.00,
  dressing_percentage numeric NOT NULL DEFAULT 0.52,
  effective_from date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

ALTER TABLE herd_valuation_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON herd_valuation_config FOR SELECT TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_insert" ON herd_valuation_config FOR INSERT TO authenticated
  WITH CHECK (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_update" ON herd_valuation_config FOR UPDATE TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));

CREATE INDEX idx_herd_valuation_effective ON herd_valuation_config(effective_from DESC);
