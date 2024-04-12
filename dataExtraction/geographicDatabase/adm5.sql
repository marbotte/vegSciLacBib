
CREATE TABLE main.adm5
(
  cd_adm5 serial PRIMARY KEY,
  adm5 varchar(50),
  orig varchar(20),
  gid_5 varchar(20),-- unique key from gadm
  cd_geounit char(5) REFERENCES main.adm0_geounit(cd_geounit) NOT NULL, -- parent geounit
  cd_adm4 int REFERENCES main.adm4(cd_adm4), --parent adm4
  type_part varchar(70),
  type_part_verbatim text,
  cd_cat_part int,
  modified_gid_5 varchar(50),
  modification_gid_5 text,
  equi_geounit char(5) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm1 int REFERENCES main.adm1(cd_adm1),
  equi_adm2 int REFERENCES main.adm2(cd_adm2),
  equi_adm3 int REFERENCES main.adm3(cd_adm3),
  equi_adm4 int REFERENCES main.adm4(cd_adm4),
  equi_muni int,
  UNIQUE(adm5,cd_geounit,cd_adm4,type_part)
);
SELECT AddGeometryColumn('main','adm5','the_geom',4326,'MULTIPOLYGON',2);
CREATE INDEX main_adm5_the_geom_idx ON main.adm5 USING GIST(the_geom);
CREATE INDEX main_adm_5_cd_geounit_idx ON main.adm5(cd_geounit);
CREATE INDEX main_adm_5_cd_adm4_idx ON main.adm5(cd_adm4);

CREATE TABLE already_included_gid_5(gid_5 varchar(50),cd_adm5 int);

-- gid_5 in grouped gid_4 or... all the rest!
WITH a AS(
SELECT cd_geounit, cd_adm4, modified_gid_4 gid_4
FROM main.adm4
WHERE modification_gid_4 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm4,UNNEST(substring(modification_gid_4,'{.*}')::text[]) gid_4
FROM main.adm4
WHERE modification_gid_4 ~ 'grouped'
UNION
SELECT cd_geounit,cd_adm4,gid_4
FROM main.adm4
WHERE modification_gid_4 IS NULL
), b AS(
SELECT name_5 adm5, 'gadm' orig, gid_5, cd_geounit, cd_adm4, engtype_5 type_part, type_5 type_part_verbatim, ST_Multi(geom) the_geom
FROM a
JOIN gadm.gadm_adm5 USING (gid_4)
WHERE NOT gid_5 IN (SELECT gid_5 FROM already_included_gid_5 WHERE gid_5 IS NOT NULL)
),g AS(
INSERT INTO main.adm5 (adm5, orig, gid_5, cd_geounit,cd_adm4,type_part, type_part_verbatim, the_geom)
SELECT adm5, orig, gid_5, cd_geounit,cd_adm4,type_part, type_part_verbatim, the_geom
FROM b
RETURNING gid_5,cd_adm5
)
INSERT INTO already_included_gid_5
SELECT * FROM g
;




SELECT g5.*-- gid_5, gid_2,gid_2 IN (SELECT gid_2 FROM main.adm2)
FROM already_included_gid_5
RIGHT JOIN gadm.gadm_adm5  g5 USING(gid_5)
WHERE cd_adm5 IS NULL AND (name_5 IS NOT NULL IS NOT NULL)
;



-- equivalence calculation adm5->adm4
WITH a AS(
SELECT cd_adm4,ST_Area(the_geom) area_g4
FROM main.adm4
), b AS(
SELECT cd_adm5, cd_adm4, equi_adm4,modification_gid_5, ST_Area(ST_Intersection(a5.the_geom,a4.the_geom))/area_g4 prop_g4
FROM main.adm5 a5
LEFT JOIN main.adm4 a4 USING (cd_adm4)
LEFT JOIN a USING(cd_adm4)
WHERE ST_Area(ST_Intersection(a5.the_geom,a4.the_geom))/area_g4 > 0.999
)
UPDATE main.adm5 a5
SET equi_adm4=b.cd_adm4
FROM b
WHERE a5.cd_adm5=b.cd_adm5 AND a5.equi_adm4 IS NULL
;

