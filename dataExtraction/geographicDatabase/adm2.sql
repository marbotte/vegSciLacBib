CREATE TABLE main.adm2
(
  cd_adm2 serial PRIMARY KEY,
  adm2 varchar(50),
  orig varchar(20),
  gid_2 varchar(15),-- unique key from gadm
  adm1_code varchar(10),-- unique key from naturalearth adm1
  adm2_code varchar(10),-- unique key from naturalearth adm2
  cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit), -- parent geounit
  cd_adm1 int REFERENCES main.adm1(cd_adm1), --parent adm1
  type_part varchar(70),
  type_part_verbatim text,
  cd_cat_part int,
  modified_gid_2 varchar(50),
  modification_gid_2 text,
  equi_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm1 int REFERENCES main.adm1(cd_adm1),
  equi_adm3 int,
  equi_adm4 int,
  equi_adm5 int,
  equi_muni int,
  UNIQUE(adm2,cd_geounit,cd_adm1,type_part)

);
SELECT AddGeometryColumn('main','adm2','the_geom',4326,'MULTIPOLYGON',2);
CREATE INDEX main_adm2_the_geom_idx ON main.adm2 USING GIST(the_geom);
CREATE INDEX main_adm_2_cd_geounit_idx ON main.adm2(cd_geounit);
CREATE INDEX main_adm_2_cd_adm1_idx ON main.adm2(cd_adm1);

/* particular cases
1. gid_2 is in a gid_1 which has been modified to enter in the adm1 table
2. gid_2 does not have a gid_1 present in adm1
3. gid_2 is equivalent to geounit
4. gid_2 is the part which have been included in adm1
5. instead of the gid_2 we should insert the gid_3 for it to correspond to the geounit
*/

CREATE TABLE already_included_gid_2(gid_2 varchar(50),cd_adm2 int);


-- the gid_1 is actually the gid_2
WITH a AS(
SELECT cd_adm1, UNNEST(substring(modification_gid_1,'{.*}')::text[]) gid_2
FROM main.adm1
WHERE modification_gid_1 ~ '^gid_2 part'
), b AS(
SELECT name_2 adm2, 'gadm' orig, gid_2, cd_geounit, cd_adm1, type_part,type_part_verbatim, cd_geounit equi_geounit, cd_adm1 equi_adm1,ST_Multi(g2.geom) the_geom
FROM a
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN gadm.gadm_adm2 g2 USING (gid_2)
),c AS (
INSERT INTO main.adm2(adm2, orig, gid_2, cd_geounit, cd_adm1, type_part,type_part_verbatim, equi_geounit, equi_adm1, the_geom)
SELECT * FROM b
RETURNING adm2.gid_2,adm2.cd_adm2
)
INSERT INTO already_included_gid_2
SELECT * FROM c
;

-- the gid_1 is actually the gid_3

WITH a AS(
SELECT cd_adm1, modified_gid_1 gid_1, UNNEST(substring(modification_gid_1,'{.*}')::text[]) gid_3
FROM main.adm1
WHERE modification_gid_1 ~ '^gid_3 part'
), b AS(
SELECT cd_adm1, a.gid_1,g2.gid_2, gid_3, ST_Area(ST_Intersection(g2.geom,g3.geom))/ST_Area(g2.geom) prop_area_g3, ST_Multi(ST_Difference(g2.geom,g3.geom)) diff_geom
FROM a
LEFT JOIN gadm.gadm_adm2 g2 USING(gid_1)
LEFT JOIN gadm.gadm_adm3 g3 USING(gid_3)
WHERE ST_intersects(g2.geom,g3.geom)
), c AS(
SELECT adm1 adm2, orig, NULL gid_2, cd_geounit, cd_adm1, type_part, type_part_verbatim, gid_2 modified_gid_2, modification_gid_1 modification_gid_2,cd_geounit equi_geounit, cd_adm1 equi_adm1, the_geom
FROM b
LEFT JOIN gadm.gadm_adm2 g2 USING (gid_2)
LEFT JOIN main.adm1 a1 USING (cd_adm1)
UNION
SELECT name_2 adm2, 'gadm' orig, gid_2, cd_geounit,a1.cd_adm1, engtype_2 type_part, type_2 type_part_verbatim, gid_2 modified_gid_2, 'Substracted from original gadm polygon: gadm gid_3 {'||gid_3||'}' modification_gid_2, NULL equi_geounit,NULL equi_adm1,diff_geom the_geom
FROM b
LEFT JOIN main.adm1 a1 USING(gid_1)
LEFT JOIN gadm.gadm_adm2 USING(gid_2)
WHERE ST_Area(diff_geom)>0.00000000000001
), d AS(
INSERT INTO main.adm2(adm2,orig, gid_2, cd_geounit, cd_adm1, type_part, type_part_verbatim, modified_gid_2, modification_gid_2, equi_geounit, equi_adm1,the_geom)
SELECT *
FROM c
RETURNING adm2.gid_2, adm2.cd_adm2
)
INSERT INTO already_included_gid_2
SELECT * FROM d
;

