CREATE TABLE main.adm0_geounit
(
  cd_geounit char(3) PRIMARY KEY CHECK (cd_geounit ~ '^[A-Z]{3}$'),
  geounit varchar(30) UNIQUE NOT NULL,
  sovereign char(3) REFERENCES main.country(cd_country),
  cd_continent int REFERENCES main.continent(cd_continent),
  cd_subregion int REFERENCES main.subregion(cd_subregion),
  cd_wb_region int REFERENCES main.wb_region(cd_wb_region),
  conflict_sov boolean,
  main_territ boolean,-- is it the main territory of the country
  dependency boolean, -- is it a dependency
  part_multi boolean, -- if the country does have various part
  cd_cat_part int,
  equi_adm1 int,
  equi_adm2 int,
  equi_adm3 int,
  equi_adm4 int,
  equi_adm5 int,
  equi_city int
);
SELECT AddGeometryColumn('main','adm0_geounit','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO main.adm0_geounit(cd_geounit, geounit, sovereign, cd_continent, cd_subregion, cd_wb_region,the_geom)
WITH names AS(
SELECT name,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
UNION
SELECT name_en,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
UNION
SELECT formal_en,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
), j_same_name AS(
SELECT
  s.name,
  ARRAY_AGG(DISTINCT s.su_a3) su_a3,
  ARRAY_AGG(DISTINCT s.adm0_a3) adm0_a3,
  ARRAY_AGG(DISTINCT cd_country) cd_country,
  ARRAY_AGG(DISTINCT cd_continent) cd_continent,
  ARRAY_AGG(DISTINCT cd_subregion) cd_subregion,
  ARRAY_AGG(DISTINCT cd_wb_region) cd_wb_region,
  ST_MULTI(ST_Union(geom)) the_geom
FROM ne.ne_10m_admin_0_map_subunits s
LEFT JOIN names n ON s.sovereignt=n.name
LEFT JOIN main.continent c ON s.continent=c.continent
LEFT JOIN main.subregion sr ON s.subregion=sr.subregion
LEFT JOIN main.wb_region wb ON s.region_wb=wb.wb_region
GROUP BY s.name
)
SELECT
  CASE
    WHEN ARRAY_LENGTH(su_a3,1)>1 THEN adm0_a3[1]
    ELSE su_a3[1]
  END,
  name,
  cd_country[1],
  cd_continent[1],
  cd_subregion[1],
  cd_wb_region[1],
  the_geom
FROM j_same_name;
UPDATE main.adm0_geounit SET the_geom=ST_MakeValid(the_geom) WHERE NOT ST_IsValid(the_geom);
CREATE INDEX main_adm0_geounit_sovereign_idx ON main.adm0_geounit(sovereign);
CREATE INDEX main_adm0_geounit_cd_continent_idx ON main.adm0_geounit(cd_continent);
CREATE INDEX main_adm0_geounit_cd_subregion_idx ON main.adm0_geounit(cd_subregion);
CREATE INDEX main_adm0_geounit_cd_wb_region_idx ON main.adm0_geounit(cd_wb_region);
CREATE INDEX main_adm0_geounit_the_geom_idx ON main.continent USING GIST(the_geom);


ALTER TABLE ne.ne_10m_admin_0_map_subunits ADD column IF NOT EXISTS cd_geounit char(3);
WITH a AS(
SELECT
  ARRAY_AGG(ogc_fid) ogc_fid,
  ARRAY_AGG(DISTINCT s.su_a3) su_a3,
  ARRAY_AGG(DISTINCT s.adm0_a3) adm0_a3
FROM ne.ne_10m_admin_0_map_subunits s
GROUP BY s.name
), b AS(
SELECT
  UNNEST(ogc_fid) ogc_fid,
  CASE
    WHEN ARRAY_LENGTH(su_a3,1)>1 THEN adm0_a3[1]
    ELSE su_a3[1]
  END cd_geounit
FROM a
)
UPDATE ne.ne_10m_admin_0_map_subunits g SET cd_geounit=b.cd_geounit
FROM b
WHERE g.ogc_fid=b.ogc_fid;
