CREATE TABLE main.adm4
(
  cd_adm4 serial PRIMARY KEY,
  adm4 varchar(50),
  orig varchar(20),
  gid_4 varchar(20),-- unique key from gadm
  cd_geounit char(4) REFERENCES main.adm0_geounit(cd_geounit) NOT NULL, -- parent geounit
  cd_adm1 int REFERENCES main.adm1(cd_adm1), -- parent adm1 (there are some zones with adm4, but no adm3 nor adm2)
  cd_adm2 int REFERENCES main.adm2(cd_adm2), --parent adm2 (there are some zones with adm4 but no adm3)
  cd_adm3 int REFERENCES main.adm3(cd_adm3), --parent adm3
  type_part varchar(70),
  type_part_verbatim text,
  cd_cat_part int,
  modified_gid_4 varchar(50),
  modification_gid_4 text,
  equi_geounit char(4) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm1 int REFERENCES main.adm1(cd_adm1),
  equi_adm2 int REFERENCES main.adm2(cd_adm2),
  equi_adm3 int REFERENCES main.adm3(cd_adm3),
  equi_adm5 int,
  equi_muni int,
  UNIQUE(adm4,cd_geounit,cd_adm3,type_part)
);
SELECT AddGeometryColumn('main','adm4','the_geom',4326,'MULTIPOLYGON',2);
CREATE INDEX main_adm4_the_geom_idx ON main.adm4 USING GIST(the_geom);
CREATE INDEX main_adm_4_cd_geounit_idx ON main.adm4(cd_geounit);
CREATE INDEX main_adm_4_cd_adm1_idx ON main.adm4(cd_adm1);
CREATE INDEX main_adm_4_cd_adm2_idx ON main.adm4(cd_adm2);
CREATE INDEX main_adm_4_cd_adm3_idx ON main.adm4(cd_adm3);

CREATE TABLE already_included_gid_4(gid_4 varchar(50),cd_adm4 int);

-- gid_4 in grouped gid_3 or... all the rest!

WITH a AS(
SELECT cd_geounit,cd_adm2, cd_adm3, modified_gid_3 gid_3
FROM main.adm3
WHERE modification_gid_3 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm2,cd_adm3,UNNEST(substring(modification_gid_3,'{.*}')::text[]) gid_3
FROM main.adm3
WHERE modification_gid_3 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm2,cd_adm3,gid_3
FROM main.adm3
WHERE modification_gid_3 IS NULL
), b AS(
SELECT name_4 adm4, 'gadm' orig, gid_4, cd_geounit, cd_adm2,cd_adm3, engtype_4 type_part, type_4 type_part_verbatim, ST_Multi(geom) the_geom
FROM a
JOIN gadm.gadm_adm4 USING (gid_3)
WHERE NOT gid_4 IN (SELECT gid_4 FROM already_included_gid_4 WHERE gid_4 IS NOT NULL)
),c AS(
SELECT adm4,cd_geounit,cd_adm3,type_part,count(*) group_of
FROM b
GROUP BY adm4,cd_geounit,cd_adm3,type_part
HAVING count(*)>1
),d AS( -- case with repetitions of adm4,cd_geounit,cd_adm3,type_part : we group!
SELECT c.adm4, 'gadm' orig, ARRAY_AGG(gid_4 ORDER BY ST_Area(the_geom) DESC) gid_4, c.cd_geounit, ARRAY_AGG(cd_adm2 ORDER BY ST_Area(the_geom) DESC) cd_adm2, c.cd_adm3, c.type_part, ARRAY_AGG(type_part_verbatim ORDER BY ST_Area(the_geom) DESC) type_part_verbatim, ST_Multi(ST_Union(the_geom)) the_geom
FROM b
LEFT JOIN c ON b.adm4=c.adm4 AND b.cd_geounit=c.cd_geounit AND b.cd_adm3=c.cd_adm3 AND ((b.type_part IS NULL AND c.type_part IS NULL) OR b.type_part=c.type_part)
WHERE group_of IS NOT NULL
GROUP BY c.adm4,c.cd_geounit,c.cd_adm3,c.type_part
),e AS(
INSERT INTO main.adm4(adm4,orig,gid_4, cd_geounit,cd_adm2, cd_adm3, type_part, type_part_verbatim, modified_gid_4, modification_gid_4, the_geom)
SELECT adm4, orig, gid_4[1],cd_geounit,cd_adm2[1],cd_adm3, type_part, type_part_verbatim[1] type_part_vervatim,gid_4[1] modified_gid_4,
    'grouped with: {' || ARRAY_TO_STRING(gid_4[2:ARRAY_LENGTH(gid_4,1)],',') || '}' modification_gid_4,
    the_geom
FROM d
RETURNING cd_adm4,gid_4
),f AS(
INSERT INTO already_included_gid_4(cd_adm4,gid_4)
SELECT e.cd_adm4,e.gid_4
FROM e
UNION
SELECT cd_adm4,UNNEST(substring(modification_gid_4,'{.*}')::text[])
FROM e
LEFT JOIN main.adm4 USING(cd_adm4,gid_4)
), g AS(-- cases without repetitions
INSERT INTO main.adm4 (adm4, orig, gid_4, cd_geounit,cd_adm2,cd_adm3,type_part, type_part_verbatim, the_geom)
SELECT adm4, orig, gid_4, cd_geounit,cd_adm2,cd_adm3,type_part, type_part_verbatim, the_geom
FROM b
LEFT JOIN c USING(adm4,cd_geounit,cd_adm3,type_part)
WHERE group_of IS NULL
RETURNING gid_4,cd_adm4
)
INSERT INTO already_included_gid_4
SELECT * FROM g
;

