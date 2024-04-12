--------------------------------------------------------------------
------------- Categories ------------------------------------------
--------------------------------------------------------------------
DROP TABLE IF EXISTS main.categ_part;
CREATE TABLE main.categ_part
(
    cd_cat_part int PRIMARY KEY,
    cat_part text,
    note_cat text
);

INSERT INTO main.categ_part
VALUES
(0, 'Country',''),
(1,'States, provinces or similar in federal states, independent territories','In Federal states, federal territories are also put there'),
(2,'Administrative regions bigger than departments, territories with special status',''),
(3,'Department',''),
(4,'Counties, cantons, districts or sub-departments','Districts when those are lower than department'),
(5,'Municipalities',''),
(6,'Sub-municipilaties',''),
(99,'Landscape element','e.g. mountain, sea, lake');

--ALTER TABLE main.country ADD COLUMN federal boolean NOT NULL DEFAULT false;
UPDATE main.country
SET federal=true
WHERE cd_country IN ('MYS', 'ARG', 'ETH', 'BRA', 'RUS', 'DEU', 'ARE', 'BEL', 'BIH', 'NPL', 'USA', 'CAN', 'IND', 'GBR', 'NGA', 'VEN', 'AUS', 'PAK', 'MEX','AUT','FSM','SDN','SSD', 'IRQ','PNG');



-- types of geounit
UPDATE main.adm0_geounit g
SET main_territ=true
FROM main.country c
WHERE g.sovereign=c.cd_country AND (c.name=g.geounit OR c.cd_country=g.cd_geounit);

UPDATE main.adm0_geounit g
SET main_territ=false
FROM (SELECT sovereign FROM main.adm0_geounit WHERE main_territ) a
WHERE g.sovereign=a.sovereign AND g.main_territ IS NULL;

WITH a AS(
SELECT sovereign, SUM(ST_Area(the_geom,true)) area_country
FROM main.adm0_geounit
WHERE sovereign IS NOT NULL AND main_territ IS NULL
GROUP BY sovereign
), b AS(
SELECT sovereign,cd_geounit,ST_area(g.the_geom,true)/area_country prop_country
FROM a
LEFT JOIN main.adm0_geounit g USING (sovereign)
WHERE ST_area(g.the_geom,true)/area_country>0.9
)
UPDATE main.adm0_geounit g
SET main_territ=true
FROM b
WHERE g.cd_geounit=b.cd_geounit;

UPDATE main.adm0_geounit g
SET main_territ=false
FROM (SELECT sovereign FROM main.adm0_geounit WHERE main_territ) a
WHERE g.sovereign=a.sovereign AND g.main_territ IS NULL;

WITH a AS(
SELECT name, sovereign, SUM(ST_Area(the_geom,true)) area_country
FROM main.adm0_geounit
LEFT JOIN main.country ON sovereign=cd_country
WHERE sovereign IS NOT NULL AND main_territ IS NULL
GROUP BY name,sovereign
), b AS(
SELECT name,sovereign,cd_geounit,geounit,ST_area(g.the_geom,true)/area_country prop_country
FROM a
LEFT JOIN main.adm0_geounit g USING (sovereign)
--WHERE ST_area(g.the_geom,true)/area_country
)
UPDATE main.adm0_geounit g
SET part_multi=true
FROM b
WHERE g.cd_geounit=b.cd_geounit AND prop_country>0.05 AND part_multi IS NULL
;

UPDATE main.adm0_geounit g
SET part_multi=true
WHERE (sovereign='TTO' AND cd_geounit IN ('TTD','TTG')) OR geounit='Brussels';

UPDATE main.adm0_geounit g
SET part_multi=false
WHERE part_multi IS NULL;

UPDATE main.adm0_geounit g
SET dependency=TRUE
FROM ne.ne_10m_admin_0_map_subunits s
WHERE s.cd_geounit=g.cd_geounit AND "type"='Dependency';

------------------------------------------------------
---------ADM1 types-----------------------------------
------------------------------------------------------

--ALTER TABLE main.adm1 ADD COLUMN cd_cat_part int REFERENCES main.categ_part(cd_cat_part);
--ALTER TABLE main.adm1 DROP COLUMN cd_cat_part ;
--UPDATE main.adm1 SET cd_cat_part=NULL;

