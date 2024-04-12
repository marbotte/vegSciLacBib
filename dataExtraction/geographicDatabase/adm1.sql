--------------------------------------
-- Relationship geounit->gadm adm1----
--------------------------------------
CREATE TABLE tmp.equi_gu_to_adm1 AS(
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
),b AS(
SELECT DISTINCT gid_0,cd_geounit,geounit,string,the_geom
FROM a
LEFT JOIN main.adm0_names USING (cd_geounit)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
),c AS(
SELECT /*b.gid_0,*/b.cd_geounit,geounit, --ARRAY_AGG(DISTINCT b.string),
    ARRAY_AGG(DISTINCT g1.gid_1) FILTER (WHERE g1.gid_1 IS NOT NULL) gid_1, ARRAY_AGG(DISTINCT g1.name_1) FILTER (WHERE g1.gid_1 IS NOT NULL) name_1
FROM
b
LEFT JOIN gadm.gadm_adm1 g1 ON (g1.gid_0 IS NULL OR b.gid_0=g1.gid_0) AND (string ILIKE name_1 OR string ILIKE ANY(varname_1)) AND ST_DWithin(the_geom,g1.geom,2)
GROUP BY /*b.gid_0,*/b.cd_geounit,geounit
)
SELECT cd_geounit,gid_1[1] 
FROM c
WHERE
    /*ARRAY_LENGTH(gid_1,1)>1 OR
    ARRAY_LENGTH(gid_2,1)>1 OR
    ARRAY_LENGTH(gid_3,1)>1 OR
    ARRAY_LENGTH(gid_4,1)>1 OR
    ARRAY_LENGTH(gid_5,1)>1 */
    gid_1 IS NOT NULL AND ARRAY_LENGTH(gid_1,1)=1
)
;

-- After checking manually, we can see that everything is fine except when the 2 polygons don't intersect

WITH a AS(SELECT cd_geounit,gid_1,gu.the_geom,g1.geom FROM tmp.equi_gu_to_adm1 gcc LEFT JOIN main.adm0_geounit gu USING (cd_geounit)LEFT JOIN gadm.gadm_adm1 g1 USING(gid_1))
DELETE FROM tmp.equi_gu_to_adm1 gcc USING a WHERE gcc.cd_geounit=a.cd_geounit AND gcc.gid_1=a.gid_1 AND NOT ST_Intersects(geom,the_geom);

-- Now we check the cases where the names might be different but the polygons are very similar:
INSERT INTO tmp.equi_gu_to_adm1
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
)
,b AS(
SELECT DISTINCT a.gid_0,cd_geounit,
    g1.gid_1,
    gu.the_geom,
    g1.geom g1_geom
FROM a
LEFT JOIN main.adm0_geounit gu USING (cd_geounit)
LEFT JOIN gadm.gadm_adm1 g1 ON ST_Intersects(gu.the_geom,g1.geom)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1) 
	AND gid_1 IS NOT NULL
),c AS(
SELECT b.gid_0,cd_geounit,gid_1,(ST_AREA(ST_Intersection(the_geom,g1_geom))/ST_AREA(g1_geom)) * (ST_AREA(ST_Intersection(the_geom,g1_geom))/ST_AREA(the_geom)) similarity
FROM b
ORDER BY cd_geounit,similarity DESC
),d AS(
SELECT gid_0,cd_geounit,
    ARRAY_AGG(gid_1 ORDER BY similarity DESC) gid_1, MAX(similarity)  simCorres
FROM c
WHERE similarity>0.15
GROUP BY gid_0,cd_geounit
)
SELECT cd_geounit,gid_1[1]
FROM d
WHERE gid_1 IS NOT NULL
	AND simCorres>0.56 AND ARRAY_LENGTH(gid_1,1)=1
;



--------------------------------------
-- Relationship geounit->gadm adm2----
--------------------------------------

CREATE TABLE tmp.equi_gu_to_adm2 AS(
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
),b AS(
SELECT DISTINCT gid_0,cd_geounit,geounit,string,the_geom
FROM a
LEFT JOIN main.adm0_names USING (cd_geounit)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1)
),c AS(
SELECT /*b.gid_0,*/b.cd_geounit,geounit, --ARRAY_AGG(DISTINCT b.string),
    ARRAY_AGG(DISTINCT g2.gid_2) FILTER (WHERE g2.gid_2 IS NOT NULL) gid_2, ARRAY_AGG(DISTINCT g2.name_2) FILTER (WHERE g2.gid_2 IS NOT NULL) name_2
FROM
b
LEFT JOIN gadm.gadm_adm2 g2 ON  (string ILIKE name_2 OR string ILIKE ANY(varname_2)) AND ST_DWithin(the_geom,g2.geom,1)
GROUP BY /*b.gid_0,*/b.cd_geounit,geounit
)
SELECT cd_geounit,gid_2[1]
FROM c
WHERE
    /*ARRAY_LENGTH(gid_2,2)>2 OR
    ARRAY_LENGTH(gid_2,2)>2 OR
    ARRAY_LENGTH(gid_3,2)>2 OR
    ARRAY_LENGTH(gid_4,2)>2 OR
    ARRAY_LENGTH(gid_5,2)>2 */
    gid_2 IS NOT NULL AND ARRAY_LENGTH(gid_2,1)=1
)
;

