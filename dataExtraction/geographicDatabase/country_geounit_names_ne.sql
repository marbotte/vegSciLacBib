-- country names
CREATE TABLE main.country_names
(
  string text NOT NULL CHECK (string ~ '[A-za-z]'),
  orig text,
  name_type text,
  cd_lang char(2) REFERENCES main.lang(cd_lang),
  cd_country char(3) REFERENCES main.country(cd_country),
  locale boolean,
  part boolean, --When it is only a part of the country
  UNIQUE(string,name_type,cd_lang)
);

INSERT INTO main.country_names(string,orig,name_type,cd_lang,cd_country)
WITH a AS(
SELECT name string, 'naturalearth' orig, NULL name_type, 'en' cd_lang, cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT sovereignt, 'naturalearth', NULL, 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_long, 'naturalearth', 'long', 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT brk_name, 'naturalearth', NULL, 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT admin, 'naturalearth', NULL, 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT formal_en, 'naturalearth', 'formal', 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT formal_fr, 'naturalearth', 'formal', 'fr', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_ciawf, 'naturalearth', NULL, 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_sort, 'naturalearth', 'sort', 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT UNNEST(STRING_TO_ARRAY(name_alt,', ')), 'naturalearth', 'alternate', 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_en, 'naturalearth', NULL, 'en', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_fr, 'naturalearth', NULL, 'fr', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_pt, 'naturalearth', NULL, 'pt', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_es, 'naturalearth', NULL, 'es', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_de, 'naturalearth', NULL, 'de', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_nl, 'naturalearth', NULL, 'nl', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
UNION
SELECT name_it, 'naturalearth', NULL, 'it', cd_country
FROM ne.ne_10m_admin_0_countries
WHERE cd_country IS NOT NULL
)
SELECT DISTINCT ON (string,name_type,cd_lang) *
FROM a
WHERE string IS NOT NULL AND string ~ '[A-Za-z]'
ON CONFLICT (string,name_type,cd_lang) DO NOTHING;

-- adm0_names
CREATE TABLE main.adm0_names
(
  cd_name serial PRIMARY KEY,
  string text NOT NULL CHECK (string ~ '[A-za-z]'),
  orig text,
  name_type text,
  cd_lang char(2) REFERENCES main.lang(cd_lang),
  cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
  locale boolean,
  part boolean,--when it is only a part of the geounit
  UNIQUE(string,name_type,cd_lang)
);

INSERT INTO main.adm0_names(string,orig,name_type,cd_lang,cd_geounit)
WITH a AS(
SELECT name string, 'naturalearth' orig, NULL name_type, 'en' cd_lang, cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_long, 'naturalearth', 'long', 'en', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT brk_name, 'naturalearth', NULL, 'en', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT formal_en, 'naturalearth', 'formal', 'en', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT formal_fr, 'naturalearth', 'formal', 'fr', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_sort, 'naturalearth', 'sort', 'en', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT UNNEST(STRING_TO_ARRAY(name_alt,', ')), 'naturalearth', 'alternate', NULL, cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_en, 'naturalearth', NULL, 'en', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_fr, 'naturalearth', NULL, 'fr', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_pt, 'naturalearth', NULL, 'pt', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_es, 'naturalearth', NULL, 'es', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_de, 'naturalearth', NULL, 'de', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_nl, 'naturalearth', NULL, 'nl', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
UNION
SELECT name_it, 'naturalearth', NULL, 'it', cd_geounit
FROM ne.ne_10m_admin_0_map_subunits
WHERE cd_geounit IS NOT NULL
)
SELECT DISTINCT ON (string,name_type,cd_lang) *
FROM a
WHERE string IS NOT NULL AND string ~ '[A-Za-z]'
ON CONFLICT (string,name_type,cd_lang) DO NOTHING;

--Adding Part
UPDATE main.adm0_names SET part=false;

-- Adding locale
UPDATE main.adm0_names n
SET locale=false
WHERE cd_lang IS NOT NULL;
With a AS(
SELECT a0n.cd_name, bool_or(a0n.cd_lang=cl.cd_lang) locale_t
FROM main.adm0_names a0n
LEFT JOIN main.adm0_geounit a0g USING (cd_geounit)
LEFT JOIN main.country c ON a0g.sovereign = c.cd_country
LEFT JOIN main.country_lang cl ON c.cd_country=cl.cd_country
GROUP BY a0n.cd_name
)
UPDATE main.adm0_names n
SET locale=locale_t
FROM a
WHERE a.cd_name=n.cd_name AND a.locale_t IS NOT NULL;