UPDATE main.adm1 a1
SET cd_cat_part=1
FROM main.adm0_geounit a0,main.country c
WHERE a1.cd_cat_part IS NULL AND a1.cd_geounit=a0.cd_geounit AND a0.sovereign=c.cd_country
    AND(
    (federal AND type_part='State')
    OR (sovereign='ARG' AND type_part IN ('Province','Federal District'))
    OR (sovereign='AUS' AND type_part IN ('State','Territory'))
    OR (sovereign='BEL' AND type_part='Region')
    OR (sovereign='BRA' AND type_part IN ('State','Federal District'))
    OR (sovereign='CAN' AND type_part IN ('Province','Territory'))
    OR (sovereign='ETH' AND (type_part='State' OR type_part_verbatim='Astedader'))
    OR (sovereign='DEU' AND type_part~'State')
    OR (sovereign='IND' AND type_part IN ('State','Union Territory','Autonomous Region'))
    OR (sovereign='MYS' AND type_part IN ('State','Federal Territory'))
    OR (sovereign='NPL' AND type_part = 'Development Region')
    OR (sovereign='NGA' AND type_part = 'State')
    OR (sovereign='PAK' AND type_part IN ('Province','Centrally Administered Area','Capital Territory','Territory'))
    OR (sovereign='RUS' AND (type_part ~ 'Autonomous' OR type_part ~ 'Republic' OR type_part_verbatim='Kray' OR type_part IN ('Region') OR type_part_verbatim IN ('Gorod','Gorsovet')))
    OR (sovereign='ARE' AND (type_part = 'Emirate'))
    OR (sovereign='GBR' AND (type_part = 'Constituent Country'))
    OR (sovereign='USA' AND type_part IN ('State','Federal District'))
    OR (sovereign='VEN' AND type_part='State')
    OR (sovereign='MEX' AND type_part IN ('State','Federal District'))
    OR (sovereign='BIH' AND (type_part='Entity' OR adm1='Brčko'))
    OR (sovereign='CHN' AND (type_part='Special Administrative Region'))
    OR (sovereign='CHN' AND (type_part='Autonomous Region'))
    OR (sovereign='PNG' AND (type_part IN ('National Capital District','Autonomous Region')))
    OR (sovereign='MDA' AND adm1='Transnistria')
    OR (sovereign='PAN' AND type_part='Indigenous Territory')
    OR (sovereign='UZB' AND type_part='Autononous Region')
    OR (federal AND type_part IN ('Governorate','Province'))
    )
;