-- equivalence chain adm5 -> adm4 -> adm3
WITH a AS(
SELECT cd_adm5, a4.equi_adm3
FROM main.adm5 a5
JOIN main.adm4 a4 ON a5.equi_adm4=a4.cd_adm4
WHERE a4.equi_adm3 IS NOT NULL
)
UPDATE main.adm5 a5
SET equi_adm3=a.equi_adm3
FROM a
WHERE a5.cd_adm5=a.cd_adm5 AND a5.equi_adm3 IS NULL
;


-- equivalence chain adm5 -> adm4 -> adm2
WITH a AS(
SELECT cd_adm5, a4.equi_adm2
FROM main.adm5 a5
JOIN main.adm4 a4 ON a5.equi_adm4=a4.cd_adm4
WHERE a4.equi_adm2 IS NOT NULL
)
UPDATE main.adm5 a5
SET equi_adm2=a.equi_adm2
FROM a
WHERE a5.cd_adm5=a.cd_adm5 AND a5.equi_adm2 IS NULL
;

-- equivalence chain adm5 -> adm3 -> adm2
WITH a AS(
SELECT cd_adm5, a3.equi_adm2
FROM main.adm5 a5
JOIN main.adm3 a3 ON a5.equi_adm3=a3.cd_adm3
WHERE a3.equi_adm2 IS NOT NULL
)
UPDATE main.adm5 a5
SET equi_adm2=a.equi_adm2
FROM a
WHERE a5.cd_adm5=a.cd_adm5 AND a5.equi_adm2 IS NULL
;


-- equivalence calculation adm5->adm3
WITH a AS(
SELECT cd_adm3,ST_Area(the_geom) area_g3
FROM main.adm3
), b AS(
SELECT cd_adm5, cd_adm3, equi_adm3,modification_gid_5, ST_Area(ST_Intersection(a5.the_geom,a3.the_geom))/area_g3 prop_g3
FROM main.adm5 a5
LEFT JOIN main.adm3 a3 ON ST_Intersects(a3.the_geom,a5.the_geom)
LEFT JOIN a USING(cd_adm3)
WHERE a5.equi_adm3 IS NULL AND ST_Area(ST_Intersection(a5.the_geom,a3.the_geom))/area_g3 > 0.999
)
UPDATE main.adm5 a5
SET equi_adm3=b.cd_adm3
FROM b
WHERE a5.cd_adm5=b.cd_adm5 AND a5.equi_adm3 IS NULL
;

-- equivalence calculation adm5->adm2
WITH a AS(
SELECT cd_adm2,ST_Area(the_geom) area_g2
FROM main.adm2
), b AS(
SELECT cd_adm5, cd_adm2, equi_adm2,modification_gid_5, ST_Area(ST_Intersection(a5.the_geom,a2.the_geom))/area_g2 prop_g2
FROM main.adm5 a5
LEFT JOIN main.adm2 a2 ON ST_Intersects(a2.the_geom,a5.the_geom)
LEFT JOIN a USING(cd_adm2)
WHERE a5.equi_adm2 IS NULL AND ST_Area(ST_Intersection(a5.the_geom,a2.the_geom))/area_g2 > 0.999
)
UPDATE main.adm5 a5
SET equi_adm2=b.cd_adm2
FROM b
WHERE a5.cd_adm5=b.cd_adm5 AND a5.equi_adm2 IS NULL
;

-- equivalence calculation adm5->adm1
WITH a AS(
SELECT cd_adm1,ST_Area(the_geom) area_g1
FROM main.adm1
), b AS(
SELECT cd_adm5, cd_adm1, equi_adm1,modification_gid_5, ST_Area(ST_Intersection(a5.the_geom,a1.the_geom))/area_g1 prop_g2
FROM main.adm5 a5
LEFT JOIN main.adm1 a1 ON ST_Intersects(a5.the_geom,a1.the_geom)
LEFT JOIN a USING(cd_adm1)
WHERE ST_Area(ST_Intersection(a5.the_geom,a1.the_geom))/area_g1 > 0.999
)
UPDATE main.adm5 a5
SET equi_adm1=b.cd_adm1
FROM b
WHERE a5.cd_adm5=b.cd_adm5 AND a5.equi_adm1 IS NULL
;

