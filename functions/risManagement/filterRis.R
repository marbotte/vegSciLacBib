writeRis <-function(extractedRis,filename=tempfile())
{
  writeLines(extractedRis$raw,con=filename)
  return(filename)
}

filterRis <- function(extractedRis, idToSupp, writeFile=NA)
{
  filteredRis <- list()
  linesToSupp <- extractedRis$lineRegId%in%idToSupp
  filteredRis$fieldName <- extractedRis$fieldName[!linesToSupp]
  if("raw"%in%names(extractedRis)){
    filteredRis$raw <- extractedRis$raw[!linesToSupp]
  }
  if("content"%in%names(extractedRis)){
    filteredRis$content <- extractedRis$content[!linesToSupp]
  }
  filteredRis$lineRegId<-extractedRis$lineRegId[!linesToSupp]
  filteredRis$registers<- data.frame(
    id=unique(filteredRis$lineRegId),
    begin=tapply(1:length(filteredRis$lineRegId),filteredRis$lineRegId,min),
    end=tapply(1:length(filteredRis$lineRegId),filteredRis$lineRegId,max)
  )
  filteredRis$nbRecords <- nrow(filteredRis$registers)
  if(!"nbDeleted"%in%names(extractedRis)){
    filteredRis$nbDeleted <- extractedRis$nbRecords-filteredRis$nbRecords
  }else{
    filteredRis$nbDeleted <- extractedRis$nbDeleted+(extractedRis$nbRecords-filteredRis$nbRecords)
  }
  if(any(!names(extractedRis) %in% names(filteredRis)))
  {filteredRis<-c(filteredRis,extractedRis[!names(extractedRis) %in% names(filteredRis)])}
  if(!is.na(writeFile))
  {
    print(paste(writeRis(filteredRis,filename=writeFile),"written!"))
  }
  return(filteredRis)
}