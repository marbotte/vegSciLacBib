
------------------------------------------------------
---------ADM1 types-----------------------------------
------------------------------------------------------

--ALTER TABLE main.adm4 ADD COLUMN cd_cat_part int REFERENCES main.categ_part(cd_cat_part);
--ALTER TABLE main.adm4 DROP COLUMN cd_cat_part ;
--UPDATE main.adm4 SET cd_cat_part=NULL;


-- First we try to manage the cases where all the type_part of a sovereign are the same
/*
WITH a AS(
SELECT sovereign,ARRAY_AGG(DISTINCT geounit) geounits/*, ARRAY_AGG(DISTINCT geounit)*/,ARRAY_AGG(DISTINCT a1.cd_cat_part ORDER BY a1.cd_cat_part) sup_cat,ARRAY_AGG(DISTINCT a4.type_part),count(*)
FROM main.adm4 a4
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
GROUP BY sovereign
HAVING count(DISTINCT a4.type_part)=1
), b AS(
SELECT sovereign,geounits,sup_cat, sup_cat[ARRAY_LENGTH(sup_cat,1)] max_sup_cat
FROM a
)
SELECT sovereign,cd_adm4,adm4,sup_cat,max_sup_cat,a4.type_part
FROM main.adm4 a4
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
JOIN b USING(sovereign)
ORDER BY type_part,sovereign;
*/

UPDATE main.adm5 SET cd_cat_part=NULL;
SELECT count(*) FROM main.adm5 WHERE cd_cat_part IS NULL;

UPDATE main.adm5
SET cd_cat_part=99
WHERE type_part IN ('Waterbody','Water body','Water Body');
SELECT count(*) FROM main.adm5 WHERE cd_cat_part IS NULL;

/*
SELECT ARRAY_AGG(DISTINCT sovereign),ARRAY_AGG(DISTINCT a4.cd_cat_part),
CASE WHEN a5.cd_adm4 IS NULL THEN NULL WHEN a5.equi_adm4 IS NULL THEN false WHEN a5.equi_adm4=a4.cd_adm4 THEN true END equivalent,/*cd_adm5,a4.cd_cat_part,*/a5.type_part,count(DISTINCT cd_adm5)
FROM main.adm5 a5
LEFT JOIN main.adm4 a4 USING(cd_adm4,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE  a5.cd_cat_part IS NULL
GROUP BY a5.type_part, equivalent
ORDER BY a5.type_part,equivalent--count(DISTINCT cd_adm5) DESC
;
*/

WITH a AS(
SELECT cd_adm5,CASE WHEN a5.cd_adm4 IS NULL THEN NULL WHEN a5.equi_adm4 IS NULL THEN false WHEN a5.equi_adm4=a4.cd_adm4 THEN true END equivalent ,a4.cd_cat_part cd_cat_part_sup,sovereign
FROM main.adm5 a5
LEFT JOIN main.adm4 a4 USING(cd_adm4,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a5.cd_cat_part IS NULL
)
UPDATE main.adm5 a5
SET cd_cat_part=
    CASE
        WHEN cd_cat_part_sup=99 THEN 99
        WHEN cd_cat_part_sup=4 THEN 5
        WHEN cd_cat_part_sup>=5 THEN 6
    END
FROM a
WHERE a.cd_adm5=a5.cd_adm5;

/*
SELECT cd_adm5,cd_cat_part,adm5
FROM main.adm5
WHERE adm5 ~ '[Aa]rrondissement';
*/

UPDATE main.adm5
SET cd_cat_part=6
WHERE adm5 ~ '[Aa]rrondissement';



SELECT cd_adm3,cd_cat_part,adm3
FROM main.adm3
WHERE adm3 ~ '[Aa]rrondissement';
