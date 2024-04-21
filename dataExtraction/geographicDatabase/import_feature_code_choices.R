require(RPostgreSQL)
geog<-dbConnect(PostgreSQL(),dbname='worldGeog')
dbWriteTable(geog,value=read.csv("../../../Data/Geographic/geonames_feature_codes.csv"),c("tmp","feature_code_choices"),overwrite=T)
dbDisconnect(geog)