-- it appears
INSERT INTO already_included_gid_4(cd_adm4,gid_4)
SELECT cd_adm4,UNNEST(substring(modification_gid_4,'{.*}')::text[]) gid_4
FROM already_included_gid_4
LEFT JOIN main.adm4 USING (cd_adm4)
WHERE modification_gid_4 ~ '^grouped'
;


--- What hasn't been included yet:
/*
SELECT *
FROM already_included_gid_4
RIGHT JOIN gadm.gadm_adm4 USING(gid_4)
WHERE cd_adm4 IS NULL
;
*/

-- I don't understand why, but that is not included yet:
/* --it appears there is no case
WITH a AS(
SELECT name_4 adm4, 'gadm' orig, gid_4, cd_geounit,cd_adm3,cd_adm3, engtype_4 type_part, type_4 type_part_verbatim, ST_Multi(geom) the_geom
FROM already_included_gid_4
RIGHT JOIN gadm.gadm_adm4  g4 USING(gid_4)
LEFT JOIN main.adm3 a3 USING(gid_3)
WHERE cd_adm4 IS NULL AND a3.cd_adm3 IS NOT NULL AND name_4 IS NOT NULL
), b AS(
INSERT INTO main.adm4 (adm4, orig, gid_4, cd_geounit,cd_adm2,cd_adm3,type_part, type_part_verbatim, the_geom)
SELECT *
FROM a
RETURNING gid_4,cd_adm4
)
INSERT INTO already_included_gid_4
SELECT *
FROM b
;
*/
-- These ones were not included because no connection to adm3 is found

WITH a AS(
SELECT g4.*-- gid_4, gid_3,gid_3 IN (SELECT gid_3 FROM main.adm3)
FROM already_included_gid_4
RIGHT JOIN gadm.gadm_adm4  g4 USING(gid_4)
WHERE cd_adm4 IS NULL AND (name_4 IS NOT NULL OR varname_4 IS NOT NULL)
),b AS(
SELECT a.gid_4,COALESCE(a3.cd_geounit,a2.cd_geounit) cd_geounit,a2.cd_adm2,a3.cd_adm3--,ST_Area(ST_Intersection(a.geom,a3.the_geom))
FROM a
LEFT JOIN main.adm3 a3 ON ST_Intersects(a.geom,a3.the_geom) AND ST_Area(ST_Intersection(a.geom,a3.the_geom))> (0.99*ST_Area(a.geom))
LEFT JOIN main.adm2 a2 ON ST_Intersects(a.geom,a2.the_geom) AND ST_Area(ST_Intersection(a.geom,a2.the_geom))> (0.99*ST_Area(a.geom))
),c AS( --!!!!! CHECK IT !!!!!! all should be size 1 or all identical
SELECT gid_4,ARRAY_AGG(cd_geounit) cd_geounit, ARRAY_AGG(cd_adm2) cd_adm2 ,ARRAY_AGG(cd_adm3) cd_adm3
FROM b
GROUP BY gid_4
),d AS(
INSERT INTO main.adm4 (adm4, orig, gid_4, cd_geounit,cd_adm2,cd_adm3,type_part, type_part_verbatim, the_geom)
SELECT name_4 adm4, 'gadm' orig, gid_4, c.cd_geounit[1],c.cd_adm2[1],c.cd_adm3[1], engtype_4 type_part, type_4 type_part_verbatim, ST_Multi(geom) the_geom
FROM c
LEFT JOIN gadm.gadm_adm4 USING(gid_4)
WHERE cd_geounit[1] IS NOT NULL
RETURNING gid_4,cd_adm4
)
INSERT INTO already_included_gid_4
SELECT *
FROM d
;

