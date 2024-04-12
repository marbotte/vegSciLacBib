
-------------------------------------------------
----- Relations with naturalearth adm1 ----------
-------------------------------------------------

---
CREATE TABLE tmp.ne_adm1_name AS(
WITH a AS(
SELECT name string, 'naturalearth' orig, NULL name_type, 'en' cd_lang, adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT UNNEST(STRING_TO_ARRAY(name_alt,'|')), 'naturalearth', 'alternate', NULL, adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT woe_name, 'naturalearth' orig, NULL, NULL, adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT gn_name, 'naturalearth' orig, NULL, NULL, adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_en, 'naturalearth', NULL, 'en', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_fr, 'naturalearth', NULL, 'fr', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_pt, 'naturalearth', NULL, 'pt', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_es, 'naturalearth', NULL, 'es', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_de, 'naturalearth', NULL, 'de', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_nl, 'naturalearth', NULL, 'nl', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
UNION
SELECT name_it, 'naturalearth', NULL, 'it', adm1_code
FROM ne.ne_10m_admin_1_states_provinces
WHERE adm1_code IS NOT NULL
)
SELECT DISTINCT *
FROM a
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
);





-- names from gadm adm1
CREATE TABLE tmp.gadm_adm1_name AS(
WITH a AS(
SELECT name_1 string, 'GADM' orig, NULL name_type, 'en' cd_lang, gid_1
FROM gadm.gadm_adm1
UNION
SELECT UNNEST(varname_1), 'GADM', NULL, NULL, gid_1
FROM gadm.gadm_adm1
)
SELECT DISTINCT string, name_type, cd_lang, cd_adm1
FROM a
JOIN main.adm1 USING (gid_1)
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
);

DELETE FROM tmp.gadm_adm1_name
WHERE length(string)=1;

-- names from gadm adm2
CREATE TABLE tmp.gadm_adm2_name AS(
WITH a AS(
SELECT name_2 string, 'GADM' orig, NULL name_type, 'en' cd_lang, gid_2
FROM gadm.gadm_adm2
UNION
SELECT UNNEST(varname_2), 'GADM', NULL, NULL, gid_2
FROM gadm.gadm_adm2
)
SELECT DISTINCT string, name_type, cd_lang, cd_adm2
FROM a
JOIN main.adm2 USING (gid_2)
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
);



-- Searching the cases where the name is the same, both were included in the same geounit (when there are formal links gadm_adm1 -> main_adm1 -> geounit and ne_adm1 -> ne_adm0 -> geounit) and distance < 40 km

   --We first create a table with similarity and distances for adm1/ne_admin_1
CREATE TABLE tmp.simil_adm1_ne1 AS(
WITH a AS(
SELECT DISTINCT a1.cd_geounit,a1.adm1 g_name, n1ss.name n_name,a1.cd_adm1,n1ss.adm1_code,gadm_level,a1.the_geom ,n1ss.geom
FROM tmp.gadm_adm1_name gn
JOIN main.adm1 a1 USING (cd_adm1)
JOIN main.adm0_geounit USING (cd_geounit)
JOIN ne.ne_10m_admin_0_map_subunits USING(cd_geounit)
JOIN ne.ne_10m_admin_1_states_provinces n1ss USING (gu_a3)
JOIN tmp.ne_adm1_name nn ON n1ss.adm1_code=nn.adm1_code AND UNACCENT(LOWER(gn.string))= UNACCENT(LOWER(nn.string))
), b AS(
SELECT cd_geounit, cd_adm1, adm1_code,g_name, n_name, ST_Area(the_geom,true)/(1000*1000) g_area,ST_Area(geom,true)/(1000*1000) n_area, ST_Area(ST_Intersection(the_geom,geom),true)/(1000*1000) common_area, ST_Distance(the_geom,geom,true)/1000 distance_km, gadm_level
FROM a
)
SELECT cd_geounit, cd_adm1, adm1_code,g_name, n_name, (common_area/n_area) * (common_area/g_area) similarity, n_area,g_area,common_area,distance_km, gadm_level
FROM b
ORDER BY similarity
)
;
    --Then we create a table with similarity and distances for adm2/ne_admin_1

CREATE TABLE tmp.simil_adm2_ne1 AS(
WITH a AS(
SELECT DISTINCT a2.cd_geounit,a2.adm2 g_name, n1ss.name n_name,a2.cd_adm2,n1ss.adm1_code,a2.the_geom ,n1ss.geom, gadm_level
FROM tmp.gadm_adm2_name gn
JOIN main.adm2 a2 USING (cd_adm2)
JOIN main.adm0_geounit USING (cd_geounit)
JOIN ne.ne_10m_admin_0_map_subunits USING(cd_geounit)
JOIN ne.ne_10m_admin_1_states_provinces n1ss USING (gu_a3)
JOIN tmp.ne_adm1_name nn ON n1ss.adm1_code=nn.adm1_code AND UNACCENT(LOWER(gn.string))= UNACCENT(LOWER(nn.string))
), b AS(
SELECT cd_geounit, cd_adm2, adm1_code,g_name, n_name, ST_Area(the_geom,true)/(1000*1000) g_area,ST_Area(geom,true)/(1000*1000) n_area, ST_Area(ST_Intersection(the_geom,geom),true)/(1000*1000) common_area, ST_Distance(the_geom,geom,true)/1000 distance_km, gadm_level
FROM a
)
SELECT cd_geounit, cd_adm2, adm1_code,g_name, n_name, (common_area/n_area) * (common_area/g_area) similarity, n_area,g_area,common_area,distance_km, gadm_level
FROM b
ORDER BY similarity
)
;

