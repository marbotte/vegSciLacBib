library(stringdist)

fileTot<-"../../Data/SCOPUS/scopus.csv"
datab <- read.csv(fileTot, h = T, row.names = NULL,sep=",")
load(file="../dataExtraction/docId.RData")
df_id_doi<-na.omit(data.frame(docId,DOI=datab$DOI))
alreadyDownloaded<-gsub("\\.pdf","",dir("../../vegSciLacBib_export/PDF"))
df_id_doi2 <- df_id_doi[!df_id_doi$docId%in%alreadyDownloaded,]


### Finding and renaming downloaded pdf ###
files<-dir("../../vegSciLacBib_export/PDF_torename/")
sepInfo<-strsplit(gsub("\\.pdf$","",files)," - ")
journals<-sapply(sepInfo,function(x)x[1])
listJournals<-c("J Vegetation Science","Applied Vegetation Science","Vegetation Classification and Survey")
listJournalsSourceTitle<-c("Journal of Vegetation Science","Applied Vegetation Science","Vegetation Classification and Survey")
journalsOK<-listJournalsSourceTitle[match(journals,listJournals)]
year<-as.numeric(sapply(sepInfo,function(x)x[2]))
author<-sapply(sepInfo,function(x)x[3])
titlePart<-sapply(sepInfo,function(x)x[4])
#Match titles
matchTitle<-sapply(titlePart,function(x,listT){
  n<-nchar(x)
  tb<-substr(listT,1,n)
  return(match(x,tb))
},listT=datab$Title,USE.NAMES = F)

typeMatch<-character(length(matchTitle))
typeMatch[!is.na(matchTitle)]<-"exact"
A<-mapply(function(tit,yea,jour,dt){
  #browser()
  n<-nchar(tit)
  if(sum(dt$Year==yea&dt$Source.title==jour,na.rm=T)==0|nchar(tit)<10){return(NA)}
  subDt<-dt[dt$Year==yea&dt$Source.title==jour,]
  tb<-substr(subDt$Title,1,n)
  lvDist<-sapply(tb,function(tb_el,cur)stringdist(tolower(cur),tolower(tb_el)),cur=tit)
  first3<-order(lvDist)[1:3]
  #browser()
  return(which(dt$Year==yea&dt$Source.title==jour)[first3[lvDist[first3]<=6]])},
  as.list(titlePart[is.na(matchTitle)]),
  as.list(year[is.na(matchTitle)]),
  as.list(journalsOK[is.na(matchTitle)]),
  MoreArgs=list(dt=datab))
notOK<-which(sapply(A,function(x)length(x)==0|all(is.na(x))))
tabNotOk<-data.frame(journal=journalsOK[is.na(matchTitle)][notOK],
           year=year[is.na(matchTitle)][notOK],
           title=titlePart[is.na(matchTitle)][notOK],
           author=author[is.na(matchTitle)][notOK])
testTi<-tabNotOk$title[2]
testTi2<-datab[datab$Source.title==tabNotOk$journal[2]&datab$Year==tabNotOk$year[2]&grepl(tabNotOk$author[2],datab$Authors,fixed=T),]$Title
stringdist(testTi,substr(testTi2,1,nchar(testTi)))

stopifnot(all(sapply(A,length)<=1))
A[unlist(A)%in%matchTitle]
res2<-sapply(A,function(x)ifelse(length(x)==0,NA,x))
typeMatch[is.na(matchTitle)][!is.na(res2)]<-"partialMatch"
matchTitle[is.na(matchTitle)]<-res2
apply(
na.omit(cbind(
paste0("../../vegSciLacBib_export/PDF_torename/",files),
paste0("../../vegSciLacBib_export/PDF/",docId[matchTitle],".pdf")
)),1,function(x)file.rename(x[1],x[2]))


alreadyDownloaded<-gsub("\\.pdf","",dir("../../vegSciLacBib_export/PDF"))
df_id_doi2 <- df_id_doi[!df_id_doi$docId%in%alreadyDownloaded,]

# download of missing papers through firefox
lapply(paste0("firefox https://onlinelibrary.wiley.com/doi/pdfdirect/",df_id_doi2$DOI,"?download=true")[1:500],system)
