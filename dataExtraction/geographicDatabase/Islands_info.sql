
------------------------------------------------------
---------------Islands--------------------------------
------------------------------------------------------
CREATE TABLE tmp.ne_continental_parts AS(
WITH a AS(
SELECT cd_continent,continent,(ST_DUMP(the_geom)).geom
FROM main.continent
), b AS(
SELECT cd_continent,continent,rank() OVER(PARTITION BY cd_continent ORDER BY ST_area(geom) DESC),geom
FROM a
ORDER BY cd_continent,continent,ST_Area(geom) DESC
), c AS(
SELECT cd_continent,continent,geom
FROM b
WHERE "rank"=1
UNION
SELECT b.cd_continent,b.continent,b.geom
FROM b
JOIN b b2 ON b.rank<>1 AND b2.rank=1 AND (ST_Intersects(b.geom,b2.geom))
)
SELECT cd_continent,continent,ST_Union(geom) geom
FROM c
WHERE continent IS NOT NULL
GROUP BY cd_continent,continent
);

CREATE INDEX ne_continental_parts_geom_idx ON tmp.ne_continental_parts USING GIST(geom);

    -- BEGIN;
CREATE TEMPORARY TABLE continents AS(
SELECT c.cd_continent,c.continent,ST_Union(a1.the_geom) geom
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN main.continent c ON a0.cd_continent=c.cd_continent
WHERE a0.cd_continent IS NOT NULL
GROUP BY c.cd_continent,c.continent
);
CREATE TEMPORARY TABLE dump_continents AS(
WITH a AS(
SELECT cd_continent,continent,(ST_Dump(geom)).geom
FROM continents
)
SELECT cd_continent,continent,rank() OVER(PARTITION BY cd_continent ORDER BY ST_area(geom) DESC),geom
FROM a
)
;
CREATE INDEX idx_a ON dump_continents USING GIST(geom);
VACUUM ANALYSE;
CREATE TABLE tmp.gadm_continental_parts AS(
WITH a AS(
(SELECT cd_continent,continent,geom
FROM dump_continents
WHERE rank=1)
UNION
(SELECT c.cd_continent,c.continent,c.geom
FROM dump_continents c
JOIN dump_continents c2 ON c.rank<>1 AND c2.rank=1 AND ST_Intersects(c.geom,c2.geom)
)
)
SELECT cd_continent,continent,ST_UNION(geom) geom
FROM a
GROUP BY cd_continent,continent
);
CREATE INDEX gadm_continental_parts_geom_idx ON tmp.gadm_continental_parts USING GIST(geom);
--COMMIT;


-- ADM0

-- note only are considered subgeometries of at least 0.01 km2
CREATE TABLE main.country_island_info
(
    cd_country char(3) PRIMARY KEY REFERENCES main.country(cd_country),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);


INSERT INTO main.country_island_info (cd_country,all_island,main_part_is_island,part_of_island,nb_island_parts,nb_continental_parts,island_area_km2,continental_area_km2)
WITH country AS(
SELECT cd_country,country,ST_Union(the_geom) the_geom
FROM main.country
LEFT JOIN main.adm0_geounit ON sovereign=cd_country
GROUP BY cd_country,country
),a AS(
SELECT cd_country,country, (ST_Dump(the_geom)).geom
FROM country
), area AS(
SELECT cd_country,country,rank() OVER (PARTITION BY cd_country ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a
), b AS(
SELECT cd_country, "rank",area_part_km2, bool_and(acp.cd_continent IS NULL) island,area.geom
FROM area
LEFT JOIN tmp.ne_continental_parts acp ON ST_Intersects(area.geom,acp.geom)
WHERE area_part_km2>0.01
GROUP BY cd_country, "rank",area_part_km2,area.geom
ORDER BY cd_country,"rank"
), main_island AS(
SELECT cd_country,geom
FROM b
WHERE "rank"=1 AND island
), islands AS(
SELECT cd_country,geom
FROM b
WHERE island
), main_touches AS(
SELECT mi.cd_country,bool_or(i.cd_country IS NOT NULL) part_of_island
FROM main_island mi
LEFT JOIN islands i ON mi.cd_country<>i.cd_country AND ST_Intersects(mi.geom,i.geom)
GROUP BY mi.cd_country
)
SELECT cd_country,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE "rank"=1) main_part_is_island,
    part_of_island,
    count(DISTINCT "rank") FILTER (WHERE island) nb_island_parts,
    count(DISTINCT "rank") FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM b
