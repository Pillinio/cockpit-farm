-- Feature: Ochsen (kastriert) von Bullen (intakt) trennen.
--
-- herd_animals kennt aus dem CSV-Import nur Sex M/F, keine Kastraten-Info.
-- Tester-Feedback: "Ich würde Ochsen und Bullen in separate Kategorien
-- einordnen." Lösung: neues Feld is_castrated (manuell pflegbar via Herde-Seite).
--   is_castrated = true  -> Ochse (Mast)
--   is_castrated = false -> Bulle (intakt/Zucht)
--   is_castrated = null  -> ungetaggt (wird als Bulle/intakt behandelt)

alter table herd_animals
  add column if not exists is_castrated boolean;

-- Tageszunahme für adulte Zuchtbullen (stabil, kaum Zunahme). Ochsen nutzen
-- weiterhin die bestehende Mast-Rate 'ox_fattening' (0.40).
insert into weight_gain_config (category, daily_gain_kg, description)
values ('bull_adult', 0.15, 'Bulle adult (Zuchtbulle, stabil)')
on conflict (farm_id, category) do nothing;
