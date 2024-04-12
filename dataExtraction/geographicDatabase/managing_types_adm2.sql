
------------------------------------------------------
---------ADM1 types-----------------------------------
------------------------------------------------------

--ALTER TABLE main.adm2 ADD COLUMN cd_cat_part int REFERENCES main.categ_part(cd_cat_part);
--ALTER TABLE main.adm2 DROP COLUMN cd_cat_part ;
--UPDATE main.adm2 SET cd_cat_part=NULL;


-- First we try to manage the cases where all the type_part of a sovereign are the same
/*
WITH a AS(
SELECT sovereign,ARRAY_AGG(DISTINCT geounit) geounits/*, ARRAY_AGG(DISTINCT geounit)*/,ARRAY_AGG(DISTINCT a1.cd_cat_part ORDER BY a1.cd_cat_part) sup_cat,ARRAY_AGG(DISTINCT a2.type_part),count(*)
FROM main.adm2 a2
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
GROUP BY sovereign
HAVING count(DISTINCT a2.type_part)=1
), b AS(
SELECT sovereign,geounits,sup_cat, sup_cat[ARRAY_LENGTH(sup_cat,1)] max_sup_cat
FROM a
)
SELECT sovereign,cd_adm2,adm2,sup_cat,max_sup_cat,a2.type_part
FROM main.adm2 a2
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
JOIN b USING(sovereign)
ORDER BY type_part,sovereign;
*/

UPDATE main.adm2 SET cd_cat_part=NULL;
SELECT count(*) FROM main.adm2 WHERE cd_cat_part IS NULL;

UPDATE main.adm2 a2
SET cd_cat_part=
    CASE
        WHEN a1.sovereign IN ('NPL','MLI','KEN','CMR','GAB','MRT','SEN','TCD','BGD','IRQ','LAO','LBN','LVA','MMR','PNG','RWA','SDN','SSD','PAK','GIN','BFA','CHL','GRC') THEN 3
        WHEN a1.sovereign IN ('NER','BIH','CRI','LUX','NAM','SWZ','AFG','BLR','COG','ERI','GMB','HTI','LBR','MOZ','SOM','SVK','SYR','TJK','TON','TUR','YEM','ZMB','ZWE','ZAF','SUR','TLS','EGY','CAF','JOR','HUN','MNG','SLB','BOL','GNB','FJI')  THEN 4
        WHEN a1.sovereign IN
        ('GNQ','LKA','ISR','SAU','MLT','BRN','BRA','PRT','SWE','AGO','CUB','HND','ISL','MEX','NOR','KOS','BTN','SVN','SRB','BEN') THEN 5
    END
FROM main.adm0_geounit a1
WHERE a1.cd_geounit=a2.cd_geounit AND a2.cd_cat_part IS NULL;

SELECT count(*) FROM main.adm2 WHERE cd_cat_part IS NULL;

UPDATE main.adm2 a2
SET cd_cat_part=5
WHERE type_part IN ('Municipality','Commune') AND cd_cat_part IS NULL;

SELECT count(*) FROM main.adm2 WHERE cd_cat_part IS NULL;


UPDATE main.adm2 a2
SET cd_cat_part=99
WHERE type_part IN ('Water body','Waterbody','Water Body') AND cd_cat_part IS NULL;

SELECT count(*) FROM main.adm2 WHERE cd_cat_part IS NULL;


/*
SELECT sovereign,ARRAY_AGG(DISTINCT a1.cd_cat_part) parent_cat,a2.type_part,count(*),ARRAY_AGG(DISTINCT a3.type_part)
FROM main.adm2 a2
LEFT JOIN main.adm1 a1 USING (cd_adm1,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm3 a3 USING (cd_adm2)
WHERE a2.cd_cat_part IS NULL
GROUP BY sovereign,a2.type_part
ORDER BY  sovereign,count(*) DESC
;
*/

