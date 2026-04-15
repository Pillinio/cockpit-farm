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

// LSU (Large Stock Unit) conversion factors
export const LSU_FACTORS = {
  cows:    1.0,
  bulls:   1.2,
  heifers: 0.8,
  oxen:    1.0,
  calves:  0.2,
};