UPDATE main.adm1 a1
SET cd_cat_part=2
FROM main.adm0_geounit a0, main.country c,main.adm1_island_info ii1,main.adm0_geounit_island_info ii0,main.country_island_info cii
WHERE a1.cd_cat_part IS NULL
    AND a1.cd_geounit=a0.cd_geounit AND a0.sovereign=c.cd_country AND a1.cd_adm1=ii1.cd_adm1 AND ii0.cd_geounit=a0.cd_geounit AND cii.cd_country=a0.sovereign
    AND(
    (NOT federal AND type_part='State')
    OR (sovereign IN ('PER','BEL','BFA','CMR','TCD','CHL','GIN','MLI','MRT','MUS','MAR','OMN','PER','SEN','GNB','NAM') AND type_part='Region')
    OR (sovereign='CHL' AND adm1='Santiago Metropolitan')
    OR (sovereign='MLI' AND adm1='Bamako')
    OR (sovereign='MRT' AND adm1='Nouakchott')
    OR (sovereign='CHL' AND type_part='Metropolian region')
    OR (sovereign='AUS' AND NOT type_part IN ('State','Territory'))
    OR (sovereign='IND' AND NOT type_part IN ('State','Union Territory','Autonomous Region'))
    OR (sovereign='GBR' AND (NOT ii1.part_of_island OR type_part='Sovereign Base Area'))
    OR (sovereign='FRA' AND type_part IN ('Region','Kingdom','Administrative subdivisions'))
    OR (sovereign='CHN' AND type_part IN ('Municipality'))
    OR (sovereign='TKM' AND type_part='Captial City District')
    OR (sovereign='DOM' AND type_part='National District')
    OR (sovereign='MDG' AND type_part IS NULL)
    OR (ii1.all_island AND NOT ii1.part_of_island AND NOT cii.main_part_is_island AND NOT type_part IN ('State','Province','Department'))
    OR (NOT federal AND type_part IN ('Atoll','Atol','Island','Group of islands','Island Council','Island Group','Autonomous island'))
    OR (NOT federal AND type_part IN ('Province','Governorate'))
    OR (sovereign='CHN' AND type_part='Municipality')
    OR (sovereign IN ('BRN','CIV','UGA') AND type_part='District')
    OR (sovereign='ARM' AND adm1='Erevan')
    OR (sovereign='CIV' AND type_part='Autonomous district')
    OR (sovereign = 'LAO' AND type_part IN ('Municipality|Prefecture','Special Region|Zone'))
    OR (sovereign IN ('HUN') AND type_part='County')
    OR (sovereign IN ('HUN') AND type_part='Capital City')
    OR (sovereign='ATG' AND type_part='Dependency')
    OR (sovereign IN ('BGD','FJI','MMR') AND type_part='Division')
    OR (sovereign='MMR' AND adm1='Naypyitaw')
    OR (sovereign='COM' AND type_part='Autonomous Island')
    OR (sovereign='GEO' AND (type_part='Autonomous Republic'))
    OR (sovereign='GRC' AND type_part='Decentralized administration')
    OR (sovereign='PRK' AND type_part IN ('Directly Governed City','Special Administrative Region','Special City'))
    OR (sovereign IN ('SLB') AND type_part='Capital Territory')
    OR (sovereign IN ('ESP') AND type_part~'Autonomous')
    OR (sovereign IN ('TWN') AND type_part='Special Municipality')
    OR (sovereign IN ('TUV') AND type_part='Town Council')
    OR (sovereign IN ('VNM') AND type_part='City')
    OR (sovereign IN ('YEM') AND type_part='City')
    OR (sovereign IN ('ZWE') AND type_part='City')
    OR (sovereign IN ('GNB') AND adm1='Bissau')
    OR (sovereign IN ('KGZ') AND adm1 IN ('Biškek','Osh (city)'))
    OR (sovereign IN ('KHM') AND type_part='Municipality')
    OR (sovereign='KOR' AND adm1='Seoul')
    OR (sovereign='KOR'AND type_part IN ('Metropolitan City','Metropolitan Autonomous City','Capital Metropolitan City '))
    OR (sovereign='MNG' AND type_part='Municipality')
    OR (sovereign='FIN' AND type_part='Sub-Region')
    OR (sovereign='FIN' AND type_part='Statistical Region')
    )
;

UPDATE main.adm1 a1
SET cd_cat_part=3
FROM main.adm0_geounit a0, main.country c,main.adm1_island_info ii1,main.adm0_geounit_island_info ii0,main.country_island_info cii
WHERE a1.cd_cat_part IS NULL
    AND a1.cd_geounit=a0.cd_geounit AND a0.sovereign=c.cd_country AND a1.cd_adm1=ii1.cd_adm1 AND ii0.cd_geounit=a0.cd_geounit AND cii.cd_country=a0.sovereign
    AND(
    (sovereign IN ('BEN','BOL','COL','SLV','GTM','HTI','HND','NIC','NER','PRY','URY') AND type_part IN ('Department','Capital District','Intendancy','Commissiary','Autonomous Region'))
    OR (sovereign IN ('CHE','KEN') AND type_part IN ('Canton','County'))
    OR (sovereign='POL' AND type_part='Voivodeship')
    OR (sovereign='SVN' AND type_part='Statistical Region')
    OR (sovereign IN ('AZE','BLR','COG','CZE','DNK','DJI','ERI','GHA','GUY','ISL','ITA','KAZ','NZL','SGP','SVK','SOM','TJK','TZA','TGO','TTO','UKR','UZB','GEO','MLT','NZL') AND type_part='Region')
    OR (sovereign IN ('GEO') AND adm1 IN ('Tbilisi'))
    OR (sovereign IN ('TJK') AND type_part IN ('Districts of Republican Subordin'))
    OR (sovereign IN ('UKR') AND type_part IN ('Autonomous Republic','Independent City'))
    OR (sovereign IN ('UZB') AND type_part IN ('Autonomous Region','City'))
    OR (sovereign IN ('TJK') AND type_part IN ('Autonomous Region','City','District of Republican Subordin'))
    OR (sovereign IN ('TTO') AND type_part IN ('Borough','City'))
    OR (sovereign='BLR' AND adm1='Minsk')
    OR (sovereign='CAF' AND adm1='Bangui')
    OR (sovereign='BWA' AND type_part IN ('City','Town'))
    OR (sovereign IN ('NZL') AND type_part='Territory')
    OR (sovereign IN ('ITA') AND type_part='Autonomous Region')
    OR (sovereign IN ('ISL') AND type_part='Independent Town')
    OR (sovereign IN ('BWA','SWZ','ISR','KOS','LSO','LBY','LUX','MWI','PRT','TLS') AND type_part='District')
    OR (sovereign IN ('EST','LBR','NOR','LTU','ROU','SWE','ALB','HRV','IRL') AND type_part='County')
    OR (sovereign IN ('IRL') AND adm1='Dublin')
    OR (sovereign IN ('CAF','JPN') AND type_part~'Prefecture')
    OR (sovereign IN ('JPN') AND type_part IN('Circuit','Metropolis'))
    OR (sovereign='GMB'AND type_part IN ('Division','Independent City'))
    OR (sovereign='HRV' AND adm1='Grad Zagreb')
    OR (sovereign='ROU' AND adm1='Bucharest')
    )