-- After checking manually, we can see that everything is fine 


WITH a AS(SELECT cd_geounit,gid_2,gu.the_geom,g2.geom FROM tmp.equi_gu_to_adm2 gcc LEFT JOIN main.adm0_geounit gu USING (cd_geounit)LEFT JOIN gadm.gadm_adm2 g2 USING(gid_2))
DELETE FROM tmp.equi_gu_to_adm2 gcc USING a WHERE gcc.cd_geounit=a.cd_geounit AND gcc.gid_2=a.gid_2 AND NOT ST_Intersects(geom,the_geom);

-- Now we check the cases where the names might be different but the polygons are very similar:
INSERT INTO tmp.equi_gu_to_adm2
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
)
,b AS(
SELECT DISTINCT a.gid_0,cd_geounit,
    g2.gid_2,
    gu.the_geom,
    g2.geom g2_geom
FROM a
LEFT JOIN main.adm0_geounit gu USING (cd_geounit)
LEFT JOIN gadm.gadm_adm2 g2 ON ST_Intersects(gu.the_geom,g2.geom)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm1 ) 
	AND gid_2 IS NOT NULL
),c AS(
SELECT b.gid_0,cd_geounit,gid_2,(ST_AREA(ST_Intersection(the_geom,g2_geom))/ST_AREA(g2_geom)) * (ST_AREA(ST_Intersection(the_geom,g2_geom))/ST_AREA(the_geom)) similarity
FROM b
ORDER BY cd_geounit,similarity DESC
),d AS(
SELECT gid_0,cd_geounit,
    ARRAY_AGG(gid_2 ORDER BY similarity DESC) gid_2, MAX(similarity)  simCorres
FROM c
WHERE similarity>0.15
GROUP BY gid_0,cd_geounit
)
SELECT cd_geounit,gid_2[1]
FROM d
WHERE gid_2 IS NOT NULL
	AND simCorres>0.56 AND ARRAY_LENGTH(gid_2,1)=1
;



--------------------------------------
-- Relationship geounit->gadm adm3----
--------------------------------------

CREATE TABLE tmp.equi_gu_to_adm3 AS(
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
),b AS(
SELECT DISTINCT gid_0,cd_geounit,geounit,string,the_geom
FROM a
LEFT JOIN main.adm0_names USING (cd_geounit)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2)
),c AS(
SELECT /*b.gid_0,*/b.cd_geounit,geounit, --ARRAY_AGG(DISTINCT b.string),
    ARRAY_AGG(DISTINCT g3.gid_3) FILTER (WHERE g3.gid_3 IS NOT NULL) gid_3, ARRAY_AGG(DISTINCT g3.name_3) FILTER (WHERE g3.gid_3 IS NOT NULL) name_3
FROM
b
LEFT JOIN gadm.gadm_adm3 g3 ON  (string ILIKE name_3 OR string ILIKE ANY(varname_3)) AND ST_DWithin(the_geom,g3.geom,1)
GROUP BY /*b.gid_0,*/b.cd_geounit,geounit
)
SELECT cd_geounit,gid_3[1]
FROM c
WHERE
    /*ARRAY_LENGTH(gid_3,3)>3 OR
    ARRAY_LENGTH(gid_3,3)>3 OR
    ARRAY_LENGTH(gid_3,3)>3 OR
    ARRAY_LENGTH(gid_4,3)>3 OR
    ARRAY_LENGTH(gid_5,3)>3 */
    gid_3 IS NOT NULL AND ARRAY_LENGTH(gid_3,1)=1
)
;

-- After checking manually, we can see that everything is fine 


WITH a AS(SELECT cd_geounit,gid_3,gu.the_geom,g3.geom FROM tmp.equi_gu_to_adm3 gcc LEFT JOIN main.adm0_geounit gu USING (cd_geounit)LEFT JOIN gadm.gadm_adm3 g3 USING(gid_3))
DELETE FROM tmp.equi_gu_to_adm3 gcc USING a WHERE gcc.cd_geounit=a.cd_geounit AND gcc.gid_3=a.gid_3 AND NOT ST_Intersects(geom,the_geom);

