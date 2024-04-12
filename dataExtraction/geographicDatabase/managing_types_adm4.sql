
------------------------------------------------------
---------ADM1 types-----------------------------------
------------------------------------------------------

--ALTER TABLE main.adm3 ADD COLUMN cd_cat_part int REFERENCES main.categ_part(cd_cat_part);
--ALTER TABLE main.adm3 DROP COLUMN cd_cat_part ;
--UPDATE main.adm3 SET cd_cat_part=NULL;


-- First we try to manage the cases where all the type_part of a sovereign are the same
/*
WITH a AS(
SELECT sovereign,ARRAY_AGG(DISTINCT geounit) geounits/*, ARRAY_AGG(DISTINCT geounit)*/,ARRAY_AGG(DISTINCT a1.cd_cat_part ORDER BY a1.cd_cat_part) sup_cat,ARRAY_AGG(DISTINCT a3.type_part),count(*)
FROM main.adm3 a3
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
GROUP BY sovereign
HAVING count(DISTINCT a3.type_part)=1
), b AS(
SELECT sovereign,geounits,sup_cat, sup_cat[ARRAY_LENGTH(sup_cat,1)] max_sup_cat
FROM a
)
SELECT sovereign,cd_adm3,adm3,sup_cat,max_sup_cat,a3.type_part
FROM main.adm3 a3
LEFT JOIN main.adm1 a1 USING(cd_geounit,cd_adm1)
LEFT JOIN main.adm0_geounit USING (cd_geounit)
JOIN b USING(sovereign)
ORDER BY type_part,sovereign;
*/

UPDATE main.adm4 SET cd_cat_part=NULL;
SELECT count(*) FROM main.adm4 WHERE cd_cat_part IS NULL;

UPDATE main.adm4
SET cd_cat_part=99
WHERE type_part IN ('Waterbody','Water body','Water Body');
SELECT count(*) FROM main.adm4 WHERE cd_cat_part IS NULL;


/*
SELECT ARRAY_AGG(DISTINCT sovereign),ARRAY_AGG(DISTINCT a3.cd_cat_part),
CASE WHEN a4.cd_adm3 IS NULL THEN NULL WHEN a4.equi_adm3 IS NULL THEN false WHEN a4.equi_adm3=a3.cd_adm3 THEN true END equivalent,/*cd_adm4,a3.cd_cat_part,*/a4.type_part, ARRAY_AGG(DISTINCT a5.type_part),count(DISTINCT cd_adm4)
FROM main.adm4 a4
LEFT JOIN main.adm3 a3 USING(cd_adm3,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
LEFT JOIN main.adm5 a5 USING(cd_adm4,cd_geounit)
WHERE  a4.cd_cat_part IS NULL
GROUP BY a4.type_part, equivalent
ORDER BY a4.type_part,equivalent--count(DISTINCT cd_adm4) DESC
;
*/
WITH a AS(
SELECT cd_adm4,CASE WHEN a4.cd_adm3 IS NULL THEN NULL WHEN a4.equi_adm3 IS NULL THEN false WHEN a4.equi_adm3=a3.cd_adm3 THEN true END equivalent ,a3.cd_cat_part cd_cat_part_sup,sovereign
FROM main.adm4 a4
LEFT JOIN main.adm3 a3 USING(cd_adm3,cd_geounit)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE a4.cd_cat_part IS NULL
)
UPDATE main.adm4 a4
SET cd_cat_part=
    CASE
        WHEN type_part IN ('Cell','Commune','Commune (same as level 3)','Municipality','National Park','Parish','Rural Commune','Sub-prefecture','Town','Union','Urban Commune','Urban Community','Village','Village development committee','Ward','Sovereign territories','Sovereign territory') AND cd_cat_part_sup<5 THEN 5
        WHEN type_part IN ('Cell','Commune','Commune (same as level 3)','Municipality','National Park','Parish','Rural Commune','Sub-prefecture','Town','Union','Urban Commune','Urban Community','Village','Village development committee','Ward','Sovereign territories','Sovereign territory') AND cd_cat_part_sup>=5 THEN 6
        WHEN type_part IS NULL AND cd_cat_part_sup>=5 THEN 6
        WHEN type_part IS NULL AND sovereign='MDG' THEN 5
        WHEN type_part IS NULL AND cd_cat_part_sup<5 THEN 5
        WHEN type_part IS NULL AND cd_cat_part_sup IS NULL THEN 5
        WHEN type_part IN ('Canton') THEN 4
        WHEN type_part IN ('Cadastral community','Quarter','Sous Colline','Sub-commune') THEN 6
    END
FROM a
WHERE a.cd_adm4=a4.cd_adm4;
/*
SELECT cd_adm4,cd_cat_part,adm4
FROM main.adm4
WHERE adm4 ~ '[Aa]rrondissement';
*/
UPDATE main.adm4
SET cd_cat_part=6
WHERE adm4 ~ '[Aa]rrondissement';