;

UPDATE main.adm1 a1
SET cd_cat_part = 3
WHERE a1.cd_cat_part IS NULL AND  ((cd_geounit='CYN' AND type_part='District')
    OR (cd_geounit='SAH' AND type_part='Province'));

UPDATE main.adm1 a1
SET cd_cat_part=4
FROM main.adm0_geounit a0, main.country c,main.adm1_island_info ii1,main.adm0_geounit_island_info ii0,main.country_island_info cii
WHERE a1.cd_cat_part IS NULL
    AND a1.cd_geounit=a0.cd_geounit AND a0.sovereign=c.cd_country AND a1.cd_adm1=ii1.cd_adm1 AND ii0.cd_geounit=a0.cd_geounit AND cii.cd_country=a0.sovereign
    AND(
    (NOT cii.main_part_is_island AND ii1.all_island AND ii1.part_of_island AND type_part='District')
    OR (sovereign='GBR'AND type_part IN ('District','Parish','Parish District','Town District', 'Village District'))
    OR (sovereign IN ('BTN','BHS','BLZ','CYP','MUS','MDA','NRU','WSM','SRB','SYC','LKA','SUR') AND type_part='District')
    OR (sovereign IN ('SYC') AND type_part='Outer Islands')
    OR (sovereign IN ('ALB','HRV','IRL','CPV') AND type_part='County')
    OR (sovereign IN ('AND','ATG','BRB','DMA','JAM','GRD','KNA','VCT') AND type_part='Parish')
    OR (sovereign IN ('GRD') AND type_part='Dependency')
    OR (sovereign IN ('DNK') AND adm1='Bornholm')
    OR (sovereign IN ('MDA') AND type_part IN ('Autonomous Territory','City','Territorial Unit'))
    OR (sovereign='SRB' AND adm1='Grad Beograd')
    OR (sovereign='FRA' AND a1.cd_geounit <> 'FXX' AND type_part='Arrondissement')
    )
;

UPDATE main.adm1 a1
SET cd_cat_part=5
FROM main.adm0_geounit a0, main.country c,main.adm1_island_info ii1,main.adm0_geounit_island_info ii0,main.country_island_info cii
WHERE a1.cd_cat_part IS NULL
    AND a1.cd_geounit=a0.cd_geounit AND a0.sovereign=c.cd_country AND a1.cd_adm1=ii1.cd_adm1 AND ii0.cd_geounit=a0.cd_geounit AND cii.cd_country=a0.sovereign
    AND(
    (sovereign IN ('MNE','MKD') AND type_part='Municipality')
    OR (ii1.all_island AND ii1.part_of_island AND type_part IN ('Municipality','Commune'))
    OR (sovereign='FRA' AND a1.cd_geounit <> 'FXX' AND type_part='Parish')
    OR (sovereign='LIE' AND type_part='Commune')
    OR (sovereign IN ('QAT','STP','SMR') AND type_part='Municipality')
    OR (sovereign IN ('LCA') AND type_part='Quarter')
    OR (sovereign IN ('DNK') AND type_part='National Park')
    )
;