WITH a AS(
SELECT cd_adm2,
    CASE
        WHEN sovereign IN ('ALB') AND type_part IS NULL THEN 4

        WHEN sovereign IN ('ARE') AND type_part IN ('Emirate','Sector','Region') THEN 3
        WHEN sovereign IN ('ARE') AND type_part IN ('District','Municipal Region') THEN 4
        WHEN sovereign IN ('ARE') AND type_part IN ('Township','Village') THEN 5

        WHEN sovereign IN ('ARG') THEN 3

        WHEN sovereign IN ('AUS') AND type_part IN ('Region','Area','Unincorporated Area','Region','Territory','Regional Council') THEN 3
        WHEN sovereign IN ('AUS') AND type_part IN ('Islands','Borough','Shire','District Council','Aboriginal Council','State reserve') THEN 4
        WHEN sovereign IN ('AUS') AND type_part IN ('City','Town','Rural City') THEN 5

        WHEN sovereign IN ('AUT') THEN 4

        WHEN sovereign IN ('AZE') AND type_part IN ('District') THEN 4
        WHEN sovereign IN ('AZE') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('BDI') AND type_part IN ('Commune') THEN 5

        WHEN sovereign IN ('BEL') THEN 3

        WHEN sovereign IN ('BGR') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('BWA') AND type_part IS NULL OR type_part IN ('Sub-district') THEN 4
        WHEN sovereign IN ('BWA') AND type_part IN ('Town','City','Town Council') THEN 5

        WHEN sovereign IN ('CAN') AND type_part IN ('Census Division','Regional District','Region','Territory') THEN 3
        WHEN sovereign IN ('CAN') AND type_part IN ('Regional County Municipality','District','Regional Municipality','United Counties','United County','District Municipality','County') THEN 4

        WHEN sovereign IN ('CHE') AND type_part IN ('District') THEN 4

        WHEN sovereign IN ('CHN') THEN 3

        WHEN sovereign IN ('CIV') THEN 3

        WHEN sovereign IN ('COD') AND type_part IN ('Territory') THEN 3
        WHEN sovereign IN ('COD') AND type_part IN ('Town') THEN 5

        WHEN sovereign IN ('COL') THEN 4

        WHEN sovereign IN ('CZE') THEN 4

        WHEN sovereign IN ('DEU')  THEN 4

        WHEN sovereign IN ('DJI') THEN 4

        WHEN sovereign IN ('DNK') AND type_part IN ('Commune') THEN 5

        WHEN sovereign IN ('DOM') AND type_part IN ('Municipal district') THEN 4

        WHEN sovereign IN ('DZA') THEN 5

        WHEN sovereign IN ('ECU') THEN 4

        WHEN sovereign IN ('ESP')  THEN 3

        WHEN sovereign IN ('EST') AND type_part IN ('Parish') THEN 4
        WHEN sovereign IN ('EST') AND type_part IN ('Town') THEN 5

        WHEN sovereign IN ('ETH') THEN 3

        WHEN sovereign IN ('FIN') THEN 3

        WHEN sovereign IN ('FRA') AND type_part IN ('Department') THEN 3
        WHEN sovereign IN ('FRA') AND type_part IN ('District','Islands') THEN 4
        WHEN sovereign IN ('FRA') AND type_part IN ('Commune') THEN 5
        WHEN sovereign IN ('FRA') AND type_part IN ('Quarter') THEN 6

        WHEN sovereign IN ('FSM') AND type_part IN ('Atol','Reef') THEN 3

        WHEN sovereign IN ('GBR') THEN 3

        WHEN sovereign IN ('GEO') AND type_part IN ('District') THEN 4
        WHEN sovereign IN ('GEO') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('GHA')  THEN 4

        WHEN sovereign IN ('GUY') THEN 4

        WHEN sovereign IN ('HRV') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('IDN') AND (type_part IN ('Regency') OR type_part IS NULL)  THEN 3
        WHEN sovereign IN ('') AND type_part IN ('') THEN 4
        WHEN sovereign IN ('IDN') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('IND') THEN 3

        WHEN sovereign IN ('IRL') AND type_part IN ('City') THEN 5
        WHEN sovereign IN ('IRL') AND NOT type_part='City'  THEN 4

        WHEN sovereign IN ('IRN')  THEN 3

        WHEN sovereign IN ('ITA') THEN 4

        WHEN sovereign IN ('JPN') AND type_part IN ('County','Subprefecture') THEN 4
        WHEN sovereign IN ('JPN') AND NOT type_part IN ('County','Subprefecture') THEN 5

        WHEN sovereign IN ('KAZ') THEN 4

        WHEN sovereign IN ('KGZ') AND type_part IN ('District') THEN 4
        WHEN sovereign IN ('KGZ') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('KHM') AND type_part IN ('District') THEN 4

        WHEN sovereign IN ('KOR') AND (type_part IN ('District','County') OR type_part IS NULL) THEN 4
        WHEN sovereign IN ('KOR') AND type_part IN ('City','Township') THEN 5

        WHEN sovereign IN ('LTU') THEN 5

        WHEN sovereign IN ('MAR') THEN 3

        WHEN sovereign IN ('MDG') THEN 3

        WHEN sovereign IN ('MWI') AND type_part IN ('Town','City','Urban') THEN 5
        WHEN sovereign IN ('MWI') AND NOT type_part IN ('Town','City','Urban') THEN 4

        WHEN sovereign IN ('MYS') THEN 3

        WHEN sovereign IN ('NGA') THEN 3

        WHEN sovereign IN ('NZL') AND NOT type_part IN ('City') THEN 4
        WHEN sovereign IN ('NZL') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('OMN') THEN 3

        WHEN sovereign IN ('PAN')  THEN 3

        WHEN sovereign IN ('PER') THEN 4

        WHEN sovereign IN ('PHL') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('POL')  THEN 4

        WHEN sovereign IN ('PRK') AND type_part IN ('County') THEN 4
        WHEN sovereign IN ('PRK') AND NOT type_part IN ('County') THEN 5

        WHEN sovereign IN ('PRY')  THEN 4

        WHEN sovereign IN ('ROU')  THEN 5

        WHEN sovereign IN ('RUS') AND (type_part IN ('Raion','Island','Islands','Autonomous Okurg') OR type_part IS NULL) THEN 3
        WHEN sovereign IN ('RUS') AND type_part IN ('District') THEN 4
        WHEN sovereign IN ('RUS') AND type_part IN ('Town','City','City of Regional Significance') THEN 5

        WHEN sovereign IN ('SLE')  THEN 3

        WHEN sovereign IN ('STP')  THEN 4

        WHEN sovereign IN ('TGO') AND type_part IN ('Prefecture','Sub-Prefecture') THEN 4
        WHEN sovereign IN ('TGO') AND type_part IN ('Commune') THEN 5

        WHEN sovereign IN ('THA')  THEN 3

        WHEN sovereign IN ('TKM') AND type_part IN ('District','Borough') THEN 4
        WHEN sovereign IN ('TKM') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('TUN') AND type_part IN ('Delegation') THEN 3

        WHEN sovereign IN ('TWN')  THEN 4

        WHEN sovereign IN ('TZA') THEN 4

        WHEN sovereign IN ('UGA') THEN 3

        WHEN sovereign IN ('UKR') AND type_part IN ('District','Raion') THEN 3
        WHEN sovereign IN ('UKR') AND type_part~'City' THEN 4

        WHEN sovereign IN ('URY') AND type_part~'Munic' THEN 4

        WHEN sovereign IN ('USA') AND (type_part IN ('County','Parish','Borough','Census Area','City and Borough','City and County','District','Island') OR type_part IS NULL) THEN 4
        WHEN sovereign IN ('USA') AND type_part IN ('City','Independent City') THEN 5

        WHEN sovereign IN ('UZB') AND type_part IN ('District') THEN 4
        WHEN sovereign IN ('UZB') AND type_part IN ('City') THEN 5

        WHEN sovereign IN ('VEN') AND type_part IN ('Islands') THEN 4

        WHEN sovereign IN ('VNM') AND type_part IN ('District','Urban District','Area council') THEN 4
        WHEN sovereign IN ('VNM') AND type_part IN ('City','Town') THEN 5

        WHEN sovereign IN ('VUT') AND type_part IN ('Area council') THEN 4

        WHEN sovereign IN ('WSM') THEN 5
    END cd_cat_part
FROM main.adm2
LEFT JOIN main.adm0_geounit USING(cd_geounit)
)
UPDATE main.adm2 a2
SET cd_cat_part=a.cd_cat_part
FROM a
WHERE a.cd_adm2=a2.cd_adm2 AND a2.cd_cat_part IS NULL;


SELECT count(*) FROM main.adm2 WHERE cd_cat_part IS NULL;
