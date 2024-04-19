DROP TABLE IF EXISTS geonames.cities;


----------------------------------------------------------------------
----------------------------------------------------------------------
------------- INDEXES AND KEYS ---------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------


ALTER TABLE geonames.all_countries DROP CONSTRAINT  IF EXISTS geonames_all_countries_geonameid_pk CASCADE;
ALTER TABLE geonames.all_countries ADD CONSTRAINT geonames_all_countries_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.all_countries DROP COLUMN IF EXISTS alternatenames CASCADE;
ALTER TABLE geonames.all_countries DROP COLUMN IF EXISTS geom;
SELECT AddGeometryColumn('geonames','all_countries','geom',4326,'POINT',2);
UPDATE geonames.all_countries
SET geom=ST_SetSRID(ST_MakePoint(longitude,latitude),4326);
CREATE INDEX geonames_all_countries_geom_idx ON geonames.all_countries USING GIST(geom);

ALTER TABLE geonames.cities500 DROP COLUMN IF EXISTS alternatenames CASCADE;
ALTER TABLE geonames.cities500 DROP COLUMN IF EXISTS geom;

DELETE FROM geonames.feature_codes WHERE feature_code IS NULL;
ALTER TABLE geonames.feature_codes DROP CONSTRAINT  IF EXISTS geonames_feature_code_feature_code_pk CASCADE;
ALTER TABLE geonames.feature_codes ADD CONSTRAINT geonames_feature_codes_feature_code_pk PRIMARY KEY (feature_code);


ALTER TABLE geonames.all_countries DROP CONSTRAINT  IF EXISTS geonames_all_countries_feature_code_fk;
ALTER TABLE geonames.all_countries ADD CONSTRAINT  geonames_all_countries_feature_code_fk FOREIGN KEY (feature_code) REFERENCES geonames.feature_codes(feature_code);
CREATE INDEX geonames_all_countries_feature_code_fk_idx ON geonames.all_countries(feature_code);

ALTER TABLE geonames.admin1_codes_asc_ii DROP CONSTRAINT  IF EXISTS geonames_admin1_codes_asc_ii_geonameid_pk;
ALTER TABLE geonames.admin1_codes_asc_ii ADD CONSTRAINT geonames_admin1_codes_asc_ii_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.admin1_codes_asc_ii DROP CONSTRAINT  IF EXISTS geonames_admin1_codes_asc_ii_geonameid_fk;
ALTER TABLE geonames.admin1_codes_asc_ii ADD CONSTRAINT geonames_admin1_codes_asc_ii_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);


ALTER TABLE geonames.admin1_codes_asc_ii DROP CONSTRAINT  IF EXISTS geonames_admin1_codes_asc_ii_geonameid_pk;
ALTER TABLE geonames.admin1_codes_asc_ii ADD CONSTRAINT geonames_admin1_codes_asc_ii_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.admin1_codes_asc_ii DROP CONSTRAINT  IF EXISTS geonames_admin1_codes_asc_ii_geonameid_fk;
ALTER TABLE geonames.admin1_codes_asc_ii ADD CONSTRAINT geonames_admin1_codes_asc_ii_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);

ALTER TABLE geonames.admin2_code DROP CONSTRAINT  IF EXISTS geonames_admin2_code_geonameid_pk;
ALTER TABLE geonames.admin2_code ADD CONSTRAINT geonames_admin2_code_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.admin2_code DROP CONSTRAINT  IF EXISTS geonames_admin2_code_geonameid_fk;
ALTER TABLE geonames.admin2_code ADD CONSTRAINT geonames_admin2_code_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);

ALTER TABLE geonames.admin_code5 DROP CONSTRAINT  IF EXISTS geonames_admin_code5_geonameid_pk;
ALTER TABLE geonames.admin_code5 ADD CONSTRAINT geonames_admin_code5_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.admin_code5 DROP CONSTRAINT  IF EXISTS geonames_admin_code5_geonameid_fk;
ALTER TABLE geonames.admin_code5 ADD CONSTRAINT geonames_admin_code5_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);

ALTER TABLE geonames.cities500 DROP CONSTRAINT  IF EXISTS geonames_cities500_geonameid_pk;
ALTER TABLE geonames.cities500 ADD CONSTRAINT geonames_cities500_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.cities500 DROP CONSTRAINT  IF EXISTS geonames_cities500_geonameid_fk;
ALTER TABLE geonames.cities500 ADD CONSTRAINT geonames_cities500_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);

ALTER TABLE geonames.country_info DROP CONSTRAINT  IF EXISTS geonames_country_info_geonameid_pk;
ALTER TABLE geonames.country_info ADD CONSTRAINT geonames_country_info_geonameid_pk PRIMARY KEY (geonameid);
ALTER TABLE geonames.country_info DROP CONSTRAINT  IF EXISTS geonames_country_info_geonameid_fk;
ALTER TABLE geonames.country_info ADD CONSTRAINT geonames_country_info_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);

ALTER TABLE geonames.alternate_names DROP CONSTRAINT  IF EXISTS geonames_alternate_names_geonameid_fk;
ALTER TABLE geonames.alternate_names ADD CONSTRAINT geonames_alternate_names_geonameid_fk FOREIGN KEY (geonameid) REFERENCES geonames.all_countries(geonameid);
DROP INDEX IF EXISTS geonames_alternate_names_geonameid_fk_idx;
CREATE INDEX geonames_alternate_names_geonameid_fk_idx ON geonames.alternate_names(geonameid);

WITH a AS(
SELECT child_id
FROM geonames.hierarchy h
LEFT JOIN geonames.all_countries ac ON h.child_id=ac.geonameid
WHERE ac.geonameid IS NULL
)
DELETE FROM geonames.hierarchy
WHERE child_id IN (SELECT child_id FROM a);

ALTER TABLE geonames.hierarchy DROP CONSTRAINT  IF EXISTS geonames_hierarchy_parent_id_geonameid_fk;
ALTER TABLE geonames.hierarchy ADD CONSTRAINT geonames_hierarchy_geonameid_fk FOREIGN KEY (parent_id) REFERENCES geonames.all_countries(geonameid);
DROP INDEX IF EXISTS geonames_hierarchy_parent_id_geonameid_fk_idx;
CREATE INDEX geonames_hierarchyparent_id_geonameid_fk_idx ON geonames.hierarchy(parent_id);
ALTER TABLE geonames.hierarchy DROP CONSTRAINT  IF EXISTS geonames_hierarchy_child_id_geonameid_fk;
ALTER TABLE geonames.hierarchy ADD CONSTRAINT geonames_hierarchy_child_id_geonameid_fk  FOREIGN KEY (child_id) REFERENCES geonames.all_countries(geonameid);
DROP INDEX IF EXISTS geonames_hierarchy_child_id_geonameid_fk_idx;
CREATE INDEX geonames_hierarchy_child_id_geonameid_fk_idx ON geonames.hierarchy(child_id);


ALTER TABLE geonames.country_info DROP CONSTRAINT IF EXISTS country_info_iso_unique ;
ALTER TABLE geonames.country_info ADD CONSTRAINT country_info_iso_unique UNIQUE (iso);

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--------------------- LANGUAGES -------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

/*
SELECT count(*)
FROM geonames.alternate_names gan
JOIN geonames.iso_languagecodes gil ON gil.iso_639_1=gan.isolanguage OR gil.iso_639_2=gan.isolanguage OR gil.iso_639_3=gan.isolanguage
*/

ALTER TABLE geonames.iso_languagecodes ADD COLUMN IF NOT EXISTS cd_lang serial PRIMARY KEY;
ALTER TABLE geonames.alternate_names ADD COLUMN IF NOT EXISTS cd_lang int REFERENCES geonames.iso_languagecodes(cd_lang);

ALTER TABLE geonames.alternate_names DROP CONSTRAINT  IF EXISTS geonames_alternate_names_pk;
ALTER TABLE geonames.alternate_names ADD CONSTRAINT geonames_alternate_names_pk PRIMARY KEY (alternate_name_id);

WITH a AS(
SELECT alternate_name_id,gil.cd_lang
FROM geonames.alternate_names gan
JOIN geonames.iso_languagecodes gil ON gil.iso_639_1=gan.isolanguage
)
UPDATE geonames.alternate_names an
SET cd_lang=a.cd_lang
FROM a
WHERE an.alternate_name_id=a.alternate_name_id;

WITH a AS(
SELECT alternate_name_id,gil.cd_lang
FROM geonames.alternate_names gan
JOIN geonames.iso_languagecodes gil ON gil.iso_639_2=gan.isolanguage
WHERE gan.cd_lang IS NULL
)
UPDATE geonames.alternate_names an
SET cd_lang=a.cd_lang
FROM a
WHERE an.alternate_name_id=a.alternate_name_id;

WITH a AS(
SELECT alternate_name_id,gil.cd_lang
FROM geonames.alternate_names gan
JOIN geonames.iso_languagecodes gil ON gil.iso_639_3=gan.isolanguage
WHERE gan.cd_lang IS NULL
)
UPDATE geonames.alternate_names an
SET cd_lang=a.cd_lang
FROM a
WHERE an.alternate_name_id=a.alternate_name_id;

ALTER TABLE geonames.alternate_names ADD COLUMN IF NOT EXISTS lang_variant text;

WITH a AS(
SELECT alternate_name_id,isolanguage
FROM geonames.alternate_names gan
WHERE gan.cd_lang IS NULL AND isolanguage IS NOT NULL AND NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','fr_1793','abbr','unlc','lauc','nuts','geoid','uicn','tcid','phon') AND isolanguage ~ '^[a-z]{2,3}-[A-z]{1,10}$'
),b AS(
SELECT alternate_name_id,isolanguage,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\1') lang_part,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\2') lang_variant
FROM a
), c AS(
SELECT alternate_name_id,isolanguage,cd_lang,lang_variant
FROM b
JOIN geonames.iso_languagecodes gil ON gil.iso_639_3=b.lang_part
)
UPDATE geonames.alternate_names an
SET cd_lang=c.cd_lang, lang_variant=c.lang_variant
FROM c
WHERE an.alternate_name_id=c.alternate_name_id;

WITH a AS(
SELECT alternate_name_id,isolanguage
FROM geonames.alternate_names gan
WHERE gan.cd_lang IS NULL AND isolanguage IS NOT NULL AND NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','fr_1793','abbr','unlc','lauc','nuts','geoid','uicn','tcid','phon') AND isolanguage ~ '^[a-z]{2,3}-[A-z]{1,10}$'
),b AS(
SELECT alternate_name_id,isolanguage,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\1') lang_part,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\2') lang_variant
FROM a
), c AS(
SELECT alternate_name_id,isolanguage,cd_lang,lang_variant
FROM b
JOIN geonames.iso_languagecodes gil ON gil.iso_639_2=b.lang_part
)
UPDATE geonames.alternate_names an
SET cd_lang=c.cd_lang, lang_variant=c.lang_variant
FROM c
WHERE an.alternate_name_id=c.alternate_name_id;

WITH a AS(
SELECT alternate_name_id,isolanguage
FROM geonames.alternate_names gan
WHERE gan.cd_lang IS NULL AND isolanguage IS NOT NULL AND NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','fr_1793','abbr','unlc','lauc','nuts','geoid','uicn','tcid','phon') AND isolanguage ~ '^[a-z]{2,3}-[A-z]{1,10}$'
),b AS(
SELECT alternate_name_id,isolanguage,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\1') lang_part,REGEXP_REPLACE(isolanguage,'^([a-z]{2,3})-([A-z]{1,10})$','\2') lang_variant
FROM a
), c AS(
SELECT alternate_name_id,isolanguage,cd_lang,lang_variant
FROM b
JOIN geonames.iso_languagecodes gil ON gil.iso_639_1=b.lang_part
)
UPDATE geonames.alternate_names an
SET cd_lang=c.cd_lang, lang_variant=c.lang_variant
FROM c
WHERE an.alternate_name_id=c.alternate_name_id;

CREATE INDEX IF NOT EXISTS alternate_name_lang_fk_idx ON geonames.alternate_names(cd_lang);

/*
-- There are things to do with languages and alphabets, but that is not as clean as expected:

SELECT gil.cd_lang,language, alternate_name ~ '[A-z]' latin,count(*)
FROM geonames.alternate_names
LEFT JOIN geonames.iso_languagecodes gil USING (cd_lang)
GROUP BY gil.cd_lang, language, alternate_name ~ '[A-z]'
ORDER BY language
;


SELECT count(*)
FROM geonames.alternate_names
WHERE alternate_name ~ '[A-z]';

SELECT count(*)
FROM geonames.alternate_names
WHERE NOT alternate_name ~ '[A-z]';
*/

-------------------------------------------------------------------------
-------------------------------------------------------------------------
---------RELATION GEONAMES ADM -> GADM ADM-------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
ALTER TABLE geonames.all_countries DROP COLUMN IF EXISTS equi_gadm_ref ;
ALTER TABLE geonames.all_countries ADD COLUMN equi_gadm_ref t_ref;

