-- Zentraler Log aller Datenimporte
CREATE TABLE data_imports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL REFERENCES farms(id) DEFAULT default_farm_id(),
  source_type text NOT NULL,
  source_detail text,
  period_start date,
  period_end date,
  file_name text,
  file_path text,
  file_size_bytes integer,
  file_hash text,
  records_count integer,
  status text NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'pending_review', 'failed', 'duplicate')),
  error_message text,
  triggered_by text NOT NULL DEFAULT 'manual',
  imported_by uuid REFERENCES auth.users(id),
  raw_event_id uuid,
  imported_at timestamptz DEFAULT now(),
  notes text
);

ALTER TABLE data_imports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "farm_read" ON data_imports FOR SELECT TO authenticated
  USING (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "farm_insert" ON data_imports FOR INSERT TO authenticated
  WITH CHECK (farm_id = (SELECT farm_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "service_all" ON data_imports FOR ALL TO service_role USING (true);

CREATE INDEX idx_data_imports_date ON data_imports(imported_at DESC);
CREATE INDEX idx_data_imports_type ON data_imports(source_type, imported_at DESC);
CREATE INDEX idx_data_imports_hash ON data_imports(file_hash) WHERE file_hash IS NOT NULL;
