-- Erichsfelde Kamps Update (basierend auf Okt. 25)
-- generiert via scripts/extract-camps-from-kml.py
-- 68 Kamps insgesamt
-- 44 mit Polygon
-- 24 ohne Polygon (LineString-only / Folder ohne eigene Geometrie)

BEGIN;

-- ── UPSERT: Kamps aus KML ──
INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Berg-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Berg North-Kamp', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.85352260502215 -21.66280538056184, 16.87046617766839 -21.66023765860372, 16.87063086712879 -21.66017553499386, 16.87031781934665 -21.65962863375813, 16.87311816801904 -21.65924806743922, 16.86640751427962 -21.64171489150659, 16.86614427039029 -21.64846257413554, 16.85504137436396 -21.64810697263392, 16.85352260502215 -21.66280538056184))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Berg West-Kamp', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.85109908337962 -21.67740725212591, 16.83620798974467 -21.68021008954315, 16.82767255321876 -21.68175839481914, 16.81189904322005 -21.69356603916261, 16.85778552080103 -21.69610414088734, 16.87194858399509 -21.66249067420676, 16.87085643286002 -21.6605768095938, 16.8706275797454 -21.66017639799932, 16.87046593540686 -21.66023642993824, 16.85341935024748 -21.66283341295522, 16.85109908337962 -21.67740725212591))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Berg South-Kamp', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.88727298075152 -21.69822772000298, 16.88734849136784 -21.69746841142973, 16.88713337730824 -21.69550358233102, 16.87336452120141 -21.65999617392629, 16.87135278394271 -21.66047588025301, 16.8708544137473 -21.66058148992718, 16.87194968851155 -21.66248752610155, 16.85778138809701 -21.696107797901, 16.88727298075152 -21.69822772000298))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Berg Int', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.8449586793974 -21.68221700732246, 16.85033878083942 -21.68048831082017, 16.85112931986364 -21.67741400704371, 16.86697686484468 -21.67451599594604, 16.85111660822512 -21.67742513304551, 16.83619821406742 -21.68022607240589, 16.84498085668545 -21.68225698045551, 16.84392486780286 -21.6952785751273, 16.8449586793974 -21.68221700732246))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Bergposten 1', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.87336493887383 -21.65999335384725, 16.87312224463003 -21.65923674895, 16.87031442271259 -21.65962682506001, 16.87054804663968 -21.66002766484798, 16.87107065733482 -21.65983050764168, 16.87132782594492 -21.66047849527866, 16.87336493887383 -21.65999335384725))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Bergposten 2', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.87054845877602 -21.6600262523512, 16.87099005905843 -21.65985990570872, 16.87097310517411 -21.65981550230134, 16.87066559450618 -21.65993333074823, 16.8704885400963 -21.65960624564186, 16.87032010247126 -21.6596314183125, 16.87054845877602 -21.6600262523512))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Bergposten 3', 'Berg-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.87107209806901 -21.65983298063721, 16.8705488688768 -21.66002946700353, 16.87062849527849 -21.66017065196971, 16.87074431261667 -21.66011701157708, 16.87080172784308 -21.66006916039763, 16.87111534360636 -21.65994443501439, 16.87107209806901 -21.65983298063721))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Berposten 3' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Dreieck-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Dreieck-Kamp Bdy', 'Dreieck-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.88768083772238 -21.69539446740095, 16.88792292333186 -21.69695978436287, 16.8879110699989 -21.69766575741758, 16.8880936320471 -21.69767807666236, 16.89497231216463 -21.68700968473965, 16.89485764317822 -21.68699033973082, 16.89473297199409 -21.68697663819369, 16.89485506586494 -21.68682008371709, 16.89504522591485 -21.68688472008664, 16.89535805741561 -21.68638925370119, 16.89551343157259 -21.68570009327448, 16.89540133238961 -21.68571649532699, 16.89481543576721 -21.68634497151525, 16.8944273799507 -21.6864194632461, 16.8944199778231 -21.68652215711682, 16.89474426800787 -21.68658411614579, 16.89464254680463 -21.68696099648235, 16.89404539554687 -21.68691118961371, 16.89404193969003 -21.68653850250417, 16.89378513043223 -21.68661959759926, 16.88539326698886 -21.68946943800315, 16.88768083772238 -21.69539446740095))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Gemsbock-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Gemsbock North-Kamp', 'Gemsbock-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.92846801027298 -21.67162007395671, 16.93482200735843 -21.67343628591226, 16.93720231232684 -21.67387642062968, 16.94104342840533 -21.67561115795212, 16.94681958117022 -21.67927915051433, 16.95001734810478 -21.68117158278955, 16.95484761031543 -21.68411773473729, 16.95514316829061 -21.68424872522871, 16.95525708226424 -21.68388523354091, 16.9549824928905 -21.64254503632076, 16.94410801413439 -21.64219363563479, 16.93368089759884 -21.64184375995676, 16.93722631641698 -21.64998810544114, 16.91728746838949 -21.64932835649116, 16.91523242168066 -21.66775223866758, 16.92846801027298 -21.67162007395671))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Gamsbock North-Kamp' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Gemsbock South-Kamp', 'Gemsbock-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.91190283185961 -21.69723949651058, 16.95125644381244 -21.69650639421905, 16.95460848561467 -21.68463021410219, 16.95464684896489 -21.68445907844966, 16.95485545620062 -21.68411750500301, 16.946828218359 -21.67928126845569, 16.94104611394088 -21.67561238972694, 16.93720555877175 -21.67387717603155, 16.9348277452869 -21.67343808291617, 16.9284671533725 -21.67161538197573, 16.91522695899148 -21.66776220314684, 16.91391596603147 -21.67930997294926, 16.91190283185961 -21.69723949651058))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Gamsbock South-Kamp' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Gemsbock-Kamp Int', 'Gemsbock-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.93310343687089 -21.68500593731972, 16.94681721831804 -21.67928850647844, 16.9500154224069 -21.6811831816262, 16.94295678562255 -21.65953920912139, 16.94139988486707 -21.6547366318928, 16.93720413113682 -21.6499920926498, 16.94138145525046 -21.65471645214527, 16.94295924888271 -21.65952679111006, 16.92846512416739 -21.67161983273976, 16.93310343687089 -21.68500593731972))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Gamsbock-Kamp Int' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hackl-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hackl-Kamp Bdy', 'Hackl-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.95580469978977 -21.68454404950119, 16.95558241796462 -21.68493489453867, 16.95508992570415 -21.68466591499117, 16.955003317127 -21.68479516343927, 16.95487563055944 -21.68474222288166, 16.95159525204951 -21.69652265168514, 16.96651489446632 -21.6962752465527, 16.96934842711218 -21.69488183240103, 16.97501787024942 -21.68385702974179, 16.95580469978977 -21.68454404950119))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Hackel-Kamp Bdy' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hof', NULL, extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89808816247295 -21.60721083085765, 16.89894836590793 -21.60724480829541, 16.89940157119761 -21.60707851310384, 16.89938889436513 -21.60691719817057, 16.89941186139666 -21.60687932803141, 16.89946167438096 -21.60661298842546, 16.89959724781594 -21.60656816858646, 16.89948730655215 -21.60630820678086, 16.8993619815425 -21.60601332567378, 16.89887227977145 -21.60612449791954, 16.89824464546434 -21.60626569786124, 16.89808816247295 -21.60721083085765))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Druckkraal 1', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89892900743681 -21.60767632147828, 16.89893709506178 -21.60780294570896, 16.89899813963853 -21.60777367833946, 16.89892900743681 -21.60767632147828))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Druckkraal 2', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.8989981499574 -21.60777439852305, 16.89898371214885 -21.60778170655327, 16.89902661313879 -21.60795264693033, 16.89908205456414 -21.6079354478317, 16.8989981499574 -21.60777439852305))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Dorpie', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.90134410225384 -21.6088534629178, 16.90227838063942 -21.60917339773937, 16.90293789409554 -21.60894265280155, 16.90333891975952 -21.60808486373935, 16.90028357529217 -21.60732138416948, 16.89999358903149 -21.60747324862636, 16.90134410225384 -21.6088534629178))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 1', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89914472488935 -21.6073556508152, 16.89932374311697 -21.60776611079175, 16.89960946952566 -21.60744669999096, 16.89947618192651 -21.60723005213173, 16.89914472488935 -21.6073556508152))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 2', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89894113744968 -21.60733413249398, 16.89920464990156 -21.60789960226656, 16.89932370093497 -21.60776632275413, 16.89914489015062 -21.6073563259637, 16.89910470137107 -21.60727296639028, 16.89894113744968 -21.60733413249398))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 3', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.8989412608921 -21.60733533165916, 16.89879489970559 -21.60741667967632, 16.89887185401613 -21.60756803322751, 16.89901574119159 -21.60749468071382, 16.8989412608921 -21.60733533165916))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 4', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89879489657851 -21.60741728370894, 16.89866068450302 -21.60749591667928, 16.89872639966993 -21.6076330322952, 16.89887185401613 -21.60756803322751, 16.89879489657851 -21.60741728370894))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 5', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89887253807702 -21.60756773180203, 16.89893161059458 -21.60768057503936, 16.89899814115558 -21.60777306889932, 16.8991199457564 -21.60771814325344, 16.89901578367279 -21.60749451126822, 16.89887253807702 -21.60756773180203))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 6', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89899813819786 -21.60777428768188, 16.89908205907381 -21.60793584538769, 16.89920416438979 -21.60789945118406, 16.89911929021189 -21.60771814422048, 16.89899813819786 -21.60777428768188))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 7', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89883525618832 -21.60784877121848, 16.8989042611114 -21.607987560422, 16.89902664792447 -21.60795197181017, 16.89898371214885 -21.60778170655327, 16.89883525618832 -21.60784877121848))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 8', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89890391574457 -21.60798780251657, 16.89901729891064 -21.60822415688413, 16.899256231197 -21.6081963346165, 16.89920466956426 -21.60789962970258, 16.89890391574457 -21.60798780251657))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 9', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89890433885076 -21.60798844168105, 16.89865424319093 -21.60806451344813, 16.89875418982538 -21.60825748569579, 16.89901745741593 -21.60822474222008, 16.89890433885076 -21.60798844168105))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 10', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89875405442751 -21.6082576257697, 16.89885591058636 -21.60845095854185, 16.8991048578033 -21.60841884974791, 16.89901669753729 -21.6082250941819, 16.89875405442751 -21.6082576257697))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 11', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89901556804495 -21.60822389277424, 16.89910444473116 -21.60841863930772, 16.89928925535558 -21.60839168052956, 16.89925713552787 -21.60819663115193, 16.89901556804495 -21.60822389277424))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Hauskraal 12', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89865484685293 -21.60806500727193, 16.89826300714937 -21.6081749076375, 16.898322115478 -21.60852086510233, 16.89881212333501 -21.60836782023805, 16.89865484685293 -21.60806500727193))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kaktusgarten', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89910403719837 -21.60727257237912, 16.89914429026146 -21.60735544434154, 16.89947650958946 -21.60722993828628, 16.89942740358174 -21.60714920425453, 16.89910403719837 -21.60727257237912))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Mangakraal 1', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89872707049376 -21.60763322047285, 16.89875031945366 -21.60768180320031, 16.89879884439323 -21.60766417992335, 16.89884072796078 -21.6076623547796, 16.89886751908602 -21.60767024986817, 16.89889103202293 -21.60768118568891, 16.898915185068 -21.60769820454993, 16.89893346534743 -21.60771279915868, 16.89892770067899 -21.60767571394044, 16.89887187957377 -21.60756894317427, 16.89872707049376 -21.60763322047285))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Mangakraal 2', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89875097388635 -21.60768180315189, 16.89883525151684 -21.60784872704326, 16.8989364393655 -21.60780294578013, 16.89893281052505 -21.60771279919999, 16.89890012164841 -21.60770002977391, 16.89888314601639 -21.60768908760704, 16.89884198204643 -21.60767389704624, 16.89880009788775 -21.60767450759982, 16.89875097388635 -21.60768180315189))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Pferde-Acker', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89939835486033 -21.60447046602012, 16.89908332348531 -21.60535300833733, 16.89959653377499 -21.60656581408556, 16.89989338291021 -21.60646942218819, 16.899984687925 -21.60678015861862, 16.90001325852896 -21.60688194924524, 16.90193587706771 -21.60677720832716, 16.89939835486033 -21.60447046602012))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Pferdestall', 'Hof', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89974500737225 -21.60691347770184, 16.9000002620536 -21.60682424961271, 16.89989342052722 -21.60647063554986, 16.89959712760054 -21.60656658044466, 16.89974500737225 -21.60691347770184))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kälber-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kälber-Kamp Bdy', 'Kälber-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89510389733585 -21.68703789962386, 16.89497843243138 -21.6869995899182, 16.88809176164587 -21.6976786541379, 16.91190585344063 -21.69723682980812, 16.91390387839418 -21.6793250611715, 16.90173409583123 -21.68353547098163, 16.90169371827162 -21.68365105288229, 16.90023456571246 -21.68709199322948, 16.89510389733585 -21.68703789962386))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Kalber-Kamp Bdy' (Tippfehler korrigiert)

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kudu-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kudu-Kamp Bdy', 'Kudu-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.94739065294522 -21.61901123994436, 16.95063845020827 -21.59634600138485, 16.92398814316191 -21.59502171185131, 16.92146715297654 -21.59490286764642, 16.92247750082003 -21.59964119677744, 16.90842865225694 -21.60933579299826, 16.94739065294522 -21.61901123994436))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kudu Int', 'Kudu-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.93565315797036 -21.61611980995284, 16.93529564322082 -21.6146535013407, 16.9382470576858 -21.60491901063104, 16.93827092482279 -21.59572346894899, 16.93569379093817 -21.59560087988074, 16.93029787703298 -21.60302114799506, 16.92495435872531 -21.61347649914717, 16.93565315797036 -21.61611980995284))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kudu-Acker 2', 'Kudu-Kamp', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Kudu-Acker 1', 'Kudu-Kamp', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Matador-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Matador-Acker 1', 'Matador-Kamp', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Milzbrand-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Milzbrand-Kamp Bdy', 'Milzbrand-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.95525957153699 -21.68389749456079, 16.95514414763883 -21.68425501560226, 16.95534350440389 -21.68432114359234, 16.95577931679016 -21.68454533823914, 16.97501452506051 -21.68385703072391, 16.99055357745357 -21.65380664183804, 16.99074382120177 -21.64591465877967, 16.9917535903323 -21.64400067476094, 16.95491082281365 -21.64257631652457, 16.95525957153699 -21.68389749456079))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Mittel-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Mittel-Kamp Bdy', 'Mittel-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89377935505401 -21.68661979894126, 16.89379843359074 -21.68626849307173, 16.89540461978335 -21.68571664202588, 16.89551357286527 -21.68569872834146, 16.8951947442707 -21.68541213250936, 16.89393120453758 -21.6835034531221, 16.88947500349685 -21.6794796656379, 16.88837352796071 -21.67752959953451, 16.88813095808858 -21.67703072053026, 16.88756665837646 -21.67406425678072, 16.88068763391964 -21.65956234177115, 16.87976745544114 -21.65885602024738, 16.87966880487683 -21.65891784507186, 16.87400176907182 -21.65988076374315, 16.88540003540411 -21.68944561944232, 16.89377935505401 -21.68661979894126))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Okaruheke West-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Okaruheke West-Kamp Bdy', 'Okaruheke West-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89784452696171 -21.67683669364797, 16.89784122288026 -21.67655136341734, 16.89822585324074 -21.67655939759916, 16.90391412077494 -21.64079060037406, 16.86711014396102 -21.63948247582568, 16.86704754893935 -21.64096594918756, 16.86730336995484 -21.64260733365689, 16.87371275667571 -21.65915937463157, 16.87863050551486 -21.6584049855832, 16.87955908354507 -21.65874821947402, 16.8796700789384 -21.6589147485973, 16.87977193074885 -21.65885458221178, 16.88068558922105 -21.65955830567066, 16.88756711943697 -21.6740613244862, 16.88812929500163 -21.67703357216445, 16.88838072502058 -21.67752948539643, 16.89784452696171 -21.67683669364797))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Reha-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Reha-Kamp Bdy', 'Reha-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.93396152232218 -21.64254154439456, 16.91808759616736 -21.64196227085724, 16.91727110875934 -21.64933066279382, 16.93721803657632 -21.64998474331368, 16.93396152232218 -21.64254154439456))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Schlangen-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Schlangen-Acker 1', 'Schlangen-Kamp', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Schweine-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Schweine-Acker 1', 'Schweine-Kamp', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Schweine-Kamp Bdy', 'Schweine-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.90674359888503 -21.61444959933254, 16.90043230782123 -21.61538896794329, 16.90333010058009 -21.63330799754239, 16.90551221253676 -21.6345097922551, 16.90446885803221 -21.64080382509613, 16.94409868661671 -21.64217671208338, 16.94739065294522 -21.61901123994436, 16.90843276508167 -21.60933429888873, 16.90674359888503 -21.61444959933254))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Vlei Süd-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Verrit-Posteu Bdy', 'Vlei Süd-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.91311738465115 -21.67873528384352, 16.91422272020773 -21.66926571559444, 16.91322029449803 -21.66913912468154, 16.91325992377613 -21.66869336963645, 16.91384730408347 -21.66874660806985, 16.91380772953761 -21.66777196911583, 16.91431186477976 -21.66775912680793, 16.91583723468363 -21.65430910239857, 16.90222767625986 -21.65138518854283, 16.89823160133634 -21.67658620292879, 16.89811536702452 -21.67713139673507, 16.89729288961641 -21.68429558952461, 16.91311738465115 -21.67873528384352))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Vlei Nord-Kamp', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Vlei-Kamp Bdy', 'Vlei Nord-Kamp', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.91585237814749 -21.65430898520394, 16.91725139328694 -21.64195752227304, 16.90484485732363 -21.6414316809461, 16.9043989272833 -21.64092186444259, 16.90441620815535 -21.64080830746194, 16.90391535137636 -21.64079504188176, 16.90222543510868 -21.65138914807284, 16.91585237814749 -21.65430898520394))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Wildkamp-Acker', NULL, NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Wildkamp-Acker 1', 'Wildkamp-Acker', extensions.ST_Multi(extensions.ST_GeomFromText('POLYGON((16.89935397173338 -21.60445924872937, 16.89629151510159 -21.59365966645166, 16.89054031771441 -21.59337970083446, 16.89331103575861 -21.60342780804866, 16.89935397173338 -21.60445924872937))', 4326)), true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Wildkamp-Acker 2', 'Wildkamp-Acker', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Wildkamp-Acker 3', 'Wildkamp-Acker', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- ⚠ kein Polygon im KML → geom NULL, in der Karte unsichtbar