-- Now we look at the best match for the ne polygons having the same names and a geographic similarity > 0.5 and we put them in the main tables

WITH a AS(
SELECT cd_geounit, adm1_code,n_name, gadm_level, 'adm1' match_1_2, cd_adm1,g_name adm1,NULL cd_adm2,NULL adm2, similarity, distance_km, n_area, g_area, common_area
FROM tmp.simil_adm1_ne1
UNION
SELECT cd_geounit, adm1_code,n_name, gadm_level,'adm2' match_1_2, NULL cd_adm1, NULL adm1,cd_adm2, g_name adm2, similarity, distance_km, n_area, g_area, common_area
FROM tmp.simil_adm2_ne1
), b AS(
SELECT adm1_code,
    ARRAY_AGG(adm1 ORDER BY similarity DESC) FILTER (WHERE match_1_2='adm1') adm1s,
    ARRAY_AGG(similarity ORDER BY similarity DESC) FILTER (WHERE match_1_2='adm1') sim_adm1,
    ARRAY_AGG(adm2 ORDER BY similarity)FILTER (WHERE match_1_2='adm2') adm2s,
    ARRAY_AGG(similarity ORDER BY similarity DESC) FILTER (WHERE match_1_2='adm2') sim_adm2
FROM a
GROUP BY adm1_code
), c AS(
SELECT DISTINCT ON (adm1_code) cd_geounit,adm1_code, n_name, match_1_2,cd_adm1, adm1, cd_adm2, adm2,similarity,distance_km,n_area,g_area,common_area,adm1s,adm2s
FROM a
LEFT JOIN b USING (adm1_code)
WHERE similarity>0.5
ORDER BY adm1_code, similarity DESC, distance_km ASC,match_1_2
), d AS(
UPDATE main.adm1 a1
SET adm1_code=c.adm1_code
FROM c
WHERE a1.cd_adm1=c.cd_adm1
)
UPDATE main.adm2 a2
SET adm1_code=c.adm1_code
FROM c
WHERE a2.cd_adm2=c.cd_adm2
/*, d AS(
SELECT cd_geounit, count(*) nb,
    count(*) FILTER (WHERE match_1_2='adm1') nb_1,
    count(*) FILTER (WHERE match_1_2='adm2') nb_2

FROM c
GROUP BY cd_geounit
ORDER BY cd_geounit,count(*) DESC
)
SELECT *
FROM d
WHERE nb_1<>0 AND nb_2<>0
*/
;


-- For the ne polygons which have not yet been match, we search a purely geographic match with a similarity > .8

WITH a AS(
SELECT adm1_code, ST_Area(geom) ne_area, geom ne_geom
FROM ne.ne_10m_admin_1_states_provinces
LEFT JOIN main.adm1 a1 USING (adm1_code)
LEFT JOIN main.adm2 a2 USING (adm1_code)
WHERE a1.adm1_code IS NULL AND a2.adm1_code IS NULL
), a1 AS(
SELECT cd_adm1, ST_Area(the_geom) a1_area, the_geom a1_geom
FROM main.adm1
WHERE adm1_code IS NULL
), a2 AS(
SELECT cd_adm2, ST_Area(the_geom) a2_area, the_geom a2_geom
FROM main.adm2
WHERE adm1_code IS NULL
), b AS(
SELECT adm1_code, cd_adm1,NULL cd_adm2, a1_area area_adm, ne_area, ST_Area(ST_Intersection(ne_geom,a1_geom)) common_area
FROM a
LEFT JOIN a1 ON ST_Intersects(a1_geom,ne_geom)
UNION
SELECT adm1_code, NULL cd_adm1,cd_adm2, a2_area area_adm, ne_area, ST_Area(ST_Intersection(ne_geom,a2_geom)) common_area
FROM a
LEFT JOIN a2 ON ST_Intersects(a2_geom,ne_geom)
), best_match AS(
SELECT DISTINCT ON (adm1_code) adm1_code,cd_adm1,cd_adm2,(common_area/area_adm)*(common_area/ne_area) similarity
FROM b
WHERE (common_area/area_adm)*(common_area/ne_area)>.8
ORDER BY adm1_code,(common_area/area_adm)*(common_area/ne_area) DESC
), upd_a1 AS(
UPDATE main.adm1 a1
SET adm1_code=bm.adm1_code
FROM best_match bm
WHERE bm.cd_adm1=a1.cd_adm1 AND a1.adm1_code IS NULL
RETURNING bm.adm1_code,a1.cd_adm1
), upd_a2 AS(
UPDATE main.adm2 a2
SET adm1_code=bm.adm1_code
FROM best_match bm
WHERE bm.cd_adm2=a2.cd_adm2 AND a2.adm1_code IS NULL
RETURNING bm.adm1_code,a2.cd_adm2
)
SELECT *
FROM upd_a1
FULL OUTER JOIN upd_a2 USING(adm1_code)
;



