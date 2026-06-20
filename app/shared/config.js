// Supabase configuration
export const SUPABASE_URL = 'https://vhwlcnfxslkftswksqrw.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_2a5cKq6CF2Qfe1D1DqLrTw_0kHRD4Cd';

// App URLs — relative paths from /app/*.html
export const PAGES = {
  cockpit:   'cockpit.html',
  kalender:  'kalender.html',
  finanzen:  'finanzen.html',
  herde:     'herde.html',
  weide:     'weide.html',
  markt:     'markt.html',
  operativ:  'operativ.html',
  berichte:  'berichte.html',
  bericht:   'berichte.html#monat',
  wochenbericht: 'berichte.html#woche',
  bonus:     'bonus.html',
  admin:     'admin.html',
  forecast:  'forecast.html',
  // herdEntry has been merged into berichte.html#monat (Monatsmeldung erfassen)
  herdEntry: 'berichte.html#monat',
};

// LSU (Large Stock Unit) Umrechnungsfaktoren — Meissner-Referenz: 450-kg-Ochse = 1,0.
// Einheitliche 7-Kategorien-Taxonomie (Meat-Board-Handelskategorien). NICHT das
// EU-/GVE-System (anderes Referenztier). Kanonisch identisch zu categorizeAnimal().
export const LSU_FACTORS = {
  calf:       0.20,  // Kalb 0–7 Mon
  weaner:     0.40,  // Absetzer 7–12 Mon
  heifer:     0.60,  // Färse (weibl. ≥12 Mon, nicht gekalbt)
  cow:        1.00,  // Kuh (hat gekalbt)
  bull_young: 0.75,  // Jungbulle (männl. intakt 12–24 Mon)
  bull:       1.30,  // Zuchtbulle (männl. intakt ≥24 Mon)
  ox:         1.00,  // Ochse (kastriert)
};