-- update cd_adm1
UPDATE main.adm4 a4
SET cd_adm1=a2.cd_adm1
FROM main.adm2 a2
WHERE a2.cd_adm2=a4.cd_adm2 AND a2.cd_adm1 IS NOT NULL;

UPDATE main.adm4 a4
SET cd_adm1=a3.cd_adm1
FROM main.adm3 a3
WHERE a3.cd_adm2=a4.cd_adm2 AND a3.cd_adm1 IS NOT NULL;

-- There are 2 zones in england which have adm4 but no adm3, no adm2


WITH a AS(
SELECT g4.*-- gid_4, gid_3,gid_3 IN (SELECT gid_3 FROM main.adm3)
FROM already_included_gid_4
RIGHT JOIN gadm.gadm_adm4  g4 USING(gid_4)
WHERE cd_adm4 IS NULL AND (name_4 IS NOT NULL OR varname_4 IS NOT NULL)
),b AS(
SELECT a.gid_4,a1.cd_geounit cd_geounit,a1.cd_adm1--,ST_Area(ST_Intersection(a.geom,a3.the_geom))
FROM a
LEFT JOIN main.adm1 a1 ON ST_Intersects(a.geom,a1.the_geom) AND ST_Area(ST_Intersection(a.geom,a1.the_geom))> (0.99*ST_Area(a.geom))
),c AS(
INSERT INTO main.adm4(adm4, orig, gid_4, cd_geounit,cd_adm1,type_part, type_part_verbatim, the_geom)
SELECT a4.name_4 adm4, 'gadm' orig, gid_4, cd_geounit,b.cd_adm1, engtype_4 type_part, type_4 type_part_verbatim, ST_Multi(geom)
FROM b
LEFT JOIN gadm.gadm_adm4 a4 USING (gid_4)
RETURNING gid_4,cd_adm4
)
INSERT INTO already_included_gid_4 SELECT * FROM c;



SELECT g4.*-- gid_4, gid_2,gid_2 IN (SELECT gid_2 FROM main.adm2)
FROM already_included_gid_4
RIGHT JOIN gadm.gadm_adm4  g4 USING(gid_4)
WHERE cd_adm4 IS NULL AND (name_4 IS NOT NULL OR varname_4 IS NOT NULL)
;



-- equivalence calculation adm4->adm3
WITH a AS(
SELECT cd_adm3,ST_Area(the_geom) area_g3
FROM main.adm3
), b AS(
SELECT cd_adm4, cd_adm3, equi_adm3,modification_gid_4, ST_Area(ST_Intersection(a4.the_geom,a3.the_geom))/area_g3 prop_g3
FROM main.adm4 a4
LEFT JOIN main.adm3 a3 USING (cd_adm3)
LEFT JOIN a USING(cd_adm3)
WHERE ST_Area(ST_Intersection(a4.the_geom,a3.the_geom))/area_g3 > 0.999
)
UPDATE main.adm4 a4
SET equi_adm3=b.cd_adm3
FROM b
WHERE a4.cd_adm4=b.cd_adm4 AND a4.equi_adm3 IS NULL
;

-- equivalence chain adm4 -> adm3 -> adm2
WITH a AS(
SELECT cd_adm4, a3.equi_adm2
FROM main.adm4 a4
JOIN main.adm3 a3 ON a4.equi_adm3=a3.cd_adm3
WHERE a3.equi_adm2 IS NOT NULL
)
UPDATE main.adm4 a4
SET equi_adm2=a.equi_adm2
FROM a
WHERE a4.cd_adm4=a.cd_adm4 AND a4.equi_adm2 IS NULL
;


-- equivalence chain adm4 -> adm3 -> geounit
WITH a AS(
SELECT cd_adm4, a3.equi_geounit
FROM main.adm4 a4
JOIN main.adm3 a3 ON a4.equi_adm3=a3.cd_adm3
WHERE a3.equi_geounit IS NOT NULL
)
UPDATE main.adm4 a4
SET equi_geounit=a.equi_geounit
FROM a
WHERE a4.cd_adm4=a.cd_adm4 AND a4.equi_geounit IS NULL
;


