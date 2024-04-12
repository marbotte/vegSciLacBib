CREATE TABLE main.adm3
(
  cd_adm3 serial PRIMARY KEY,
  adm3 varchar(50),
  orig varchar(20),
  gid_3 varchar(15),-- unique key from gadm
  cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit), -- parent geounit
  cd_adm1 int REFERENCES main.adm1(cd_adm1), --parent adm1 (there are some zones with adm3 but no adm2)
  cd_adm2 int REFERENCES main.adm2(cd_adm2), --parent adm2
  type_part varchar(70),
  type_part_verbatim text,
  cd_cat_part int,
  modified_gid_3 varchar(50),
  modification_gid_3 text,
  equi_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm1 int REFERENCES main.adm1(cd_adm1),
  equi_adm2 int REFERENCES main.adm2(cd_adm2),
  equi_adm4 int,
  equi_adm5 int,
  equi_muni int,
  UNIQUE(adm3,cd_geounit,cd_adm2,type_part)
);
SELECT AddGeometryColumn('main','adm3','the_geom',4326,'MULTIPOLYGON',2);
CREATE INDEX main_adm3_the_geom_idx ON main.adm3 USING GIST(the_geom);
CREATE INDEX main_adm_3_cd_geounit_idx ON main.adm3(cd_geounit);
CREATE INDEX main_adm_3_cd_adm1_idx ON main.adm3(cd_adm1);
CREATE INDEX main_adm_3_cd_adm2_idx ON main.adm3(cd_adm2);

/* particular cases
1. gid_2 is in a gid_1 which has been modified to enter in the adm1 table
2. gid_2 does not have a gid_1 present in adm1
3. gid_2 is equivalent to geounit
4. gid_2 is the part which have been included in adm1
5. instead of the gid_2 we should insert the gid_3 for it to correspond to the geounit
*/

CREATE TABLE already_included_gid_3(gid_3 varchar(50),cd_adm3 int);

-- the gid_2 is actually the gid_3
WITH a AS(
SELECT cd_adm2, UNNEST(substring(modification_gid_2,'{.*}')::text[]) gid_3
FROM main.adm2
WHERE modification_gid_2 ~ '^gid_3 part'
), b AS(
SELECT name_3 adm3, 'gadm' orig, gid_3, cd_geounit, a2.cd_adm1, cd_adm2, type_part,type_part_verbatim, cd_geounit equi_geounit, cd_adm2 equi_adm2,ST_Multi(g3.geom) the_geom
FROM a
LEFT JOIN main.adm2 a2 USING (cd_adm2)
LEFT JOIN gadm.gadm_adm3 g3 USING (gid_3)
),c AS (
INSERT INTO main.adm3(adm3, orig, gid_3, cd_geounit, cd_adm1,cd_adm2, type_part,type_part_verbatim, equi_geounit, equi_adm2, the_geom)
SELECT * FROM b
RETURNING adm3.gid_3,adm3.cd_adm3
)
INSERT INTO already_included_gid_3
SELECT * FROM c
;


-- gid_3 in grouped gid_2 or... all the rest!

WITH a AS(
SELECT cd_geounit,cd_adm1, cd_adm2, modified_gid_2 gid_2
FROM main.adm2
WHERE modification_gid_2 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm1,cd_adm2,UNNEST(substring(modification_gid_2,'{.*}')::text[]) gid_2
FROM main.adm2
WHERE modification_gid_2 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm1,cd_adm2,gid_2
FROM main.adm2
WHERE modification_gid_2 IS NULL
), b AS(
SELECT name_3 adm3, 'gadm' orig, gid_3, cd_geounit, cd_adm1,cd_adm2, engtype_3 type_part, type_3 type_part_verbatim, ST_Multi(geom) the_geom
FROM a
JOIN gadm.gadm_adm3 USING (gid_2)
WHERE NOT gid_3 IN (SELECT gid_3 FROM already_included_gid_3 WHERE gid_3 IS NOT NULL)
),c AS(
SELECT adm3,cd_geounit,cd_adm2,type_part,count(*) group_of
FROM b
GROUP BY adm3,cd_geounit,cd_adm2,type_part
HAVING count(*)>1
),d AS( -- case with repetitions of adm3,cd_geounit,cd_adm2,type_part : we group!
SELECT adm3, 'gadm' orig, ARRAY_AGG(gid_3 ORDER BY ST_Area(the_geom) DESC) gid_3, cd_geounit, ARRAY_AGG(cd_adm1 ORDER BY ST_Area(the_geom) DESC) cd_adm1, cd_adm2, type_part, ARRAY_AGG(type_part_verbatim ORDER BY ST_Area(the_geom) DESC) type_part_verbatim, ST_Multi(ST_Union(the_geom)) the_geom
FROM b
LEFT JOIN c USING(adm3,cd_geounit,cd_adm2,type_part)
WHERE group_of IS NOT NULL
GROUP BY adm3,cd_geounit,cd_adm2,type_part
),e AS(
INSERT INTO main.adm3(adm3,orig,gid_3, cd_geounit,cd_adm1, cd_adm2, type_part, type_part_verbatim, modified_gid_3, modification_gid_3, the_geom)
SELECT adm3, orig, gid_3[1],cd_geounit,cd_adm1[1],cd_adm2, type_part, type_part_verbatim[1] type_part_vervatim,gid_3[1] modified_gid_3,
    'grouped with: {' || ARRAY_TO_STRING(gid_3[2:ARRAY_LENGTH(gid_3,1)],',') || '}' modification_gid_3,
    the_geom
FROM d
RETURNING cd_adm3,gid_3
),f AS(
INSERT INTO already_included_gid_3(cd_adm3,gid_3)
SELECT e.cd_adm3,e.gid_3
FROM e
UNION
SELECT cd_adm3,UNNEST(substring(modification_gid_3,'{.*}')::text[])
FROM e
LEFT JOIN main.adm3 USING(cd_adm3,gid_3)
), g AS(-- cases without repetitions
INSERT INTO main.adm3 (adm3, orig, gid_3, cd_geounit,cd_adm1,cd_adm2,type_part, type_part_verbatim, the_geom)
SELECT adm3, orig, gid_3, cd_geounit,cd_adm1,cd_adm2,type_part, type_part_verbatim, the_geom
FROM b
LEFT JOIN c USING(adm3,cd_geounit,cd_adm2,type_part)
WHERE group_of IS NULL
RETURNING gid_3,cd_adm3
)
INSERT INTO already_included_gid_3
SELECT * FROM g
;

