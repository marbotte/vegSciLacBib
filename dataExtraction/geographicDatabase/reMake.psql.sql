DROP SCHEMA IF EXISTS main CASCADE;
DROP SCHEMA IF EXISTS tmp CASCADE;
DROP TABLE IF EXISTS gadm.adm0_to_geounit CASCADE;
\i ./adm0_regions_countries.sql
\i ./adm0_geounit.sql
\i ./lang.sql
\i ./country_geounit_names_ne.sql
\i ./relations_adm0.sql
\i ./adm1.sql
\i ./adm2.sql
\i ./adm3.sql
\i ./adm4.sql
\i ./adm5.sql
\i ./ne_relations_adm1_adm2.sql
\i ./names_adm1_to_5.sql
\i ./Islands_info.sql
\i managing_types_adm1.sql
\i managing_types_adm2.sql
\i managing_types_adm3.sql
\i managing_types_adm4.sql
\i managing_types_adm5.sql
\i managing_types_adm0_final.sql
\i final_organization.sql
\i geonames.sql
VACUUM FULL VERBOSE ANALYSE;