-- gid_2 in exploded gid_1: there are not referenced in gadm_adm2

SELECT g2.gid_2
FROM gadm.gadm_adm2 g2
LEFT JOIN main.adm1 a1 ON a1.modified_gid_1=g2.gid_1
WHERE modification_gid_1 ~ '^exploded geometries';

-- gid_2 in grouped gid_1 or... all the rest!

WITH a AS(
SELECT cd_geounit,cd_adm1, modified_gid_1 gid_1
FROM main.adm1
WHERE modification_gid_1 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm1,UNNEST(substring(modification_gid_1,'{.*}')::text[]) gid_1
FROM main.adm1
WHERE modification_gid_1 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm1,gid_1
FROM main.adm1
WHERE modification_gid_1 IS NULL
), b AS(
SELECT name_2 adm2, 'gadm' orig, gid_2, cd_geounit,cd_adm1, engtype_2 type_part, type_2 type_part_verbatim, ST_Multi(geom) the_geom
FROM a
JOIN gadm.gadm_adm2 USING (gid_1)
WHERE NOT gid_2 IN (SELECT gid_2 FROM already_included_gid_2 WHERE gid_2 IS NOT NULL)
),c AS(
SELECT adm2,cd_geounit,cd_adm1,type_part,count(*) group_of
FROM b
GROUP BY adm2,cd_geounit,cd_adm1,type_part
HAVING count(*)>1
),d AS( -- case with repetitions of adm2,cd_geounit,cd_adm1,type_part : we group!
SELECT adm2, 'gadm' orig, ARRAY_AGG(gid_2 ORDER BY ST_Area(the_geom) DESC) gid_2, cd_geounit,cd_adm1, type_part, ARRAY_AGG(type_part_verbatim ORDER BY ST_Area(the_geom) DESC) type_part_verbatim, ST_Multi(ST_Union(the_geom)) the_geom
FROM b
LEFT JOIN c USING(adm2,cd_geounit,cd_adm1,type_part)
WHERE group_of IS NOT NULL
GROUP BY adm2,cd_geounit,cd_adm1,type_part
),e AS(
INSERT INTO main.adm2(adm2,orig,gid_2, cd_geounit, cd_adm1, type_part, type_part_verbatim, modified_gid_2, modification_gid_2, the_geom)
SELECT adm2, orig, gid_2[1],cd_geounit,cd_adm1, type_part, type_part_verbatim[1] type_part_vervatim,gid_2[1] modified_gid_2,
    'grouped with: {' || ARRAY_TO_STRING(gid_2[2:ARRAY_LENGTH(gid_2,1)],',') || '}' modification_gid_2,
    the_geom
FROM d
RETURNING cd_adm2,gid_2
),f AS(
INSERT INTO already_included_gid_2(cd_adm2,gid_2)
SELECT e.cd_adm2,e.gid_2
FROM e
UNION
SELECT cd_adm2,UNNEST(substring(modification_gid_2,'{.*}')::text[])
FROM e
LEFT JOIN main.adm2 USING(cd_adm2,gid_2)
), g AS(-- cases without repetitions
INSERT INTO main.adm2 (adm2, orig, gid_2, cd_geounit,cd_adm1,type_part, type_part_verbatim, the_geom)
SELECT adm2, orig, gid_2, cd_geounit,cd_adm1,type_part, type_part_verbatim, the_geom
FROM b
LEFT JOIN c USING(adm2,cd_geounit,cd_adm1,type_part)
WHERE group_of IS NULL
RETURNING gid_2,cd_adm2
)
INSERT INTO already_included_gid_2
SELECT * FROM g
;