UPDATE main.adm1 a1
SET cd_cat_part=99
WHERE a1.cd_cat_part IS NULL AND type_part IN ('Water body')
;

/*
SELECT cd_geounit,cd_adm1,adm1,type_part,type_part_verbatim,a1.cd_cat_part
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a1.cd_cat_part IS NULL;

WITH a AS(
SELECT COALESCE(sovereign,cd_geounit) n0,ARRAY_AGG(DISTINCT geounit) geounits,ARRAY_AGG(DISTINCT a1.cd_cat_part) cd_cat_part
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a1.cd_cat_part<>99
GROUP BY COALESCE(sovereign,cd_geounit)
HAVING ARRAY_LENGTH(ARRAY_AGG(DISTINCT a1.cd_cat_part),1)>1
)
SELECT n0,cd_geounit,type_part,adm1,a1.cd_cat_part
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit USING (cd_geounit)
JOIN a ON COALESCE(sovereign,cd_geounit)=a.n0
ORDER BY n0,cd_cat_part
;

WITH a AS(
SELECT DISTINCT sovereign
FROM main.adm1 a1
LEFT JOIN main.adm0_geounit USING (cd_geounit)
WHERE a1.cd_cat_part IS NULL
)
SELECT sovereign,cd_geounit,geounit,
    ARRAY_AGG(DISTINCT a1.cd_cat_part),
    ARRAY_AGG(DISTINCT type_part) FILTER (WHERE a1.cd_cat_part IS NOT NULL) resolved,
    ARRAY_AGG(DISTINCT type_part) FILTER (WHERE a1.cd_cat_part IS NULL) to_cat,
    ARRAY_AGG(DISTINCT adm1) FILTER (WHERE a1.cd_cat_part IS NULL) adm1_to_resolve

FROM a
JOIN main.adm0_geounit USING(sovereign)
JOIN Main.adm1 a1 USING(cd_geounit)
GROUP BY sovereign,cd_geounit,geounit
ORDER BY sovereign,cd_geounit

;

SELECT cd_country,name,cd_geounit,geounit,adm1,type_part,type_part_verbatim,
    CASE WHEN ii1.all_island THEN '!!!TRUE!!!' WHEN NOT ii1.all_island THEN 'nope' END all_island,
    CASE WHEN ii1.part_of_island THEN '!!!TRUE!!!' WHEN NOT ii1.part_of_island THEN 'nope' END part_of_island,
    CASE WHEN ii1.main_part_is_island THEN '!!!TRUE!!!' WHEN NOT ii1.main_part_is_island THEN 'nope' END main_part_is_island,
a1.cd_cat_part
FROM main.adm1 a1
LEFT JOIN main.adm1_island_info ii1 USING (cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
LEFT JOIN main.adm0_geounit_island_info ii0 USING (cd_geounit)
LEFT JOIN main.country ON sovereign=cd_country
WHERE
    --type_part IN ('State') OR type_part ~ '[Ss]overeign' OR type_part ~ '[Ii]ndep' OR type_part~'[Aa]uton' OR type_part ~ '[Tt]errit'
    cd_country='USA'
ORDER BY name;

SELECT /*cd_country,name, cd_geounit, geounit, cd_adm1, adm1, */type_part, ARRAY_AGG(DISTINCT type_part_verbatim),count(*),ARRAY_AGG(DISTINCT name)
FROM main.country c
LEFT JOIN main.adm0_geounit a0 ON sovereign=cd_country
LEFT JOIN main.adm1 a1 USING (cd_geounit)
WHERE /*cd_country IN ('MYS', 'ARG', 'ETH', 'BRA', 'RUS', 'DEU', 'ARE', 'BEL', 'BIH', 'NPL', 'USA', 'CAN', 'IND', 'GBR', 'NGA', 'VEN', 'AUS', 'PAK',MEX)
AND*/ cd_cat_part IS NULL
--ORDER BY name, type_part
GROUP BY type_part
ORDER BY count(*)
;

SELECT cd_country,name, cd_geounit, geounit, cd_adm1, adm1, type_part, type_part_verbatim,cd_cat_part--, all_island, part_of_island
FROM main.adm1 a1
--LEFT JOIN main.adm1_island_info USING (cd_adm1)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.country c ON sovereign=cd_country
WHERE cd_country IN ('MYS', 'ARG', 'ETH', 'BRA', 'RUS', 'DEU', 'ARE', 'BEL', 'BIH', 'NPL', 'USA', 'CAN', 'IND', 'GBR', 'NGA', 'VEN', 'AUS', 'PAK','MEX','SOM') AND cd_cat_part IS NULL
ORDER BY name, type_part;


