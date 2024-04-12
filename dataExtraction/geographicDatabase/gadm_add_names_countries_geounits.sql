INSERT INTO main.adm0_names(string, orig, name_type, cd_lang,cd_geounit,part)
WITH a AS(
SELECT name_0,'GADM', NULL,'en' cd_lang, cd_geounit,NOT equivalent
FROM gadm.gadm_adm0 a0
LEFT JOIN gadm.adm0_to_geounit a0tg USING (gid_0)
LEFT JOIN main.adm0_geounit g ON a0tg.included_in=g.cd_geounit
--WHERE equivalent
UNION
SELECT UNNEST(varname_0),'GADM','alternate' name_type, NULL,cd_geounit, NOT equivalent
FROM gadm.gadm_adm0 a0
LEFT JOIN gadm.adm0_to_geounit a0tg USING (gid_0)
LEFT JOIN main.adm0_geounit g ON a0tg.included_in=g.cd_geounit
--WHERE equivalent
)
SELECT *
FROM a
WHERE name_0 NOT IN (SELECT string FROM main.adm0_names)
AND cd_geounit IS NOT NULL
;

--NOTHING INTERESTING IN countries from gadm.sovereign:

SELECT a0.sovereign,'GADM', NULL,'en' cd_lang, cd_country,NOT equivalent,c.name
FROM gadm.gadm_adm0 a0
LEFT JOIN gadm.adm0_to_geounit a0tg USING (gid_0)
LEFT JOIN main.adm0_geounit g ON a0tg.included_in=g.cd_geounit
LEFT JOIN main.country c ON g.sovereign=c.cd_country
WHERE equivalent AND cd_country IS NOT NULL AND a0.sovereign NOT IN (SELECT string FROM main.country_names);
