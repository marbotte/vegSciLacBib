First exercise of extraction from Ris files
================
Marius Bottin
2024-02-23

- [1 Scopus](#1-scopus)
- [2 Web of science](#2-web-of-science)

# 1 Scopus

``` r
source("../functions/risManagement/readRis.R")
fileTot<-"../../Data/SCOPUS/tot.ris"
if(!file.exists(fileTot)){
risFilesScopus<- paste0("../../Data/SCOPUS/",c("JVS-3476.ris","AVS-1326.ris","VCS-94.ris"))
extractedRiss <- lapply(risFilesScopus, read_ris)
writeLines(unlist(lapply(extractedRiss,function(x)x$raw)),fileTot)
}  
tot_extracted<-read_ris(fileTot)
```

What are the fields we have access to in these files:

``` r
(ctFields<-table(tot_extracted$fieldName))
```

    ## 
    ##    AB    AD    AU    C7    DB    DO    EP    ER    IS    J2    KW    LA    M3 
    ##  4738 14115 20065   527  4896  4883  4349  4896  4801  4892 73146  4896  4896 
    ##    N1    PB    PY    SN    SP    T2    TI    TY    UR    VL 
    ##  4896  2905  4896  4896  4370  4896  4896  4896  4896  4896

``` r
fields<-names(ctFields)
w_5<-lapply(fields,function(x,w){
  A<-which(w==x)
  sample(A,5)
},w=tot_extracted$fieldName)
names(w_5)<-fields
lapply(w_5,function(x,r){
  text<-r[x]
  sup50<-nchar(text)>50
  if(any(sup50)){
    text[sup50]<-sapply(text[sup50],function(x)paste(substr(x,1,50),"[...]"))
  }
  return(text)
},r=tot_extracted$raw)
```

    ## $AB
    ## [1] "AB  - Abstract.  The mycorrhizal mycoflora was inv [...]"
    ## [2] "AB  - Aim: Landscape management and conservation p [...]"
    ## [3] "AB  - Prosopis glandulosa var. glandulosa has play [...]"
    ## [4] "AB  - The invasion by non-native plant species of  [...]"
    ## [5] "AB  - Due to economic pressures and policy changes [...]"
    ## 
    ## $AD
    ## [1] "AD  - Center for Environmental Biology and Ecosyst [...]"
    ## [2] "AD  - Hungarian Department of Biology and Ecology, [...]"
    ## [3] "AD  - Systems Ecology, Department of Ecological Sc [...]"
    ## [4] "AD  - AgroParisTech, INRAE, Silva, Université de L [...]"
    ## [5] "AD  - National Center for Remote Sensing, Lebanese [...]"
    ## 
    ## $AU
    ## [1] "AU  - Prokešová, H."   "AU  - Pérez-Haase, A." "AU  - Villiers, J.-F."
    ## [4] "AU  - Hoshino, Y."     "AU  - Cruz, P."       
    ## 
    ## $C7
    ## [1] "C7  - e13042" "C7  - e12701" "C7  - e13107" "C7  - e13196" "C7  - e13064"
    ## 
    ## $DB
    ## [1] "DB  - Scopus" "DB  - Scopus" "DB  - Scopus" "DB  - Scopus" "DB  - Scopus"
    ## 
    ## $DO
    ## [1] "DO  - 10.2307/3236854"    "DO  - 10.1111/avsc.12642"
    ## [3] "DO  - 10.1111/avsc.12409" "DO  - 10.1111/jvs.13176" 
    ## [5] "DO  - 10.1111/jvs.12161" 
    ## 
    ## $EP
    ## [1] "EP  - 635" "EP  - 544" "EP  - 668" "EP  - 271" "EP  - 625"
    ## 
    ## $ER
    ## [1] "ER  -" "ER  -" "ER  -" "ER  -" "ER  -"
    ## 
    ## $IS
    ## [1] "IS  - 6" "IS  - 1" "IS  - 1" "IS  - 2" "IS  - 4"
    ## 
    ## $J2
    ## [1] "J2  - Appl. Veg. Sci." "J2  - Appl. Veg. Sci." "J2  - J. Veg. Sci."   
    ## [4] "J2  - J. Veg. Sci."    "J2  - Appl. Veg. Sci."
    ## 
    ## $KW
    ## [1] "KW  - species diversity" "KW  - Step-across"      
    ## [3] "KW  - limestone"         "KW  - Florida scrub"    
    ## [5] "KW  - autumn"           
    ## 
    ## $LA
    ## [1] "LA  - English" "LA  - English" "LA  - English" "LA  - English"
    ## [5] "LA  - English"
    ## 
    ## $M3
    ## [1] "M3  - Article"   "M3  - Article"   "M3  - Article"   "M3  - Editorial"
    ## [5] "M3  - Article"  
    ## 
    ## $N1
    ## [1] "N1  - Export Date: 23 February 2024; Cited By: 100 [...]"
    ## [2] "N1  - Export Date: 23 February 2024; Cited By: 0;  [...]"
    ## [3] "N1  - Export Date: 23 February 2024; Cited By: 61"       
    ## [4] "N1  - Export Date: 23 February 2024; Cited By: 9;  [...]"
    ## [5] "N1  - Export Date: 23 February 2024; Cited By: 17; [...]"
    ## 
    ## $PB
    ## [1] "PB  - Opulus Press AB" "PB  - Opulus Press AB" "PB  - Wiley-Blackwell"
    ## [4] "PB  - Wiley-Blackwell" "PB  - Opulus Press AB"
    ## 
    ## $PY
    ## [1] "PY  - 2002" "PY  - 2000" "PY  - 2013" "PY  - 2016" "PY  - 1998"
    ## 
    ## $SN
    ## [1] "SN  - 11009233 (ISSN)" "SN  - 11009233 (ISSN)" "SN  - 11009233 (ISSN)"
    ## [4] "SN  - 14022001 (ISSN)" "SN  - 11009233 (ISSN)"
    ## 
    ## $SP
    ## [1] "SP  - 465" "SP  - 844" "SP  - 459" "SP  - 517" "SP  - 701"
    ## 
    ## $T2
    ## [1] "T2  - Journal of Vegetation Science" "T2  - Journal of Vegetation Science"
    ## [3] "T2  - Journal of Vegetation Science" "T2  - Journal of Vegetation Science"
    ## [5] "T2  - Journal of Vegetation Science"
    ## 
    ## $TI
    ## [1] "TI  - Mycorrhizal traits and plant communities: Pe [...]"
    ## [2] "TI  - Shrinking opportunities for establishment of [...]"
    ## [3] "TI  - Observer bias and random variation in vegeta [...]"
    ## [4] "TI  - A functional analysis of a limestone grassla [...]"
    ## [5] "TI  - Soil seed bank development of smoke-responsi [...]"
    ## 
    ## $TY
    ## [1] "TY  - JOUR" "TY  - CONF" "TY  - JOUR" "TY  - JOUR" "TY  - JOUR"
    ## 
    ## $UR
    ## [1] "UR  - https://www.scopus.com/inward/record.uri?eid [...]"
    ## [2] "UR  - https://www.scopus.com/inward/record.uri?eid [...]"
    ## [3] "UR  - https://www.scopus.com/inward/record.uri?eid [...]"
    ## [4] "UR  - https://www.scopus.com/inward/record.uri?eid [...]"
    ## [5] "UR  - https://www.scopus.com/inward/record.uri?eid [...]"
    ## 
    ## $VL
    ## [1] "VL  - 25" "VL  - 21" "VL  - 9"  "VL  - 8"  "VL  - 11"

``` r
sum(grepl("^ *Location:",tot_extracted$raw))
```

    ## [1] 0

``` r
sum(grepl("Location:",tot_extracted$raw))
```

    ## [1] 2745

``` r
sum(grepl("Locations?:",tot_extracted$raw))
```

    ## [1] 2768

# 2 Web of science

``` r
source("../functions/risManagement/readRis.R")
fileTot<-"../../Data/Web of Science/tot.ris"
if(!file.exists(fileTot)){
risFilesScopus<- paste0("../../Data/Web of Science/",c("appliedvegetationscience_0to1000_wos.ris","appliedvegetationscience_1001to1333_wos.ris","journalofvegetationscience_0to1000_wos.ris","journalofvegetationscience_1001to2000_wosris","journalofvegetationscience_2001to3000_wos.ris","journalofvegetationscience_3001to3490_wos.ris"))
extractedRiss <- lapply(risFilesScopus, read_ris)
writeLines(unlist(lapply(extractedRiss,function(x)x$raw)),fileTot)
}  
tot_extracted<-read_ris(fileTot)
```

``` r
(ctFields<-table(tot_extracted$fieldName))
```

    ## 
    ##                    A1                    AB                  AB_f 
    ##                     6                  4565                 10384 
    ##                    AD                    AN                    AU 
    ##                 12583                  4823                 19531 
    ##                    C3                    C6                    C7 
    ##                 14922                   267                   462 
    ## Cited Reference Count                    CP                    DA 
    ##                  4823                   236                  4823 
    ##                    DO                    EP                    ER 
    ##                  4732                  4284                  4823 
    ##                    FU                    FX                    IS 
    ##                  2282                  2263                  4823 
    ##                    J9                    JI                    KW 
    ##                  4823                  4823                 67255 
    ##                    LA                    N1                    PA 
    ##                  4823                  4823                  4823 
    ##                    PI                    PU                    PY 
    ##                  4823                  4823                  4823 
    ##                    SN                    SP                    T2 
    ##                  8354                  4284                  4823 
    ##                    TI     Total Times Cited                    TY 
    ##                  4823                  4823                  4823 
    ##                    VL                    WE 
    ##                  4823                  5085

``` r
fields<-names(ctFields)
w_5<-lapply(fields,function(x,w){
  A<-which(w==x)
  sample(A,5)
},w=tot_extracted$fieldName)
names(w_5)<-fields
lapply(w_5,function(x,r){
  text<-r[x]
  sup50<-nchar(text)>50
  if(any(sup50)){
    text[sup50]<-sapply(text[sup50],function(x)paste(substr(x,1,50),"[...]"))
  }
  return(text)
},r=tot_extracted$raw)
```

    ## $A1
    ## [1] "A1  - European Ctr Dis Prevention Contro"
    ## [2] "A1  - European Union Reference Lab Avian"
    ## [3] "A1  - VISTA Consortium"                  
    ## [4] "A1  - CAVM Team"                         
    ## [5] "A1  - European Food Safety Authority"    
    ## 
    ## $AB
    ## [1] "AB  - A common goal in functional type research is [...]"
    ## [2] "AB  - Vegetation phenological phenomena are closel [...]"
    ## [3] "AB  - The recovery of forest plant communities in  [...]"
    ## [4] "AB  - Questions Does the presence of salt marsh ve [...]"
    ## [5] "AB  - Question"                                          
    ## 
    ## $AB_f
    ## [1] "   We make clear how ecoinformatics in vegetation  [...]"
    ## [2] "   Methods Variability in an annually sampled, 15- [...]"
    ## [3] "   Location: Forest corridor of Fianarantsoa, sout [...]"
    ## [4] "   ResultsWe found that recruitment had declined t [...]"
    ## [5] "   MethodsCliff faces on two mountains were blocke [...]"
    ## 
    ## $AD
    ## [1] "AD  - Univ Minnesota, Dept Ecol Evolut & Behav, St [...]"
    ## [2] "AD  - Univ Nacl Cordoba, Inst Multidisciplinario B [...]"
    ## [3] "AD  - Ernst Moritz Arndt Univ Greifswald, Inst Bot [...]"
    ## [4] "AD  - James Cook Univ, Coll Sci & Engn, ARC Ctr Ex [...]"
    ## [5] "AD  - Washington Univ, Dept Biol, St Louis, MO 631 [...]"
    ## 
    ## $AN
    ## [1] "AN  - WOS:000220133300004" "AN  - WOS:000412077700013"
    ## [3] "AN  - WOS:000263168800014" "AN  - WOS:000509801600001"
    ## [5] "AN  - WOS:000071290800008"
    ## 
    ## $AU
    ## [1] "AU  - Maxwell, BD" "AU  - Loram, A"    "AU  - Hartz, SM"  
    ## [4] "AU  - Dolezal, J"  "AU  - Attorre, F" 
    ## 
    ## $C3
    ## [1] "C3  - Swedish University of Agricultural Sciences"
    ## [2] "C3  - Lund University"                            
    ## [3] "C3  - Universite de Toulouse"                     
    ## [4] "C3  - Michigan State University"                  
    ## [5] "C3  - Stellenbosch University"                    
    ## 
    ## $C6
    ## [1] "C6  - FEB 2020" "C6  - OCT 2020" "C6  - NOV 2019" "C6  - OCT 2020"
    ## [5] "C6  - OCT 2020"
    ## 
    ## $C7
    ## [1] "C7  - e12990"  "C7  - e12714"  "C7  - e12720"  "C7  - e12738" 
    ## [5] "C7  - e013073"
    ## 
    ## $`Cited Reference Count`
    ## [1] "Cited Reference Count:  68" "Cited Reference Count:  46"
    ## [3] "Cited Reference Count:  51" "Cited Reference Count:  0" 
    ## [5] "Cited Reference Count:  58"
    ## 
    ## $CP
    ## [1] "CP  - IGBP Terrestrial Transects Workshop"               
    ## [2] "CP  - Conference on Restoration Ecology"                 
    ## [3] "CP  - 41st Symposium of the International-Associat [...]"
    ## [4] "CP  - Meeting of the Working-Group-on-Long-Term-Ve [...]"
    ## [5] "CP  - 38th Symposium of IAVS on the Importance of  [...]"
    ## 
    ## $DA
    ## [1] "DA  - NOV" "DA  - MAR" "DA  - NOV" "DA  - DEC" "DA  - MAY"
    ## 
    ## $DO
    ## [1] "DO  - 10.1111/jvs.12728"                                 
    ## [2] "DO  - 10.1111/jvs.12389"                                 
    ## [3] "DO  - 10.1111/j.1654-109X.2011.01150.x"                  
    ## [4] "DO  - 10.1658/1402-2001(2004)007[0221:SDAMOT]2.0.C [...]"
    ## [5] "DO  - 10.2307/3236164"                                   
    ## 
    ## $EP
    ## [1] "EP  - 803" "EP  - 188" "EP  - 697" "EP  - 180" "EP  - 472"
    ## 
    ## $ER
    ## [1] "ER  -" "ER  -" "ER  -" "ER  -" "ER  -"
    ## 
    ## $FU
    ## [1] "FU  - Consejo Nacional para Investigaciones Cienti [...]"
    ## [2] "FU  - U.S. Department of Defense, Army Garrison Ha [...]"
    ## [3] "FU  - European Research Council (ERC) [ERC-StG-201 [...]"
    ## [4] "FU  - Spanish Government;  [CGL2009-13497-C02-01]; [...]"
    ## [5] "FU  - Archbold Biological Station (ABS); Garden Cl [...]"
    ## 
    ## $FX
    ## [1] "FX  - The authors thank the Yesaires team, especia [...]"
    ## [2] "FX  - US Bureau of Reclamation, Grant/Award Number [...]"
    ## [3] "FX  - This work was funded by the Deutsche Forschu [...]"
    ## [4] "FX  - The authors thank P. J. Lin, R. J. Shao, H.  [...]"
    ## [5] "FX  - NorgesForskningsr (NORKLIMA #184912/230)."         
    ## 
    ## $IS
    ## [1] "IS  - 4" "IS  - 2" "IS  - 2" "IS  - 2" "IS  - 4"
    ## 
    ## $J9
    ## [1] "J9  - J VEG SCI"    "J9  - J VEG SCI"    "J9  - APPL VEG SCI"
    ## [4] "J9  - J VEG SCI"    "J9  - J VEG SCI"   
    ## 
    ## $JI
    ## [1] "JI  - J. Veg. Sci."    "JI  - Appl. Veg. Sci." "JI  - Appl. Veg. Sci."
    ## [4] "JI  - J. Veg. Sci."    "JI  - J. Veg. Sci."   
    ## 
    ## $KW
    ## [1] "KW  - coastal dune habitats" "KW  - ECOLOGICAL SUCCESSION"
    ## [3] "KW  - Sulphur"               "KW  - TAXONOMIC COMPOSITION"
    ## [5] "KW  - SEASONAL-VARIATION"   
    ## 
    ## $LA
    ## [1] "LA  - English" "LA  - English" "LA  - English" "LA  - English"
    ## [5] "LA  - English"
    ## 
    ## $N1
    ## [1] "N1  - Times Cited in Web of Science Core Collectio [...]"
    ## [2] "N1  - Times Cited in Web of Science Core Collectio [...]"
    ## [3] "N1  - Times Cited in Web of Science Core Collectio [...]"
    ## [4] "N1  - Times Cited in Web of Science Core Collectio [...]"
    ## [5] "N1  - Times Cited in Web of Science Core Collectio [...]"
    ## 
    ## $PA
    ## [1] "PA  - GAMLA VAGEN 40, S-770 13 GRANGARDE, SWEDEN"        
    ## [2] "PA  - BOX 25137, S 752 25 UPPSALA, SWEDEN"               
    ## [3] "PA  - 111 RIVER ST, HOBOKEN 07030-5774, NJ USA"          
    ## [4] "PA  - COMMERCE PLACE, 350 MAIN ST, MALDEN 02148, M [...]"
    ## [5] "PA  - 111 RIVER ST, HOBOKEN 07030-5774, NJ USA"          
    ## 
    ## $PI
    ## [1] "PI  - HOBOKEN" "PI  - HOBOKEN" "PI  - HOBOKEN" "PI  - KNIVSTA"
    ## [5] "PI  - HOBOKEN"
    ## 
    ## $PU
    ## [1] "PU  - OPULUS PRESS UPPSALA AB" "PU  - WILEY-BLACKWELL"        
    ## [3] "PU  - WILEY"                   "PU  - OPULUS PRESS UPPSALA AB"
    ## [5] "PU  - WILEY"                  
    ## 
    ## $PY
    ## [1] "PY  - 2021" "PY  - 2009" "PY  - 2021" "PY  - 2007" "PY  - 2008"
    ## 
    ## $SN
    ## [1] "SN  - 1654-1103" "SN  - 1100-9233" "SN  - 1654-1103" "SN  - 1100-9233"
    ## [5] "SN  - 1402-2001"
    ## 
    ## $SP
    ## [1] "SP  - 103" "SP  - 721" "SP  - 149" "SP  - 269" "SP  - 409"
    ## 
    ## $T2
    ## [1] "T2  - JOURNAL OF VEGETATION SCIENCE" "T2  - JOURNAL OF VEGETATION SCIENCE"
    ## [3] "T2  - JOURNAL OF VEGETATION SCIENCE" "T2  - JOURNAL OF VEGETATION SCIENCE"
    ## [5] "T2  - JOURNAL OF VEGETATION SCIENCE"
    ## 
    ## $TI
    ## [1] "TI  - Scientific floras can be reliable sources fo [...]"
    ## [2] "TI  - Restoration of wooded meadows -: a comparati [...]"
    ## [3] "TI  - Cascading effects from plant to soil elucida [...]"
    ## [4] "TI  - Temporal changes in height and diameter grow [...]"
    ## [5] "TI  - Facilitation of holm oak recruitment through [...]"
    ## 
    ## $`Total Times Cited`
    ## [1] "Total Times Cited:  49" "Total Times Cited:  29" "Total Times Cited:  17"
    ## [4] "Total Times Cited:  19" "Total Times Cited:  8" 
    ## 
    ## $TY
    ## [1] "TY  - JOUR" "TY  - JOUR" "TY  - JOUR" "TY  - JOUR" "TY  - JOUR"
    ## 
    ## $VL
    ## [1] "VL  - 20" "VL  - 32" "VL  - 1"  "VL  - 26" "VL  - 19"
    ## 
    ## $WE
    ## [1] "WE  - Science Citation Index Expanded (SCI-EXPANDE [...]"
    ## [2] "WE  - Science Citation Index Expanded (SCI-EXPANDE [...]"
    ## [3] "WE  - Science Citation Index Expanded (SCI-EXPANDE [...]"
    ## [4] "WE  - Science Citation Index Expanded (SCI-EXPANDE [...]"
    ## [5] "WE  - Science Citation Index Expanded (SCI-EXPANDE [...]"

``` r
sum(grepl("^ *Location:",tot_extracted$raw))
```

    ## [1] 1050

``` r
sum(grepl("Location:",tot_extracted$raw))
```

    ## [1] 1165

``` r
sum(grepl("Locations?:",tot_extracted$raw))
```

    ## [1] 1179

``` r
sum(grepl("Locations? ?:",tot_extracted$raw))
```

    ## [1] 1179

Which records do not have location:

``` r
regLoc <- tot_extracted$lineRegId[grepl("Locations? ?:",tot_extracted$raw)]
reg <- 1:max(tot_extracted$lineRegId)
#With location
table(tot_extracted$content[!is.na(tot_extracted$fieldName) & tot_extracted$fieldName=="T2" & tot_extracted$lineRegId %in%regLoc])
```

    ## 
    ##    APPLIED VEGETATION SCIENCE JOURNAL OF VEGETATION SCIENCE 
    ##                           503                           676

``` r
#Without location
table(tot_extracted$content[!is.na(tot_extracted$fieldName) & tot_extracted$fieldName=="T2" & !tot_extracted$lineRegId %in%regLoc])
```

    ## 
    ##    APPLIED VEGETATION SCIENCE JOURNAL OF VEGETATION SCIENCE 
    ##                           830                          2814

``` r
#With location
#table(tot_extracted$content[!is.na(tot_extracted$fieldName) & tot_extracted$fieldName=="PY"],tot_extracted$content[tot_extracted$lineRegId %in%regLoc])
#Without location
#table(tot_extracted$content[!is.na(tot_extracted$fieldName) & tot_extracted$fieldName=="PY"],tot_extracted$content[tot_extracted$lineRegId %in%regLoc])
```