DROP TABLE IF EXISTS geonames.country_iso_to_sovereign;
CREATE TABLE geonames.country_iso_to_sovereign
(
    iso char(2) REFERENCES geonames.country_info(iso),
    country_geonames text,
    cd_sov CHAR(3) REFERENCES sovereign(cd_sov),
    sovereign text,
    UNIQUE (iso,cd_sov)
);

INSERT INTO geonames.country_iso_to_sovereign
SELECT DISTINCT iso, country,cd_sov, sovereign
FROM geonames.country_info
JOIN geonames.all_countries ac USING(geonameid)
JOIN geonames.alternate_names USING(geonameid)
JOIN geonames.feature_codes fc USING (feature_code)
JOIN sovereign_names ON alternate_name=string OR country=string OR ac.name=string OR ac.asciiname=string
JOIN sovereign USING (cd_sov)
;

INSERT INTO geonames.country_iso_to_sovereign
SELECT DISTINCT  iso, country,cd_sov, s.sovereign
FROM geonames.country_info
JOIN geonames.all_countries ac USING(geonameid)
JOIN geonames.alternate_names USING(geonameid)
JOIN geonames.feature_codes fc USING (feature_code)
JOIN main.adm0_names ON alternate_name=string OR country=string OR ac.name=string OR ac.asciiname=string
JOIN main.adm0_geounit a0 USING (cd_geounit)
JOIN sovereign s ON COALESCE(a0.sovereign,a0.cd_geounit) = cd_sov
ON CONFLICT (iso,cd_sov) DO NOTHING
;

---- CHECK THAT
/*
SELECT *
FROM geonames.country_iso_to_sovereign
WHERE country_geonames<>sovereign
ORDER BY iso
;
*/
--TODO correct congo, Saint Martin / Sint Marteen  (suppress the wrong cases)


DELETE FROM geonames.country_iso_to_sovereign
WHERE (iso='CD' AND cd_sov='COG')
    OR (iso='MF' AND cd_sov='NLD')
    OR (iso='SC' AND cd_sov='FRA')
    OR (iso='SX' AND cd_sov='FRA')
    OR (iso='ML' AND cd_sov='SDN')
    OR (iso='GY' AND cd_sov='FRA')
    OR iso IS NULL
    ;


/*
SELECT iso, count(*),ARRAY_AGG(country_geonames), ARRAY_AGG(cd_sov),ARRAY_AGG(sovereign)
FROM geonames.country_iso_to_sovereign
GROUP BY iso
HAVING count(*)>1;

WITH a AS(
SELECT cd_sov, count(*),ARRAY_AGG(country_geonames), ARRAY_AGG(iso),ARRAY_AGG(sovereign)
FROM geonames.country_iso_to_sovereign
GROUP BY cd_sov
HAVING count(*)>1
)
SELECT cits.*
FROM a
LEFT JOIN geonames.country_iso_to_sovereign cits USING (cd_sov)
ORDER BY cd_sov
;


SELECT s.cd_sov,s.sovereign
FROM sovereign s
LEFT JOIN geonames.country_iso_to_sovereign cits USING(cd_sov)
WHERE cits.cd_sov IS NULL;


SELECT iso,country
FROM geonames.country_info
LEFT JOIN geonames.country_iso_to_sovereign cits USING(iso)
WHERE cits.iso IS NULL;
*/
INSERT INTO geonames.country_iso_to_sovereign
VALUES  ('AQ','Antartica','ATP','Peter I I.'),
    ('AQ','Antartica','ATS','S. Orkney Is'),
    ('UM','','BJN',''),
    ('TD','','BRT',''),
    ('SO','','SOL',''),
    ('VN','','PGA',''),
    ('CY','','CNM',''),
    ('TR','','CYN',''),
    ('IN','','KAS',''),
    ('UM','','SCR',''),
    ('UM','','SER',''),
    ('CL','','SPI',''),
    ('BR','','BRI',''),
    ('GS','','GBR',''),
    ('PS','','ISR',''),
    ('AN','','NLD','')
;
UPDATE geonames.country_iso_to_sovereign cits
SET country_geonames=ci.country
FROM geonames.country_info ci
WHERE cits.country_geonames='' AND cits.iso=ci.iso;
UPDATE geonames.country_iso_to_sovereign cits
SET sovereign=s.sovereign
FROM sovereign s
WHERE cits.sovereign='' AND cits.cd_sov=s.cd_sov;

--- Simple correspondence countries
WITH sov_nb AS(
SELECT cd_sov,count(*) nb_corres
FROM geonames.country_iso_to_sovereign
GROUP BY cd_sov
), iso_nb AS(
SELECT iso,count(*) nb_corres
FROM geonames.country_iso_to_sovereign
GROUP BY iso
), ok AS(
SELECT cits.iso,(-1,0,cd_sov)::t_ref equi_gadm_ref
FROM geonames.country_iso_to_sovereign cits
LEFT JOIN sov_nb USING (cd_sov)
LEFT JOIN iso_nb USING (iso)
WHERE sov_nb.nb_corres=1 AND iso_nb.nb_corres=1
), a AS(
SELECT geonameid,equi_gadm_ref
FROM ok
JOIN geonames.country_info USING (iso)
)
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.equi_gadm_ref
FROM a
WHERE a.geonameid=ac.geonameid
;
UPDATE geonames.all_countries
SET equi_gadm_ref=(-1,0,'GBR')
WHERE name='United Kingdom of Great Britain and Northern Ireland' AND feature_code='PCLI';
UPDATE geonames.all_countries
SET equi_gadm_ref=(-1,0,'NZL')
WHERE name='New Zealand' AND feature_code='PCLI';
UPDATE geonames.all_countries
SET equi_gadm_ref=(0,0,'PYF')
WHERE name='French Polynesia' AND feature_code='PCLD';
UPDATE geonames.all_countries
SET equi_gadm_ref=(0,0,'FSA')
WHERE name='French Southern and Antarctic Lands' AND feature_code='PCLIX';
UPDATE geonames.all_countries
SET equi_gadm_ref=(0,0,'TKL')
WHERE name='Tokelau' AND feature_code='PCLD';


DROP TABLE IF EXISTS geonames_adm_string;
CREATE TEMPORARY TABLE geonames_adm_string
(
    geonameid integer,
    string text,
    cd_geounit CHAR(3),
    UNIQUE(geonameid,string,cd_geounit)
);
DROP INDEX IF EXISTS geonames_adm_string_btree_idx;
DROP INDEX IF EXISTS geonames_adm_string_geonameid_btree_idx;
DROP INDEX IF EXISTS geonames_adm_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS geonames_adm_string_gin_idx;
CREATE INDEX geonames_adm_string_btree_idx ON geonames_adm_string(string);
CREATE INDEX geonames_adm_string_geonameid_btree_idx ON geonames_adm_string(geonameid);
CREATE INDEX geonames_adm_string_cd_geounit_btree_idx ON geonames_adm_string(cd_geounit);
CREATE INDEX geonames_adm_string_gin_idx ON geonames_adm_string USING GIN(string gin_trgm_ops);

INSERT INTO geonames_adm_string
SELECT DISTINCT geonameid, regexp_replace(name,'[[:punct:]]','','g'), cd_geounit
FROM geonames.all_countries ac
LEFT JOIN geonames.country_iso_to_sovereign cits ON cits.iso=ac.country_code
LEFT JOIN geounit g USING (cd_sov)
WHERE feature_class='A'
UNION
SELECT DISTINCT geonameid, regexp_replace(asciiname,'[[:punct:]]','','g'), cd_geounit
FROM geonames.all_countries ac
LEFT JOIN geonames.country_iso_to_sovereign cits ON cits.iso=ac.country_code
LEFT JOIN geounit g USING (cd_sov)
WHERE feature_class='A'
UNION
SELECT DISTINCT geonameid, alternate_name, cd_geounit
FROM geonames.all_countries ac
LEFT JOIN geonames.alternate_names USING(geonameid)
LEFT JOIN geonames.country_iso_to_sovereign cits ON cits.iso=ac.country_code
LEFT JOIN geounit g USING (cd_sov)
WHERE feature_class='A'
;
DELETE FROM geonames_adm_string WHERE string !~ '[A-z]' OR string IS NULL OR string='';

DROP TABLE IF EXISTS adm0_string;
CREATE TEMPORARY TABLE adm0_string
(
    cd_geounit CHAR(3),
    string text,
    UNIQUE(string,cd_geounit)
);
DROP INDEX IF EXISTS adm0_string_btree_idx;
DROP INDEX IF EXISTS adm0_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm0_string_gin_idx;
CREATE INDEX adm0_string_btree_idx ON adm0_string(string);
CREATE INDEX adm0_string_cd_geounit_btree_idx ON adm0_string(cd_geounit);
CREATE INDEX adm0_string_gin_idx ON adm0_string USING GIN(string gin_trgm_ops);

INSERT INTO adm0_string
SELECT DISTINCT cd_geounit, regexp_replace(geounit,'[[:punct:]]','','g')
FROM main.adm0_geounit
UNION
SELECT DISTINCT cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm0_names;


