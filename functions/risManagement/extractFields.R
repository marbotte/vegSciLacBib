
# There are various ways to use the RIS norm in the platforms which export them. For example, why the norm states that Abstract of articles should be put in the "N2" field, Scopus and web of science put it in the "AB" field
# Therefore, in order to keep the data from the original file as untouched as possible, we put a table "synoFields" in the object and we apply the synonymy in the object only at the moment of extracting fields

synoFields <- function(extractedRis,fieldFrom=c("T1","N2"),fieldTo=c("TI","AB"))
{
  tab<-data.frame(from=fieldFrom,to=fieldTo)
  if("synoFields" %in% names(extractedRis))
  {extractedRis$synoFields<-unique(rbind.data.frame(extractedRis$synoFields,tab))}
  else{
    extractedRis$synoFields <- tab 
  }
  return(extractedRis)
}

extractFields <- function(extractedRis, fields=c("DO","TI","AU"),sep="|")
{
  # Apply synonyms
  if("synoFields" %in% names(extractedRis))
  {
    for(i in 1:nrow(extractedRis$synoFields))
    {
      extractedRis$fieldName <- sub(paste0("^", extractedRis$synoFields$from[i]), extractedRis$synoFields$to[i], extractedRis$fieldName)
    }
  }
  # Are fields unique by record
  tab <- data.frame(
    fieldName=extractedRis$fieldName[!is.na(extractedRis$fieldName)&extractedRis$fieldName%in%fields],
    record=extractedRis$lineRegId[!is.na(extractedRis$fieldName)&extractedRis$fieldName%in%fields],
    content=extractedRis$content[!is.na(extractedRis$fieldName)&extractedRis$fieldName%in%fields])
  f_multi<-sapply(by(tab[c("fieldName","record")],INDICES = tab$fieldName,FUN = duplicated),any)
  #
  reg<-extractedRis$registers$id
  no_multi_field <- names(f_multi)[!f_multi]
  tab2<-tab[tab$fieldName%in%no_multi_field,]
  if(any(f_multi)){
    multi_field <- names(f_multi)[f_multi]
    names(multi_field)<-multi_field
    dataMF <- lapply(multi_field,function(f,t,s)
      tapply(t$content[t$fieldName==f],t$record[t$fieldName==f],paste,collapse=s)
    ,t=tab,s=sep)
    dataMF_tab<-data.frame(
      fieldName=rep(names(dataMF),sapply(dataMF,length)),
      record=as.numeric(unlist(lapply(dataMF,names))),
      content=unlist(dataMF)
      )
  tab2 <- rbind(tab2,dataMF_tab)
  }
  COLS <- unique(as.character(tab2$fieldName))
  ROWS <- unique(as.character(extractedRis$registers$id))
  arr.which<-cbind(row=match(as.character(tab2$record),ROWS), col=match(tab2$fieldName, COLS))
  res <- matrix(nrow=length(ROWS),ncol=length(COLS),dimnames=list(as.character(ROWS),COLS))
  res[arr.which]<-tab2$content
  return(as.data.frame(cbind(id=ROWS,res)))
}

