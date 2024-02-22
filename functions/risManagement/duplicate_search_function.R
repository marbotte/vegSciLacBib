stopifnot(require(stringdist))

risInternalDuplicate <- function(extractedRis, priority=c("JOUR","CHAP"))
{
  AcceptedDupli<-DupliToCheck<-data.frame()
  tabFields <- extractFields(extractedRis = extractedRis,c("DO","TI","PY","AU","TY"))
  tabFields$title_simp <- tolower(gsub("[^A-Za-z0-9]","",tabFields$TI,perl = T))
  #Searching duplicated DOI
  tabFields_do <- tabFields[!is.na(tabFields$DO)&tabFields$TY!="CHAP",]
  do_d <- duplicated(tabFields_do$DO)
  doDupli<-unique(tabFields_do[do_d,"DO"])
  toTest <- lapply(doDupli,function(x,tab)tab[tab$DO==x,],tab=tabFields_do)
  if(length(toTest)>0)
  {
    tested <- sapply(toTest,function(x){
      length(unique(x$title_simp))==1
    })
    if(any(!tested))
    {sapply(toTest[!tested],function(x)warning("\nRecords: ",paste(x$id,collapse=","),"\nhave the same DOI (",unique(x$DO),") but differences in their titles:\n",paste(x$TI,collapse="\n"),"\n\nthey will NOT be considered as duplicates\n"))}
    AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[tested],function(x,p){
        tab<-x[order(match(x$TY,p)),]
        data.frame(step="doi",ref=tab$id[1],toSupp=tab$id[2:nrow(x)])
      },p=priority)))
    DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!tested],function(x)data.frame(step="doi",ref=x$id[1],toSupp=x$id[2:nrow(x)]))))
  }
  # Searching duplicated titles and years (max difference:1) 
  # (both either do not have DOI or are chapters)
  tabFields_tiye <- tabFields[is.na(tabFields$DO)|tabFields$TY=="CHAP",]
  tabFields_tiye <-tabFields_tiye[!is.na(tabFields_tiye$PY),]
  title_simp_dup<-unique(tabFields_tiye$title_simp[duplicated(tabFields_tiye$title_simp)])
  toTest <- by(tabFields_tiye[which(tabFields_tiye$title_simp%in%title_simp_dup),], tabFields_tiye$title_simp[tabFields_tiye$title_simp%in%title_simp_dup],function(x)x)
  if(length(toTest)>0)
  {
    diff_Ymax1 <- sapply(toTest,function(x)diff(range(as.numeric(x$PY)))<=1)
    sameType <- sapply(toTest,function(x)length(unique(x$TY))==1)
    sameAuth <- sapply(toTest,function(x)length(unique(x$AU))==1)
    if(any(diff_Ymax1&(!sameAuth|!sameType)))
    {
      {sapply(toTest[diff_Ymax1&(!sameAuth|!sameType)],function(x)warning("\nRecords: ",paste(x$id,collapse=","),"\nhave comparable titles and pulication years \n(",paste(unique(x$TI),collapse="\n"),")\n but have differences in their authors and/or types:\n\nNote that they will be considered as duplicates\n"))}
    }
    if(any(!diff_Ymax1))
    {
      {sapply(toTest[!diff_Ymax1],function(x)warning("\nRecords: ",paste(x$id,collapse=","),"\nhave comparable titles (",paste(unique(x$TI),collapse="\n"),") but have a difference of more than one publication year!\n\nNote that they WONT be considered as duplicates\n"))}
    }
    AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[diff_Ymax1],function(x,p,a)
      {
        tab<-x[order(match(x$TY,p),!x$id%in%a),]
        return(data.frame(step="ti_ye_noDoi",ref=tab$id[1],toSupp=tab$id[2:nrow(x)]))
      },p=priority,a=AcceptedDupli$ref)))
    DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!diff_Ymax1],function(x,p)
      {
        tab<-x[order(match(x$TY,p)),]
        return(data.frame(step="ti_ye_noDoi",ref=tab$id[1],toSupp=tab$id[2:nrow(x)]))
      },p=priority)))
  }
 # Searching duplicated titles and years (max difference:1) 
 # (one of them do not have DOI or is a chapter)
  m_tiye_do <- match(tabFields_tiye$title_simp,tabFields_do$title_simp)
  if(sum(!is.na(m_tiye_do))){
  title_simp_dup <- tabFields_tiye$title_simp[!is.na(m_tiye_do)]
  toTest<-by(tabFields[tabFields$title_simp%in%title_simp_dup,], tabFields$title_simp[tabFields$title_simp%in%title_simp_dup],function(x)x)
  diff_Ymax1 <- sapply(toTest,function(x)diff(range(as.numeric(x$PY)))<=1)
  sameType <- sapply(toTest,function(x)length(unique(x$TY))==1)
  sameAuth <- sapply(toTest,function(x)length(unique(x$AU))==1)
    if(any(diff_Ymax1&(!sameAuth|!sameType)))
    {
      {sapply(toTest[diff_Ymax1&(!sameAuth|!sameType)],function(x)warning("\nRecords: ",paste(x$id,collapse=","),"\nhave comparable titles and pulication years \n(",paste(unique(x$TI),collapse="\n"),")\n but have differences in their authors and/or types:\n\nNote that they will be considered as duplicates\n"))}
    }
    if(any(!diff_Ymax1))
    {
      {sapply(toTest[!diff_Ymax1],function(x)warning("\nRecords: ",paste(x$id,collapse=","),"\nhave comparable titles (",paste(unique(x$TI),collapse="\n"),") but have a difference of more than one publication year!\n\nNote that they WONT be considered as duplicates\n"))}
    }
    AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[diff_Ymax1],function(x,p)
      {
        tab<-x[order(match(x$TY,p)),]
        return(data.frame(step="ti_ye_1Doi",ref=tab$id[1],toSupp=tab$id[2:nrow(x)]))
      },p=priority)))
    DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!diff_Ymax1],function(x,p)
      {
        tab<-x[order(match(x$TY,p)),]
        return(data.frame(step="ti_ye_1Doi",ref=tab$id[1],toSupp=tab$id[2:nrow(x)]))
      },p=priority)))
  }
  # Checking that we dont suppress a document which is the reference a couple of duplicates
  # If documents are cited more than once in AcceptedDupli, we need to make groups
  nbSeen<-table(c(unique(AcceptedDupli$ref),AcceptedDupli$toSupp))
  if(any(nbSeen>1)){
    gps=data.frame(gp=1,id=c(AcceptedDupli[1,"ref"],AcceptedDupli[1,"toSupp"]))
      for(i in 2:nrow(AcceptedDupli)){
        if(!AcceptedDupli$ref[i]%in%gps$id & !AcceptedDupli$toSupp[i]%in%gps$id)
          gps<-rbind(gps,data.frame(gp=max(gps$gp)+1,id=c(AcceptedDupli[i,"ref"],AcceptedDupli[i,"toSupp"])))
        if(AcceptedDupli$ref[i]%in%gps$id & AcceptedDupli$toSupp[i]%in%gps$id){
          gpAlready<-gps$gp[gps$id==AcceptedDupli$ref[i] | gps$id==AcceptedDupli$toSupp[i]]
          gp<-min(gpAlready)
          gps$gp[gps$gp%in%gpAlready]<-gp
        }
        if(AcceptedDupli$ref[i]%in%gps$id & !AcceptedDupli$toSupp[i]%in%gps$id){
          gp<-gps$gp[gps$id==AcceptedDupli$ref[i]]
          gps<-rbind(gps,data.frame(gp=gp,id=c(AcceptedDupli[i,"toSupp"])))
        }
        if(!AcceptedDupli$ref[i]%in%gps$id & AcceptedDupli$toSupp[i]%in%gps$id){
          gp<-gps$gp[gps$id==AcceptedDupli$toSupp[i]]
          gps<-rbind(gps,data.frame(gp=gp,id=c(AcceptedDupli[i,"ref"])))
        }
      
      }
    gps<-gps[order(gps$gp),]
    gpList<-tapply(gps$id,gps$gp,function(x,t)t[x,],t=tabFields)
    nbRefGp<-sapply(gpList,nrow)
    AD_gp<-gps$gp[match(AcceptedDupli$ref,gps$id)]
    AcceptedDupli<-AcceptedDupli[nbRefGp[as.character(AD_gp)]==2,]
    AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(gpList[nbRefGp>2],function(x,p){
      tab<-x[order(match(x,p)),]
      return(data.frame(step="reorganization",ref=tab$id[1],toSupp=tab$id[2:nrow(x)]))
    },p=priority)))
  }
  return(list(tabInfo= tabFields, accepted_dupes=AcceptedDupli, to_check_dupes=DupliToCheck, toSupp=AcceptedDupli$toSupp))
}