-- it appears
INSERT INTO already_included_gid_3(cd_adm3,gid_3)
SELECT cd_adm3,UNNEST(substring(modification_gid_3,'{.*}')::text[]) gid_3
FROM already_included_gid_3
LEFT JOIN main.adm3 USING (cd_adm3)
WHERE modification_gid_3 ~ '^grouped'
;


--- What hasn't been included yet:
/*
SELECT *
FROM already_included_gid_3
RIGHT JOIN gadm.gadm_adm3 USING(gid_3)
WHERE cd_adm3 IS NULL
;
*/

-- I don't understand why, but that is not included yet:
WITH a AS(
SELECT name_3 adm3, 'gadm' orig, gid_3, cd_geounit,cd_adm1,cd_adm2, engtype_3 type_part, type_3 type_part_verbatim, ST_Multi(geom) the_geom
FROM already_included_gid_3
RIGHT JOIN gadm.gadm_adm3  g3 USING(gid_3)
LEFT JOIN main.adm2 a2 USING(gid_2)
WHERE cd_adm3 IS NULL AND a2.cd_adm2 IS NOT NULL AND name_3 IS NOT NULL
), b AS(
INSERT INTO main.adm3 (adm3, orig, gid_3, cd_geounit,cd_adm1,cd_adm2,type_part, type_part_verbatim, the_geom)
SELECT *
FROM a
RETURNING gid_3,cd_adm3
)
INSERT INTO already_included_gid_3
SELECT *
FROM b
;

-- These ones were not included because no connection to adm2 is found

WITH a AS(
SELECT g3.*-- gid_3, gid_2,gid_2 IN (SELECT gid_2 FROM main.adm2)
FROM already_included_gid_3
RIGHT JOIN gadm.gadm_adm3  g3 USING(gid_3)
WHERE cd_adm3 IS NULL AND (name_3 IS NOT NULL OR varname_3 IS NOT NULL)
),b AS(
SELECT a.gid_3,COALESCE(a2.cd_geounit,a1.cd_geounit) cd_geounit,a1.cd_adm1,a2.cd_adm2--,ST_Area(ST_Intersection(a.geom,a2.the_geom))
FROM a
LEFT JOIN main.adm2 a2 ON ST_Intersects(a.geom,a2.the_geom) AND ST_Area(ST_Intersection(a.geom,a2.the_geom))> (0.99*ST_Area(a.geom))
LEFT JOIN main.adm1 a1 ON ST_Intersects(a.geom,a1.the_geom) AND ST_Area(ST_Intersection(a.geom,a1.the_geom))> (0.99*ST_Area(a.geom))
),c AS( --!!!!! CHECK IT !!!!!! all should be size 1 or all identical
SELECT gid_3,ARRAY_AGG(cd_geounit) cd_geounit, ARRAY_AGG(cd_adm1) cd_adm1 ,ARRAY_AGG(cd_adm2) cd_adm2
FROM b
GROUP BY gid_3
),d AS(
INSERT INTO main.adm3 (adm3, orig, gid_3, cd_geounit,cd_adm1,cd_adm2,type_part, type_part_verbatim, the_geom)
SELECT name_3 adm3, 'gadm' orig, gid_3, c.cd_geounit[1],c.cd_adm1[1],c.cd_adm2[1], engtype_3 type_part, type_3 type_part_verbatim, ST_Multi(geom) the_geom
FROM c
LEFT JOIN gadm.gadm_adm3 USING(gid_3)
RETURNING gid_3,cd_adm3
)
INSERT INTO already_included_gid_3
SELECT *
FROM d
;

