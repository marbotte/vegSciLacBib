CREATE SCHEMA IF NOT EXISTS tmp AUTHORIZATION CURRENT_USER;

CREATE TABLE tmp.rel_adm0_calc AS(
WITH a0 AS(
  SELECT gid_0,ST_Area(geom) area_g0
  FROM gadm.gadm_adm0
)
,au AS(
  SELECT cd_geounit,ST_area(the_geom) area_gu
  FROM main.adm0_geounit
)
,b AS(
  SELECT gid_0,name_0,cd_geounit,geounit, area_g0, area_gu, ST_Area(ST_Intersection(g0.geom,gu.the_geom)) common_area
  FROM gadm.gadm_adm0 g0
  JOIN main.adm0_geounit gu ON ST_intersects(g0.geom,gu.the_geom)
  LEFT JOIN a0 USING (gid_0)
  LEFT JOIN au USING (cd_geounit)
)
SELECT gid_0,name_0,cd_geounit,geounit,
  CASE
    WHEN common_area/area_g0 > 0.9 AND common_area/area_gu > 0.9 THEN 'equivalent'
    WHEN common_area/area_g0 > 0.7 AND common_area/area_gu < 0.9 THEN 'g0_in_gu'
    WHEN common_area/area_g0 < 0.9 AND common_area/area_gu > 0.7 THEN 'gu_in_g0'
    ELSE NULL
  END type_rel_geog, area_g0,area_gu,common_area, common_area/area_g0 prop_g0,  common_area/area_gu prop_gu
FROM b
)
;
-- Then we add rows for the gid_0 which are not yet in the table (no intersection with the other table)

INSERT INTO tmp.rel_adm0_calc(gid_0,name_0,area_g0)
SELECT gid_0,name_0,ST_area(geom)
FROM gadm.gadm_adm0
WHERE NOT gid_0 IN (SELECT gid_0 FROM tmp.rel_adm0_calc);

-- Then we add rows for the geounits which are not yet in the table (no intersection with the other table)

INSERT INTO tmp.rel_adm0_calc(cd_geounit,geounit,area_g0)
SELECT cd_geounit,geounit,ST_area(the_geom)
FROM main.adm0_geounit
WHERE NOT cd_geounit IN (SELECT cd_geounit FROM tmp.rel_adm0_calc);

/* Then we add a column to check whether there are name matches between tables, when:
1. polygons intersect
2. polygon have no intersection
*/

ALTER TABLE tmp.rel_adm0_calc ADD COLUMN type_rel_name text;

WITH a AS(
SELECT gid_0, cd_geounit,name_0,string
FROM tmp.rel_adm0_calc ra0
LEFT JOIN main.adm0_names a0n USING (cd_geounit)
LEFT JOIN gadm.gadm_adm0 ga0 USING (gid_0,name_0)
UNION
SELECT gid_0,cd_geounit,UNNEST(varname_0),string
FROM tmp.rel_adm0_calc ra0
LEFT JOIN main.adm0_names a0n USING (cd_geounit)
LEFT JOIN gadm.gadm_adm0 ga0 USING (gid_0,name_0)
), b AS(
SELECT gid_0, cd_geounit, bool_or(name_0=string) equi
FROM a
GROUP BY gid_0, cd_geounit
)
UPDATE tmp.rel_adm0_calc ra0
SET type_rel_name='equivalent'
FROM b
WHERE b.equi=true AND b.gid_0=ra0.gid_0 AND b.cd_geounit=ra0.cd_geounit;

