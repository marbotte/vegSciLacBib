

CREATE TABLE main.adm1
(
  cd_adm1 serial PRIMARY KEY,
  adm1 varchar(50) UNIQUE,
  orig varchar(20),
  gid_1 varchar(10),-- unique key from gadm
  adm1_code varchar(10),-- unique key from naturalearth
  cd_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit), -- parent geounit
  type_part varchar(50),
  equi_geounit char(3) REFERENCES main.adm0_geounit(cd_geounit),
  equi_adm2 int,
  equi_adm3 int,
  equi_adm4 int,
  equi_adm5 int,
  equi_muni int
);
SELECT AddGeometryColumn('main','adm0_geounit','the_geom',4326,'MULTIPOLYGON',2);

-- Fist we include the gid_1 which corresponds to geounits

SELECT name_1, 'gadm', gid_1, included_in,gid_0,engtype_1
FROM tmp.equi_gu_to_gadms egtg
JOIN gadm.gadm_adm1 g1 USING (gid_1)
LEFT JOIN gadm.adm0_to_geounit a0tg USING (gid_0)

