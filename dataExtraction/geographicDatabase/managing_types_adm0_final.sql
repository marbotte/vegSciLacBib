/*
SELECT sovereign,cd_geounit,geounit
FROM main.adm0_geounit
WHERE main_territ
ORDER BY sovereign;
*/
UPDATE main.adm0_geounit
SET cd_cat_part=NULL;

UPDATE main.adm0_geounit
SET cd_cat_part=0
WHERE main_territ;

UPDATE main.adm0_geounit
SET cd_cat_part=1
WHERE part_multi;

/*
SELECT sovereign,a0.cd_geounit,geounit, ARRAY_AGG(DISTINCT a1_in.cd_cat_part),a0.cd_cat_part, COALESCE(a1.cd_cat_part,a2.cd_cat_part,a3.cd_cat_part,a4.cd_cat_part,a5.cd_cat_part) equi_cd_cat_part,main_territ,dependency,part_multi
FROM main.adm0_geounit a0
LEFT JOIN main.adm1 a1_in USING (cd_geounit)
LEFT JOIN main.adm1 a1 ON a0.equi_adm1=a1.cd_adm1
LEFT JOIN main.adm2 a2 ON a0.equi_adm2=a2.cd_adm2
LEFT JOIN main.adm3 a3 ON a0.equi_adm3=a3.cd_adm3
LEFT JOIN main.adm4 a4 ON a0.equi_adm4=a4.cd_adm4
LEFT JOIN main.adm5 a5 ON a0.equi_adm5=a5.cd_adm5
GROUP BY sovereign,a0.cd_geounit,geounit,COALESCE(a1.cd_cat_part,a2.cd_cat_part,a3.cd_cat_part,a4.cd_cat_part,a5.cd_cat_part)
ORDER BY sovereign,cd_geounit;
*/
WITH a AS(
SELECT a0.cd_geounit, COALESCE(a1.cd_cat_part,a2.cd_cat_part,a3.cd_cat_part,a4.cd_cat_part,a5.cd_cat_part) equi_cd_cat
FROM main.adm0_geounit a0
LEFT JOIN main.adm1 a1 ON a0.equi_adm1=a1.cd_adm1
LEFT JOIN main.adm2 a2 ON a0.equi_adm2=a2.cd_adm2
LEFT JOIN main.adm3 a3 ON a0.equi_adm3=a3.cd_adm3
LEFT JOIN main.adm4 a4 ON a0.equi_adm4=a4.cd_adm4
LEFT JOIN main.adm5 a5 ON a0.equi_adm5=a5.cd_adm5
WHERE COALESCE(a1.cd_cat_part,a2.cd_cat_part,a3.cd_cat_part,a4.cd_cat_part,a5.cd_cat_part) IS NOT NULL
)
UPDATE main.adm0_geounit a0
SET cd_cat_part=equi_cd_cat
FROM a
WHERE a.cd_geounit=a0.cd_geounit;

UPDATE main.adm0_geounit
SET cd_cat_part=1
WHERE sovereign IS NULL;

UPDATE main.adm0_geounit
SET cd_cat_part=2
WHERE dependency;
/*
SELECT sovereign,ARRAY_AGG(cd_cat_part)
FROM main.adm0_geounit
GROUP BY sovereign;
*/
UPDATE main.adm0_geounit
SET cd_cat_part=
CASE
    WHEN cd_geounit IN ('GRL','ALD','FLK','GGG','GIB','IMN','JEY','IRK','ABW','CUW','SXM','TKL','SOP','SRV','TZZ','YES','ZAI') THEN 1
    WHEN cd_geounit IN ('CCK','CXR','CHS','PFA','USG','BSI','GUF','GGH','IOD','IOT','SGG','SGX','GNK','INA','JPH','JPB','JPI','JPS','JPV','JPY','JPO','KAB','KNX','KOD','KNZ','SYU') THEN 2
    WHEN cd_geounit IN ('GLP','MTQ','MYT','ITI','REU') THEN 3
    WHEN cd_geounit IN ('GOI') THEN 4
END
WHERE cd_cat_part IS NULL
;

ALTER TABLE main.adm0_geounit ADD CONSTRAINT main_adm0_geounit_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm0_geounit_categ_part_fkey_idx ON main.adm0_geounit(cd_cat_part);

ALTER TABLE main.adm1 ADD CONSTRAINT main_adm1_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm1_categ_part_fkey_idx ON main.adm1(cd_cat_part);

ALTER TABLE main.adm2 ADD CONSTRAINT main_adm2_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm2_categ_part_fkey_idx ON main.adm2(cd_cat_part);

ALTER TABLE main.adm3 ADD CONSTRAINT main_adm3_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm3_categ_part_fkey_idx ON main.adm3(cd_cat_part);

ALTER TABLE main.adm4 ADD CONSTRAINT main_adm4_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm4_categ_part_fkey_idx ON main.adm4(cd_cat_part);

ALTER TABLE main.adm5 ADD CONSTRAINT main_adm5_categ_part_fkey FOREIGN KEY (cd_cat_part) REFERENCES main.categ_part(cd_cat_part);
CREATE INDEX main_adm5_categ_part_fkey_idx ON main.adm5(cd_cat_part);