-- equivalence calculation adm4->adm2
WITH a AS(
SELECT cd_adm2,ST_Area(the_geom) area_g2
FROM main.adm2
), b AS(
SELECT cd_adm4, cd_adm2, equi_adm2,modification_gid_4, ST_Area(ST_Intersection(a4.the_geom,a2.the_geom))/area_g2 prop_g2
FROM main.adm4 a4
LEFT JOIN main.adm2 a2 USING (cd_adm2)
LEFT JOIN a USING(cd_adm2)
WHERE ST_Area(ST_Intersection(a4.the_geom,a2.the_geom))/area_g2 > 0.999
)
UPDATE main.adm4 a4
SET equi_adm2=b.cd_adm2
FROM b
WHERE a4.cd_adm4=b.cd_adm4 AND a4.equi_adm2 IS NULL
;

-- equivalence calculation adm4->adm1
WITH a AS(
SELECT cd_adm1,ST_Area(the_geom) area_g1
FROM main.adm1
), b AS(
SELECT cd_adm4, cd_adm1, equi_adm1,modification_gid_4, ST_Area(ST_Intersection(a4.the_geom,a1.the_geom))/area_g1 prop_g2
FROM main.adm4 a4
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN a USING(cd_adm1)
WHERE ST_Area(ST_Intersection(a4.the_geom,a1.the_geom))/area_g1 > 0.999
)
UPDATE main.adm4 a4
SET equi_adm1=b.cd_adm1
FROM b
WHERE a4.cd_adm4=b.cd_adm4 AND a4.equi_adm1 IS NULL
;




-- equivalence adm3 -> adm4
ALTER TABLE main.adm3
ADD CONSTRAINT adm3_equi_adm4_fkey
FOREIGN KEY (equi_adm4)
REFERENCES main.adm4(cd_adm4);

CREATE INDEX main_adm3_equi_adm4_idx ON main.adm3(equi_adm4);

UPDATE main.adm3 a3
SET equi_adm4=a4.cd_adm4
FROM main.adm4 a4
WHERE a4.equi_adm3=a3.cd_adm3 AND a3.equi_adm4 IS NULL;

-- equivalence adm2 -> adm4
ALTER TABLE main.adm2
ADD CONSTRAINT adm2_equi_adm4_fkey
FOREIGN KEY (equi_adm4)
REFERENCES main.adm4(cd_adm4);

CREATE INDEX main_adm2_equi_adm4_idx ON main.adm2(equi_adm4);

UPDATE main.adm2 a2
SET equi_adm4=a4.cd_adm4
FROM main.adm4 a4
WHERE a4.equi_adm2=a2.cd_adm2 AND a2.equi_adm4 IS NULL;

-- equivalence adm1 -> adm4
ALTER TABLE main.adm1
ADD CONSTRAINT adm1_equi_adm4_fkey
FOREIGN KEY (equi_adm4)
REFERENCES main.adm4(cd_adm4);

CREATE INDEX main_adm1_equi_adm4_idx ON main.adm1(equi_adm4);

UPDATE main.adm1 a1
SET equi_adm4=a4.cd_adm4
FROM main.adm4 a4
WHERE a4.equi_adm1=a1.cd_adm1 AND a1.equi_adm4 IS NULL;

-- equivalence geounit -> adm4
ALTER TABLE main.adm0_geounit
ADD CONSTRAINT adm0_geounit_equi_adm4_fkey
FOREIGN KEY (equi_adm4)
REFERENCES main.adm4(cd_adm4);

CREATE INDEX main_adm0_geounit_equi_adm4_idx ON main.adm0_geounit(equi_adm4);

UPDATE main.adm0_geounit ag
SET equi_adm4=a4.cd_adm4
FROM main.adm4 a4
WHERE a4.equi_geounit=ag.cd_geounit AND ag.equi_adm4 IS NULL;




-- Test whether they are some wrong overlaps (more than 20%) betweem geometries of adm4
/*
SELECT a.cd_adm4,b.cd_adm4
FROM main.adm4 a
JOIN main.adm4 b ON a.cd_adm4<b.cd_adm4 AND ST_Intersects(a.the_geom,b.the_geom) AND (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.2 * ST_Area(a.the_geom) OR (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.2 * ST_Area(b.the_geom)))
LIMIT 20;
*/



DROP TABLE already_included_gid_4;
