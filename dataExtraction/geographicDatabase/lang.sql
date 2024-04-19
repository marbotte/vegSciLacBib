CREATE TABLE main.lang
(
  cd_lang char(2) PRIMARY KEY,
  lang varchar(20) UNIQUE
);
INSERT INTO main.lang
VALUES
('en','English'),
('fr','French'),
('es','Spanish'),
('pt','Portuguese'),
('de','German'),
('nl','Dutch'),
('it','Italian'),
('99','Other');

CREATE TABLE main.country_lang
(
  cd_country char(3) REFERENCES main.country(cd_country) NOT NULL,
  cd_lang char(2) REFERENCES main.lang(cd_lang) NOT NULL,
  UNIQUE(cd_country,cd_lang)
);
INSERT INTO main.country_lang
WITH names AS(
SELECT name,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
UNION
SELECT name_en,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
UNION
SELECT formal_en,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
UNION
SELECT sovereignt,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
), a as(
SELECT country,sovereignt,first_offi lang
FROM wl.world_languages
UNION ALL
SELECT country,sovereignt,second_off lang
FROM wl.world_languages
UNION ALL
SELECT country,sovereignt,third_offi  lang
FROM wl.world_languages
), corr AS(
SELECT
  CASE
    WHEN sovereignt='Guinea Bissau' THEN 'Guinea-Bissau'
    WHEN sovereignt='Republic of Congo' THEN 'Republic of the Congo'
    WHEN sovereignt='Sao Tome and Principe' THEN 'São Tomé and Principe'
    WHEN sovereignt='Swaziland' THEN 'eSwatini'
    ELSE sovereignt
  END sovereignt,
  lang
FROM a
WHERE lang IN (SELECT lang FROM main.lang)
)
SELECT DISTINCT cd_country,cd_lang
FROM corr c
LEFT JOIN names n ON c.sovereignt=n.name
LEFT JOIN main.lang USING (lang)
ORDER BY cd_country
;
CREATE INDEX main_country_lang_cd_country ON main.country_lang(cd_country);
CREATE INDEX main_country_lang_cd_lang ON main.country_lang(cd_lang);