SELECT g3.*-- gid_3, gid_2,gid_2 IN (SELECT gid_2 FROM main.adm2)
FROM already_included_gid_3
RIGHT JOIN gadm.gadm_adm3  g3 USING(gid_3)
WHERE cd_adm3 IS NULL AND (name_3 IS NOT NULL OR varname_3 IS NOT NULL)
;




-- equivalence calculation adm3->adm2
WITH a AS(
SELECT cd_adm2,ST_Area(the_geom) area_g2
FROM main.adm2
), b AS(
SELECT cd_adm3, cd_adm2, equi_adm2,modification_gid_3, ST_Area(ST_Intersection(a3.the_geom,a2.the_geom))/area_g2 prop_g2
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING (cd_adm2)
LEFT JOIN a USING(cd_adm2)
WHERE ST_Area(ST_Intersection(a3.the_geom,a2.the_geom))/area_g2 > 0.999
)
UPDATE main.adm3 a3
SET equi_adm2=b.cd_adm2
FROM b
WHERE a3.cd_adm3=b.cd_adm3 AND a3.equi_adm2 IS NULL
;

-- equivalence chain adm3 -> adm2 -> adm1
WITH a AS(
SELECT cd_adm3, a2.equi_adm1
FROM main.adm3 a3
JOIN main.adm2 a2 ON a3.equi_adm2=a2.cd_adm2
WHERE a2.equi_adm1 IS NOT NULL
)
UPDATE main.adm3 a3
SET equi_adm1=a.equi_adm1
FROM a
WHERE a3.cd_adm3=a.cd_adm3 AND a3.equi_adm1 IS NULL
;


-- equivalence chain adm3 -> adm2 -> geounit
WITH a AS(
SELECT cd_adm3, a2.equi_geounit
FROM main.adm3 a3
JOIN main.adm2 a2 ON a3.equi_adm2=a2.cd_adm2
WHERE a2.equi_geounit IS NOT NULL
)
UPDATE main.adm3 a3
SET equi_geounit=a.equi_geounit
FROM a
WHERE a3.cd_adm3=a.cd_adm3 AND a3.equi_geounit IS NULL
;


-- equivalence calculation adm3->adm1
WITH a AS(
SELECT cd_adm1,ST_Area(the_geom) area_g1
FROM main.adm1
), b AS(
SELECT cd_adm3, cd_adm1, equi_adm1,modification_gid_3, ST_Area(ST_Intersection(a3.the_geom,a1.the_geom))/area_g1 prop_g1
FROM main.adm3 a3
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN a USING(cd_adm1)
WHERE ST_Area(ST_Intersection(a3.the_geom,a1.the_geom))/area_g1 > 0.999
)
UPDATE main.adm3 a3
SET equi_adm1=b.cd_adm1
FROM b
WHERE a3.cd_adm3=b.cd_adm3 AND a3.equi_adm1 IS NULL
;


-- equivalence adm2 -> adm3
ALTER TABLE main.adm2
ADD CONSTRAINT adm2_equi_adm3_fkey
FOREIGN KEY (equi_adm3)
REFERENCES main.adm3(cd_adm3);

CREATE INDEX main_adm2_equi_adm3_idx ON main.adm2(equi_adm3);

UPDATE main.adm2 a2
SET equi_adm3=a3.cd_adm3
FROM main.adm3 a3
WHERE a3.equi_adm2=a2.cd_adm2 AND a2.equi_adm3 IS NULL;

-- equivalence adm1 -> adm3
ALTER TABLE main.adm1
ADD CONSTRAINT adm1_equi_adm3_fkey
FOREIGN KEY (equi_adm3)
REFERENCES main.adm3(cd_adm3);

CREATE INDEX main_adm1_equi_adm3_idx ON main.adm1(equi_adm3);

UPDATE main.adm1 a1
SET equi_adm3=a3.cd_adm3
FROM main.adm3 a3
WHERE a3.equi_adm1=a1.cd_adm1 AND a1.equi_adm3 IS NULL;

-- equivalence geounit -> adm3
ALTER TABLE main.adm0_geounit
ADD CONSTRAINT adm0_geounit_equi_adm3_fkey
FOREIGN KEY (equi_adm3)
REFERENCES main.adm3(cd_adm3);

CREATE INDEX main_adm0_geounit_equi_adm3_idx ON main.adm0_geounit(equi_adm3);

UPDATE main.adm0_geounit ag
SET equi_adm3=a3.cd_adm3
FROM main.adm3 a3
WHERE a3.equi_geounit=ag.cd_geounit AND ag.equi_adm3 IS NULL;




-- Test whether they are some wrong overlaps (more than 10%) betweem geometries of adm3
/*
SELECT a.cd_adm3,b.cd_adm3
FROM main.adm3 a
JOIN main.adm3 b ON a.cd_adm3<b.cd_adm3 AND ST_Intersects(a.the_geom,b.the_geom) AND (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.1 * ST_Area(a.the_geom) OR (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.1 * ST_Area(b.the_geom)))
LIMIT 10;
*/
















DROP TABLE already_included_gid_3;
