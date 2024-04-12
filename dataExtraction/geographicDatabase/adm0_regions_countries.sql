CREATE SCHEMA  IF NOT EXISTS main AUTHORIZATION CURRENT_USER;
CREATE TABLE main.continent
(
  cd_continent serial PRIMARY KEY,
  continent varchar(30) UNIQUE
);
SELECT AddGeometryColumn('main','continent','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO main.continent(continent,the_geom)
SELECT continent, ST_Union(geom)
FROM ne.ne_10m_admin_0_map_subunits
WHERE continent !~ 'Seven seas'
GROUP BY continent;
CREATE INDEX main_continent_the_geom_idx ON main.continent USING GIST(the_geom);


CREATE TABLE main.wb_region
(
  cd_wb_region serial PRIMARY KEY,
  wb_region varchar(30) UNIQUE
);
SELECT AddGeometryColumn('main','wb_region','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO main.wb_region(wb_region, the_geom)
SELECT region_wb, ST_Union(geom)
FROM ne.ne_10m_admin_0_map_subunits
GROUP BY region_wb;
CREATE INDEX main_wb_region_the_geom_idx ON main.wb_region USING GIST(the_geom);

CREATE TABLE main.subregion
(
  cd_subregion serial PRIMARY KEY,
  subregion varchar(30) UNIQUE,
  region varchar(30)
);
SELECT AddGeometryColumn('main','subregion','the_geom',4326,'MULTIPOLYGON',2);
INSERT INTO main.subregion(subregion,region,the_geom)
SELECT subregion, region_un, ST_MULTI(ST_Union(geom))
FROM ne.ne_10m_admin_0_map_subunits
WHERE subregion !~ 'Seven seas' AND name <> 'Midway Is.'
GROUP BY subregion,region_un
ORDER BY region_un, subregion
;
CREATE INDEX main_subregion_the_geom_idx ON main.continent USING GIST(the_geom);


CREATE TABLE main.country
(
  cd_country char(3) PRIMARY KEY CHECK (cd_country ~ '^[A-Z]{3}$'),
  name varchar(30) UNIQUE NOT NULL,
  federal boolean NOT NULL DEFAULT false
);

INSERT INTO main.country
SELECT
  CASE
    WHEN iso_a3 !~ '^[A-Z]{3}$' AND adm0_a3 ~ '^[A-Z]{3}$' THEN adm0_a3
    ELSE iso_a3
  END,
  name
FROM ne.ne_10m_admin_0_countries
WHERE ( (name=sovereignt OR name_long=sovereignt OR formal_en = sovereignt OR name_en=sovereignt) AND type IN ('Sovereign country','Country','Sovereignty') OR name IN ('Kosovo','Israel'));


ALTER TABLE ne.ne_10m_admin_0_countries DROP COLUMN  IF EXISTS cd_country;

ALTER TABLE ne.ne_10m_admin_0_countries ADD column cd_country char(3);
WITH a AS(
SELECT ogc_fid,
  CASE
    WHEN iso_a3 !~ '^[A-Z]{3}$' AND adm0_a3 ~ '^[A-Z]{3}$' THEN adm0_a3
    ELSE iso_a3
  END cd_country,
  name
FROM ne.ne_10m_admin_0_countries
WHERE ( (name=sovereignt OR name_long=sovereignt OR formal_en = sovereignt OR name_en=sovereignt) AND type IN ('Sovereign country','Country','Sovereignty') OR name IN ('Kosovo','Israel'))
)
UPDATE ne.ne_10m_admin_0_countries c SET cd_country=a.cd_country
FROM a
WHERE c.ogc_fid=a.ogc_fid;