INSERT INTO farm_camps (name, parent_camp, geom, active) VALUES ('Wildkamp-Acker 4', 'Wildkamp-Acker', NULL, true)
ON CONFLICT (farm_id, name) DO UPDATE SET geom = COALESCE(EXCLUDED.geom, farm_camps.geom), parent_camp = EXCLUDED.parent_camp, active = true, updated_at = now();  -- Quelle: 'Wildkam-Acker 4' (Tippfehler korrigiert)

-- ── OPTIONAL: alte Kamps deaktivieren, die nicht mehr in der KML stehen ──
-- Wenn du das ausführen willst, entkommentiere den folgenden Block:
--
-- UPDATE farm_camps SET active = false, updated_at = now()
--   WHERE active = true AND name NOT IN (
--     'Berg Int', 'Berg North-Kamp', 'Berg South-Kamp', 'Berg West-Kamp', 
--     'Berg-Kamp', 'Bergposten 1', 'Bergposten 2', 'Bergposten 3', 'Dorpie', 
--     'Dreieck-Kamp', 'Dreieck-Kamp Bdy', 'Druckkraal 1', 'Druckkraal 2', 
--     'Gemsbock North-Kamp', 'Gemsbock South-Kamp', 'Gemsbock-Kamp', 
--     'Gemsbock-Kamp Int', 'Hackl-Kamp', 'Hackl-Kamp Bdy', 'Hauskraal 1', 
--     'Hauskraal 10', 'Hauskraal 11', 'Hauskraal 12', 'Hauskraal 2', 
--     'Hauskraal 3', 'Hauskraal 4', 'Hauskraal 5', 'Hauskraal 6', 
--     'Hauskraal 7', 'Hauskraal 8', 'Hauskraal 9', 'Hof', 'Kaktusgarten', 
--     'Kudu Int', 'Kudu-Acker 1', 'Kudu-Acker 2', 'Kudu-Kamp', 
--     'Kudu-Kamp Bdy', 'Kälber-Kamp', 'Kälber-Kamp Bdy', 'Mangakraal 1', 
--     'Mangakraal 2', 'Matador-Acker 1', 'Matador-Kamp', 'Milzbrand-Kamp', 
--     'Milzbrand-Kamp Bdy', 'Mittel-Kamp', 'Mittel-Kamp Bdy', 
--     'Okaruheke West-Kamp', 'Okaruheke West-Kamp Bdy', 'Pferde-Acker', 
--     'Pferdestall', 'Reha-Kamp', 'Reha-Kamp Bdy', 'Schlangen-Acker 1', 
--     'Schlangen-Kamp', 'Schweine-Acker 1', 'Schweine-Kamp', 
--     'Schweine-Kamp Bdy', 'Verrit-Posteu Bdy', 'Vlei Nord-Kamp', 
--     'Vlei Süd-Kamp', 'Vlei-Kamp Bdy', 'Wildkamp-Acker', 'Wildkamp-Acker 1', 
--     'Wildkamp-Acker 2', 'Wildkamp-Acker 3', 'Wildkamp-Acker 4' 
--   );

-- COMMIT prüfen vor Ausführung!
-- ROLLBACK; -- bei Bedenken
COMMIT;