-- Now we check the cases where the names might be different but the polygons are very similar:
INSERT INTO tmp.equi_gu_to_adm3
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
)
,b AS(
SELECT DISTINCT a.gid_0,cd_geounit,
    g3.gid_3,
    gu.the_geom,
    g3.geom g3_geom
FROM a
LEFT JOIN main.adm0_geounit gu USING (cd_geounit)
LEFT JOIN gadm.gadm_adm3 g3 ON ST_Intersects(gu.the_geom,g3.geom)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm3)
	AND gid_3 IS NOT NULL
),c AS(
SELECT b.gid_0,cd_geounit,gid_3,(ST_AREA(ST_Intersection(the_geom,g3_geom))/ST_AREA(g3_geom)) * (ST_AREA(ST_Intersection(the_geom,g3_geom))/ST_AREA(the_geom)) similarity
FROM b
ORDER BY cd_geounit,similarity DESC
),d AS(
SELECT gid_0,cd_geounit,
    ARRAY_AGG(gid_3 ORDER BY similarity DESC) gid_3, MAX(similarity)  simCorres
FROM c
WHERE similarity>0.15
GROUP BY gid_0,cd_geounit
)
SELECT cd_geounit,gid_3[1]
FROM d
WHERE gid_3 IS NOT NULL
	AND simCorres>0.56 AND ARRAY_LENGTH(gid_3,1)=1
;



--------------------------------------
-- Relationship geounit->gadm adm4----
--------------------------------------

CREATE TABLE tmp.equi_gu_to_adm4 AS(
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
),b AS(
SELECT DISTINCT gid_0,cd_geounit,geounit,string,the_geom
FROM a
LEFT JOIN main.adm0_names USING (cd_geounit)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm3)
),c AS(
SELECT /*b.gid_0,*/b.cd_geounit,geounit, --ARRAY_AGG(DISTINCT b.string),
    ARRAY_AGG(DISTINCT g4.gid_4) FILTER (WHERE g4.gid_4 IS NOT NULL) gid_4, ARRAY_AGG(DISTINCT g4.name_4) FILTER (WHERE g4.gid_4 IS NOT NULL) name_4
FROM
b
LEFT JOIN gadm.gadm_adm4 g4 ON  (string ILIKE name_4 OR string ILIKE ANY(varname_4)) AND ST_DWithin(the_geom,g4.geom,1)
GROUP BY /*b.gid_0,*/b.cd_geounit,geounit
)
SELECT cd_geounit,gid_4[1]
FROM c
WHERE
    /*ARRAY_LENGTH(gid_4,4)>4 OR
    ARRAY_LENGTH(gid_4,4)>4 OR
    ARRAY_LENGTH(gid_4,4)>4 OR
    ARRAY_LENGTH(gid_4,4)>4 OR
    ARRAY_LENGTH(gid_5,4)>4 */
    gid_4 IS NOT NULL AND ARRAY_LENGTH(gid_4,1)=1
)
;

-- After checking manually, we can see that everything is fine 


WITH a AS(SELECT cd_geounit,gid_4,gu.the_geom,g4.geom FROM tmp.equi_gu_to_adm4 gcc LEFT JOIN main.adm0_geounit gu USING (cd_geounit)LEFT JOIN gadm.gadm_adm4 g4 USING(gid_4))
DELETE FROM tmp.equi_gu_to_adm4 gcc USING a WHERE gcc.cd_geounit=a.cd_geounit AND gcc.gid_4=a.gid_4 AND NOT ST_Intersects(geom,the_geom);

-- Now we check the cases where the names might be different but the polygons are very similar:
INSERT INTO tmp.equi_gu_to_adm4
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
)
,b AS(
SELECT DISTINCT a.gid_0,cd_geounit,
    g4.gid_4,
    gu.the_geom,
    g4.geom g4_geom
FROM a
LEFT JOIN main.adm0_geounit gu USING (cd_geounit)
LEFT JOIN gadm.gadm_adm4 g4 ON ST_Intersects(gu.the_geom,g4.geom)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm4 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm3 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm1 ) 
	AND gid_4 IS NOT NULL
),c AS(
SELECT b.gid_0,cd_geounit,gid_4,(ST_AREA(ST_Intersection(the_geom,g4_geom))/ST_AREA(g4_geom)) * (ST_AREA(ST_Intersection(the_geom,g4_geom))/ST_AREA(the_geom)) similarity
FROM b
ORDER BY cd_geounit,similarity DESC
),d AS(
SELECT gid_0,cd_geounit,
    ARRAY_AGG(gid_4 ORDER BY similarity DESC) gid_4, MAX(similarity)  simCorres
FROM c
WHERE similarity>0.15
GROUP BY gid_0,cd_geounit
)
SELECT cd_geounit,gid_4[1]
FROM d
WHERE gid_4 IS NOT NULL
	AND simCorres>0.56 AND ARRAY_LENGTH(gid_4,1)=1