-- it appears
INSERT INTO already_included_gid_2(cd_adm2,gid_2)
SELECT cd_adm2,UNNEST(substring(modification_gid_2,'{.*}')::text[])
FROM already_included_gid_2
LEFT JOIN main.adm2 USING (cd_adm2)
WHERE modification_gid_2 ~ '^grouped'
;


--- What hasn't been included yet:
/*
SELECT *
FROM already_included_gid_2
RIGHT JOIN gadm.gadm_adm2 USING(gid_2)
WHERE cd_adm2 IS NULL
;
*/

-- I don't understand why, but that is not included yet:
WITH a AS(
SELECT name_2 adm2, 'gadm' orig, gid_2, cd_geounit,cd_adm1, engtype_2 type_part, type_2 type_part_verbatim, ST_Multi(geom) the_geom
FROM already_included_gid_2
RIGHT JOIN gadm.gadm_adm2  g2 USING(gid_2)
LEFT JOIN main.adm1 a1 USING(gid_1)
WHERE cd_adm2 IS NULL AND a1.cd_adm1 IS NOT NULL AND name_2 IS NOT NULL
), b AS(
INSERT INTO main.adm2 (adm2, orig, gid_2, cd_geounit,cd_adm1,type_part, type_part_verbatim, the_geom)
SELECT *
FROM a
RETURNING gid_2,cd_adm2
)
INSERT INTO already_included_gid_2
SELECT *
FROM b
;

-- These ones were not included because no connection to adm1 is found

WITH a AS(
SELECT g2.*-- gid_2, gid_1,gid_1 IN (SELECT gid_1 FROM main.adm1)
FROM already_included_gid_2
RIGHT JOIN gadm.gadm_adm2  g2 USING(gid_2)
WHERE cd_adm2 IS NULL AND (name_2 IS NOT NULL OR varname_2 IS NOT NULL)
),b AS(
SELECT a.gid_2,a1.cd_adm1
FROM a
LEFT JOIN main.adm1 a1 ON ST_Intersects(a.geom,a1.the_geom) AND ST_Area(ST_Intersection(a.geom,a1.the_geom))> (0.99*ST_Area(a.geom))
)
SELECT gid_2,ARRAY_AGG(cd_adm1)
FROM b
GROUP BY gid_2;



-- equivalence adm1

/* -- To be able to see in qgis:
CREATE MATERIALIZED VIEW tmp.equi_adm2 AS(
WITH a AS(
SELECT cd_adm1,ST_Area(the_geom) area_g1
FROM main.adm1
)
SELECT cd_adm2, cd_adm1, adm1,adm2, equi_adm1,modification_gid_2, ST_Area(ST_Intersection(a2.the_geom,a1.the_geom))/area_g1 prop_g1,a2.the_geom
FROM main.adm2 a2
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN a USING(cd_adm1)
WHERE ST_Area(ST_Intersection(a2.the_geom,a1.the_geom))/area_g1 > 0.9
)
;
CREATE INDEX tmp_equi_adm2_the_geom_idx ON tmp.equi_adm2 USING GIST(the_geom);
*/