LEFT JOIN main_touches USING (cd_country)
GROUP BY cd_country,part_of_island
;

CREATE TABLE main.adm0_geounit_island_info
(
    cd_geounit char(3) PRIMARY KEY REFERENCES main.adm0_geounit(cd_geounit),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

INSERT INTO main.adm0_geounit_island_info (cd_geounit,all_island,main_part_is_island,part_of_island,nb_island_parts,nb_continental_parts,island_area_km2,continental_area_km2)
WITH a AS(
SELECT cd_geounit, geounit, (ST_Dump(the_geom)).geom
FROM main.adm0_geounit
), area AS(
SELECT cd_geounit,geounit,rank() OVER (PARTITION BY cd_geounit ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a
), b AS(
SELECT cd_geounit, "rank",area_part_km2, bool_and(acp.cd_continent IS NULL) island,area.geom
FROM area
LEFT JOIN tmp.ne_continental_parts acp ON ST_Intersects(area.geom,acp.geom)
WHERE area_part_km2>0.01
GROUP BY cd_geounit, "rank",area_part_km2,area.geom
ORDER BY cd_geounit,"rank"
), main_island AS(
SELECT cd_geounit,geom
FROM b
WHERE "rank"=1 AND island
), islands AS(
SELECT cd_geounit,geom
FROM b
WHERE island
), main_touches AS(
SELECT mi.cd_geounit,bool_or(i.cd_geounit IS NOT NULL) part_of_island
FROM main_island mi
LEFT JOIN islands i ON mi.cd_geounit<>i.cd_geounit AND ST_Intersects(mi.geom,i.geom)
GROUP BY mi.cd_geounit
)
SELECT cd_geounit,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE "rank"=1) main_part_is_island,
    part_of_island,
    count(DISTINCT "rank") FILTER (WHERE island) nb_island_parts,
    count(DISTINCT "rank") FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM b
LEFT JOIN main_touches USING (cd_geounit)
GROUP BY cd_geounit,part_of_island
;

-- ADM1

-- note only are considered subgeometries of at least 0.01 km2

-- note to speed a bit the process we will only consider the part of more than 0.05 km2 you might want to supress that if you want a more accurate evaluation of superficies and you have a lot of time to spare...

CREATE TABLE main.adm1_island_info
(
    cd_adm1 int PRIMARY KEY REFERENCES main.adm1(cd_adm1),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

CREATE TEMPORARY TABLE adm1_to_test AS(
SELECT cd_adm1, adm1, a1.the_geom
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN tmp.gadm_continental_parts gcp ON a0.cd_continent=gcp.cd_continent AND ST_Contains(gcp.geom,a1.the_geom)
WHERE gcp.cd_continent IS NULL)
;

CREATE TEMPORARY TABLE adm1_parts_to_test AS(
WITH a AS(
SELECT cd_adm1, adm1, (ST_Dump(the_geom)).geom
FROM adm1_to_test
)
SELECT cd_adm1,adm1,rank() OVER (PARTITION BY cd_adm1 ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a);
DELETE FROM adm1_parts_to_test WHERE area_part_km2<0.05;

CREATE INDEX a1_ptt_idx ON adm1_parts_to_test USING GIST(geom);
VACUUM ANALYSE;

CREATE TEMPORARY TABLE adm1_parts_main_island AS(
SELECT cd_adm1, "rank"=1 AS main,area_part_km2, bool_and(acp.cd_continent IS NULL) island,a1ptt.geom
FROM adm1_parts_to_test a1ptt
LEFT JOIN tmp.gadm_continental_parts acp ON ST_Intersects(a1ptt.geom,acp.geom)
GROUP BY cd_adm1, "rank",area_part_km2,a1ptt.geom
ORDER BY cd_adm1,"rank"
)
;
CREATE INDEX a1_pmi_idx ON adm1_parts_main_island USING GIST(geom);
VACUUM ANALYSE;

INSERT INTO main.adm1_island_info
WITH main_touches AS(
SELECT a1.cd_adm1,bool_or(a2.cd_adm1 IS NOT NULL) part_of_island
FROM adm1_parts_main_island a1
JOIN adm1_parts_main_island a2 ON a1.main AND a1.island AND a1.cd_adm1<>a2.cd_adm1 AND ST_Intersects(a1.geom,a2.geom)
GROUP BY a1.cd_adm1
)
SELECT cd_adm1,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE main) main_part_is_island,
    bool_and(part_of_island IS NOT NULL AND part_of_island) FILTER (WHERE main) part_of_island,
    count(*) FILTER (WHERE island) nb_island_parts,
    count(*) FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM adm1_parts_main_island
LEFT JOIN main_touches USING (cd_adm1)
GROUP BY cd_adm1,part_of_island
;

INSERT INTO main.adm1_island_info
WITH a AS(
SELECT cd_adm1,(ST_Dump(the_geom)).geom
FROM main.adm1
WHERE NOT cd_adm1 IN (SELECT cd_adm1 FROM main.adm1_island_info)
)
SELECT cd_adm1,
    false,
    false,
    false,
    0,
    COUNT(geom) nb_continental_parts,
    0,
    SUM(ST_Area(geom,true)) continental_area_km2
FROM a
GROUP BY cd_adm1;



-- ADM2

-- note only are considered subgeometries of at least 0.02 km2


CREATE TABLE main.adm2_island_info
(
    cd_adm2 int PRIMARY KEY REFERENCES main.adm2(cd_adm2),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

CREATE TEMPORARY TABLE adm2_to_test AS(
WITH a AS(
SELECT cd_adm2, adm2, a0.cd_continent, a2.the_geom
FROM main.adm2 a2
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN main.adm1_island_info USING (cd_adm1)
WHERE nb_island_parts IS NOT NULL AND nb_island_parts>0
)
SELECT cd_adm2,adm2,the_geom
FROM a
LEFT JOIN tmp.gadm_continental_parts gcp ON a.cd_continent=gcp.cd_continent AND ST_Contains(gcp.geom,a.the_geom)
WHERE gcp.cd_continent IS NULL)
;

CREATE TEMPORARY TABLE adm2_parts_to_test AS(
WITH a AS(
SELECT cd_adm2, adm2, (ST_Dump(the_geom)).geom
FROM adm2_to_test
)
SELECT cd_adm2,adm2,rank() OVER (PARTITION BY cd_adm2 ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a);
DELETE FROM adm2_parts_to_test WHERE area_part_km2<0.05;

CREATE INDEX a2_ptt_idx ON adm2_parts_to_test USING GIST(geom);
VACUUM ANALYSE;

CREATE TEMPORARY TABLE adm2_parts_main_island AS(
SELECT cd_adm2, "rank"=1 AS main,area_part_km2, bool_and(acp.cd_continent IS NULL) island,a2ptt.geom
FROM adm2_parts_to_test a2ptt
LEFT JOIN tmp.gadm_continental_parts acp ON ST_Intersects(a2ptt.geom,acp.geom)
GROUP BY cd_adm2, "rank",area_part_km2,a2ptt.geom
ORDER BY cd_adm2,"rank"
)
;
CREATE INDEX a2_pmi_idx ON adm2_parts_main_island USING GIST(geom);
VACUUM ANALYSE;

INSERT INTO main.adm2_island_info
WITH main_touches AS(
SELECT a1.cd_adm2,bool_or(a1.cd_adm2 IS NOT NULL) part_of_island
FROM adm2_parts_main_island a1
JOIN adm2_parts_main_island a2 ON a1.main AND a1.island AND a1.cd_adm2<>a2.cd_adm2 AND ST_Intersects(a1.geom,a2.geom)
GROUP BY a1.cd_adm2
)
SELECT cd_adm2,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE main) main_part_is_island,
    bool_and(part_of_island IS NOT NULL AND part_of_island) FILTER (WHERE main) part_of_island,
    count(*) FILTER (WHERE island) nb_island_parts,
    count(*) FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM adm2_parts_main_island
LEFT JOIN main_touches USING (cd_adm2)
GROUP BY cd_adm2,part_of_island
;

INSERT INTO main.adm2_island_info
WITH a AS(
SELECT cd_adm2,(ST_Dump(the_geom)).geom
FROM main.adm2
WHERE NOT cd_adm2 IN (SELECT cd_adm2 FROM main.adm2_island_info)
)
SELECT cd_adm2,
    false,
    false,
    false,
    0,
    COUNT(geom) nb_continental_parts,
    0,
    SUM(ST_Area(geom,true)) continental_area_km2
FROM a
GROUP BY cd_adm2;



-- ADM3

-- note only are considered subgeometries of at least 0.05 km2


CREATE TABLE main.adm3_island_info
(
    cd_adm3 int PRIMARY KEY REFERENCES main.adm3(cd_adm3),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

CREATE TEMPORARY TABLE adm3_to_test AS(
WITH a AS(
SELECT cd_adm3, adm3, a0.cd_continent, a3.the_geom
FROM main.adm3 a3
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN main.adm2 a2 USING (cd_adm2)
LEFT JOIN main.adm2_island_info USING (cd_adm2)
WHERE nb_island_parts IS NOT NULL AND nb_island_parts>0
)
SELECT cd_adm3,adm3,the_geom
FROM a
LEFT JOIN tmp.gadm_continental_parts gcp ON a.cd_continent=gcp.cd_continent AND ST_Contains(gcp.geom,a.the_geom)
WHERE gcp.cd_continent IS NULL)
;

CREATE TEMPORARY TABLE adm3_parts_to_test AS(
WITH a AS(
SELECT cd_adm3, adm3, (ST_Dump(the_geom)).geom
FROM adm3_to_test
)
SELECT cd_adm3,adm3,rank() OVER (PARTITION BY cd_adm3 ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a);
DELETE FROM adm3_parts_to_test WHERE area_part_km2<0.05;

CREATE INDEX a3_ptt_idx ON adm3_parts_to_test USING GIST(geom);
VACUUM ANALYSE;

CREATE TEMPORARY TABLE adm3_parts_main_island AS(
SELECT cd_adm3, "rank"=1 AS main,area_part_km2, bool_and(acp.cd_continent IS NULL) island,a3ptt.geom
FROM adm3_parts_to_test a3ptt
LEFT JOIN tmp.gadm_continental_parts acp ON ST_Intersects(a3ptt.geom,acp.geom)
GROUP BY cd_adm3, "rank",area_part_km2,a3ptt.geom
ORDER BY cd_adm3,"rank"
)
;
CREATE INDEX a3_pmi_idx ON adm3_parts_main_island USING GIST(geom);
VACUUM ANALYSE;

INSERT INTO main.adm3_island_info
WITH main_touches AS(
SELECT a1.cd_adm3,bool_or(a1.cd_adm3 IS NOT NULL) part_of_island
FROM adm3_parts_main_island a1
JOIN adm3_parts_main_island a2 ON a1.main AND a1.island AND a1.cd_adm3<>a2.cd_adm3 AND ST_Intersects(a1.geom,a2.geom)
GROUP BY a1.cd_adm3
)
SELECT cd_adm3,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE main) main_part_is_island,
    bool_and(part_of_island IS NOT NULL AND part_of_island) FILTER (WHERE main) part_of_island,
    count(*) FILTER (WHERE island) nb_island_parts,
    count(*) FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM adm3_parts_main_island
LEFT JOIN main_touches USING (cd_adm3)
GROUP BY cd_adm3,part_of_island
;

INSERT INTO main.adm3_island_info
WITH a AS(
SELECT cd_adm3,(ST_Dump(the_geom)).geom
FROM main.adm3
WHERE NOT cd_adm3 IN (SELECT cd_adm3 FROM main.adm3_island_info)
)
SELECT cd_adm3,
    false,
    false,
    false,
    0,
    COUNT(geom) nb_continental_parts,
    0,
    SUM(ST_Area(geom,true)) continental_area_km2
FROM a
GROUP BY cd_adm3;



-- ADM4

-- note only are considered subgeometries of at least 0.05 km2


CREATE TABLE main.adm4_island_info
(
    cd_adm4 int PRIMARY KEY REFERENCES main.adm4(cd_adm4),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

CREATE TEMPORARY TABLE adm4_to_test AS(
WITH a AS(
SELECT cd_adm4, adm4, a0.cd_continent, a4.the_geom
FROM main.adm4 a4
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN main.adm3 a3 USING (cd_adm3)
LEFT JOIN main.adm3_island_info USING (cd_adm3)
WHERE nb_island_parts IS NOT NULL AND nb_island_parts>0
)
SELECT cd_adm4,adm4,the_geom
FROM a
LEFT JOIN tmp.gadm_continental_parts gcp ON a.cd_continent=gcp.cd_continent AND ST_Contains(gcp.geom,a.the_geom)
WHERE gcp.cd_continent IS NULL)
;

CREATE TEMPORARY TABLE adm4_parts_to_test AS(
WITH a AS(
SELECT cd_adm4, adm4, (ST_Dump(the_geom)).geom
FROM adm4_to_test
)
SELECT cd_adm4,adm4,rank() OVER (PARTITION BY cd_adm4 ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a);
DELETE FROM adm4_parts_to_test WHERE area_part_km2<0.05;

CREATE INDEX a4_ptt_idx ON adm4_parts_to_test USING GIST(geom);
VACUUM ANALYSE;

CREATE TEMPORARY TABLE adm4_parts_main_island AS(
SELECT cd_adm4, "rank"=1 AS main,area_part_km2, bool_and(acp.cd_continent IS NULL) island,a4ptt.geom
FROM adm4_parts_to_test a4ptt
LEFT JOIN tmp.gadm_continental_parts acp ON ST_Intersects(a4ptt.geom,acp.geom)
GROUP BY cd_adm4, "rank",area_part_km2,a4ptt.geom
ORDER BY cd_adm4,"rank"
)
;
CREATE INDEX a4_pmi_idx ON adm4_parts_main_island USING GIST(geom);
VACUUM ANALYSE;

INSERT INTO main.adm4_island_info
WITH main_touches AS(
SELECT a1.cd_adm4,bool_or(a1.cd_adm4 IS NOT NULL) part_of_island
FROM adm4_parts_main_island a1
JOIN adm4_parts_main_island a2 ON a1.main AND a1.island AND a1.cd_adm4<>a2.cd_adm4 AND ST_Intersects(a1.geom,a2.geom)
GROUP BY a1.cd_adm4
)
SELECT cd_adm4,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE main) main_part_is_island,
    bool_and(part_of_island IS NOT NULL AND part_of_island) FILTER (WHERE main) part_of_island,
    count(*) FILTER (WHERE island) nb_island_parts,
    count(*) FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM adm4_parts_main_island
LEFT JOIN main_touches USING (cd_adm4)
GROUP BY cd_adm4,part_of_island
;

INSERT INTO main.adm4_island_info
WITH a AS(
SELECT cd_adm4,(ST_Dump(the_geom)).geom
FROM main.adm4
WHERE NOT cd_adm4 IN (SELECT cd_adm4 FROM main.adm4_island_info)
)
SELECT cd_adm4,
    false,
    false,
    false,
    0,
    COUNT(geom) nb_continental_parts,
    0,
    SUM(ST_Area(geom,true)) continental_area_km2
FROM a
GROUP BY cd_adm4;



-- ADM5

-- note only are considered subgeometries of at least 0.05 km2


CREATE TABLE main.adm5_island_info
(
    cd_adm5 int PRIMARY KEY REFERENCES main.adm5(cd_adm5),
    all_island boolean, -- all subgeometries are islands
    main_part_is_island boolean, -- largest subgeometry in island
    part_of_island boolean, -- largest subgeometry in island but touches or intersects another
    nb_island_parts int, -- number of subgeometries which are in islands
    nb_continental_parts int, -- number of subgeometries in the continental part
    island_area_km2 double precision DEFAULT 0.0, -- total area of island parts
    continental_area_km2 double precision DEFAULT 0.0-- total area of continental part,
);

CREATE TEMPORARY TABLE adm5_to_test AS(
WITH a AS(
SELECT cd_adm5, adm5, a0.cd_continent, a5.the_geom
FROM main.adm5 a5
LEFT JOIN main.adm0_geounit a0 USING(cd_geounit)
LEFT JOIN main.adm4 a4 USING (cd_adm4)
LEFT JOIN main.adm4_island_info USING (cd_adm4)
WHERE nb_island_parts IS NOT NULL AND nb_island_parts>0
)
SELECT cd_adm5,adm5,the_geom
FROM a
LEFT JOIN tmp.gadm_continental_parts gcp ON a.cd_continent=gcp.cd_continent AND ST_Contains(gcp.geom,a.the_geom)
WHERE gcp.cd_continent IS NULL)
;

CREATE TEMPORARY TABLE adm5_parts_to_test AS(
WITH a AS(
SELECT cd_adm5, adm5, (ST_Dump(the_geom)).geom
FROM adm5_to_test
)
SELECT cd_adm5,adm5,rank() OVER (PARTITION BY cd_adm5 ORDER BY ST_Area(geom,true) DESC), ST_Area(geom,true)/(1000 * 1000) area_part_km2,geom
FROM a);
DELETE FROM adm5_parts_to_test WHERE area_part_km2<0.05;

CREATE INDEX a5_ptt_idx ON adm5_parts_to_test USING GIST(geom);
VACUUM ANALYSE;

CREATE TEMPORARY TABLE adm5_parts_main_island AS(
SELECT cd_adm5, "rank"=1 AS main,area_part_km2, bool_and(acp.cd_continent IS NULL) island,a5ptt.geom
FROM adm5_parts_to_test a5ptt
LEFT JOIN tmp.gadm_continental_parts acp ON ST_Intersects(a5ptt.geom,acp.geom)
GROUP BY cd_adm5, "rank",area_part_km2,a5ptt.geom
ORDER BY cd_adm5,"rank"
)
;
CREATE INDEX a5_pmi_idx ON adm5_parts_main_island USING GIST(geom);
VACUUM ANALYSE;

INSERT INTO main.adm5_island_info
WITH main_touches AS(
SELECT a1.cd_adm5,bool_or(a1.cd_adm5 IS NOT NULL) part_of_island
FROM adm5_parts_main_island a1
JOIN adm5_parts_main_island a2 ON a1.main AND a1.island AND a1.cd_adm5<>a2.cd_adm5 AND ST_Intersects(a1.geom,a2.geom)
GROUP BY a1.cd_adm5
)
SELECT cd_adm5,
    bool_and(island) all_island,
    bool_and(island) FILTER (WHERE main) main_part_is_island,
    bool_and(part_of_island IS NOT NULL AND part_of_island) FILTER (WHERE main) part_of_island,
    count(*) FILTER (WHERE island) nb_island_parts,
    count(*) FILTER (WHERE NOT island) nb_continental_parts,
    sum(area_part_km2) FILTER (WHERE island) island_area_km2,
    sum(area_part_km2) FILTER (WHERE NOT island) continental_area_km2
FROM adm5_parts_main_island
LEFT JOIN main_touches USING (cd_adm5)
GROUP BY cd_adm5,part_of_island
;

INSERT INTO main.adm5_island_info
WITH a AS(
SELECT cd_adm5,(ST_Dump(the_geom)).geom
FROM main.adm5
WHERE NOT cd_adm5 IN (SELECT cd_adm5 FROM main.adm5_island_info)
)
SELECT cd_adm5,
    false,
    false,
    false,
    0,
    COUNT(geom) nb_continental_parts,
    0,
    SUM(ST_Area(geom,true)) continental_area_km2
FROM a
GROUP BY cd_adm5;


