;



--------------------------------------
-- Relationship geounit->gadm adm5----
--------------------------------------

CREATE TABLE tmp.equi_gu_to_adm5 AS(
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
),b AS(
SELECT DISTINCT gid_0,cd_geounit,geounit,string,the_geom
FROM a
LEFT JOIN main.adm0_names USING (cd_geounit)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm1 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm3 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm4)
),c AS(
SELECT /*b.gid_0,*/b.cd_geounit,geounit, --ARRAY_AGG(DISTINCT b.string),
    ARRAY_AGG(DISTINCT g5.gid_5) FILTER (WHERE g5.gid_5 IS NOT NULL) gid_5, ARRAY_AGG(DISTINCT g5.name_5) FILTER (WHERE g5.gid_5 IS NOT NULL) name_5
FROM
b
LEFT JOIN gadm.gadm_adm5 g5 ON  (string ILIKE name_5) AND ST_DWithin(the_geom,g5.geom,1)
GROUP BY /*b.gid_0,*/b.cd_geounit,geounit
)
SELECT cd_geounit,gid_5[1]
FROM c
WHERE
    /*ARRAY_LENGTH(gid_5,5)>5 OR
    ARRAY_LENGTH(gid_5,5)>5 OR
    ARRAY_LENGTH(gid_5,5)>5 OR
    ARRAY_LENGTH(gid_5,5)>5 OR
    ARRAY_LENGTH(gid_5,5)>5 */
    gid_5 IS NOT NULL AND ARRAY_LENGTH(gid_5,1)=1
)
;

-- After checking manually, we can see that everything is fine 


WITH a AS(SELECT cd_geounit,gid_5,gu.the_geom,g5.geom FROM tmp.equi_gu_to_adm5 gcc LEFT JOIN main.adm0_geounit gu USING (cd_geounit)LEFT JOIN gadm.gadm_adm5 g5 USING(gid_5))
DELETE FROM tmp.equi_gu_to_adm5 gcc USING a WHERE gcc.cd_geounit=a.cd_geounit AND gcc.gid_5=a.gid_5 AND NOT ST_Intersects(geom,the_geom);

-- Now we check the cases where the names might be different but the polygons are very similar:
INSERT INTO tmp.equi_gu_to_adm5
WITH a AS(
SELECT gid_0, UNNEST(includes) cd_geounit
FROM gadm.adm0_to_geounit
WHERE includes IS NOT NULL
)
,b AS(
SELECT DISTINCT a.gid_0,cd_geounit,
    g5.gid_5,
    gu.the_geom,
    g5.geom g5_geom
FROM a
LEFT JOIN main.adm0_geounit gu USING (cd_geounit)
LEFT JOIN gadm.gadm_adm5 g5 ON ST_Intersects(gu.the_geom,g5.geom)
WHERE a.cd_geounit NOT IN (SELECT cd_geounit FROM tmp.equi_gu_to_adm5 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm4 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm3 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm2 UNION SELECT cd_geounit FROM tmp.equi_gu_to_adm1 ) 
	AND gid_5 IS NOT NULL
),c AS(
SELECT b.gid_0,cd_geounit,gid_5,(ST_AREA(ST_Intersection(the_geom,g5_geom))/ST_AREA(g5_geom)) * (ST_AREA(ST_Intersection(the_geom,g5_geom))/ST_AREA(the_geom)) similarity
FROM b
ORDER BY cd_geounit,similarity DESC
),d AS(
SELECT gid_0,cd_geounit,
    ARRAY_AGG(gid_5 ORDER BY similarity DESC) gid_5, MAX(similarity)  simCorres
FROM c
WHERE similarity>0.15
GROUP BY gid_0,cd_geounit
)
SELECT cd_geounit,gid_5[1]
FROM d
WHERE gid_5 IS NOT NULL
	AND simCorres>0.56 AND ARRAY_LENGTH(gid_5,1)=1
;

