---------------------------------------------------
-------------- ADM1 -------------------------------
---------------------------------------------------

CREATE TABLE main.adm1_names
(
    cd_name serial PRIMARY KEY,
    string text NOT NULL CHECK (string ~ '[A-Za-z]'),
    name_type text,
    cd_lang character(2) REFERENCES main.lang(cd_lang),
    cd_adm1 int REFERENCES main.adm1(cd_adm1),
    cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
    locale boolean,
    part boolean,
    UNIQUE (string, name_type, cd_lang, cd_geounit)
);
CREATE INDEX main_adm1_names_cd_adm1_fk_idx ON main.adm1_names(cd_adm1);
CREATE INDEX main_adm1_names_cd_geounit_fk_idx ON main.adm1_names(cd_geounit);

--- ne_name base
INSERT INTO main.adm1_names(string, name_type, cd_lang,cd_adm1,cd_geounit)
SELECT REGEXP_REPLACE(REGEXP_REPLACE(n.string,'^ +',''),' +$','') string,
  CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 2'
    WHEN (string ~ '^[A-Z][a-z]{2,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END name_type,
  cd_lang,cd_adm1,cd_geounit
FROM tmp.ne_adm1_name n
JOIN main.adm1 a1 USING (adm1_code)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE
   length(string)>1
ORDER BY cd_geounit,cd_adm1;

--- gadm names adds
INSERT INTO main.adm1_names(string, name_type, cd_lang,cd_adm1,cd_geounit)
WITH a AS(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(n.string,'^ +',''),' +$','') string,
  CASE
    WHEN n.string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 2'
    WHEN (n.string ~ '^[A-Z][a-z]{2,5}\.$' OR n.string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END name_type,
  n.cd_lang,a1.cd_adm1,cd_geounit
FROM tmp.gadm_adm1_name n
JOIN main.adm1 a1 USING (cd_adm1)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE
   length(string)>1
)
SELECT a.*
FROM a
LEFT JOIN main.adm1_names n2 ON
    a.string=n2.string
    AND a.cd_adm1=n2.cd_adm1
    AND ((n2.cd_lang IS NULL AND a.cd_lang IS NULL) OR n2.cd_lang=a.cd_lang)
    AND ((n2.name_type IS NULL AND a.name_type IS NULL) OR n2.name_type=a.name_type)
WHERE n2.cd_name IS NULL
;


---------------------------------------------------
-------------- ADM2 -------------------------------
---------------------------------------------------

CREATE TABLE main.adm2_names
(
    cd_name serial PRIMARY KEY,
    string text NOT NULL CHECK (string ~ '[A-Za-z]'),
    name_type text,
    cd_lang character(2) REFERENCES main.lang(cd_lang),
    cd_adm2 int REFERENCES main.adm2(cd_adm2),
    cd_adm1 int REFERENCES main.adm1(cd_adm1),
    locale boolean,
    part boolean,
    UNIQUE (string, name_type, cd_lang, cd_adm1)
);
CREATE INDEX main_adm2_names_cd_adm1_fk_idx ON main.adm2_names(cd_adm1);
CREATE INDEX main_adm2_names_cd_adm2_fk_idx ON main.adm2_names(cd_adm2);

--- ne_name base (naturalearth adm1 -> our adm2)
INSERT INTO main.adm2_names(string, name_type, cd_lang,cd_adm2,cd_adm1)
SELECT REGEXP_REPLACE(REGEXP_REPLACE(n.string,'^ +',''),' +$','') string,
  /*CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 2'
    WHEN (string ~ '^[A-Z][a-z]{2,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END*/ name_type,
  cd_lang,cd_adm2,cd_adm1
FROM tmp.ne_adm1_name n
JOIN main.adm2 a2 USING (adm1_code)
WHERE
   length(string)>1
ORDER BY cd_geounit,cd_adm1;

--- ne_name base (naturalearth adm2 -> our adm2)
INSERT INTO main.adm2_names(string, name_type, cd_lang,cd_adm2,cd_adm1)
SELECT REGEXP_REPLACE(REGEXP_REPLACE(n.string,'^ +',''),' +$','') string,
  /*CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 2'
    WHEN (string ~ '^[A-Z][a-z]{2,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END*/ name_type,
  cd_lang,cd_adm2,cd_adm1
FROM tmp.ne_adm2_name n
JOIN main.adm2 a2 USING (adm2_code)
WHERE
   length(string)>1
ORDER BY cd_geounit,cd_adm1;
--- gadm names adds
INSERT INTO main.adm2_names(string, name_type, cd_lang,cd_adm2,cd_adm1)
WITH a AS(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(n.string,'^ +',''),' +$','') string,
  CASE
    WHEN n.string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 2'
    WHEN (n.string ~ '^[A-Z][a-z]{2,5}\.$' OR n.string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END name_type,
  n.cd_lang,a1.cd_adm2,cd_adm1
FROM tmp.gadm_adm2_name n
JOIN main.adm2 a1 USING (cd_adm2)
LEFT JOIN main.adm0_geounit a0 USING (cd_geounit)
)
SELECT a.*
FROM a
LEFT JOIN main.adm2_names n2 ON
    a.string=n2.string
    AND a.cd_adm2=n2.cd_adm2
    AND ((n2.cd_lang IS NULL AND a.cd_lang IS NULL) OR n2.cd_lang=a.cd_lang)
    AND ((n2.name_type IS NULL AND a.name_type IS NULL) OR n2.name_type=a.name_type)
WHERE n2.cd_name IS NULL
   AND length(a.string)>1
;


---------------------------------------------------
-------------- ADM3 -------------------------------
---------------------------------------------------

CREATE TABLE main.adm3_names
(
    cd_name serial PRIMARY KEY,
    string text NOT NULL CHECK (string ~ '[A-Za-z]'),
    name_type text,
    cd_lang character(3) REFERENCES main.lang(cd_lang),
    cd_adm3 int REFERENCES main.adm3(cd_adm3),
    /*cd_adm2 int REFERENCES main.adm2(cd_adm2),
    cd_adm1 int REFERENCES main.adm1(cd_adm1),*/
    locale boolean,
    part boolean/*,
    UNIQUE (string, name_type, cd_lang, cd_adm2)*/ --cant set a unique string even in cd_adm1/cd_adm2: a lot of repetitions!
);
/*CREATE INDEX main_adm3_names_cd_adm1_fk_idx ON main.adm3_names(cd_adm1);
CREATE INDEX main_adm3_names_cd_adm2_fk_idx ON main.adm3_names(cd_adm2);*/
CREATE INDEX main_adm3_names_cd_adm3_fk_idx ON main.adm3_names(cd_adm3);

--- gadm names
INSERT INTO main.adm3_names(string, name_type, cd_lang,cd_adm3)
WITH a AS(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(name_3,'^ +',''),' +$','') string, 'GADM' orig, NULL name_type, 'en' cd_lang, gid_3
FROM gadm.gadm_adm3
UNION
SELECT REGEXP_REPLACE(REGEXP_REPLACE(UNNEST(varname_3),'^ +',''),' +$',''), 'GADM', NULL, NULL, gid_3
FROM gadm.gadm_adm3
),b AS(
SELECT DISTINCT string, name_type, cd_lang, cd_adm3
FROM a
JOIN main.adm3 USING (gid_3)
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
)
SELECT REGEXP_REPLACE(REGEXP_REPLACE(b.string,'^ +',''),' +$','') string,
  /*CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 3'
    WHEN (string ~ '^[A-Z][a-z]{3,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END*/ name_type,
  cd_lang,cd_adm3/*,cd_adm2,cd_adm1*/
