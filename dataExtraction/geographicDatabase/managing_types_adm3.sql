
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

UPDATE main.adm3 SET cd_cat_part=NULL;
SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;

UPDATE main.adm3
SET cd_cat_part=99
WHERE type_part IN ('Waterbody','Water body','Water Body');
SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;


-- adm2 is municipality, adm3 correspond exactly to adm2
/*
SELECT sovereign,/*cd_adm3,a2.cd_cat_part,*/a3.type_part,count(*)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=5 AND a3.equi_adm2=cd_adm2
GROUP BY sovereign,a3.type_part
ORDER BY sovereign;
*/
WITH a AS(
SELECT cd_adm3
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=5 AND a3.equi_adm2=cd_adm2
)
UPDATE main.adm3 a3
SET cd_cat_part=5
FROM a
WHERE a.cd_adm3=a3.cd_adm3 AND a3.cd_cat_part IS NULL;

SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;
-- adm2 is municipality, adm3 does not correspond to adm2
/*
SELECT sovereign,/*cd_adm3,a2.cd_cat_part,*/a3.type_part,count(*)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=5 AND a3.equi_adm2 IS NULL
GROUP BY sovereign,a3.type_part
ORDER BY sovereign;
*/
WITH a AS(
SELECT cd_adm3
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=5 AND a3.equi_adm2 IS NULL
)
UPDATE main.adm3 a3
SET cd_cat_part=6
FROM a
WHERE a.cd_adm3=a3.cd_adm3 AND a3.cd_cat_part IS NULL;

SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;
-- Adm2 is 4 (just higher than municipality)
/*
SELECT sovereign,/*cd_adm3,a2.cd_cat_part,*/a3.type_part, ARRAY_AGG(DISTINCT a4.type_part),count(DISTINCT cd_adm3)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm4 a4 USING(cd_adm3,cd_geounit)
WHERE a2.cd_cat_part=4 AND a3.equi_adm2=a3.cd_adm2
GROUP BY sovereign,a3.type_part
ORDER BY sovereign;
*/

WITH a AS(
SELECT cd_adm3,a3.cd_cat_part
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=4 AND a3.equi_adm2=a2.cd_adm2
)
UPDATE main.adm3 a3
SET cd_cat_part=
    CASE
        WHEN type_part IN ('Municipality','Commune','Ville','City','Town','Municipality (rural)','Village','Clan','Ward') THEN 5
        ELSE 4
    END
FROM a
WHERE a.cd_adm3=a3.cd_adm3 AND a3.cd_cat_part IS NULL;

SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;


--adm2 is a district
/*
SELECT sovereign,/*cd_adm3,a2.cd_cat_part,*/a3.type_part, ARRAY_AGG(DISTINCT a4.type_part),count(DISTINCT cd_adm3)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm4 a4 USING(cd_adm3,cd_geounit)
WHERE a2.cd_cat_part=4 AND a3.equi_adm2 IS NULL
GROUP BY sovereign,a3.type_part
ORDER BY sovereign;

SELECT ARRAY_AGG(DISTINCT sovereign),/*cd_adm3,a2.cd_cat_part,*/a3.type_part, ARRAY_AGG(DISTINCT a4.type_part),count(DISTINCT cd_adm3)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm4 a4 USING(cd_adm3,cd_geounit)
WHERE a2.cd_cat_part=4 AND a3.equi_adm2 IS NULL
GROUP BY a3.type_part
ORDER BY count(DISTINCT cd_adm3) DESC;
*/
WITH a AS(
SELECT cd_adm3,a3.cd_cat_part,sovereign
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=4 AND a3.equi_adm2 IS NULL
)
UPDATE main.adm3 a3
SET cd_cat_part=
    CASE
        WHEN type_part IN ('Municipality','Commune','Ville','City','Town','Municipality (rural)','Municipality (urban)','Municipality (urban-rural)','Village','District','Township','Rural Parish','Townlet','Community','Distrito','Clan','Parish Municipality','Ville','Local Municipality','Indian reserve','Cantonal Head','Small town','Parish','Township and Royalty','Canton Municipality','Village Nordique','Municipal District','Indian Settlement','Village Cri','United Cantons Municipality','Islands','Regional Municipality','Village Naskapi','City County','Administrative District','Rural Community','Metropolitan Municipality') THEN 5
        WHEN type_part IS NULL AND sovereign='RUS' THEN 6
        WHEN type_part IS NULL AND sovereign='ALB' THEN 5
        WHEN type_part IN ('Ward','Neighborhood','Locality','Subdivision of County Municipali','Unorganized','Inuite Land','Land Reserved','Training Center','','','','') THEN 6
        ELSE 5
    END