CREATE TABLE main.adm1
(
  cd_adm1 serial PRIMARY KEY,
  adm1 varchar(50),
  orig varchar(20),
  gid_1 varchar(10),-- unique key from gadm
  adm1_code varchar(10),-- unique key from naturalearth,
  cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit), -- parent geounit
  type_part varchar(70),
  type_part_verbatim text,
  cd_cat_part int,
  cd_continent int REFERENCES main.continent(cd_continent),
  cd_subregion int REFERENCES main.subregion(cd_subregion),
  cd_wb_region int REFERENCES main.wb_region(cd_wb_region),
  modified_gid_1 varchar(50),
  modification_gid_1 text,
  equi_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm2 int,
  equi_adm3 int,
  equi_adm4 int,
  equi_adm5 int,
  equi_muni int,
  UNIQUE(adm1,cd_geounit,type_part)

);
SELECT AddGeometryColumn('main','adm1','the_geom',4326,'MULTIPOLYGON',2);
CREATE INDEX main_adm1_the_geom_idx ON main.adm1 USING GIST(the_geom);
CREATE INDEX main_adm_1_cd_geounit_idx ON main.adm1(cd_geounit);
CREATE INDEX main_adm_1_cd_continent_idx ON main.adm1(cd_continent);
CREATE INDEX main_adm_1_cd_subregion_idx ON main.adm1(cd_subregion);
CREATE INDEX main_adm_1_cd_wb_region_idx ON main.adm1(cd_wb_region);
------------------
--- Simple case 1: gadm adm1 correspond to geounit
------------------
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit,type_part,type_part_verbatim,equi_geounit,the_geom)
SELECT name_1 adm1, 'gadm' orig, gid_1,cd_geounit, engtype_1 type_part, type_1 type_part_verbatim,  cd_geounit equi_geounit, ST_Multi(geom) the_geom
FROM tmp.equi_gu_to_adm1
LEFT JOIN gadm.gadm_adm1 USING (gid_1);

------------------
--- Simple case 2: gid_1 IN gid_0 IN geounit ==> gid_1 IN geounit
------------------

-- Unfortunately the case is not that simple:
-- there are some cases where various polygons have the same names, types and cd_geounit:
-- What we will do is to give the information from gadm for the biggest polygon
-- check the cases with:

/*
WITH a AS(
SELECT name_1 adm1, 'gadm' orig, gid_1,included_in cd_geounit, engtype_1 type_part, type_1 type_part_verbatim, ST_Multi(geom) the_geom
FROM gadm.gadm_adm1
LEFT JOIN gadm.adm0_to_geounit USING (gid_0)
WHERE gid_1 NOT IN (SELECT gid_1 FROM main.adm1)
 AND included_in IS NOT NULL
),b AS(
SELECT adm1,'gadm' orig, ARRAY_AGG(gid_1 ORDER BY ST_AREA(the_geom)) gid_1, cd_geounit, type_part, type_part_verbatim --, ST_Union(the_geom)
FROM a
GROUP BY adm1,cd_geounit,type_part,type_part_verbatim
HAVING count(*)>1
)
SELECT *
FROM b;
*/

-- We extract the information in the right format:
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit,type_part,type_part_verbatim,modified_gid_1,modification_gid_1,the_geom)
WITH a AS(
SELECT name_1 adm1, 'gadm' orig, gid_1,included_in cd_geounit, engtype_1 type_part, type_1 type_part_verbatim, geom the_geom
FROM gadm.gadm_adm1
LEFT JOIN gadm.adm0_to_geounit USING (gid_0)
WHERE gid_1 NOT IN (SELECT gid_1 FROM main.adm1)
 AND included_in IS NOT NULL
),b AS(
SELECT adm1,'gadm' orig, ARRAY_AGG(gid_1 ORDER BY ST_AREA(the_geom) DESC) gid_1, cd_geounit, type_part, type_part_verbatim, ST_Multi(ST_Union(the_geom)) the_geom
FROM a
GROUP BY adm1,cd_geounit,type_part,type_part_verbatim
HAVING count(*)>1
)
SELECT adm1, orig, gid_1[1],cd_geounit, type_part, type_part_verbatim,gid_1[1] modified_gid_1,
    'grouped with: {' || ARRAY_TO_STRING(gid_1[2:ARRAY_LENGTH(gid_1,1)],',') || '}' modification_gid_1,
    the_geom
FROM b;

-- Now the already included gid_1 are more complicated to extract
/*
SELECT gid_1
FROM main.adm1
UNION
SELECT UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 ~ 'grouped with: '
*/

-- Now we insert the simple cases!
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit,type_part,type_part_verbatim,the_geom)
WITH already AS(
SELECT gid_1
FROM main.adm1
UNION
SELECT UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 ~ 'grouped with: '
)
SELECT name_1 adm1, 'gadm' orig, gid_1,included_in cd_geounit, engtype_1 type_part, type_1 type_part_verbatim, ST_Multi(geom) the_geom
FROM gadm.gadm_adm1
LEFT JOIN gadm.adm0_to_geounit USING (gid_0)
WHERE gid_1 NOT IN (SELECT gid_1 FROM already) AND included_in IS NOT NULL;



-------------------------------------------------
------PARTICULAR CASES --------------------------
-------------------------------------------------