-- We transfer the adm1_code from ne in cases of equivalence from adm1 and adm2
WITH a AS(
SELECT a1.cd_adm1,a2.cd_adm2,COALESCE(a1.adm1_code,a2.adm1_code) adm1_code
FROM main.adm1 a1
JOIN main.adm2 a2 ON a1.equi_adm2=a2.cd_adm2 OR a2.equi_adm1=a1.cd_adm1
WHERE a1.adm1_code IS NOT NULL OR a2.adm1_code IS NOT NULL
), b AS(
UPDATE main.adm1 a1
SET adm1_code=a.adm1_code
FROM a
WHERE a1.adm1_code IS NULL AND a.cd_adm1=a1.cd_adm1
)
UPDATE main.adm2 a2
SET adm1_code=a.adm1_code
FROM a
WHERE a2.adm1_code IS NULL AND a.cd_adm2=a2.cd_adm2
;

-------------------------------------------
------Admin 2------------------------------
-------------------------------------------

-- naturalearth names


CREATE TABLE tmp.ne_adm2_name AS(
WITH a AS(
SELECT name string, 'naturalearth' orig, NULL name_type, 'en' cd_lang, adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT UNNEST(STRING_TO_ARRAY(name_alt,', ')), 'naturalearth', 'alternate', NULL, adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_en, 'naturalearth', NULL, 'en', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_fr, 'naturalearth', NULL, 'fr', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_pt, 'naturalearth', NULL, 'pt', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_es, 'naturalearth', NULL, 'es', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_de, 'naturalearth', NULL, 'de', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_nl, 'naturalearth', NULL, 'nl', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
UNION
SELECT name_it, 'naturalearth', NULL, 'it', adm2_code
FROM ne.ne_10m_admin_2_counties
WHERE adm2_code IS NOT NULL
)
SELECT DISTINCT *
FROM a
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
);

-- Here the relations are much simpler to make because naturalearth have only included the counties and parishes from USA, which should all be in adm2
WITH a AS(
SELECT a2.adm2,a2.cd_adm2, n2.name,n2.adm2_code,a2.the_geom,n2.geom
FROM tmp.gadm_adm2_name gn
JOIN main.adm2 a2 USING(cd_adm2)
JOIN main.adm0_geounit a0 USING(cd_geounit)
JOIN tmp.ne_adm2_name nn ON a0.sovereign='USA' AND UNACCENT(LOWER(gn.string))= UNACCENT(LOWER(nn.string))
JOIN ne.ne_10m_admin_2_counties n2 ON nn.adm2_code=n2.adm2_code
), b AS(
SELECT DISTINCT ON (cd_adm2,adm2) cd_adm2, adm2, adm2_code, name,
ST_Area(the_geom) g_area,ST_Area(geom) n_area, ST_Area(ST_Intersection(the_geom,geom)) common_area, ST_Distance(the_geom,geom,true)/1000 distance_km
FROM a
), c AS(
SELECT cd_adm2, adm2_code,adm2, name, (common_area/n_area) * (common_area/g_area) similarity,distance_km
FROM b
ORDER BY similarity
), d AS(
SELECT DISTINCT ON (adm2_code) adm2_code,cd_adm2,similarity,distance_km
FROM c
WHERE similarity > 0.7
ORDER BY adm2_code, similarity DESC, distance_km ASC
)
UPDATE main.adm2 a2
SET adm2_code=d.adm2_code
FROM d
WHERE d.cd_adm2=a2.cd_adm2;


-- For those of ne for which names did not match, searching high geographic similarity
WITH a AS(
SELECT adm2_code, ST_Area(geom) n_area, geom
FROM ne.ne_10m_admin_2_counties
LEFT JOIN main.adm2 not_a2 USING(adm2_code)
WHERE not_a2.cd_adm2 IS NULL
), b AS(
SELECT cd_adm2, ST_area(the_geom) a2_area, the_geom
FROM main.adm2
WHERE adm2_code IS NULL
), c AS(
SELECT adm2_code,cd_adm2, (ST_area(ST_Intersection(geom, the_geom))/a2_area) * (ST_area(ST_Intersection(geom, the_geom))/n_area) similarity
FROM a
JOIN b ON ST_intersects(geom,the_geom)
), d AS(
SELECT *
FROM c
WHERE similarity>0.8
)
UPDATE main.adm2 a2
SET adm2_code=d.adm2_code
FROM d
WHERE a2.cd_adm2=d.cd_adm2
;
