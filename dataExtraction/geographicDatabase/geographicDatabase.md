Making a geographic database for managing location extraction
================
Marius Bottin
2024-04-03

- [1 Finding and downloading locality
  database](#1-finding-and-downloading-locality-database)
- [2 Downloading and loading geographic
  data](#2-downloading-and-loading-geographic-data)
  - [2.1 GeoBoundaries](#21-geoboundaries)
  - [2.2 GADM](#22-gadm)
  - [2.3 Natural earth](#23-natural-earth)
  - [2.4 Geonames](#24-geonames)
  - [2.5 World languages](#25-world-languages)
- [3 Organizing the database](#3-organizing-the-database)
  - [3.1 Creating a Spatialite
    database](#31-creating-a-spatialite-database)
  - [3.2 Importing the data into
    postgres](#32-importing-the-data-into-postgres)
    - [3.2.1 Geoboundaries](#321-geoboundaries)
    - [3.2.2 GADM](#322-gadm)
    - [3.2.3 NaturalEarth](#323-naturalearth)
    - [3.2.4 Geonames](#324-geonames)
    - [3.2.5 World languages](#325-world-languages)
  - [3.3 Map units adm0](#33-map-units-adm0)
    - [3.3.1 Regions](#331-regions)
    - [3.3.2 Countries and territories
      (ADM0)](#332-countries-and-territories-adm0)
  - [3.4 Languages](#34-languages)
    - [3.4.1 simplified solution](#341-simplified-solution)
    - [3.4.2 List of languages and character
      sets](#342-list-of-languages-and-character-sets)
    - [3.4.3 Relation with countries](#343-relation-with-countries)
  - [3.6 Relations between adm0
    tables](#36-relations-between-adm0-tables)
  - [3.7 Adm1](#37-adm1)
  - [3.8 Adm2](#38-adm2)
  - [3.9 Adm3](#39-adm3)
  - [3.10 Adm4](#310-adm4)
  - [3.11 Adm5](#311-adm5)
- [4 Relations with natural earth](#4-relations-with-natural-earth)
  - [4.1 Closing the door before
    leaving](#41-closing-the-door-before-leaving)

# 1 Finding and downloading locality database

I have used the package `rnaturalearth` before, but it seems that the
package `rgeoboundaries` goes further in the geographic administrative
levels (adm2, adm3?). Note that it is on development phase and does not
seem to be in CRAN, you might want to install it with the package
`remote` installation functions.

After looking more in details the package `rgeoboundaries`, it seems
that various opensource dataset could be useful:

1.  naturalearth (<https://www.naturalearthdata.com/>, available in R
    through `rnaturalearth`): contains countries and states, and is
    accompanied by a quite complete dataset concerning names, continents
    and regions
2.  geoboundaries (<https://www.geoboundaries.org/>, available in R
    through `rgeoboundaties`): it is quite precise and goes further in
    terms of administrative levels
3.  gdam (<https://gadm.org/>) I have the feeling it is quite redundant
    with geoboundaries. It is accessible quite easily through a
    geopackage (SQLite database), I would tend to prefer this one than
    the former one
4.  geonames
    (<https://public.opendatasoft.com/explore/dataset/geonames-all-cities-with-a-population-1000/table/?disjunctive.cou_name_en&sort=name>).
    The best opensource database I found for cities (should be all
    cities with more than 1000 inhabitants), quite complete in terms of
    names in every language

# 2 Downloading and loading geographic data

``` r
require(sf)
```

    ## Loading required package: sf

    ## Linking to GEOS 3.11.2, GDAL 3.8.0, PROJ 9.2.1; sf_use_s2() is TRUE

``` r
require(RSQLite)
```

    ## Loading required package: RSQLite

``` r
if("params" %in% ls())
{
  dbms<-match.arg(params$dbms,c("Postgres","SQLite"))
}else{dbms <- "Postgres"}
st_changeGeomName<-function(sfobj,newName="geom")
{
  sf_col<-attr(sfobj,"sf_column")
  names(sfobj)[names(sfobj)==sf_col]<-newName
  st_geometry(sfobj)<-newName
  return(sfobj)
}
```

## 2.1 GeoBoundaries

``` r
if(!dir.exists("../../../Data/"))
{
  dir.create("../../../Data/")
}
if(!dir.exists("../../../Data/Geographic"))
{
  dir.create("../../../Data/Geographic")
}
if(!file.exists("../../../Data/Geographic/geoBoundariesCGAZ_ADM0.gpkg"))
{
download.file("https://github.com/wmgeolab/geoBoundaries/raw/main/releaseData/CGAZ/geoBoundariesCGAZ_ADM0.gpkg", destfile = "../../../Data/Geographic/geoBoundariesCGAZ_ADM0.gpkg")
download.file("https://github.com/wmgeolab/geoBoundaries/raw/main/releaseData/CGAZ/geoBoundariesCGAZ_ADM1.gpkg", destfile = "../../../Data/Geographic/geoBoundariesCGAZ_ADM1.gpkg")
download.file("https://github.com/wmgeolab/geoBoundaries/raw/main/releaseData/CGAZ/geoBoundariesCGAZ_ADM2.gpkg", destfile = "../../../Data/Geographic/geoBoundariesCGAZ_ADM2.gpkg")
}
geoBoundaries_adm0<-st_read("../../../Data/Geographic/geoBoundariesCGAZ_ADM0.gpkg")
```

    ## Reading layer `globalADM0' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/geoBoundariesCGAZ_ADM0.gpkg' 
    ##   using driver `GPKG'
    ## Simple feature collection with 218 features and 4 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -90 xmax: 180 ymax: 83.63339
    ## Geodetic CRS:  Undefined geographic SRS

``` r
geoBoundaries_adm1<-st_read("../../../Data/Geographic/geoBoundariesCGAZ_ADM1.gpkg")
```

    ## Reading layer `globalADM1' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/geoBoundariesCGAZ_ADM1.gpkg' 
    ##   using driver `GPKG'
    ## Simple feature collection with 3224 features and 5 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -89.99893 xmax: 180 ymax: 83.61593
    ## Geodetic CRS:  Undefined geographic SRS

``` r
geoBoundaries_adm2<-st_read("../../../Data/Geographic/geoBoundariesCGAZ_ADM2.gpkg")
```

    ## Reading layer `globalADM2' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/geoBoundariesCGAZ_ADM2.gpkg' 
    ##   using driver `GPKG'
    ## Simple feature collection with 49349 features and 5 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -89.99893 xmax: 180 ymax: 83.61593
    ## Geodetic CRS:  Undefined geographic SRS

``` r
st_crs(geoBoundaries_adm0)<-st_crs(geoBoundaries_adm1)<-st_crs(geoBoundaries_adm2)<-4326
```

    ## Warning: st_crs<- : replacing crs does not reproject data; use st_transform for
    ## that

    ## Warning: st_crs<- : replacing crs does not reproject data; use st_transform for
    ## that

    ## Warning: st_crs<- : replacing crs does not reproject data; use st_transform for
    ## that

``` r
geoBoundaries_db<-dbConnect(drv=SQLite(),"../../../Data/Geographic/geoBoundariesCGAZ_ADM0.gpkg")
```

## 2.2 GADM

``` r
if(!dir.exists("../../../Data/"))
{
  dir.create("../../../Data/")
}
if(!dir.exists("../../../Data/Geographic"))
{
  dir.create("../../../Data/Geographic")
}
if(!file.exists("../../../Data/Geographic/gadm_410-gpkg.zip"))
{
download.file("https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-gpkg.zip", destfile = "../../../Data/Geographic/gadm_410-gpkg.zip",method = "wget",quiet=T)
}
if(!file.exists("../../../Data/Geographic/gadm_410.gpkg"))
{
A<-unzip("../../../Data/Geographic/gadm_410-gpkg.zip")
file.copy(A,"../../../Data/Geographic/")
file.remove(A)
}
if(!file.exists("../../../Data/Geographic/gadm_410-gdb.zip"))
{
  download.file("https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-gdb.zip", destfile = "../../../Data/Geographic/gadm_410-gdb.zip",method = "wget",quiet=T)
}
if(!file.exists("../../../Data/Geographic/gadm_410.gdb"))
{
A<-unzip("../../../Data/Geographic/gadm_410-gdb.zip")
file.rename("gadm_410.gdb","../../../Data/Geographic/gadm_410.gdb")
}
st_layers("../../../Data/Geographic/gadm_410.gdb")
```

    ## Driver: OpenFileGDB 
    ## Available layers:
    ##   layer_name geometry_type features fields crs_name
    ## 1       gadm Multi Polygon   356508     54   WGS 84

``` r
gadm_gdb<-st_read("../../../Data/Geographic/gadm_410.gdb","gadm")
```

    ## Reading layer `gadm' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/gadm_410.gdb' 
    ##   using driver `OpenFileGDB'

    ## Warning in CPL_read_ogr(dsn, layer, query, as.character(options), quiet, : GDAL
    ## Message 1: organizePolygons() received a polygon with more than 100 parts.  The
    ## processing may be really slow.  You can skip the processing by setting
    ## METHOD=SKIP.

    ## Simple feature collection with 356508 features and 54 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -90 xmax: 180 ymax: 83.65833
    ## Geodetic CRS:  WGS 84

``` r
sf_col<-attr(gadm_gdb,"sf_column")
names(gadm_gdb)[names(gadm_gdb)==sf_col]<-"geom"
st_geometry(gadm_gdb)<-"geom"
colnames(gadm_gdb)<-tolower(colnames(gadm_gdb))
gadm<-st_read("../../../Data/Geographic/gadm_410.gpkg")
```

    ## Reading layer `gadm_410' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/gadm_410.gpkg' 
    ##   using driver `GPKG'
    ## Simple feature collection with 356508 features and 52 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -90 xmax: 180 ymax: 83.65833
    ## Geodetic CRS:  WGS 84

``` r
gadm_db<-dbConnect(drv=SQLite(),"../../../Data/Geographic/gadm_410.gpkg")
```

## 2.3 Natural earth

Naturalearth is available through the package rnaturalearth, but the way
they organize the dataset and the query makes it difficult to use for
our particular objectives, so maybe downloading the sqlite will make it
easier…

``` r
if(!dir.exists("../../../Data/"))
{
  dir.create("../../../Data/")
}
if(!dir.exists("../../../Data/Geographic"))
{
  dir.create("../../../Data/Geographic")
}
if(!file.exists("../../../Data/Geographic/natural_earth_vector.sqlite.zip"))
{
download.file("https://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip", destfile = "../../../Data/Geographic/natural_earth_vector.sqlite.zip",method = "wget",quiet=T)
}
if(!file.exists("../../../Data/Geographic/natural_earth_vector.sqlite"))
{
A<-unzip("../../../Data/Geographic/natural_earth_vector.sqlite.zip")
file.copy(A,"../../../Data/Geographic/")
file.remove(A)
}
ne_sf<-st_read("../../../Data/Geographic/natural_earth_vector.sqlite")
```

    ## Multiple layers are present in data source /home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/natural_earth_vector.sqlite, reading layer `ne_10m_admin_0_antarctic_claim_limit_lines'.
    ## Use `st_layers' to list all layer names and their type in a data source.
    ## Set the `layer' argument in `st_read' to read a particular layer.

    ## Warning in CPL_read_ogr(dsn, layer, query, as.character(options), quiet, :
    ## automatically selected the first layer in a data source containing more than
    ## one.

    ## Reading layer `ne_10m_admin_0_antarctic_claim_limit_lines' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/natural_earth_vector.sqlite' 
    ##   using driver `SQLite'
    ## Simple feature collection with 23 features and 5 fields
    ## Geometry type: LINESTRING
    ## Dimension:     XY
    ## Bounding box:  xmin: -150 ymin: -90 xmax: 160.1 ymax: -60
    ## Geodetic CRS:  WGS 84

``` r
ne_db<-dbConnect(SQLite(),"../../../Data/Geographic/natural_earth_vector.sqlite")
```

## 2.4 Geonames

``` r
if(!dir.exists("../../../Data/"))
{
  dir.create("../../../Data/")
}
if(!dir.exists("../../../Data/Geographic"))
{
  dir.create("../../../Data/Geographic")
}
if(!file.exists("../../../Data/Geographic/geonames-all-cities-with-a-population-1000.geojson"))
{
download.file("https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/geonames-all-cities-with-a-population-1000/exports/geojson?lang=en&timezone=America%2FBogota", destfile = "../../../Data/Geographic/geonames-all-cities-with-a-population-1000.geojson",method = "wget",quiet=T)
}
require(geojsonR)
```

    ## Loading required package: geojsonR

``` r
if(!file.exists("../../../Data/Geographic/geonames.RData"))
{
  geonames<-st_read("../../../Data/Geographic/geonames-all-cities-with-a-population-1000.geojson")
  save(geonames,file="../../../Data/Geographic/geonames.RData")
}else{
  load("../../../Data/Geographic/geonames.RData")
}
```

## 2.5 World languages

``` r
if(!dir.exists("../../../Data/"))
{
  dir.create("../../../Data/")
}
if(!dir.exists("../../../Data/Geographic"))
{
  dir.create("../../../Data/Geographic")
}
if(!file.exists("../../../Data/Geographic/soc_071_world_languages.zip"))
{
download.file("https://wri-public-data.s3.amazonaws.com/resourcewatch/soc_071_world_languages.zip", destfile = "../../../Data/Geographic/soc_071_world_languages.zip",method = "wget",quiet=T)
}
if(!file.exists("../../../Data/Geographic/World_Languages.shp"))
{
A<-unzip("../../../Data/Geographic/soc_071_world_languages.zip")
lapply(A,file.copy,to="../../../Data/Geographic/")
file.remove(A)
}
wl<-st_read("../../../Data/Geographic/World_Languages.shp")
```

    ## Reading layer `World_Languages' from data source 
    ##   `/home/marius/Travail/traitementDonnees/2024_bibliometrics_iavs/Data/Geographic/World_Languages.shp' 
    ##   using driver `ESRI Shapefile'
    ## Simple feature collection with 234 features and 15 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -55.9185 xmax: 180 ymax: 83.6341
    ## Geodetic CRS:  WGS 84

``` r
wl<-st_changeGeomName(wl)
colnames(wl)<-tolower(colnames(wl))
```

# 3 Organizing the database

The idea would be to make a database in which we could put together all
the names of the geographic objects that we might want to find in our
dataset fields. For it to be useful we need to be able to:

- understand the hierarchy of objects
  (region\<country\<state\<department\<city, sovereignt, )
- be able to link them to polygons or coordinates
- managing language and note which language is spoken locally (to be
  able to filter the local language and English in our search), as well
  as whether the alphabet is latin

## 3.1 Creating a Spatialite database

For this we will create a SQLite + Spatialite database. It might seem
weird but the best way I found to create an empty spatialite database is
QGIS (look on the left panel, a spatialite connection will be proposed
to you, right click on it and choose “Create a new database”).

``` r
fileGeogDb<-"../../../Data/Geographic/geog_db.sqlite"
existsDb<-file.exists(fileGeogDb)
if(dbms=="SQLite"){
if(!existsDb){stop("Please create an empty spatialite database in this folder:\n", normalizePath(dirname(fileGeogDb)), "\n and call it : ",basename(fileGeogDb),"\nYou may use the software you prefer, but QGIS works well!")}
geog <- dbConnect(SQLite(),"../../../Data/Geographic/geog_db.sqlite")
}
```

## 3.2 Importing the data into postgres

If the code here is run with the postgres option, you need to create a
postgres database with the `postgis` extension, and the `unaccent`
extension hosted in “localhost” and called worldGeog, with a
configuration which does not require a password to be send for
connecting (since the code is publicly shared).

``` r
require(RPostgreSQL)
```

    ## Loading required package: RPostgreSQL

    ## Loading required package: DBI

``` r
geog<- dbConnect(PostgreSQL(),dbname="worldGeog")
```

``` r
schemas<-dbGetQuery(geog,"SELECT DISTINCT schema_name FROM information_schema.schemata;")$schema_name
```

### 3.2.1 Geoboundaries

``` r
if(!"geoboundaries"%in%schemas){dbSendStatement(geog,"CREATE SCHEMA geoboundaries AUTHORIZATION CURRENT_USER;")}
if(!"global_adm0"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='geoboundaries'")$table_name)
{st_write(geoBoundaries_adm0,dsn=geog,layer=c("geoboundaries","global_adm0"))
dbSendStatement(geog,"UPDATE geoboundaries.global_adm0 SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
dbSendStatement(geog,"CREATE INDEX geoboundaries_global_adm0_geom_idx ON geoboundaries.global_adm0 USING GIST(geom)")  
}
if(!"global_adm1"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='geoboundaries'")$table_name)
{st_write(geoBoundaries_adm1,dsn=geog,layer=c("geoboundaries","global_adm1"))
dbSendStatement(geog,"UPDATE geoboundaries.global_adm1 SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
dbSendStatement(geog,"CREATE INDEX geoboundaries_global_adm1_geom_idx ON geoboundaries.global_adm1 USING GIST(geom)")  
}
if(!"global_adm2"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='geoboundaries'")$table_name)
{st_write(geoBoundaries_adm2,dsn=geog,layer=c("geoboundaries","global_adm2"))
dbSendStatement(geog,"UPDATE geoboundaries.global_adm2 SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
dbSendStatement(geog,"CREATE INDEX geoboundaries_global_adm2_geom_idx ON geoboundaries.global_adm2 USING GIST(geom)")  
}
```

### 3.2.2 GADM

``` r
if(!"gadm"%in%schemas){dbSendStatement(geog,"CREATE SCHEMA gadm AUTHORIZATION CURRENT_USER;")}
if(!"gadm_tot"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='gadm'")$table_name)
{st_write(gadm_gdb,dsn=geog,layer=c("gadm","gadm_tot"))
dbSendStatement(geog,"UPDATE gadm.gadm_tot SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
dbSendStatement(geog,"CREATE INDEX gadm_gadm_tot_geom_idx ON gadm.gadm_tot USING GIST(geom)")
dbSendStatement(geog,paste(readLines("./gadm_management.sql"),collapse="\n"))
}
#colText<-dbGetQuery(geog,"SELECT column_name FROM information_schema.columns WHERE table_name='gadm_tot' AND data_type='text'")$column_name
#cat(paste0(colText,"~'Null'"),sep=" OR ")
```

### 3.2.3 NaturalEarth

1We will not import antartic claims

``` r
#A small correction in the database:
#dbSendStatement(ne_db,"UPDATE geometry_columns SET srid=4326 WHERE srid IS NULL")
tables<-dbListTables(ne_db)
tablesOK<-tables[!tables%in%c("geometry_columns","spatial_ref_sys","sqlite_sequence","ne_10m_admin_0_names","ne_10m_admin_1_states_provinces_lines","ne_10m_admin_2_counties_lines","ne_10m_admin_2_label_points","ne_10m_rivers_north_america","ne_50m_admin_0_scale_rank","ne_50m_rivers_lake_centerlines") & grepl("_10m_",tables) & ! grepl("^ne_10m_admin_0_countries_[a-z]{3}",tables) & ! grepl("label",tables)]
tablesOK_spat<-tablesOK[tablesOK %in% dbReadTable(ne_db,"geometry_columns")$f_table_name]
#for(i in tablesOK_spat){st_read(ne_db,i)}
import_ne<-lapply(tablesOK_spat,st_read,dsn=ne_db)
names(import_ne)<-tablesOK_spat
for(i in 1:length(import_ne)){st_crs(import_ne[[i]])<-4326}
import_ne<-lapply(import_ne,st_changeGeomName)
if(!"ne"%in%schemas){dbSendStatement(geog,"CREATE SCHEMA ne AUTHORIZATION CURRENT_USER;")}
tables_ne<-dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='ne'")$table_name
for(i in names(import_ne))
{
  nameTable<-i
  if(nameTable %in% tables_ne){next}
  st_write(import_ne[[i]],dsn = geog,layer=c("ne",nameTable))
  dbSendStatement(geog,paste0("UPDATE ne.",nameTable," SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)"),)
  dbSendStatement(geog,paste0("CREATE INDEX IF NOT EXISTS ne_",nameTable,"_geom_idx ON ne.",nameTable," USING GIST(geom)"))
}
```

### 3.2.4 Geonames

``` r
geonames<-st_changeGeomName(geonames)
if(!"geonames"%in%schemas){dbSendStatement(geog,"CREATE SCHEMA geonames AUTHORIZATION CURRENT_USER;")}
tables_gn<-dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='geonames'")$table_name
if(!"cities"%in%tables_gn)
{
  geonames$alternate_names<-sapply(geonames$alternate_names,paste,collapse=", ")
  st_write(geonames,dsn = geog,layer=c("geonames","cities"))
  dbSendStatement(geog,"UPDATE geonames.cities SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
  dbSendStatement(geog,paste0("CREATE INDEX IF NOT EXISTS geonames_cities_geom_idx ON geonames.cities USING GIST(geom)"))
}
```

### 3.2.5 World languages

``` r
if(!"wl"%in%schemas){dbSendStatement(geog,"CREATE SCHEMA wl AUTHORIZATION CURRENT_USER;")}
tables_wl<-dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='wl'")$table_name
if(!"world_languages"%in%tables_wl)
{
  st_write(wl,dsn = geog,layer=c("wl","world_languages"))
  dbSendStatement(geog,"UPDATE wl.world_languages SET geom=ST_MakeValid(geom) WHERE NOT ST_ISVALID(geom)")
  dbSendStatement(geog,paste0("CREATE INDEX IF NOT EXISTS wl_world_languages_geom_idx ON wl.world_languages USING GIST(geom)"))
}
```

## 3.3 Map units adm0

The best way to have a base map for countries and regions is to use the
“ne_50m_admin_0_map_subunits” from naturalearth.

### 3.3.1 Regions

#### 3.3.1.1 natural earth

Concerning regions, we have various interesting classification of
regions in `naturalearth`:

Regions and subregions UN:

``` r
countries_ne<-dbReadTable(ne_db,"ne_10m_admin_0_countries")
table(countries_ne$region_un)
```

    ## 
    ##     Africa   Americas Antarctica       Asia     Europe    Oceania 
    ##         62         58          1         59         51         27

``` r
region_un<-countries_ne$region_un
subregions<-countries_ne$subregion
tapply(subregions,region_un,unique)
```

    ## $Africa
    ## [1] "Eastern Africa"          "Northern Africa"        
    ## [3] "Middle Africa"           "Southern Africa"        
    ## [5] "Western Africa"          "Seven seas (open ocean)"
    ## 
    ## $Americas
    ## [1] "South America"           "Central America"        
    ## [3] "Caribbean"               "Northern America"       
    ## [5] "Seven seas (open ocean)"
    ## 
    ## $Antarctica
    ## [1] "Antarctica"
    ## 
    ## $Asia
    ## [1] "South-Eastern Asia" "Western Asia"       "Southern Asia"     
    ## [4] "Eastern Asia"       "Central Asia"      
    ## 
    ## $Europe
    ## [1] "Western Europe"  "Eastern Europe"  "Northern Europe" "Southern Europe"
    ## 
    ## $Oceania
    ## [1] "Melanesia"                 "Australia and New Zealand"
    ## [3] "Polynesia"                 "Micronesia"               
    ## [5] "Seven seas (open ocean)"

Region WB (It is interesting for us because it includes Latin America &
Caribbean)

``` r
regions_wb<-countries_ne$region_wb
table(regions_wb)
```

    ## regions_wb
    ##                 Antarctica        East Asia & Pacific 
    ##                          2                         49 
    ##      Europe & Central Asia  Latin America & Caribbean 
    ##                         66                         52 
    ## Middle East & North Africa              North America 
    ##                         23                          4 
    ##                 South Asia         Sub-Saharan Africa 
    ##                          9                         53

#### 3.3.1.2 gadm

gadm uses a more classical definition of continents:

``` r
table(gadm$CONTINENT)
```

    ## 
    ##        Africa    Antarctica          Asia     Australia        Europe 
    ##         56835             8        160688           568        106252 
    ## North America       Oceania South America 
    ##         14573          5935         11649

``` r
tapply(gadm$SUBCONT,gadm$CONTINENT,table)
```

    ## $Africa
    ## 
    ##       
    ## 56835 
    ## 
    ## $Antarctica
    ## 
    ##   
    ## 8 
    ## 
    ## $Asia
    ## 
    ##        
    ## 160688 
    ## 
    ## $Australia
    ## 
    ##     
    ## 568 
    ## 
    ## $Europe
    ## 
    ##        
    ## 106252 
    ## 
    ## $`North America`
    ## 
    ##            Micronesia 
    ##      14572          1 
    ## 
    ## $Oceania
    ## 
    ##             Melanesia Micronesia  Polynesia 
    ##       5229        383        160        163 
    ## 
    ## $`South America`
    ## 
    ##       
    ## 11649

However there is no Central America in GADM. From Alaska to Panama, it
is considered North America:

``` r
sort(table(gadm$COUNTRY[gadm$CONTINENT=="North America"]))
```

    ## 
    ##                Clipperton Island                     Saint-Martin 
    ##                                1                                1 
    ##                     Sint Maarten United States Minor Outlying Isl 
    ##                                1                                1 
    ## Bonaire, Sint Eustatius and Saba        Saint Pierre and Miquelon 
    ##                                2                                2 
    ##                         Colombia                       Montserrat 
    ##                                3                                3 
    ##           British Virgin Islands                        Greenland 
    ##                                5                                5 
    ##                          Grenada                           Belize 
    ##                                5                                6 
    ##                   Cayman Islands Saint Vincent and the Grenadines 
    ##                                6                                6 
    ##         Turks and Caicos Islands              Antigua and Barbuda 
    ##                                6                                8 
    ##                         Dominica                      Saint Lucia 
    ##                               10                               10 
    ##                         Barbados                          Bermuda 
    ##                               11                               11 
    ##                          Jamaica            Saint Kitts and Nevis 
    ##                               14                               14 
    ##                         Anguilla             Virgin Islands, U.S. 
    ##                               18                               20 
    ##                          Bahamas                       Guadeloupe 
    ##                               32                               32 
    ##                       Martinique                 Saint-Barthélemy 
    ##                               32                               42 
    ##                      Puerto Rico                        Nicaragua 
    ##                               78                              139 
    ##               Dominican Republic                             Cuba 
    ##                              155                              168 
    ##                      El Salvador                         Honduras 
    ##                              266                              298 
    ##                        Guatemala                       Costa Rica 
    ##                              354                              485 
    ##                            Haiti                           Panama 
    ##                              542                              598 
    ##                           México                    United States 
    ##                             2459                             3142 
    ##                           Canada 
    ##                             5582

#### 3.3.1.3 Creating our region tables

Creating the main schema:

``` r
if(! "main" %in% dbGetQuery(geog,"SELECT schema_name FROM information_schema.schemata")$schema_name)
{dbSendStatement(geog,"CREATE SCHEMA main AUTHORIZATION CURRENT_USER;")}
```

    ## <PostgreSQLResult>

``` r
mainTables<-dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema = 'main'")$table_name
```

##### 3.3.1.3.1 Continent

Creating and populating continent:

``` r
if(! "continent" %in% mainTables)
{
dbSendStatement(geog,
"
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
")
}
```

    ## <PostgreSQLResult>

##### 3.3.1.3.2 World bank regions

Creating and populating the world bank region table

``` r
if(! "wb_region" %in% mainTables){
dbSendStatement(geog,
"
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
")  
}
```

    ## <PostgreSQLResult>

##### 3.3.1.3.3 subRegion/regions

Creating and populating the subregion table

``` r
if(! "subregion" %in% mainTables)
{
dbSendStatement(geog,
"
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
")
}
```

    ## <PostgreSQLResult>

### 3.3.2 Countries and territories (ADM0)

#### 3.3.2.1 Countries (and sovereignity)

First we need to list the potential sovereignities in natural earth maps

Note:

- su_a3 is unique and may serve as a PRIMARY KEY for subunits
- iso_a3 does not correspond to the countries
- To get the real country code, we need to join with the country table
  by names

We’ ll use a definition of countries which might be open to debate,
where United Kingdom, Kosovo, Northern Cyprus and Israel are included,
but not Antartica, Hong-Kong, Palestina or Western Sahara (I am sure you
could find other debatable examples in the data)…

``` r
if(!"country" %in% dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{
dbSendStatement(geog,
"
CREATE TABLE main.country
(
  cd_country char(3) PRIMARY KEY CHECK (cd_country ~ '^[A-Z]{3}$'),
  name varchar(30) UNIQUE NOT NULL
);
"
)
dbSendStatement(geog,
"INSERT INTO main.country
SELECT 
  CASE 
    WHEN iso_a3 !~ '^[A-Z]{3}$' AND adm0_a3 ~ '^[A-Z]{3}$' THEN adm0_a3
    ELSE iso_a3
  END,
  name
FROM ne.ne_10m_admin_0_countries  
WHERE ( (name=sovereignt OR name_long=sovereignt OR formal_en = sovereignt OR name_en=sovereignt) AND type IN ('Sovereign country','Country','Sovereignty') OR name IN ('Kosovo','Israel'))
"
)
if("cd_country" %in% dbGetQuery(geog,"SELECT column_name FROM information_schema.columns WHERE table_name='ne_10m_admin_0_countries'")$column_name)
{
  dbSendStatement(geog,"ALTER TABLE ne.ne_10m_admin_0_countries DROP COLUMN cd_country ")
}
dbSendStatement(geog,
"ALTER TABLE ne.ne_10m_admin_0_countries ADD column cd_country char(3);
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
"                
)
}
```

    ## <PostgreSQLResult>

``` r
dbGetQuery(geog,
"
SELECT name,sovereignt,type,sov_a3, iso_a3, type 
FROM ne.ne_10m_admin_0_countries  
WHERE ( (name=sovereignt OR name_long=sovereignt OR formal_en = sovereignt OR name_en=sovereignt) AND type IN ('Sovereign country','Country','Sovereignty') OR name IN ('Kosovo','Israel'))
ORDER BY sovereignt
"
           )
```

<div class="kable-table">

| name                     | sovereignt                       | type              | sov_a3 | iso_a3 | type              |
|:-------------------------|:---------------------------------|:------------------|:-------|:-------|:------------------|
| Afghanistan              | Afghanistan                      | Sovereign country | AFG    | AFG    | Sovereign country |
| Albania                  | Albania                          | Sovereign country | ALB    | ALB    | Sovereign country |
| Algeria                  | Algeria                          | Sovereign country | DZA    | DZA    | Sovereign country |
| Andorra                  | Andorra                          | Sovereign country | AND    | AND    | Sovereign country |
| Angola                   | Angola                           | Sovereign country | AGO    | AGO    | Sovereign country |
| Antigua and Barb.        | Antigua and Barbuda              | Sovereign country | ATG    | ATG    | Sovereign country |
| Argentina                | Argentina                        | Sovereign country | ARG    | ARG    | Sovereign country |
| Armenia                  | Armenia                          | Sovereign country | ARM    | ARM    | Sovereign country |
| Australia                | Australia                        | Country           | AU1    | AUS    | Country           |
| Austria                  | Austria                          | Sovereign country | AUT    | AUT    | Sovereign country |
| Azerbaijan               | Azerbaijan                       | Sovereign country | AZE    | AZE    | Sovereign country |
| Bahrain                  | Bahrain                          | Sovereign country | BHR    | BHR    | Sovereign country |
| Bangladesh               | Bangladesh                       | Sovereign country | BGD    | BGD    | Sovereign country |
| Barbados                 | Barbados                         | Sovereign country | BRB    | BRB    | Sovereign country |
| Belarus                  | Belarus                          | Sovereign country | BLR    | BLR    | Sovereign country |
| Belgium                  | Belgium                          | Sovereign country | BEL    | BEL    | Sovereign country |
| Belize                   | Belize                           | Sovereign country | BLZ    | BLZ    | Sovereign country |
| Benin                    | Benin                            | Sovereign country | BEN    | BEN    | Sovereign country |
| Bhutan                   | Bhutan                           | Sovereign country | BTN    | BTN    | Sovereign country |
| Bolivia                  | Bolivia                          | Sovereign country | BOL    | BOL    | Sovereign country |
| Bosnia and Herz.         | Bosnia and Herzegovina           | Sovereign country | BIH    | BIH    | Sovereign country |
| Botswana                 | Botswana                         | Sovereign country | BWA    | BWA    | Sovereign country |
| Brazil                   | Brazil                           | Sovereign country | BRA    | BRA    | Sovereign country |
| Brunei                   | Brunei                           | Sovereign country | BRN    | BRN    | Sovereign country |
| Bulgaria                 | Bulgaria                         | Sovereign country | BGR    | BGR    | Sovereign country |
| Burkina Faso             | Burkina Faso                     | Sovereign country | BFA    | BFA    | Sovereign country |
| Burundi                  | Burundi                          | Sovereign country | BDI    | BDI    | Sovereign country |
| Cabo Verde               | Cabo Verde                       | Sovereign country | CPV    | CPV    | Sovereign country |
| Cambodia                 | Cambodia                         | Sovereign country | KHM    | KHM    | Sovereign country |
| Cameroon                 | Cameroon                         | Sovereign country | CMR    | CMR    | Sovereign country |
| Canada                   | Canada                           | Sovereign country | CAN    | CAN    | Sovereign country |
| Central African Rep.     | Central African Republic         | Sovereign country | CAF    | CAF    | Sovereign country |
| Chad                     | Chad                             | Sovereign country | TCD    | TCD    | Sovereign country |
| Chile                    | Chile                            | Sovereign country | CHL    | CHL    | Sovereign country |
| China                    | China                            | Country           | CH1    | CHN    | Country           |
| Colombia                 | Colombia                         | Sovereign country | COL    | COL    | Sovereign country |
| Comoros                  | Comoros                          | Sovereign country | COM    | COM    | Sovereign country |
| Costa Rica               | Costa Rica                       | Sovereign country | CRI    | CRI    | Sovereign country |
| Croatia                  | Croatia                          | Sovereign country | HRV    | HRV    | Sovereign country |
| Cuba                     | Cuba                             | Sovereignty       | CU1    | CUB    | Sovereignty       |
| Cyprus                   | Cyprus                           | Sovereign country | CYP    | CYP    | Sovereign country |
| Czechia                  | Czechia                          | Sovereign country | CZE    | CZE    | Sovereign country |
| Dem. Rep. Congo          | Democratic Republic of the Congo | Sovereign country | COD    | COD    | Sovereign country |
| Denmark                  | Denmark                          | Country           | DN1    | DNK    | Country           |
| Djibouti                 | Djibouti                         | Sovereign country | DJI    | DJI    | Sovereign country |
| Dominica                 | Dominica                         | Sovereign country | DMA    | DMA    | Sovereign country |
| Dominican Rep.           | Dominican Republic               | Sovereign country | DOM    | DOM    | Sovereign country |
| Timor-Leste              | East Timor                       | Sovereign country | TLS    | TLS    | Sovereign country |
| Ecuador                  | Ecuador                          | Sovereign country | ECU    | ECU    | Sovereign country |
| Egypt                    | Egypt                            | Sovereign country | EGY    | EGY    | Sovereign country |
| El Salvador              | El Salvador                      | Sovereign country | SLV    | SLV    | Sovereign country |
| Eq. Guinea               | Equatorial Guinea                | Sovereign country | GNQ    | GNQ    | Sovereign country |
| Eritrea                  | Eritrea                          | Sovereign country | ERI    | ERI    | Sovereign country |
| Estonia                  | Estonia                          | Sovereign country | EST    | EST    | Sovereign country |
| eSwatini                 | eSwatini                         | Sovereign country | SWZ    | SWZ    | Sovereign country |
| Ethiopia                 | Ethiopia                         | Sovereign country | ETH    | ETH    | Sovereign country |
| Micronesia               | Federated States of Micronesia   | Sovereign country | FSM    | FSM    | Sovereign country |
| Fiji                     | Fiji                             | Sovereign country | FJI    | FJI    | Sovereign country |
| Finland                  | Finland                          | Country           | FI1    | FIN    | Country           |
| France                   | France                           | Country           | FR1    | -99    | Country           |
| Gabon                    | Gabon                            | Sovereign country | GAB    | GAB    | Sovereign country |
| Gambia                   | Gambia                           | Sovereign country | GMB    | GMB    | Sovereign country |
| Georgia                  | Georgia                          | Sovereign country | GEO    | GEO    | Sovereign country |
| Germany                  | Germany                          | Sovereign country | DEU    | DEU    | Sovereign country |
| Ghana                    | Ghana                            | Sovereign country | GHA    | GHA    | Sovereign country |
| Greece                   | Greece                           | Sovereign country | GRC    | GRC    | Sovereign country |
| Grenada                  | Grenada                          | Sovereign country | GRD    | GRD    | Sovereign country |
| Guatemala                | Guatemala                        | Sovereign country | GTM    | GTM    | Sovereign country |
| Guinea                   | Guinea                           | Sovereign country | GIN    | GIN    | Sovereign country |
| Guinea-Bissau            | Guinea-Bissau                    | Sovereign country | GNB    | GNB    | Sovereign country |
| Guyana                   | Guyana                           | Sovereign country | GUY    | GUY    | Sovereign country |
| Haiti                    | Haiti                            | Sovereign country | HTI    | HTI    | Sovereign country |
| Honduras                 | Honduras                         | Sovereign country | HND    | HND    | Sovereign country |
| Hungary                  | Hungary                          | Sovereign country | HUN    | HUN    | Sovereign country |
| Iceland                  | Iceland                          | Sovereign country | ISL    | ISL    | Sovereign country |
| India                    | India                            | Sovereign country | IND    | IND    | Sovereign country |
| Indonesia                | Indonesia                        | Sovereign country | IDN    | IDN    | Sovereign country |
| Iran                     | Iran                             | Sovereign country | IRN    | IRN    | Sovereign country |
| Iraq                     | Iraq                             | Sovereign country | IRQ    | IRQ    | Sovereign country |
| Ireland                  | Ireland                          | Sovereign country | IRL    | IRL    | Sovereign country |
| Israel                   | Israel                           | Disputed          | IS1    | ISR    | Disputed          |
| Italy                    | Italy                            | Sovereign country | ITA    | ITA    | Sovereign country |
| Côte d’Ivoire            | Ivory Coast                      | Sovereign country | CIV    | CIV    | Sovereign country |
| Jamaica                  | Jamaica                          | Sovereign country | JAM    | JAM    | Sovereign country |
| Japan                    | Japan                            | Sovereign country | JPN    | JPN    | Sovereign country |
| Jordan                   | Jordan                           | Sovereign country | JOR    | JOR    | Sovereign country |
| Kazakhstan               | Kazakhstan                       | Sovereignty       | KA1    | KAZ    | Sovereignty       |
| Kenya                    | Kenya                            | Sovereign country | KEN    | KEN    | Sovereign country |
| Kiribati                 | Kiribati                         | Sovereign country | KIR    | KIR    | Sovereign country |
| Kosovo                   | Kosovo                           | Disputed          | KOS    | -99    | Disputed          |
| Kuwait                   | Kuwait                           | Sovereign country | KWT    | KWT    | Sovereign country |
| Kyrgyzstan               | Kyrgyzstan                       | Sovereign country | KGZ    | KGZ    | Sovereign country |
| Laos                     | Laos                             | Sovereign country | LAO    | LAO    | Sovereign country |
| Latvia                   | Latvia                           | Sovereign country | LVA    | LVA    | Sovereign country |
| Lebanon                  | Lebanon                          | Sovereign country | LBN    | LBN    | Sovereign country |
| Lesotho                  | Lesotho                          | Sovereign country | LSO    | LSO    | Sovereign country |
| Liberia                  | Liberia                          | Sovereign country | LBR    | LBR    | Sovereign country |
| Libya                    | Libya                            | Sovereign country | LBY    | LBY    | Sovereign country |
| Liechtenstein            | Liechtenstein                    | Sovereign country | LIE    | LIE    | Sovereign country |
| Lithuania                | Lithuania                        | Sovereign country | LTU    | LTU    | Sovereign country |
| Luxembourg               | Luxembourg                       | Sovereign country | LUX    | LUX    | Sovereign country |
| Madagascar               | Madagascar                       | Sovereign country | MDG    | MDG    | Sovereign country |
| Malawi                   | Malawi                           | Sovereign country | MWI    | MWI    | Sovereign country |
| Malaysia                 | Malaysia                         | Sovereign country | MYS    | MYS    | Sovereign country |
| Maldives                 | Maldives                         | Sovereign country | MDV    | MDV    | Sovereign country |
| Mali                     | Mali                             | Sovereign country | MLI    | MLI    | Sovereign country |
| Malta                    | Malta                            | Sovereign country | MLT    | MLT    | Sovereign country |
| Marshall Is.             | Marshall Islands                 | Sovereign country | MHL    | MHL    | Sovereign country |
| Mauritania               | Mauritania                       | Sovereign country | MRT    | MRT    | Sovereign country |
| Mauritius                | Mauritius                        | Sovereign country | MUS    | MUS    | Sovereign country |
| Mexico                   | Mexico                           | Sovereign country | MEX    | MEX    | Sovereign country |
| Moldova                  | Moldova                          | Sovereign country | MDA    | MDA    | Sovereign country |
| Monaco                   | Monaco                           | Sovereign country | MCO    | MCO    | Sovereign country |
| Mongolia                 | Mongolia                         | Sovereign country | MNG    | MNG    | Sovereign country |
| Montenegro               | Montenegro                       | Sovereign country | MNE    | MNE    | Sovereign country |
| Morocco                  | Morocco                          | Sovereign country | MAR    | MAR    | Sovereign country |
| Mozambique               | Mozambique                       | Sovereign country | MOZ    | MOZ    | Sovereign country |
| Myanmar                  | Myanmar                          | Sovereign country | MMR    | MMR    | Sovereign country |
| Namibia                  | Namibia                          | Sovereign country | NAM    | NAM    | Sovereign country |
| Nauru                    | Nauru                            | Sovereign country | NRU    | NRU    | Sovereign country |
| Nepal                    | Nepal                            | Sovereign country | NPL    | NPL    | Sovereign country |
| Netherlands              | Netherlands                      | Country           | NL1    | NLD    | Country           |
| New Zealand              | New Zealand                      | Country           | NZ1    | NZL    | Country           |
| Nicaragua                | Nicaragua                        | Sovereign country | NIC    | NIC    | Sovereign country |
| Niger                    | Niger                            | Sovereign country | NER    | NER    | Sovereign country |
| Nigeria                  | Nigeria                          | Sovereign country | NGA    | NGA    | Sovereign country |
| N. Cyprus                | Northern Cyprus                  | Sovereign country | CYN    | -99    | Sovereign country |
| North Korea              | North Korea                      | Sovereign country | PRK    | PRK    | Sovereign country |
| North Macedonia          | North Macedonia                  | Sovereign country | MKD    | MKD    | Sovereign country |
| Norway                   | Norway                           | Sovereign country | NOR    | -99    | Sovereign country |
| Oman                     | Oman                             | Sovereign country | OMN    | OMN    | Sovereign country |
| Pakistan                 | Pakistan                         | Sovereign country | PAK    | PAK    | Sovereign country |
| Palau                    | Palau                            | Sovereign country | PLW    | PLW    | Sovereign country |
| Panama                   | Panama                           | Sovereign country | PAN    | PAN    | Sovereign country |
| Papua New Guinea         | Papua New Guinea                 | Sovereign country | PNG    | PNG    | Sovereign country |
| Paraguay                 | Paraguay                         | Sovereign country | PRY    | PRY    | Sovereign country |
| Peru                     | Peru                             | Sovereign country | PER    | PER    | Sovereign country |
| Philippines              | Philippines                      | Sovereign country | PHL    | PHL    | Sovereign country |
| Poland                   | Poland                           | Sovereign country | POL    | POL    | Sovereign country |
| Portugal                 | Portugal                         | Sovereign country | PRT    | PRT    | Sovereign country |
| Qatar                    | Qatar                            | Sovereign country | QAT    | QAT    | Sovereign country |
| Serbia                   | Republic of Serbia               | Sovereign country | SRB    | SRB    | Sovereign country |
| Congo                    | Republic of the Congo            | Sovereign country | COG    | COG    | Sovereign country |
| Romania                  | Romania                          | Sovereign country | ROU    | ROU    | Sovereign country |
| Russia                   | Russia                           | Sovereign country | RUS    | RUS    | Sovereign country |
| Rwanda                   | Rwanda                           | Sovereign country | RWA    | RWA    | Sovereign country |
| St. Kitts and Nevis      | Saint Kitts and Nevis            | Sovereign country | KNA    | KNA    | Sovereign country |
| Saint Lucia              | Saint Lucia                      | Sovereign country | LCA    | LCA    | Sovereign country |
| St. Vin. and Gren.       | Saint Vincent and the Grenadines | Sovereign country | VCT    | VCT    | Sovereign country |
| Samoa                    | Samoa                            | Sovereign country | WSM    | WSM    | Sovereign country |
| San Marino               | San Marino                       | Sovereign country | SMR    | SMR    | Sovereign country |
| São Tomé and Principe    | São Tomé and Principe            | Sovereign country | STP    | STP    | Sovereign country |
| Saudi Arabia             | Saudi Arabia                     | Sovereign country | SAU    | SAU    | Sovereign country |
| Senegal                  | Senegal                          | Sovereign country | SEN    | SEN    | Sovereign country |
| Seychelles               | Seychelles                       | Sovereign country | SYC    | SYC    | Sovereign country |
| Sierra Leone             | Sierra Leone                     | Sovereign country | SLE    | SLE    | Sovereign country |
| Singapore                | Singapore                        | Sovereign country | SGP    | SGP    | Sovereign country |
| Slovakia                 | Slovakia                         | Sovereign country | SVK    | SVK    | Sovereign country |
| Slovenia                 | Slovenia                         | Sovereign country | SVN    | SVN    | Sovereign country |
| Solomon Is.              | Solomon Islands                  | Sovereign country | SLB    | SLB    | Sovereign country |
| Somalia                  | Somalia                          | Sovereign country | SOM    | SOM    | Sovereign country |
| Somaliland               | Somaliland                       | Sovereign country | SOL    | -99    | Sovereign country |
| South Africa             | South Africa                     | Sovereign country | ZAF    | ZAF    | Sovereign country |
| South Korea              | South Korea                      | Sovereign country | KOR    | KOR    | Sovereign country |
| S. Sudan                 | South Sudan                      | Sovereign country | SDS    | SSD    | Sovereign country |
| Spain                    | Spain                            | Sovereign country | ESP    | ESP    | Sovereign country |
| Sri Lanka                | Sri Lanka                        | Sovereign country | LKA    | LKA    | Sovereign country |
| Sudan                    | Sudan                            | Sovereign country | SDN    | SDN    | Sovereign country |
| Suriname                 | Suriname                         | Sovereign country | SUR    | SUR    | Sovereign country |
| Sweden                   | Sweden                           | Sovereign country | SWE    | SWE    | Sovereign country |
| Switzerland              | Switzerland                      | Sovereign country | CHE    | CHE    | Sovereign country |
| Syria                    | Syria                            | Sovereign country | SYR    | SYR    | Sovereign country |
| Taiwan                   | Taiwan                           | Sovereign country | TWN    | TWN    | Sovereign country |
| Tajikistan               | Tajikistan                       | Sovereign country | TJK    | TJK    | Sovereign country |
| Thailand                 | Thailand                         | Sovereign country | THA    | THA    | Sovereign country |
| Bahamas                  | The Bahamas                      | Sovereign country | BHS    | BHS    | Sovereign country |
| Togo                     | Togo                             | Sovereign country | TGO    | TGO    | Sovereign country |
| Tonga                    | Tonga                            | Sovereign country | TON    | TON    | Sovereign country |
| Trinidad and Tobago      | Trinidad and Tobago              | Sovereign country | TTO    | TTO    | Sovereign country |
| Tunisia                  | Tunisia                          | Sovereign country | TUN    | TUN    | Sovereign country |
| Turkey                   | Turkey                           | Sovereign country | TUR    | TUR    | Sovereign country |
| Turkmenistan             | Turkmenistan                     | Sovereign country | TKM    | TKM    | Sovereign country |
| Tuvalu                   | Tuvalu                           | Sovereign country | TUV    | TUV    | Sovereign country |
| Uganda                   | Uganda                           | Sovereign country | UGA    | UGA    | Sovereign country |
| Ukraine                  | Ukraine                          | Sovereign country | UKR    | UKR    | Sovereign country |
| United Arab Emirates     | United Arab Emirates             | Sovereign country | ARE    | ARE    | Sovereign country |
| United Kingdom           | United Kingdom                   | Country           | GB1    | GBR    | Country           |
| Tanzania                 | United Republic of Tanzania      | Sovereign country | TZA    | TZA    | Sovereign country |
| United States of America | United States of America         | Country           | US1    | USA    | Country           |
| Uruguay                  | Uruguay                          | Sovereign country | URY    | URY    | Sovereign country |
| Uzbekistan               | Uzbekistan                       | Sovereign country | UZB    | UZB    | Sovereign country |
| Vanuatu                  | Vanuatu                          | Sovereign country | VUT    | VUT    | Sovereign country |
| Vatican                  | Vatican                          | Sovereign country | VAT    | VAT    | Sovereign country |
| Venezuela                | Venezuela                        | Sovereign country | VEN    | VEN    | Sovereign country |
| Vietnam                  | Vietnam                          | Sovereign country | VNM    | VNM    | Sovereign country |
| Yemen                    | Yemen                            | Sovereign country | YEM    | YEM    | Sovereign country |
| Zambia                   | Zambia                           | Sovereign country | ZMB    | ZMB    | Sovereign country |
| Zimbabwe                 | Zimbabwe                         | Sovereign country | ZWE    | ZWE    | Sovereign country |

</div>

At some point we will have to correct that:

``` sql
SELECT name, name_long, formal_en, name_en FROM main.country c LEFT JOIN ne.ne_10m_admin_0_countries USING (name) WHERE c.name ~ '\.'
```

<div class="knitsql-table">

| name                 | name_long                        | formal_en                           | name_en                             |
|:---------------------|:---------------------------------|:------------------------------------|:------------------------------------|
| Dem. Rep. Congo      | Democratic Republic of the Congo | Democratic Republic of the Congo    | Democratic Republic of the Congo    |
| Bosnia and Herz.     | Bosnia and Herzegovina           | Bosnia and Herzegovina              | Bosnia and Herzegovina              |
| Solomon Is.          | Solomon Islands                  | NA                                  | Solomon Islands                     |
| St. Vin. and Gren.   | Saint Vincent and the Grenadines | Saint Vincent and the Grenadines    | Saint Vincent and the Grenadines    |
| S. Sudan             | South Sudan                      | Republic of South Sudan             | South Sudan                         |
| Antigua and Barb.    | Antigua and Barbuda              | Antigua and Barbuda                 | Antigua and Barbuda                 |
| Central African Rep. | Central African Republic         | Central African Republic            | Central African Republic            |
| Dominican Rep.       | Dominican Republic               | Dominican Republic                  | Dominican Republic                  |
| N. Cyprus            | Northern Cyprus                  | Turkish Republic of Northern Cyprus | Turkish Republic of Northern Cyprus |
| Eq. Guinea           | Equatorial Guinea                | Republic of Equatorial Guinea       | Equatorial Guinea                   |
| Marshall Is.         | Marshall Islands                 | Republic of the Marshall Islands    | Marshall Islands                    |
| St. Kitts and Nevis  | Saint Kitts and Nevis            | Federation of Saint Kitts and Nevis | Saint Kitts and Nevis               |

12 records

</div>

which also might cause problems in sovereignity attribution such as:

``` sql
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
)
SELECT s.name,s.sovereignt,n.cd_country
FROM ne.ne_10m_admin_0_map_subunits s
LEFT JOIN names n ON s.sovereignt=n.name
WHERE n.cd_country IS NULL
ORDER BY s.sovereignt
```

<div class="knitsql-table">

| name                    | sovereignt                   | cd_country |
|:------------------------|:-----------------------------|:-----------|
| S. Orkney Is.           | Antarctica                   | NA         |
| Peter I I.              | Antarctica                   | NA         |
| Antarctica              | Antarctica                   | NA         |
| Bajo Nuevo Bank         | Bajo Nuevo Bank (Petrel Is.) | NA         |
| Bir Tawil               | Bir Tawil                    | NA         |
| Brazilian I.            | Brazilian Island             | NA         |
| Cyprus U.N. Buffer Zone | Cyprus No Mans Area          | NA         |
| Siachen Glacier         | Kashmir                      | NA         |
| N. Cyprus               | Northern Cyprus              | NA         |
| Scarborough Reef        | Scarborough Reef             | NA         |

Displaying records 1 - 10

</div>

#### 3.3.2.2 Geographic units

Small issue:

``` sql
SELECT name, ARRAY_AGG(adm0_a3) adm0_a3,ARRAY_AGG(su_a3) su_a3, count(*) FROM ne.ne_10m_admin_0_map_subunits GROUP BY name HAVING count(*)>1;
```

<div class="knitsql-table">

| name        | adm0_a3   | su_a3     | count |
|:------------|:----------|:----------|------:|
| Russia      | {RUS,RUS} | {RUA,RUE} |     2 |
| South Korea | {KOR,KOR} | {KOX,KXI} |     2 |

2 records

</div>

Will be resolved through a st_union (dissolve) process. For Russia,
naturalearth had separated the european and Asian regions of Russia, for
South Korea, they separated the islands and the mainland.

``` r
if(!"adm0_geounit" %in% dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{
if("cd_geounit" %in% dbGetQuery(geog,"SELECT column_name FROM information_schema.columns WHERE table_name='ne_10m_admin_0_map_subunits'")$column_name)
{dbSendStatement(geog,"ALTER TABLE ne.ne_10m_admin_0_map_subunits DROP COLUMN cd_geounit")}
dbSendStatement(geog,paste(readLines("./adm0_geounit.sql"),collapse="\n"))
}
```

    ## <PostgreSQLResult>

## 3.4 Languages

Now that we have the countries and territories, we can join them with
the language database

------------------------------------------------------------------------

**Note**:

While it would have been cleaner to work on the language and character
sets, the process of integrating official languages and their
corresponding character sets seems very complicated for not much
results.

**For now the plan will be: integrating english, french, spanish,
german, portuguese, italian, neerlandese excluding all strings which
does not have at least a “$$a-z$$” character to filter the latin
alphabet.**

So we keep the first test made in the subsections, but we will not use
them for now!

------------------------------------------------------------------------

### 3.4.1 simplified solution

(english, french, spanish, german, portuguese, italian, dutch)

``` r
if(!"lang" %in% dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{
dbSendStatement(geog,
"
CREATE TABLE main.lang
(
  cd_lang char(2) PRIMARY KEY,
  lang varchar(20) UNIQUE
);
INSERT INTO main.lang
VALUES
('en','English'),
('fr','French'),
('es','Spanish'),
('pt','Portuguese'),
('de','German'),
('nl','Dutch'),
('it','Italian');
CREATE TABLE main.country_lang
(
  cd_country char(3) REFERENCES main.country(cd_country) NOT NULL,
  cd_lang char(2) REFERENCES main.lang(cd_lang) NOT NULL,
  UNIQUE(cd_country,cd_lang)
);
INSERT INTO main.country_lang
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
UNION
SELECT sovereignt,c.cd_country
FROM main.country c
LEFT JOIN ne.ne_10m_admin_0_countries nec USING (name)
), a as(
SELECT country,sovereignt,first_offi lang
FROM wl.world_languages
UNION ALL
SELECT country,sovereignt,second_off lang
FROM wl.world_languages
UNION ALL
SELECT country,sovereignt,third_offi  lang
FROM wl.world_languages
), corr AS(
SELECT 
  CASE
    WHEN sovereignt='Guinea Bissau' THEN 'Guinea-Bissau'
    WHEN sovereignt='Republic of Congo' THEN 'Republic of the Congo'
    WHEN sovereignt='Sao Tome and Principe' THEN 'São Tomé and Principe'
    WHEN sovereignt='Swaziland' THEN 'eSwatini'
    ELSE sovereignt
  END sovereignt,
  lang
FROM a
WHERE lang IN (SELECT lang FROM main.lang)
)
SELECT DISTINCT cd_country,cd_lang
FROM corr c
LEFT JOIN names n ON c.sovereignt=n.name
LEFT JOIN main.lang USING (lang)
ORDER BY cd_country
;
CREATE INDEX main_country_lang_cd_country ON main.country_lang(cd_country);
CREATE INDEX main_country_lang_cd_lang ON main.country_lang(cd_lang);"
)
}
```

    ## <PostgreSQLResult>

### 3.4.2 List of languages and character sets

There is a file on github with the language codes, however I am not sure
it is worth managing all this information:

``` r
if(!file.exists("../../../Data/Geographic/language-codes-full.csv"))
{
  download.file("https://github.com/datasets/language-codes/blob/master/data/language-codes-full.csv",destfile = "../../../Data/Geographic/language-codes-full.csv")
}
```

``` sql
WITH a as(
SELECT first_offi language, count(*) nb_offi--,1 AS lang_ord
FROM wl.world_languages
WHERE first_offi IS NOT NULL
GROUP BY first_offi
UNION ALL
SELECT second_off language, count(*) nb_offi--,2 AS lang_ord
FROM wl.world_languages
WHERE second_off IS NOT NULL
GROUP BY second_off
UNION ALL
SELECT third_offi  language, count(*) nb_offi--,3 AS lang_ord
FROM wl.world_languages
WHERE third_offi IS NOT NULL 
GROUP BY third_offi
)
SELECT language, SUM(nb_offi)
FROM a
GROUP BY language
ORDER BY sum(nb_offi) DESC
```

<div class="knitsql-table">

| language   | sum |
|:-----------|----:|
| English    |  80 |
| French     |  40 |
| Arabic     |  26 |
| Spanish    |  21 |
| Portuguese |   8 |
| German     |   6 |
| Dutch      |   5 |
| Russian    |   4 |
| Italian    |   4 |
| Indigenous |   4 |

Displaying records 1 - 10

</div>

### 3.4.3 Relation with countries

Checking whether we can join the countries:

``` sql
WITH names AS(
SELECT name,c.cd_geounit
FROM main.adm0_geounit c
LEFT JOIN ne.ne_10m_admin_0_map_subunits nec ON c.geounit=nec.name
UNION
SELECT subunit,c.cd_geounit
FROM main.adm0_geounit c
LEFT JOIN ne.ne_10m_admin_0_map_subunits nec ON c.geounit=nec.name
UNION
SELECT name_en,c.cd_geounit
FROM main.adm0_geounit c
LEFT JOIN ne.ne_10m_admin_0_map_subunits nec ON c.geounit=nec.name
UNION
SELECT formal_en,c.cd_geounit
FROM main.adm0_geounit c
LEFT JOIN ne.ne_10m_admin_0_map_subunits nec ON c.geounit=nec.name
), a AS(
SELECT country, sovereignt, cd_geounit
FROM wl.world_languages wl
LEFT JOIN names n ON wl.country=n.name
), b AS(
SELECT DISTINCT ON (cd_geounit) cd_geounit,country
FROM a
WHERE country IS NOT NULL AND cd_geounit IS NOT NULL
)
SELECT cd_geounit,geounit FROM main.adm0_geounit WHERE NOT cd_geounit IN (SELECT cd_geounit FROM b)
```

<div class="knitsql-table">

| cd_geounit | geounit                 |
|:-----------|:------------------------|
| GEA        | Adjara                  |
| WSB        | Akrotiri                |
| USK        | Alaska                  |
| GGA        | Alderney                |
| GNA        | Annobón                 |
| ATB        | Antarctica              |
| LQI        | Palmyra Atoll           |
| INA        | Andaman Is.             |
| ACA        | Antigua                 |
| ATC        | Ashmore and Cartier Is. |

Displaying records 1 - 10

</div>

So the join is complicated, we will have to divide the cases

CASE 1: the languages are all the same in a “sovereignt”

``` sql
With a AS(
  SELECT 
    sovereignt,
    COUNT(DISTINCT first_offi),
    COUNT(DISTINCT second_off),
    COUNT(DISTINCT third_offi) 
  FROM wl.world_languages 
  GROUP BY sovereignt 
  HAVING 
    COUNT(DISTINCT first_offi)<2 AND
    COUNT(DISTINCT second_off)<2 AND
    COUNT(DISTINCT third_offi)<2
)
SELECT COUNT(DISTINCT sovereignt)
FROM a
```

<div class="knitsql-table">

| count |
|------:|
|   191 |

1 records

</div>

CASE 2: in a same sovereignt, different territories may have different
languages:

``` sql
With a AS(
  SELECT 
    sovereignt,
    COUNT(DISTINCT first_offi),
    COUNT(DISTINCT second_off),
    COUNT(DISTINCT third_offi) 
  FROM wl.world_languages 
  GROUP BY sovereignt 
  HAVING 
    COUNT(DISTINCT first_offi)>1 OR
    COUNT(DISTINCT second_off)>1 OR
    COUNT(DISTINCT third_offi)>1
)
SELECT sovereignt
FROM a
```

<div class="knitsql-table">

| sovereignt               |
|:-------------------------|
| China                    |
| Denmark                  |
| Israel                   |
| Netherlands              |
| New Zealand              |
| United Kingdom           |
| United States of America |

7 records

</div>

<!--
&#10;```sql connection=geog
SELECT g.geounit, wl.country 
FROM wl.world_languages wl
LEFT JOIN main.adm0_geounit g ON ST_intersects(g.the_geom,wl.geom)
LEFT JOIN main.country c ON g.sovereign=
ORDER BY wl.country

–\>

    ## [3.5 Regions, country and geounit names]{data-rmarkdown-temporarily-recorded-id="regions-country-and-geounit-names"}

    ``` r
    if(!"country_names" %in% dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name | ! "adm0_names"  %in% dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
    {
      dbSendStatement(geog,paste(readLines(con = "./country_geounit_names_ne.sql"),collapse="\n"))
    }

    ## <PostgreSQLResult>

## 3.6 Relations between adm0 tables

``` r
if(!"adm0_to_geounit"%in%dbListTables(geog))
{dbSendStatement(geog,paste(readLines("./relations_adm0.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

## 3.7 Adm1

``` r
if(!"adm1"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{dbSendStatement(geog,paste(readLines("./adm1.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

## 3.8 Adm2

``` r
if(!"adm2"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{dbSendStatement(geog,paste(readLines("./adm2.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

## 3.9 Adm3

``` r
if(!"adm3"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{dbSendStatement(geog,paste(readLines("./adm3.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

## 3.10 Adm4

``` r
if(!"adm4"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{dbSendStatement(geog,paste(readLines("./adm4.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

## 3.11 Adm5

``` r
if(!"adm5"%in%dbGetQuery(geog,"SELECT table_name FROM information_schema.tables WHERE table_schema='main'")$table_name)
{dbSendStatement(geog,paste(readLines("./adm5.sql"),collapse="\n"))}
```

    ## <PostgreSQLResult>

# 4 Relations with natural earth

``` r
dbSendStatement(geog,paste(readLines("./ne_relations_adm1_adm2.sql"),collapse="\n"))
```

## 4.1 Closing the door before leaving

``` r
dbDisconnect(ne_db)
dbDisconnect(gadm_db)
dbDisconnect(geoBoundaries_db)
dbDisconnect(geog)
```

    ## [1] TRUE
