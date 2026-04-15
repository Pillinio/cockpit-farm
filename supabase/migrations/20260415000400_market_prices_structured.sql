-- Strukturiert market_prices: provider / grade / weight_basis als First-Class-Felder.
-- Existierende Zeilen werden aus dem commodity-String gebackfillt.

ALTER TABLE market_prices
  ADD COLUMN IF NOT EXISTS provider     text,
  ADD COLUMN IF NOT EXISTS grade        text,
  ADD COLUMN IF NOT EXISTS weight_basis text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'market_prices_weight_basis_check'
  ) THEN
    ALTER TABLE market_prices
      ADD CONSTRAINT market_prices_weight_basis_check
      CHECK (weight_basis IS NULL OR weight_basis IN ('carcass','live','per_head'));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_market_prices_filter
  ON market_prices (weight_basis, provider, grade, price_date DESC);

-- Backfill Meatco Fixed (muss VOR dem generischen beef_%-Backfill laufen,
-- weil 'beef_meatco_fixed_A2' sonst als provider='meatco', grade='fixed' gebackfillt wird).
UPDATE market_prices SET
  provider     = 'meatco_fixed',
  grade        = split_part(commodity, '_', 4),
  weight_basis = 'carcass'
WHERE commodity LIKE 'beef_meatco_fixed_%'
  AND provider IS NULL;

-- Backfill alle übrigen beef_<provider>_<grade>: meatco, beefcor, rmaa, savannah
UPDATE market_prices SET
  provider     = split_part(commodity, '_', 2),
  grade        = split_part(commodity, '_', 3),
  weight_basis = 'carcass'
WHERE commodity LIKE 'beef_%'
  AND commodity NOT LIKE 'beef_meatco_fixed_%'
  AND provider IS NULL;

-- Backfill Auktions-Preise (per_head, kein Grade)
UPDATE market_prices SET
  provider     = 'auction',
  grade        = NULL,
  weight_basis = 'per_head'
WHERE commodity LIKE 'auction_%'
  AND provider IS NULL;

-- Legacy Dashboard-Einträge wie "Meatco Grade A0 (180-239)" (parse-dashboard.js)
UPDATE market_prices SET
  provider     = 'meatco',
  grade        = substring(commodity FROM 'Grade\s+([A-C]+\d)'),
  weight_basis = 'carcass'
WHERE commodity ILIKE 'meatco grade %'
  AND provider IS NULL;

-- FX-Kurse bleiben ohne Provider/Grade (werden nicht mehr auf markt.html gerendert)
-- und laufen auf weight_basis = NULL — kein CHECK-Verstoß dank NULL-Zulässigkeit.