SELECT cd_country,name, cd_geounit, geounit, cd_adm1, adm1, type_part,cd_cat_part
FROM main.country c
LEFT JOIN main.adm0_geounit a0 ON sovereign=cd_country
LEFT JOIN main.adm1 a1 USING (cd_geounit)
WHERE cd_country IN ('MYS', 'ARG', 'ETH', 'BRA', 'RUS', 'DEU', 'ARE', 'BEL', 'BIH', 'NPL', 'USA', 'CAN', 'IND', 'GBR', 'NGA', 'VEN', 'AUS', 'PAK','MEX');


SELECT type_part, ARRAY_AGG(DISTINCT type_part_verbatim) verbatim, ARRAY_AGG(DISTINCT name),count(*)
FROM main.adm1
LEFT JOIN main.adm0_geounit USING (cd_geounit)
LEFT JOIN main.country ON sovereign=cd_country
WHERE cd_cat_part IS NULL
GROUP BY type_part
ORDER BY count(*) DESC;





WITH a AS(
SELECT cd_country,name,cd_geounit,geounit
FROM main.adm0_geounit g
LEFT JOIN main.country c ON c.cd_country=g.sovereign
ORDER BY cd_country,ST_Area(g.the_geom)
)
SELECT cd_country,name, ARRAY_AGG(geounit) FILTER (WHERE geounit=name OR cd_geounit=cd_country)
FROM a
GROUP BY cd_country,name
HAVING count(*) FILTER (WHERE geounit=name OR cd_geounit=cd_country) >1


SELECT cd_country,cd_geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5
FROM main.country c
FULL JOIN main.adm0_geounit a0 ON c.cd_country=a0.sovereign
FULL JOIN main.adm1 a1 USING(cd_geounit)
FULL JOIN main.adm2 a2 USING(cd_geounit,cd_adm1)
FULL JOIN main.adm3 a3 USING(cd_geounit,cd_adm1,cd_adm2)
FULL JOIN main.adm4 a4 USING(cd_geounit,cd_adm1,cd_adm2,cd_adm3)
FULL JOIN main.adm5 a5 USING(cd_geounit,cd_adm4)

WITH a AS(
SELECT cd_country,c.name, cd_geounit, geounit,
    CASE WHEN a0.cd_geounit=a1.equi_geounit THEN '=' ELSE '>' END|| ' 1: ' ||
    CASE WHEN a1.cd_adm1 IS NULL THEN '!NULL!' WHEN a1.type_part IS NULL THEN 'ND' ELSE a1.type_part END|| ' ' ||
    CASE WHEN a1.cd_adm1=a2.equi_adm1 THEN '=' ELSE '>' END|| ' 2: ' ||
    CASE WHEN a2.cd_adm2 IS NULL THEN '!NULL!' WHEN a2.type_part IS NULL THEN 'ND' ELSE a2.type_part END|| ' ' ||
    CASE WHEN a2.cd_adm2=a3.equi_adm2 THEN '=' ELSE '>' END|| ' 3: ' ||
    CASE WHEN a3.cd_adm3 IS NULL THEN '!NULL!' WHEN a3.type_part IS NULL THEN 'ND' ELSE a3.type_part END|| ' ' ||
    CASE WHEN a3.cd_adm3=a4.equi_adm3 THEN '=' ELSE '>' END|| ' 4: ' ||
    CASE WHEN a4.cd_adm4 IS NULL THEN '!NULL!' WHEN a4.type_part IS NULL THEN 'ND' ELSE a4.type_part END|| ' ' ||
    CASE WHEN a4.cd_adm4=a5.equi_adm4 THEN '=' ELSE '>' END|| ' 5: ' ||
    CASE WHEN a5.cd_adm5 IS NULL THEN '!NULL!' WHEN a5.type_part IS NULL THEN 'ND' ELSE a5.type_part END phrase

FROM main.adm5 a5
FULL JOIN main.adm4 a4 USING(cd_geounit,cd_adm4)
FULL JOIN main.adm3 a3 USING(cd_geounit,cd_adm3,cd_adm2,cd_adm1)
FULL JOIN main.adm2 a2 USING(cd_geounit,cd_adm2,cd_adm1)
FULL JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
FULL JOIN main.adm0_geounit a0 USING (cd_geounit)
FULL JOIN main.country c ON c.cd_country=a0.sovereign
ORDER BY cd_country,c.name,cd_geounit,geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5
)
SELECT cd_country,name,cd_geounit, phrase, count(*)
FROM a
GROUP BY cd_country,name,cd_geounit, phrase
ORDER BY cd_country,cd_geounit,count(*) DESC
;