-- equivalence calculation adm5->geounit
WITH a AS(
SELECT cd_geounit,ST_Area(the_geom) area_geounit
FROM main.adm0_geounit
), b AS(
SELECT cd_adm5, cd_geounit, equi_geounit,modification_gid_5, ST_Area(ST_Intersection(a5.the_geom,a0.the_geom))/area_geounit prop_g2
FROM main.adm5 a5
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN a USING(cd_geounit)
WHERE ST_Area(ST_Intersection(a5.the_geom,a0.the_geom))/area_geounit > 0.999
)
UPDATE main.adm5 a5
SET equi_geounit=b.cd_geounit
FROM b
WHERE a5.cd_adm5=b.cd_adm5 AND a5.equi_geounit IS NULL
;


-- equivalence adm4 -> adm5
ALTER TABLE main.adm4
ADD CONSTRAINT adm4_equi_adm5_fkey
FOREIGN KEY (equi_adm5)
REFERENCES main.adm5(cd_adm5);

CREATE INDEX main_adm4_equi_adm5_idx ON main.adm4(equi_adm5);

UPDATE main.adm4 a4
SET equi_adm5=a5.cd_adm5
FROM main.adm5 a5
WHERE a5.equi_adm4=a4.cd_adm4 AND a4.equi_adm5 IS NULL;

-- equivalence adm2 -> adm5
ALTER TABLE main.adm2
ADD CONSTRAINT adm2_equi_adm5_fkey
FOREIGN KEY (equi_adm5)
REFERENCES main.adm5(cd_adm5);

CREATE INDEX main_adm2_equi_adm5_idx ON main.adm2(equi_adm5);

UPDATE main.adm2 a2
SET equi_adm5=a5.cd_adm5
FROM main.adm5 a5
WHERE a5.equi_adm2=a2.cd_adm2 AND a2.equi_adm5 IS NULL;

-- equivalence adm1 -> adm5
ALTER TABLE main.adm1
ADD CONSTRAINT adm1_equi_adm5_fkey
FOREIGN KEY (equi_adm5)
REFERENCES main.adm5(cd_adm5);

CREATE INDEX main_adm1_equi_adm5_idx ON main.adm1(equi_adm5);

UPDATE main.adm1 a1
SET equi_adm5=a5.cd_adm5
FROM main.adm5 a5
WHERE a5.equi_adm1=a1.cd_adm1 AND a1.equi_adm5 IS NULL;

-- equivalence geounit -> adm5
ALTER TABLE main.adm0_geounit
ADD CONSTRAINT adm0_geounit_equi_adm5_fkey
FOREIGN KEY (equi_adm5)
REFERENCES main.adm5(cd_adm5);

CREATE INDEX main_adm0_geounit_equi_adm5_idx ON main.adm0_geounit(equi_adm5);

UPDATE main.adm0_geounit ag
SET equi_adm5=a5.cd_adm5
FROM main.adm5 a5
WHERE a5.equi_geounit=ag.cd_geounit AND ag.equi_adm5 IS NULL;




-- Test whether they are some wrong overlaps (more than 20%) betweem geometries of adm5
/*
SELECT a.cd_adm5,b.cd_adm5
FROM main.adm5 a
JOIN main.adm5 b ON a.cd_adm5<b.cd_adm5 AND ST_Intersects(a.the_geom,b.the_geom) AND (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.2 * ST_Area(a.the_geom) OR (ST_Area(ST_Intersection(a.the_geom,b.the_geom)) > 0.2 * ST_Area(b.the_geom)))
LIMIT 20;
*/
















DROP TABLE already_included_gid_5;
