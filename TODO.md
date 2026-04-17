# Farm-Controlling – Offene Features / Roadmap

Persistente Todo-Liste fürs Tool. Wird bei jedem Planungs-Sprint mitgepflegt.

## Ingest-Pipeline (PDF → DB)

- [ ] **Parser für Beefcor-Schlachtabrechnungen** — sobald erste PDFs vorliegen. Ähnlich `parse-meatco.js`, aber anderes Layout. Muss in `slaughter_reports` + `slaughter_line_items` schreiben (Grade, kg, N$). Auto-Ingest-Routing über Unterordner `Slaughterhouses-Other/Beefcor/`.
- [ ] **Parser für Savanna Beef Operations** — analog Beefcor. Provider-Key `savanna`.
- [ ] **Parser für RMAA** — analog. Provider-Key `rmaa`.
- [ ] **Bank-Statement-PDF-Parser** (aktuell nur JSON über `ingest`). Ziel: Rohe Nedbank/Pointbreak-PDFs direkt ingesten. Pdfplumber-basiert.
- [ ] **Income-Statement-Parser** (Buchhaltungs-PDFs) — Struktur noch zu klären.
- [ ] **Multi-Date Upload in `ingest` Edge Function für market-prices-lpo** — aktuell nimmt sie nur ein `price_date`; LPO liefert aber mehrere Wochen pro PDF.
- [ ] **Provider/Grade/Weight-Basis-Felder in ingest annehmen** — statt Ableitung aus `commodity`-String.

## Monitoring / Admin

- [ ] **Slack/E-Mail-Alert bei Ingest-Fehler** — aktuell nur Admin-UI-Badge. OpenClaw-Bot könnte E-Mails senden.
- [ ] **Letzter-Import-Badge im Cockpit** — schnelle Sichtbarkeit für Owner wenn Sync hängt.
- [ ] **Retry-Logik bei fehlgeschlagenen Ingests** — aktuell manuell.

## Daten-Qualität

- [ ] **Outlier-Detection für Marktpreise** — LPO-Parser lieferte mal Artefakte (z.B. 1000+ N$/kg). Check gegen Median ±50 % + flag in `data_imports.status='pending_review'`.
- [ ] **Währungs-Umrechnung** — fx_rates-Tabelle existiert aber nicht durchgängig verwendet (z.B. bei USD-Preisen).
- [ ] **Backfill historischer LPO-PDFs** — wenn Sammlung in GDrive wächst, alle vergangenen Wochen nachparsen.

## GDrive-Integration

- [x] Folder-ID für LPO/Schlachtberichte umstellen
- [x] Unterordner-Struktur LPO-Weekly / Meatco-Slaughter / Slaughterhouses-Other / Bank-Nedbank / Bank-Pointbreak / Accounting
- [ ] **Service-Account auf Cloud-VM statt lokalem Mac** — aktueller Cron läuft nur wenn Mac an ist.
- [ ] **GitHub Actions Runner** für tägliche Sync + Ingest — entkoppelt von Mac.

## UI / UX

- [ ] **Markt-Tab: Savanna-Daten sichtbar machen** sobald Savanna-Provider in DB vorhanden (aktuell nur bei neuen LPO-Layouts ab Q2 2026).
- [ ] **Markt: Vergleich historischer Preise per Provider** (Liniendiagramm über 6 Monate).
- [ ] **Admin: Manuelle Import-Auslösung** per Button (z.B. "LPO jetzt parsen").

## Technische Schulden

- [ ] **Edge Function `ingest` → Provider-Split-Funktion** — aktuelle Handler sind monolithisch.
- [ ] **schema.json im ingest-Function validieren** — aktuell nur top-level Felder geprüft.
- [ ] **TypeScript-Strict für Edge Functions** — mehrere `as unknown as ...` Casts.

## Erweiterungen

- [ ] **Automatischer Wetterbericht pro Kamp** via Open-Meteo API (Cron) + Alerts bei Regenabweichung.
- [ ] **NDVI-Integration** für Weide-Vegetations-Tracking (Sentinel-2 via sentinel.yml existiert schon).
- [ ] **Mobile-Eingabe** für Farmverwalter (PWA, offline-fähig).