-- equivalence calculation adm2->adm1
WITH a AS(
SELECT cd_adm1,ST_Area(the_geom) area_g1
FROM main.adm1
), b AS(
SELECT cd_adm2, cd_adm1, equi_adm1,modification_gid_2, ST_Area(ST_Intersection(a2.the_geom,a1.the_geom))/area_g1 prop_g1
FROM main.adm2 a2
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN a USING(cd_adm1)
WHERE ST_Area(ST_Intersection(a2.the_geom,a1.the_geom))/area_g1 > 0.999
)
UPDATE main.adm2 a2
SET equi_adm1=b.cd_adm1
FROM b
WHERE a2.cd_adm2=b.cd_adm2 AND a2.equi_adm1 IS NULL
;

-- equivalence chain adm2 -> adm1 -> geounit
WITH a AS(
SELECT cd_adm2, a1.equi_geounit
FROM main.adm2 a2
JOIN main.adm1 a1 ON a2.equi_adm1=a1.cd_adm1
WHERE a1.equi_geounit IS NOT NULL
)
UPDATE main.adm2 a2
SET equi_geounit=a.equi_geounit
FROM a
WHERE a2.cd_adm2=a.cd_adm2 AND a2.equi_geounit IS NULL
;


-- equivalence adm1 -> adm2
ALTER TABLE main.adm1
ADD CONSTRAINT adm1_equi_adm2_fkey
FOREIGN KEY (equi_adm2)
REFERENCES main.adm2(cd_adm2);

CREATE INDEX main_adm1_equi_adm2_idx ON main.adm1(equi_adm2);

UPDATE main.adm1 a1
SET equi_adm2=a2.cd_adm2
FROM main.adm2 a2
WHERE a2.equi_adm1=a1.cd_adm1 AND a1.equi_adm2 IS NULL;


-- equivalence geounit -> adm2
ALTER TABLE main.adm0_geounit
ADD CONSTRAINT adm0_geounit_equi_adm2_fkey
FOREIGN KEY (equi_adm2)
REFERENCES main.adm2(cd_adm2);

CREATE INDEX main_adm0_geounit_equi_adm2_idx ON main.adm1(equi_adm2);

UPDATE main.adm0_geounit ag
SET equi_adm2=a2.cd_adm2
FROM main.adm2 a2
WHERE a2.equi_geounit=ag.cd_geounit AND ag.equi_adm2 IS NULL;




/*
SELECT gid_1
FROM main.adm1
WHERE gid_1 IS NOT NULL
GROUP BY gid_1
HAVING count(*)>1;

SELECT cd_adm1,gid_1,cd_geounit,modified_gid_1,modification_gid_1
FROM main.adm1 WHERE modified_gid_1 IS NOT NULL OR modification_gid_1 IS NOT NULL;

WITH gid AS(
SELECT cd_adm1, gid_1 gid
FROM main.adm1
WHERE gid_1 IS NOT NULL
UNION
SELECT cd_adm1, modified_gid_1
FROM main.adm1
WHERE modified_gid_1 IS NOT NULL
UNION
SELECT cd_adm1, UNNEST(substring(modification_gid_1,'{.*}')::text[])
FROM main.adm1
WHERE modification_gid_1 IS NOT NULL
)
SELECT gid_2, a1.gid_1 direct_gid_1,a1m.gid_1 in_modified,a1.modification_gid_1,a1m.modification_gid_1
FROM gadm.gadm_adm2 g2
LEFT JOIN gid g ON g.gid=g2.gid_2
LEFT JOIN main.adm1 a1 USING (gid_1)
LEFT JOIN main.adm1 a1m ON g2.gid_1=a1.modified_gid_1
WHERE a1m.gid_1 IS NOT NULL;

*/


-- Test whether they are some wrong overlaps (more than 10%) betweem geometries of adm2
/*
SELECT a.cd_adm2,b.cd_adm2
FROM main.adm2 a
JOIN main.adm2 b ON a.cd_adm2<b.cd_adm2 AND ST_Intersects(a.the_geom,b.the_geom) AND (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.1 * ST_Area(a.the_geom) OR (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.1 * ST_Area(b.the_geom)))
LIMIT 10;
*/

DROP TABLE already_included_gid_2;