WITH a AS(
SELECT type_part, 1 AS level
FROM main.adm1
UNION ALL
SELECT type_part, 2 AS level
FROM main.adm2
UNION ALL
SELECT type_part, 3 AS level
FROM main.adm3
UNION ALL
SELECT type_part, 4 AS level
FROM main.adm4
UNION ALL
SELECT type_part, 5 AS level
FROM main.adm5
), b AS(
SELECT type_part,ARRAY_AGG(DISTINCT level)levels,
    count(*) nb,
    count(*) FILTER (WHERE level=1) nb_1,
    count(*) FILTER (WHERE level=2) nb_2,
    count(*) FILTER (WHERE level=3) nb_3,
    count(*) FILTER (WHERE level=4) nb_4,
    count(*) FILTER (WHERE level=5) nb_5
FROM a
GROUP BY type_part
ORDER BY count(*) DESC
)
SELECT * FROM b ORDER BY nb_1 DESC;


WITH a AS(
SELECT cd_country,c.name, cd_geounit, geounit, adm1,
    CASE WHEN a0.cd_geounit=a1.equi_geounit THEN '=' ELSE '>' END|| ' 1: ' ||
    CASE WHEN a1.cd_adm1 IS NULL THEN '!NULL!' WHEN a1.type_part IS NULL THEN 'ND' ELSE a1.type_part END|| ' ' ||
    CASE WHEN a1.cd_adm1=a2.equi_adm1 THEN '=' ELSE '>' END|| ' 2: ' ||
    CASE WHEN a2.cd_adm2 IS NULL THEN '!NULL!' WHEN a2.type_part IS NULL THEN 'ND' ELSE a2.type_part END|| ' ' ||
    CASE WHEN a2.cd_adm2=a3.equi_adm2 THEN '=' ELSE '>' END|| ' 3: ' ||
    CASE WHEN a3.cd_adm3 IS NULL THEN '!NULL!' WHEN a3.type_part IS NULL THEN 'ND' ELSE a3.type_part END|| ' ' ||
    CASE WHEN a3.cd_adm3=a4.equi_adm3 THEN '=' ELSE '>' END|| ' 4: ' ||
    CASE WHEN a4.cd_adm4 IS NULL THEN '!NULL!' WHEN a4.type_part IS NULL THEN 'ND' ELSE a4.type_part END|| ' ' ||
    CASE WHEN a4.cd_adm4=a5.equi_adm4 THEN '=' ELSE '>' END|| ' 5: ' ||
    CASE WHEN a5.cd_adm5 IS NULL THEN '!NULL!' WHEN a5.type_part IS NULL THEN 'ND' ELSE a5.type_part END phrase

FROM main.adm5 a5
FULL JOIN main.adm4 a4 USING(cd_geounit,cd_adm4)
FULL JOIN main.adm3 a3 USING(cd_geounit,cd_adm3,cd_adm2,cd_adm1)
FULL JOIN main.adm2 a2 USING(cd_geounit,cd_adm2,cd_adm1)
FULL JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
FULL JOIN main.adm0_geounit a0 USING (cd_geounit)
FULL JOIN main.country c ON c.cd_country=a0.sovereign
ORDER BY cd_country,c.name,cd_geounit,geounit,cd_adm1,cd_adm2,cd_adm3,cd_adm4,cd_adm5
), b AS(
SELECT cd_country,name,cd_geounit,geounit, phrase, count(*)
FROM a
GROUP BY cd_country,name,cd_geounit,geounit, phrase
ORDER BY cd_country,cd_geounit,count(*) DESC
)
SELECT *
FROM b ORDER BY phrase ~ 'Province';





