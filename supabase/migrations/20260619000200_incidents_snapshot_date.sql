-- FIX: Monatsmeldung löschen schlägt fehl + Vorfälle wurden nie gespeichert.
--
-- Befund (live im Browser reproduziert): Der Monatsbericht-Code referenziert
-- incidents.snapshot_date an mehreren Stellen (Insert/Select/Delete), aber die
-- Spalte existiert nicht — der Refactor 20260417000400 ergänzte snapshot_date
-- nur bei camp_vegetation/pasture_observations und vergaß incidents.
-- Folgen:
--   1. deleteMeldung() bricht beim Kind-Delete auf incidents mit
--      "column incidents.snapshot_date does not exist" (42703) ab → die ganze
--      Löschung schlägt fehl (Monatsmeldung lässt sich nicht löschen).
--   2. Vorfälle aus dem Monatsbericht wurden nie gespeichert (Insert mit
--      snapshot_date schlug still fehl → incidents-Tabelle ist leer).
--
-- Fix: snapshot_date-Spalte ergänzen, analog zum bestehenden Muster. Damit
-- funktionieren Insert/Select/Delete des Monatsberichts wie vorgesehen.

alter table incidents
  add column if not exists snapshot_date date;

create index if not exists idx_incidents_snapshot
  on incidents(snapshot_date);
