#!/usr/bin/env python3
"""Erzeugt SQL-UPSERTs für farm_camps aus einer Google-Earth-KML.

Vorgehen:
- KML einlesen, "Erichsfelde > Kamps"-Folder finden.
- Jede Folder-Ebene unter "Kamps" wird ein Hauptkamp (parent_camp = NULL).
  Wenn der Folder direkt ein <Polygon> enthält, wird das als geom genommen;
  sonst bleibt geom NULL (kann manuell nachgepflegt werden).
- Jede Placemark IM Folder wird ein Sub-Kamp mit parent_camp = Folder-Name.
- LineStrings haben kein Polygon → geom NULL.

Tippfehler aus dem KML werden NICHT automatisch korrigiert, sondern als
Kommentare angemerkt — du entscheidest, welche fixer/skipper-Liste du nutzt.

Aufruf:
    python3 scripts/extract-camps-from-kml.py <path/to/file.kml> > /tmp/camps.sql
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

NS = {'k': 'http://www.opengis.net/kml/2.2'}

# Bekannte Tippfehler im KML → kanonische Schreibweise im Tool
NAME_FIXES = {
    'Berposten 3':       'Bergposten 3',
    'Wildkam-Acker 4':   'Wildkamp-Acker 4',
    'Kalber-Kamp Bdy':   'Kälber-Kamp Bdy',
    'Hackel-Kamp Bdy':   'Hackl-Kamp Bdy',
    # Gemsbock/Gamsbock-Sammelfehler: Folder ist "Gemsbock", Subs "Gamsbock"
    'Gamsbock North-Kamp': 'Gemsbock North-Kamp',
    'Gamsbock South-Kamp': 'Gemsbock South-Kamp',
    'Gamsbock-Kamp Int':   'Gemsbock-Kamp Int',
}

# Items, die zwar im KML stehen aber keine Kamps sind (Orientierung/Weg/Grab)
SKIP_NAMES = {
    'Grab',
    'Hof-Insel',
    'Tiefenbach Laufgang',
    'Tiefenbach Laufgang 1',
    'Tiefenbach Laufgang 2',
    'River 33',
}


def find_folder(elem, name):
    """Tiefen-Suche: erstes Folder-Element mit passendem <name>."""
    for f in elem.iter('{http://www.opengis.net/kml/2.2}Folder'):
        n = f.find('k:name', NS)
        if n is not None and n.text == name:
            return f
    return None


def name_of(elem):
    n = elem.find('k:name', NS)
    return n.text if n is not None and n.text else None


def find_direct_child(elem, tag):
    """Direktes (nicht-rekursives) Kind-Element finden."""
    fullt = '{http://www.opengis.net/kml/2.2}' + tag
    for child in elem:
        if child.tag == fullt:
            return child
    return None


def polygon_to_wkt(poly_el):
    """KML <Polygon> → 'POLYGON((lon lat, ...))'."""
    if poly_el is None:
        return None
    # outerBoundaryIs > LinearRing > coordinates
    outer = poly_el.find('.//k:outerBoundaryIs/k:LinearRing/k:coordinates', NS)
    if outer is None or not outer.text:
        return None
    pts = []
    for tok in outer.text.split():
        parts = tok.split(',')
        if len(parts) >= 2:
            lon, lat = parts[0].strip(), parts[1].strip()
            if lon and lat:
                pts.append(f'{lon} {lat}')
    if len(pts) < 4:
        return None
    if pts[0] != pts[-1]:
        pts.append(pts[0])
    inner_clauses = [f'({", ".join(pts)})']
    # Inner Boundaries (Löcher) — bei Erichsfelde unüblich, aber sauber gehandhabt
    for ib in poly_el.findall('.//k:innerBoundaryIs/k:LinearRing/k:coordinates', NS):
        if not ib.text:
            continue
        ipts = []
        for tok in ib.text.split():
            parts = tok.split(',')
            if len(parts) >= 2:
                ipts.append(f'{parts[0].strip()} {parts[1].strip()}')
        if len(ipts) >= 4:
            if ipts[0] != ipts[-1]:
                ipts.append(ipts[0])
            inner_clauses.append(f'({", ".join(ipts)})')
    return f'POLYGON({", ".join(inner_clauses)})'


def sql_escape(s):
    if s is None:
        return 'NULL'
    return "'" + s.replace("'", "''") + "'"


def geom_expr(wkt):
    if wkt is None:
        return 'NULL'
    return f"extensions.ST_Multi(extensions.ST_GeomFromText({sql_escape(wkt)}, 4326))"


def normalize_name(raw):
    if raw is None:
        return None
    return NAME_FIXES.get(raw, raw)


def main():
    if len(sys.argv) < 2:
        print('usage: extract-camps-from-kml.py <kml-path>', file=sys.stderr)
        sys.exit(2)

    path = Path(sys.argv[1])
    tree = ET.parse(path)
    root = tree.getroot()

    kamps_folder = find_folder(root, 'Kamps')
    if kamps_folder is None:
        print('ERROR: kein Folder "Kamps" gefunden', file=sys.stderr)
        sys.exit(1)

    records = []  # list of dicts: {name, parent, wkt}
    main_kamps = set()  # parent_camp Names → werden als sub-parent referenziert

    for sub in kamps_folder:
        tag = sub.tag.split('}')[-1]
        if tag != 'Folder':
            continue
        fname_raw = name_of(sub)
        if not fname_raw:
            continue
        fname = normalize_name(fname_raw)
        if fname in SKIP_NAMES:
            continue
        # Polygon direkt im Folder?
        folder_poly = find_direct_child(sub, 'Polygon') or sub.find('k:Polygon', NS)
        wkt = polygon_to_wkt(folder_poly) if folder_poly is not None else None
        main_kamps.add(fname)
        records.append({'name': fname, 'parent': None, 'wkt': wkt, 'src': fname_raw})

        # Placemarks im Folder
        for pm in sub.findall('k:Placemark', NS):
            pname_raw = name_of(pm)
            if not pname_raw:
                continue
            pname = normalize_name(pname_raw)
            if pname in SKIP_NAMES:
                continue
            if pname == fname:
                # Folder + gleichnamige Placemark → Doppelung. Wenn Folder kein WKT hat,
                # nehmen wir die Placemark-Geometrie als Folder-Geometrie.
                pm_poly = pm.find('.//k:Polygon', NS)
                pm_wkt = polygon_to_wkt(pm_poly)
                if records[-1]['wkt'] is None and pm_wkt is not None:
                    records[-1]['wkt'] = pm_wkt
                continue
            pm_poly = pm.find('.//k:Polygon', NS)
            pm_wkt = polygon_to_wkt(pm_poly)
            records.append({'name': pname, 'parent': fname, 'wkt': pm_wkt, 'src': pname_raw})

    # SQL Output
    out = []
    out.append('-- Erichsfelde Kamps Update (basierend auf Okt. 25)')
    out.append('-- generiert via scripts/extract-camps-from-kml.py')
    out.append('-- ' + str(len(records)) + ' Kamps insgesamt')
    out.append('-- ' + str(sum(1 for r in records if r['wkt'])) + ' mit Polygon')
    out.append('-- ' + str(sum(1 for r in records if not r['wkt'])) + ' ohne Polygon (LineString-only / Folder ohne eigene Geometrie)')
    out.append('')
    out.append('BEGIN;')
    out.append('')
    out.append('-- ── UPSERT: Kamps aus KML ──')
    for r in records:
        # Tippfehler-Anmerkung
        marker = ''
        if r['src'] in NAME_FIXES:
            marker = f"  -- Quelle: '{r['src']}' (Tippfehler korrigiert)"
        elif not r['wkt']:
            marker = '  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar'
        out.append(
            f"INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES "
            f"({sql_escape(r['name'])}, {sql_escape(r['parent'])}, {geom_expr(r['wkt'])}, true)"
            f"\nON CONFLICT (farm_id, name) DO UPDATE SET "
            f"geom = COALESCE(EXCLUDED.geom, farm_camps.geom), "
            f"parent_camp = EXCLUDED.parent_camp, "
            f"active = true, "
            f"updated_at = now();{marker}"
        )
        out.append('')

    # Optional: alle Kamps, die NICHT in der neuen Liste stehen, deaktivieren
    new_names = sorted(set(r['name'] for r in records))
    out.append('-- ── OPTIONAL: alte Kamps deaktivieren, die nicht mehr in der KML stehen ──')
    out.append('-- Wenn du das ausführen willst, entkommentiere den folgenden Block:')
    out.append('--')
    quoted = ', '.join(sql_escape(n) for n in new_names)
    out.append(f"-- UPDATE farm_camps SET active = false, updated_at = now()")
    out.append(f"--   WHERE active = true AND name NOT IN (")
    # 70-char-broken-list für Lesbarkeit
    line = '--     '
    for i, name in enumerate(new_names):
        token = sql_escape(name) + (',' if i < len(new_names) - 1 else '')
        if len(line) + len(token) > 78:
            out.append(line)
            line = '--     '
        line += token + ' '
    if line.strip() != '--':
        out.append(line)
    out.append('--   );')
    out.append('')
    out.append('-- COMMIT prüfen vor Ausführung!')
    out.append('-- ROLLBACK; -- bei Bedenken')
    out.append('COMMIT;')

    print('\n'.join(out))


if __name__ == '__main__':
    main()
