# Go-Live — Schritt für Schritt

Reihenfolge ist wichtig: Auth muss vor dem ersten Login funktionieren, Vault-Secret muss vor den pg_cron-Jobs gesetzt sein, Cloudflare-Domain muss bekannt sein bevor Auth-Redirects konfiguriert werden.

Projekt-Ref: `vhwlcnfxslkftswksqrw`
Service-Role-Key bleibt im Vault — niemals in Repo / Chat / E-Mail.

---

## 1. Cloudflare Pages deployen (5 min, lokal)

In einem normalen Terminal (nicht Claude Code):

```bash
cd /Users/philipp/Projekte/Farmcockpit
wrangler login                          # öffnet Browser, einmalig
npx wrangler pages deploy . --project-name=farm-controlling
# Bei Erstausführung: Production Branch = main
```

→ Notiere die finale URL (z.B. `https://farm-controlling.pages.dev`). Brauchst du in Schritt 2.

**Verify:** `https://farm-controlling.pages.dev/app/login.html` lädt das Magic-Link-Formular.

---

## 2. Supabase Auth aktivieren (2 min, Dashboard)

**a) Email-Provider an:**
https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/auth/providers
→ Email → "Enable Email provider" auf AN. "Confirm email" kann AUS bleiben.

**b) URL-Konfiguration:**
https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/auth/url-configuration

- **Site URL:** `https://farm-controlling.pages.dev` (oder deine eigene Domain aus Schritt 1)
- **Redirect URLs** (alle vier eintragen):
  - `https://farm-controlling.pages.dev/app/cockpit.html`
  - `https://farm-controlling.pages.dev/app/herd-entry.html`
  - `https://farm-controlling.pages.dev/app/login.html`
  - `http://localhost:3001/**`

**Verify:** Auf der Pages-URL Login → Magic Link kommt per Mail an.

---

## 3. Storage Bucket anlegen (1 min, Dashboard)

https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/storage/buckets

- **New bucket** → Name `farm-uploads`, **public OFF**
- Policies (im Editor unter "Policies" am Bucket):
  - `INSERT` für authenticated User aus eigener Farm (`bucket_id = 'farm-uploads' AND auth.uid() IS NOT NULL`)
  - `SELECT` analog

**Verify:** Bucket erscheint in der Liste, leer.

---

## 4. Owner-Profil + erster Login (3 min, Dashboard)

**a) Login einmal durchspielen:**
`https://farm-controlling.pages.dev/app/login.html` → eigene Mail eintragen → Magic Link klicken → landet auf cockpit.html (rendert leer, weil noch kein Profil).

**b) Profile-Row anlegen:**
SQL Editor → https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/sql/new

```sql
insert into profiles (id, farm_id, role, display_name)
values (
  (select id from auth.users where email = 'p.rocholl@rocholl-gmbh.de' limit 1),
  (select id from farms where name = 'Erichsfelde' limit 1),
  'owner',
  'Philipp Rocholl'
);
```

**Verify:** Cockpit nach Reload zeigt KPI-Karten mit Daten.

---

## 5. pg_cron + pg_net + Vault (5 min, Dashboard)

**a) Extensions an:**
https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/database/extensions
→ `pg_cron` und `pg_net` aktivieren.

**b) Service-Role-Key in den Vault** (SQL Editor):
Ersetze `<SERVICE_ROLE_KEY>` mit dem Key aus
https://supabase.com/dashboard/project/vhwlcnfxslkftswksqrw/settings/api
(`service_role` — geheim!).

```sql
select vault.create_secret(
  '<SERVICE_ROLE_KEY>',
  'service_role_key',
  'Service role key for pg_cron Edge Function calls'
);
```

**c) Cron-Jobs anlegen** (SQL Editor, ein Block):