SELECT name,cd_geounit,geounit,cd_adm1,adm1,type_part,type_part_verbatim,
        CASE WHEN ii1.all_island THEN '!!!TRUE!!!' WHEN NOT ii1.all_island THEN 'nope' END all_island,
        CASE WHEN ii1.part_of_island THEN '!!!TRUE!!!' WHEN NOT ii1.part_of_island THEN 'nope' END part_of_island,
        CASE WHEN ii1.main_part_is_island THEN '!!!TRUE!!!' WHEN NOT ii1.main_part_is_island THEN 'nope' END main_part_is_island,
        CASE WHEN cii.all_island THEN '!!!TRUE!!!' WHEN NOT cii.all_island THEN 'nope' END all_island,
        CASE WHEN cii.part_of_island THEN '!!!TRUE!!!' WHEN NOT cii.part_of_island THEN 'nope' END part_of_island,
        CASE WHEN cii.main_part_is_island THEN '!!!TRUE!!!' WHEN NOT cii.main_part_is_island THEN 'nope' END main_part_is_island,
        ii1.nb_island_parts
FROM main.country c
LEFT JOIN main.country_island_info cii USING(cd_country)
LEFT JOIN main.adm0_geounit a0 ON sovereign=cd_country
LEFT JOIN main.adm0_geounit_island_info ii0 USING(cd_geounit)
LEFT JOIN main.adm1 a1 USING (cd_geounit)
LEFT JOIN main.adm1_island_info ii1 USING(cd_adm1)
WHERE /*cd_country IN ('MYS', 'ARG', 'ETH', 'BRA', 'RUS', 'DEU', 'ARE', 'BEL', 'BIH', 'NPL', 'USA', 'CAN', 'IND', 'GBR', 'NGA', 'VEN', 'AUS', 'PAK',MEX)
AND*/ cd_cat_part IS NULL
AND ii1.all_island /*AND ii1.main_part_is_island*/ AND NOT ii1.part_of_island /*AND NOT cii.main_part_is_island*/
ORDER BY cd_country,type_part;

SELECT cd_country,name,federal,
    COUNT(*) FILTER (WHERE a1.cd_cat_part IS NOT NULL) nb_already,
    COUNT(*) FILTER (WHERE a1.cd_cat_part IS NULL) nb_to_cat,
    ARRAY_AGG(DISTINCT type_part) FILTER (WHERE a1.cd_cat_part IS NOT NULL) already,
    ARRAY_AGG(DISTINCT type_part) FILTER (WHERE a1.cd_cat_part IS NULL) to_cat

FROM main.adm1 a1
LEFT JOIN main.adm1_island_info USING (cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
LEFT JOIN Main.country ON sovereign=cd_country
GROUP BY cd_country,name
ORDER BY ARRAY_LENGTH( ARRAY_AGG(DISTINCT type_part) FILTER (WHERE a1.cd_cat_part IS NULL),1)
;




/*
 Metropolitan Autonomous City
 Captial City District
 Administrative Area
 Capital City
 Reef
 Municipality|Prefecture
 Special Region|Zone
 Metropolis
 State reserve
 Town Council
 Territorial Unit
 National District
 Autonomous Commune
 Autonomous Territory
 Autonomous Sector
 Capital Metropolitan City
 National Park
 Autonomous island
 Township
 Districts of Republican Subordin
 Directly Governed City
 Capital Territory
 Union territory
 Special City
 Outer Islands
 Circuit
 Independent Town
 Autononous Region
 Metropolian Region
 'Autonomous Region'
 Autonomous City
 Autonomous district
 Sovereign Base Area
 Urban Prefecture
 Village District
 Group of islands
 Economic Prefecture
 Autonomous Island
 Capital District
 Borough
 Autonomous Republic
 Indigenous Territory
 Kingdom
 Sub-Region
 Independent City
 Town District
 Intendancy
 Town
 Territory
 Atoll
 Special Administrative Region
 Special Municipality
 Commissiary
 Island Group
 Dependency
 Administrative subdivisions
 Metropolitan City
 Decentralized administration
 Water body
 Quarter
 Arrondissement
 Statistical Region
 Parish District
 Autonomous Region
 Island
 Voivodeship
 Autonomous Community
 Island Council
 Atol
 Division
 City
 Canton
 Commune
 Prefecture

 State
 Governorate
 Parish
 Department
 Municipality
 County
 District
 Region
 Province
*/
*/