-- 1. we need to substract!
-- When cd_geounit is equivalent to a gid (gadm) of level 2 to 3 (there is no found equivalence to level 4 or 5 that does not correspond to higher levels) the gadm geometry should be sustracted
CREATE TABLE tmp.adm1_substract
AS (
SELECT *
FROM
    (SELECT cd_geounit,g2.gid_1 ref_gid_1,gid_2 to_sustract_gid_2
    FROM tmp.equi_gu_to_adm2
    LEFT JOIN gadm.gadm_adm2 g2 USING (gid_2)
    ) g2
FULL OUTER JOIN
    (SELECT cd_geounit,g2.gid_1 ref_gid_1,gid_3 to_sustract_gid_3 FROM tmp.equi_gu_to_adm3 LEFT JOIN gadm.gadm_adm3 USING (gid_3) LEFT JOIN gadm.gadm_adm2 g2 USING (gid_2) ) g3 USING (cd_geounit,ref_gid_1)
);

-- 2 possibilities: the polygons are already in adm1 or not

    -- already:
    -- 2 possibilities extract from gid 2 or from gid_3
        -- gid 2
        -- note that the case of ceuta y Melilla is particular: together they correspond to the totality of the gid_1
/*
SELECT ST_AREA(ST_Difference(ST_Multi(ST_Union(geom)),(SELECT the_geom FROM main.adm1 WHERE gid_1='ESP.7_1')))
FROM gadm.gadm_adm2
WHERE gid_2 IN ('ESP.7.1_1','ESP.7.2_1');
;
*/

-- managing Ceuta y Melilla
DELETE FROM main.adm1 WHERE gid_1='ESP.7_1';

-- Modifying the others
WITH a AS(
SELECT ref_gid_1 gid_1,to_sustract_gid_2 gid_2
FROM tmp.adm1_substract
WHERE ref_gid_1 IN (SELECT gid_1 FROM main.adm1) AND to_sustract_gid_2 IS NOT NULL
), b AS(
SELECT a.gid_1,a.gid_2,ST_MakeValid(ST_difference(a1.the_geom,g2.geom)) geom
FROM a
JOIN main.adm1 a1 USING (gid_1)
JOIN gadm.gadm_adm2 g2 USING (gid_2)
)
UPDATE main.adm1 a1
SET modified_gid_1=b.gid_1, modification_gid_1='Substracted from original gadm polygon: gadm gid_2 {'|| gid_2||'}', the_geom=b.geom
FROM b
WHERE a1.gid_1=b.gid_1;

-- Inserting the parts from gadm_adm2
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit, type_part, type_part_verbatim,modified_gid_1,modification_gid_1,equi_geounit, the_geom)
WITH a AS(
SELECT cd_geounit,ref_gid_1 gid_1,to_sustract_gid_2 gid_2
FROM tmp.adm1_substract
WHERE (ref_gid_1 IN (SELECT gid_1 FROM main.adm1) OR ref_gid_1='ESP.7_1') AND to_sustract_gid_2 IS NOT NULL
)
SELECT name_2 adm1, 'gadm' orig, NULL gid_1, cd_geounit, engtype_2 type_part, type_2 type_part_verbatim, a.gid_1 modified_gid_1, 'gid_2 part: {'|| gid_2||'}', cd_geounit, ST_Multi(g2.geom) the_geom
FROM a
JOIN gadm.gadm_adm2 g2 USING (gid_2)
;

        -- gid 3

-- Modifying the large part
WITH a AS(
SELECT ref_gid_1 gid_1,to_sustract_gid_3 gid_3
FROM tmp.adm1_substract
WHERE ref_gid_1 IN (SELECT gid_1 FROM main.adm1) AND to_sustract_gid_3 IS NOT NULL
), b AS(
SELECT a.gid_1,a.gid_3,ST_MakeValid(ST_difference(a1.the_geom,g3.geom)) geom
FROM a
JOIN main.adm1 a1 USING (gid_1)
JOIN gadm.gadm_adm3 g3 USING (gid_3)
)
UPDATE main.adm1 a1
SET modified_gid_1=b.gid_1, modification_gid_1='Substracted from original gadm polygon: gadm gid_3 {'|| gid_3||'}', the_geom=b.geom
FROM b
WHERE a1.gid_1=b.gid_1;

-- Inserting the parts from gadm_adm3
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit, type_part, type_part_verbatim,modified_gid_1,modification_gid_1,equi_geounit, the_geom)
WITH a AS(
SELECT cd_geounit,ref_gid_1 gid_1,to_sustract_gid_3 gid_3
FROM tmp.adm1_substract
WHERE (ref_gid_1 IN (SELECT gid_1 FROM main.adm1) OR ref_gid_1='ESP.7_1') AND to_sustract_gid_3 IS NOT NULL
)
SELECT name_3 adm1, 'gadm' orig, NULL gid_1, cd_geounit, engtype_3 type_part, type_3 type_part_verbatim, a.gid_1 modified_gid_1, 'gid_3 part: {'|| gid_3||'}', cd_geounit, ST_Multi(g3.geom) the_geom
FROM a
JOIN gadm.gadm_adm3 g3 USING (gid_3)
;
        -- adm1 not yet in  there

