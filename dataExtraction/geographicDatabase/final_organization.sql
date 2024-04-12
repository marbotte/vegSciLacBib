DROP TYPE IF EXISTS t_ref CASCADE;
CREATE TYPE t_ref AS(level_ref int, cd_cat_ref int, cd_ref text);

DROP TABLE IF EXISTS sovereign CASCADE;
CREATE TABLE sovereign
(
    cd_sov char(3) PRIMARY KEY,
    sovereign text,
    ref t_ref
);
SELECT AddGeometryColumn('sovereign','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO sovereign
SELECT COALESCE(sovereign,cd_geounit) cd_sov, COALESCE(name,geounit) sov,(-1,0,COALESCE(sovereign,cd_geounit))::t_ref,ST_MULTI(ST_UNION(a0.the_geom)) the_geom
FROM main.adm0_geounit a0
LEFT JOIN main.country ON sovereign=cd_country
GROUP BY sovereign,COALESCE(sovereign,cd_geounit),COALESCE(name,geounit)
ORDER BY sovereign;

DROP TABLE IF EXISTS geounit CASCADE;
CREATE TABLE geounit
(
    cd_geounit char(3) PRIMARY KEY,
    geounit text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref
);
SELECT AddGeometryColumn('geounit','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO geounit
SELECT cd_geounit,geounit,COALESCE(sovereign,cd_geounit),continent,region,subregion,wb_region,(0,0,cd_geounit)::t_ref,a0.the_geom
FROM main.adm0_geounit a0
LEFT JOIN main.continent USING(cd_continent)
LEFT JOIN main.subregion USING(cd_subregion)
LEFT JOIN main.wb_region USING(cd_wb_region)
;


DROP TABLE IF EXISTS ref_state;
CREATE TEMPORARY TABLE ref_state AS(
WITH a AS(
SELECT (0,1,cd_geounit)::t_ref ref,
    cd_geounit,
    equi_adm1 cd_adm1,
    equi_adm2 cd_adm2,
    equi_adm3 cd_adm3,
    equi_adm4 cd_adm4,
    equi_adm5 cd_adm5
FROM main.adm0_geounit a0
WHERE cd_cat_part=1
UNION
SELECT (1,1,cd_adm1::text)::t_ref,
    a1.equi_geounit,
    a1.cd_adm1,
    a1.equi_adm2,
    a1.equi_adm3,
    a1.equi_adm4,
    a1.equi_adm5
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a1.cd_cat_part=1
)
SELECT DISTINCT ON (cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5) * FROM a ORDER BY cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5,(ref).level_ref
)
;
ALTER TABLE ref_state ADD COLUMN tot_ref t_ref[];
WITH a AS(
SELECT ref,ARRAY[(0,1,cd_geounit),(1,1,cd_adm1::text),(2,1,cd_adm2::text),(3,1,cd_adm3::text),(4,1,cd_adm4::text),(5,1,cd_adm5::text)]::t_ref[] arr_ref
FROM ref_state
),b AS(
SELECT ref,UNNEST(arr_ref) other
FROM a
),c AS(
SELECT ref,ARRAY_AGG(other) tot_ref
FROM b
WHERE (other).cd_ref IS NOT NULL
GROUP BY ref
)
UPDATE ref_state rs
SET tot_ref=c.tot_ref
FROM c
WHERE rs.ref=c.ref;

DROP TABLE IF EXISTS state CASCADE;
CREATE TABLE state(
    cd_state serial PRIMARY KEY,
    state text,
    type_verbatim text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    cd_geounit char(3) REFERENCES geounit(cd_geounit),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref
);
SELECT AddGeometryColumn('state','the_geom',4326,'MULTIPOLYGON',2);

INSERT INTO state(state,cd_sov,cd_geounit,continent,region,subregion,wb_region,ref,the_geom)
SELECT g.geounit state, g.cd_sov,g.cd_geounit,g.continent,g.region,g.subregion,g.wb_region,rs.ref,g.the_geom
FROM ref_state rs
LEFT JOIN geounit g ON (rs.ref).cd_ref=g.cd_geounit
WHERE (rs.ref).level_ref=0
;

INSERT INTO state(state,type_verbatim,cd_sov,cd_geounit,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 state,COALESCE(a1.type_part_verbatim,a1.type_part), g.cd_sov,g.cd_geounit,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_state rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN state s ON (s.ref).level_ref=0 AND rs.cd_geounit=(s.ref).cd_ref
WHERE (rs.ref).level_ref=1 AND s.cd_state IS NULL
;
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

DROP TABLE IF EXISTS ref_substate CASCADE;
CREATE TEMPORARY TABLE ref_substate AS(
WITH A AS(
SELECT  (0,2,cd_geounit)::t_ref ref,
    cd_geounit,
    equi_adm1 cd_adm1,
    equi_adm2 cd_adm2,
    equi_adm3 cd_adm3,
    equi_adm4 cd_adm4,
    equi_adm5 cd_adm5
FROM main.adm0_geounit a0
WHERE cd_cat_part=2
UNION
SELECT (1,2,cd_adm1)::t_ref,
    a1.equi_geounit,
    a1.cd_adm1,
    a1.equi_adm2,
    a1.equi_adm3,
    a1.equi_adm4,
    a1.equi_adm5
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a1.cd_cat_part=2
)
SELECT DISTINCT ON (cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5) * FROM a ORDER BY cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5,(ref).level_ref
);

ALTER TABLE ref_substate ADD COLUMN tot_ref t_ref[];
WITH a AS(
SELECT ref,ARRAY[(0,2,cd_geounit),(1,2,cd_adm1::text),(2,2,cd_adm2::text),(3,2,cd_adm3::text),(4,2,cd_adm4::text),(5,2,cd_adm5::text)]::t_ref[] arr_ref
FROM ref_substate
),b AS(
SELECT ref,UNNEST(arr_ref) other
FROM a
),c AS(
SELECT ref,ARRAY_AGG(other) tot_ref
FROM b
WHERE (other).cd_ref IS NOT NULL
GROUP BY ref
)
UPDATE ref_substate rs
SET tot_ref=c.tot_ref
FROM c
WHERE rs.ref=c.ref;
;


ALTER TABLE ref_substate ADD COLUMN sup t_ref;

WITH a AS(
SELECT ref,(-1,0,sovereign)::t_ref sup
FROM ref_substate rs
LEFT JOIN main.adm0_geounit a0 ON (ref).cd_ref=a0.cd_geounit
WHERE (ref).level_ref=0
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a0.cd_cat_part < 2 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_substate rs
LEFT JOIN main.adm1 a1 ON (ref).cd_ref::int=a1.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a1.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=1
)
UPDATE ref_substate rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref;

WITH l1 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_state
),a AS(
SELECT rs.ref, l1.ref sup, rs.sup sup_old
FROM ref_substate rs
LEFT JOIN l1 ON rs.sup=l1.ref0
WHERE (sup).cd_cat_ref=1
)
UPDATE ref_substate rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

DROP TABLE IF EXISTS substate CASCADE;
CREATE TABLE substate(
    cd_substate serial PRIMARY KEY,
    substate text,
    type_verbatim text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    cd_geounit char(3) REFERENCES geounit(cd_geounit),
    cd_state int REFERENCES state(cd_state),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref
);
SELECT AddGeometryColumn('substate','the_geom',4326,'MULTIPOLYGON',2);

INSERT INTO substate(substate,cd_sov,cd_geounit,cd_state,continent,region,subregion,wb_region,ref,the_geom)
SELECT g.geounit substate, g.cd_sov,g.cd_geounit,sup_s.cd_state,g.continent,g.region,g.subregion,g.wb_region,rs.ref,g.the_geom
FROM ref_substate rs
LEFT JOIN geounit g ON (rs.ref).cd_ref=g.cd_geounit
LEFT JOIN state sup_s ON (rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref
WHERE (rs.ref).level_ref=0
;

INSERT INTO substate(substate,type_verbatim,cd_sov,cd_geounit,cd_state,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 substate,COALESCE(a1.type_part_verbatim,a1.type_part), g.cd_sov,g.cd_geounit,sup_s.cd_state,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_substate rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN state sup_s ON (rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref
LEFT JOIN substate ss ON (
    ((ss.ref).level_ref=0 AND rs.cd_geounit=(ss.ref).cd_ref)
    OR ((ss.ref).level_ref=1 AND rs.cd_adm1::text=(ss.ref).cd_ref))
WHERE (rs.ref).level_ref=1 AND (rs.sup).cd_cat_ref=1 AND ss.cd_substate IS NULL
;

INSERT INTO substate(substate,type_verbatim,cd_geounit,cd_state,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 substate, COALESCE(a1.type_part_verbatim,a1.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_substate rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN state sup_s ON (rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref
LEFT JOIN substate ss ON (
    ((ss.ref).level_ref=0 AND rs.cd_geounit=(ss.ref).cd_ref)
    OR ((ss.ref).level_ref=1 AND rs.cd_adm1::text=(ss.ref).cd_ref))
WHERE (rs.ref).level_ref=1 AND (rs.sup).cd_cat_ref=0 AND ss.cd_substate IS NULL
;
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


DROP TABLE IF EXISTS ref_department;
CREATE TEMPORARY TABLE ref_department AS(
WITH A AS(
SELECT  (0,3,cd_geounit)::t_ref ref,
    cd_geounit,
    equi_adm1 cd_adm1,
    equi_adm2 cd_adm2,
    equi_adm3 cd_adm3,
    equi_adm4 cd_adm4,
    equi_adm5 cd_adm5
FROM main.adm0_geounit a0
WHERE cd_cat_part=3
UNION
SELECT (1,3,cd_adm1)::t_ref,
    a1.equi_geounit,
    a1.cd_adm1,
    a1.equi_adm2,
    a1.equi_adm3,
    a1.equi_adm4,
    a1.equi_adm5
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a1.cd_cat_part=3
UNION
SELECT (2,3,cd_adm2)::t_ref,
    a2.equi_geounit,
    a2.equi_adm1,
    a2.cd_adm2,
    a2.equi_adm3,
    a2.equi_adm4,
    a2.equi_adm5
FROM main.adm2 a2
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a2.cd_cat_part=3
)
SELECT DISTINCT ON (cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5) * FROM a ORDER BY cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5,(ref).level_ref
);

ALTER TABLE ref_department ADD COLUMN tot_ref t_ref[];
WITH a AS(
SELECT ref,ARRAY[(0,3,cd_geounit),(1,3,cd_adm1::text),(2,3,cd_adm2::text),(3,3,cd_adm3::text),(4,3,cd_adm4::text),(5,3,cd_adm5::text)]::t_ref[] arr_ref
FROM ref_department
),b AS(
SELECT ref,UNNEST(arr_ref) other
FROM a
),c AS(
SELECT ref,ARRAY_AGG(other) tot_ref
FROM b
WHERE (other).cd_ref IS NOT NULL
GROUP BY ref
)
UPDATE ref_department rs
SET tot_ref=c.tot_ref
FROM c
WHERE rs.ref=c.ref;
;

ALTER TABLE ref_department DROP COLUMN IF EXISTS sup;
ALTER TABLE ref_department ADD COLUMN sup t_ref;

WITH a AS(
SELECT ref,(-1,0,sovereign)::t_ref sup
FROM ref_department rs
LEFT JOIN main.adm0_geounit a0 ON (ref).cd_ref=a0.cd_geounit
WHERE (ref).level_ref=0
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a1.cd_cat_part < 3 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 3 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_department rs
LEFT JOIN main.adm1 a1 ON (ref).cd_ref::int=a1.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a1.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=1
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a2.cd_cat_part < 3 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 3 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 3 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_department rs
LEFT JOIN main.adm2 a2 ON (ref).cd_ref::int=a2.cd_adm2
LEFT JOIN main.adm1 a1 ON a1.cd_adm1=a2.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a1.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=2
)
UPDATE ref_department rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref;

WITH l2 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_substate
),a AS(
SELECT DISTINCT rs.ref, l2.ref sup, rs.sup sup_old
FROM ref_department rs
LEFT JOIN l2 ON rs.sup=l2.ref0
WHERE (sup).cd_cat_ref=2
)
UPDATE ref_department rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;


WITH l1 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_state
),a AS(
SELECT DISTINCT rs.ref, l1.ref sup, rs.sup sup_old
FROM ref_department rs
LEFT JOIN l1 ON rs.sup=l1.ref0
WHERE (sup).cd_cat_ref=1
)
UPDATE ref_department rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

DROP TABLE IF EXISTS department CASCADE;
CREATE TABLE department(
    cd_department serial PRIMARY KEY,
    department text,
    type_verbatim text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    cd_geounit char(3) REFERENCES geounit(cd_geounit),
    cd_state int REFERENCES state(cd_state),
    cd_substate int REFERENCES substate(cd_substate),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref
);
SELECT AddGeometryColumn('department','the_geom',4326,'MULTIPOLYGON',2);

/*
WITH a AS(
SELECT (ref).level_ref ref_tab,(sup).level_ref sup_ref_tab,(sup).cd_cat_ref sup_cd_cat
FROM ref_department
)
SELECT ref_tab,sup_ref_tab, sup_cd_cat,count(*)
FROM a
GROUP BY ref_tab,sup_ref_tab, sup_cd_cat
ORDER BY ref_tab,sup_ref_tab, sup_cd_cat
;
*/

INSERT INTO department(department,cd_sov,cd_geounit,cd_state,cd_substate,continent,region,subregion,wb_region,ref,the_geom)
SELECT g.geounit department, g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,g.continent,g.region,g.subregion,g.wb_region,rs.ref,g.the_geom
FROM ref_department rs
LEFT JOIN geounit g ON (rs.ref).cd_ref=g.cd_geounit
LEFT JOIN substate sup_ss ON ((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref)
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_ss.cd_state=sup_s.cd_state))
WHERE (rs.ref).level_ref=0
;

INSERT INTO department(department,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 department,  COALESCE(a1.type_part_verbatim,a1.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_department rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN substate sup_ss ON (rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref=2 AND sup_ss.cd_state=sup_s.cd_state)
LEFT JOIN department d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref))
WHERE (rs.ref).level_ref=1 AND d.cd_department IS NULL
;

INSERT INTO department(department,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,continent,region,subregion,wb_region,ref,the_geom)
SELECT a2.adm2 department,  COALESCE(a2.type_part_verbatim,a2.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a2.the_geom
FROM ref_department rs
LEFT JOIN main.adm2 a2 ON (rs.ref).cd_ref::int=a2.cd_adm2
LEFT JOIN geounit g ON a2.cd_geounit=g.cd_geounit
LEFT JOIN substate sup_ss ON (rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref=2 AND sup_ss.cd_state=sup_s.cd_state)
LEFT JOIN department d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=2 AND d.cd_department IS NULL
;

DROP TABLE IF EXISTS ref_district;
CREATE TEMPORARY TABLE ref_district AS(
WITH A AS(
SELECT  (0,4,cd_geounit)::t_ref ref,
    cd_geounit,
    equi_adm1 cd_adm1,
    equi_adm2 cd_adm2,
    equi_adm3 cd_adm3,
    equi_adm4 cd_adm4,
    equi_adm5 cd_adm5
FROM main.adm0_geounit a0
WHERE cd_cat_part=4
UNION
SELECT (1,4,cd_adm1)::t_ref,
    a1.equi_geounit,
    a1.cd_adm1,
    a1.equi_adm2,
    a1.equi_adm3,
    a1.equi_adm4,
    a1.equi_adm5
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a1.cd_cat_part=4
UNION
SELECT (2,4,cd_adm2)::t_ref,
    a2.equi_geounit,
    a2.equi_adm1,
    a2.cd_adm2,
    a2.equi_adm3,
    a2.equi_adm4,
    a2.equi_adm5
FROM main.adm2 a2
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a2.cd_cat_part=4
UNION
SELECT (3,4,cd_adm3)::t_ref,
    a3.equi_geounit,
    a3.equi_adm1,
    a3.equi_adm2,
    a3.cd_adm3,
    a3.equi_adm4,
    a3.equi_adm5
FROM main.adm3 a3
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a3.cd_cat_part=4
UNION
SELECT (4,4,cd_adm4)::t_ref,
    a4.equi_geounit,
    a4.equi_adm1,
    a4.equi_adm2,
    a4.equi_adm3,
    a4.cd_adm4,
    a4.equi_adm5
FROM main.adm4 a4
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a4.cd_cat_part=4
UNION
SELECT (5,4,cd_adm4)::t_ref,
    a5.equi_geounit,
    a5.equi_adm1,
    a5.equi_adm2,
    a5.equi_adm3,
    a5.equi_adm4,
    a5.cd_adm5
FROM main.adm5 a5
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a5.cd_cat_part=4
)
SELECT DISTINCT ON (cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5) * FROM a ORDER BY cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5,(ref).level_ref
);

ALTER TABLE ref_district ADD COLUMN tot_ref t_ref[];
WITH a AS(
SELECT ref,ARRAY[(0,4,cd_geounit),(1,4,cd_adm1::text),(2,4,cd_adm2::text),(3,4,cd_adm3::text),(4,4,cd_adm4::text),(5,4,cd_adm5::text)]::t_ref[] arr_ref
FROM ref_district
),b AS(
SELECT ref,UNNEST(arr_ref) other
FROM a
),c AS(
SELECT ref,ARRAY_AGG(other) tot_ref
FROM b
WHERE (other).cd_ref IS NOT NULL
GROUP BY ref
)
UPDATE ref_district rs
SET tot_ref=c.tot_ref
FROM c
WHERE rs.ref=c.ref;
;

ALTER TABLE ref_district DROP COLUMN IF EXISTS sup;
ALTER TABLE ref_district ADD COLUMN sup t_ref;

WITH a AS(
SELECT ref,(-1,0,sovereign)::t_ref sup
FROM ref_district rs
LEFT JOIN main.adm0_geounit a0 ON (ref).cd_ref=a0.cd_geounit
WHERE (ref).level_ref=0
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a0.cd_cat_part < 4 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_district rs
LEFT JOIN main.adm1 a1 ON (ref).cd_ref::int=a1.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a1.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=1
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a1.cd_cat_part < 4 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 4 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_district rs
LEFT JOIN main.adm2 a2 ON (ref).cd_ref::int=a2.cd_adm2
LEFT JOIN main.adm1 a1 ON a1.cd_adm1=a2.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a2.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=2
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a2.cd_cat_part < 4 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 4 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 4 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_district rs
LEFT JOIN main.adm3 a3 ON (ref).cd_ref::int=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON a2.cd_adm2=a3.cd_adm2
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a3.cd_adm1=a1.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a3.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=3
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a3.cd_cat_part < 4 THEN (3,a3.cd_cat_part,a3.cd_adm3::text)::t_ref
            WHEN a2.cd_cat_part < 4 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 4 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 4 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_district rs
LEFT JOIN main.adm4 a4 ON (ref).cd_ref::int=a4.cd_adm4
LEFT JOIN main.adm3 a3 ON a4.cd_adm4=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON (a2.cd_adm2=a3.cd_adm2 OR a2.cd_adm2=a3.cd_adm2)
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a1.cd_adm1=a3.cd_adm1 OR a1.cd_adm1=a4.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a4.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=4
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a3.cd_cat_part < 4 THEN (3,a3.cd_cat_part,a3.cd_adm3::text)::t_ref
            WHEN a2.cd_cat_part < 4 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 4 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 4 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_district rs
LEFT JOIN main.adm5 a5 ON (ref).cd_ref::int=a5.cd_adm5
LEFT JOIN main.adm4 a4 ON a5.cd_adm5=a4.cd_adm4
LEFT JOIN main.adm3 a3 ON a4.cd_adm4=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON (a2.cd_adm2=a3.cd_adm2 OR a2.cd_adm2=a3.cd_adm2)
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a1.cd_adm1=a3.cd_adm1 OR a1.cd_adm1=a4.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a5.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=5
),b AS(
SELECT DISTINCT ON (ref) ref,sup
FROM a
ORDER BY ref,(sup).cd_cat_ref DESC, (sup).level_ref DESC
)
UPDATE ref_district rs
SET sup=b.sup
FROM b
WHERE b.ref=rs.ref;



-- We've got a problem:
-- no 2 in cd_cat_ref de sup
-- and some nulls
/*SELECT (ref).level_ref,(ref).cd_cat_ref,(sup).cd_cat_ref,count(*) FROM ref_district GROUP BY (ref).level_ref,(ref).cd_cat_ref,(sup).cd_cat_ref ORDER BY (ref).level_ref;
*/

WITH l3 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_department
),a AS(
SELECT DISTINCT rs.ref, l3.ref sup, rs.sup sup_old
FROM ref_district rs
LEFT JOIN l3 ON rs.sup=l3.ref0
WHERE (sup).cd_cat_ref=3
)
UPDATE ref_district rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

WITH l2 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_substate
),a AS(
SELECT DISTINCT rs.ref, l2.ref sup, rs.sup sup_old
FROM ref_district rs
LEFT JOIN l2 ON rs.sup=l2.ref0
WHERE (sup).cd_cat_ref=2
)
UPDATE ref_district rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;


WITH l1 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_state
),a AS(
SELECT DISTINCT rs.ref, l1.ref sup, rs.sup sup_old
FROM ref_district rs
LEFT JOIN l1 ON rs.sup=l1.ref0
WHERE (sup).cd_cat_ref=1
)
UPDATE ref_district rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

DROP TABLE IF EXISTS district CASCADE;
CREATE TABLE district(
    cd_district serial PRIMARY KEY,
    district text,
    type_verbatim text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    cd_geounit char(3) REFERENCES geounit(cd_geounit),
    cd_state int REFERENCES state(cd_state),
    cd_substate int REFERENCES substate(cd_substate),
    cd_department int REFERENCES department(cd_department),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref
);
SELECT AddGeometryColumn('district','the_geom',4326,'MULTIPOLYGON',2);

/*
WITH a AS(
SELECT (ref).level_ref ref_tab,(sup).level_ref sup_ref_tab,(sup).cd_cat_ref sup_cd_cat
FROM ref_district
)
SELECT ref_tab,sup_ref_tab, sup_cd_cat,count(*)
FROM a
GROUP BY ref_tab,sup_ref_tab, sup_cd_cat
ORDER BY ref_tab,sup_ref_tab, sup_cd_cat
;
*/

INSERT INTO district(district,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT g.geounit district, g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,g.the_geom
FROM ref_district rs
LEFT JOIN geounit g ON (rs.ref).cd_ref=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
WHERE (rs.ref).level_ref=0
;

INSERT INTO district(district,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 district,  COALESCE(a1.type_part_verbatim,a1.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_district rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN district d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref))
WHERE (rs.ref).level_ref=1 AND d.cd_district IS NULL
;

INSERT INTO district(district,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a2.adm2 district,  COALESCE(a2.type_part_verbatim,a2.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a2.the_geom
FROM ref_district rs
LEFT JOIN main.adm2 a2 ON (rs.ref).cd_ref::int=a2.cd_adm2
LEFT JOIN geounit g ON a2.cd_geounit=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN district d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=2 AND d.cd_district IS NULL
;


INSERT INTO district(district,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a3.adm3 district,  COALESCE(a3.type_part_verbatim,a3.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a3.the_geom
FROM ref_district rs
LEFT JOIN main.adm3 a3 ON (rs.ref).cd_ref::int=a3.cd_adm3
LEFT JOIN geounit g ON a3.cd_geounit=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN district d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=3 AND d.cd_district IS NULL
;

INSERT INTO district(district,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a4.adm4 district,  COALESCE(a4.type_part_verbatim,a4.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a4.the_geom
FROM ref_district rs
LEFT JOIN main.adm4 a4 ON (rs.ref).cd_ref::int=a4.cd_adm4
LEFT JOIN geounit g ON a4.cd_geounit=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN district d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=4 AND rs.cd_adm4::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=4 AND d.cd_district IS NULL
;

INSERT INTO district(district,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a5.adm5 district,  COALESCE(a5.type_part_verbatim,a5.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a5.the_geom
FROM ref_district rs
LEFT JOIN main.adm5 a5 ON (rs.ref).cd_ref::int=a5.cd_adm5
LEFT JOIN geounit g ON a5.cd_geounit=g.cd_geounit
LEFT JOIN department sup_d ON (rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref
LEFT JOIN substate sup_ss ON (((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN district d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=4 AND rs.cd_adm4::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=5 AND rs.cd_adm5::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=5 AND d.cd_district IS NULL
;

DROP TABLE IF EXISTS ref_municipality;
CREATE TEMPORARY TABLE ref_municipality AS(
WITH A AS(
SELECT  (0,5,cd_geounit)::t_ref ref,
    cd_geounit,
    equi_adm1 cd_adm1,
    equi_adm2 cd_adm2,
    equi_adm3 cd_adm3,
    equi_adm4 cd_adm4,
    equi_adm5 cd_adm5
FROM main.adm0_geounit a0
WHERE cd_cat_part=5
UNION
SELECT (1,5,cd_adm1)::t_ref,
    a1.equi_geounit,
    a1.cd_adm1,
    a1.equi_adm2,
    a1.equi_adm3,
    a1.equi_adm4,
    a1.equi_adm5
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a1.cd_cat_part=5
UNION
SELECT (2,5,cd_adm2)::t_ref,
    a2.equi_geounit,
    a2.equi_adm1,
    a2.cd_adm2,
    a2.equi_adm3,
    a2.equi_adm4,
    a2.equi_adm5
FROM main.adm2 a2
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a2.cd_cat_part=5
UNION
SELECT (3,5,cd_adm3)::t_ref,
    a3.equi_geounit,
    a3.equi_adm1,
    a3.equi_adm2,
    a3.cd_adm3,
    a3.equi_adm4,
    a3.equi_adm5
FROM main.adm3 a3
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a3.cd_cat_part=5
UNION
SELECT (4,5,cd_adm4)::t_ref,
    a4.equi_geounit,
    a4.equi_adm1,
    a4.equi_adm2,
    a4.equi_adm3,
    a4.cd_adm4,
    a4.equi_adm5
FROM main.adm4 a4
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a4.cd_cat_part=5
UNION
SELECT (5,5,cd_adm5)::t_ref,
    a5.equi_geounit,
    a5.equi_adm1,
    a5.equi_adm2,
    a5.equi_adm3,
    a5.equi_adm4,
    a5.cd_adm5
FROM main.adm5 a5
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
WHERE a5.cd_cat_part=5
)
SELECT DISTINCT ON (cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5) * FROM a ORDER BY cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5,(ref).level_ref
);

ALTER TABLE ref_municipality ADD COLUMN tot_ref t_ref[];
WITH a AS(
SELECT ref,ARRAY[(0,5,cd_geounit),(1,5,cd_adm1::text),(2,5,cd_adm2::text),(3,5,cd_adm3::text),(4,5,cd_adm4::text),(5,5,cd_adm5::text)]::t_ref[] arr_ref
FROM ref_municipality
),b AS(
SELECT ref,UNNEST(arr_ref) other
FROM a
),c AS(
SELECT ref,ARRAY_AGG(other) tot_ref
FROM b
WHERE (other).cd_ref IS NOT NULL
GROUP BY ref
)
UPDATE ref_municipality rs
SET tot_ref=c.tot_ref
FROM c
WHERE rs.ref=c.ref;
;

ALTER TABLE ref_municipality DROP COLUMN IF EXISTS sup;
ALTER TABLE ref_municipality ADD COLUMN sup t_ref;

WITH a AS(
SELECT ref,(-1,0,sovereign)::t_ref sup
FROM ref_municipality rs
LEFT JOIN main.adm0_geounit a0 ON (ref).cd_ref=a0.cd_geounit
WHERE (ref).level_ref=0
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a0.cd_cat_part < 5 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_municipality rs
LEFT JOIN main.adm1 a1 ON (ref).cd_ref::int=a1.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a1.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=1
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a1.cd_cat_part < 5 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 5 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_municipality rs
LEFT JOIN main.adm2 a2 ON (ref).cd_ref::int=a2.cd_adm2
LEFT JOIN main.adm1 a1 ON a1.cd_adm1=a2.cd_adm1
LEFT JOIN main.adm0_geounit a0 ON a2.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=2
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a2.cd_cat_part < 5 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 5 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 5 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_municipality rs
LEFT JOIN main.adm3 a3 ON (ref).cd_ref::int=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON a2.cd_adm2=a3.cd_adm2
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a3.cd_adm1=a1.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a3.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=3
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a3.cd_cat_part < 5 THEN (3,a3.cd_cat_part,a3.cd_adm3::text)::t_ref
            WHEN a2.cd_cat_part < 5 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 5 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 5 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_municipality rs
LEFT JOIN main.adm4 a4 ON (ref).cd_ref::int=a4.cd_adm4
LEFT JOIN main.adm3 a3 ON a4.cd_adm4=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON (a2.cd_adm2=a3.cd_adm2 OR a2.cd_adm2=a3.cd_adm2)
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a1.cd_adm1=a3.cd_adm1 OR a1.cd_adm1=a4.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a4.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=4
UNION
SELECT ref,
    COALESCE(
        CASE
            WHEN a3.cd_cat_part < 5 THEN (3,a3.cd_cat_part,a3.cd_adm3::text)::t_ref
            WHEN a2.cd_cat_part < 5 THEN (2,a2.cd_cat_part,a2.cd_adm2::text)::t_ref
            WHEN a1.cd_cat_part < 5 THEN (1,a1.cd_cat_part,a1.cd_adm1::text)::t_ref
            WHEN a0.cd_cat_part < 5 THEN (0,a0.cd_cat_part,a0.cd_geounit)::t_ref
            ELSE (-1,0,sovereign)::t_ref
        END
        ) sup
FROM ref_municipality rs
LEFT JOIN main.adm5 a5 ON (ref).cd_ref::int=a5.cd_adm5
LEFT JOIN main.adm4 a4 ON a5.cd_adm5=a4.cd_adm4
LEFT JOIN main.adm3 a3 ON a4.cd_adm4=a3.cd_adm3
LEFT JOIN main.adm2 a2 ON (a2.cd_adm2=a3.cd_adm2 OR a2.cd_adm2=a3.cd_adm2)
LEFT JOIN main.adm1 a1 ON (a1.cd_adm1=a2.cd_adm1 OR a1.cd_adm1=a3.cd_adm1 OR a1.cd_adm1=a4.cd_adm1)
LEFT JOIN main.adm0_geounit a0 ON a5.cd_geounit=a0.cd_geounit
WHERE (ref).level_ref=5
), b AS(
SELECT DISTINCT ON (ref) ref,sup
FROM a
WHERE (sup).cd_cat_ref IS NOT NULL AND (sup).level_ref IS NOT NULL AND (sup).cd_ref IS NOT NULL
ORDER BY ref,(sup).cd_cat_ref DESC, (sup).level_ref DESC
)
UPDATE ref_municipality rs
SET sup=b.sup
FROM b
WHERE b.ref=rs.ref;



-- We've got a problem:
-- no 2 in cd_cat_ref de sup
-- and some nulls
/*SELECT (ref).level_ref,(ref).cd_cat_ref,(sup).cd_cat_ref,count(*) FROM ref_municipality GROUP BY (ref).level_ref,(ref).cd_cat_ref,(sup).cd_cat_ref ORDER BY (ref).level_ref;
*/
ALTER TABLE ref_municipality DROP column if exists pb_sup;
ALTER TABLE ref_municipality ADD column pb_sup boolean NOT NULL default false;
WITH l4 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_district
),a AS(
SELECT DISTINCT rs.ref, l4.ref sup, rs.sup sup_old
FROM ref_municipality rs
LEFT JOIN l4 ON rs.sup=l4.ref0
WHERE (sup).cd_cat_ref=4
),b AS (
UPDATE ref_municipality rs
SET pb_sup=true
FROM a
WHERE a.ref=rs.ref AND a.sup IS NULL
)
UPDATE ref_municipality rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref AND a.sup IS NOT NULL
;
/*
I do not understand why we have to do the following, but seems it is the only solution... and it works

SELECT (ref).level_ref,(sup).level_ref level_ref_sup,(sup).cd_cat_ref cd_cat_sup,count(*)
FROM ref_municipality
WHERE pb_sup
GROUP BY (ref).level_ref,(sup).level_ref ,(sup).cd_cat_ref
;

WITH A AS(
SELECT ref,(ref).cd_ref::int cd_adm4,pb_sup
FROM ref_municipality
WHERE (ref).level_ref=4 AND pb_sup
)
SELECT ref,(3,a3.cd_cat_part,cd_adm3
FROM a
LEFT JOIN main.adm4 a4 USING (cd_adm4)
LEFT JOIN main.adm3 a3 USING (cd_adm3)
WHERE a3.cd_cat_part<5
;
*/

WITH l3 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_department
),a AS(
SELECT DISTINCT rs.ref, l3.ref sup, rs.sup sup_old
FROM ref_municipality rs
LEFT JOIN l3 ON rs.sup=l3.ref0
WHERE (sup).cd_cat_ref=3
),b AS (
UPDATE ref_municipality rs
SET pb_sup=true
FROM a
WHERE a.ref=rs.ref AND a.sup IS NULL
)
UPDATE ref_municipality rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

WITH l2 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_substate
),a AS(
SELECT DISTINCT rs.ref, l2.ref sup, rs.sup sup_old
FROM ref_municipality rs
LEFT JOIN l2 ON rs.sup=l2.ref0
WHERE (sup).cd_cat_ref=2
)
UPDATE ref_municipality rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;


WITH l1 AS(
SELECT ref,UNNEST(tot_ref) ref0
FROM ref_state
),a AS(
SELECT DISTINCT rs.ref, l1.ref sup, rs.sup sup_old
FROM ref_municipality rs
LEFT JOIN l1 ON rs.sup=l1.ref0
WHERE (sup).cd_cat_ref=1
)
UPDATE ref_municipality rs
SET sup=a.sup
FROM a
WHERE a.ref=rs.ref
;

DROP TABLE IF EXISTS municipality CASCADE;
CREATE TABLE municipality(
    cd_municipality serial PRIMARY KEY,
    municipality text,
    type_verbatim text,
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    cd_geounit char(3) REFERENCES geounit(cd_geounit),
    cd_state int REFERENCES state(cd_state),
    cd_substate int REFERENCES substate(cd_substate),
    cd_department int REFERENCES department(cd_department),
    cd_district int REFERENCES district(cd_district),
    continent text,
    region text,
    subregion text,
    wb_region text,
    ref t_ref UNIQUE
);
SELECT AddGeometryColumn('municipality','the_geom',4326,'MULTIPOLYGON',2);

/*
WITH a AS(
SELECT (ref).level_ref ref_tab,(sup).level_ref sup_ref_tab,(sup).cd_cat_ref sup_cd_cat
FROM ref_municipality
)
SELECT ref_tab,sup_ref_tab, sup_cd_cat,count(*)
FROM a
GROUP BY ref_tab,sup_ref_tab, sup_cd_cat
ORDER BY ref_tab,sup_ref_tab, sup_cd_cat
;
*/

INSERT INTO municipality(municipality,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,continent,region,subregion,wb_region,ref,the_geom)
SELECT g.geounit municipality, g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,sup_dt.cd_district,g.continent,g.region,g.subregion,g.wb_region,rs.ref,g.the_geom
FROM ref_municipality rs
LEFT JOIN geounit g ON (rs.ref).cd_ref=g.cd_geounit
LEFT JOIN district sup_dt ON (rs.sup).cd_cat_ref=4 AND rs.sup=sup_dt.ref
LEFT JOIN department sup_d ON ((rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref) OR ((rs.sup).cd_cat_ref>3 AND sup_dt.cd_substate=sup_d.cd_substate)
LEFT JOIN substate sup_ss ON ((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND (sup_dt.cd_substate=sup_ss.cd_substate OR sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_dt.cd_state=sup_s.cd_state OR sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
WHERE (rs.ref).level_ref=0
;

INSERT INTO municipality(municipality,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,continent,region,subregion,wb_region,ref,the_geom)
SELECT a1.adm1 municipality,  COALESCE(a1.type_part_verbatim,a1.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a1.the_geom
FROM ref_municipality rs
LEFT JOIN main.adm1 a1 ON (rs.ref).cd_ref::int=a1.cd_adm1
LEFT JOIN geounit g ON a1.cd_geounit=g.cd_geounit
LEFT JOIN district sup_dt ON (rs.sup).cd_cat_ref=4 AND rs.sup=sup_dt.ref
LEFT JOIN department sup_d ON ((rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref) OR ((rs.sup).cd_cat_ref>3 AND sup_dt.cd_substate=sup_d.cd_substate)
LEFT JOIN substate sup_ss ON ((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND (sup_dt.cd_substate=sup_ss.cd_substate OR sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_dt.cd_state=sup_s.cd_state OR sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN municipality d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref))
WHERE (rs.ref).level_ref=1 AND d.cd_municipality IS NULL
;

INSERT INTO municipality(municipality,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,continent,region,subregion,wb_region,ref,the_geom)
SELECT a2.adm2 municipality,  COALESCE(a2.type_part_verbatim,a2.type_part),g.cd_sov,g.cd_geounit,sup_s.cd_state,sup_ss.cd_substate,sup_d.cd_department,sup_dt.cd_district,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a2.the_geom
FROM ref_municipality rs
LEFT JOIN main.adm2 a2 ON (rs.ref).cd_ref::int=a2.cd_adm2
LEFT JOIN geounit g ON a2.cd_geounit=g.cd_geounit
LEFT JOIN district sup_dt ON (rs.sup).cd_cat_ref=4 AND rs.sup=sup_dt.ref
LEFT JOIN department sup_d ON ((rs.sup).cd_cat_ref=3 AND rs.sup=sup_d.ref) OR ((rs.sup).cd_cat_ref>3 AND sup_dt.cd_substate=sup_d.cd_substate)
LEFT JOIN substate sup_ss ON ((rs.sup).cd_cat_ref=2 AND rs.sup=sup_ss.ref) OR ((rs.sup).cd_cat_ref>2 AND (sup_dt.cd_substate=sup_ss.cd_substate OR sup_d.cd_substate=sup_ss.cd_substate))
LEFT JOIN state sup_s ON ((rs.sup).cd_cat_ref=1 AND rs.sup=sup_s.ref) OR ((rs.sup).cd_cat_ref>1 AND (sup_dt.cd_state=sup_s.cd_state OR sup_d.cd_state=sup_s.cd_state OR sup_ss.cd_state=sup_s.cd_state))
LEFT JOIN municipality d ON (
    ((d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref)
    OR ((d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref)
    OR ((d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref)
    )
WHERE (rs.ref).level_ref=2 AND d.cd_municipality IS NULL
;


--- This is taking forever... change of strategy
ALTER TABLE ref_municipality DROP COLUMN IF EXISTS cd_district;
ALTER TABLE ref_municipality ADD COLUMN cd_district int;
ALTER TABLE ref_municipality DROP COLUMN IF EXISTS cd_department;
ALTER TABLE ref_municipality ADD COLUMN cd_department int;
ALTER TABLE ref_municipality DROP COLUMN IF EXISTS cd_substate;
ALTER TABLE ref_municipality ADD COLUMN cd_substate int;
ALTER TABLE ref_municipality DROP COLUMN IF EXISTS cd_state;
ALTER TABLE ref_municipality ADD COLUMN cd_state int;

WITH a AS(
SELECT rs.ref,sup_dt.cd_district,sup_dt.cd_department,sup_dt.cd_substate,sup_dt.cd_state
FROM ref_municipality rs
LEFT JOIN district sup_dt ON rs.sup=sup_dt.ref
WHERE (rs.sup).cd_cat_ref=4
)
UPDATE ref_municipality rs
SET cd_district=a.cd_district, cd_department=a.cd_department, cd_substate=a.cd_substate, cd_state=a.cd_state
FROM a
WHERE rs.ref=a.ref AND a.cd_district IS NOT NULL
;

WITH a AS(
SELECT rs.ref,sup_d.cd_department,sup_d.cd_substate,sup_d.cd_state
FROM ref_municipality rs
LEFT JOIN department sup_d ON rs.sup=sup_d.ref
WHERE (rs.sup).cd_cat_ref=3
)
UPDATE ref_municipality rs
SET cd_department=a.cd_department, cd_substate=a.cd_substate, cd_state=a.cd_state
FROM a
WHERE rs.ref=a.ref AND a.cd_department IS NOT NULL AND rs.cd_department IS NULL
;

WITH a AS(
SELECT rs.ref,sup_ss.cd_substate,sup_ss.cd_state
FROM ref_municipality rs
LEFT JOIN substate sup_ss ON rs.sup=sup_ss.ref
WHERE (rs.sup).cd_cat_ref=2
)
UPDATE ref_municipality rs
SET cd_substate=a.cd_substate, cd_state=a.cd_state
FROM a
WHERE rs.ref=a.ref AND a.cd_substate IS NOT NULL AND rs.cd_department IS NULL
;

WITH a AS(
SELECT rs.ref,sup_s.cd_state
FROM ref_municipality rs
LEFT JOIN state sup_s ON rs.sup=sup_s.ref
WHERE (rs.sup).cd_cat_ref=1
)
UPDATE ref_municipality rs
SET  cd_state=a.cd_state
FROM a
WHERE rs.ref=a.ref AND a.cd_state IS NOT NULL AND rs.cd_department IS NULL
;

ALTER TABLE ref_municipality DROP COLUMN IF EXISTS already;
ALTER TABLE ref_municipality ADD COLUMN already boolean;

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);
WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);


INSERT INTO municipality(municipality,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,continent,region,subregion,wb_region,ref,the_geom)
SELECT a3.adm3 municipality,  COALESCE(a3.type_part_verbatim,a3.type_part),g.cd_sov,g.cd_geounit,rs.cd_state,rs.cd_substate,rs.cd_department,rs.cd_district,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a3.the_geom
FROM ref_municipality rs
LEFT JOIN main.adm3 a3 ON (rs.ref).cd_ref::int=a3.cd_adm3
LEFT JOIN geounit g ON a3.cd_geounit=g.cd_geounit
WHERE (rs.ref).level_ref=3 AND NOT rs.already
;
WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);


WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=4 AND rs.cd_adm4::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=5 AND rs.cd_adm5::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

INSERT INTO municipality(municipality,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,continent,region,subregion,wb_region,ref,the_geom)
SELECT a4.adm4 municipality,  COALESCE(a4.type_part_verbatim,a4.type_part),g.cd_sov,g.cd_geounit,rs.cd_state,rs.cd_substate,rs.cd_department,rs.cd_district,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a4.the_geom
FROM ref_municipality rs
LEFT JOIN main.adm4 a4 ON (rs.ref).cd_ref::int=a4.cd_adm4
LEFT JOIN geounit g ON a4.cd_geounit=g.cd_geounit
WHERE (rs.ref).level_ref=4 AND NOT rs.already
;

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=0 AND rs.cd_geounit=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=1 AND rs.cd_adm1::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=2 AND rs.cd_adm2::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=3 AND rs.cd_adm3::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=4 AND rs.cd_adm4::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

WITH a AS(
SELECT rs.ref, d.cd_municipality IS NOT NULL already
FROM ref_municipality rs
LEFT JOIN municipality d ON (d.ref).level_ref=5 AND rs.cd_adm5::text=(d.ref).cd_ref
)
UPDATE ref_municipality rs
SET already=a.already
FROM a
WHERE rs.ref=a.ref AND (rs.already IS NULL OR NOT rs.already);

INSERT INTO municipality(municipality,type_verbatim,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,continent,region,subregion,wb_region,ref,the_geom)
SELECT a5.adm5 municipality,  COALESCE(a5.type_part_verbatim,a5.type_part),g.cd_sov,g.cd_geounit,rs.cd_state,rs.cd_substate,rs.cd_department,rs.cd_district,g.continent,g.region,g.subregion,g.wb_region,rs.ref,a5.the_geom
FROM ref_municipality rs
LEFT JOIN main.adm5 a5 ON (rs.ref).cd_ref::int=a5.cd_adm5
LEFT JOIN geounit g ON a5.cd_geounit=g.cd_geounit
WHERE (rs.ref).level_ref=5 AND NOT rs.already
;

----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------- NAMES ----------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
DROP TYPE IF EXISTS t_ref_name CASCADE;
CREATE TYPE t_ref_name AS (level_ref int,cd_cat_ref int ,cd_name int);
DROP TABLE IF EXISTS municipality_names;
CREATE TABLE municipality_names
(
    cd_municipality int REFERENCES municipality(cd_municipality),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref,
    ref_name t_ref_name,
    trust int NOT NULL DEFAULT 10,
    UNIQUE(cd_municipality,ref_name)
);


INSERT INTO municipality_names(cd_municipality,ref,string,orig,name_type,cd_lang,locale,ref_name)
SELECT cd_municipality,(ref),string,orig,name_type,cd_lang,locale, (0,a0.cd_cat_part,n0.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm0_geounit a0 ON rm.cd_geounit=a0.cd_geounit
LEFT JOIN main.adm0_names n0 ON rm.cd_geounit=n0.cd_geounit
WHERE rm.cd_geounit IS NOT NULL
UNION
SELECT cd_municipality,(ref),string,NULL orig,name_type,cd_lang,locale, (1,a1.cd_cat_part,n1.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm1 a1 ON rm.cd_adm1=a1.cd_adm1
LEFT JOIN main.adm1_names n1 ON rm.cd_adm1=n1.cd_adm1
WHERE rm.cd_adm1 IS NOT NULL
UNION
SELECT cd_municipality,(ref),string,NULL orig,name_type,cd_lang,locale , (2,a2.cd_cat_part,n2.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm2 a2 ON rm.cd_adm2=a2.cd_adm2
LEFT JOIN main.adm2_names n2 ON rm.cd_adm2=n2.cd_adm2
WHERE rm.cd_adm2 IS NOT NULL
UNION
SELECT cd_municipality,(ref),string,NULL orig,name_type,cd_lang,locale , (3,a3.cd_cat_part,n3.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm3 a3 ON rm.cd_adm3=a3.cd_adm3
LEFT JOIN main.adm3_names n3 ON rm.cd_adm3=n3.cd_adm3
WHERE rm.cd_adm3 IS NOT NULL
UNION
SELECT cd_municipality,(ref),string,NULL orig,name_type,cd_lang,locale , (4,a4.cd_cat_part,n4.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm4 a4 ON rm.cd_adm4=a4.cd_adm4
LEFT JOIN main.adm4_names n4 ON rm.cd_adm4=n4.cd_adm4
WHERE rm.cd_adm4 IS NOT NULL
UNION
SELECT cd_municipality,(ref),string,NULL orig,name_type,cd_lang,locale , (5,a5.cd_cat_part,n5.cd_name)::t_ref_name
FROM municipality m
LEFT JOIN ref_municipality rm USING(ref)
LEFT JOIN main.adm5 a5 ON rm.cd_adm5=a5.cd_adm5
LEFT JOIN main.adm5_names n5 ON rm.cd_adm5=n5.cd_adm5
WHERE rm.cd_adm5 IS NOT NULL
;

DROP TABLE IF EXISTS district_names;
CREATE TABLE district_names
(
    cd_district int REFERENCES district(cd_district),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref,
    ref_name t_ref_name,
    trust int NOT NULL DEFAULT 10,
    UNIQUE(cd_district,ref_name)
);


INSERT INTO district_names(cd_district,ref,string,orig,name_type,cd_lang,locale,ref_name)
SELECT cd_district,(ref),string,orig,name_type,cd_lang,locale, (0,a0.cd_cat_part,n0.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm0_geounit a0 ON rm.cd_geounit=a0.cd_geounit
LEFT JOIN main.adm0_names n0 ON rm.cd_geounit=n0.cd_geounit
WHERE rm.cd_geounit IS NOT NULL
UNION
SELECT cd_district,(ref),string,NULL orig,name_type,cd_lang,locale, (1,a1.cd_cat_part,n1.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm1 a1 ON rm.cd_adm1=a1.cd_adm1
LEFT JOIN main.adm1_names n1 ON rm.cd_adm1=n1.cd_adm1
WHERE rm.cd_adm1 IS NOT NULL
UNION
SELECT cd_district,(ref),string,NULL orig,name_type,cd_lang,locale , (2,a2.cd_cat_part,n2.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm2 a2 ON rm.cd_adm2=a2.cd_adm2
LEFT JOIN main.adm2_names n2 ON rm.cd_adm2=n2.cd_adm2
WHERE rm.cd_adm2 IS NOT NULL
UNION
SELECT cd_district,(ref),string,NULL orig,name_type,cd_lang,locale , (3,a3.cd_cat_part,n3.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm3 a3 ON rm.cd_adm3=a3.cd_adm3
LEFT JOIN main.adm3_names n3 ON rm.cd_adm3=n3.cd_adm3
WHERE rm.cd_adm3 IS NOT NULL
UNION
SELECT cd_district,(ref),string,NULL orig,name_type,cd_lang,locale , (4,a4.cd_cat_part,n4.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm4 a4 ON rm.cd_adm4=a4.cd_adm4
LEFT JOIN main.adm4_names n4 ON rm.cd_adm4=n4.cd_adm4
WHERE rm.cd_adm4 IS NOT NULL
UNION
SELECT cd_district,(ref),string,NULL orig,name_type,cd_lang,locale , (5,a5.cd_cat_part,n5.cd_name)::t_ref_name
FROM district m
LEFT JOIN ref_district rm USING(ref)
LEFT JOIN main.adm5 a5 ON rm.cd_adm5=a5.cd_adm5
LEFT JOIN main.adm5_names n5 ON rm.cd_adm5=n5.cd_adm5
WHERE rm.cd_adm5 IS NOT NULL
;

DROP TABLE IF EXISTS department_names;
CREATE TABLE department_names
(
    cd_department int REFERENCES department(cd_department),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref,
    ref_name t_ref_name,
    trust int NOT NULL DEFAULT 10,
    UNIQUE(cd_department,ref_name)
);


INSERT INTO department_names(cd_department,ref,string,orig,name_type,cd_lang,locale,ref_name)
SELECT cd_department,(ref),string,orig,name_type,cd_lang,locale, (0,a0.cd_cat_part,n0.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm0_geounit a0 ON rm.cd_geounit=a0.cd_geounit
LEFT JOIN main.adm0_names n0 ON rm.cd_geounit=n0.cd_geounit
WHERE rm.cd_geounit IS NOT NULL
UNION
SELECT cd_department,(ref),string,NULL orig,name_type,cd_lang,locale, (1,a1.cd_cat_part,n1.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm1 a1 ON rm.cd_adm1=a1.cd_adm1
LEFT JOIN main.adm1_names n1 ON rm.cd_adm1=n1.cd_adm1
WHERE rm.cd_adm1 IS NOT NULL
UNION
SELECT cd_department,(ref),string,NULL orig,name_type,cd_lang,locale , (2,a2.cd_cat_part,n2.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm2 a2 ON rm.cd_adm2=a2.cd_adm2
LEFT JOIN main.adm2_names n2 ON rm.cd_adm2=n2.cd_adm2
WHERE rm.cd_adm2 IS NOT NULL
UNION
SELECT cd_department,(ref),string,NULL orig,name_type,cd_lang,locale , (3,a3.cd_cat_part,n3.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm3 a3 ON rm.cd_adm3=a3.cd_adm3
LEFT JOIN main.adm3_names n3 ON rm.cd_adm3=n3.cd_adm3
WHERE rm.cd_adm3 IS NOT NULL
UNION
SELECT cd_department,(ref),string,NULL orig,name_type,cd_lang,locale , (4,a4.cd_cat_part,n4.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm4 a4 ON rm.cd_adm4=a4.cd_adm4
LEFT JOIN main.adm4_names n4 ON rm.cd_adm4=n4.cd_adm4
WHERE rm.cd_adm4 IS NOT NULL
UNION
SELECT cd_department,(ref),string,NULL orig,name_type,cd_lang,locale , (5,a5.cd_cat_part,n5.cd_name)::t_ref_name
FROM department m
LEFT JOIN ref_department rm USING(ref)
LEFT JOIN main.adm5 a5 ON rm.cd_adm5=a5.cd_adm5
LEFT JOIN main.adm5_names n5 ON rm.cd_adm5=n5.cd_adm5
WHERE rm.cd_adm5 IS NOT NULL
;

DROP TABLE IF EXISTS substate_names;
CREATE TABLE substate_names
(
    cd_substate int REFERENCES substate(cd_substate),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref,
    ref_name t_ref_name,
    trust int NOT NULL DEFAULT 10,
    UNIQUE(cd_substate,ref_name)
);


INSERT INTO substate_names(cd_substate,ref,string,orig,name_type,cd_lang,locale,ref_name)
SELECT cd_substate,(ref),string,orig,name_type,cd_lang,locale, (0,a0.cd_cat_part,n0.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm0_geounit a0 ON rm.cd_geounit=a0.cd_geounit
LEFT JOIN main.adm0_names n0 ON rm.cd_geounit=n0.cd_geounit
WHERE rm.cd_geounit IS NOT NULL
UNION
SELECT cd_substate,(ref),string,NULL orig,name_type,cd_lang,locale, (1,a1.cd_cat_part,n1.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm1 a1 ON rm.cd_adm1=a1.cd_adm1
LEFT JOIN main.adm1_names n1 ON rm.cd_adm1=n1.cd_adm1
WHERE rm.cd_adm1 IS NOT NULL
UNION
SELECT cd_substate,(ref),string,NULL orig,name_type,cd_lang,locale , (2,a2.cd_cat_part,n2.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm2 a2 ON rm.cd_adm2=a2.cd_adm2
LEFT JOIN main.adm2_names n2 ON rm.cd_adm2=n2.cd_adm2
WHERE rm.cd_adm2 IS NOT NULL
UNION
SELECT cd_substate,(ref),string,NULL orig,name_type,cd_lang,locale , (3,a3.cd_cat_part,n3.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm3 a3 ON rm.cd_adm3=a3.cd_adm3
LEFT JOIN main.adm3_names n3 ON rm.cd_adm3=n3.cd_adm3
WHERE rm.cd_adm3 IS NOT NULL
UNION
SELECT cd_substate,(ref),string,NULL orig,name_type,cd_lang,locale , (4,a4.cd_cat_part,n4.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm4 a4 ON rm.cd_adm4=a4.cd_adm4
LEFT JOIN main.adm4_names n4 ON rm.cd_adm4=n4.cd_adm4
WHERE rm.cd_adm4 IS NOT NULL
UNION
SELECT cd_substate,(ref),string,NULL orig,name_type,cd_lang,locale , (5,a5.cd_cat_part,n5.cd_name)::t_ref_name
FROM substate m
LEFT JOIN ref_substate rm USING(ref)
LEFT JOIN main.adm5 a5 ON rm.cd_adm5=a5.cd_adm5
LEFT JOIN main.adm5_names n5 ON rm.cd_adm5=n5.cd_adm5
WHERE rm.cd_adm5 IS NOT NULL
;

DROP TABLE IF EXISTS state_names;
CREATE TABLE state_names
(
    cd_state int REFERENCES state(cd_state),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref,
    ref_name t_ref_name,
    trust int NOT NULL DEFAULT 10,
    UNIQUE(cd_state,ref_name)
);


INSERT INTO state_names(cd_state,ref,string,orig,name_type,cd_lang,locale,ref_name)
SELECT cd_state,(ref),string,orig,name_type,cd_lang,locale, (0,a0.cd_cat_part,n0.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm0_geounit a0 ON rm.cd_geounit=a0.cd_geounit
LEFT JOIN main.adm0_names n0 ON rm.cd_geounit=n0.cd_geounit
WHERE rm.cd_geounit IS NOT NULL
UNION
SELECT cd_state,(ref),string,NULL orig,name_type,cd_lang,locale, (1,a1.cd_cat_part,n1.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm1 a1 ON rm.cd_adm1=a1.cd_adm1
LEFT JOIN main.adm1_names n1 ON rm.cd_adm1=n1.cd_adm1
WHERE rm.cd_adm1 IS NOT NULL
UNION
SELECT cd_state,(ref),string,NULL orig,name_type,cd_lang,locale , (2,a2.cd_cat_part,n2.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm2 a2 ON rm.cd_adm2=a2.cd_adm2
LEFT JOIN main.adm2_names n2 ON rm.cd_adm2=n2.cd_adm2
WHERE rm.cd_adm2 IS NOT NULL
UNION
SELECT cd_state,(ref),string,NULL orig,name_type,cd_lang,locale , (3,a3.cd_cat_part,n3.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm3 a3 ON rm.cd_adm3=a3.cd_adm3
LEFT JOIN main.adm3_names n3 ON rm.cd_adm3=n3.cd_adm3
WHERE rm.cd_adm3 IS NOT NULL
UNION
SELECT cd_state,(ref),string,NULL orig,name_type,cd_lang,locale , (4,a4.cd_cat_part,n4.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm4 a4 ON rm.cd_adm4=a4.cd_adm4
LEFT JOIN main.adm4_names n4 ON rm.cd_adm4=n4.cd_adm4
WHERE rm.cd_adm4 IS NOT NULL
UNION
SELECT cd_state,(ref),string,NULL orig,name_type,cd_lang,locale , (5,a5.cd_cat_part,n5.cd_name)::t_ref_name
FROM state m
LEFT JOIN ref_state rm USING(ref)
LEFT JOIN main.adm5 a5 ON rm.cd_adm5=a5.cd_adm5
LEFT JOIN main.adm5_names n5 ON rm.cd_adm5=n5.cd_adm5
WHERE rm.cd_adm5 IS NOT NULL
;

DROP TABLE IF EXISTS sovereign_names;
CREATE TABLE sovereign_names
(
    cd_sov char(3) REFERENCES sovereign(cd_sov),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    ref t_ref ,
    trust int NOT NULL DEFAULT 10
);

INSERT INTO sovereign_names(cd_sov,string,orig,name_type,cd_lang,locale,ref)
SELECT cd_sov,string,orig,name_type,cd_lang,locale,(-1,0,cd_sov)::t_ref
FROM sovereign c
LEFT JOIN main.country_names cn ON c.cd_sov=cn.cd_country
WHERE string IS NOT NULL
UNION
SELECT cd_sov,string,orig,name_type,cd_lang,locale,(-1,0,cd_sov)::t_ref
FROM sovereign c
LEFT JOIN main.adm0_names cn ON c.cd_sov=cn.cd_geounit
WHERE string IS NOT NULL;

DROP TABLE IF EXISTS continent CASCADE;
CREATE TABLE continent
(
 cd_continent int PRIMARY KEY,
 continent text UNIQUE
);

DROP TABLE IF EXISTS continent_names CASCADE;
CREATE TABLE continent_names
(
    cd_continent int REFERENCES continent(cd_continent),
    continent text REFERENCES continent(continent),
    string text,
    ascii_simp text,
    orig text,
    name_type text,
    cd_lang character(2),
    trust int NOT NULL DEFAULT 10
);
INSERT INTO continent
SELECT cd_continent,continent FROM main.continent;

INSERT INTO continent_names(cd_continent,continent,string,cd_lang)
SELECT cd_continent,continent,continent,'en' FROM continent;


DROP TABLE IF EXISTS wb_region CASCADE;
CREATE TABLE wb_region
(
 cd_wb_region int PRIMARY KEY,
 wb_region text UNIQUE
);

DROP TABLE IF EXISTS wb_region_names CASCADE;
CREATE TABLE wb_region_names
(
    cd_wb_region int REFERENCES wb_region(cd_wb_region),
    wb_region text REFERENCES wb_region(wb_region),
    string text,
    ascii_simp text,
    orig text,
    name_type text,
    cd_lang character(2),
    trust int NOT NULL DEFAULT 10
);
INSERT INTO wb_region
SELECT cd_wb_region,wb_region FROM main.wb_region;

INSERT INTO wb_region_names(cd_wb_region,wb_region,string,cd_lang)
SELECT cd_wb_region,wb_region,wb_region,'en' FROM wb_region;

DROP TABLE IF EXISTS region CASCADE;
CREATE TABLE region
(
 cd_region serial PRIMARY KEY,
 region text UNIQUE
);
DROP TABLE IF EXISTS region_names CASCADE;
CREATE TABLE region_names
(
    cd_region int REFERENCES region(cd_region),
    region text REFERENCES region(region),
    string text,
    ascii_simp text,
    orig text,
    name_type text,
    cd_lang character(2),
    trust int NOT NULL DEFAULT 10
);
INSERT INTO region(region)
SELECT DISTINCT region FROM main.subregion;

INSERT INTO region_names(cd_region,region,string,cd_lang)
SELECT DISTINCT cd_region,region,region,'en' FROM region;



DROP TABLE IF EXISTS subregion CASCADE;
CREATE TABLE subregion
(
 cd_subregion int PRIMARY KEY,
 subregion text UNIQUE,
 cd_region int REFERENCES region(cd_region)
);

DROP TABLE IF EXISTS subregion_names CASCADE;
CREATE TABLE subregion_names
(
    cd_subregion int REFERENCES subregion(cd_subregion),
    subregion text REFERENCES subregion(subregion),
    string text,
    ascii_simp text,
    orig text,
    name_type text,
    cd_lang character(2),
    trust int NOT NULL DEFAULT 10
);
INSERT INTO subregion
SELECT cd_subregion,subregion,cd_region
FROM main.subregion
LEFT JOIN region USING (region);

INSERT INTO subregion_names(cd_subregion,subregion,string,cd_lang)
SELECT cd_subregion,subregion,subregion,'en' FROM subregion;

----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------- INDEXES --------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------


--geometries
 DROP INDEX IF EXISTS public_geounit_the_geom_idx CASCADE;
 DROP INDEX IF EXISTS public_sovereign_the_geom_idx  CASCADE;
 DROP INDEX IF EXISTS public_state_the_geom_idx CASCADE;
 DROP INDEX IF EXISTS public_substate_the_geom_idx  CASCADE;
 DROP INDEX IF EXISTS public_department_the_geom_idx  CASCADE;
 DROP INDEX IF EXISTS public_district_the_geom_idx  CASCADE;
 DROP INDEX IF EXISTS public_municipality_the_geom_idx  CASCADE;

 CREATE INDEX public_geounit_the_geom_idx ON geounit USING GIST(the_geom);
 CREATE INDEX public_sovereign_the_geom_idx ON sovereign USING GIST(the_geom);
 CREATE INDEX public_state_the_geom_idx ON state USING GIST(the_geom);
 CREATE INDEX public_substate_the_geom_idx ON substate USING GIST(the_geom);
 CREATE INDEX public_department_the_geom_idx ON department USING GIST(the_geom);
 CREATE INDEX public_district_the_geom_idx ON district USING GIST(the_geom);
 CREATE INDEX public_municipality_the_geom_idx ON municipality USING GIST(the_geom);

--relations between tables
ALTER TABLE geounit DROP CONSTRAINT IF EXISTS geounit_sovereign_fkey;
ALTER TABLE geounit DROP CONSTRAINT IF EXISTS geounit_continent_fkey;
ALTER TABLE geounit DROP CONSTRAINT IF EXISTS geounit_region_fkey;
ALTER TABLE geounit DROP CONSTRAINT IF EXISTS geounit_subregion_fkey;
ALTER TABLE geounit DROP CONSTRAINT IF EXISTS geounit_wb_region_fkey;

ALTER TABLE geounit ADD CONSTRAINT geounit_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE geounit ADD CONSTRAINT geounit_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE geounit ADD CONSTRAINT geounit_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE geounit ADD CONSTRAINT geounit_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE geounit ADD CONSTRAINT geounit_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS geounit_sovereign_fk_idx ;
DROP INDEX IF EXISTS geounit_continent_fk_idx ;
DROP INDEX IF EXISTS geounit_region_fk_idx ;
DROP INDEX IF EXISTS geounit_subregion_fk_idx ;
DROP INDEX IF EXISTS geounit_wb_region_fk_idx ;

CREATE INDEX geounit_sovereign_fk_idx ON geounit(cd_sov);
CREATE INDEX geounit_continent_fk_idx ON geounit(continent);
CREATE INDEX geounit_region_fk_idx ON geounit(region);
CREATE INDEX geounit_subregion_fk_idx ON geounit(subregion);
CREATE INDEX geounit_wb_region_fk_idx ON geounit(wb_region);


ALTER TABLE state DROP CONSTRAINT IF EXISTS state_sovereign_fkey;
ALTER TABLE state DROP CONSTRAINT IF EXISTS state_geounit_fkey;
ALTER TABLE state DROP CONSTRAINT IF EXISTS state_continent_fkey;
ALTER TABLE state DROP CONSTRAINT IF EXISTS state_region_fkey;
ALTER TABLE state DROP CONSTRAINT IF EXISTS state_subregion_fkey;
ALTER TABLE state DROP CONSTRAINT IF EXISTS state_wb_region_fkey;

ALTER TABLE state ADD CONSTRAINT state_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE state ADD CONSTRAINT state_geounit_fkey FOREIGN KEY (cd_geounit) REFERENCES geounit(cd_geounit);
ALTER TABLE state ADD CONSTRAINT state_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE state ADD CONSTRAINT state_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE state ADD CONSTRAINT state_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE state ADD CONSTRAINT state_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS state_sovereign_fk_idx ;
DROP INDEX IF EXISTS state_geounit_fk_idx ;
DROP INDEX IF EXISTS state_continent_fk_idx ;
DROP INDEX IF EXISTS state_region_fk_idx ;
DROP INDEX IF EXISTS state_subregion_fk_idx ;
DROP INDEX IF EXISTS state_wb_region_fk_idx ;

CREATE INDEX state_sovereign_fk_idx ON sovereign(cd_sov);
CREATE INDEX state_geounit_fk_idx ON geounit(cd_geounit);
CREATE INDEX state_continent_fk_idx ON continent(continent);
CREATE INDEX state_region_fk_idx ON region(region);
CREATE INDEX state_subregion_fk_idx ON subregion(subregion);
CREATE INDEX state_wb_region_fk_idx ON wb_region(wb_region);


ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_sovereign_fkey;
ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_geounit_fkey;
ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_continent_fkey;
ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_region_fkey;
ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_subregion_fkey;
ALTER TABLE substate DROP CONSTRAINT IF EXISTS substate_wb_region_fkey;

ALTER TABLE substate ADD CONSTRAINT substate_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE substate ADD CONSTRAINT substate_geounit_fkey FOREIGN KEY (cd_geounit) REFERENCES geounit(cd_geounit);
ALTER TABLE substate ADD CONSTRAINT substate_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE substate ADD CONSTRAINT substate_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE substate ADD CONSTRAINT substate_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE substate ADD CONSTRAINT substate_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS substate_sovereign_fk_idx ;
DROP INDEX IF EXISTS substate_geounit_fk_idx ;
DROP INDEX IF EXISTS substate_continent_fk_idx ;
DROP INDEX IF EXISTS substate_region_fk_idx ;
DROP INDEX IF EXISTS substate_subregion_fk_idx ;
DROP INDEX IF EXISTS substate_wb_region_fk_idx ;

CREATE INDEX substate_sovereign_fk_idx ON sovereign(cd_sov);
CREATE INDEX substate_geounit_fk_idx ON geounit(cd_geounit);
CREATE INDEX substate_continent_fk_idx ON continent(continent);
CREATE INDEX substate_region_fk_idx ON region(region);
CREATE INDEX substate_subregion_fk_idx ON subregion(subregion);
CREATE INDEX substate_wb_region_fk_idx ON wb_region(wb_region);


ALTER TABLE department DROP CONSTRAINT IF EXISTS department_sovereign_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_geounit_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_continent_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_region_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_subregion_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_wb_region_fkey;

ALTER TABLE department ADD CONSTRAINT department_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE department ADD CONSTRAINT department_geounit_fkey FOREIGN KEY (cd_geounit) REFERENCES geounit(cd_geounit);
ALTER TABLE department ADD CONSTRAINT department_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE department ADD CONSTRAINT department_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE department ADD CONSTRAINT department_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE department ADD CONSTRAINT department_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS department_sovereign_fk_idx ;
DROP INDEX IF EXISTS department_geounit_fk_idx ;
DROP INDEX IF EXISTS department_continent_fk_idx ;
DROP INDEX IF EXISTS department_region_fk_idx ;
DROP INDEX IF EXISTS department_subregion_fk_idx ;
DROP INDEX IF EXISTS department_wb_region_fk_idx ;

CREATE INDEX department_sovereign_fk_idx ON sovereign(cd_sov);
CREATE INDEX department_geounit_fk_idx ON geounit(cd_geounit);
CREATE INDEX department_continent_fk_idx ON continent(continent);
CREATE INDEX department_region_fk_idx ON region(region);
CREATE INDEX department_subregion_fk_idx ON subregion(subregion);
CREATE INDEX department_wb_region_fk_idx ON wb_region(wb_region);


ALTER TABLE district DROP CONSTRAINT IF EXISTS district_sovereign_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_geounit_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_continent_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_region_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_subregion_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_wb_region_fkey;

ALTER TABLE department ADD CONSTRAINT department_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE department ADD CONSTRAINT department_geounit_fkey FOREIGN KEY (cd_geounit) REFERENCES geounit(cd_geounit);
ALTER TABLE department ADD CONSTRAINT department_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE department ADD CONSTRAINT department_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE department ADD CONSTRAINT department_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE department ADD CONSTRAINT department_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS department_sovereign_fk_idx ;
DROP INDEX IF EXISTS department_geounit_fk_idx ;
DROP INDEX IF EXISTS department_continent_fk_idx ;
DROP INDEX IF EXISTS department_region_fk_idx ;
DROP INDEX IF EXISTS department_subregion_fk_idx ;
DROP INDEX IF EXISTS department_wb_region_fk_idx ;

CREATE INDEX department_sovereign_fk_idx ON sovereign(cd_sov);
CREATE INDEX department_geounit_fk_idx ON geounit(cd_geounit);
CREATE INDEX department_continent_fk_idx ON continent(continent);
CREATE INDEX department_region_fk_idx ON region(region);
CREATE INDEX department_subregion_fk_idx ON subregion(subregion);
CREATE INDEX department_wb_region_fk_idx ON wb_region(wb_region);


ALTER TABLE municipality DROP CONSTRAINT IF EXISTS municipality_sovereign_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_geounit_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_continent_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_region_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_subregion_fkey;
ALTER TABLE department DROP CONSTRAINT IF EXISTS department_wb_region_fkey;

ALTER TABLE department ADD CONSTRAINT department_sovereign_fkey FOREIGN KEY (cd_sov) REFERENCES sovereign(cd_sov);
ALTER TABLE department ADD CONSTRAINT department_geounit_fkey FOREIGN KEY (cd_geounit) REFERENCES geounit(cd_geounit);
ALTER TABLE department ADD CONSTRAINT department_continent_fkey FOREIGN KEY (continent) REFERENCES continent(continent);
ALTER TABLE department ADD CONSTRAINT department_region_fkey FOREIGN KEY (region) REFERENCES region(region);
ALTER TABLE department ADD CONSTRAINT department_subregion_fkey FOREIGN KEY (subregion) REFERENCES subregion(subregion);
ALTER TABLE department ADD CONSTRAINT department_wb_region_fkey FOREIGN KEY (wb_region) REFERENCES wb_region(wb_region);

DROP INDEX IF EXISTS department_sovereign_fk_idx ;
DROP INDEX IF EXISTS department_geounit_fk_idx ;
DROP INDEX IF EXISTS department_continent_fk_idx ;
DROP INDEX IF EXISTS department_region_fk_idx ;
DROP INDEX IF EXISTS department_subregion_fk_idx ;
DROP INDEX IF EXISTS department_wb_region_fk_idx ;

CREATE INDEX department_sovereign_fk_idx ON sovereign(cd_sov);
CREATE INDEX department_geounit_fk_idx ON geounit(cd_geounit);
CREATE INDEX department_continent_fk_idx ON continent(continent);
CREATE INDEX department_region_fk_idx ON region(region);
CREATE INDEX department_subregion_fk_idx ON subregion(subregion);
CREATE INDEX department_wb_region_fk_idx ON wb_region(wb_region);