compareRisDuplicate<-function(risToFilter, risReference)
{
  # DOI
  AcceptedDupli<-DupliToCheck<-data.frame()
  rf_fieldTab<-extractFields(extractedRis = risToFilter,c("DO","TI","PY","AU","TY"))
  rr_fieldTab<-extractFields(extractedRis = risReference,c("DO","TI","PY","AU","TY"))
  rf_fieldTab$title_simp <- tolower(gsub("[^A-Za-z0-9]","",rf_fieldTab$TI,perl = T))
  rr_fieldTab$title_simp <- tolower(gsub("[^A-Za-z0-9]","",rr_fieldTab$TI,perl = T))
  #Searching duplicated DOI
  rr_fieldTab_do <- rr_fieldTab[!is.na(rr_fieldTab$DO)&rr_fieldTab$TY!="CHAP",]
  rf_fieldTab_do <- rf_fieldTab[!is.na(rf_fieldTab$DO)&rf_fieldTab$TY!="CHAP",]
  do_dupes <- unique(rf_fieldTab_do$DO[rf_fieldTab_do$DO %in% rr_fieldTab_do$DO])
  toTest <- lapply(do_dupes,function(x,a,b)rbind(data.frame(ref = F,a[a$DO==x,]), data.frame(ref = T, b[b$DO==x,])),
         a = rf_fieldTab_do, b = rr_fieldTab_do)
  tab <- Reduce(rbind, lapply(toTest, function(x){
    m <- match(x[!x$ref,"title_simp"], x[x$ref,"title_simp"])
    data.frame(toSupp = x[!x$ref,"id"],ref = x[x$ref,"id"][m])
  }))
  if(!is.null(tab) && as.logical(nrow(tab)) && sum(!is.na(tab$ref))>0)
  {
    AcceptedDupli <- rbind(AcceptedDupli, 
                           data.frame(step="doi",
                                      tab[!is.na(tab$ref),c("ref","toSupp")]))
  }
  pbs<-Reduce(rbind, lapply(toTest,function(x){
    pb<-x[!x$ref,"id"][!x[!x$ref,"title_simp"] %in% x[x$ref,"title_simp"]]
    if(length(pb)>0){
    data.frame(toSupp = pb, ref = x[x$ref,"id"])
    }
  }))
  if(!is.null(pbs) && nrow(pbs)>0)
  {
    DupliToCheck <- rbind(AcceptedDupli, 
                           data.frame(step="doi",
                                      tab[,c("ref","toSupp")]))
  }
  # No Doi
  rr_fieldTab_tiye <- rr_fieldTab[is.na(rr_fieldTab$DO)|rr_fieldTab$TY=="CHAP",]
  rf_fieldTab_tiye <- rf_fieldTab[is.na(rf_fieldTab$DO)|rf_fieldTab$TY=="CHAP",]
  tisimp_dupes <- unique(rf_fieldTab_tiye$title_simp[rf_fieldTab_tiye$title_simp %in% rr_fieldTab_tiye$title_simp])
  toTest <- lapply(tisimp_dupes,function(x,a,b)rbind(data.frame(ref = F,a[a$title_simp==x,]), data.frame(ref = T, b[b$title_simp==x,])),
         a = rf_fieldTab_tiye, b = rr_fieldTab_tiye)
  ok <- sapply(toTest,function(x)(diff(range(as.integer(x$PY))) <= 1))
  if(any(ok)){
  AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[ok],function(x)
         data.frame(step="no_doi",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  if(any(!ok)){
  DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!ok],function(x)
         data.frame(step="no_doi",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  # ref no doi
  tisimp_dupes <- unique(rf_fieldTab_do$title_simp[rf_fieldTab_do$title_simp %in% rr_fieldTab_tiye$title_simp])
  toTest <- lapply(tisimp_dupes,function(x,a,b)rbind(data.frame(ref = F,a[a$title_simp==x,]), data.frame(ref = T, b[b$title_simp==x,])),
         a = rf_fieldTab_do, b = rr_fieldTab_tiye)
  ok <- sapply(toTest,function(x)(diff(range(as.integer(x$PY))) <= 1))
  if(any(ok)){
  AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[ok],function(x)
         data.frame(step="ref_no_doi",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  if(any(!ok)){
  DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!ok],function(x)
         data.frame(step="ref_no_doi",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  # fil no doi
  tisimp_dupes <- unique(rf_fieldTab_tiye$title_simp[rf_fieldTab_tiye$title_simp %in% rr_fieldTab_do$title_simp])
  toTest <- lapply(tisimp_dupes,function(x,a,b)rbind(data.frame(ref = F,a[a$title_simp==x,]), data.frame(ref = T, b[b$title_simp==x,])),
         a = rf_fieldTab_tiye, b = rr_fieldTab_do)
  ok <- sapply(toTest,function(x)(diff(range(as.integer(x$PY))) <= 1))
  if(any(ok)){
  AcceptedDupli<-rbind(AcceptedDupli,Reduce(rbind,lapply(toTest[ok],function(x)
         data.frame(step="fil_no_tiye",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  if(any(!ok)){
  DupliToCheck<-rbind(DupliToCheck,Reduce(rbind,lapply(toTest[!ok],function(x)
         data.frame(step="fil_no_tiye",ref = x$id[x$ref], toSupp = x$id[!x$ref]))))
  }
  message(paste(length(unique(AcceptedDupli$toSupp)),"/",risToFilter$nbRecords,"records are already in the reference file"))
  return(list(tabInfoRef= rr_fieldTab, tabInfoFil=rf_fieldTab, accepted_dupes=AcceptedDupli, to_check_dupes=DupliToCheck, toSupp=unique(AcceptedDupli$toSupp)))
}