-- only a case for gid_2
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit, type_part, type_part_verbatim,modified_gid_1,modification_gid_1,equi_geounit, the_geom)
WITH a AS(
SELECT s.cd_geounit,ref_gid_1 gid_1,to_sustract_gid_2 gid_2
FROM tmp.adm1_substract s
LEFT JOIN main.adm1 a1 ON s.ref_gid_1=a1.gid_1 OR s.ref_gid_1=a1.modified_gid_1
WHERE a1.cd_adm1 IS NULL
), b AS(
SELECT cd_geounit,a.gid_1,a.gid_2,ST_MakeValid(ST_difference(g1.geom,g2.geom)) geom
FROM a
JOIN gadm.gadm_adm1 g1 USING (gid_1)
JOIN gadm.gadm_adm2 g2 USING (gid_2)
)
SELECT name_2 adm1, 'gadm' orig, NULL gid_1, cd_geounit, engtype_2 type_part, type_2 type_part_verbatim, a.gid_1 modified_gid_1, 'gid_2 part: {'|| gid_2||'}', cd_geounit, ST_Multi(g2.geom) the_geom
FROM a
JOIN gadm.gadm_adm2 g2 USING (gid_2)
UNION
SELECT name_1 adm1, 'gadm' orig, a.gid_1, cd_geounit, engtype_1 type_part, type_1 type_part_verbatim, a.gid_1 modified_gid_1, 'Substracted from original gadm polygon: gadm gid_2 {'|| gid_2||'}', NULL, ST_Multi(ST_MakeValid(ST_difference(g1.geom,g2.geom)))
FROM a
JOIN gadm.gadm_adm1 g1 USING (gid_1)
JOIN gadm.gadm_adm2 g2 USING (gid_2)
;

-- Now we look for the still not included gadm1 which ones could be defined as part of the geounits relatively easily (we go from the relationships between gid_0 and geounits):

INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit,type_part,type_part_verbatim,the_geom)
WITH already AS(
SELECT gid_1
FROM main.adm1
WHERE gid_1 IS NOT NULL
UNION
SELECT UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 IS NOT NULL
)
,a AS(
SELECT gid_1, UNNEST(includes) cd_geounit
FROM gadm.gadm_adm1
LEFT JOIN gadm.adm0_to_geounit USING (gid_0)
WHERE gid_1 NOT IN (SELECT gid_1 FROM already)
 AND included_in IS NULL
), intersections AS(
SELECT gid_1,cd_geounit,ST_AREA(ST_Intersection(geom,the_geom)) common_area,geom,the_geom
FROM a
LEFT JOIN gadm.gadm_adm1 USING (gid_1)
LEFT JOIN main.adm0_geounit USING(cd_geounit)
WHERE ST_intersects(geom,the_geom)
), area_gu AS(
SELECT DISTINCT cd_geounit,ST_AREA(the_geom) area_gu
FROM intersections
),area_g1 AS(
SELECT DISTINCT gid_1, ST_AREA(geom) area_g1
FROM intersections
), calcul_prop AS(
SELECT gid_1,cd_geounit, common_area/area_g1 prop_common_in_g1, common_area/area_gu prop_common_in_gu,
    CASE
        WHEN area_g1>area_gu THEN 'g1'
        ELSE 'gu'
    END bigger
FROM intersections
LEFT JOIN area_gu USING(cd_geounit)
LEFT JOIN area_g1 USING(gid_1)
),classif AS(
SELECT gid_1,cd_geounit,prop_common_in_g1,prop_common_in_gu,
    CASE
        WHEN prop_common_in_g1>.9 AND prop_common_in_gu>.9 THEN 'equi'
        WHEN prop_common_in_g1>.7 AND prop_common_in_gu<.7 THEN 'g1_in_gu'
        WHEN prop_common_in_g1<.7 AND prop_common_in_gu>.7 THEN 'gu_in_g1'
    END type_rel,bigger
FROM calcul_prop
ORDER BY gid_1
), bygid1 AS(
SELECT gid_1,
    ARRAY_AGG(cd_geounit ORDER BY prop_common_in_g1) intersects,
    ARRAY_AGG(cd_geounit ORDER BY prop_common_in_g1) FILTER (WHERE bigger = 'gu') bigger,
    ARRAY_AGG(cd_geounit ORDER BY prop_common_in_g1) FILTER (WHERE bigger = 'g1') smaller,
    ARRAY_AGG(cd_geounit ORDER BY prop_common_in_g1) FILTER (WHERE type_rel='g1_in_gu') definitly
FROM classif
GROUP BY gid_1
)
SELECT name_1 adm1, 'gadm' orig, gid_1,
    CASE
        WHEN ARRAY_LENGTH(definitly,1)=1 THEN definitly[1]
        WHEN ARRAY_LENGTH(intersects,1)=1 AND ARRAY_LENGTH(bigger,1)=1 THEN intersects[1]
    END cd_geounit,
    engtype_1 type_part, type_1 type_part_verbatim, ST_Multi(geom)