```sql
select cron.schedule('alerts-hourly', '0 * * * *', $$
  select net.http_post(
    url     := 'https://vhwlcnfxslkftswksqrw.supabase.co/functions/v1/alerts',
    headers := internal.edge_function_headers(),
    body    := '{}'::jsonb
  );
$$);

select cron.schedule('health-check-6h', '0 */6 * * *', $$
  select net.http_post(
    url     := 'https://vhwlcnfxslkftswksqrw.supabase.co/functions/v1/health-check',
    headers := internal.edge_function_headers(),
    body    := '{}'::jsonb
  );
$$);

select cron.schedule('reminder-monthly', '0 8 1 * *', $$
  select net.http_post(
    url     := 'https://vhwlcnfxslkftswksqrw.supabase.co/functions/v1/reminder',
    headers := internal.edge_function_headers(),
    body    := '{}'::jsonb
  );
$$);
```

**Verify:**

```sql
select jobid, jobname, schedule, active from cron.job;
-- erwartet: 3 Zeilen, alle active=true
```

Optional sofortiger Trigger-Test (alerts läuft sonst zur vollen Stunde):

```sql
select cron.schedule('alerts-test-once', '* * * * *', $$
  select net.http_post(
    url     := 'https://vhwlcnfxslkftswksqrw.supabase.co/functions/v1/alerts',
    headers := internal.edge_function_headers(),
    body    := '{}'::jsonb
  );
$$);
-- 2 min warten, dann:
select cron.unschedule('alerts-test-once');
select * from net._http_response order by created desc limit 5;  -- HTTP 200?
```

---

## 6. Smoke-Test Edge Functions (2 min, Terminal)

```bash
cd /Users/philipp/Projekte/Farmcockpit
export SUPABASE_URL=https://vhwlcnfxslkftswksqrw.supabase.co
export SUPABASE_ANON_KEY='<anon-key aus Dashboard>'
bash tests/edge-smoke.sh
```

**Erwartung:** alle Endpoints geben 401 für leeren + gefälschten Bearer zurück. `Result: 18 passed, 0 failed`.

---

## 7. End-to-End Smoke (10 min, Mobil + Desktop)

CHECKLIST.md §9 abarbeiten:

- [ ] Login → Cockpit → jeder Tab → Logout
- [ ] Herd-Entry auf echtem Smartphone, möglichst über LTE
- [ ] Alle 47 Camps auf Karte sichtbar (weide.html)
- [ ] Künstlich Alert auslösen (z.B. Test-Reihe in `pasture_observations` mit Score 1) → `alert_history`-Row + ggf. Telegram
- [ ] Bonus-Live-Defaults vs. manuelle Eingabe → identisches Ergebnis
- [ ] Budget-Summen 2024 vs. Excel-Original
- [ ] Meatco-Total (3 Statements) vs. PDF-Originale

---

## Optional (nicht Go-Live-blockierend)

- **Telegram-Bot:** DEPLOY.md §4. Nur für Reminder/Alert-Versand.
- **Resend-API-Key:** Wenn Quartals-Report per Mail kommen soll. Dashboard-Edge-Secret `RESEND_API_KEY`. PDF-Generator selbst ist noch nicht implementiert (Phase 4 offen).
- **Copernicus-Account:** Für echtes Sentinel-2-NDVI. Alternativ vorerst der Open-Meteo-Vegetation-Proxy.
- **Eigene Domain:** Cloudflare Pages → Custom domain → DNS automatisch wenn Domain bei CF.

---

## Was ich (Claude) gemacht habe — bereits committet

- `report` Edge Function: Auth auf Service-Role-only (verifyAuth-Pattern, Commit `61d9f00`)
- `tests/edge-smoke.sh`: prüft alle Service-Role-Endpoints auf 401
- README: Neufassung als Projekt-Frontdoor (Commit `3c93ef3`)
- GitHub Actions `test.yml` + `package.json`: bonus-engine Golden-Master via CI (Commit `a4d1d44`)

→ **Push noch nicht gemacht.** Wenn du `git push` willst, sag Bescheid.