WITH a AS(
SELECT ga0.gid_0, cd_geounit,ga0.name_0 testname,string,ga0.name_0 refname
FROM tmp.rel_adm0_calc ra0
LEFT JOIN main.adm0_names a0n USING (cd_geounit)
CROSS JOIN gadm.gadm_adm0 ga0
WHERE ra0.name_0 IS NULL AND NOT ga0.name_0 IN (SELECT name_0 FROM tmp.rel_adm0_calc WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent')
UNION
SELECT ga0.gid_0,cd_geounit,UNNEST(ga0.varname_0) testname ,string, ga0.name_0 refname
FROM tmp.rel_adm0_calc ra0
LEFT JOIN main.adm0_names a0n USING (cd_geounit)
CROSS JOIN gadm.gadm_adm0 ga0
WHERE ra0.name_0 IS NULL AND NOT ga0.name_0 IN (SELECT name_0 FROM tmp.rel_adm0_calc WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent')
)
UPDATE tmp.rel_adm0_calc ra0c
SET gid_0=a.gid_0, name_0=a.refname
FROM a
WHERE a.testname=a.string AND a.gid_0=ra0c.gid_0 AND a.cd_geounit=ra0c.cd_geounit;

-----------------------------------------------
--- !!!!!!!!!!!!!!CHECK THAT!!!!!!!!!!!!!!!!!!!
-----------------------------------------------
-- Here are the problems, and some proposed resolutions:
WITH same_sovereign AS(
SELECT gid_0,cd_geounit,bool_or(g0.sovereign=string) same_sovereign
FROM tmp.rel_adm0_calc
LEFT JOIN gadm.gadm_adm0 g0 USING (gid_0,name_0)
LEFT JOIN main.adm0_geounit gu USING (cd_geounit,geounit)
LEFT JOIN main.country_names cn ON gu.sovereign=cn.cd_country
GROUP BY gid_0,cd_geounit
),
a AS(
SELECT gid_0,name_0,
  ARRAY_AGG(geounit) FILTER (WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent') equi,
  ARRAY_AGG(geounit) FILTER (WHERE type_rel_geog='g0_in_gu' AND type_rel_name IS NULL) contained_in,
  ARRAY_AGG(geounit) FILTER (WHERE type_rel_geog='gu_in_g0' AND type_rel_name IS NULL) contains,
  ARRAY_AGG(geounit ORDER BY prop_g0 DESC) FILTER (WHERE cd_geounit IS NOT NULL) intersects,
  ARRAY_AGG(geounit ORDER BY prop_g0 DESC) FILTER (WHERE cd_geounit IS NOT NULL AND same_sovereign) intersects_same_sovereign

FROM tmp.rel_adm0_calc
LEFT JOIN same_sovereign USING (gid_0,cd_geounit)
GROUP BY gid_0,name_0
)
,b AS(
SELECT gid_0,name_0,equi,contained_in,contains,intersects,intersects_same_sovereign,
  CASE
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects,1)=1) THEN intersects
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)=1) THEN intersects_same_sovereign
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)>1) THEN ARRAY[intersects_same_sovereign[1]]
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND intersects_same_sovereign IS NULL AND intersects IS NOT NULL THEN ARRAY[intersects[1]]
  END resol_contained_in
FROM a
WHERE gid_0 IS NOT NULL
)
SELECT *
FROM b
WHERE
    ARRAY_LENGTH(equi,1)>1 OR
    ARRAY_LENGTH(contained_in,1)>1 OR
    (equi IS NULL AND
        ((contained_in IS NULL AND contains IS NULL)
        OR ARRAY_LENGTH(contained_in,1)<>1
        OR ARRAY_LENGTH(contains,1)=0))
;

-----------------------------------------------
--- !!!!!!!!!!!!!!CHECK THAT!!!!!!!!!!!!!!!!!!!
-----------------------------------------------
-- Here are the problems, and some proposed resolutions:

WITH same_sovereign AS(
SELECT gid_0,cd_geounit,bool_or(g0.sovereign=string) same_sovereign
FROM tmp.rel_adm0_calc
LEFT JOIN gadm.gadm_adm0 g0 USING (gid_0,name_0)
LEFT JOIN main.adm0_geounit gu USING (cd_geounit,geounit)
LEFT JOIN main.country_names cn ON gu.sovereign=cn.cd_country
GROUP BY gid_0,cd_geounit
),
a AS(
SELECT cd_geounit,geounit,
  ARRAY_AGG(name_0) FILTER (WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent') equi,
  ARRAY_AGG(name_0) FILTER (WHERE type_rel_geog='gu_in_g0' AND type_rel_name IS NULL) contained_in,
  ARRAY_AGG(name_0) FILTER (WHERE type_rel_geog='g0_in_gu' AND type_rel_name IS NULL) contains,
  ARRAY_AGG(name_0 ORDER BY prop_gu DESC) FILTER (WHERE gid_0 IS NOT NULL) intersects,
  ARRAY_AGG(name_0 ORDER BY prop_gu DESC) FILTER (WHERE gid_0 IS NOT NULL AND same_sovereign) intersects_same_sovereign

FROM tmp.rel_adm0_calc
LEFT JOIN same_sovereign USING (gid_0,cd_geounit)
GROUP BY cd_geounit,geounit
)
,b AS(
SELECT cd_geounit,geounit,equi,contained_in,contains,intersects,intersects_same_sovereign,
  CASE
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects,1)=1) THEN intersects
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)=1) THEN intersects_same_sovereign
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)>1) THEN ARRAY[intersects_same_sovereign[1]]
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND intersects_same_sovereign IS NULL AND intersects IS NOT NULL THEN ARRAY[intersects[1]]
  END resol_contained_in
FROM a
WHERE cd_geounit IS NOT NULL
)
SELECT *
FROM b
WHERE
    ARRAY_LENGTH(equi,1)>1 OR
    ARRAY_LENGTH(contained_in,1)>1 OR
    (equi IS NULL AND
        ((contained_in IS NULL AND contains IS NULL)
        OR ARRAY_LENGTH(contained_in,1)<>1
        OR ARRAY_LENGTH(contains,1)=0))
;

-- If you revised the 2 previous suggestions and agrees, you may run the following code, it will repeat the same treatment to determine in which geounit goes each gid_0, or which geounits contains it
CREATE TABLE gadm.adm0_to_geounit
(
    gid_0 CHAR(3) PRIMARY KEY REFERENCES gadm.gadm_adm0,
    included_in CHAR(3) REFERENCES main.adm0_geounit,
    equivalent boolean,
    includes CHAR(3)[]
);