FROM b
JOIN main.adm3 a3 USING (cd_adm3)
WHERE
   length(string)>1 AND string !~ '^Poblaci[óo]n$'
ORDER BY cd_geounit,cd_adm3
;

---------------------------------------------------
-------------- ADM4 -------------------------------
---------------------------------------------------

CREATE TABLE main.adm4_names
(
    cd_name serial PRIMARY KEY,
    string text NOT NULL CHECK (string ~ '[A-Za-z]'),
    name_type text,
    cd_lang character(4) REFERENCES main.lang(cd_lang),
    cd_adm4 int REFERENCES main.adm4(cd_adm4),
    /*cd_adm2 int REFERENCES main.adm2(cd_adm2),
    cd_adm1 int REFERENCES main.adm1(cd_adm1),*/
    locale boolean,
    part boolean/*,
    UNIQUE (string, name_type, cd_lang, cd_adm2)*/ --cant set a unique string even in cd_adm1/cd_adm2/cd_adm3: a lot of repetitions!
);
/*CREATE INDEX main_adm4_names_cd_adm1_fk_idx ON main.adm4_names(cd_adm1);
CREATE INDEX main_adm4_names_cd_adm2_fk_idx ON main.adm4_names(cd_adm2);*/
CREATE INDEX main_adm4_names_cd_adm4_fk_idx ON main.adm4_names(cd_adm4);