FROM bygid1 b1
JOIN gadm.gadm_adm1 g1 USING(gid_1)
WHERE ARRAY_LENGTH(definitly,1)=1 OR(ARRAY_LENGTH(intersects,1)=1 AND ARRAY_LENGTH(bigger,1)=1)
;

-- It did not work for:
/*
WITH already AS(
SELECT gid_1
FROM main.adm1
WHERE gid_1 IS NOT NULL
UNION
SELECT UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 IS NOT NULL
)
,a AS(
SELECT gid_1, UNNEST(includes) cd_geounit
FROM gadm.gadm_adm1
LEFT JOIN gadm.adm0_to_geounit USING (gid_0)
WHERE gid_1 NOT IN (SELECT gid_1 FROM already)
 AND included_in IS NULL
), intersections AS(
SELECT gid_1,cd_geounit,ST_AREA(ST_Intersection(geom,the_geom)) common_area,geom,the_geom
FROM a
LEFT JOIN gadm.gadm_adm1 USING (gid_1)
LEFT JOIN main.adm0_geounit USING(cd_geounit)
WHERE ST_intersects(geom,the_geom)
)
SELECT gid_1,ARRAY_AGG(cd_geounit) cd_geounit
FROM intersections
GROUP BY gid_1;
*/
-- It appears the the iles eparses are separated in gadm while they are not in the naturalearth data
-- Since they are remote islands, a ST_DWithin of 500 km is pretty useful together with a drop on gadm geometries
INSERT INTO main.adm1(adm1,orig,cd_geounit,type_part, modified_gid_1,modification_gid_1,equi_geounit, the_geom)
WITH g1 AS(
SELECT gid_1, (ST_Dump(geom)).*
FROM gadm.gadm_adm1
WHERE gid_1='ATF.2_1'
),gu AS(
SELECT cd_geounit,the_geom
FROM main.adm0_geounit
WHERE cd_geounit IN ('JUI','EUI','TEI')
),a AS(
SELECT cd_geounit,gid_1,ARRAY_AGG(path[1]) parts, ST_Multi(ST_Union(geom)) the_geom
FROM g1
JOIN gu ON ST_DWithin(gu.the_geom,g1.geom,500*1000,true)
GROUP BY cd_geounit,gid_1
)
SELECT geounit adm1, 'gadm' orig, cd_geounit,'Island' AS type_part, gid_1 AS modified_gid_1, 'exploded geometries from gadm_adm1: {' || gid_1 ||'}, parts: ' || ARRAY_TO_STRING(parts,','),cd_geounit equi_geounit,a.the_geom
FROM a
LEFT JOIN main.adm0_geounit USING(cd_geounit)
;

-- Now there are only a few missing islands:
INSERT INTO main.adm1(adm1,orig,gid_1,cd_geounit,type_part,type_part_verbatim,equi_geounit,the_geom)
WITH already AS(
SELECT cd_adm1, gid_1
FROM main.adm1
WHERE gid_1 IS NOT NULL
UNION
SELECT cd_adm1, modified_gid_1
FROM main.adm1
WHERE gid_1 IS NOT NULL
UNION
SELECT cd_adm1, UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 IS NOT NULL
)
SELECT name_1 adm1, 'gadm' orig, gid_1, cd_geounit, engtype_1 type_part, type_1 type_part_verbatim, cd_geounit equi_geounit, ST_Multi(geom)
FROM gadm.gadm_adm1 g1
LEFT JOIN already USING (gid_1)
LEFT JOIN main.adm0_geounit gu ON ST_DWithin(g1.geom,gu.the_geom,30*1000,true)
WHERE cd_adm1 IS NULL AND gid_1 <> 'ESP.7_1'
;




-- converse equivalence with geounit
ALTER TABLE main.adm0_geounit
ADD CONSTRAINT adm0_geounit_equi_adm1_fkey
FOREIGN KEY (equi_adm1)
REFERENCES main.adm1(cd_adm1);

CREATE INDEX main_adm0_geounit_equi_adm1_idx ON main.adm0_geounit(equi_adm1);

UPDATE main.adm0_geounit ag
SET equi_adm1=a1.cd_adm1
FROM main.adm1 a1
WHERE a1.equi_geounit=ag.cd_geounit AND ag.equi_adm1 IS NULL;




