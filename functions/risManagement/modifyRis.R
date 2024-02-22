#Change field name----
# In most case, it is possible to use the synoFields function to add synonyms between fields in the object and not to modify the object from the original file.
# However, in cases where a field name is abusively used and causes problems in the data management, we may use the following function

changeFieldName<-function(risObj,from,to,...)
{
  linesConcerned <- grep(paste0("^",from),risObj$fieldName)
  risObj$raw[linesConcerned]<-gsub(paste0("^[﻿ ]?",from),to,risObj$raw[linesConcerned])
  # There will be much cleaner and efficient to manage all parts of the ris object, but as a programmation shortcut, we may write the modified raw part and read it again
  tmpFile<-writeRis(risObj)
  res<-read_ris(tmpFile,...)
  if(any(!names(risObj) %in% names(res)))
  {res<-c(res,risObj[!names(risObj) %in% names(res)])}
  return(res)
}

# Generic function to insert values in a vector at determined indexes of the vector in an efficient way ----

insertValuesAtIdx <- function(vec,value,idx)
{
  res<-vector(mode=mode(vec),length = length(vec)+length(idx))
  res[-idx]<-vec
  res[idx]<-value
  return(res)
}

# Adding a nonexistant field in a Ris file ----

addField <- function(risObj,fieldName,values)
{
  if(fieldName %in% risObj$fieldName){stop("field",fieldName,"already is present in the ris object")}
  stopifnot(length(values)==risObj$nbRecords)
  endRecords<-which(risObj$fieldName=="ER")
  idx<-endRecords + cumsum(!is.na(values)) - 1
  res<-list()
  linesToAdd<-paste0(fieldName," - ",values)
  if("raw" %in% names(risObj))
  {
    res$raw <- insertValuesAtIdx(risObj$raw,linesToAdd[!is.na(values)],idx[!is.na(values)])
  }
  if("fieldName" %in% names(risObj))
  {
    res$fieldName <- insertValuesAtIdx(risObj$fieldName, rep(fieldName,sum(!is.na(values))),idx[!is.na(values)])
  }
  if("content" %in% names(risObj))
  {
    res$content <- insertValuesAtIdx(risObj$content, values[!is.na(values)], idx[!is.na(values)])
  }
  res$lineRegId <- insertValuesAtIdx(risObj$lineRegId,risObj$registers$id[!is.na(values)],idx[!is.na(values)])
  res$registers <- data.frame(id=unique(res$lineRegId),
                              begin=tapply(1:length(res$raw),res$lineRegId,min),
                              end=tapply(1:length(res$raw),res$lineRegId,max))
  if(any(!names(risObj) %in% names(res)))
  {res<-c(res,risObj[!names(risObj) %in% names(res)])}
  return(res)
}