INSERT INTO gadm.adm0_to_geounit
WITH same_sovereign AS(
SELECT gid_0,cd_geounit,bool_or(g0.sovereign=string) same_sovereign
FROM tmp.rel_adm0_calc
LEFT JOIN gadm.gadm_adm0 g0 USING (gid_0,name_0)
LEFT JOIN main.adm0_geounit gu USING (cd_geounit,geounit)
LEFT JOIN main.country_names cn ON gu.sovereign=cn.cd_country
GROUP BY gid_0,cd_geounit
),-- Work from gid_0
a AS(
SELECT gid_0,name_0,
  ARRAY_AGG(cd_geounit) FILTER (WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent') equi,
  ARRAY_AGG(cd_geounit) FILTER (WHERE type_rel_geog='g0_in_gu' AND type_rel_name IS NULL) contained_in,
  ARRAY_AGG(cd_geounit) FILTER (WHERE type_rel_geog='gu_in_g0' AND type_rel_name IS NULL) contains,
  ARRAY_AGG(cd_geounit ORDER BY prop_g0 DESC) FILTER (WHERE cd_geounit IS NOT NULL) intersects,
  ARRAY_AGG(cd_geounit ORDER BY prop_g0 DESC) FILTER (WHERE cd_geounit IS NOT NULL AND same_sovereign) intersects_same_sovereign

FROM tmp.rel_adm0_calc
LEFT JOIN same_sovereign USING (gid_0,cd_geounit)
GROUP BY gid_0,name_0
)
,b AS(
SELECT gid_0,name_0,equi,
  CASE
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects,1)=1) THEN intersects
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)=1) THEN intersects_same_sovereign
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)>1) THEN ARRAY[intersects_same_sovereign[1]]
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND intersects_same_sovereign IS NULL AND intersects IS NOT NULL THEN ARRAY[intersects[1]]
    ELSE contained_in
  END contained_in,contains
FROM a
WHERE gid_0 IS NOT NULL
-- Work from cd_geounit
),a2 AS(
SELECT cd_geounit,geounit,
  ARRAY_AGG(gid_0) FILTER (WHERE type_rel_geog='equivalent' OR type_rel_name='equivalent') equi,
  ARRAY_AGG(gid_0) FILTER (WHERE type_rel_geog='gu_in_g0' AND type_rel_name IS NULL) contained_in,
  ARRAY_AGG(gid_0) FILTER (WHERE type_rel_geog='g0_in_gu' AND type_rel_name IS NULL) contains,
  ARRAY_AGG(gid_0 ORDER BY prop_gu DESC) FILTER (WHERE gid_0 IS NOT NULL) intersects,
  ARRAY_AGG(gid_0 ORDER BY prop_gu DESC) FILTER (WHERE gid_0 IS NOT NULL AND same_sovereign) intersects_same_sovereign
FROM tmp.rel_adm0_calc
LEFT JOIN same_sovereign USING (gid_0,cd_geounit)
GROUP BY cd_geounit,geounit
)
,b2 AS(
SELECT cd_geounit,geounit,equi,
  CASE
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects,1)=1) THEN intersects
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)=1) THEN intersects_same_sovereign
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND (ARRAY_LENGTH(intersects_same_sovereign,1)>1) THEN ARRAY[intersects_same_sovereign[1]]
    WHEN contained_in IS NULL AND equi IS NULL AND contains IS NULL AND intersects_same_sovereign IS NULL AND intersects IS NOT NULL THEN ARRAY[intersects[1]]
    ELSE contained_in
  END contained_in,contains
FROM a2
WHERE cd_geounit IS NOT NULL
), contained_in AS(
SELECT gid_0,
    CASE
        WHEN equi IS NOT NULL THEN equi[1]
        WHEN contained_in IS NOT NULL THEN contained_in[1]
    END contained_in,
    CASE
        WHEN equi IS NOT NULL THEN true
        WHEN contained_in IS NOT NULL THEN false
    END equivalent
FROM b
WHERE equi IS NOT NULL OR contained_in IS NOT NULL
UNION
SELECT equi[1],cd_geounit,true
FROM b2
WHERE equi IS NOT NULL
UNION
SELECT UNNEST(contains),cd_geounit,false
FROM b2
WHERE equi IS NULL
), contains_tab AS(
SELECT gid_0,ARRAY_AGG(DISTINCT contains)
FROM
    (SELECT gid_0,UNNEST(contains) contains FROM b WHERE contains IS NOT NULL
    UNION
    SELECT contained_in[1], cd_geounit FROM b2 WHERE contained_in IS NOT NULL) tab_contains
GROUP BY gid_0
)
SELECT *
FROM contained_in
FULL OUTER JOIN contains_tab USING (gid_0);