DROP TABLE IF EXISTS compare_geonames_adm_adm0;
CREATE TEMPORARY TABLE compare_geonames_adm_adm0 AS(
SELECT DISTINCT geonameid,a0.cd_geounit
FROM geonames_adm_string gas
JOIN adm0_string a0 ON (a0.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a0.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(0,cd_cat_part,cd_geounit)::t_ref ref
FROM compare_geonames_adm_adm0
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm0_geounit a0 USING (cd_geounit)
WHERE ST_DWithin(ac.geom,a0.the_geom,50000,true)
ORDER BY geonameid,ST_Distance(ac.geom,a0.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;




--- ADM1
DROP TABLE IF EXISTS adm1_string;
CREATE TEMPORARY TABLE adm1_string
(
    cd_adm1 int,
    cd_geounit CHAR(3),
    string text,
    UNIQUE(string,cd_geounit,cd_adm1)
);
DROP INDEX IF EXISTS adm1_string_btree_idx;
DROP INDEX IF EXISTS adm1_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm1_string_gin_idx;
DROP INDEX IF EXISTS adm1_string_cd_adm1_btree_idx;
CREATE INDEX adm1_string_btree_idx ON adm1_string(string);
CREATE INDEX adm1_string_cd_geounit_btree_idx ON adm1_string(cd_geounit);
CREATE INDEX adm1_string_cd_adm1_btree_idx ON adm1_string(cd_adm1);
CREATE INDEX adm1_string_gin_idx ON adm1_string USING GIN(string gin_trgm_ops);

INSERT INTO adm1_string
SELECT DISTINCT cd_adm1,a1.cd_geounit, regexp_replace(adm1,'[[:punct:]]','','g')
FROM main.adm1 a1
UNION
SELECT DISTINCT cd_adm1,a1.cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm1_names n1
LEFT JOIN main.adm1 a1 USING (cd_adm1)
;

VACUUM ANALYSE geonames_adm_string;

DROP TABLE IF EXISTS compare_geonames_adm_adm1;
CREATE TEMPORARY TABLE compare_geonames_adm_adm1 AS(
SELECT DISTINCT geonameid,a1.cd_adm1
FROM geonames_adm_string gas
JOIN adm1_string a1 ON (a1.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a1.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(1,cd_cat_part,cd_adm1)::t_ref ref
FROM compare_geonames_adm_adm1
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm1 a1 USING (cd_adm1)
WHERE ST_DWithin(ac.geom,a1.the_geom,50000,true)
ORDER BY geonameid, ST_Distance(ac.geom,a1.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;


--- ADM2
DROP TABLE IF EXISTS adm2_string;
CREATE TEMPORARY TABLE adm2_string
(
    cd_adm2 int,
    cd_geounit CHAR(3),
    string text,
    UNIQUE(string,cd_geounit,cd_adm2)
);
DROP INDEX IF EXISTS adm2_string_btree_idx;
DROP INDEX IF EXISTS adm2_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm2_string_gin_idx;
DROP INDEX IF EXISTS adm2_string_cd_adm2_btree_idx;
CREATE INDEX adm2_string_btree_idx ON adm2_string(string);
CREATE INDEX adm2_string_cd_geounit_btree_idx ON adm2_string(cd_geounit);
CREATE INDEX adm2_string_cd_adm2_btree_idx ON adm2_string(cd_adm2);
CREATE INDEX adm2_string_gin_idx ON adm2_string USING GIN(string gin_trgm_ops);

INSERT INTO adm2_string
SELECT DISTINCT cd_adm2,a2.cd_geounit, regexp_replace(adm2,'[[:punct:]]','','g')
FROM main.adm2 a2
UNION
SELECT DISTINCT cd_adm2,a2.cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm2_names n2
LEFT JOIN main.adm2 a2 USING (cd_adm2)
;

VACUUM ANALYSE geonames_adm_string;

DROP TABLE IF EXISTS compare_geonames_adm_adm2;
CREATE TEMPORARY TABLE compare_geonames_adm_adm2 AS(
SELECT DISTINCT geonameid,a2.cd_adm2
FROM geonames_adm_string gas
JOIN adm2_string a2 ON (a2.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a2.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(2,cd_cat_part,cd_adm2)::t_ref ref
FROM compare_geonames_adm_adm2
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm2 a2 USING (cd_adm2)
WHERE ST_DWithin(ac.geom,a2.the_geom,50000,true)
ORDER BY geonameid, ST_Distance(ac.geom,a2.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;


--- ADM3
DROP TABLE IF EXISTS adm3_string;
CREATE TEMPORARY TABLE adm3_string
(
    cd_adm3 int,
    cd_geounit CHAR(3),
    string text,
    UNIQUE(string,cd_geounit,cd_adm3)
);
DROP INDEX IF EXISTS adm3_string_btree_idx;
DROP INDEX IF EXISTS adm3_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm3_string_gin_idx;
DROP INDEX IF EXISTS adm3_string_cd_adm3_btree_idx;
CREATE INDEX adm3_string_btree_idx ON adm3_string(string);
CREATE INDEX adm3_string_cd_geounit_btree_idx ON adm3_string(cd_geounit);
CREATE INDEX adm3_string_cd_adm3_btree_idx ON adm3_string(cd_adm3);
CREATE INDEX adm3_string_gin_idx ON adm3_string USING GIN(string gin_trgm_ops);

INSERT INTO adm3_string
SELECT DISTINCT cd_adm3,a3.cd_geounit, regexp_replace(adm3,'[[:punct:]]','','g')
FROM main.adm3 a3
UNION
SELECT DISTINCT cd_adm3,a3.cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm3_names n3
LEFT JOIN main.adm3 a3 USING (cd_adm3)
;

VACUUM ANALYSE geonames_adm_string;

DROP TABLE IF EXISTS compare_geonames_adm_adm3;
CREATE TEMPORARY TABLE compare_geonames_adm_adm3 AS(
SELECT DISTINCT geonameid,a3.cd_adm3
FROM geonames_adm_string gas
JOIN adm3_string a3 ON (a3.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a3.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(3,cd_cat_part,cd_adm3)::t_ref ref
FROM compare_geonames_adm_adm3
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm3 a3 USING (cd_adm3)
WHERE ST_DWithin(ac.geom,a3.the_geom,50000,true)
ORDER BY geonameid, ST_Distance(ac.geom,a3.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;


--- ADM4
DROP TABLE IF EXISTS adm4_string;
CREATE TEMPORARY TABLE adm4_string
(
    cd_adm4 int,
    cd_geounit CHAR(4),
    string text,
    UNIQUE(string,cd_geounit,cd_adm4)
);
DROP INDEX IF EXISTS adm4_string_btree_idx;
DROP INDEX IF EXISTS adm4_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm4_string_gin_idx;
DROP INDEX IF EXISTS adm4_string_cd_adm4_btree_idx;
CREATE INDEX adm4_string_btree_idx ON adm4_string(string);
CREATE INDEX adm4_string_cd_geounit_btree_idx ON adm4_string(cd_geounit);
CREATE INDEX adm4_string_cd_adm4_btree_idx ON adm4_string(cd_adm4);
CREATE INDEX adm4_string_gin_idx ON adm4_string USING GIN(string gin_trgm_ops);

INSERT INTO adm4_string
SELECT DISTINCT cd_adm4,a4.cd_geounit, regexp_replace(adm4,'[[:punct:]]','','g')
FROM main.adm4 a4
UNION
SELECT DISTINCT cd_adm4,a4.cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm4_names n4
LEFT JOIN main.adm4 a4 USING (cd_adm4)
;

VACUUM ANALYSE geonames_adm_string;

DROP TABLE IF EXISTS compare_geonames_adm_adm4;
CREATE TEMPORARY TABLE compare_geonames_adm_adm4 AS(
SELECT DISTINCT geonameid,a4.cd_adm4
FROM geonames_adm_string gas
JOIN adm4_string a4 ON (a4.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a4.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(4,cd_cat_part,cd_adm4)::t_ref ref
FROM compare_geonames_adm_adm4
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm4 a4 USING (cd_adm4)
WHERE ST_DWithin(ac.geom,a4.the_geom,50000,true)
ORDER BY geonameid, ST_Distance(ac.geom,a4.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;


--- ADM5
DROP TABLE IF EXISTS adm5_string;
CREATE TEMPORARY TABLE adm5_string
(
    cd_adm5 int,
    cd_geounit CHAR(5),
    string text,
    UNIQUE(string,cd_geounit,cd_adm5)
);
DROP INDEX IF EXISTS adm5_string_btree_idx;
DROP INDEX IF EXISTS adm5_string_cd_geounit_btree_idx;
DROP INDEX IF EXISTS adm5_string_gin_idx;
DROP INDEX IF EXISTS adm5_string_cd_adm5_btree_idx;
CREATE INDEX adm5_string_btree_idx ON adm5_string(string);
CREATE INDEX adm5_string_cd_geounit_btree_idx ON adm5_string(cd_geounit);
CREATE INDEX adm5_string_cd_adm5_btree_idx ON adm5_string(cd_adm5);
CREATE INDEX adm5_string_gin_idx ON adm5_string USING GIN(string gin_trgm_ops);

INSERT INTO adm5_string
SELECT DISTINCT cd_adm5,a5.cd_geounit, regexp_replace(adm5,'[[:punct:]]','','g')
FROM main.adm5 a5
UNION
SELECT DISTINCT cd_adm5,a5.cd_geounit, regexp_replace(string,'[[:punct:]]','','g')
FROM main.adm5_names n5
LEFT JOIN main.adm5 a5 USING (cd_adm5)
;

VACUUM ANALYSE geonames_adm_string;

DROP TABLE IF EXISTS compare_geonames_adm_adm5;
CREATE TEMPORARY TABLE compare_geonames_adm_adm5 AS(
SELECT DISTINCT geonameid,a5.cd_adm5
FROM geonames_adm_string gas
JOIN adm5_string a5 ON (a5.cd_geounit=gas.cd_geounit OR gas.cd_geounit IS NULL) AND gas.string ILIKE a5.string
);

WITH a AS(
SELECT DISTINCT ON (geonameid) geonameid,name,(5,cd_cat_part,cd_adm5)::t_ref ref
FROM compare_geonames_adm_adm5
JOIN geonames.all_countries ac USING (geonameid)
JOIN main.adm5 a5 USING (cd_adm5)
WHERE ST_DWithin(ac.geom,a5.the_geom,50000,true)
ORDER BY geonameid, ST_Distance(ac.geom,a5.the_geom) ASC
),b AS(
UPDATE geonames.all_countries ac
SET equi_gadm_ref=a.ref
FROM a
WHERE ac.geonameid=a.geonameid AND ac.equi_gadm_ref IS NULL
)
DELETE FROM geonames_adm_string
WHERE geonameid IN (SELECT geonameid FROM a)
;


/*
SELECT count(DISTINCT geonameid)
FROM geonames.hierarchy h
LEFT JOIN geonames.all_countries ac ON h.parent_id=ac.geonameid;

SELECT geonameid,country_code,admin1_code,admin2_code,admin3_code,admin4_code
FROM geonames.all_countries
WHERE feature_code='ADM2';

SELECT count(*),count(DISTINCT admin2_code),count(DISTINCT country_code||'.'||admin2_code),count(DISTINCT country_code||'.'||admin1_code||'.'||admin2_code)
FROM geonames.all_countries
WHERE feature_code='ADM2';


SELECT country_code||'.'||admin1_code||'.'||admin2_code,count(*)
FROM geonames.all_countries
WHERE feature_code='ADM2'
GROUP BY country_code||'.'||admin1_code||'.'||admin2_code
HAVING count(*)>1;

SELECT geonameid,name,country_code,admin1_code,admin2_code
FROM geonames.all_countries
WHERE (admin2_code IS NULL OR country_code IS NULL OR admin1_code IS NULL)
    AND feature_code='ADM2';
*/


UPDATE geonames.all_countries
SET admin1_code=NULL
WHERE admin1_code='00';

UPDATE geonames.all_countries
SET admin2_code=NULL
WHERE admin2_code='00';

UPDATE geonames.all_countries
SET admin3_code=NULL
WHERE admin3_code='00';

UPDATE geonames.all_countries
SET admin4_code=NULL
WHERE admin4_code='00';

ALTER TABLE geonames.all_countries DROP COLUMN IF EXISTS level_adm;
ALTER TABLE geonames.all_countries ADD COLUMN level_adm smallint;

UPDATE geonames.all_countries ac
SET level_adm=5
FROM geonames.admin_code5 ac5
WHERE ac.geonameid=ac5.geonameid;

UPDATE geonames.all_countries ac
SET level_adm=4
WHERE level_adm IS NULL AND admin4_code IS NOT NULL;

UPDATE geonames.all_countries ac
SET level_adm=3
WHERE level_adm IS NULL AND admin3_code IS NOT NULL;

UPDATE geonames.all_countries ac
SET level_adm=2
WHERE level_adm IS NULL AND admin2_code IS NOT NULL;

UPDATE geonames.all_countries ac
SET level_adm=1
WHERE level_adm IS NULL AND admin1_code IS NOT NULL;

UPDATE geonames.all_countries ac
SET level_adm=0
WHERE level_adm IS NULL AND country_code IS NOT NULL;

UPDATE geonames.all_countries ac
SET level_adm=0
FROM geonames.country_info ci
WHERE ac.geonameid=ci.geonameid;

UPDATE geonames.all_countries ac
SET level_adm=1
WHERE feature_code='ADM1';

UPDATE geonames.all_countries ac
SET level_adm=2
WHERE feature_code='ADM2';

UPDATE geonames.all_countries ac
SET level_adm=3
WHERE feature_code='ADM3';

UPDATE geonames.all_countries ac
SET level_adm=4
WHERE feature_code='ADM4';

UPDATE geonames.all_countries ac
SET level_adm=5
WHERE feature_code='ADM5';





DROP INDEX IF EXISTS geonames_all_countries_level_adm_idx;
CREATE INDEX geonames_all_countries_level_adm_idx ON geonames.all_countries(level_adm);


ALTER TABLE geonames.all_countries DROP COLUMN IF EXISTS adm_id;
ALTER TABLE geonames.all_countries ADD COLUMN adm_id text;

UPDATE geonames.all_countries ac
SET adm_id=CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||
            CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||
            CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END||'.'||
            CASE WHEN admin3_code IS NULL THEN 'null' ELSE admin3_code END||'.'||
            CASE WHEN admin4_code IS NULL THEN 'null' ELSE admin4_code END||'.'||
            adm5
FROM geonames.admin_code5 ac5
WHERE level_adm=5 AND ac.geonameid=ac5.geonameid;
UPDATE geonames.all_countries ac
SET adm_id=
            CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||
            CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||
            CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END||'.'||
            CASE WHEN admin3_code IS NULL THEN 'null' ELSE admin3_code END||'.'||
            CASE WHEN admin4_code IS NULL THEN 'null' ELSE admin4_code END
WHERE level_adm=4;
UPDATE geonames.all_countries ac
SET adm_id=
            CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||
            CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||
            CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END||'.'||
            CASE WHEN admin3_code IS NULL THEN 'null' ELSE admin3_code END
WHERE level_adm=3;
UPDATE geonames.all_countries ac
SET adm_id=
            CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||
            CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||
            CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END
WHERE level_adm=2;
UPDATE geonames.all_countries ac
SET adm_id=
            CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||
            CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END
WHERE level_adm=1;
UPDATE geonames.all_countries ac
SET adm_id=
            CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END
WHERE level_adm=0;
DROP INDEX IF EXISTS geonames_all_countries_adm_id_idx;
CREATE INDEX geonames_all_countries_adm_id_idx ON geonames.all_countries(adm_id);


-- find parents
/*
SELECT h.parent_id,h.child_id,type,ac1.level_adm child_level,ac2.level_adm parent_level, ac1.name child,ac2.name parent
FROM geonames.hierarchy h
LEFT JOIN geonames.all_countries ac1 ON h.child_id=ac1.geonameid
LEFT JOIN geonames.all_countries ac2 ON h.parent_id=ac2.geonameid
;
SELECT fc1.feature, fc2.feature,h.type,count(*)
FROM geonames.hierarchy h
LEFT JOIN geonames.all_countries ac1 ON h.child_id=ac1.geonameid
LEFT JOIN geonames.all_countries ac2 ON h.parent_id=ac2.geonameid
LEFT JOIN geonames.feature_codes fc1 ON ac1.feature_code=fc1.feature_code
LEFT JOIN geonames.feature_codes fc2 ON ac2.feature_code=fc2.feature_code
WHERE ac2.level_adm>ac1.level_adm
GROUP BY fc1.feature, fc2.feature,h.type
;
*/
ALTER TABLE geonames.all_countries ADD COLUMN IF NOT EXISTS parent_id int REFERENCES geonames.all_countries(geonameid);
CREATE INDEX IF NOT EXISTS geoname_all_countries_parent_id_fk_idx ON geonames.all_countries(geonameid);

WITH a AS(
SELECT DISTINCT ON (child_id) child_id,ac.geonameid parent_id
FROM geonames.hierarchy h
LEFT JOIN geonames.all_countries ac ON h.parent_id=ac.geonameid
ORDER BY child_id,equi_gadm_ref ,level_adm DESC
)
UPDATE geonames.all_countries ac
SET parent_id=a.parent_id
FROM a
WHERE ac.geonameid=a.child_id;

DROP TABLE IF EXISTS geonames.reference_adm;
CREATE TABLE geonames.reference_adm
(
    geonameid int PRIMARY KEY REFERENCES geonames.all_countries(geonameid),
    adm_id text UNIQUE,
    level_adm smallint
);
CREATE INDEX IF NOT EXISTS geonames_reference_adm_level_adm ON geonames.reference_adm(level_adm);

INSERT INTO geonames.reference_adm
SELECT geonameid,adm_id,level_adm
FROM geonames.country_info
JOIN geonames.all_countries USING (geonameid);

INSERT INTO geonames.reference_adm
SELECT geonameid,adm_id,level_adm
FROM geonames.all_countries
WHERE feature_code ~ '^ADM[1-5]$';

/*
UPDATE geonames.all_countries
SET adm_id=NULL
WHERE feature_code ~ '^ADM[1-5]$' OR parent_id IS NOT NULL;
*/

UPDATE geonames.all_countries ac
SET adm_id=NULL
FROM geonames.country_info ci
WHERE ac.geonameid=ci.geonameid AND country_code IS NOT NULL;

DELETE FROM geonames.reference_adm WHERE adm_id IS NULL;

UPDATE geonames.all_countries ac
SET parent_id=ra.geonameid
FROM geonames.reference_adm ra
WHERE ac.parent_id IS NULL AND ra.level_adm=ac.level_adm AND ra.adm_id=ac.adm_id;


-- Parents of adm_ref: it is already done well
/*
SELECT ac.geonameid, ac.name,ra.level_adm,ac.parent_id, ac2.name,ac2.level_adm
FROM geonames.reference_adm ra
JOIN geonames.all_countries ac USING (geonameid)
JOIN geonames.all_countries ac2 ON ac.parent_id=ac2.geonameid;
*/




-- How much of the references parents are recognized in our system
/*
SELECT ac1.equi_gadm_ref IS NULL,count(*)
FROM geonames.all_countries ac
LEFT JOIN geonames.all_countries ac1 ON ac.parent_id=ac1.geonameid
GROUP BY ac1.equi_gadm_ref;
*/
ALTER TABLE geonames.all_countries ADD COLUMN in_gadm_ref t_ref;


CREATE INDEX IF NOT EXISTS geonames_all_countries_equi_gadm_ref ON geonames.all_countries((equi_gadm_ref));


--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------- POPULATED PLACES -----------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
DROP TYPE IF EXISTS t_complete_ref;
CREATE TYPE  t_complete_ref AS (orig varchar(10), gadm_lev smallint, orga_lev smallint, ne_geounit CHAR(3), gadm_cd_ref int, orga_cd_ref int, geonameid int);

DROP TYPE IF EXISTS t_gadm_ref;
CREATE TYPE  t_gadm_ref AS(gadm_lev smallint, orga_lev smallint, ne_geounit CHAR(3), gadm_cd_ref int, orga_cd_ref int);





-- Checking whether cities are where it is said
/*
WITH a AS(
SELECT ac.name,acp.name,acp.equi_gadm_ref,ST_Distance(ac.geom,COALESCE(m.the_geom,dt.the_geom,d.the_geom),true)/1000 distance_km
FROM geonames.all_countries ac
LEFT JOIN geonames.all_countries acp ON ac.parent_id=acp.geonameid
LEFT JOIN municipality m ON (acp.equi_gadm_ref).cd_cat_ref=5 AND acp.equi_gadm_ref=m.ref
LEFT JOIN district dt ON (acp.equi_gadm_ref).cd_cat_ref=4 AND acp.equi_gadm_ref=m.ref
LEFT JOIN department d ON (acp.equi_gadm_ref).cd_cat_ref=3 AND acp.equi_gadm_ref=m.ref

WHERE ac.feature_class='P' AND acp.equi_gadm_ref IS NOT NULL AND (acp.equi_gadm_ref).cd_cat_ref=5
LIMIT 100000
)
SELECT *
FROM a
ORDER BY distance_km
;
*/


DROP TABLE IF EXISTS geonames.capital;
CREATE TABLE geonames.capital
(
    geonameid int PRIMARY KEY REFERENCES geonames.all_countries(geonameid),
    feature_code varchar(8) REFERENCES geonames.feature_codes(feature_code),
    capital_of_adm_id text NOT NULL,
    capital_of int REFERENCES geonames.all_countries(geonameid)
);

CREATE INDEX IF NOT EXISTS capital_of_adm_id_idx ON geonames.capital(capital_of_adm_id);

INSERT INTO geonames.capital (geonameid,feature_code,capital_of_adm_id,capital_of)
SELECT ac.geonameid,ac.feature_code,ac.country_code,ra.geonameid
FROM geonames.all_countries ac
LEFT JOIN geonames.reference_adm ra ON ac.country_code=ra.adm_id
WHERE feature_code IN ('PPLG','PPLC') AND ra.geonameid IS NOT NULL;

INSERT INTO geonames.capital (geonameid,feature_code,capital_of_adm_id)
SELECT ac.geonameid,feature_code,CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||admin1_code adm_id
FROM geonames.all_countries ac
WHERE ac.feature_code = 'PPLA' AND ac.admin1_code IS NOT NULL
ORDER BY geonameid;

INSERT INTO geonames.capital (geonameid,feature_code,capital_of_adm_id)
SELECT ac.geonameid,feature_code,CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'||CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||admin2_code adm_id
FROM geonames.all_countries ac
WHERE ac.feature_code = 'PPLA2' AND ac.admin2_code IS NOT NULL
ORDER BY geonameid;

INSERT INTO geonames.capital (geonameid,feature_code,capital_of_adm_id)
SELECT ac.geonameid,feature_code, CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'|| CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END||'.'||admin3_code adm_id
FROM geonames.all_countries ac
WHERE ac.feature_code = 'PPLA3' AND ac.admin3_code IS NOT NULL
ORDER BY geonameid;

INSERT INTO geonames.capital (geonameid,feature_code,capital_of_adm_id)
SELECT ac.geonameid,feature_code, CASE WHEN country_code IS NULL THEN 'null' ELSE country_code END||'.'|| CASE WHEN admin1_code IS NULL THEN 'null' ELSE admin1_code END||'.'||CASE WHEN admin2_code IS NULL THEN 'null' ELSE admin2_code END||'.'||CASE WHEN admin3_code IS NULL THEN 'null' ELSE admin3_code END||'.'||admin4_code adm_id
FROM geonames.all_countries ac
WHERE ac.feature_code = 'PPLA4' AND ac.admin4_code IS NOT NULL
ORDER BY geonameid;

UPDATE geonames.capital c
SET capital_of=ra.geonameid
FROM geonames.reference_adm ra
WHERE c.capital_of_adm_id=ra.adm_id AND c.capital_of IS NULL;

ALTER TABLE geonames.capital DROP COLUMN IF EXISTS capital_of_adm_id;
DELETE FROM geonames.capital WHERE capital_of IS NULL;
CREATE INDEX capital_of_idx ON geonames.capital(capital_of);

DROP TABLE IF EXISTS city CASCADE;
CREATE TABLE city --note: a city must have more than 500 habitant or to be an administrative capital (to be in the cities500 table from geonames)
(
    cd_city serial PRIMARY KEY,
    city text,
    orig text,
    geonameid int,
    feature_code varchar(10),
    in_from_geonames t_gadm_ref,--which with minimal gadm reference could we find a correspondence from geonames
    capital_of t_gadm_ref,
    population bigint,
    cd_sov CHAR(3) REFERENCES sovereign(cd_sov),-- if correspondence not found in geonames, geographically determined
    cd_geounit CHAR(3) REFERENCES geounit(cd_geounit),-- if correspondence not found in geonames, geographically determined
    cd_state int REFERENCES state(cd_state),-- if correspondence not found in geonames, geographically determined
    cd_substate int REFERENCES substate(cd_substate),-- if correspondence not found in geonames, geographically determined
    cd_department int REFERENCES department(cd_department),-- if correspondence not found in geonames, geographically determined
    cd_district int REFERENCES district(cd_district),-- if correspondence not found in geonames, geographically determined
    cd_municipality int REFERENCES municipality(cd_municipality),-- if correspondence not found in geonames, geographically determined
    cd_submunicipality int,
    min_level_equi int,
    max_level_equi int
);
SELECT AddGeometryColumn('city','the_geom',4326,'POINT',2);
CREATE INDEX IF NOT EXISTS city_the_geom_idx ON city USING GIST(the_geom);
CREATE INDEX IF NOT EXISTS city_feature_code_idx ON city(feature_code);
CREATE INDEX IF NOT EXISTS city_cd_sov_idx ON city(cd_sov);
CREATE INDEX IF NOT EXISTS city_cd_geounit_idx ON city(cd_geounit);
CREATE INDEX IF NOT EXISTS city_cd_state_idx ON city(cd_state);
CREATE INDEX IF NOT EXISTS city_cd_substate_idx ON city(cd_substate);
CREATE INDEX IF NOT EXISTS city_cd_department_idx ON city(cd_department);
CREATE INDEX IF NOT EXISTS city_cd_district_idx ON city(cd_district);
CREATE INDEX IF NOT EXISTS city_cd_municipality_idx ON city(cd_municipality);
CREATE INDEX IF NOT EXISTS city_capital_of_idx ON city((capital_of));
CREATE INDEX IF NOT EXISTS city_in_from_geonames_idx ON city((in_from_geonames));




INSERT INTO city(city,orig,geonameid,feature_code,in_from_geonames,capital_of,population,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,the_geom)
WITH a AS(
SELECT ac.name city,ac.geonameid,ac.feature_code,
    COALESCE(acp.equi_gadm_ref,acpp.equi_gadm_ref,acppp.equi_gadm_ref,acpppp.equi_gadm_ref) parent_ref,
    cac.equi_gadm_ref capital_ref,
    CASE WHEN ac.population<500 THEN NULL ELSE ac.population END population,
    ac.geom
FROM geonames.all_countries ac
JOIN geonames.cities500 c500 USING (geonameid)
LEFT JOIN geonames.capital c USING(geonameid)
LEFT JOIN geonames.all_countries cac ON cac.geonameid=c.capital_of
LEFT JOIN geonames.all_countries acp ON ac.parent_id=acp.geonameid
LEFT JOIN geonames.all_countries acpp ON acp.equi_gadm_ref IS NULL AND acp.parent_id=acpp.geonameid
LEFT JOIN geonames.all_countries acppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acpp.parent_id=acppp.geonameid
LEFT JOIN geonames.all_countries acpppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acppp.equi_gadm_ref IS NULL AND acppp.parent_id=acpppp.geonameid
WHERE ac.feature_code IN('PPL','PPLA','PPLA2','PPLA3','PPLA4','PPLC','PPLF','PPLG','PPLS')
),par AS(
SELECT geonameid,
    CASE
        WHEN m.cd_municipality IS NOT NULL THEN ((m.ref).level_ref, (m.ref).cd_cat_ref, m.cd_geounit, CASE WHEN (m.ref).level_ref=0 THEN NULL ELSE (m.ref).cd_ref END, m.cd_municipality)::t_gadm_ref
        WHEN dt.cd_district IS NOT NULL THEN ((dt.ref).level_ref, (dt.ref).cd_cat_ref, dt.cd_geounit, CASE WHEN (dt.ref).level_ref=0 THEN NULL ELSE (dt.ref).cd_ref END, dt.cd_district)::t_gadm_ref
        WHEN d.cd_department IS NOT NULL THEN ((d.ref).level_ref,(d.ref).cd_cat_ref,d.cd_geounit,CASE WHEN (d.ref).level_ref=0 THEN NULL ELSE (d.ref).cd_ref END,d.cd_department)::t_gadm_ref
        WHEN ss.cd_substate IS NOT NULL THEN ((ss.ref).level_ref,(ss.ref).cd_cat_ref,ss.cd_geounit,CASE WHEN (ss.ref).level_ref=0 THEN NULL ELSE (ss.ref).cd_ref END,ss.cd_substate)::t_gadm_ref
        WHEN s.cd_state IS NOT NULL THEN ((s.ref).level_ref,(s.ref).cd_cat_ref,s.cd_geounit,CASE WHEN (s.ref).level_ref=0 THEN NULL ELSE (s.ref).cd_ref END,s.cd_state)::t_gadm_ref
        WHEN g.cd_geounit IS NOT NULL THEN ((g.ref).level_ref,(g.ref).cd_cat_ref,g.cd_geounit,NULL,NULL)::t_gadm_ref
        WHEN sov.cd_sov IS NOT NULL THEN ((sov.ref).level_ref,(sov.ref).cd_cat_ref,sov.cd_sov,NULL,NULL)::t_gadm_ref
    END in_from_geonames,
    COALESCE(m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov,sov.cd_sov) cd_sov,
    COALESCE(m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(m.cd_district,dt.cd_district) cd_district,
    COALESCE(m.cd_municipality) cd_municipality
FROM a
LEFT JOIN municipality m ON (parent_ref).cd_cat_ref=5 AND parent_ref=m.ref
LEFT JOIN district dt ON (parent_ref).cd_cat_ref=4 AND parent_ref=dt.ref
LEFT JOIN department d ON (parent_ref).cd_cat_ref=3 AND parent_ref=d.ref
LEFT JOIN substate ss ON (parent_ref).cd_cat_ref=2 AND parent_ref=ss.ref
LEFT JOIN state s ON (parent_ref).cd_cat_ref=1 AND parent_ref=s.ref
LEFT JOIN geounit g ON (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=0 AND parent_ref=g.ref
LEFT JOIN sovereign sov ON (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=-1 AND parent_ref=sov.ref
),cap AS(
SELECT geonameid,
    CASE
        WHEN m.cd_municipality IS NOT NULL THEN ((m.ref).level_ref, (m.ref).cd_cat_ref, m.cd_geounit, CASE WHEN (m.ref).level_ref=0 THEN NULL ELSE (m.ref).cd_ref END, m.cd_municipality)::t_gadm_ref
        WHEN dt.cd_district IS NOT NULL THEN ((dt.ref).level_ref, (dt.ref).cd_cat_ref, dt.cd_geounit, CASE WHEN (dt.ref).level_ref=0 THEN NULL ELSE (dt.ref).cd_ref END, dt.cd_district)::t_gadm_ref
        WHEN d.cd_department IS NOT NULL THEN ((d.ref).level_ref,(d.ref).cd_cat_ref,d.cd_geounit,CASE WHEN (d.ref).level_ref=0 THEN NULL ELSE (d.ref).cd_ref END,d.cd_department)::t_gadm_ref
        WHEN ss.cd_substate IS NOT NULL THEN ((ss.ref).level_ref,(ss.ref).cd_cat_ref,ss.cd_geounit,CASE WHEN (ss.ref).level_ref=0 THEN NULL ELSE (ss.ref).cd_ref END,ss.cd_substate)::t_gadm_ref
        WHEN s.cd_state IS NOT NULL THEN ((s.ref).level_ref,(s.ref).cd_cat_ref,s.cd_geounit,CASE WHEN (s.ref).level_ref=0 THEN NULL ELSE (s.ref).cd_ref END,s.cd_state)::t_gadm_ref
        WHEN g.cd_geounit IS NOT NULL THEN ((g.ref).level_ref,(g.ref).cd_cat_ref,g.cd_geounit,NULL,NULL)::t_gadm_ref
        WHEN sov.cd_sov IS NOT NULL THEN ((sov.ref).level_ref,(sov.ref).cd_cat_ref,sov.cd_sov,NULL,NULL)::t_gadm_ref
    END capital_of
FROM a
LEFT JOIN municipality m ON (capital_ref).cd_cat_ref=5 AND capital_ref=m.ref
LEFT JOIN district dt ON (capital_ref).cd_cat_ref=4 AND capital_ref=dt.ref
LEFT JOIN department d ON (capital_ref).cd_cat_ref=3 AND capital_ref=d.ref
LEFT JOIN substate ss ON (capital_ref).cd_cat_ref=2 AND capital_ref=ss.ref
LEFT JOIN state s ON (capital_ref).cd_cat_ref=1 AND capital_ref=s.ref
LEFT JOIN geounit g ON (capital_ref).cd_cat_ref=0 AND (capital_ref).level_ref=0 AND capital_ref=g.ref
LEFT JOIN sovereign sov ON (capital_ref).cd_cat_ref=0 AND (capital_ref).level_ref=-1 AND capital_ref=sov.ref
)
SELECT city,'geonames' orig, geonameid, feature_code, in_from_geonames, capital_of, population, cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,geom
FROM a
LEFT JOIN par USING (geonameid)
LEFT JOIN cap USING (geonameid)
;

-- TODO: here I do a fast spatial relationship with superior levels, but it would be better to check with the names of close (not only intersecting polygons)

WITH a AS(
SELECT cd_city,
    COALESCE(m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov) cd_sov,
    COALESCE(m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(m.cd_district,dt.cd_district) cd_district,
    COALESCE(m.cd_municipality) cd_municipality
FROM city c
LEFT JOIN municipality m ON ST_Intersects(c.the_geom,m.the_geom)
LEFT JOIN district dt ON m.cd_municipality IS NULL AND ST_Intersects(c.the_geom,dt.the_geom)
LEFT JOIN department d ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND ST_Intersects(c.the_geom,d.the_geom)
LEFT JOIN substate ss ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ST_Intersects(c.the_geom,ss.the_geom)
LEFT JOIN state s ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND ST_Intersects(c.the_geom,s.the_geom)
LEFT JOIN geounit g ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND s.cd_state IS NULL AND ST_Intersects(c.the_geom,g.the_geom)
WHERE in_from_geonames IS NULL
)
UPDATE city c
SET
    cd_sov=a.cd_sov,
    cd_geounit=a.cd_geounit,
    cd_state=a.cd_state,
    cd_substate=a.cd_substate,
    cd_department=a.cd_department,
    cd_district=a.cd_district,
    cd_municipality=a.cd_municipality
FROM a
WHERE c.cd_city=a.cd_city;

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-------------- LOCALITIES ------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS locality CASCADE;
CREATE TABLE locality --note: a locality must have less than 500 habitant and not to be an administrative capital (notto be in the cities500 table from geonames) OR be directly designed as a locality in geonames
(
    cd_locality serial PRIMARY KEY,
    locality text,
    orig text,
    geonameid int,
    feature_code varchar(10),
    in_from_geonames t_gadm_ref,--which with minimal gadm reference could we find a correspondence from geonames
    population bigint,
    cd_sov CHAR(3) REFERENCES sovereign(cd_sov),-- if correspondence not found in geonames, geographically determined
    cd_geounit CHAR(3) REFERENCES geounit(cd_geounit),-- if correspondence not found in geonames, geographically determined
    cd_state int REFERENCES state(cd_state),-- if correspondence not found in geonames, geographically determined
    cd_substate int REFERENCES substate(cd_substate),-- if correspondence not found in geonames, geographically determined
    cd_department int REFERENCES department(cd_department),-- if correspondence not found in geonames, geographically determined
    cd_district int REFERENCES district(cd_district),-- if correspondence not found in geonames, geographically determined
    cd_municipality int REFERENCES municipality(cd_municipality),-- if correspondence not found in geonames, geographically determined
    cd_submunicipality int,
    cd_city int REFERENCES city(cd_city),
    min_level_equi int,
    max_level_equi int
);
SELECT AddGeometryColumn('locality','the_geom',4326,'POINT',2);
CREATE INDEX IF NOT EXISTS locality_the_geom_idx ON locality USING GIST(the_geom);
CREATE INDEX IF NOT EXISTS locality_feature_code_idx ON locality(feature_code);
CREATE INDEX IF NOT EXISTS locality_cd_sov_idx ON locality(cd_sov);
CREATE INDEX IF NOT EXISTS locality_cd_geounit_idx ON locality(cd_geounit);
CREATE INDEX IF NOT EXISTS locality_cd_state_idx ON locality(cd_state);
CREATE INDEX IF NOT EXISTS locality_cd_substate_idx ON locality(cd_substate);
CREATE INDEX IF NOT EXISTS locality_cd_department_idx ON locality(cd_department);
CREATE INDEX IF NOT EXISTS locality_cd_district_idx ON locality(cd_district);
CREATE INDEX IF NOT EXISTS locality_cd_municipality_idx ON locality(cd_municipality);
CREATE INDEX IF NOT EXISTS locality_cd_city_idx ON locality(cd_city);
CREATE INDEX IF NOT EXISTS locality_in_from_geonames_idx ON locality((in_from_geonames));




INSERT INTO locality(locality,orig,geonameid,feature_code,in_from_geonames,population,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,cd_city,the_geom)
WITH a AS(
SELECT ac.name locality,ac.geonameid,COALESCE(acp.geonameid,acpp.geonameid,acppp.geonameid,acpppp.geonameid) parent_geonameid,ac.feature_code,
    COALESCE(acp.equi_gadm_ref,acpp.equi_gadm_ref,acppp.equi_gadm_ref,acpppp.equi_gadm_ref) parent_ref,
    CASE WHEN ac.population<500 THEN NULL ELSE ac.population END population,
    ac.geom
FROM geonames.all_countries ac
LEFT JOIN geonames.cities500 c500 USING (geonameid)
LEFT JOIN geonames.all_countries acp ON ac.parent_id=acp.geonameid
LEFT JOIN geonames.all_countries acpp ON acp.equi_gadm_ref IS NULL AND acp.parent_id=acpp.geonameid
LEFT JOIN geonames.all_countries acppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acpp.parent_id=acppp.geonameid
LEFT JOIN geonames.all_countries acpppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acppp.equi_gadm_ref IS NULL AND acppp.parent_id=acpppp.geonameid
WHERE (ac.feature_class='P' AND c500.geonameid IS NULL) OR ac.feature_code = 'LCTY'
),par AS(
SELECT a.geonameid,c.cd_city,
    CASE
        WHEN m.cd_municipality IS NOT NULL THEN ((m.ref).level_ref, (m.ref).cd_cat_ref, m.cd_geounit, CASE WHEN (m.ref).level_ref=0 THEN NULL ELSE (m.ref).cd_ref END, m.cd_municipality)::t_gadm_ref
        WHEN dt.cd_district IS NOT NULL THEN ((dt.ref).level_ref, (dt.ref).cd_cat_ref, dt.cd_geounit, CASE WHEN (dt.ref).level_ref=0 THEN NULL ELSE (dt.ref).cd_ref END, dt.cd_district)::t_gadm_ref
        WHEN d.cd_department IS NOT NULL THEN ((d.ref).level_ref,(d.ref).cd_cat_ref,d.cd_geounit,CASE WHEN (d.ref).level_ref=0 THEN NULL ELSE (d.ref).cd_ref END,d.cd_department)::t_gadm_ref
        WHEN ss.cd_substate IS NOT NULL THEN ((ss.ref).level_ref,(ss.ref).cd_cat_ref,ss.cd_geounit,CASE WHEN (ss.ref).level_ref=0 THEN NULL ELSE (ss.ref).cd_ref END,ss.cd_substate)::t_gadm_ref
        WHEN s.cd_state IS NOT NULL THEN ((s.ref).level_ref,(s.ref).cd_cat_ref,s.cd_geounit,CASE WHEN (s.ref).level_ref=0 THEN NULL ELSE (s.ref).cd_ref END,s.cd_state)::t_gadm_ref
        WHEN g.cd_geounit IS NOT NULL THEN ((g.ref).level_ref,(g.ref).cd_cat_ref,g.cd_geounit,NULL,NULL)::t_gadm_ref
        WHEN sov.cd_sov IS NOT NULL THEN ((sov.ref).level_ref,(sov.ref).cd_cat_ref,sov.cd_sov,NULL,NULL)::t_gadm_ref
    END in_from_geonames,
    COALESCE(c.cd_sov,m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov,sov.cd_sov) cd_sov,
    COALESCE(c.cd_geounit,m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(c.cd_state,m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(c.cd_substate,m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(c.cd_department,m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(c.cd_district,m.cd_district,dt.cd_district) cd_district,
    COALESCE(c.cd_municipality,m.cd_municipality) cd_municipality
FROM a
LEFT JOIN city c ON parent_geonameid=c.geonameid
LEFT JOIN municipality m ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=5 AND parent_ref=m.ref
LEFT JOIN district dt ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=4 AND parent_ref=dt.ref
LEFT JOIN department d ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=3 AND parent_ref=d.ref
LEFT JOIN substate ss ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=2 AND parent_ref=ss.ref
LEFT JOIN state s ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=1 AND parent_ref=s.ref
LEFT JOIN geounit g ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=0 AND parent_ref=g.ref
LEFT JOIN sovereign sov ON c.cd_city IS NULL AND (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=-1 AND parent_ref=sov.ref
)
SELECT locality,'geonames' orig, geonameid, feature_code, in_from_geonames, population, cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,cd_city,geom
FROM a
LEFT JOIN par USING (geonameid)
;
-- TODO: here I do a fast spatial relationship with superior levels, but it would be better to check with the names of close (not only intersecting polygons)
/*
SELECT *
FROM locality
JOIN city USING (geonameid);
*/

WITH a AS(
SELECT l.cd_locality,c.cd_city,c.in_from_geonames
FROM locality l
JOIN city c USING (cd_city)
WHERE l.in_from_geonames IS NULL AND l.cd_city IS NOT NULL AND c.in_from_geonames IS NOT NULL
)
UPDATE locality l
SET in_from_geonames=a.in_from_geonames
FROM a
WHERE l.cd_locality=a.cd_locality;


WITH a AS(
SELECT cd_locality,
    c.cd_city,
    COALESCE(m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov) cd_sov,
    COALESCE(m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(m.cd_district,dt.cd_district) cd_district,
    COALESCE(m.cd_municipality) cd_municipality
FROM locality l
LEFT JOIN city c ON l.cd_city=c.cd_city
LEFT JOIN municipality m ON ST_Intersects(l.the_geom,m.the_geom)
LEFT JOIN district dt ON m.cd_municipality IS NULL AND ST_Intersects(l.the_geom,dt.the_geom)
LEFT JOIN department d ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND ST_Intersects(l.the_geom,d.the_geom)
LEFT JOIN substate ss ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ST_Intersects(l.the_geom,ss.the_geom)
LEFT JOIN state s ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND ST_Intersects(l.the_geom,s.the_geom)
LEFT JOIN geounit g ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND s.cd_state IS NULL AND ST_Intersects(l.the_geom,g.the_geom)
WHERE l.in_from_geonames IS NULL AND c.cd_city IS NULL
)
UPDATE locality l
SET
    cd_sov=a.cd_sov,
    cd_geounit=a.cd_geounit,
    cd_state=a.cd_state,
    cd_substate=a.cd_substate,
    cd_department=a.cd_department,
    cd_district=a.cd_district,
    cd_municipality=a.cd_municipality
FROM a
WHERE l.cd_locality=a.cd_locality;



-------------------------------------------------------------------------------------------------------
---- LANDSCAPES AND AREAS ------
---------------------------------------------------------------

ALTER TABLE geonames.feature_codes DROP COLUMN IF EXISTS landscape;
ALTER TABLE geonames.feature_codes ADD COLUMN landscape boolean NOT NULL DEFAULT false;

UPDATE geonames.feature_codes
SET landscape=TRUE
WHERE (feature_class IN ('H','T','V') OR feature_code IN ('AREA','CLG','CONT','FLD','GRAZ','LAND','OAS','PRK','RES','RESF','RESH','RESN','RESP','RESV','RESW','RGN','RGNH','RGNL','SALT','SNOW','CAVE','GDN','PRKGT','PRKHQ','RNCH'));

UPDATE geonames.feature_codes SET landscape=FALSE
WHERE  feature_code IN ('AIRS','CONT','ANCH','CHNM','CHNN','CNLA','CNLB','CNLD','CNLSB','DCK','DCKB','DTCH','DTCHD','DTCHI','DTCHM','HBR','HBRX','SYSI','TNLC','WLL','WLLQ','WLLS');
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------- REGIONS OF THE WORLD       -------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- the goal here is to have a table with the spatial objects for stuffs which are not possible to put in a geounit because they are larger or overlap more than one


--continent and regions already in the database
DROP TABLE IF EXISTS geonames.equi_organized_region;
CREATE TABLE geonames.equi_organized_region -- Note that there are repeated geonameid and references in this table
(
    geonameid int REFERENCES geonames.all_countries(geonameid) NOT NULL,
    table_ref text,
    cd_ref int
);

INSERT INTO geonames.equi_organized_region
WITH a AS(
SELECT 'continent' table_ref, string,cd_continent cd_ref
FROM continent_names
UNION
SELECT 'subregion' table_ref,string,cd_subregion cd_ref
FROM subregion_names
UNION
SELECT 'wb_region' table_ref,string,cd_wb_region cd_ref
FROM wb_region_names
UNION
SELECT 'region' table_ref,string,cd_region cd_ref
FROM region_names
), b AS(
SELECT geonameid,name,feature_code
FROM geonames.all_countries
WHERE feature_code IN ('CONT','RGN','AREA')
UNION
SELECT an.geonameid,alternate_name,feature_code
FROM geonames.alternate_names an
JOIN geonames.all_countries ac ON feature_code IN ('CONT','RGN') AND ac.geonameid=an.geonameid
WHERE feature_code IN ('CONT','RGN','AREA')
)
SELECT DISTINCT geonameid,table_ref,cd_ref
FROM b
JOIN a ON string=name
WHERE geonameid IS NOT NULL
;
INSERT INTO geonames.equi_organized_region
VALUES
    (7730009,'wb_region',4);


/*
SELECT feature_class, feature_code, feature, count(*)
FROM geonames.all_countries ac
LEFT JOIN geonames.feature_codes fc USING(feature_class,feature_code)
WHERE
    landscape
    AND ARRAY_LENGTH(STRING_TO_ARRAY(cc2,','),1)>1
    AND NOT geonameid IN (SELECT DISTINCT geonameid FROM geonames.equi_organized_region)
GROUP BY feature_class, feature_code, feature
ORDER BY count(*) DESC;
*/

DROP TABLE IF EXISTS international_elt;
CREATE TABLE international_elt
(
    cd_int_elt serial PRIMARY KEY,
    int_elt text,
    geonameid int UNIQUE,
    feature_code varchar(10),
    over_sov_geounit t_gadm_ref[]
);
SELECT AddGeometryColumn('international_elt','the_geom',4326,'POINT',2);
CREATE INDEX IF NOT EXISTS international_elt_the_geom_idx ON international_elt USING GIST(the_geom);
CREATE INDEX IF NOT EXISTS international_elt_feature_code_idx ON international_elt(feature_code);


INSERT INTO international_elt(geonameid,int_elt,feature_code,over_sov_geounit,the_geom)
WITH a AS(
SELECT feature_class, feature_code,feature, geonameid, name, UNNEST(STRING_TO_ARRAY(cc2,',')) iso,geom
FROM geonames.all_countries ac
LEFT JOIN geonames.feature_codes fc USING(feature_class,feature_code)
WHERE
    landscape
    AND ARRAY_LENGTH(STRING_TO_ARRAY(cc2,','),1)>1
    AND NOT geonameid IN (SELECT DISTINCT geonameid FROM geonames.equi_organized_region)
),b AS(
SELECT DISTINCT a.feature_class,a.feature_code,a.feature,a.geonameid,a.name,ac.name country,((ac.equi_gadm_ref).level_ref,(ac.equi_gadm_ref).cd_cat_ref,(ac.equi_gadm_ref).cd_ref,NULL,NULL)::t_gadm_ref includes, a.geom
FROM a
LEFT JOIN geonames.country_info ci USING (iso)
LEFT JOIN geonames.all_countries ac ON ci.geonameid=ac.geonameid
WHERE ac.geonameid IS NOT NULL
ORDER BY a.geonameid
)
SELECT geonameid,name,feature_code,ARRAY_AGG(includes),geom
FROM b
GROUP BY  geonameid,name,feature_code,geom
HAVING ARRAY_LENGTH(ARRAY_AGG(includes),1)>1
;

/*
WITH a AS(
SELECT ac.geonameid, UNNEST(STRING_TO_ARRAY(cc2,',')) cc2
FROM geonames.all_countries ac
WHERE
((feature_class IN ('H','T','V')
    AND NOT feature_code IN ('AIRS','CONT','ANCH','CHNM','CHNN','CNLA','CNLB','CNLD','CNLSB','DCK','DCKB','DTCH','DTCHD','DTCHI','DTCHM','HBR','HBRX','SYSI','TNLC','WLL','WLLQ','WLLS'))
    OR feature_code IN ('AREA','CLG','CONT','FLD','GRAZ','LAND','OAS','PRK','RES','RESF','RESH','RESN','RESP','RESV','RESW','RGN','RGNH','RGNL','SALT','SNOW','CAVE','GDN','PRKGT','PRKHQ','RNCH')
    )
),b AS(
SELECT a.geonameid,count(DISTINCT ci.iso)
FROM a
LEFT JOIN geonames.country_info ci ON cc2=iso
GROUP BY a.geonameid
HAVING count(DISTINCT ci.iso)>2
)
SELECT ac.feature_code,fc.feature,ac.name,fcp.feature_code feature_code_parent,fcp.feature feature_parent,acp.name parent,ac.cc2
FROM b
LEFT JOIN geonames.all_countries ac USING (geonameid)
LEFT JOIN geonames.feature_codes fc USING (feature_code)
LEFT JOIN geonames.all_countries acp ON ac.parent_id=acp.geonameid
LEFT JOIN geonames.feature_codes fcp ON acp.feature_code=fcp.feature_code
ORDER BY fc.feature
;
*/

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------- LANDSCAPES       -----------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS landscape CASCADE;
CREATE TABLE landscape --note: a landscape must have more than 500 habitant or to be an administrative capital (to be in the cities500 table from geonames)
(
    cd_landscape serial PRIMARY KEY,
    landscape text,
    orig text,
    geonameid int,
    feature_code varchar(10),
    in_from_geonames t_gadm_ref,--which with minimal gadm reference could we find a correspondence from geonames
    cd_sov CHAR(3) REFERENCES sovereign(cd_sov),-- if correspondence not found in geonames, geographically determined
    cd_geounit CHAR(3) REFERENCES geounit(cd_geounit),-- if correspondence not found in geonames, geographically determined
    cd_state int REFERENCES state(cd_state),-- if correspondence not found in geonames, geographically determined
    cd_substate int REFERENCES substate(cd_substate),-- if correspondence not found in geonames, geographically determined
    cd_department int REFERENCES department(cd_department),-- if correspondence not found in geonames, geographically determined
    cd_district int REFERENCES district(cd_district),-- if correspondence not found in geonames, geographically determined
    cd_municipality int REFERENCES municipality(cd_municipality),-- if correspondence not found in geonames, geographically determined
    cd_submunicipality int
);
SELECT AddGeometryColumn('landscape','the_geom',4326,'POINT',2);
CREATE INDEX IF NOT EXISTS landscape_the_geom_idx ON landscape USING GIST(the_geom);
CREATE INDEX IF NOT EXISTS landscape_feature_code_idx ON landscape(feature_code);
CREATE INDEX IF NOT EXISTS landscape_cd_sov_idx ON landscape(cd_sov);
CREATE INDEX IF NOT EXISTS landscape_cd_geounit_idx ON landscape(cd_geounit);
CREATE INDEX IF NOT EXISTS landscape_cd_state_idx ON landscape(cd_state);
CREATE INDEX IF NOT EXISTS landscape_cd_substate_idx ON landscape(cd_substate);
CREATE INDEX IF NOT EXISTS landscape_cd_department_idx ON landscape(cd_department);
CREATE INDEX IF NOT EXISTS landscape_cd_district_idx ON landscape(cd_district);
CREATE INDEX IF NOT EXISTS landscape_cd_municipality_idx ON landscape(cd_municipality);

INSERT INTO landscape(landscape,orig,geonameid,feature_code,in_from_geonames,cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,the_geom)
WITH a AS(
SELECT ac.name landscape,ac.geonameid,ac.feature_code,
    COALESCE(acp.equi_gadm_ref,acpp.equi_gadm_ref,acppp.equi_gadm_ref,acpppp.equi_gadm_ref) parent_ref,
    ac.geom
FROM geonames.all_countries ac
LEFT JOIN geonames.feature_codes fc USING (feature_code)
LEFT JOIN geonames.all_countries acp ON ac.parent_id=acp.geonameid
LEFT JOIN geonames.all_countries acpp ON acp.equi_gadm_ref IS NULL AND acp.parent_id=acpp.geonameid
LEFT JOIN geonames.all_countries acppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acpp.parent_id=acppp.geonameid
LEFT JOIN geonames.all_countries acpppp ON acp.equi_gadm_ref IS NULL AND acpp.equi_gadm_ref IS NULL  AND acppp.equi_gadm_ref IS NULL AND acppp.parent_id=acpppp.geonameid
WHERE fc.landscape AND NOT ac.geonameid IN (SELECT geonameid FROM international_elt UNION SELECT geonameid FROM geonames.equi_organized_region)
),par AS(
SELECT geonameid,
    CASE
        WHEN m.cd_municipality IS NOT NULL THEN ((m.ref).level_ref, (m.ref).cd_cat_ref, m.cd_geounit, CASE WHEN (m.ref).level_ref=0 THEN NULL ELSE (m.ref).cd_ref END, m.cd_municipality)::t_gadm_ref
        WHEN dt.cd_district IS NOT NULL THEN ((dt.ref).level_ref, (dt.ref).cd_cat_ref, dt.cd_geounit, CASE WHEN (dt.ref).level_ref=0 THEN NULL ELSE (dt.ref).cd_ref END, dt.cd_district)::t_gadm_ref
        WHEN d.cd_department IS NOT NULL THEN ((d.ref).level_ref,(d.ref).cd_cat_ref,d.cd_geounit,CASE WHEN (d.ref).level_ref=0 THEN NULL ELSE (d.ref).cd_ref END,d.cd_department)::t_gadm_ref
        WHEN ss.cd_substate IS NOT NULL THEN ((ss.ref).level_ref,(ss.ref).cd_cat_ref,ss.cd_geounit,CASE WHEN (ss.ref).level_ref=0 THEN NULL ELSE (ss.ref).cd_ref END,ss.cd_substate)::t_gadm_ref
        WHEN s.cd_state IS NOT NULL THEN ((s.ref).level_ref,(s.ref).cd_cat_ref,s.cd_geounit,CASE WHEN (s.ref).level_ref=0 THEN NULL ELSE (s.ref).cd_ref END,s.cd_state)::t_gadm_ref
        WHEN g.cd_geounit IS NOT NULL THEN ((g.ref).level_ref,(g.ref).cd_cat_ref,g.cd_geounit,NULL,NULL)::t_gadm_ref
        WHEN sov.cd_sov IS NOT NULL THEN ((sov.ref).level_ref,(sov.ref).cd_cat_ref,sov.cd_sov,NULL,NULL)::t_gadm_ref
    END in_from_geonames,
    COALESCE(m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov,sov.cd_sov) cd_sov,
    COALESCE(m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(m.cd_district,dt.cd_district) cd_district,
    COALESCE(m.cd_municipality) cd_municipality
FROM a
LEFT JOIN municipality m ON (parent_ref).cd_cat_ref=5 AND parent_ref=m.ref
LEFT JOIN district dt ON (parent_ref).cd_cat_ref=4 AND parent_ref=dt.ref
LEFT JOIN department d ON (parent_ref).cd_cat_ref=3 AND parent_ref=d.ref
LEFT JOIN substate ss ON (parent_ref).cd_cat_ref=2 AND parent_ref=ss.ref
LEFT JOIN state s ON (parent_ref).cd_cat_ref=1 AND parent_ref=s.ref
LEFT JOIN geounit g ON (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=0 AND parent_ref=g.ref
LEFT JOIN sovereign sov ON (parent_ref).cd_cat_ref=0 AND (parent_ref).level_ref=-1 AND parent_ref=sov.ref
)
SELECT landscape,'geonames' orig, geonameid, feature_code, in_from_geonames, cd_sov,cd_geounit,cd_state,cd_substate,cd_department,cd_district,cd_municipality,geom
FROM a
LEFT JOIN par USING (geonameid)
;

WITH a AS(
SELECT cd_landscape,
    COALESCE(m.cd_sov,dt.cd_sov,d.cd_sov,ss.cd_sov,s.cd_sov,g.cd_sov) cd_sov,
    COALESCE(m.cd_geounit,dt.cd_geounit,d.cd_geounit,ss.cd_geounit,s.cd_geounit,g.cd_geounit) cd_geounit,
    COALESCE(m.cd_state,dt.cd_state,d.cd_state,ss.cd_state,s.cd_state) cd_state,
    COALESCE(m.cd_substate,dt.cd_substate,d.cd_substate,ss.cd_substate) cd_substate,
    COALESCE(m.cd_department,dt.cd_department,d.cd_department) cd_department,
    COALESCE(m.cd_district,dt.cd_district) cd_district,
    COALESCE(m.cd_municipality) cd_municipality
FROM landscape c
LEFT JOIN municipality m ON false AND ST_Intersects(c.the_geom,m.the_geom) -- note:deactivated
LEFT JOIN district dt ON false AND m.cd_municipality IS NULL AND ST_Intersects(c.the_geom,dt.the_geom)-- note:deactivated
LEFT JOIN department d ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND ST_Intersects(c.the_geom,d.the_geom)
LEFT JOIN substate ss ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ST_Intersects(c.the_geom,ss.the_geom)
LEFT JOIN state s ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND ST_Intersects(c.the_geom,s.the_geom)
LEFT JOIN geounit g ON m.cd_municipality IS NULL AND dt.cd_district IS NULL AND d.cd_department IS NULL AND ss.cd_substate IS NULL AND s.cd_state IS NULL AND ST_Intersects(c.the_geom,g.the_geom)
WHERE in_from_geonames IS NULL
)
UPDATE landscape c
SET
    cd_sov=a.cd_sov,
    cd_geounit=a.cd_geounit,
    cd_state=a.cd_state,
    cd_substate=a.cd_substate,
    cd_department=a.cd_department,
    cd_district=a.cd_district,
    cd_municipality=a.cd_municipality
FROM a
WHERE c.cd_landscape=a.cd_landscape;

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-------------------- NAMES --------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
/* TODO Later we should do it properly from the creation of the tables but for now we will modify the name tables to have instead of a category containing a lot of information, columns for abbreviation, formal, long, short, alternate,main/preferred, sort,colloquial, historic */


ALTER TABLE main.country_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm0_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm1_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm2_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm3_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm4_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE main.adm5_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE region_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE continent_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE subregion_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

ALTER TABLE wb_region_names
ADD COLUMN IF NOT EXISTS preferred boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS abbrev_type varchar(50),
ADD COLUMN IF NOT EXISTS formal boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS long boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS short boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sort boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS colloquial boolean NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historic boolean NOT NULL DEFAULT FALSE;

--------------------------------------------------------------------------------------------------
UPDATE main.country_names SET sort=true WHERE name_type='sort';
UPDATE main.country_names SET long=true WHERE name_type='long';
UPDATE main.country_names SET formal=true WHERE name_type='formal';

UPDATE main.adm0_names SET sort=true WHERE name_type='sort';
UPDATE main.adm0_names SET long=true WHERE name_type='long';
UPDATE main.adm0_names SET formal=true WHERE name_type='formal';

UPDATE main.adm0_names SET abbrev=true, abbrev_type='state long' WHERE name_type='state abbv long';
UPDATE main.adm0_names SET abbrev=true, abbrev_type='state 2' WHERE name_type='state abbv 2';

-------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--------------- MODIFYING OLD name tables ------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--TODO: I wont modify the name tables from main for now, just the ones from public...


ALTER TABLE sovereign_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ~ 'names';

DROP TABLE IF EXISTS tmp_country_names;
CREATE TEMPORARY TABLE  tmp_country_names AS(
SELECT geonameid,country,'en' cd_lang,true preferred,false abbrev,NULL abbrev_type,false formal,false long, true short,false sort,false colloquial,false historic,equi_gadm_ref
FROM geonames.country_info ci
LEFT JOIN geonames.all_countries ac USING (geonameid)
WHERE equi_gadm_ref IS NOT NULL
UNION
SELECT geonameid,name,'en' cd_lang,false preferred,false abbrev,NULL abbrev_type,true formal,true long, false short,false sort,false colloquial,false historic,equi_gadm_ref
FROM geonames.country_info ci
LEFT JOIN geonames.all_countries ac USING (geonameid)
WHERE equi_gadm_ref IS NOT NULL
UNION
SELECT DISTINCT geonameid,
    an.alternate_name,
    CASE
        WHEN an.cd_lang IS NULL THEN NULL
        WHEN  ( l.cd_lang IS NULL) AND ilc.cd_lang IS NOT NULL THEN '99'
        ELSE l.cd_lang
    END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref
FROM geonames.country_info ci
LEFT JOIN geonames.all_countries ac USING (geonameid)
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON iso_639_1=l.cd_lang
WHERE alternate_name ~ '[A-z]'
    AND NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND equi_gadm_ref IS NOT NULL
);


/*
SELECT (equi_gadm_ref).cd_cat_ref, (equi_gadm_ref).level_ref, count(*)
FROM tmp_country_names
GROUP BY (equi_gadm_ref).cd_cat_ref, (equi_gadm_ref).level_ref
ORDER BY (equi_gadm_ref).cd_cat_ref, (equi_gadm_ref).level_ref
;
*/

-- Here we might want to first update values which are already there
INSERT INTO sovereign_names (cd_sov,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT tcn.*,cd_name
FROM tmp_country_names tcn
LEFT JOIN sovereign_names sn ON equi_gadm_ref=ref AND country=string AND ((sn.cd_lang IS NULL AND tcn.cd_lang='99') OR sn.cd_lang=tcn.cd_lang)
WHERE (tcn.equi_gadm_ref).level_ref=-1
ORDER BY geonameid
)
SELECT DISTINCT (equi_gadm_ref).cd_ref cd_sov,country string, 'geonames' orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,equi_gadm_ref
FROM a
WHERE cd_name IS NULL
;

WITH a AS(
SELECT cd_sov,string,orig,name_type,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ARRAY_AGG(cd_name ORDER BY ref IS NULL) rep_names
FROM sovereign_names
GROUP BY cd_sov,string,orig,name_type,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic
HAVING count(*)>1
),b AS(
SELECT UNNEST(rep_names[2:ARRAY_LENGTH(rep_names,1)]) cd_name,cd_sov
FROM a
ORDER BY cd_sov
)
DELETE FROM sovereign_names WHERE cd_name IN (SELECT cd_name FROM b)
;

-- geounit from geonames countries

INSERT INTO geounit_names (cd_geounit,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT tcn.*,cd_name
FROM tmp_country_names tcn
LEFT JOIN geounit_names sn ON equi_gadm_ref=ref AND country=string AND ((sn.cd_lang IS NULL AND tcn.cd_lang='99') OR sn.cd_lang=tcn.cd_lang)
WHERE (tcn.equi_gadm_ref).level_ref=0 AND (tcn.equi_gadm_ref).cd_cat_ref=0
ORDER BY geonameid
)
SELECT DISTINCT (equi_gadm_ref).cd_ref cd_geounit,country string, 'geonames' orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,equi_gadm_ref
FROM a
WHERE cd_name IS NULL
;

WITH a AS(
SELECT cd_geounit,string,orig,name_type,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ARRAY_AGG(cd_name) rep_names
FROM geounit_names
GROUP BY cd_geounit,string,orig,name_type,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic
HAVING count(*)>1
),b AS(
SELECT UNNEST(rep_names[2:ARRAY_LENGTH(rep_names,1)]) cd_name,cd_geounit
FROM a
ORDER BY cd_geounit
)
DELETE FROM geounit_names WHERE cd_name IN (SELECT cd_name FROM b)
;
----------------------------------STATES ----------------------------------------------

-- TODO We've got a problem some equi_gadm_ref have cd_cat_ref>1 and a character cd_ref
-- TODO We've got another proble some counties or depatments have the same names than states and are then into the states

ALTER TABLE state_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

INSERT INTO state_names(cd_state,string,orig,ref,abbrev,formal,long)
WITH a AS(
SELECT geonameid,cd_state,name,state,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN state ON (equi_gadm_ref).cd_cat_ref=1 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=1 AND cd_state IS NOT NULL
)
SELECT DISTINCT ON (cd_state,name) a.cd_state,name string,'geonames' orig,equi_gadm_ref,false abbrev,true formal,true long
FROM a
LEFT JOIN state_names sn ON a.cd_state=sn.cd_state AND a.name=sn.string
WHERE sn.cd_name IS NULL AND name !~ 'county'
;


INSERT INTO state_names(cd_state,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT geonameid,cd_state,name,state,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN state ON (equi_gadm_ref).cd_cat_ref=1 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=1 AND cd_state IS NOT NULL
)
SELECT DISTINCT ON (cd_state,name,l.cd_lang) a.cd_state,alternate_name string,'geonames' orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref ref
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN state_names sn ON a.cd_state=sn.cd_state AND a.name=sn.string AND ((l.cd_lang IS NULL AND sn.cd_lang IS NULL) OR l.cd_lang=sn.cd_lang) -- note that we use only state, string and language to determine whether the name is already on the list
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND a.name !~ 'county'
    AND sn.cd_name IS NULL
;


----------------------------------SUBSTATES ----------------------------------------------


ALTER TABLE substate_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

INSERT INTO substate_names(cd_substate,string,orig,ref,abbrev,formal,long)
WITH a AS(
SELECT geonameid,cd_substate,name,substate,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN substate ON (equi_gadm_ref).cd_cat_ref=2 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=2 AND cd_substate IS NOT NULL
)
SELECT DISTINCT ON (cd_substate,name) a.cd_substate,name string,'geonames' orig,equi_gadm_ref,false abbrev,true formal,true long
FROM a
LEFT JOIN substate_names sn ON a.cd_substate=sn.cd_substate AND a.name=sn.string
WHERE sn.cd_name IS NULL
;

INSERT INTO substate_names(cd_substate,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT geonameid,cd_substate,name,substate,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN substate ON (equi_gadm_ref).cd_cat_ref=2 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=2 AND cd_substate IS NOT NULL
)
SELECT DISTINCT ON (cd_substate,name,l.cd_lang) a.cd_substate,alternate_name string,'geonames' orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref ref
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN substate_names sn ON a.cd_substate=sn.cd_substate AND a.name=sn.string AND ((l.cd_lang IS NULL AND sn.cd_lang IS NULL) OR l.cd_lang=sn.cd_lang) -- note that we use only substate, string and language to determine whether the name is already on the list
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND a.name !~ 'county'
    AND sn.cd_name IS NULL
;


----------------------------------DEPARTMENTS ----------------------------------------------


ALTER TABLE department_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

INSERT INTO department_names(cd_department,string,orig,ref,abbrev,formal,long)
WITH a AS(
SELECT geonameid,cd_department,name,department,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN department ON (equi_gadm_ref).cd_cat_ref=3 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=3 AND cd_department IS NOT NULL
)
SELECT DISTINCT ON (cd_department,name) a.cd_department,name string,'geonames' orig,equi_gadm_ref,false abbrev,true formal,true long
FROM a
LEFT JOIN department_names sn ON a.cd_department=sn.cd_department AND a.name=sn.string
WHERE sn.cd_name IS NULL
;

INSERT INTO department_names(cd_department,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT geonameid,cd_department,name,department,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN department ON (equi_gadm_ref).cd_cat_ref=3 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=3 AND cd_department IS NOT NULL
)
SELECT DISTINCT ON (cd_department,name,l.cd_lang) a.cd_department,alternate_name string,'geonames' orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref ref
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN department_names sn ON a.cd_department=sn.cd_department AND a.name=sn.string AND ((l.cd_lang IS NULL AND sn.cd_lang IS NULL) OR l.cd_lang=sn.cd_lang) -- note that we use only department, string and language to determine whether the name is already on the list
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND sn.cd_name IS NULL
;


----------------------------------DISTRICTS ----------------------------------------------


ALTER TABLE district_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

INSERT INTO district_names(cd_district,string,orig,ref,abbrev,formal,long)
WITH a AS(
SELECT geonameid,cd_district,name,district,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN district ON (equi_gadm_ref).cd_cat_ref=4 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=4 AND cd_district IS NOT NULL
)
SELECT DISTINCT ON (cd_district,name) a.cd_district,name string,'geonames' orig,equi_gadm_ref,false abbrev,true formal,true long
FROM a
LEFT JOIN district_names sn ON a.cd_district=sn.cd_district AND a.name=sn.string
WHERE sn.cd_name IS NULL
;

INSERT INTO district_names(cd_district,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT geonameid,cd_district,name,district,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN district ON (equi_gadm_ref).cd_cat_ref=4 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=4 AND cd_district IS NOT NULL
)
SELECT DISTINCT ON (cd_district,name,l.cd_lang) a.cd_district,alternate_name string,'geonames' orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref ref
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN district_names sn ON a.cd_district=sn.cd_district AND a.name=sn.string AND ((l.cd_lang IS NULL AND sn.cd_lang IS NULL) OR l.cd_lang=sn.cd_lang) -- note that we use only district, string and language to determine whether the name is already on the list
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND sn.cd_name IS NULL
;


----------------------------------MUNICIPALITY ----------------------------------------------


ALTER TABLE municipality_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;

INSERT INTO municipality_names(cd_municipality,string,orig,ref,abbrev,formal,long)
WITH a AS(
SELECT geonameid,cd_municipality,name,municipality,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN municipality ON (equi_gadm_ref).cd_cat_ref=5 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=5 AND cd_municipality IS NOT NULL
)
SELECT DISTINCT ON (cd_municipality,name) a.cd_municipality,name string,'geonames' orig,equi_gadm_ref,false abbrev,true formal,true long
FROM a
LEFT JOIN municipality_names sn ON a.cd_municipality=sn.cd_municipality AND a.name=sn.string
WHERE sn.cd_name IS NULL
;

INSERT INTO municipality_names(cd_municipality,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic,ref)
WITH a AS(
SELECT geonameid,cd_municipality,name,municipality,equi_gadm_ref
FROM geonames.all_countries
LEFT JOIN municipality ON (equi_gadm_ref).cd_cat_ref=5 AND equi_gadm_ref=ref
WHERE (equi_gadm_ref).cd_cat_ref=5 AND cd_municipality IS NOT NULL
)
SELECT DISTINCT ON (cd_municipality,name,l.cd_lang) a.cd_municipality,alternate_name string,'geonames' orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic,
    equi_gadm_ref ref
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN municipality_names sn ON a.cd_municipality=sn.cd_municipality AND a.name=sn.string AND ((l.cd_lang IS NULL AND sn.cd_lang IS NULL) OR l.cd_lang=sn.cd_lang) -- note that we use only municipality, string and language to determine whether the name is already on the list
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND sn.cd_name IS NULL
;
---------------------- Special tables ---------------------------------------

-- continents
ALTER TABLE continent_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;
INSERT INTO continent_names(cd_continent, string, ascii_simp,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
WITH a AS(
SELECT cd_continent, name string,asciiname ascii_simp,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM geonames.equi_organized_region
JOIN continent ON table_ref='continent' AND cd_ref=cd_continent
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT a.*
FROM a
LEFT JOIN continent_names cn USING(string,cd_lang)
WHERE cd_name IS NULL
;
INSERT INTO continent_names(cd_continent,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
WITH a AS(
SELECT cd_continent, 'geonames' orig, geonameid
FROM geonames.equi_organized_region
JOIN continent ON table_ref='continent' AND cd_ref=cd_continent
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT DISTINCT a.cd_continent,alternate_name,a.orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN continent_names cn ON string=alternate_name AND l.cd_lang=cn.cd_lang OR (l.cd_lang IS NULL AND cn.cd_lang IS NULL)
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND cn.cd_name IS NULL
;

-- wb_regions
ALTER TABLE wb_region_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;
INSERT INTO wb_region_names(cd_wb_region, string, ascii_simp,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
WITH a AS(
SELECT cd_wb_region, name string,asciiname ascii_simp,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM geonames.equi_organized_region
JOIN wb_region ON table_ref='wb_region' AND cd_ref=cd_wb_region
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT a.*
FROM a
LEFT JOIN wb_region_names cn USING(string,cd_lang)
WHERE cd_name IS NULL
;
INSERT INTO wb_region_names(cd_wb_region,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
WITH a AS(
SELECT cd_wb_region, 'geonames' orig, geonameid
FROM geonames.equi_organized_region
JOIN wb_region ON table_ref='wb_region' AND cd_ref=cd_wb_region
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT DISTINCT a.cd_wb_region,alternate_name,a.orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN wb_region_names cn ON string=alternate_name AND l.cd_lang=cn.cd_lang OR (l.cd_lang IS NULL AND cn.cd_lang IS NULL)
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND cn.cd_name IS NULL
;

-- regions
ALTER TABLE region_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;
INSERT INTO region_names(cd_region, string, ascii_simp,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
WITH a AS(
SELECT cd_region, name string,asciiname ascii_simp,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM geonames.equi_organized_region
JOIN region ON table_ref='region' AND cd_ref=cd_region
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT a.*
FROM a
LEFT JOIN region_names cn USING(string,cd_lang)
WHERE cd_name IS NULL
;
INSERT INTO region_names(cd_region,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
WITH a AS(
SELECT cd_region, 'geonames' orig, geonameid
FROM geonames.equi_organized_region
JOIN region ON table_ref='region' AND cd_ref=cd_region
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT DISTINCT a.cd_region,alternate_name,a.orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN region_names cn ON string=alternate_name AND l.cd_lang=cn.cd_lang OR (l.cd_lang IS NULL AND cn.cd_lang IS NULL)
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND cn.cd_name IS NULL
;

-- subregions
ALTER TABLE subregion_names ADD COLUMN IF NOT EXISTS cd_name serial PRIMARY KEY;
INSERT INTO subregion_names(cd_subregion, string, ascii_simp,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
WITH a AS(
SELECT cd_subregion, name string,asciiname ascii_simp,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM geonames.equi_organized_region
JOIN subregion ON table_ref='subregion' AND cd_ref=cd_subregion
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT a.*
FROM a
LEFT JOIN subregion_names cn USING(string,cd_lang)
WHERE cd_name IS NULL
;
INSERT INTO subregion_names(cd_subregion,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
WITH a AS(
SELECT cd_subregion, 'geonames' orig, geonameid
FROM geonames.equi_organized_region
JOIN subregion ON table_ref='subregion' AND cd_ref=cd_subregion
LEFT JOIN geonames.all_countries USING (geonameid)
)
SELECT DISTINCT a.cd_subregion,alternate_name,a.orig,
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    false preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM a
LEFT JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
LEFT JOIN subregion_names cn ON string=alternate_name AND l.cd_lang=cn.cd_lang OR (l.cd_lang IS NULL AND cn.cd_lang IS NULL)
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
    AND cn.cd_name IS NULL
;
---------------------- ADDING NAMES IN TABLES WHICH DO NOT EXIST YET --------------------------------------

--- city
DROP TABLE IF EXISTS city_names;
CREATE TABLE city_names
(
    cd_name serial PRIMARY KEY,
    cd_city int REFERENCES city(cd_city),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    trust int NOT NULL DEFAULT 10,
    preferred boolean,
    abbrev boolean,
    abbrev_type varchar(50),
    formal boolean,
    long boolean,
    short boolean,
    sort boolean,
    colloquial boolean,
    historic boolean
);
INSERT INTO city_names(cd_city,string,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
SELECT DISTINCT cd_city, name string,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM city
LEFT JOIN geonames.all_countries USING (geonameid)
;

INSERT INTO city_names(cd_city,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
SELECT DISTINCT ON (alternate_name,l.cd_lang) cd_city, alternate_name string,'geonames',
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    CASE WHEN is_preferred_name=1 THEN true ELSE false END preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM city
JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
;
--- international_elt
DROP TABLE IF EXISTS international_elt_names;
CREATE TABLE international_elt_names
(
    cd_name serial PRIMARY KEY,
    cd_int_elt int REFERENCES international_elt(cd_int_elt),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    trust int NOT NULL DEFAULT 10,
    preferred boolean,
    abbrev boolean,
    abbrev_type varchar(50),
    formal boolean,
    long boolean,
    short boolean,
    sort boolean,
    colloquial boolean,
    historic boolean
);
INSERT INTO international_elt_names(cd_int_elt,string,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
SELECT DISTINCT cd_int_elt, name string,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM international_elt
LEFT JOIN geonames.all_countries USING (geonameid)
;

INSERT INTO international_elt_names(cd_int_elt,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
SELECT DISTINCT ON (alternate_name,l.cd_lang) cd_int_elt, alternate_name string,'geonames',
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    CASE WHEN is_preferred_name=1 THEN true ELSE false END preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM international_elt
JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
;
--- landscape
DROP TABLE IF EXISTS landscape_names;
CREATE TABLE landscape_names
(
    cd_name serial PRIMARY KEY,
    cd_landscape int REFERENCES landscape(cd_landscape),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    trust int NOT NULL DEFAULT 10,
    preferred boolean,
    abbrev boolean,
    abbrev_type varchar(50),
    formal boolean,
    long boolean,
    short boolean,
    sort boolean,
    colloquial boolean,
    historic boolean
);
INSERT INTO landscape_names(cd_landscape,string,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
SELECT DISTINCT cd_landscape, name string,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM landscape
LEFT JOIN geonames.all_countries USING (geonameid)
;

INSERT INTO landscape_names(cd_landscape,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
SELECT DISTINCT ON (alternate_name,l.cd_lang) cd_landscape, alternate_name string,'geonames',
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    CASE WHEN is_preferred_name=1 THEN true ELSE false END preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM landscape
JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
;
--- locality
DROP TABLE IF EXISTS locality_names;
CREATE TABLE locality_names
(
    cd_name serial PRIMARY KEY,
    cd_locality int REFERENCES locality(cd_locality),
    string text,
    orig text,
    name_type text,
    cd_lang character(2),
    locale boolean,
    trust int NOT NULL DEFAULT 10,
    preferred boolean,
    abbrev boolean,
    abbrev_type varchar(50),
    formal boolean,
    long boolean,
    short boolean,
    sort boolean,
    colloquial boolean,
    historic boolean
);
INSERT INTO locality_names(cd_locality,string,orig,cd_lang,preferred,abbrev,formal,long,short, sort, colloquial,historic)
SELECT DISTINCT cd_locality, name string,'geonames','en' cd_lang,false preferred,false abbrev,false formal,false long,false short, false sort, false colloquial,false historic
FROM locality
LEFT JOIN geonames.all_countries USING (geonameid)
;

INSERT INTO locality_names(cd_locality,string,orig,cd_lang,preferred,abbrev,abbrev_type,formal,long,short,sort,colloquial,historic)
SELECT DISTINCT ON (alternate_name,l.cd_lang) cd_locality, alternate_name string,'geonames',
    CASE WHEN l.cd_lang IS NOT NULL THEN l.cd_lang ELSE '99' END cd_lang,
    CASE WHEN is_preferred_name=1 THEN true ELSE false END preferred,
    isolanguage='abbr' abbrev,
    NULL abbrev_type,
    false formal,
    false long,
    CASE WHEN is_short_name=1 THEN true ELSE false END short,
    false sort,
    CASE WHEN is_colloquial=1 THEN true ELSE false END colloquial,
    CASE WHEN is_historic=1 THEN true ELSE false END historic
FROM locality
JOIN geonames.alternate_names an USING (geonameid)
LEFT JOIN geonames.iso_languagecodes ilc USING (cd_lang)
LEFT JOIN main.lang l ON ilc.iso_639_1=l.cd_lang
WHERE
    NOT isolanguage IN ('link','wkdt','post','iata','icao','faac','unlc','lauc','nuts','geoid','uicn','tcid','phon')
    AND alternate_name ~ '[A-z]'
;
