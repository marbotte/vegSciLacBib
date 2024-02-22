# This function allows to read a ris files with the following obligatory characteristics:
# - no empty lines except the ones between registers
# - always at least an empty line between 2 registers
# - all registers have one and only one title field, except for abstract which might be on more than one line
# - each line beginning is the name of a field

regexiseField<-function(field){
  return(paste0("^(",field,") +-(.*)$"))
}


read_ris <- function(risFile,keepCompleteRaw = T, extractFields = T, title="TI",multiLine=c("AB"))
{
  fileLines <- readLines(risFile)
  emptyLines <- grep("^[::blank::]*$",fileLines)
  lineTypes <- grep("TY +-.*",fileLines)
  sep_registers<-lineTypes[-1]-1
  #sep_registers <- numeric()
  #for(i in 1:length(emptyLines)){
  #  if(i != length(emptyLines) && emptyLines[i]!=(emptyLines[i+1]-1))
  #    sep_registers <- c(sep_registers,emptyLines[i])
  #}
  titleLines<-grep(regexiseField(title),fileLines)
  abstractLines<-grep(regexiseField("AB"),fileLines)
  #stopifnot(length(sep_registers)+1==length(titleLines))
  registers <- data.frame(
    id=1:(length(sep_registers)+1),
    begin=c(1,sep_registers+1),
    end=c(sep_registers,length(fileLines))
  )
  idLines <- rep(registers$id, (registers$end-registers$begin)+1)
  lineFields <- grepl("^[﻿ ]?([A-Z][A-Za-z0-9]) +-.*$",fileLines)
  lineOtherFields <- grepl("^Total Times Cited: +[0-9]+$",fileLines) | grepl("^Cited Reference Count: +[0-9]+$",fileLines)
  emptyLinesBool <- grepl("^[::blank::]*$",fileLines)
  fieldName <- rep(NA,length(fileLines))
  fieldName[lineFields] <- gsub("^[﻿ ]?([A-Z][A-Za-z0-9]) +-.*$","\\1",fileLines[lineFields])
  if(!all(is.na(multiLine)) & length(multiLine)>0)
  {
    followingMultiLine<-lapply(multiLine,function(x)integer())
    names(followingMultiLine)<-multiLine
    for(m in 1:length(multiLine))
    {
      w_field <- grep(regexiseField(multiLine[m]),fileLines)
      for(i in 1:length(w_field))
      {
        ct <- (w_field[i]+1)
        while(!(lineFields[ct]|lineOtherFields[ct]))
        {
          followingMultiLine[[m]] <- c(followingMultiLine[[m]],ct)
          ct <- ct+1
        }
      }
    }
    if(length(unlist(followingMultiLine)))
    {
      fieldName[unlist(followingMultiLine)]<-rep(paste(multiLine,"f",sep="_"),sapply(followingMultiLine,length))
    }
  }
  fieldName [lineOtherFields] <- gsub("^([ A-Za-z]+): +([0-9]+)$","\\1",fileLines[lineOtherFields])
  fieldName [emptyLinesBool] <- NA
  if(extractFields){
    fieldContent <- gsub("^[ ?[A-Z][A-Za-z0-9] +- +(.*)$","\\1",fileLines)
    fieldContent [grepl("^﻿[ -Z]][A-Za-z0-9] +-$",fileLines)] <- ""
    if(!all(is.na(multiLine)) & length(multiLine)>0)
    {
      fieldContent [unlist(followingMultiLine)] <- gsub("^ *([A-Za-z0-9].*)$","\\1",fileLines[unlist(followingMultiLine)])
    }
    fieldContent [lineOtherFields] <- gsub("^([ A-Za-z]+): +([0-9]+)$","\\2",fileLines[lineOtherFields])
    fieldContent [emptyLinesBool] <- NA
  }
  res <- list(
  nbRecords=max(registers$id),
              registers=registers,
              fieldName=fieldName,
	      lineRegId=idLines
  )
  if(keepCompleteRaw){
    res$raw <- fileLines
  }  
if(extractFields){
    res$content <- fieldContent
  }
  return(res)
}