--- gadm names
INSERT INTO main.adm4_names(string, name_type, cd_lang,cd_adm4)
WITH a AS(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(name_4,'^ +',''),' +$','') string, 'GADM' orig, NULL name_type, 'en' cd_lang, gid_4
FROM gadm.gadm_adm4
UNION
SELECT REGEXP_REPLACE(REGEXP_REPLACE(UNNEST(varname_4),'^ +',''),' +$',''), 'GADM', NULL, NULL, gid_4
FROM gadm.gadm_adm4
),b AS(
SELECT DISTINCT string, name_type, cd_lang, cd_adm4
FROM a
JOIN main.adm4 USING (gid_4)
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
)--, c AS(
SELECT b.string,
  /*CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 4'
    WHEN (string ~ '^[A-Z][a-z]{4,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END*/ name_type,
  cd_lang,cd_adm4/*,cd_adm3,cd_adm2,cd_adm1*/
FROM b
JOIN main.adm4 a4 USING (cd_adm4)
WHERE
   length(string)>1
ORDER BY cd_geounit,cd_adm4
/*)
SELECT string,name_type, cd_lang,ARRAY_AGG(DISTINCT cd_adm4),cd_adm3,cd_adm2,cd_adm1
FROM c
GROUP BY string,name_type, cd_lang,cd_adm3,cd_adm2,cd_adm1
ORDER BY COUNT(DISTINCT cd_adm4) DESC
*/
;
---------------------------------------------------
-------------- ADM5 -------------------------------
---------------------------------------------------

CREATE TABLE main.adm5_names
(
    cd_name serial PRIMARY KEY,
    string text NOT NULL CHECK (string ~ '[A-Za-z]'),
    name_type text,
    cd_lang character(5) REFERENCES main.lang(cd_lang),
    cd_adm5 int REFERENCES main.adm5(cd_adm5),
    cd_adm4 int REFERENCES main.adm4(cd_adm4),
    locale boolean,
    part boolean,
    UNIQUE (string, name_type, cd_lang, cd_adm4)
);
/*CREATE INDEX main_adm5_names_cd_adm1_fk_idx ON main.adm5_names(cd_adm1);
CREATE INDEX main_adm5_names_cd_adm2_fk_idx ON main.adm5_names(cd_adm2);*/
CREATE INDEX main_adm5_names_cd_adm5_fk_idx ON main.adm5_names(cd_adm5);

--- gadm names
INSERT INTO main.adm5_names(string, name_type, cd_lang,cd_adm5,cd_adm4)
WITH a AS(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(name_5,'^ +',''),' +$','') string, 'GADM' orig, NULL name_type, 'en' cd_lang, gid_5
FROM gadm.gadm_adm5
),b AS(
SELECT DISTINCT string, name_type, cd_lang, cd_adm5
FROM a
JOIN main.adm5 USING (gid_5)
WHERE string IS NOT NULL AND string ~ '[A-Za-z]' AND string <> ''
)--, c AS(
SELECT b.string,
  /*CASE
    WHEN string ~ '^[A-Z][A-Z]$' AND sovereign='USA' THEN 'state abbv 5'
    WHEN (string ~ '^[A-Z][a-z]{5,5}\.$' OR string ~ '^[A-Z]\.[A-Z][a-z]?\.$') AND sovereign='USA' THEN 'state abbv long'
    ELSE name_type
  END*/ name_type,
  cd_lang,cd_adm5/**/,cd_adm4/**/
FROM b
JOIN main.adm5 a5 USING (cd_adm5)
WHERE
   length(string)>1
ORDER BY cd_geounit,cd_adm5
/*)
SELECT string,name_type, cd_lang,ARRAY_AGG(DISTINCT cd_adm5),cd_adm4
FROM c
GROUP BY string,name_type, cd_lang,cd_adm4
ORDER BY COUNT(DISTINCT cd_adm5) DESC
*/
;



-----------------------------------------------------------
-------- Checking on missing names ------------------------
-----------------------------------------------------------

-- adm1
INSERT INTO main.adm1_names(string,cd_lang,cd_adm1,cd_geounit)
WITH a AS(
SELECT cd_adm1, adm1, modified_gid_1, modification_gid_1, adm1_code, gid_1, count(DISTINCT cd_name) nb_name
FROM main.adm1
LEFT JOIN main.adm1_names USING (cd_adm1)
GROUP BY cd_adm1, adm1, modified_gid_1, modification_gid_1
HAVING count(DISTINCT cd_name) = 0
)
SELECT adm1 string, 'en' cd_lang, cd_adm1, cd_geounit
FROM a
LEFT JOIN main.adm1 USING (adm1,cd_adm1)
RETURNING *;


--adm2
INSERT INTO main.adm2_names(string,cd_lang,cd_adm2,cd_adm1)
WITH a AS(
SELECT cd_adm2, adm2, modified_gid_2, modification_gid_2, adm1_code, adm2_code, gid_2, count(DISTINCT cd_name) nb_name
FROM main.adm2
LEFT JOIN main.adm2_names USING (cd_adm2)
GROUP BY cd_adm2, adm2, modified_gid_2, modification_gid_2
HAVING count(DISTINCT cd_name) = 0
)
SELECT adm2 string, 'en' cd_lang, cd_adm2, cd_adm1
FROM a
LEFT JOIN main.adm2 USING (adm2,cd_adm2)
WHERE adm2 ~ '[A-Za-z]' AND length(adm2)>1
RETURNING *;

--adm3
INSERT INTO main.adm3_names(string,cd_lang,cd_adm3)
WITH a AS(
SELECT cd_adm3, adm3, modified_gid_3, modification_gid_3, gid_3, count(DISTINCT cd_name) nb_name
FROM main.adm3
LEFT JOIN main.adm3_names USING (cd_adm3)
GROUP BY cd_adm3, adm3, modified_gid_3, modification_gid_3
HAVING count(DISTINCT cd_name) = 0
)
SELECT adm3 string, 'en' cd_lang, cd_adm3
FROM a
LEFT JOIN main.adm3 USING (adm3,cd_adm3)
WHERE adm3 ~ '[A-Za-z]' AND length(adm3)>1 AND NOT adm3 ~ '^Poblaci[oó]n$'
RETURNING *;



--adm4
INSERT INTO main.adm4_names(string,cd_lang,cd_adm4)
WITH a AS(
SELECT cd_adm4, adm4, modified_gid_4, modification_gid_4, gid_4, count(DISTINCT cd_name) nb_name
FROM main.adm4
LEFT JOIN main.adm4_names USING (cd_adm4)
GROUP BY cd_adm4, adm4, modified_gid_4, modification_gid_4
HAVING count(DISTINCT cd_name) = 0
)
SELECT adm4 string, 'en' cd_lang, cd_adm4
FROM a
LEFT JOIN main.adm4 USING (adm4,cd_adm4)
WHERE adm4 ~ '[A-Za-z]' AND length(adm4)>1
RETURNING *;


--adm5
INSERT INTO main.adm5_names(string,cd_lang,cd_adm5,cd_adm4)
WITH a AS(
SELECT cd_adm5, adm5, modified_gid_5, modification_gid_5, gid_5, count(DISTINCT cd_name) nb_name
FROM main.adm5
LEFT JOIN main.adm5_names USING (cd_adm5)
GROUP BY cd_adm5, adm5, modified_gid_5, modification_gid_5
HAVING count(DISTINCT cd_name) = 0
)
SELECT adm5 string, 'en' cd_lang, cd_adm5,cd_adm4
FROM a
LEFT JOIN main.adm5 USING (adm5,cd_adm5)
WHERE adm5 ~ '[A-Za-z]' AND length(adm5)>1
RETURNING *;

