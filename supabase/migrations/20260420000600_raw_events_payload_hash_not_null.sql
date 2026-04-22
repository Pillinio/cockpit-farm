-- M11: payload_hash darf nicht null sein — das bestehende Unique-Index WHERE
-- payload_hash IS NOT NULL erlaubt sonst beliebig viele Duplikat-Inserts mit
-- NULL-Hash. Die ingest-Funktion setzt den Hash immer (SHA-256 der Payload),
-- aber ohne NOT NULL ist das nicht garantiert.

-- Sicherheits-Check: falls doch null-rows existieren, backfillen.
update raw_events
   set payload_hash = 'backfill-' || id::text
 where payload_hash is null;

alter table raw_events
  alter column payload_hash set not null;