FROM a
WHERE a.cd_adm3=a3.cd_adm3 AND a3.cd_cat_part IS NULL;

SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;

--adm2 is a department
/*
SELECT ARRAY_AGG(DISTINCT sovereign),a3.equi_adm2=a2.cd_adm2,/*cd_adm3,a2.cd_cat_part,*/a3.type_part, ARRAY_AGG(DISTINCT a4.type_part),count(DISTINCT cd_adm3)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm4 a4 USING(cd_adm3,cd_geounit)
WHERE a2.cd_cat_part=3 AND a3.cd_cat_part IS NULL
GROUP BY a3.type_part, a3.equi_adm2=a2.cd_adm2
ORDER BY a3.type_part,a3.equi_adm2=a2.cd_adm2--count(DISTINCT cd_adm3) DESC
;
*/
WITH a AS(
SELECT cd_adm3,CASE WHEN a3.equi_adm2=a2.cd_adm2 THEN true ELSE false END equivalent ,a3.cd_cat_part,sovereign
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a2.cd_cat_part=3 AND a3.cd_cat_part IS NULL
)
UPDATE main.adm3 a3
SET cd_cat_part=
    CASE
        WHEN type_part IN ('Canton Municipality', 'Chartered Community', 'Chiefdom', 'City', 'County City', 'County Municipality',  'Hamlet',  'Indian reserve',  'Island Municipality', 'Metropolitan borough', 'Metropolitan borough (city)', 'Municipality', 'Nisga''a Village', 'Northern Hamlet', 'Northern Village', 'Parish', 'Resort Village', 'Rural Municipality', 'Settlement', 'Specialized Municipality', 'Sub district', 'Sub-prefecture', 'Summer Village', 'Taluk', 'Town', 'Unitary authority (city)', 'Unitary district (city)', 'Village', 'Village|Township', 'Ville', 'Ward') THEN 5
        ELSE 4
    END
FROM a
WHERE a.cd_adm3=a3.cd_adm3;


SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;
/*
SELECT ARRAY_AGG(DISTINCT sovereign),ARRAY_AGG(DISTINCT a3.cd_cat_part),a3.equi_adm2=a2.cd_adm2,/*cd_adm3,a2.cd_cat_part,*/a3.type_part, ARRAY_AGG(DISTINCT a4.type_part),count(DISTINCT cd_adm3)
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm4 a4 USING(cd_adm3,cd_geounit)
WHERE  a3.cd_cat_part IS NULL
GROUP BY a3.type_part, a3.equi_adm2=a2.cd_adm2
ORDER BY a3.type_part,a3.equi_adm2=a2.cd_adm2--count(DISTINCT cd_adm3) DESC
;
*/
WITH a AS(
SELECT cd_adm3,CASE WHEN a3.equi_adm2=a2.cd_adm2 THEN true ELSE false END equivalent ,a3.cd_cat_part,sovereign
FROM main.adm3 a3
LEFT JOIN main.adm2 a2 USING(cd_adm2,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a3.cd_cat_part IS NULL
)
UPDATE main.adm3 a3
SET cd_cat_part=
    CASE
        WHEN type_part ~ '[Bb]orough' THEN 5
        WHEN type_part ~ '[Cc]ity' THEN 5
        WHEN type_part ~ '[Mm]unicipality' THEN 5
        ELSE 4
    END
FROM a
WHERE a.cd_adm3=a3.cd_adm3;

SELECT count(*) FROM main.adm3 WHERE cd_cat_part IS NULL;

UPDATE main.adm3
SET cd_cat_part=6
WHERE adm3 ~ '[Aa]rrondissement';
