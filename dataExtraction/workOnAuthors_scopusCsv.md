Managing the author data from the scopus CSV file
================
Marius Bottin
2024-03-09

- [1 Reading the csv file](#1-reading-the-csv-file)
- [2 Authors full names and
  identifiers](#2-authors-full-names-and-identifiers)
  - [2.1 Extraction with regular
    expression](#21-extraction-with-regular-expression)
- [3 Relationships between complete author names and author
  names](#3-relationships-between-complete-author-names-and-author-names)
- [4 Clean extraction](#4-clean-extraction)
- [5 tests](#5-tests)

# 1 Reading the csv file

``` r
fileTot<-"../../Data/SCOPUS/scopus.csv"
datab <- read.csv(fileTot, h = T, row.names = NULL,sep=",")
```

# 2 Authors full names and identifiers

The colum `Author.full.names` include the full name and a scopus
identifier.

``` r
sepAuthors <- strsplit(datab$Author.full.names,"; ")
```

## 2.1 Extraction with regular expression

``` r
regexCompAuth<- "^(.+), (.+) \\(([0-9]+)\\)$"
```

It appears three authors have only a last name:

``` r
sepAuthors[!sapply(sapply(sepAuthors,grepl,pattern=regexCompAuth),all)]
```

    ## [[1]]
    ## [1] "Niu, Kechang (24468583100)"        "Suonan, Ji (57194634792)"         
    ## [3] "Badingqiuying (57195249219)"       "Smith, Andrew T. (7406746939)"    
    ## [5] "Lechowicz, Martin J. (7004043584)"
    ## 
    ## [[2]]
    ## [1] "Toledo-Aceves (56000854300)" "Swaine, M.D. (7005840067)"  
    ## 
    ## [[3]]
    ## [1] "Malkinson, D. (12768896700)" "Kadmon, R. (7003440508)"    
    ## [3] "Cohen D. (7404418038)"      
    ## 
    ## [[4]]
    ## [1] "Silvertown, Jonathan (7006821066)" "Watt, Trudy A. (7004535648)"      
    ## [3] "Smith Bridget (57191102745)"       "Treweek, Joanna R. (55881708200)"

``` r
regexNoFirst<- "^(.+) \\(([0-9]+)\\)$"

treatedFullNames <- lapply(sepAuthors,function(x,r1,r2)
{
  stopifnot(grepl(r1,x)|grepl(r2,x))
  regexOk <- grepl(r1,x)
  verbatim <- x
  lastName <- gsub(r1,"\\1",x)
  firstName <- gsub(r1,"\\2",x)
  authorId <- gsub(r1,"\\3",x)
  if(any(!regexOk))
  lastName[!regexOk] <- gsub(r2,"\\1",x[!regexOk])
  firstName[!regexOk] <- NA
  authorId[!regexOk] <- gsub(r2,"\\2",x[!regexOk])
  return(data.frame(
    verbatim=verbatim,
    lastName=lastName,
    firstName=firstName,
    authorId=authorId
    ))
},r1=regexCompAuth,r2=regexNoFirst)
```

# 3 Relationships between complete author names and author names

``` r
length(datab$Authors)==length(treatedFullNames)
```

    ## [1] TRUE

``` r
sepAuthorSimp <- strsplit(datab$Authors,"; ")
all(sapply(sepAuthorSimp,length)==sapply(treatedFullNames,nrow))
```

    ## [1] TRUE

``` r
tabAuthComp<-Reduce(rbind,treatedFullNames)
tabAuthComp$nameSimp<-unlist(sepAuthorSimp)
lastNameInNameSimp<-apply(tabAuthComp,1,function(x)grepl(x[2],x[5],fixed=T))
```

It appears that the order in both columns is really always the same!

# 4 Clean extraction

Then it should be easy to extract the names in function of the author ID

``` r
require(sqldf)
```

    ## Loading required package: sqldf

    ## Loading required package: gsubfn

    ## Loading required package: proto

    ## Loading required package: RSQLite

``` r
extractMajoNames<-by(tabAuthComp,tabAuthComp$authorId,function(tab)
  {
    lnfnOrder<-sqldf("SELECT lastName, firstName, count(*) FROM tab ORDER BY count(*) DESC,LENGTH(firstName) DESC LIMIT 1")
    nbns<-table(tab$nameSimp)
    nsMaj<-names(nbns)[which.max(nbns)]
    data.frame(lastName=lnfnOrder$lastName,firstName=lnfnOrder$firstName,nameSimp=nsMaj)
    
  })
tabNamesFinal<-Reduce(rbind,extractMajoNames)
rownames(tabNamesFinal)<-names(extractMajoNames)
authIdsDoc<-sapply(treatedFullNames,function(x)x$authorId)
authDoc<-data.frame(
  doc=rep(1:length(authIdsDoc),sapply(authIdsDoc,length)),
  authId=unlist(authIdsDoc),
  authOrder=unlist(lapply(authIdsDoc[sapply(authIdsDoc,length)>0],function(x)1:length(x))),
  authNb=rep(sapply(authIdsDoc,length),sapply(authIdsDoc,length)),
  authSimp=tabAuthComp$nameSimp
)
```

# 5 tests

``` r
sepAbbAuthors <- strsplit(datab$Authors,"; ")
regexAbbAuthors <- "^.+ ((-?[A-Z]?[a-z]?\\.)+)$"
regexAbbAuthors <- "^.+ ([.[:alpha:]-]+)$"

sepAbbAuthors[sapply(sapply(sapply(sepAbbAuthors,grepl,pattern=regexAbbAuthors,perl=T),`!`),any)]
```

    ## [[1]]
    ##  [1] "Fóti S."       "Bartha S."     "Balogh J."     "Pintér K."    
    ##  [5] "Koncz P."      "Biró M."       "Süle G."       "Petrás D."    
    ##  [9] "de Luca G."    "Mészáros Á."   "Zimmermann Z." "Szabó G."     
    ## [13] "Csathó A.I."   "Ladányi M."    "Péli E.R."     "Nagy Z."      
    ## 
    ## [[2]]
    ##  [1] "Midolo G."           "Axmanová I."         "Divíšek J."         
    ##  [4] "Dřevojan P."         "Lososová Z."         "Večeřa M."          
    ##  [7] "Karger D.N."         "Thuiller W."         "Bruelheide H."      
    ## [10] "Aćić S."             "Attorre F."          "Biurrun I."         
    ## [13] "Boch S."             "Bonari G."           "Čarni A."           
    ## [16] "Chiarucci A."        "Ćušterevska R."      "Dengler J."         
    ## [19] "Dziuba T."           "Garbolino E."        "Jandt U."           
    ## [22] "Lenoir J."           "Marcenò C."          "Rūsiņa S."          
    ## [25] "Šibík J."            "Škvorc Ž."           "Stančić Z."         
    ## [28] "Stanišić-Vujačić M." "Svenning J.-C."      "Swacha G."          
    ## [31] "Vassilev K."         "Chytrý M."          
    ## 
    ## [[3]]
    ## [1] "Erdős L."        "Ho K.V."         "Bede-Fazekas Á." "Kröel-Dulay G." 
    ## [5] "Tölgyesi C."     "Bátori Z."       "Török P."       
    ## 
    ## [[4]]
    ## [1] "Maturano-Ruiz A." "Ruiz-Yanetti S."  "Manrique-Alba À." "Moutahir H."     
    ## [5] "Chirino E."       "Vilagrosa A."     "Bellot J.F."     
    ## 
    ## [[5]]
    ## [1] "Pinke G."        "Vér A."          "Réder K."        "Koltai G."      
    ## [5] "Schlögl G."      "Bede-Fazekas Á." "Czúcz B."        "Botta-Dukát Z." 
    ## 
    ## [[6]]
    ##  [1] "Preislerová Z."        "Marcenò C."            "Loidi J."             
    ##  [4] "Bonari G."             "Borovyk D."            "Gavilán R.G."         
    ##  [7] "Golub V."              "Terzi M."              "Theurillat J.-P."     
    ## [10] "Argagnon O."           "Bioret F."             "Biurrun I."           
    ## [13] "Campos J.A."           "Capelo J."             "Čarni A."             
    ## [16] "Çoban S."              "Csiky J."              "Ćuk M."               
    ## [19] "Ćušterevska R."        "Dengler J."            "Didukh Y."            
    ## [22] "Dítě D."               "Fanelli G."            "Fernández-González F."
    ## [25] "Guarino R."            "Hájek O."              "Iakushenko D."        
    ## [28] "Iemelianova S."        "Jansen F."             "Jašková A."           
    ## [31] "Jiroušek M."           "Kalníková V."          "Kavgacı A."           
    ## [34] "Kuzemko A."            "Landucci F."           "Lososová Z."          
    ## [37] "Milanović Đ."          "Molina J.A."           "Monteiro-Henriques T."
    ## [40] "Mucina L."             "Novák P."              "Nowak A."             
    ## [43] "Pätsch R."             "Perrin G."             "Peterka T."           
    ## [46] "Rašomavičius V."       "Reczyńska K."          "Rūsiņa S."            
    ## [49] "Mata D.S."             "Guerra A."             "Šibík J."             
    ## [52] "Škvorc Ž."             "Stešević D."           "Stupar V."            
    ## [55] "Świerkosz K."          "Tzonev R."             "Vassilev K."          
    ## [58] "Vynokurov D."          "Willner W."            "Chytrý M."            
    ## 
    ## [[7]]
    ##  [1] "Klinkovská K." "Kučerová A."   "Pustková Š."   "Rohel J."     
    ##  [5] "Slachová K."   "Sobotka V."    "Szokala D."    "Danihelka J." 
    ##  [9] "Kočí M."       "Šmerdová E."   "Chytrý M."    
    ## 
    ## [[8]]
    ## [1] "Gómez-García D."       "Aguirre de Juana Á.J." "Jiménez Sánchez R."   
    ## [4] "Manrique Magallón C." 
    ## 
    ## [[9]]
    ## [1] "Niu K."        "Suonan J."     "Badingqiuying" "Smith A.T."   
    ## [5] "Lechowicz M." 
    ## 
    ## [[10]]
    ##  [1] "Tichý L."             "Axmanová I."          "Dengler J."          
    ##  [4] "Guarino R."           "Jansen F."            "Midolo G."           
    ##  [7] "Nobis M.P."           "Van Meerbeek K."      "Aćić S."             
    ## [10] "Attorre F."           "Bergmeier E."         "Biurrun I."          
    ## [13] "Bonari G."            "Bruelheide H."        "Campos J.A."         
    ## [16] "Čarni A."             "Chiarucci A."         "Ćuk M."              
    ## [19] "Ćušterevska R."       "Didukh Y."            "Dítě D."             
    ## [22] "Dítě Z."              "Dziuba T."            "Fanelli G."          
    ## [25] "Fernández-Pascual E." "Garbolino E."         "Gavilán R.G."        
    ## [28] "Gégout J.-C."         "Graf U."              "Güler B."            
    ## [31] "Hájek M."             "Hennekens S.M."       "Jandt U."            
    ## [34] "Jašková A."           "Jiménez-Alfaro B."    "Julve P."            
    ## [37] "Kambach S."           "Karger D.N."          "Karrer G."           
    ## [40] "Kavgacı A."           "Knollová I."          "Kuzemko A."          
    ## [43] "Küzmič F."            "Landucci F."          "Lengyel A."          
    ## [46] "Lenoir J."            "Marcenò C."           "Moeslund J.E."       
    ## [49] "Novák P."             "Pérez-Haase A."       "Peterka T."          
    ## [52] "Pielech R."           "Pignatti A."          "Rašomavičius V."     
    ## [55] "Rūsiņa S."            "Saatkamp A."          "Šilc U."             
    ## [58] "Škvorc Ž."            "Theurillat J.-P."     "Wohlgemuth T."       
    ## [61] "Chytrý M."           
    ## 
    ## [[11]]
    ## [1] "Loidi J."               "Amigo J."               "Bueno Á."              
    ## [4] "Herrera M."             "Rodríguez-Guitián M.A."
    ## 
    ## [[12]]
    ##  [1] "Preislerová Z."        "Jiménez-Alfaro B."     "Mucina L."            
    ##  [4] "Berg C."               "Bonari G."             "Kuzemko A."           
    ##  [7] "Landucci F."           "Marcenò C."            "Monteiro-Henriques T."
    ## [10] "Novák P."              "Vynokurov D."          "Bergmeier E."         
    ## [13] "Dengler J."            "Apostolova I."         "Bioret F."            
    ## [16] "Biurrun I."            "Campos J.A."           "Capelo J."            
    ## [19] "Čarni A."              "Çoban S."              "Csiky J."             
    ## [22] "Ćuk M."                "Ćušterevska R."        "Daniëls F.J.A."       
    ## [25] "De Sanctis M."         "Didukh Y."             "Dítě D."              
    ## [28] "Fanelli G."            "Golovanov Y."          "Golub V."             
    ## [31] "Guarino R."            "Hájek M."              "Iakushenko D."        
    ## [34] "Indreica A."           "Jansen F."             "Jašková A."           
    ## [37] "Jiroušek M."           "Kalníková V."          "Kavgacı A."           
    ## [40] "Kucherov I."           "Küzmič F."             "Lebedeva M."          
    ## [43] "Loidi J."              "Lososová Z."           "Lysenko T."           
    ## [46] "Milanović Đ."          "Onyshchenko V."        "Perrin G."            
    ## [49] "Peterka T."            "Rašomavičius V."       "Rodríguez-Rojo M.P."  
    ## [52] "Rodwell J.S."          "Rūsiņa S."             "Sánchez-Mata D."      
    ## [55] "Schaminée J.H.J."      "Semenishchenkov Y."    "Shevchenko N."        
    ## [58] "Šibík J."              "Škvorc Ž."             "Smagin V."            
    ## [61] "Stešević D."           "Stupar V."             "Šumberová K."         
    ## [64] "Theurillat J.-P."      "Tikhonova E."          "Tzonev R."            
    ## [67] "Valachovič M."         "Vassilev K."           "Willner W."           
    ## [70] "Yamalov S."            "Večeřa M."             "Chytrý M."            
    ## 
    ## [[13]]
    ## [1] "Egea Á.V."     "Campagna M.S." "Cona M.I."     "Sartor C."    
    ## [5] "Campos C.M."  
    ## 
    ## [[14]]
    ## [1] "Janišová M."  "Širka P."     "Palpurina S." "Magnes M."    "Kuzemko A."  
    ## [6] "Dembicz I."   "Kozub Ł."    
    ## 
    ## [[15]]
    ## [1] "Idárraga-Piedrahíta Á." "González-Caro S."       "Duque Á.J."            
    ## [4] "Jiménez-Montoya J."     "González-M. R."         "Parra J.L."            
    ## [7] "Rivera-Gutiérrez H.F." 
    ## 
    ## [[16]]
    ## [1] "Roy M.-È."       "Surget-Groba Y." "Rivest D."      
    ## 
    ## [[17]]
    ## [1] "Albert Á.-J."        "Götzenberger L."     "Jongepierová I."    
    ## [4] "Konečná M."          "Lőkkösné-Kelbert B." "Májeková M."        
    ## [7] "Mudrák O."           "Klimešová J."       
    ## 
    ## [[18]]
    ##  [1] "Dembicz I."            "Dengler J."            "Steinbauer M.J."      
    ##  [4] "Matthews T.J."         "Bartha S."             "Burrascano S."        
    ##  [7] "Chiarucci A."          "Filibeck G."           "Gillet F."            
    ## [10] "Janišová M."           "Palpurina S."          "Storch D."            
    ## [13] "Ulrich W."             "Aćić S."               "Boch S."              
    ## [16] "Campos J.A."           "Cancellieri L."        "Carboni M."           
    ## [19] "Ciaschetti G."         "Conradi T."            "De Frenne P."         
    ## [22] "Dolezal J."            "Dolnik C."             "Essl F."              
    ## [25] "Fantinato E."          "García-Mijangos I."    "Giusso del Galdo G.P."
    ## [28] "Grytnes J.-A."         "Guarino R."            "Güler B."             
    ## [31] "Kapfer J."             "Klichowska E."         "Kozub Ł."             
    ## [34] "Kuzemko A."            "Löbel S."              "Manthey M."           
    ## [37] "Marcenò C."            "Mimet A."              "Naqinezhad A."        
    ## [40] "Noroozi J."            "Nowak A."              "Pauli H."             
    ## [43] "Peet R.K."             "Pellissier V."         "Pielech R."           
    ## [46] "Terzi M."              "Uğurlu E."             "Valkó O."             
    ## [49] "Vasheniak I."          "Vassilev K."           "Vynokurov D."         
    ## [52] "White H.J."            "Willner W."            "Winkler M."           
    ## [55] "Wolfrum S."            "Zhang J."              "Biurrun I."           
    ## 
    ## [[19]]
    ##   [1] "Biurrun I."             "Pielech R."             "Dembicz I."            
    ##   [4] "Gillet F."              "Kozub Ł."               "Marcenò C."            
    ##   [7] "Reitalu T."             "Van Meerbeek K."        "Guarino R."            
    ##  [10] "Chytrý M."              "Pakeman R.J."           "Preislerová Z."        
    ##  [13] "Axmanová I."            "Burrascano S."          "Bartha S."             
    ##  [16] "Boch S."                "Bruun H.H."             "Conradi T."            
    ##  [19] "De Frenne P."           "Essl F."                "Filibeck G."           
    ##  [22] "Hájek M."               "Jiménez-Alfaro B."      "Kuzemko A."            
    ##  [25] "Molnár Z."              "Pärtel M."              "Pätsch R."             
    ##  [28] "Prentice H.C."          "Roleček J."             "Sutcliffe L.M.E."      
    ##  [31] "Terzi M."               "Winkler M."             "Wu J."                 
    ##  [34] "Aćić S."                "Acosta A.T.R."          "Afif E."               
    ##  [37] "Akasaka M."             "Alatalo J.M."           "Aleffi M."             
    ##  [40] "Aleksanyan A."          "Ali A."                 "Apostolova I."         
    ##  [43] "Ashouri P."             "Bátori Z."              "Baumann E."            
    ##  [46] "Becker T."              "Belonovskaya E."        "Benito Alonso J.L."    
    ##  [49] "Berastegi A."           "Bergamini A."           "Bhatta K.P."           
    ##  [52] "Bonini I."              "Büchler M.-O."          "Budzhak V."            
    ##  [55] "Bueno Á."               "Buldrini F."            "Campos J.A."           
    ##  [58] "Cancellieri L."         "Carboni M."             "Ceulemans T."          
    ##  [61] "Chiarucci A."           "Chocarro C."            "Conti L."              
    ##  [64] "Csergő A.M."            "Cykowska-Marzencka B."  "Czarniecka-Wiera M."   
    ##  [67] "Czarnocka-Cieciura M."  "Czortek P."             "Danihelka J."          
    ##  [70] "de Bello F."            "Deák B."                "Demeter L."            
    ##  [73] "Deng L."                "Diekmann M."            "Dolezal J."            
    ##  [76] "Dolnik C."              "Dřevojan P."            "Dupré C."              
    ##  [79] "Ecker K."               "Ejtehadi H."            "Erschbamer B."         
    ##  [82] "Etayo J."               "Etzold J."              "Farkas T."             
    ##  [85] "Farzam M."              "Fayvush G."             "Fernández Calzado M.R."
    ##  [88] "Finckh M."              "Fjellstad W."           "Fotiadis G."           
    ##  [91] "García-Magro D."        "García-Mijangos I."     "Gavilán R.G."          
    ##  [94] "Germany M."             "Ghafari S."             "Giusso del Galdo G.P." 
    ##  [97] "Grytnes J.-A."          "Güler B."               "Gutiérrez-Girón A."    
    ## [100] "Helm A."                "Herrera M."             "Hüllbusch E.M."        
    ## [103] "Ingerpuu N."            "Jägerbrand A.K."        "Jandt U."              
    ## [106] "Janišová M."            "Jeanneret P."           "Jeltsch F."            
    ## [109] "Jensen K."              "Jentsch A."             "Kącki Z."              
    ## [112] "Kakinuma K."            "Kapfer J."              "Kargar M."             
    ## [115] "Kelemen A."             "Kiehl K."               "Kirschner P."          
    ## [118] "Koyama A."              "Langer N."              "Lazzaro L."            
    ## [121] "Lepš J."                "Li C.-F."               "Li F.Y."               
    ## [124] "Liendo D."              "Lindborg R."            "Löbel S."              
    ## [127] "Lomba A."               "Lososová Z."            "Lustyk P."             
    ## [130] "Luzuriaga A.L."         "Ma W."                  "Maccherini S."         
    ## [133] "Magnes M."              "Malicki M."             "Manthey M."            
    ## [136] "Mardari C."             "May F."                 "Mayrhofer H."          
    ## [139] "Meier E.S."             "Memariani F."           "Merunková K."          
    ## [142] "Michelsen O."           "Molero Mesa J."         "Moradi H."             
    ## [145] "Moysiyenko I."          "Mugnai M."              "Naqinezhad A."         
    ## [148] "Natcheva R."            "Ninot J.M."             "Nobis M."              
    ## [151] "Noroozi J."             "Nowak A."               "Onipchenko V."         
    ## [154] "Palpurina S."           "Pauli H."               "Pedashenko H."         
    ## [157] "Pedersen C."            "Peet R.K."              "Pérez-Haase A."        
    ## [160] "Peters J."              "Pipenbaher N."          "Pirini C."             
    ## [163] "Pladevall-Izard E."     "Plesková Z."            "Potenza G."            
    ## [166] "Rahmanian S."           "Rodríguez-Rojo M.P."    "Ronkin V."             
    ## [169] "Rosati L."              "Ruprecht E."            "Rusina S."             
    ## [172] "Sabovljević M."         "Sanaei A."              "Sánchez A.M."          
    ## [175] "Santi F."               "Savchenko G."           "Sebastià M.T."         
    ## [178] "Shyriaieva D."          "Silva V."               "Škornik S."            
    ## [181] "Šmerdová E."            "Sonkoly J."             "Sperandii M.G."        
    ## [184] "Staniaszek-Kik M."      "Stevens C."             "Stifter S."            
    ## [187] "Suchrow S."             "Swacha G."              "Świerszcz S."          
    ## [190] "Talebi A."              "Teleki B."              "Tichý L."              
    ## [193] "Tölgyesi C."            "Torca M."               "Török P."              
    ## [196] "Tsarevskaya N."         "Tsiripidis I."          "Turisová I."           
    ## [199] "Ushimaru A."            "Valkó O."               "Van Mechelen C."       
    ## [202] "Vanneste T."            "Vasheniak I."           "Vassilev K."           
    ## [205] "Viciani D."             "Villar L."              "Virtanen R."           
    ## [208] "Vitasović-Kosić I."     "Vojtkó A."              "Vynokurov D."          
    ## [211] "Waldén E."              "Wang Y."                "Weiser F."             
    ## [214] "Wen L."                 "Wesche K."              "White H."              
    ## [217] "Widmer S."              "Wolfrum S."             "Wróbel A."             
    ## [220] "Yuan Z."                "Zelený D."              "Zhao L."               
    ## [223] "Dengler J."            
    ## 
    ## [[20]]
    ##  [1] "Wagner V."             "Večeřa M."             "Jiménez-Alfaro B."    
    ##  [4] "Pergl J."              "Lenoir J."             "Svenning J.-C."       
    ##  [7] "Pyšek P."              "Agrillo E."            "Biurrun I."           
    ## [10] "Campos J.A."           "Ewald J."              "Fernández-González F."
    ## [13] "Jandt U."              "Rašomavičius V."       "Šilc U."              
    ## [16] "Škvorc Ž."             "Vassilev K."           "Wohlgemuth T."        
    ## [19] "Chytrý M."            
    ## 
    ## [[21]]
    ##  [1] "Sporbert M."       "Welk E."           "Seidler G."       
    ##  [4] "Jandt U."          "Aćić S."           "Biurrun I."       
    ##  [7] "Campos J.A."       "Čarni A."          "Cerabolini B.E.L."
    ## [10] "Chytrý M."         "Ćušterevska R."    "Dengler J."       
    ## [13] "De Sanctis M."     "Dziuba T."         "Fagúndez J."      
    ## [16] "Field R."          "Golub V."          "He T."            
    ## [19] "Jansen F."         "Lenoir J."         "Marcenò C."       
    ## [22] "Martín-Forés I."   "Moeslund J.E."     "Moretti M."       
    ## [25] "Niinemets Ü."      "Penuelas J."       "Pérez-Haase A."   
    ## [28] "Vandvik V."        "Vassilev K."       "Vynokurov D."     
    ## [31] "Bruelheide H."    
    ## 
    ## [[22]]
    ##  [1] "Večeřa M."             "Axmanová I."           "Padullés Cubino J."   
    ##  [4] "Lososová Z."           "Divíšek J."            "Knollová I."          
    ##  [7] "Aćić S."               "Biurrun I."            "Boch S."              
    ## [10] "Bonari G."             "Campos J.A."           "Čarni A."             
    ## [13] "Carranza M.L."         "Casella L."            "Chiarucci A."         
    ## [16] "Ćušterevska R."        "Delbosc P."            "Dengler J."           
    ## [19] "Fernández-González F." "Gégout J.-C."          "Jandt U."             
    ## [22] "Jansen F."             "Jašková A."            "Jiménez-Alfaro B."    
    ## [25] "Kuzemko A."            "Lebedeva M."           "Lenoir J."            
    ## [28] "Lysenko T."            "Moeslund J.E."         "Pielech R."           
    ## [31] "Ruprecht E."           "Šibík J."              "Šilc U."              
    ## [34] "Škvorc Ž."             "Swacha G."             "Tatarenko I."         
    ## [37] "Vassilev K."           "Wohlgemuth T."         "Yamalov S."           
    ## [40] "Chytrý M."            
    ## 
    ## [[23]]
    ## [1] "Martín-Vélez V." "Lovas-Kiss Á."   "Sánchez M.I."    "Green A.J."     
    ## 
    ## [[24]]
    ## [1] "Dembicz I."            "Moysiyenko I.I."       "Kozub Ł."             
    ## [4] "Dengler J."            "Zakharova M."          "Sudnik-Wójcikowska B."
    ## 
    ## [[25]]
    ##  [1] "Padullés Cubino J." "Jiménez-Alfaro B."  "Sabatini F.M."     
    ##  [4] "Willner W."         "Lososová Z."        "Biurrun I."        
    ##  [7] "Brunet J."          "Campos J.A."        "Indreica A."       
    ## [10] "Jansen F."          "Lenoir J."          "Škvorc Ž."         
    ## [13] "Vassilev K."        "Chytrý M."         
    ## 
    ## [[26]]
    ##  [1] "Kalníková V."    "Chytrý K."       "Biţa-Nicolae C." "Bracco F."      
    ##  [5] "Font X."         "Iakushenko D."   "Kącki Z."        "Kudrnovsky H."  
    ##  [9] "Landucci F."     "Lustyk P."       "Milanović Đ."    "Šibík J."       
    ## [13] "Šilc U."         "Uziębło A.K."    "Villani M."      "Chytrý M."      
    ## 
    ## [[27]]
    ## [1] "Marsman F."    "Nystuen K.O."  "Opedal Ø.H."   "Foest J.J."   
    ## [5] "Sørensen M.V." "De Frenne P."  "Graae B.J."    "Limpens J."   
    ## 
    ## [[28]]
    ## [1] "Gustafsson L."   "Granath G."      "Nohrstedt H.-Ö." "Leverkus A.B."  
    ## [5] "Johansson V."   
    ## 
    ## [[29]]
    ##  [1] "Bonari G."             "Fernández-González F." "Çoban S."             
    ##  [4] "Monteiro-Henriques T." "Bergmeier E."          "Didukh Y.P."          
    ##  [7] "Xystrakis F."          "Angiolini C."          "Chytrý K."            
    ## [10] "Acosta A.T.R."         "Agrillo E."            "Costa J.C."           
    ## [13] "Danihelka J."          "Hennekens S.M."        "Kavgacı A."           
    ## [16] "Knollová I."           "Neto C.S."             "Sağlam C."            
    ## [19] "Škvorc Ž."             "Tichý L."              "Chytrý M."            
    ## 
    ## [[30]]
    ##  [1] "Chytrý M."             "Tichý L."              "Hennekens S.M."       
    ##  [4] "Knollová I."           "Janssen J.A.M."        "Rodwell J.S."         
    ##  [7] "Peterka T."            "Marcenò C."            "Landucci F."          
    ## [10] "Danihelka J."          "Hájek M."              "Dengler J."           
    ## [13] "Novák P."              "Zukal D."              "Jiménez-Alfaro B."    
    ## [16] "Mucina L."             "Abdulhak S."           "Aćić S."              
    ## [19] "Agrillo E."            "Attorre F."            "Bergmeier E."         
    ## [22] "Biurrun I."            "Boch S."               "Bölöni J."            
    ## [25] "Bonari G."             "Braslavskaya T."       "Bruelheide H."        
    ## [28] "Campos J.A."           "Čarni A."              "Casella L."           
    ## [31] "Ćuk M."                "Ćušterevska R."        "De Bie E."            
    ## [34] "Delbosc P."            "Demina O."             "Didukh Y."            
    ## [37] "Dítě D."               "Dziuba T."             "Ewald J."             
    ## [40] "Gavilán R.G."          "Gégout J.-C."          "Giusso del Galdo G.P."
    ## [43] "Golub V."              "Goncharova N."         "Goral F."             
    ## [46] "Graf U."               "Indreica A."           "Isermann M."          
    ## [49] "Jandt U."              "Jansen F."             "Jansen J."            
    ## [52] "Jašková A."            "Jiroušek M."           "Kącki Z."             
    ## [55] "Kalníková V."          "Kavgacı A."            "Khanina L."           
    ## [58] "Yu. Korolyuk A."       "Kozhevnikova M."       "Kuzemko A."           
    ## [61] "Küzmič F."             "Kuznetsov O.L."        "Laiviņš M."           
    ## [64] "Lavrinenko I."         "Lavrinenko O."         "Lebedeva M."          
    ## [67] "Lososová Z."           "Lysenko T."            "Maciejewski L."       
    ## [70] "Mardari C."            "Marinšek A."           "Napreenko M.G."       
    ## [73] "Onyshchenko V."        "Pérez-Haase A."        "Pielech R."           
    ## [76] "Prokhorov V."          "Rašomavičius V."       "Rodríguez Rojo M.P."  
    ## [79] "Rūsiņa S."             "Schrautzer J."         "Šibík J."             
    ## [82] "Šilc U."               "Škvorc Ž."             "Smagin V.A."          
    ## [85] "Stančić Z."            "Stanisci A."           "Tikhonova E."         
    ## [88] "Tonteri T."            "Uogintas D."           "Valachovič M."        
    ## [91] "Vassilev K."           "Vynokurov D."          "Willner W."           
    ## [94] "Yamalov S."            "Evans D."              "Palitzsch Lund M."    
    ## [97] "Spyropoulou R."        "Tryfon E."             "Schaminée J.H.J."     
    ## 
    ## [[31]]
    ## [1] "Škvorc Ž."     "Ćuk M."        "Zelnik I."     "Franjić J."   
    ## [5] "Igić R."       "Ilić M."       "Krstonošić D." "Vukov D."     
    ## [9] "Čarni A."     
    ## 
    ## [[32]]
    ## [1] "Meira-Neto J.A.A."  "Nunes Cândido H.M." "Miazaki Â."        
    ## [4] "Pontara V."         "Bueno M.L."         "Solar R."          
    ## [7] "Gastauer M."       
    ## 
    ## [[33]]
    ## [1] "Trujillo L.N."          "Granzow-de la Cerda Í." "Pardo I."              
    ## [4] "Macía M.J."             "Cala V."                "Arellano G."           
    ## 
    ## [[34]]
    ## [1] "Bitomský M." "Mládková P." "Cimalová Š." "Mládek J."  
    ## 
    ## [[35]]
    ##   [1] "Bruelheide H."         "Dengler J."            "Jiménez-Alfaro B."    
    ##   [4] "Purschke O."           "Hennekens S.M."        "Chytrý M."            
    ##   [7] "Pillar V.D."           "Jansen F."             "Kattge J."            
    ##  [10] "Sandel B."             "Aubin I."              "Biurrun I."           
    ##  [13] "Field R."              "Haider S."             "Jandt U."             
    ##  [16] "Lenoir J."             "Peet R.K."             "Peyre G."             
    ##  [19] "Sabatini F.M."         "Schmidt M."            "Schrodt F."           
    ##  [22] "Winter M."             "Aćić S."               "Agrillo E."           
    ##  [25] "Alvarez M."            "Ambarlı D."            "Angelini P."          
    ##  [28] "Apostolova I."         "Arfin Khan M.A.S."     "Arnst E."             
    ##  [31] "Attorre F."            "Baraloto C."           "Beckmann M."          
    ##  [34] "Berg C."               "Bergeron Y."           "Bergmeier E."         
    ##  [37] "Bjorkman A.D."         "Bondareva V."          "Borchardt P."         
    ##  [40] "Botta-Dukát Z."        "Boyle B."              "Breen A."             
    ##  [43] "Brisse H."             "Byun C."               "Cabido M.R."          
    ##  [46] "Casella L."            "Cayuela L."            "Černý T."             
    ##  [49] "Chepinoga V."          "Csiky J."              "Curran M."            
    ##  [52] "Ćušterevska R."        "Dajić Stevanović Z."   "De Bie E."            
    ##  [55] "de Ruffray P."         "De Sanctis M."         "Dimopoulos P."        
    ##  [58] "Dressler S."           "Ejrnæs R."             "El-Sheikh M.A.E.-R.M."
    ##  [61] "Enquist B."            "Ewald J."              "Fagúndez J."          
    ##  [64] "Finckh M."             "Font X."               "Forey E."             
    ##  [67] "Fotiadis G."           "García-Mijangos I."    "de Gasper A.L."       
    ##  [70] "Golub V."              "Gutierrez A.G."        "Hatim M.Z."           
    ##  [73] "He T."                 "Higuchi P."            "Holubová D."          
    ##  [76] "Hölzel N."             "Homeier J."            "Indreica A."          
    ##  [79] "Işık Gürsoy D."        "Jansen S."             "Janssen J."           
    ##  [82] "Jedrzejek B."          "Jiroušek M."           "Jürgens N."           
    ##  [85] "Kącki Z."              "Kavgacı A."            "Kearsley E."          
    ##  [88] "Kessler M."            "Knollová I."           "Kolomiychuk V."       
    ##  [91] "Korolyuk A."           "Kozhevnikova M."       "Kozub Ł."             
    ##  [94] "Krstonošić D."         "Kühl H."               "Kühn I."              
    ##  [97] "Kuzemko A."            "Küzmič F."             "Landucci F."          
    ## [100] "Lee M.T."              "Levesley A."           "Li C.-F."             
    ## [103] "Liu H."                "Lopez-Gonzalez G."     "Lysenko T."           
    ## [106] "Macanović A."          "Mahdavi P."            "Manning P."           
    ## [109] "Marcenò C."            "Martynenko V."         "Mencuccini M."        
    ## [112] "Minden V."             "Moeslund J.E."         "Moretti M."           
    ## [115] "Müller J.V."           "Munzinger J."          "Niinemets Ü."         
    ## [118] "Nobis M."              "Noroozi J."            "Nowak A."             
    ## [121] "Onyshchenko V."        "Overbeck G.E."         "Ozinga W.A."          
    ## [124] "Pauchard A."           "Pedashenko H."         "Peñuelas J."          
    ## [127] "Pérez-Haase A."        "Peterka T."            "Petřík P."            
    ## [130] "Phillips O.L."         "Prokhorov V."          "Rašomavičius V."      
    ## [133] "Revermann R."          "Rodwell J."            "Ruprecht E."          
    ## [136] "Rūsiņa S."             "Samimi C."             "Schaminée J.H.J."     
    ## [139] "Schmiedel U."          "Šibík J."              "Šilc U."              
    ## [142] "Škvorc Ž."             "Smyth A."              "Sop T."               
    ## [145] "Sopotlieva D."         "Sparrow B."            "Stančić Z."           
    ## [148] "Svenning J.-C."        "Swacha G."             "Tang Z."              
    ## [151] "Tsiripidis I."         "Turtureanu P.D."       "Uğurlu E."            
    ## [154] "Uogintas D."           "Valachovič M."         "Vanselow K.A."        
    ## [157] "Vashenyak Y."          "Vassilev K."           "Vélez-Martin E."      
    ## [160] "Venanzoni R."          "Vibrans A.C."          "Violle C."            
    ## [163] "Virtanen R."           "von Wehrden H."        "Wagner V."            
    ## [166] "Walker D.A."           "Wana D."               "Weiher E."            
    ## [169] "Wesche K."             "Whitfeld T."           "Willner W."           
    ## [172] "Wiser S."              "Wohlgemuth T."         "Yamalov S."           
    ## [175] "Zizka G."              "Zverev A."            
    ## 
    ## [[36]]
    ## [1] "Nystuen K.O."   "Sundsdal K."    "Opedal Ø.H."    "Holien H."     
    ## [5] "Strimbeck G.R." "Graae B.J."    
    ## 
    ## [[37]]
    ## [1] "Kozub Ł."       "Goldstein K."   "Dembicz I."     "Wilk M."       
    ## [5] "Wyszomirski T." "Kotowski W."   
    ## 
    ## [[38]]
    ##  [1] "Verheyen K."        "Bažány M."          "Chećko E."         
    ##  [4] "Chudomelová M."     "Closset-Kopp D."    "Czortek P."        
    ##  [7] "Decocq G."          "De Frenne P."       "De Keersmaeker L." 
    ## [10] "Enríquez García C." "Fabšičová M."       "Grytnes J.-A."     
    ## [13] "Hederová L."        "Hédl R."            "Heinken T."        
    ## [16] "Schei F.H."         "Horváth S."         "Jaroszewicz B."    
    ## [19] "Jermakowicz E."     "Klinerová T."       "Kolk J."           
    ## [22] "Kopecký M."         "Kuras I."           "Lenoir J."         
    ## [25] "Macek M."           "Máliš F."           "Martinessen T.C."  
    ## [28] "Naaf T."            "Papp L."            "Papp-Szakály Á."   
    ## [31] "Pech P."            "Petřík P."          "Prach J."          
    ## [34] "Reczyńska K."       "Sætersdal M."       "Spicher F."        
    ## [37] "Standovár T."       "Świerkosz K."       "Szczęśniak E."     
    ## [40] "Tóth Z."            "Ujházy K."          "Ujházyová M."      
    ## [43] "Vangansbeke P."     "Vild O."            "Wołkowycki D."     
    ## [46] "Wulf M."            "Baeten L."         
    ## 
    ## [[39]]
    ## [1] "Øien D.-I."   "Pedersen B."  "Kozub Ł."     "Goldstein K." "Wilk M."     
    ## 
    ## [[40]]
    ##  [1] "Andrade B.O."       "Bonilha C.L."       "Overbeck G.E."     
    ##  [4] "Vélez-Martin E."    "Rolim R.G."         "Bordignon S.A.L."  
    ##  [7] "Schneider A.A."     "Vogel Ely C."       "Lucas D.B."        
    ## [10] "Garcia É.N."        "dos Santos E.D."    "Torchelsen F.P."   
    ## [13] "Vieira M.S."        "Silva Filho P.J.S." "Ferreira P.M.A."   
    ## [16] "Trevisan R."        "Hollas R."          "Campestrini S."    
    ## [19] "Pillar V.D."        "Boldrini I.I."     
    ## 
    ## [[41]]
    ##  [1] "Takkis K."   "Kull T."     "Hallikma T." "Jaksi P."    "Kaljund K." 
    ##  [6] "Kauer K."    "Kull T."     "Kurina O."   "Külvik M."   "Lanno K."   
    ## [11] "Leht M."     "Liira J."    "Melts I."    "Pehlak H."   "Raet J."    
    ## [16] "Sammet K."   "Sepp K."     "Väli Ü."     "Laanisto L."
    ## 
    ## [[42]]
    ## [1] "Weekes L."      "Kącki Z."       "FitzPatrick Ú." "Kelly F."      
    ## [5] "Matson R."      "Kelly-Quinn M."
    ## 
    ## [[43]]
    ##  [1] "Marcenò C."          "Guarino R."          "Loidi J."           
    ##  [4] "Herrera M."          "Isermann M."         "Knollová I."        
    ##  [7] "Tichý L."            "Tzonev R.T."         "Acosta A.T.R."      
    ## [10] "FitzPatrick Ú."      "Iakushenko D."       "Janssen J.A.M."     
    ## [13] "Jiménez-Alfaro B."   "Kącki Z."            "Keizer-Sedláková I."
    ## [16] "Kolomiychuk V."      "Rodwell J.S."        "Schaminée J.H.J."   
    ## [19] "Šilc U."             "Chytrý M."          
    ## 
    ## [[44]]
    ## [1] "Ranlund Å."    "Hylander K."   "Johansson V."  "Jonsson F."   
    ## [5] "Nordin U."     "Gustafsson L."
    ## 
    ## [[45]]
    ## [1] "Ullerud H.A." "Bryn A."      "Halvorsen R." "Hemsing L.Ø."
    ## 
    ## [[46]]
    ##  [1] "Willner W."        "Jiménez-Alfaro B." "Agrillo E."       
    ##  [4] "Biurrun I."        "Campos J.A."       "Čarni A."         
    ##  [7] "Casella L."        "Csiky J."          "Ćušterevska R."   
    ## [10] "Didukh Y.P."       "Ewald J."          "Jandt U."         
    ## [13] "Jansen F."         "Kącki Z."          "Kavgacı A."       
    ## [16] "Lenoir J."         "Marinšek A."       "Onyshchenko V."   
    ## [19] "Rodwell J.S."      "Schaminée J.H.J."  "Šibík J."         
    ## [22] "Škvorc Ž."         "Svenning J.-C."    "Tsiripidis I."    
    ## [25] "Turtureanu P.D."   "Tzonev R."         "Vassilev K."      
    ## [28] "Venanzoni R."      "Wohlgemuth T."     "Chytrý M."        
    ## 
    ## [[47]]
    ## [1] "Somodi I."       "Molnár Z."       "Czúcz B."        "Bede-Fazekas Á."
    ## [5] "Bölöni J."       "Pásztor L."      "Laborczi A."     "Zimmermann N.E."
    ## 
    ## [[48]]
    ##  [1] "Peterka T."          "Hájek M."            "Jiroušek M."        
    ##  [4] "Jiménez-Alfaro B."   "Aunina L."           "Bergamini A."       
    ##  [7] "Dítě D."             "Felbaba-Klushyna L." "Graf U."            
    ## [10] "Hájková P."          "Hettenbergerová E."  "Ivchenko T.G."      
    ## [13] "Jansen F."           "Koroleva N.E."       "Lapshina E.D."      
    ## [16] "Lazarević P.M."      "Moen A."             "Napreenko M.G."     
    ## [19] "Pawlikowski P."      "Plesková Z."         "Sekulová L."        
    ## [22] "Smagin V.A."         "Tahvanainen T."      "Thiele A."          
    ## [25] "Biţǎ-Nicolae C."     "Biurrun I."          "Brisse H."          
    ## [28] "Ćušterevska R."      "De Bie E."           "Ewald J."           
    ## [31] "FitzPatrick Ú."      "Font X."             "Jandt U."           
    ## [34] "Kącki Z."            "Kuzemko A."          "Landucci F."        
    ## [37] "Moeslund J.E."       "Pérez-Haase A."      "Rašomavičius V."    
    ## [40] "Rodwell J.S."        "Schaminée J.H.J."    "Šilc U."            
    ## [43] "Stančić Z."          "Chytrý M."          
    ## 
    ## [[49]]
    ##  [1] "Moles A.T."          "Perkins S.E."        "Laffan S.W."        
    ##  [4] "Flores-Moreno H."    "Awasthy M."          "Tindall M.L."       
    ##  [7] "Sack L."             "Pitman A."           "Kattge J."          
    ## [10] "Aarssen L.W."        "Anand M."            "Bahn M."            
    ## [13] "Blonder B."          "Cavender-Bares J."   "Cornelissen J.H.C." 
    ## [16] "Cornwell W.K."       "Díaz S."             "Dickie J.B."        
    ## [19] "Freschet G.T."       "Griffiths J.G."      "Gutierrez A.G."     
    ## [22] "Hemmings F.A."       "Hickler T."          "Hitchcock T.D."     
    ## [25] "Keighery M."         "Kleyer M."           "Kurokawa H."        
    ## [28] "Leishman M.R."       "Liu K."              "Niinemets"          
    ## [31] "Onipchenko V."       "Onoda Y."            "Penuelas J."        
    ## [34] "Pillar V.D."         "Reich P.B."          "Shiodera S."        
    ## [37] "Siefert A."          "Sosinski E.E., Jr."  "Soudzilovskaia N.A."
    ## [40] "Swaine E.K."         "Swenson N.G."        "van Bodegom P.M."   
    ## [43] "Warman L."           "Weiher E."           "Wright I.J."        
    ## [46] "Zhang H."            "Zobel M."            "Bonser S.P."        
    ## 
    ## [[50]]
    ## [1] "Hájková P."     "Hájek M."       "Rybníček K."    "Jiroušek M."   
    ## [5] "Tichý L."       "Králová Š."     "Mikulášková E."
    ## 
    ## [[51]]
    ## [1] "Gallegos Torell Å." "Glimskär A."       
    ## 
    ## [[52]]
    ## [1] "Aavik T." "Jõgar Ü." "Liira J." "Tulva I." "Zobel M."
    ## 
    ## [[53]]
    ## [1] "Fritz Ö."     "Niklasson M." "Churski M."  
    ## 
    ## [[54]]
    ## [1] "Toledo-Aceves" "Swaine M.D."  
    ## 
    ## [[55]]
    ## [1] "Gunnarsson U." "Flodin L.-Å." 
    ## 
    ## [[56]]
    ## [1] "Lososová Z." "Chytrý M."   "Cimalová Š." "Kropáč Z."   "Otýpková Z."
    ## [6] "Pyšek P."    "Tichý L."   
    ## 
    ## [[57]]
    ## [1] "Dag-Inge Ø." "Asbjørn M." 
    ## 
    ## [[58]]
    ##  [1] "Jarvis P.G."    "Dolman A.J."    "Schulze E.-D."  "Matteucci G."  
    ##  [5] "Kowalski A.S."  "Ceulemans R."   "Rebmann C."     "Moors E.J."    
    ##  [9] "Granier A."     "Gross P."       "Jensen N.O."    "Pilegaard K."  
    ## [13] "Lindroth A."    "Grelle A."      "Bernhofer C."   "Grünwald T."   
    ## [17] "Aubinet M."     "Vesala T."      "Rannik Ü."      "Berbigier P."  
    ## [21] "Loustau D."     "Guômundsson J." "Ibrom A."       "Morgenstern K."
    ## [25] "Clement R."     "Moncrieff J."   "Montagnani L."  "Minerbi S."    
    ## [29] "Valentini R."  
    ## 
    ## [[59]]
    ## [1] "Eriksson Å." "Eriksson O."
    ## 
    ## [[60]]
    ## [1] "Brunet J."            "Falkengren-Grerup U." "Rühling Å."          
    ## [4] "Tyler G."            
    ## 
    ## [[61]]
    ## [1] "Antonić O."  "Lovrić A.Ž."
    ## 
    ## [[62]]
    ## [1] "Yamamoto S.‐I." "Nishimura N."   "Matsui K."     
    ## 
    ## [[63]]
    ## [1] "Okitsu S." "Ito K."    "Li C.‐h." 
    ## 
    ## [[64]]
    ## [1] "Maubon M."   "Ponge J.‐F." "André J."   
    ## 
    ## [[65]]
    ## [1] "Cao K.‐f."      "Peters R."      "Oldeman R.A.A."
    ## 
    ## [[66]]
    ## [1] "Trémolières M." "Carbiener R."   "Ortscheit A."   "Klein J.‐P."   
    ## 
    ## [[67]]
    ## [1] "Mordelet P."  "Menaut J.‐C."
    ## 
    ## [[68]]
    ## [1] "Camenisch M." "Géhu J.‐M."  
    ## 
    ## [[69]]
    ## [1] "Bergeron Y."     "Dansereau P.‐R."
    ## 
    ## [[70]]
    ## [1] "Mäkirinta A.‐M."
    ## 
    ## [[71]]
    ## [1] "Tapper P.‐G."
    ## 
    ## [[72]]
    ## [1] "Borgegård S.‐O."

``` r
all(sapply(sepAbbAuthors,length) == sapply(sepAuthors,length))
```

    ## [1] TRUE

``` r
allInOne<-Reduce(rbind,treatedFullNames)
length(unique(allInOne$authorId))
```

    ## [1] 10654

``` r
A<-tapply(allInOne$verbatim,allInOne$authorId,unique)
A[sapply(A,length)>1]
```

    ## $`10040202500`
    ## [1] "Chang, Esther R. (10040202500)" "Chang, E.R. (10040202500)"     
    ## 
    ## $`10238977700`
    ## [1] "Šibík, Jozef (10238977700)" "Šibik, Jozef (10238977700)"
    ## 
    ## $`10440589300`
    ## [1] "Westbury, Duncan B. (10440589300)" "Westbury, D.B. (10440589300)"     
    ## 
    ## $`10639674700`
    ## [1] "Urrego, Dunia H (10639674700)"  "Urrego, Dunia H. (10639674700)"
    ## 
    ## $`10641980000`
    ## [1] "Cañellas, Isabel (10641980000)" "Cañellas, I. (10641980000)"    
    ## 
    ## $`12040626400`
    ## [1] "Graf, Ulrich H. (12040626400)" "Graf, Ulrich (12040626400)"   
    ## 
    ## $`12244200500`
    ## [1] "Navarro, Francisco B. (12244200500)" "Navarro, F.B. (12244200500)"        
    ## 
    ## $`12244260300`
    ## [1] "Vaieretti, María Victoria (12244260300)"
    ## [2] "Vaieretti, M.V. (12244260300)"          
    ## 
    ## $`12545539700`
    ## [1] "Treydte, Anna Christina (12545539700)"
    ## [2] "Treydte, Anna C. (12545539700)"       
    ## 
    ## $`12753381600`
    ## [1] "Texeira, M. (12753381600)"        "Texeira, Marcos A. (12753381600)"
    ## 
    ## $`12759708300`
    ## [1] "Bartelheimer, Maik (12759708300)" "Bartelheimer, M. (12759708300)"  
    ## 
    ## $`12766523800`
    ## [1] "Hart, Justin L. (12766523800)"   "Hart, Justin Lane (12766523800)"
    ## 
    ## $`12784994700`
    ## [1] "Kalwij, Jesse Machiel (12784994700)" "Kalwij, Jesse M. (12784994700)"     
    ## 
    ## $`12785984900`
    ## [1] "Reilly, Matthew J. (12785984900)" "Reilly, Matthew (12785984900)"   
    ## 
    ## $`12796580400`
    ## [1] "Palma, Ana C. (12796580400)"       "Palma, Ana Cristina (12796580400)"
    ## 
    ## $`12800237000`
    ## [1] "Černý, Tomáš (12800237000)" "Černý, T. (12800237000)"   
    ## 
    ## $`12805884300`
    ## [1] "Härdtle, Werner (12805884300)" "Härdtle, W. (12805884300)"    
    ## 
    ## $`12902779200`
    ## [1] "Tecco, Paula A. (12902779200)" "Tecco, P.A. (12902779200)"    
    ## [3] "Tecco, A. (12902779200)"      
    ## 
    ## $`13305252700`
    ## [1] "Ross, Karen A. (13305252700)" "Ross, K.A. (13305252700)"    
    ## 
    ## $`13403767300`
    ## [1] "Piñeiro, Gervasio (13403767300)" "Piñeiro, G. (13403767300)"      
    ## 
    ## $`13609806400`
    ## [1] "Matesanz, Silvia (13609806400)" "Matesanz, S. (13609806400)"    
    ## 
    ## $`14059584400`
    ## [1] "Boughton, Elizabeth H. (14059584400)"
    ## [2] "Boughton, E.A. (14059584400)"        
    ## 
    ## $`14622394000`
    ## [1] "Garbin, Mário Luís (14622394000)" "Garbin, Mário L. (14622394000)"  
    ## 
    ## $`14630087700`
    ## [1] "Baeza, Santiago (14630087700)" "Baeza, S. (14630087700)"      
    ## 
    ## $`14819243000`
    ## [1] "Belinchón, R. (14819243000)"    "Belinchón, Rocío (14819243000)"
    ## 
    ## $`14826751200`
    ## [1] "Marques, Marcia C. M. (14826751200)"          
    ## [2] "Marques, Marcia Cristina Mendes (14826751200)"
    ## [3] "Marques, Marcia C.M. (14826751200)"           
    ## 
    ## $`14832442500`
    ## [1] "Janeček, Štěpán (14832442500)" "Janeček, Š (14832442500)"     
    ## 
    ## $`15022098700`
    ## [1] "Fabšičová, Martina (15022098700)" "Fabšičová, M. (15022098700)"     
    ## 
    ## $`15028126900`
    ## [1] "Cornwell, William K. (15028126900)" "Cornwell, Will K. (15028126900)"   
    ## 
    ## $`15051082700`
    ## [1] "Rodríguez-Echeverría, Susana (15051082700)"
    ## [2] "Rodríguez-Echeverría, S. (15051082700)"    
    ## 
    ## $`15081915300`
    ## [1] "Stella, John (15081915300)"    "Stella, John C. (15081915300)"
    ## 
    ## $`15120189400`
    ## [1] "Moskalenko, Natalya (15120189400)" "Moskalenko, N.G. (15120189400)"   
    ## 
    ## $`15126867400`
    ## [1] "Allegrezza, Marina (15126867400)" "Allegrezza, M. (15126867400)"    
    ## 
    ## $`15136796700`
    ## [1] "Munhoz, Cássia Beatriz Rodrigues (15136796700)"
    ## [2] "Munhoz, Cássia B.R. (15136796700)"             
    ## 
    ## $`15520350800`
    ## [1] "von Wehrden, Henrik (15520350800)" "Von Wehrden, Henrik (15520350800)"
    ## 
    ## $`15623611400`
    ## [1] "van Aardt, Jan A.N. (15623611400)" "van Aardt, Jan (15623611400)"     
    ## 
    ## $`15836906900`
    ## [1] "de Lima, Renato A. Ferreira (15836906900)"
    ## [2] "De Lima, Renato Augusto F. (15836906900)" 
    ## 
    ## $`15843808900`
    ## [1] "Machado, Rafael E. (15843808900)" "Machado, R.E. (15843808900)"     
    ## 
    ## $`16021876800`
    ## [1] "FitzPatrick, Úna (16021876800)" "Fitzpatrick, Úna (16021876800)"
    ## 
    ## $`16039888800`
    ## [1] "Marinšek, Aleksander (16039888800)" "Marinšek, A. (16039888800)"        
    ## 
    ## $`16178149500`
    ## [1] "Robroek, Bjorn J. M. (16178149500)" "Robroek, Bjorn J.M. (16178149500)" 
    ## [3] "Robroek, B.J.M. (16178149500)"     
    ## 
    ## $`16217773900`
    ## [1] "Van Andel, J. (16217773900)"    "Van Andel, Jelte (16217773900)"
    ## 
    ## $`16231951300`
    ## [1] "Thébault, A. (16231951300)"        "The´bault, Aure´lie (16231951300)"
    ## 
    ## $`16239227000`
    ## [1] "Martínez-Ruiz, C. (16239227000)"      
    ## [2] "Martínez-Ruiz, Carolina (16239227000)"
    ## [3] "Martínez Ruiz, Carolina (16239227000)"
    ## 
    ## $`16240059900`
    ## [1] "Rogers, Paul C. (16240059900)" "Rogers Paul, C. (16240059900)"
    ## 
    ## $`16308762100`
    ## [1] "Becerra, Pablo I. (16308762100)" "Becerra, P.I. (16308762100)"    
    ## 
    ## $`16315816500`
    ## [1] "Giehl, Eduardo L. H. (16315816500)" "Giehl, Eduardo L.H. (16315816500)" 
    ## 
    ## $`16319565200`
    ## [1] "Pál, Róbert (16319565200)"    "Pál, Róbert W. (16319565200)"
    ## 
    ## $`16414576700`
    ## [1] "Perelman, Susana (16414576700)"    "Perelman, Susana B. (16414576700)"
    ## [3] "Perelman, S.B. (16414576700)"     
    ## 
    ## $`16419270700`
    ## [1] "Martinez Carretero, E. (16419270700)"     
    ## [2] "Martínez Carretero, Eduardo (16419270700)"
    ## 
    ## $`16444133400`
    ## [1] "Archibald, Sally (16444133400)" "Archibald, S. (16444133400)"   
    ## 
    ## $`16444470500`
    ## [1] "Lopez-Gonzalez, Gabriela (16444470500)"
    ## [2] "Lopez-Gonzalez, G. (16444470500)"      
    ## 
    ## $`16479754400`
    ## [1] "Bader, Maaike Y. (16479754400)" "Bader, Maaike Y. (16479754400)"
    ## 
    ## $`16480902200`
    ## [1] "Oliva, Francesc (16480902200)" "Oliva, F. (16480902200)"      
    ## 
    ## $`16531609800`
    ## [1] "Pignatti, Sandro (16531609800)" "Pignatti, S. (16531609800)"    
    ## 
    ## $`16547065300`
    ## [1] "Orshan, G. (16547065300)"     "Orshan, Gideon (16547065300)"
    ## 
    ## $`16634984800`
    ## [1] "Martín Bruschetti, Carlos (16634984800)"
    ## [2] "Bruschetti, Carlos Martín (16634984800)"
    ## 
    ## $`16837221900`
    ## [1] "Miranda, Juan de Dios (16837221900)" "De Dios Miranda, Juan (16837221900)"
    ## 
    ## $`17134394800`
    ## [1] "Blanco, Carolina C. (17134394800)" "Blanco, Carolina (17134394800)"   
    ## 
    ## $`17135626800`
    ## [1] "Piedade, Sônia Maria De S. (17135626800)"     
    ## [2] "Piedade, Sônia Maria De Stefano (17135626800)"
    ## 
    ## $`17136330600`
    ## [1] "Ruprecht, Eszter-Karolina (17136330600)"
    ## [2] "Ruprecht, Eszter (17136330600)"         
    ## 
    ## $`18436550200`
    ## [1] "Ferreira, Joice Nunes (18436550200)" "Joice N., Ferreira (18436550200)"   
    ## 
    ## $`20734084800`
    ## [1] "Golodets, Carly (20734084800)" "Carly, Golodets (20734084800)"
    ## 
    ## $`20734998800`
    ## [1] "Moreno, Gerardo (20734998800)"   "Moreno-Marcos, G. (20734998800)"
    ## 
    ## $`22133706500`
    ## [1] "Beaty, Robert M. (22133706500)"  "Beaty, R. Matthew (22133706500)"
    ## 
    ## $`22940696600`
    ## [1] "Klimkowska, Agata (22940696600)" "Klimkowska, A. (22940696600)"   
    ## 
    ## $`22941217900`
    ## [1] "Minckley, Thomas A. (22941217900)" "Minckley, T.A. (22941217900)"     
    ## 
    ## $`22952808500`
    ## [1] "Dwyer, John Matthew (22952808500)" "Dwyer, John M. (22952808500)"     
    ## [3] "Dwyer, J.M. (22952808500)"        
    ## 
    ## $`22959047300`
    ## [1] "Taoda, Hirosi (22959047300)"  "Taoda, Hiroshi (22959047300)"
    ## 
    ## $`23010184800`
    ## [1] "Riis-Nielsen, Torben (23010184800)" "Riis-Nielsen, T. (23010184800)"    
    ## 
    ## $`23012288400`
    ## [1] "Jamsran, Undarmaa (23012288400)" "Jamsran, U. (23012288400)"      
    ## 
    ## $`23012489700`
    ## [1] "Sasaki, Takehiro (23012489700)" "Sasaki, T. (23012489700)"      
    ## 
    ## $`23018594700`
    ## [1] "Gil-Tena, Assu (23018594700)" "Gil-Tena, A. (23018594700)"  
    ## 
    ## $`23023938700`
    ## [1] "Bloor, Juliette M.G. (23023938700)"  "Bloor, Juliette M. G. (23023938700)"
    ## 
    ## $`23026772500`
    ## [1] "Carlucci, Marcos Bergmann (23026772500)"
    ## [2] "Carlucci, Marcos B. (23026772500)"      
    ## 
    ## $`23033066800`
    ## [1] "Arthaud, Florent (23033066800)" "Arthaud, F. (23033066800)"     
    ## 
    ## $`23088206100`
    ## [1] "Essl, Franz (23088206100)" "Franz, Essl (23088206100)"
    ## 
    ## $`23088835100`
    ## [1] "Liancourt, Pierre (23088835100)" "Liancourt, P.D. (23088835100)"  
    ## [3] "Liancourt, P. (23088835100)"    
    ## 
    ## $`23090509600`
    ## [1] "Drozdowski, Stanisław (23090509600)" "Drozdowski, Stanislaw (23090509600)"
    ## 
    ## $`23095240000`
    ## [1] "Rosado, Bruno H.P. (23095240000)"      
    ## [2] "Rosado, Bruno enrique P. (23095240000)"
    ## 
    ## $`23110942100`
    ## [1] "Måren, Inger E. (23110942100)" "Maren, Inger E. (23110942100)"
    ## 
    ## $`23396429900`
    ## [1] "Fernández-Ondoño, Emilia (23396429900)"
    ## [2] "Fernández-Ondoño, E. (23396429900)"    
    ## 
    ## $`23399257600`
    ## [1] "Zelený, David (23399257600)" "Zelenỳ, David (23399257600)"
    ## 
    ## $`23467376800`
    ## [1] "Moysiyenko, Ivan (23467376800)"   "Moysiyenko, Ivan I (23467376800)"
    ## 
    ## $`23472958100`
    ## [1] "Holz, Andrés (23472958100)"    "Holz, C. Andrés (23472958100)"
    ## 
    ## $`23481250100`
    ## [1] "Abdallah, Fathia (23481250100)" "Abdallah, F. (23481250100)"    
    ## 
    ## $`23485668300`
    ## [1] "Johansson, L.J. (23485668300)"      "Johansson, Lotten J. (23485668300)"
    ## 
    ## $`23485704200`
    ## [1] "Hall, Karin (23485704200)" "Hall, K. (23485704200)"   
    ## 
    ## $`23486601900`
    ## [1] "Reitalu, Triin (23486601900)" "Reitalu, T. (23486601900)"   
    ## 
    ## $`23488793800`
    ## [1] "Kreyling, Juergen (23488793800)" "Kreyling, Jürgen (23488793800)" 
    ## 
    ## $`23492149500`
    ## [1] "Ecker, Klaus T. (23492149500)" "Ecker, Klaus (23492149500)"   
    ## 
    ## $`23567460300`
    ## [1] "Javier, Cabello (23567460300)" "Cabello, J. (23567460300)"    
    ## 
    ## $`23568038800`
    ## [1] "Leppälä, Mirva (23568038800)" "Leppälä, M. (23568038800)"   
    ## 
    ## $`23969137800`
    ## [1] "Lehmann, Caroline Elisabeth Randlev (23969137800)"
    ## [2] "Lehmann, Caroline E. R. (23969137800)"            
    ## 
    ## $`24069735000`
    ## [1] "Bejarano, Maria Dolores (24069735000)"
    ## [2] "Bejarano, María Dolores (24069735000)"
    ## 
    ## $`24069765900`
    ## [1] "Blanco-Moreno, José Manuel (24069765900)"
    ## [2] "Bianco-Moreno, J.M. (24069765900)"       
    ## 
    ## $`24080643000`
    ## [1] "Monteiro-Henriques, Tiago (24080643000)"
    ## [2] "Monteiro-Henriques, T. (24080643000)"   
    ## 
    ## $`24170041700`
    ## [1] "Uğurlu, Emin (24170041700)" "Uǧurlu, Emin (24170041700)"
    ## 
    ## $`24280919900`
    ## [1] "Bernhardt-Römermann, Markus (24280919900)"
    ## [2] "Bernhardt-Römermann, M. (24280919900)"    
    ## 
    ## $`24342267600`
    ## [1] "Terrail, Raphaële (24342267600)" "Terrail, R. (24342267600)"      
    ## 
    ## $`24348390800`
    ## [1] "Mazzoleni, Stefano (24348390800)" "Mazzoleni, S. (24348390800)"     
    ## 
    ## $`24365716500`
    ## [1] "Fried, Guillaume (24365716500)" "Fried, G. (24365716500)"       
    ## 
    ## $`24450223300`
    ## [1] "Burton, Julia I (24450223300)"  "Burton, Julia I. (24450223300)"
    ## 
    ## $`24450618800`
    ## [1] "Lenoir, Jonathan (24450618800)" "Lenoir, J. (24450618800)"      
    ## 
    ## $`24463232500`
    ## [1] "Domingo, Alcaraz-Segura (24463232500)"
    ## [2] "Alcaraz, D. (24463232500)"            
    ## 
    ## $`24556291700`
    ## [1] "Lamont, Byron B. (24556291700)" "Lamont, B.B. (24556291700)"    
    ## 
    ## $`24597614700`
    ## [1] "Alday, Josu G. (24597614700)"     "González-Alday, J. (24597614700)"
    ## 
    ## $`24783884000`
    ## [1] "Martín De Agar, P. (24783884000)" "Martín de Agar, P. (24783884000)"
    ## 
    ## $`24785660000`
    ## [1] "Zobel, Martin (24785660000)" "Zobel, M. (24785660000)"    
    ## 
    ## $`24831882000`
    ## [1] "Cimalová, Šárka (24831882000)" "Cimalová, Š. (24831882000)"   
    ## 
    ## $`25224308200`
    ## [1] "Spindelböck, Joachim (25224308200)"   
    ## [2] "Spindelböck, Joachim P. (25224308200)"
    ## 
    ## $`25421283600`
    ## [1] "Batllori, Enric (25421283600)" "Batllori, E. (25421283600)"   
    ## 
    ## $`25423122500`
    ## [1] "Ribeiro, Danilo B. (25423122500)"     
    ## [2] "Ribeiro, Danilo Bandini (25423122500)"
    ## 
    ## $`25637135400`
    ## [1] "Bullock, James M. (25637135400)" "Bullock, J.M. (25637135400)"    
    ## 
    ## $`25653713300`
    ## [1] "Evans, Chris D. (25653713300)"    "Evans, Christopher (25653713300)"
    ## 
    ## $`25824822200`
    ## [1] "Costa, A. (25824822200)"      "Costa, N. Alan (25824822200)"
    ## 
    ## $`25924716500`
    ## [1] "Afif, Elias (25924716500)"        "Khouri, Elías Afif (25924716500)"
    ## 
    ## $`25944671000`
    ## [1] "Michálek, Jaroslav (25944671000)" "Michálek, J. (25944671000)"      
    ## 
    ## $`26023590300`
    ## [1] "Pezzatti, Gianni Boris (26023590300)"
    ## [2] "Pezzatti, Gianni B. (26023590300)"   
    ## 
    ## $`26024021000`
    ## [1] "Van Zonneveld, Maarten (26024021000)"   
    ## [2] "van Zonneveld, Maarten J. (26024021000)"
    ## 
    ## $`26025809800`
    ## [1] "Rossatto, Davi R. (26025809800)"     
    ## [2] "Rossatto, Davi Rodrigo (26025809800)"
    ## 
    ## $`26027245500`
    ## [1] "Speed, James David Mervyn (26027245500)"
    ## [2] "Speed, James D. M. (26027245500)"       
    ## [3] "Speed, James D.M. (26027245500)"        
    ## 
    ## $`26029187400`
    ## [1] "Purschke, Oliver (26029187400)" "Purschke, O. (26029187400)"    
    ## 
    ## $`26040902100`
    ## [1] "López, Dardo Rubén (26040902100)" "López, Dardo R. (26040902100)"   
    ## 
    ## $`26424715800`
    ## [1] "Koyanagi, Tomoyo F. (26424715800)" "Koyanagi, Tomoyo (26424715800)"   
    ## 
    ## $`26432536300`
    ## [1] "Cavallero, Laura (26432536300)" "Cavallero, L. (26432536300)"   
    ## 
    ## $`26530722800`
    ## [1] "Breen, Amy (26530722800)"    "Breen, Amy L. (26530722800)"
    ## 
    ## $`26536701600`
    ## [1] "Shirokikh, Pavel (26536701600)"    "Shirokikh, Pavel S. (26536701600)"
    ## 
    ## $`26638726100`
    ## [1] "Anderson, B.J. (26638726100)"       "Anderson, Barbara J. (26638726100)"
    ## 
    ## $`26639925800`
    ## [1] "Viard-Crétat, Flore (26639925800)" "Viard-Crétat, F. (26639925800)"   
    ## 
    ## $`26641127100`
    ## [1] "De Frenne, Pieter (26641127100)" "De Frenne, Pieter (26641127100)"
    ## 
    ## $`26655887400`
    ## [1] "Mudrák, Ondřej (26655887400)" "Mudrák, O. (26655887400)"    
    ## 
    ## $`26660646100`
    ## [1] "Kapusta, Pawel (26660646100)"  "Kapusta, Pawezł (26660646100)"
    ## 
    ## $`28367592600`
    ## [1] "Gioria, M. (28367592600)"         "Gioria, Margherita (28367592600)"
    ## 
    ## $`31967495400`
    ## [1] "Carr, Susan (31967495400)"    "Carr, Susan M. (31967495400)"
    ## 
    ## $`34771306700`
    ## [1] "Jones, Laurence (34771306700)"    "Jones, Laurence M. (34771306700)"
    ## 
    ## $`34872657000`
    ## [1] "Li, Frank Yonghong (34872657000)" "Yonghong Li, Frank (34872657000)"
    ## 
    ## $`34879367800`
    ## [1] "Bueno, C. Guillermo (34879367800)"    
    ## [2] "Bueno, Guillermo (34879367800)"       
    ## [3] "Bueno, Carlos Guillermo (34879367800)"
    ## 
    ## $`34975059800`
    ## [1] "Toshihiko, Hara (34975059800)" "Hara, Toshihiko (34975059800)"
    ## [3] "Hara, T. (34975059800)"       
    ## 
    ## $`35079341200`
    ## [1] "Robbins, J.A. (35079341200)"    "Robbins, Jane A. (35079341200)"
    ## 
    ## $`35099260800`
    ## [1] "García Medina, Nagore (35099260800)" "Medina, Nagore G. (35099260800)"    
    ## 
    ## $`35183225600`
    ## [1] "Kaärlejarvi, Elina (35183225600)" "Kaarlejärvi, E.M. (35183225600)" 
    ## 
    ## $`35242993500`
    ## [1] "Klotz, Stefan (35242993500)" "Klotz, S. (35242993500)"    
    ## 
    ## $`35271299200`
    ## [1] "Carrijo, Tatiana Tavares (35271299200)"
    ## [2] "Carrijo, Tatiana T. (35271299200)"     
    ## 
    ## $`35271661700`
    ## [1] "Cushman, J. Hall (35271661700)" "Hall Cushman, J. (35271661700)"
    ## 
    ## $`35369389000`
    ## [1] "Ruifrok, Jasper L. (35369389000)"     
    ## [2] "Ruifrok, Jasper Laurens (35369389000)"
    ## 
    ## $`35406908300`
    ## [1] "Janssen, John (35406908300)"       "Janssen, John A. M. (35406908300)"
    ## [3] "Janssen, John A.M. (35406908300)"  "Janssen, J.A.M. (35406908300)"    
    ## 
    ## $`35408547000`
    ## [1] "Bergamin, Rodrigo Scarton (35408547000)"
    ## [2] "Bergamin, Rodrigo S. (35408547000)"     
    ## [3] "Bergamin, R.S. (35408547000)"           
    ## 
    ## $`35427938100`
    ## [1] "Harmon, Mark E. (35427938100)" "Harmon, M.E. (35427938100)"   
    ## 
    ## $`35428028600`
    ## [1] "Mirkin, B.M. (35428028600)"     "Mirkin, Boris M. (35428028600)"
    ## 
    ## $`35429150600`
    ## [1] "Wirth, Christian (35429150600)" "Wirth, C. (35429150600)"       
    ## 
    ## $`35446436400`
    ## [1] "Grime, John Philip (35446436400)" "Grime, J. Philip (35446436400)"  
    ## [3] "Grime, J.P. (35446436400)"       
    ## 
    ## $`35497025400`
    ## [1] "White, Peter S. (35497025400)" "White, Peter (35497025400)"   
    ## [3] "White, P.S. (35497025400)"    
    ## 
    ## $`35500762400`
    ## [1] "Condit, Richard (35500762400)" "Condit, R. (35500762400)"     
    ## 
    ## $`35509847500`
    ## [1] "Olsson, Pål Axel (35509847500)" "Olsson, Pal Axel (35509847500)"
    ## 
    ## $`35513922400`
    ## [1] "Laine, Kari (35513922400)" "Laine, K. (35513922400)"  
    ## 
    ## $`35551536200`
    ## [1] "ter Braak, Cajo J. F. (35551536200)" "Ter Braak, Cajo J.F. (35551536200)" 
    ## [3] "Ter Braak, C.J.F. (35551536200)"     "ter Braak, Cajo J.F. (35551536200)" 
    ## 
    ## $`35552019800`
    ## [1] "van Aarde, Rudi J. (35552019800)"    "van Aarde, Rudolph J. (35552019800)"
    ## 
    ## $`35553552100`
    ## [1] "Schneller, Jakob (35553552100)"       
    ## [2] "Schneller, Johann Jakob (35553552100)"
    ## 
    ## $`35560658500`
    ## [1] "Mack, Michelle C. (35560658500)" "Mack, Michelle (35560658500)"   
    ## 
    ## $`35565971500`
    ## [1] "Moreno, José M. (35565971500)" "Moreno, J.M. (35565971500)"   
    ## 
    ## $`35567066800`
    ## [1] "Facelli, José M. (35567066800)" "Facelli, José M (35567066800)" 
    ## 
    ## $`35568173200`
    ## [1] "Fortin, Marie-Josée (35568173200)" "Fortin, M.-J. (35568173200)"      
    ## 
    ## $`35568952900`
    ## [1] "Urban, D.L. (35568952900)"    "Urban, Dean L. (35568952900)"
    ## 
    ## $`35575910000`
    ## [1] "Homma, Kosuke (35575910000)"  "Homma, Kohsuke (35575910000)"
    ## 
    ## $`35580714200`
    ## [1] "Bertiller, Mónica B. (35580714200)" "Bertiller, Monica B. (35580714200)"
    ## 
    ## $`35581366400`
    ## [1] "Forbes, Bruce C. (35581366400)" "Forbes, B.C. (35581366400)"    
    ## 
    ## $`35585239900`
    ## [1] "Johansson, Mats E. (35585239900)" "Johansson, M.E. (35585239900)"   
    ## 
    ## $`35587177900`
    ## [1] "Dietz, H. (35587177900)"       "Dietz, Hansjörg (35587177900)"
    ## 
    ## $`35590023900`
    ## [1] "Kavgacı, Ali (35590023900)" "Kavgaci, Ali (35590023900)"
    ## 
    ## $`35591281000`
    ## [1] "Grootjans, Albert P. (35591281000)" "Grootjans, A.P. (35591281000)"     
    ## [3] "Grootjans, Ab (35591281000)"        "Grootjans, Ab P. (35591281000)"    
    ## 
    ## $`35602593900`
    ## [1] "Castro, Helena (35602593900)" "Castro, H. (35602593900)"    
    ## 
    ## $`35605683200`
    ## [1] "Herben, Tomáš (35605683200)" "Herben, Tomas (35605683200)"
    ## [3] "Herben, T. (35605683200)"   
    ## 
    ## $`35612496200`
    ## [1] "Ezcurra, Exequiel (35612496200)" "Ezcurra, E. (35612496200)"      
    ## 
    ## $`35613172400`
    ## [1] "Didukh, Yakiv (35613172400)"    "Didukh, Yakiv P. (35613172400)"
    ## 
    ## $`35614159300`
    ## [1] "Bartha, Sándor (35614159300)" "Bartha, Sandor (35614159300)"
    ## [3] "Bartha, S. (35614159300)"     "Sándor, B. (35614159300)"    
    ## 
    ## $`35615017800`
    ## [1] "Kigel, Jaime (35615017800)" "Jaime, Kigel (35615017800)"
    ## 
    ## $`35615503400`
    ## [1] "Rodwell, John S. (35615503400)" "Rodwell, John (35615503400)"   
    ## [3] "Rodwell, J. (35615503400)"      "Rodwell, J.S. (35615503400)"   
    ## 
    ## $`35617128600`
    ## [1] "Valadares de Sá Barreto Sampaio, Everardo (35617128600)"
    ## [2] "Sampaio, Everardo V.S.B. (35617128600)"                 
    ## 
    ## $`35618981300`
    ## [1] "St. J. Hardy, Giles E. (35618981300)"
    ## [2] "Hardy, Giles E.St.J. (35618981300)"  
    ## 
    ## $`35619471400`
    ## [1] "Grau, Héctor Ricardo (35619471400)" "Grau, H. Ricardo (35619471400)"    
    ## 
    ## $`35722318100`
    ## [1] "Kubota, Yasuhiro (35722318100)" "Kubota, Y. (35722318100)"      
    ## 
    ## $`35745975300`
    ## [1] "Huiskes, Hendrik P.J. (35745975300)" "Huiskes, H.P.J. (35745975300)"      
    ## 
    ## $`35747186200`
    ## [1] "Valdès, Alicia (35747186200)" "Valdes, Alicia (35747186200)"
    ## 
    ## $`35872086600`
    ## [1] "García Rodríguez, José Antonio (35872086600)"
    ## [2] "García-Rodríguez, J.A. (35872086600)"        
    ## [3] "García-Rodríguez, José A. (35872086600)"     
    ## 
    ## $`35965868500`
    ## [1] "De Miguel, José M. (35965868500)" "De Miguel, J.M. (35965868500)"   
    ## [3] "de Miguel, J.M. (35965868500)"   
    ## 
    ## $`35965992900`
    ## [1] "Peinado, Manuel (35965992900)" "Peinado, M. (35965992900)"    
    ## 
    ## $`35974931600`
    ## [1] "Gauthier, Sylvie (35974931600)" "Gauthier, S. (35974931600)"    
    ## 
    ## $`36003052700`
    ## [1] "Lloret, Francisco (36003052700)" "Lloret, F. (36003052700)"       
    ## 
    ## $`36003299500`
    ## [1] "Janssen, Thomas (36003299500)" "Janßen, Thomas (36003299500)" 
    ## 
    ## $`36028493500`
    ## [1] "Korolyuk, Andrei Yu (36028493500)" "Korolyuk, Andrey (36028493500)"   
    ## 
    ## $`36160533100`
    ## [1] "Matsumura, Toshikazu (36160533100)" "Matsumura, T. (36160533100)"       
    ## 
    ## $`36160561900`
    ## [1] "Mcdaniel, Sierra (36160561900)" "McDaniel, S. (36160561900)"    
    ## 
    ## $`36160638500`
    ## [1] "Roberts, Rachael (36160638500)" "Roberts, R.E. (36160638500)"   
    ## 
    ## $`36176233900`
    ## [1] "Miścicki, Stanisław (36176233900)" "Miścicki, Stanislaw (36176233900)"
    ## 
    ## $`36189105100`
    ## [1] "Westphal, Michael (36189105100)"    "Westphal, Michael F. (36189105100)"
    ## 
    ## $`36342843200`
    ## [1] "Rolo, Victor (36342843200)" "Rolo, Víctor (36342843200)"
    ## 
    ## $`36451686500`
    ## [1] "van der Merwe, Helga (36451686500)" "Rösch, H. (36451686500)"           
    ## 
    ## $`36477019000`
    ## [1] "Dvorský, Miroslav (36477019000)" "Dvorský, M. (36477019000)"      
    ## [3] "Dvorskỳ, M. (36477019000)"      
    ## 
    ## $`36537209000`
    ## [1] "Johnson, Anna L. (36537209000)" "Johnson, Anna (36537209000)"   
    ## 
    ## $`36549430400`
    ## [1] "Sfair, Julia Caram (36549430400)" "Sfair, Julia C. (36549430400)"   
    ## 
    ## $`36560595500`
    ## [1] "Wana, Desalegn (36560595500)" "Desalegn, Wana (36560595500)"
    ## 
    ## $`36598093400`
    ## [1] "Fajmon, Karel (36598093400)" "Fajmon, K. (36598093400)"   
    ## 
    ## $`36622974900`
    ## [1] "Pottier, Julien (36622974900)" "Pottier, J. (36622974900)"    
    ## 
    ## $`36663473900`
    ## [1] "Bodin, Jeanne (36663473900)" "Jeanne, Bodin (36663473900)"
    ## 
    ## $`36673481800`
    ## [1] "Mariotte, Pierre (36673481800)" "Mariotte, P. (36673481800)"    
    ## 
    ## $`36724571400`
    ## [1] "Lavrinenko, Igor A. (36724571400)" "Lavrinenko, Igor (36724571400)"   
    ## 
    ## $`36793793700`
    ## [1] "Janík, David (36793793700)" "Janik, David (36793793700)"
    ## 
    ## $`36836365000`
    ## [1] "Tardella, Federico Maria (36836365000)"
    ## [2] "Tardella, Federico M. (36836365000)"   
    ## 
    ## $`36844740000`
    ## [1] "Steinbauer, Manuel J. (36844740000)"   
    ## [2] "Steinbauer, Manuel Jonas (36844740000)"
    ## 
    ## $`36879181400`
    ## [1] "Boucher, Yan (36879181400)" "Boucher, Y. (36879181400)" 
    ## 
    ## $`36886740800`
    ## [1] "Dai, X. (36886740800)"       "Xiaobing, Dai (36886740800)"
    ## 
    ## $`36893979400`
    ## [1] "Eckstein, Rolf Lutz (36893979400)" "Eckstein, R. Lutz (36893979400)"  
    ## 
    ## $`36897189200`
    ## [1] "Llambí, Luis Daniel (36897189200)" "Llambí, Luis D. (36897189200)"    
    ## 
    ## $`36970213600`
    ## [1] "Jamoneau, Aurelien (36970213600)" "Jamoneau, Aurélien (36970213600)"
    ## 
    ## $`36981807900`
    ## [1] "Martín Vicente, A. (36981807900)" "Vicente, A. Martín (36981807900)"
    ## 
    ## $`36987626400`
    ## [1] "Rosati, Leonardo (36987626400)" "Rosati, L. (36987626400)"      
    ## 
    ## $`37030691200`
    ## [1] "Chen, Shuyan (37030691200)"  "Chen, Shu-Yan (37030691200)"
    ## 
    ## $`37074563800`
    ## [1] "Hallett, Lauren (37074563800)"    "Hallett, Lauren M. (37074563800)"
    ## 
    ## $`37104923800`
    ## [1] "Sansevero, Jerônimo Boelsums Barreto (37104923800)"
    ## [2] "Sansevero, Jerônimo B.B. (37104923800)"            
    ## 
    ## $`37111418500`
    ## [1] "Moeslund, Jesper Erenskjold (37111418500)"
    ## [2] "Moeslund, Jesper E. (37111418500)"        
    ## 
    ## $`38661050200`
    ## [1] "Andrade, Bianca O. (38661050200)"  "Andrade, Bianca Ott (38661050200)"
    ## 
    ## $`40461399800`
    ## [1] "de Gasper, André L. (40461399800)"   "de Gasper, André Luis (40461399800)"
    ## 
    ## $`41561051300`
    ## [1] "de Castilho, Carolina V. (41561051300)"
    ## [2] "Castilho, Carolina V. (41561051300)"   
    ## 
    ## $`42561657300`
    ## [1] "Reger, Birgit (42561657300)" "Reger, B. (42561657300)"    
    ## 
    ## $`46061964100`
    ## [1] "Horník, Jan (46061964100)" "Horník, J. (46061964100)" 
    ## 
    ## $`47161033000`
    ## [1] "Chen, Jian-Guo (47161033000)" "Chen, Jianguo (47161033000)" 
    ## 
    ## $`49964489400`
    ## [1] "Ransijn, J. (49964489400)"       "Ransijn, Johannes (49964489400)"
    ## 
    ## $`50661065600`
    ## [1] "Del Vecchio, Silvia (50661065600)" "Del Vecchio, S. (50661065600)"    
    ## 
    ## $`51864808600`
    ## [1] "Travers, Samantha Kay (51864808600)" "Travers, Samantha K. (51864808600)" 
    ## 
    ## $`52063738000`
    ## [1] "Ramos, Desirée Marques (52063738000)"
    ## [2] "Ramos, Desirée M. (52063738000)"     
    ## 
    ## $`53463727800`
    ## [1] "Karger, Dirk Nikolaus (53463727800)" "Karger, Dirk N. (53463727800)"      
    ## 
    ## $`53983290100`
    ## [1] "Wang, Xihua (53983290100)"  "Wang, Xi-Hua (53983290100)"
    ## 
    ## $`54398022200`
    ## [1] "Schei, Fride H. (54398022200)"      "Schei, Fride Høistad (54398022200)"
    ## 
    ## $`54413195800`
    ## [1] "Van Meerbeek, Koenraad (54413195800)"
    ## [2] "Van Meerbeek, Koenraad (54413195800)"
    ## 
    ## $`54790500100`
    ## [1] "Cavieres, Lohengrin A. (54790500100)"
    ## [2] "Cavieres, Lohengrin (54790500100)"   
    ## 
    ## $`54790508000`
    ## [1] "Coops, Nicholas C. (54790508000)" "Coops, N.C. (54790508000)"       
    ## 
    ## $`54901758700`
    ## [1] "Felde, Vivian Astrup (54901758700)" "Felde, Vivian A. (54901758700)"    
    ## 
    ## $`54901779900`
    ## [1] "Hernández Plaza, Eva (54901779900)" "Plaza, Eva Hernández (54901779900)"
    ## 
    ## $`54909218400`
    ## [1] "Sugau, John Baptist (54909218400)" "Sugau, John B. (54909218400)"     
    ## 
    ## $`55010991900`
    ## [1] "Svenning, Jens-Christian (55010991900)"
    ## [2] "Svenning, J.-C. (55010991900)"         
    ## 
    ## $`55025137000`
    ## [1] "Irl, Severin David Howard (55025137000)"
    ## [2] "Irl, Severin D. H. (55025137000)"       
    ## [3] "Irl, Severin D.H. (55025137000)"        
    ## 
    ## $`55030003400`
    ## [1] "Jo, Insu (55030003400)"  "Jo, In Su (55030003400)"
    ## 
    ## $`55090467200`
    ## [1] "Peterson, Chris J. (55090467200)" "Peterson, C. (55090467200)"      
    ## 
    ## $`55125925700`
    ## [1] "Carmona, Carlos P. (55125925700)"    "Carmona, Carlos Pérez (55125925700)"
    ## 
    ## $`55150995500`
    ## [1] "Rūsiņa, Solvita (55150995500)" "Rusina, Solvita (55150995500)"
    ## [3] "Rusiņa, Solvita (55150995500)"
    ## 
    ## $`55158044500`
    ## [1] "Verheyen, Kris (55158044500)" "Verheyen, K. (55158044500)"  
    ## 
    ## $`55180810500`
    ## [1] "Lewis, Rob J. (55180810500)"   "Lewis, Rob John (55180810500)"
    ## 
    ## $`55203945500`
    ## [1] "Duprè, Cecilia (55203945500)" "Dupré, Cecilia (55203945500)"
    ## 
    ## $`55220395000`
    ## [1] "Koyama, Asuka (55220395000)" "Koyama, A. (55220395000)"   
    ## 
    ## $`55232771500`
    ## [1] "Cousins, Sara A. O. (55232771500)" "Cousins, Sara A.O. (55232771500)" 
    ## [3] "Sara, A. O. Cousins (55232771500)"
    ## 
    ## $`55235055300`
    ## [1] "Ambarlı, Didem (55235055300)" "Ambarli, Didem (55235055300)"
    ## 
    ## $`55259753300`
    ## [1] "Flores, Olivier (55259753300)" "Flores, O. (55259753300)"     
    ## 
    ## $`55290690200`
    ## [1] "Hester, Alison J. (55290690200)" "Hester, A.J. (55290690200)"     
    ## 
    ## $`55340780500`
    ## [1] "González-M, Roy (55340780500)"  "González-M., Roy (55340780500)"
    ## 
    ## $`55347474200`
    ## [1] "Howison, Ruth A. (55347474200)" "Howison, R. (55347474200)"     
    ## 
    ## $`55362396500`
    ## [1] "Umaña, María Natalia (55362396500)" "Umaña, María N. (55362396500)"     
    ## [3] "Umaña, Maria Natalia (55362396500)"
    ## 
    ## $`55405011100`
    ## [1] "Matveyeva, N.V. (55405011100)"       
    ## [2] "Matveyeva, Nadezhda V. (55405011100)"
    ## 
    ## $`55405194200`
    ## [1] "Tichý, Lubomír (55405194200)" "Tichỳ, Lubomír (55405194200)"
    ## [3] "Tichý, L. (55405194200)"     
    ## 
    ## $`55439441900`
    ## [1] "Martini, Adriana Maria Z. (55439441900)"       
    ## [2] "Martini, Adriana Maria Zanforlin (55439441900)"
    ## 
    ## $`55456759600`
    ## [1] "Price, Jodi N. (55456759600)" "Price, Jodi (55456759600)"   
    ## 
    ## $`55457156700`
    ## [1] "Müller, Sandra C. (55457156700)"      
    ## [2] "Müller, Sandra Cristina (55457156700)"
    ## [3] "Müller, S.C. (55457156700)"           
    ## 
    ## $`55475481700`
    ## [1] "Yamamoto, S. (55475481700)"        "Yamamoto, Shin‐Ichi (55475481700)"
    ## 
    ## $`55491155700`
    ## [1] "Cambria, Vito Emanuele (55491155700)"
    ## [2] "Cambria, Vito E. (55491155700)"      
    ## 
    ## $`55505828000`
    ## [1] "Zeballos, Sebastián R. (55505828000)"     
    ## [2] "Zeballos, Sebastián Rodolfo (55505828000)"
    ## 
    ## $`55507953900`
    ## [1] "Jiráská, Šárka (55507953900)" "Jiráská, Š. (55507953900)"   
    ## 
    ## $`55536063900`
    ## [1] "Ma, Keping (55536063900)" "Ma, K.P. (55536063900)"  
    ## 
    ## $`55537920200`
    ## [1] "Wegman, Ruut M. A. (55537920200)" "Wegman, R.J.M. (55537920200)"    
    ## 
    ## $`55538185300`
    ## [1] "van der Sande, Masha T. (55538185300)"
    ## [2] "van der Sande, Masha T (55538185300)" 
    ## 
    ## $`55543645900`
    ## [1] "Andersen, Dagmar Kappel (55543645900)"
    ## [2] "Andersen, Dagmar K. (55543645900)"    
    ## 
    ## $`55543951000`
    ## [1] "Biţă-Nicolae, Claudia (55543951000)" "Biţa-Nicolae, Claudia (55543951000)"
    ## [3] "Biță-Nicolae, Claudia (55543951000)" "Biţǎ-Nicolae, Claudia (55543951000)"
    ## 
    ## $`55547906600`
    ## [1] "Wang, Xiangtai (55547906600)"  "Wang, Xiang-Tai (55547906600)"
    ## 
    ## $`55571235800`
    ## [1] "Sinsin, Brice Augustin (55571235800)"
    ## [2] "Sinsin, Brice (55571235800)"         
    ## 
    ## $`55581756400`
    ## [1] "Hunter, John C. (55581756400)" "Hunter, J.C. (55581756400)"   
    ## 
    ## $`55612751800`
    ## [1] "Williams, Richard J. (55612751800)" "Williams, R.J. (55612751800)"      
    ## 
    ## $`55613122300`
    ## [1] "Bhatta, Kuber Prasad (55613122300)" "Bhatta, Kuber P. (55613122300)"    
    ## 
    ## $`55618764700`
    ## [1] "Álvarez, Miguel (55618764700)" "Alvarez, Miguel (55618764700)"
    ## 
    ## $`55622009600`
    ## [1] "Marcenò, Corrado (55622009600)" "Marcenò, C. (55622009600)"     
    ## [3] "Marcenó, Corrado (55622009600)"
    ## 
    ## $`55622064800`
    ## [1] "An, Lizhe (55622064800)"  "An, Li-Zhe (55622064800)"
    ## 
    ## $`55630657400`
    ## [1] "Abe, S. (55630657400)"   "Abe, Shin (55630657400)"
    ## 
    ## $`55653683500`
    ## [1] "Jędrzejewska, Bogumiła (55653683500)"
    ## [2] "Jedrzejewska, Bogumila (55653683500)"
    ## [3] "Jedrzejewska, Bogumiła (55653683500)"
    ## 
    ## $`55657078100`
    ## [1] "Jensen, Kai (55657078100)" "Jensen, K. (55657078100)" 
    ## 
    ## $`55657822500`
    ## [1] "Verhoeven, Jos T.A. (55657822500)" "Verhoeven, J.T.A. (55657822500)"  
    ## 
    ## $`55666328500`
    ## [1] "Rico-Gray, Víctor (55666328500)" "Rico‐Gray, Victor (55666328500)"
    ## 
    ## $`55666800000`
    ## [1] "Del Galdo, Gian Pietro Giusso (55666800000)"
    ## [2] "Giusso del Galdo, Gian Pietro (55666800000)"
    ## 
    ## $`55709521600`
    ## [1] "Wilson, Mark (55709521600)"    "Wilson, M.V. (55709521600)"   
    ## [3] "Wilson, Mark V. (55709521600)"
    ## 
    ## $`55710743900`
    ## [1] "Kirby, Keith (55710743900)" "Kirby, K.J. (55710743900)" 
    ## 
    ## $`55745543900`
    ## [1] "Wen, Handong (55745543900)"  "Wen, Han-Dong (55745543900)"
    ## 
    ## $`55802153700`
    ## [1] "Garcia, Letícia C. (55802153700)"    "Garcia, Letícia Couto (55802153700)"
    ## 
    ## $`55833393600`
    ## [1] "Burns, Kevin C. (55833393600)" "Burns, Kevin (55833393600)"   
    ## [3] "Burns, K.C. (55833393600)"    
    ## 
    ## $`55851582800`
    ## [1] "Kollmann, Johannes (55851582800)" "Kollmann, J. (55851582800)"      
    ## 
    ## $`55871666200`
    ## [1] "Zhang, Ximing (55871666200)" "Zhang, X. (55871666200)"    
    ## 
    ## $`55872560300`
    ## [1] "Albert, Agnes-Julia (55872560300)" "Albert, Ágnes-Júlia (55872560300)"
    ## 
    ## $`55879317700`
    ## [1] "Landesmann, Jennifer Brenda (55879317700)"
    ## [2] "Landesmann, Jennifer B. (55879317700)"    
    ## 
    ## $`55880546700`
    ## [1] "Bridle, K.L. (55880546700)" "Bridle, K. (55880546700)"  
    ## 
    ## $`55881667400`
    ## [1] "Barboni, Doris (55881667400)" "Barboni, D. (55881667400)"   
    ## 
    ## $`55881697700`
    ## [1] "Gosling, William (55881697700)"    "Gosling, William D. (55881697700)"
    ## 
    ## $`55881708200`
    ## [1] "Treweek, J.R. (55881708200)"      "Treweek, Joanna R. (55881708200)"
    ## 
    ## $`55883498500`
    ## [1] "Bacaro, Giovanni (55883498500)" "Bacaro, G. (55883498500)"      
    ## 
    ## $`55888016800`
    ## [1] "Mesléard, François (55888016800)" "Mesléard, F. (55888016800)"      
    ## 
    ## $`55901093800`
    ## [1] "Pérez-Harguindeguy, Natalia (55901093800)"
    ## [2] "Perez-Harguindeguy, N. (55901093800)"     
    ## [3] "Pérez-Harguindeguy, N. (55901093800)"     
    ## 
    ## $`55901846700`
    ## [1] "Goosem, Steve (55901846700)"   "Goosem, Stephen (55901846700)"
    ## 
    ## $`55911705800`
    ## [1] "Russell-Smith, Jeremy (55911705800)" "Russell‐Smith, Jeremy (55911705800)"
    ## [3] "Russell‐Smith, J. (55911705800)"    
    ## 
    ## $`55912180900`
    ## [1] "Masubelele, Mmoto Leonard (55912180900)"
    ## [2] "Masubelele, Mmoto L. (55912180900)"     
    ## 
    ## $`55916082200`
    ## [1] "Čarni, Andraž (55916082200)" "Čarni, A. (55916082200)"    
    ## 
    ## $`55923428800`
    ## [1] "Saura, Santiago (55923428800)" "Saura, S. (55923428800)"      
    ## 
    ## $`55941775500`
    ## [1] "Montserrat-Martí, Gabriel (55941775500)"
    ## [2] "Montserrat-Martí, G. (55941775500)"     
    ## 
    ## $`55950878200`
    ## [1] "Díaz, Sandra (55950878200)"    "Díaz, Sandra M. (55950878200)"
    ## [3] "Diaz, Sandra (55950878200)"    "Díaz, S. (55950878200)"       
    ## 
    ## $`55951088700`
    ## [1] "Bush, Mark B. (55951088700)" "Bush, M.B. (55951088700)"   
    ## 
    ## $`55951969300`
    ## [1] "Chaneton, Enrique José (55951969300)"
    ## [2] "Chaneton, Enrique J. (55951969300)"  
    ## [3] "Chaneton, E.J. (55951969300)"        
    ## 
    ## $`55953965700`
    ## [1] "Rocchini, Duccio (55953965700)" "Rocchini, D. (55953965700)"    
    ## 
    ## $`55954162600`
    ## [1] "Pilon, Natashi Aparecida Lima (55954162600)"
    ## [2] "Pilon, Natashi A. L. (55954162600)"         
    ## [3] "Pilon, Natashi A.L. (55954162600)"          
    ## 
    ## $`55955194000`
    ## [1] "Feoli, Enrico (55955194000)" "Feoli, E. (55955194000)"    
    ## 
    ## $`55957973100`
    ## [1] "Moulatlet, Gabriel Massaine (55957973100)"
    ## [2] "Moulatlet, Gabriel M. (55957973100)"      
    ## 
    ## $`55965143800`
    ## [1] "Toussaint, Aurele (55965143800)" "Toussaint, Aurèle (55965143800)"
    ## 
    ## $`55966387900`
    ## [1] "Pavoine, Sandrine (55966387900)" "Pavoine, S. (55966387900)"      
    ## 
    ## $`55976929800`
    ## [1] "Skálová, Hana (55976929800)" "Skalova, Hana (55976929800)"
    ## [3] "Skálová, H. (55976929800)"  
    ## 
    ## $`55993084000`
    ## [1] "Acosta, Alicia T.R. (55993084000)"          
    ## [2] "Acosta, Alicia T. R. (55993084000)"         
    ## [3] "Acosta, Alicia Teresa Rosario (55993084000)"
    ## [4] "Acosta, A. (55993084000)"                   
    ## [5] "Acosta, Alicia (55993084000)"               
    ## 
    ## $`55995860500`
    ## [1] "Ramírez-Marcial, Neptalí (55995860500)"
    ## [2] "Ramírez‐Marcial, Neptalí (55995860500)"
    ## 
    ## $`56000854300`
    ## [1] "Toledo-Aceves, Tarin (56000854300)" "Toledo-Aceves (56000854300)"       
    ## 
    ## $`56003067200`
    ## [1] "Yee, Alex Thiam Koon (56003067200)" "Yee, Alex T. K. (56003067200)"     
    ## [3] "Yee, Alex T.K. (56003067200)"      
    ## 
    ## $`56005805300`
    ## [1] "Poorter, Lourens (56005805300)" "Poorter, L. (56005805300)"     
    ## 
    ## $`56012706100`
    ## [1] "Kucherov, Ilya (56012706100)"    "Kucherov, Ilya B. (56012706100)"
    ## 
    ## $`56013704800`
    ## [1] "Correa-Metrio, Alexander (56013704800)"
    ## [2] "Correa-Metrio, A. (56013704800)"       
    ## 
    ## $`56013854700`
    ## [1] "Velazquez, Alejandro (56013854700)" "Velázquez, Alejandro (56013854700)"
    ## 
    ## $`56015103000`
    ## [1] "Arenas, Juan M. (56015103000)"    "Arenas, Juan Maria (56015103000)"
    ## 
    ## $`56027245400`
    ## [1] "Liu, Jiajia (56027245400)" "Liu, JiaJia (56027245400)"
    ## 
    ## $`56032894000`
    ## [1] "Arfin Khan, Mohammed A. S. (56032894000)"
    ## [2] "Arfin Khan, Mohammed A.S. (56032894000)" 
    ## 
    ## $`56033000500`
    ## [1] "Mahy, Grégory (56033000500)" "Mahy, G. (56033000500)"     
    ## 
    ## $`56042647900`
    ## [1] "Halassy, Melinda (56042647900)" "Halassy, M. (56042647900)"     
    ## 
    ## $`56043661300`
    ## [1] "Munroe, Samantha (56043661300)"      
    ## [2] "Munroe, Samantha E. M. (56043661300)"
    ## 
    ## $`56049499400`
    ## [1] "Mucina, Ladislav (56049499400)" "Mucina, L. (56049499400)"      
    ## 
    ## $`56052880800`
    ## [1] "Enright, Neal J. (56052880800)" "Enright, N.J. (56052880800)"   
    ## 
    ## $`56074287700`
    ## [1] "Töpper, Joachim (56074287700)"    "Töpper, Joachim P. (56074287700)"
    ## 
    ## $`56094583800`
    ## [1] "Lezama, Felipe (56094583800)" "Lezama, F. (56094583800)"    
    ## 
    ## $`56105640400`
    ## [1] "Lewis, Simon L (56105640400)"  "Lewis, Simon L. (56105640400)"
    ## [3] "Lewis, S.L. (56105640400)"     "Lewis, S. (56105640400)"      
    ## 
    ## $`56162732100`
    ## [1] "Kohyama, Takashi S. (56162732100)" "Kohyama, Takashi (56162732100)"   
    ## [3] "Kohyama, T. (56162732100)"        
    ## 
    ## $`56187473800`
    ## [1] "Tuomi, J. (56187473800)"   "Tuomi, Juha (56187473800)"
    ## 
    ## $`56189776200`
    ## [1] "Kepfer-Rojas, Sebastian (56189776200)"
    ## [2] "Kepfer-Rojas, S. (56189776200)"       
    ## 
    ## $`56193230300`
    ## [1] "Quested, Helen (56193230300)"    "Quested, Helen M. (56193230300)"
    ## 
    ## $`56210277900`
    ## [1] "Doležal, Jiří (56210277900)" "Dolezal, Jiri (56210277900)"
    ## [3] "Doležal, Jiři (56210277900)" "Doležal, J. (56210277900)"  
    ## [5] "Doležal, Jiri (56210277900)"
    ## 
    ## $`56211234300`
    ## [1] "Eckart, Winkler (56211234300)" "Winkler, Eckart (56211234300)"
    ## 
    ## $`56211795000`
    ## [1] "Jon, Moen (56211795000)" "Moen, Jon (56211795000)"
    ## 
    ## $`56213319100`
    ## [1] "Di Bella, Carlos Marcelo (56213319100)"
    ## [2] "Di Bella, Carlos M. (56213319100)"     
    ## 
    ## $`56214217100`
    ## [1] "Reid, C.L. (56214217100)"         "Reid, Catherine L. (56214217100)"
    ## 
    ## $`56227924900`
    ## [1] "Zunzunegui, Maria (56227924900)" "Zunzunegui, M. (56227924900)"   
    ## 
    ## $`56228985100`
    ## [1] "Liira, Jaan (56228985100)" "Liira, J. (56228985100)"  
    ## 
    ## $`56231639800`
    ## [1] "Suzuki, Wajirou (56231639800)" "Suzuki, W. (56231639800)"     
    ## 
    ## $`56232919600`
    ## [1] "Fanelli, Giuliano (56232919600)" "Fanelli, G. (56232919600)"      
    ## 
    ## $`56240070800`
    ## [1] "Berendse, Frank (56240070800)" "Berendse, F. (56240070800)"   
    ## 
    ## $`56243856500`
    ## [1] "Joyce, C. (56243856500)"   "Joyce, C.B. (56243856500)"
    ## 
    ## $`56257136100`
    ## [1] "Rodríguez, Claudia (56257136100)" "Rodríguez, C. (56257136100)"     
    ## 
    ## $`56257286800`
    ## [1] "Quintana, Rubén Darío (56257286800)" "Quintana, Rubén D. (56257286800)"   
    ## 
    ## $`56261334800`
    ## [1] "Nuñez, Martín A (56261334800)"      "Nuñez, Martín Andrés (56261334800)"
    ## 
    ## $`56265097000`
    ## [1] "Chiarucci, Alessandro (56265097000)" "Chiarucci, A. (56265097000)"        
    ## 
    ## $`56268060900`
    ## [1] "Overbeck, Gerhard Ernst (56268060900)"
    ## [2] "Overbeck, Gerhard E. (56268060900)"   
    ## [3] "Overbeck, G. (56268060900)"           
    ## 
    ## $`56273696600`
    ## [1] "Escudero, Adrián (56273696600)" "Escudero, Adrian (56273696600)"
    ## [3] "Escudero, A. (56273696600)"    
    ## 
    ## $`56276857500`
    ## [1] "Gibson, David John (56276857500)" "Gibson, David J. (56276857500)"  
    ## 
    ## $`56277542400`
    ## [1] "van der Maarel, Eddy (56277542400)" "Van Der Maarel, Eddy (56277542400)"
    ## [3] "Van der Maarel, Eddy (56277542400)" "Van der Maarel, E. (56277542400)"  
    ## [5] "Van Der Maarel, E. (56277542400)"  
    ## 
    ## $`56283729900`
    ## [1] "Roelofs, Jan G. M. (56283729900)" "Roelofs, Jan G.M. (56283729900)" 
    ## [3] "Roelofs Jan, G.M. (56283729900)" 
    ## 
    ## $`56309353400`
    ## [1] "López-Acosta, Juan Carlos (56309353400)"
    ## [2] "López, J.C. (56309353400)"              
    ## 
    ## $`56327374000`
    ## [1] "Roberts, Mark R. (56327374000)" "Roberts, M.R. (56327374000)"   
    ## 
    ## $`56457335500`
    ## [1] "White, Hannah (56457335500)"    "White, Hannah J. (56457335500)"
    ## 
    ## $`56512026000`
    ## [1] "Goreaud, F. (56512026000)"       "Goreaud, François (56512026000)"
    ## 
    ## $`56522583600`
    ## [1] "Bond, William J. (56522583600)" "Bond, W.J. (56522583600)"      
    ## 
    ## $`56550093900`
    ## [1] "Johansson, Per (56550093900)" "Johansson, P. (56550093900)" 
    ## 
    ## $`56576750600`
    ## [1] "Thompson, Janette (56576750600)"    "Thompson, Janette R. (56576750600)"
    ## 
    ## $`56610835300`
    ## [1] "Vilà, M. (56610835300)"         "Vilà, Montserrat (56610835300)"
    ## 
    ## $`56635153700`
    ## [1] "Noy-Meir, Imanuel (56635153700)" "Noy‐Meir, Imanuel (56635153700)"
    ## 
    ## $`56641711300`
    ## [1] "Borovyk, Dariia (56641711300)"    "Shyriaieva, Dariia (56641711300)"
    ## 
    ## $`56641743400`
    ## [1] "Wedegärtner, Ronja (56641743400)"                    
    ## [2] "Wedegärtner, Ronja Elisabeth Magdalene (56641743400)"
    ## 
    ## $`56730316700`
    ## [1] "Meiners, S.J. (56730316700)"     "Meiners, Scott J. (56730316700)"
    ## 
    ## $`56780380300`
    ## [1] "Padullés Cubino, Josep (56780380300)"
    ## [2] "Padullés Cubino, Josep (56780380300)"
    ## 
    ## $`56800855300`
    ## [1] "Vasheniak, Iuliia (56800855300)" "Vashenyak, Yulia (56800855300)" 
    ## 
    ## $`56800856300`
    ## [1] "Kolomiychuk, Vitalii (56800856300)" "Kolomiychuk, Vitaliy (56800856300)"
    ## 
    ## $`56800948900`
    ## [1] "Işık Gürsoy, Deniz (56800948900)" "Işik Gürsoy, Deniz (56800948900)"
    ## 
    ## $`56818224600`
    ## [1] "Song, Xiaoyang (56818224600)"  "Song, Xiao-Yang (56818224600)"
    ## 
    ## $`56851940800`
    ## [1] "Meave, Jorge A. (56851940800)" "Meave, J.A. (56851940800)"    
    ## [3] "Meave, J. (56851940800)"      
    ## 
    ## $`56993664100`
    ## [1] "Massante, Jhonny Capichoni (56993664100)"
    ## [2] "Massante, Jhonny C. (56993664100)"       
    ## 
    ## $`57011781800`
    ## [1] "Haase, P. (57011781800)"    "Haase, Peter (57011781800)"
    ## 
    ## $`57074187800`
    ## [1] "Dostatny, Denise F. (57074187800)" "Dostatny, Denise Fu (57074187800)"
    ## 
    ## $`57103710900`
    ## [1] "Hollunder, Renan Köpp (57103710900)" "Hollunder, Renan K. (57103710900)"  
    ## 
    ## $`57163888000`
    ## [1] "Torchelsen, Fábio P. (57163888000)"    
    ## [2] "Torchelsen, Fábio Piccin (57163888000)"
    ## 
    ## $`57188960395`
    ## [1] "Świerszcz, Sebastian (57188960395)" "Swierszcz, Sebastian (57188960395)"
    ## 
    ## $`57189003922`
    ## [1] "Fantinato, Edy (57189003922)" "Fantinato, E. (57189003922)" 
    ## 
    ## $`57189186147`
    ## [1] "Camarero, J. Julio (57189186147)"    "Camarero, Jesús Julio (57189186147)"
    ## [3] "Julio Camarero, J. (57189186147)"   
    ## 
    ## $`57190111277`
    ## [1] "Sánchez, Ana M. (57190111277)" "Sánchez, A.M. (57190111277)"  
    ## 
    ## $`57190960917`
    ## [1] "Smith-Ramesh, Lauren M. (57190960917)"
    ## [2] "Smith, L.M. (57190960917)"            
    ## 
    ## $`57191197364`
    ## [1] "Semenishchenkov, Yuri (57191197364)"   
    ## [2] "Semenishchenkov, Yury A. (57191197364)"
    ## 
    ## $`57191439732`
    ## [1] "dos Santos, Flavio Antonio Maës (57191439732)"
    ## [2] "Santos, Flavio A.M. (57191439732)"            
    ## [3] "Dos Santos, Flavio Antonio Maës (57191439732)"
    ## 
    ## $`57191505150`
    ## [1] "Ćuk, Mirjana (57191505150)"             
    ## [2] "Krstivojević-Ćuk, Mirjana (57191505150)"
    ## [3] "Krstivojević Ćuk, Mirjana (57191505150)"
    ## 
    ## $`57191545466`
    ## [1] "Agüero, Walter D. (57191545466)"     "Agüero, Walter Damián (57191545466)"
    ## 
    ## $`57192010664`
    ## [1] "Smagin, Viktor (57192010664)"    "Smagin, Viktor A. (57192010664)"
    ## 
    ## $`57192012809`
    ## [1] "Felbaba-Klushyna, Lyubov (57192012809)"
    ## [2] "Felbaba-Klushyna, Ljuba (57192012809)" 
    ## 
    ## $`57192291070`
    ## [1] "Ojeda, Fernando (57192291070)" "Ojeda, F. (57192291070)"      
    ## 
    ## $`57192658649`
    ## [1] "Bartoš, Michael (57192658649)" "Bartoš, M. (57192658649)"     
    ## 
    ## $`57192837369`
    ## [1] "Cupertino-Eisenlohr, Mônica A. (57192837369)"
    ## [2] "Cupertino-Eisenlohr, Mônica A (57192837369)" 
    ## 
    ## $`57193675402`
    ## [1] "Mertens, Jan (57193675402)" "Mertens, J. (57193675402)" 
    ## 
    ## $`57193845334`
    ## [1] "Sperandii, Marta Gaia (57193845334)" "Sperandii, Marta G. (57193845334)"  
    ## 
    ## $`57193887430`
    ## [1] "Buyens, Isabelle Patricia Rita (57193887430)"
    ## [2] "Buyens, Isabelle P. R. (57193887430)"        
    ## 
    ## $`57194509335`
    ## [1] "Pettit, Joseph (57194509335)"    "Pettit, Joseph L. (57194509335)"
    ## 
    ## $`57194514028`
    ## [1] "González-Andújar, José L. (57194514028)"  
    ## [2] "González-Andújar, José Luis (57194514028)"
    ## [3] "González-Andujar, José Luis (57194514028)"
    ## [4] "González-Andújar, J.L. (57194514028)"     
    ## 
    ## $`57194615386`
    ## [1] "Vítovcová, Kamila (57194615386)" "Lencová, Kamila (57194615386)"  
    ## 
    ## $`57194756089`
    ## [1] "Avena, Giancarlo (57194756089)" "Avena, G. (57194756089)"       
    ## [3] "Avena, G.C. (57194756089)"     
    ## 
    ## $`57194787914`
    ## [1] "Hak, Jon C. (57194787914)" "Hak, Jon (57194787914)"   
    ## 
    ## $`57195222435`
    ## [1] "Kee, Carmen Yingxin (57195222435)" "Kee, Carmen Y. (57195222435)"     
    ## 
    ## $`57195523298`
    ## [1] "Cerdà, Artemi (57195523298)" "Cerdá, A. (57195523298)"    
    ## 
    ## $`57195824219`
    ## [1] "Boutin, Stan (57195824219)" "Boutin, S. (57195824219)"  
    ## 
    ## $`57196043693`
    ## [1] "Penman, Trent D. (57196043693)" "Penman, T.D. (57196043693)"    
    ## 
    ## $`57196442242`
    ## [1] "Loh, Jolyn Weiting (57196442242)" "Loh, Jolyn W. (57196442242)"     
    ## 
    ## $`57196594030`
    ## [1] "de la Cruz, Marcelino (57196594030)" "De la Cruz, Marcelino (57196594030)"
    ## [3] "De La Cruz, Marcelino (57196594030)"
    ## 
    ## $`57197033626`
    ## [1] "Bakker, C. (57197033626)"    "Bakker, Chris (57197033626)"
    ## 
    ## $`57197591668`
    ## [1] "Carrillo, Empar (57197591668)" "Carrillo, E. (57197591668)"   
    ## 
    ## $`57198428195`
    ## [1] "Tsakalos, James Lee (57198428195)" "Tsakalos, James L. (57198428195)" 
    ## 
    ## $`57200643879`
    ## [1] "Makelele, Isaac (57200643879)"           
    ## [2] "Makelele, Isaac Ahanamungu (57200643879)"
    ## 
    ## $`57200657902`
    ## [1] "Martins, M.J. (57200657902)"       "Martins, Maria João (57200657902)"
    ## 
    ## $`57200804625`
    ## [1] "Abedi, Mehdi (57200804625)" "Abedi, M. (57200804625)"   
    ## 
    ## $`57200835009`
    ## [1] "Sabatini, Francesco Maria (57200835009)"
    ## [2] "Sabatini, Francesco M. (57200835009)"   
    ## 
    ## $`57201194899`
    ## [1] "Chusova, Olha (57201194899)" "Chusova, Olga (57201194899)"
    ## 
    ## $`57201304604`
    ## [1] "Laurance, Susan G. W. (57201304604)" "Laurance, Susan G.W. (57201304604)" 
    ## [3] "Laurance, G.N.Susan (57201304604)"   "Laurance, Susan G. (57201304604)"   
    ## 
    ## $`57201435848`
    ## [1] "Hüllbusch, Elisabeth (57201435848)"   
    ## [2] "Hüllbusch, Elisabeth M. (57201435848)"
    ## 
    ## $`57201573421`
    ## [1] "Terradas, J. (57201573421)"    "Terradas, Jaume (57201573421)"
    ## 
    ## $`57201758600`
    ## [1] "Jönsson, Mari (57201758600)"    "Jönsson, Mari T. (57201758600)"
    ## [3] "Jönsson, Mari T (57201758600)" 
    ## 
    ## $`57202009966`
    ## [1] "Tichý, Lubomir (57202009966)" "Tichý, Lubomír (57202009966)"
    ## 
    ## $`57202864003`
    ## [1] "Goode, J. Davis (57202864003)"       "Goode, Jonathan Davis (57202864003)"
    ## 
    ## $`57202908874`
    ## [1] "Dias, E. (57202908874)"      "Dias, Eduardo (57202908874)"
    ## 
    ## $`57203043862`
    ## [1] "Bakker, Jan P. (57203043862)" "Bakker, J.P. (57203043862)"  
    ## [3] "Bakker, Jan (57203043862)"   
    ## 
    ## $`57203056321`
    ## [1] "Willis, Katherine J. (57203056321)" "Willis, Kathy J. (57203056321)"    
    ## [3] "Willis, K.J. (57203056321)"        
    ## 
    ## $`57203140102`
    ## [1] "Fang, Jing-Yun (57203140102)" "Fang, Jingyun (57203140102)" 
    ## [3] "Jingyun, Fang (57203140102)" 
    ## 
    ## $`57203257682`
    ## [1] "Sykes, M.T. (57203257682)"      "Sykes, Martin T. (57203257682)"
    ## 
    ## $`57203381681`
    ## [1] "Wessels, Konrad J. (57203381681)" "Wessels, Konrad (57203381681)"   
    ## 
    ## $`57204179557`
    ## [1] "Mehlhoop, Anne Catriona (57204179557)"
    ## [2] "Mehlhoop, Anne C. (57204179557)"      
    ## 
    ## $`57204304514`
    ## [1] "Malanson, George P (57204304514)"  "Malanson, George P. (57204304514)"
    ## 
    ## $`57204814252`
    ## [1] "Kanno, H. (57204814252)"      "Kanno, Hiroshi (57204814252)"
    ## 
    ## $`57204976112`
    ## [1] "Silva, Gabriela S. (57204976112)"       
    ## [2] "Silva, Gabriela Santos da (57204976112)"
    ## 
    ## $`57205096887`
    ## [1] "Hanz, Dagmar Martina (57205096887)" "Hanz, Dagmar M. (57205096887)"     
    ## 
    ## $`57205311446`
    ## [1] "Apps, Michael J. (57205311446)" "Apps, M. (57205311446)"        
    ## 
    ## $`57205393406`
    ## [1] "Ploughe, Laura W (57205393406)"  "Ploughe, Laura W. (57205393406)"
    ## 
    ## $`57208175552`
    ## [1] "Arnst, Elise A. (57208175552)" "Arnst, Elise (57208175552)"   
    ## 
    ## $`57209552644`
    ## [1] "Hodgson, John G. (57209552644)" "Hodgson, J.G. (57209552644)"   
    ## 
    ## $`57209574907`
    ## [1] "León, Daniela (57209574907)" "Leon, Daniela (57209574907)"
    ## 
    ## $`57210350296`
    ## [1] "Barbour, M. (57210350296)"         "Barbour, M.G. (57210350296)"      
    ## [3] "Barbour, Michael G. (57210350296)"
    ## 
    ## $`57210472543`
    ## [1] "Jia, G.J. (57210472543)"      "Jia, Gensuo J. (57210472543)"
    ## 
    ## $`57210532175`
    ## [1] "Jonsson, Bengt Gunnar (57210532175)" "Jonsson, B.G. (57210532175)"        
    ## 
    ## $`57210751721`
    ## [1] "Manning, Peter (57210751721)" "Manning, Pete (57210751721)" 
    ## 
    ## $`57211113746`
    ## [1] "Defossé, Guillermo Emilio (57211113746)"
    ## [2] "Defossé, Guillermo E. (57211113746)"    
    ## 
    ## $`57211513461`
    ## [1] "Tortorelli, Claire M. (57211513461)" "Tortorelli, Claire (57211513461)"   
    ## 
    ## $`57211624418`
    ## [1] "Padilla, Francisco M. (57211624418)" "Padilla, F.M. (57211624418)"        
    ## 
    ## $`57213783407`
    ## [1] "Lim, Reuben Chong Jin (57213783407)" "Lim, Reuben C. J. (57213783407)"    
    ## 
    ## $`57214410884`
    ## [1] "Cairns, D.M. (57214410884)"     "Cairns, David M. (57214410884)"
    ## 
    ## $`57214441596`
    ## [1] "Barfknecht, David Francis (57214441596)"
    ## [2] "Barfknecht, David F. (57214441596)"     
    ## 
    ## $`57214777535`
    ## [1] "Greene, S.E. (57214777535)"     "Greene, Sarah E. (57214777535)"
    ## 
    ## $`57214846559`
    ## [1] "Boutton, Thomas W. (57214846559)" "Boutton, T.W. (57214846559)"     
    ## 
    ## $`57216042206`
    ## [1] "Calvo, Leonor (57216042206)" "Calvo, L. (57216042206)"    
    ## 
    ## $`57217056837`
    ## [1] "Chaves, Pablo P. (57217056837)"    "Chaves, Pablo Pérez (57217056837)"
    ## 
    ## $`57217318524`
    ## [1] "Silveira, Fernando A. O. (57217318524)"
    ## [2] "Silveira, Fernando A O (57217318524)"  
    ## [3] "Silveira, Fernando A.O. (57217318524)" 
    ## 
    ## $`57218526155`
    ## [1] "Palchetti, María V. (57218526155)"   
    ## [2] "Palchetti, M. Virginia (57218526155)"
    ## 
    ## $`57221034370`
    ## [1] "Matthews, J.A. (57221034370)"    "Matthews, John A. (57221034370)"
    ## 
    ## $`57224140833`
    ## [1] "Müllerová, Jana (57224140833)" "Müllerová, J. (57224140833)"  
    ## 
    ## $`57405200800`
    ## [1] "Phillips, Oliver L. (57405200800)" "Phillips, O.L. (57405200800)"     
    ## 
    ## $`57510288600`
    ## [1] "Dupuis, Sébastien (57510288600)" "Dupuis, S. (57510288600)"       
    ## 
    ## $`58289749000`
    ## [1] "Perez, Rolando (58289749000)" "Pérez, Rolando (58289749000)"
    ## 
    ## $`58584908700`
    ## [1] "Török, Katalin (58584908700)" "Török, K. (58584908700)"     
    ## 
    ## $`6504274107`
    ## [1] "Lorite, Juan (6504274107)" "Lorite, J. (6504274107)"  
    ## 
    ## $`6504758211`
    ## [1] "Żybura, Henryk (6504758211)" "Zybura, Henryk (6504758211)"
    ## 
    ## $`6505496503`
    ## [1] "Janečková, Petra (6505496503)" "Janečková, P. (6505496503)"   
    ## 
    ## $`6505759993`
    ## [1] "Nakhutsrishvili, George (6505759993)"
    ## [2] "Nakhutsrishvili, Georgi (6505759993)"
    ## [3] "Nakhutsrishvili, G. (6505759993)"    
    ## 
    ## $`6505763602`
    ## [1] "Stafford Smith, Mark (6505763602)"   
    ## [2] "Stafford Smith, D. Mark (6505763602)"
    ## [3] "Stafford, Smith D.M. (6505763602)"   
    ## 
    ## $`6505887167`
    ## [1] "Schurr, Frank M. (6505887167)" "Schurr, Frank (6505887167)"   
    ## 
    ## $`6505981801`
    ## [1] "Väliranta, Minna (6505981801)" "Väliranta, M. (6505981801)"   
    ## 
    ## $`6506049143`
    ## [1] "Lavrinenko, Olga V. (6506049143)" "Lavrinenko, Olga (6506049143)"   
    ## 
    ## $`6506121063`
    ## [1] "Fernández-Santos, Belén (6506121063)"
    ## [2] "Fernández-Santos, B. (6506121063)"   
    ## [3] "Fernández‐Santos, Belén (6506121063)"
    ## 
    ## $`6506130751`
    ## [1] "Sieben, Erwin J.J. (6506130751)"  "Sieben, Erwin J. J. (6506130751)"
    ## [3] "Sieben, E.J.J. (6506130751)"     
    ## 
    ## $`6506163937`
    ## [1] "Holdo, Ricardo (6506163937)"    "Holdo, Ricardo M. (6506163937)"
    ## [3] "Holdo, R.M. (6506163937)"      
    ## 
    ## $`6506200561`
    ## [1] "Kącki, Zygmunt (6506200561)" "Kacki, Zygmunt (6506200561)"
    ## 
    ## $`6506319846`
    ## [1] "Dattaraja, Handanakere S. (6506319846)"
    ## [2] "Dattaraja, H.S. (6506319846)"          
    ## 
    ## $`6506321903`
    ## [1] "Hainard, Pierre (6506321903)" "Hainard, P. (6506321903)"    
    ## 
    ## $`6506336392`
    ## [1] "Mironycheva-Tokareva, N.P. (6506336392)"
    ## [2] "Mironycheva‐Tokareva, N.P. (6506336392)"
    ## 
    ## $`6506467052`
    ## [1] "Lososová, Zdeňka (6506467052)" "Lososova, Zdeňka (6506467052)"
    ## [3] "Lososová, Z. (6506467052)"    
    ## 
    ## $`6506474788`
    ## [1] "Bédécarrats, Alain (6506474788)" "Bédécarrats, A. (6506474788)"   
    ## 
    ## $`6506630861`
    ## [1] "Nieppola, J. (6506630861)"   "Nieppola, Jari (6506630861)"
    ## 
    ## $`6506640528`
    ## [1] "Nunes da Cunha, Cátia (6506640528)" "Nunes Da Cunha, C. (6506640528)"   
    ## 
    ## $`6506702625`
    ## [1] "Granzow-de la Cerda, Íñigo (6506702625)"
    ## [2] "Granzow-de la Cerda, Iñigo (6506702625)"
    ## 
    ## $`6506751747`
    ## [1] "Vegar, Bakkestuen (6506751747)" "Bakkestuen, Vegar (6506751747)"
    ## 
    ## $`6506795615`
    ## [1] "Boldrini, Ilsi Iob (6506795615)" "Boldrini, Ilsi I. (6506795615)" 
    ## 
    ## $`6506808628`
    ## [1] "Okuro, Toshiya (6506808628)" "Okuro, T. (6506808628)"     
    ## 
    ## $`6506822499`
    ## [1] "Vayreda, J. (6506822499)"    "Vayreda, Jordi (6506822499)"
    ## 
    ## $`6506870458`
    ## [1] "Basconcelo, S. (6506870458)"     "Basconcelo, Sandra (6506870458)"
    ## 
    ## $`6506873343`
    ## [1] "Vegelin, K. (6506873343)"   "Vegelin, Kees (6506873343)"
    ## 
    ## $`6506977118`
    ## [1] "Molina, José Antonio (6506977118)" "Molina, José A. (6506977118)"     
    ## 
    ## $`6506984282`
    ## [1] "Mellert, Karl H. (6506984282)" "Mellert, K.H. (6506984282)"   
    ## 
    ## $`6506986962`
    ## [1] "Slim, Pieter A. (6506986962)" "Slim, P.A. (6506986962)"     
    ## 
    ## $`6507021275`
    ## [1] "Laskurain, Nere Amaia (6507021275)" "Laskurain, N.A. (6507021275)"      
    ## 
    ## $`6507040777`
    ## [1] "Fernández-Alés, R. (6507040777)" "Fernández Ales, R. (6507040777)"
    ## 
    ## $`6507073094`
    ## [1] "Vellak, Kai (6507073094)" "Vellak, K. (6507073094)" 
    ## 
    ## $`6507100270`
    ## [1] "Berastegi, Asun (6507100270)" "Berastegi, A. (6507100270)"  
    ## 
    ## $`6507119675`
    ## [1] "Altesor, Alice (6507119675)" "Altesor, A. (6507119675)"   
    ## 
    ## $`6507120883`
    ## [1] "Franco-Pizaña, Jesus G. (6507120883)"
    ## [2] "Franco‐Pizaña, Jesus (6507120883)"   
    ## 
    ## $`6507130665`
    ## [1] "Rigling, A. (6507130665)"      "Rigling, Andreas (6507130665)"
    ## 
    ## $`6507141826`
    ## [1] "Tutubalina, Olga V. (6507141826)" "Tutubalina, Olga (6507141826)"   
    ## 
    ## $`6507152337`
    ## [1] "Pawlikowski, Pawel (6507152337)" "Pawlikowski, Paweł (6507152337)"
    ## 
    ## $`6507240286`
    ## [1] "Rédei, Tamás (6507240286)" "Rédei, T. (6507240286)"   
    ## 
    ## $`6507243508`
    ## [1] "Schmidtlein, Sebastian (6507243508)" "Schmidtlein, S. (6507243508)"       
    ## 
    ## $`6507252158`
    ## [1] "Kholod, Sergei S. (6507252158)" "Kholod, S.S. (6507252158)"     
    ## 
    ## $`6507298983`
    ## [1] "Cerabolini, Bruno (6507298983)"             
    ## [2] "Cerabolini, Bruno E. L. (6507298983)"       
    ## [3] "Cerabolini, Bruno Enrico Leone (6507298983)"
    ## [4] "Cerabolini, B. (6507298983)"                
    ## 
    ## $`6507318524`
    ## [1] "De Cáceres, Miquel (6507318524)" "de Cáceres, Miquel (6507318524)"
    ## [3] "De Caceres, M. (6507318524)"    
    ## 
    ## $`6507441106`
    ## [1] "Corcket, Emmanuel (6507441106)" "Corcket, E. (6507441106)"      
    ## 
    ## $`6507458732`
    ## [1] "Gégout, Jean-Claude (6507458732)" "Gégout, J.C. (6507458732)"       
    ## [3] "Gegout, Jean-Claude (6507458732)"
    ## 
    ## $`6507482052`
    ## [1] "Rodríguez-Rojo, María Pilar (6507482052)"
    ## [2] "Rodríguez-Rojo, Maria Pilar (6507482052)"
    ## [3] "Rodríguez Rojo, Maria Pilar (6507482052)"
    ## [4] "Rodríguez-Rojo, M.P. (6507482052)"       
    ## 
    ## $`6507541929`
    ## [1] "Felinks, Birgit (6507541929)" "Felinks, B. (6507541929)"    
    ## 
    ## $`6507593899`
    ## [1] "Molina-Montenegro, Marco A. (6507593899)"
    ## [2] "Molina-Montenegro, Marco (6507593899)"   
    ## 
    ## $`6507718632`
    ## [1] "Aldezabal, Arantza (6507718632)" "Aldezabal, A. (6507718632)"     
    ## 
    ## $`6507755831`
    ## [1] "Hirabuki, Y. (6507755831)"        "Hirabuki, Yoshihiko (6507755831)"
    ## 
    ## $`6507770254`
    ## [1] "Espigares, Tíscar (6507770254)" "Espigares, T. (6507770254)"    
    ## 
    ## $`6507791409`
    ## [1] "Hochstrasser, Tamara (6507791409)" "Hochstrasser, T. (6507791409)"    
    ## 
    ## $`6507891289`
    ## [1] "Chourmouzis, C. (6507891289)"        "Chourmouzis, Christine (6507891289)"
    ## 
    ## $`6507914637`
    ## [1] "Kuijper, Dries Pieter Jan (6507914637)"
    ## [2] "Kuijper, Dries P.J. (6507914637)"      
    ## 
    ## $`6507948656`
    ## [1] "Hennekens, Stephan M. (6507948656)" "Hennekens, Stephan (6507948656)"   
    ## [3] "Hennekens, S.M. (6507948656)"      
    ## 
    ## $`6507982017`
    ## [1] "Ninot, Josep M. (6507982017)"    "Ninot, Josep Maria (6507982017)"
    ## [3] "Ninot, J.M. (6507982017)"       
    ## 
    ## $`6508093205`
    ## [1] "Bonfil, Consuelo (6508093205)" "Bonfil, C. (6508093205)"      
    ## 
    ## $`6508101557`
    ## [1] "Dančák, Martin (6508101557)" "Dančak, Martin (6508101557)"
    ## 
    ## $`6508300993`
    ## [1] "Van Der Hoek, D. (6508300993)"   "Van Der Hoek, Dick (6508300993)"
    ## 
    ## $`6508332597`
    ## [1] "Gourlet-Fleury, Sylvie (6508332597)" "Gourlet-Fleury, S. (6508332597)"    
    ## 
    ## $`6508360489`
    ## [1] "Maceira, N. (6508360489)"        "Maceira, Néstor O. (6508360489)"
    ## 
    ## $`6508365010`
    ## [1] "Damschen, Ellen I. (6508365010)" "Damschen, Ellen (6508365010)"   
    ## 
    ## $`6601966109`
    ## [1] "Batista, William (6601966109)"    "Batista, W.B. (6601966109)"      
    ## [3] "Batista, William B. (6601966109)"
    ## 
    ## $`6601979426`
    ## [1] "Okutomi, Kiyoshi (6601979426)" "Okutomi, K. (6601979426)"     
    ## 
    ## $`6601981016`
    ## [1] "De Vries, Yzaak (6601981016)" "De Vries, Y. (6601981016)"   
    ## [3] "de Vries, Y. (6601981016)"   
    ## 
    ## $`6601988081`
    ## [1] "de Pablo, Carlos T. López (6601988081)"
    ## [2] "De Pablo, C.L. (6601988081)"           
    ## [3] "de Pablo, C.L. (6601988081)"           
    ## 
    ## $`6601990437`
    ## [1] "Suresh, Hebbalalu S. (6601990437)" "Suresh, H.S. (6601990437)"        
    ## 
    ## $`6601991949`
    ## [1] "Maskell, Lindsay C. (6601991949)" "Maskell, L.C. (6601991949)"      
    ## 
    ## $`6601997174`
    ## [1] "Roovers, Pieter (6601997174)" "Roovers, P. (6601997174)"    
    ## 
    ## $`6602071545`
    ## [1] "Grytnes, John-Arvid (6602071545)" "Grytnes, John Arvid (6602071545)"
    ## 
    ## $`6602084977`
    ## [1] "Goedhart, P.W. (6602084977)"    "Goedhart, Paul W. (6602084977)"
    ## 
    ## $`6602089140`
    ## [1] "Romane, François J. (6602089140)" "Romane, F. (6602089140)"         
    ## 
    ## $`6602091793`
    ## [1] "Arseneault, Dominique (6602091793)" "Arseneault, D. (6602091793)"       
    ## 
    ## $`6602095978`
    ## [1] "Laterra, P. (6602095978)"    "Laterra, Pedro (6602095978)"
    ## 
    ## $`6602101854`
    ## [1] "Pillar, Valério D. (6602101854)"      
    ## [2] "Pillar, Valério De Patta (6602101854)"
    ## [3] "Pillar, V.D. (6602101854)"            
    ## [4] "D. Pillar, Valério (6602101854)"      
    ## [5] "Pillar, Valério DePatta (6602101854)" 
    ## [6] "Pillar, V.D.P. (6602101854)"          
    ## 
    ## $`6602108536`
    ## [1] "Vittoz, Pascal (6602108536)" "Pascal, Vittoz (6602108536)"
    ## [3] "Vittoz, P. (6602108536)"    
    ## 
    ## $`6602115812`
    ## [1] "Rebertus, Alan J. (6602115812)" "Rebertus, A.J. (6602115812)"   
    ## 
    ## $`6602118668`
    ## [1] "Quintana-Ascencio, Pedro F. (6602118668)"       
    ## [2] "Quintana-Ascencio, P.F. (6602118668)"           
    ## [3] "Quintana-Ascencio, Pedro Francisco (6602118668)"
    ## [4] "Quintana‐Ascencio, Pedro F. (6602118668)"       
    ## 
    ## $`6602118849`
    ## [1] "Szwagrzyk, Jerzy (6602118849)" "Szwagrzyk, J. (6602118849)"   
    ## 
    ## $`6602123683`
    ## [1] "Thuiller, Wilfried (6602123683)" "Thuiller, W. (6602123683)"      
    ## 
    ## $`6602127493`
    ## [1] "Onipchenko, Vladimir (6602127493)"   
    ## [2] "Onipchenko, Vladimir G. (6602127493)"
    ## [3] "Onipchenko, V.G. (6602127493)"       
    ## 
    ## $`6602152997`
    ## [1] "Wildi, Otto (6602152997)" "Wildi, O. (6602152997)"  
    ## 
    ## $`6602163122`
    ## [1] "Vanha-Majamaa, I. (6602163122)"    "Vanha-Majamaa, Ilkka (6602163122)"
    ## 
    ## $`6602175670`
    ## [1] "Skarpe, C. (6602175670)"        "Skarpe, Christina (6602175670)"
    ## 
    ## $`6602179292`
    ## [1] "Olsvig-Whittaker, Linda (6602179292)"
    ## [2] "Olsvig‐Whittaker, Linda (6602179292)"
    ## [3] "Olsvig‐Whittaker, L.S. (6602179292)" 
    ## 
    ## $`6602205640`
    ## [1] "Silman, Miles (6602205640)"    "Silman, Miles R. (6602205640)"
    ## 
    ## $`6602245833`
    ## [1] "Haridasan, Mundayatan (6602245833)" "Haridasan, M. (6602245833)"        
    ## 
    ## $`6602258340`
    ## [1] "Kölling, C. (6602258340)"        "Kölling, Christian (6602258340)"
    ## 
    ## $`6602262679`
    ## [1] "Pauw, Anton (6602262679)" "Pauw, A. (6602262679)"   
    ## 
    ## $`6602282694`
    ## [1] "Carrer, Marco (6602282694)" "Carrer, M. (6602282694)"   
    ## 
    ## $`6602300438`
    ## [1] "Hefting, Mariet M. (6602300438)" "Hefting, M.M. (6602300438)"     
    ## 
    ## $`6602303405`
    ## [1] "Münzbergová, Zuzana (6602303405)" "Munzbergova, Zuzana (6602303405)"
    ## 
    ## $`6602306174`
    ## [1] "Bioret, Frederic (6602306174)" "Bioret, F. (6602306174)"      
    ## 
    ## $`6602306394`
    ## [1] "Pivello, Vânia R. (6602306394)"     "Pivello, Vânia Regina (6602306394)"
    ## 
    ## $`6602310183`
    ## [1] "Louault, Frédérique (6602310183)" "Louault, F. (6602310183)"        
    ## 
    ## $`6602316087`
    ## [1] "Butaye, Jan (6602316087)" "Butaye, J. (6602316087)" 
    ## 
    ## $`6602322872`
    ## [1] "Graae, Bente Jessen (6602322872)" "Graae, Bente J. (6602322872)"    
    ## [3] "Graae, B.J. (6602322872)"        
    ## 
    ## $`6602325354`
    ## [1] "Zavala-Hurtado, José Alejandro (6602325354)"
    ## [2] "Zavala‐Hurtado, J. Alejandro (6602325354)"  
    ## 
    ## $`6602342301`
    ## [1] "Bråthen, Kari Anne (6602342301)" "Brathen, Kari Anne (6602342301)"
    ## [3] "Bråthen, K.A. (6602342301)"     
    ## 
    ## $`6602347028`
    ## [1] "Krüsi, Bertil (6602347028)"    "Krüsi, Bertil O. (6602347028)"
    ## 
    ## $`6602359440`
    ## [1] "Villar-Salvador, Pedro (6602359440)" "Villar-Salvador, P. (6602359440)"   
    ## 
    ## $`6602365069`
    ## [1] "Prober, Suzanne M. (6602365069)" "Suzanne, Prober (6602365069)"   
    ## 
    ## $`6602366476`
    ## [1] "Ozinga, Wim A. (6602366476)" "Ozinga, W.A. (6602366476)"  
    ## 
    ## $`6602371914`
    ## [1] "Schoennagel, Tania L. (6602371914)" "Schoennagel, T. (6602371914)"      
    ## 
    ## $`6602379817`
    ## [1] "Dullinger, Stefan (6602379817)" "Dullinger, S. (6602379817)"    
    ## 
    ## $`6602385111`
    ## [1] "Steinlein, T. (6602385111)"     "Steinlein, Thomas (6602385111)"
    ## 
    ## $`6602385947`
    ## [1] "Aranibar, Julieta N. (6602385947)" "Araníbar, Julieta (6602385947)"   
    ## 
    ## $`6602390880`
    ## [1] "Hadincová, Věroslava (6602390880)" "Hadincová, Věra (6602390880)"     
    ## [3] "Hadincová, V. (6602390880)"        "Hadincová, Všra (6602390880)"     
    ## 
    ## $`6602392573`
    ## [1] "Brzeziecki, Bogdan (6602392573)" "Brzeziecki, B. (6602392573)"    
    ## 
    ## $`6602418331`
    ## [1] "Losvik, Mary H. (6602418331)" "Losvik, M.H. (6602418331)"   
    ## 
    ## $`6602458082`
    ## [1] "Økland, Tonje (6602458082)" "Okland, Tonje (6602458082)"
    ## 
    ## $`6602463907`
    ## [1] "Loster, Stefania (6602463907)" "Loster, S. (6602463907)"      
    ## 
    ## $`6602464343`
    ## [1] "Curt, Thomas (6602464343)" "Curt, T. (6602464343)"    
    ## 
    ## $`6602469064`
    ## [1] "Hytteborn, Håkan (6602469064)" "Hytteborn, Hakan (6602469064)"
    ## [3] "Hytteborn, Hakån (6602469064)"
    ## 
    ## $`6602469604`
    ## [1] "Lavergne, S. (6602469604)"        "Lavergne, Sébastien (6602469604)"
    ## 
    ## $`6602470914`
    ## [1] "Pimentel, Tania P. (6602470914)" "Pimentel, Tânia P. (6602470914)"
    ## 
    ## $`6602484926`
    ## [1] "Rebollo, Salvador (6602484926)" "Rebollo, S. (6602484926)"      
    ## 
    ## $`6602487630`
    ## [1] "Lenssen, John P. M. (6602487630)" "Lenssen, John P.M. (6602487630)" 
    ## 
    ## $`6602495621`
    ## [1] "Cerdeira, J.O. (6602495621)"         
    ## [2] "Cerdeira, Jorge Orestes (6602495621)"
    ## 
    ## $`6602515300`
    ## [1] "Dunnett, Nigel P. (6602515300)" "Dunnett, N.P. (6602515300)"    
    ## 
    ## $`6602528302`
    ## [1] "Levassor, Catherine (6602528302)" "Levassor, C. (6602528302)"       
    ## 
    ## $`6602543571`
    ## [1] "Tatoni, Thierry (6602543571)" "Tatoni, T. (6602543571)"     
    ## 
    ## $`6602556688`
    ## [1] "Sans, Francesc Xavier (6602556688)" "Sans, F.X. (6602556688)"           
    ## 
    ## $`6602567605`
    ## [1] "Lucassen, Esther C.H.E.T. (6602567605)"
    ## [2] "Lucassen Esther, C.H.E.T. (6602567605)"
    ## 
    ## $`6602583777`
    ## [1] "Gómez Sal, A. (6602583777)"      "Gómez-Sal, Antonio (6602583777)"
    ## [3] "Gómez‐Sal, Antonio (6602583777)"
    ## 
    ## $`6602589174`
    ## [1] "Moora, Mari (6602589174)" "Moora, M. (6602589174)"  
    ## 
    ## $`6602634225`
    ## [1] "Goslee, Sarah C. (6602634225)" "Goslee, S.C. (6602634225)"    
    ## 
    ## $`6602653533`
    ## [1] "Heitkönig, I.M.A. (6602653533)" "Heitkonig, Ignas (6602653533)" 
    ## 
    ## $`6602654760`
    ## [1] "Castro-Díez, Pilar (6602654760)" "Castro-Díez, P. (6602654760)"   
    ## 
    ## $`6602665508`
    ## [1] "Gillson, Lindsey (6602665508)" "Gillson, L. (6602665508)"     
    ## 
    ## $`6602676149`
    ## [1] "Chaieb, Mohamed (6602676149)" "Chaieb, M. (6602676149)"     
    ## 
    ## $`6602687687`
    ## [1] "Seiwa, Kenji (6602687687)" "Seiwa, K. (6602687687)"   
    ## 
    ## $`6602688494`
    ## [1] "Germino, Matthew J. (6602688494)" "Germino, Matthew (6602688494)"   
    ## 
    ## $`6602699620`
    ## [1] "Smith-Ramírez, Cecilia (6602699620)" "Smith-Ramírez, C. (6602699620)"     
    ## 
    ## $`6602723679`
    ## [1] "Collantes, Marta B. (6602723679)" "Collantes, M. (6602723679)"      
    ## 
    ## $`6602735642`
    ## [1] "Henkin, Zalmen (6602735642)" "Henkin, Z. (6602735642)"    
    ## 
    ## $`6602741289`
    ## [1] "Cadenasso, M.L. (6602741289)"    "Cadenasso, Mary L. (6602741289)"
    ## 
    ## $`6602756335`
    ## [1] "Touzard, Blaise (6602756335)" "Touzard, B. (6602756335)"    
    ## 
    ## $`6602762042`
    ## [1] "Sosinski, Enio (6602762042)"        "Sosinski, Enio E. (6602762042)"    
    ## [3] "Sosinski Jr., Enio E. (6602762042)"
    ## 
    ## $`6602778888`
    ## [1] "Rebele, Franz (6602778888)" "Rebele, F. (6602778888)"   
    ## 
    ## $`6602780007`
    ## [1] "De Schrijver, An (6602780007)" "De Schrijver, A. (6602780007)"
    ## 
    ## $`6602781868`
    ## [1] "Juergens, Norbert (6602781868)" "Jürgens, Norbert (6602781868)" 
    ## 
    ## $`6602782604`
    ## [1] "Fedriani, Jose Maria (6602782604)" "Fedriani, José M. (6602782604)"   
    ## 
    ## $`6602790626`
    ## [1] "Batalha, Marco Antônio (6602790626)" "Batalha, Marco A. (6602790626)"     
    ## 
    ## $`6602792035`
    ## [1] "Alatalo, Juha Mikael (6602792035)" "Alatalo, Juha M. (6602792035)"    
    ## 
    ## $`6602797966`
    ## [1] "Krestov, Pavel (6602797966)"    "Krestov, P.V. (6602797966)"    
    ## [3] "Krestov, Pavel V. (6602797966)"
    ## 
    ## $`6602798224`
    ## [1] "García-Mijangos, Itziar (6602798224)"
    ## [2] "Garcia-Mijangos, Itziar (6602798224)"
    ## [3] "Garcia-Mijangos, I. (6602798224)"    
    ## 
    ## $`6602800357`
    ## [1] "García-Franco, José G. (6602800357)" "García‐Franco, José G. (6602800357)"
    ## 
    ## $`6602804026`
    ## [1] "Van De Steeg, H.M. (6602804026)"     "Van De Steeg, Harry M. (6602804026)"
    ## 
    ## $`6602815276`
    ## [1] "Biurrun, Idoia (6602815276)" "Biurrun, I. (6602815276)"   
    ## 
    ## $`6602824060`
    ## [1] "Luis-Calabuig, E. (6602824060)"        
    ## [2] "Luis-Calabuig, Estanislao (6602824060)"
    ## 
    ## $`6602833460`
    ## [1] "Maccherini, Simona (6602833460)" "Maccherini, S. (6602833460)"    
    ## 
    ## $`6602848397`
    ## [1] "Ejrnæs, Rasmus (6602848397)"  "Ejrnaes, Rasmus (6602848397)"
    ## [3] "Ejrnæs, R. (6602848397)"     
    ## 
    ## $`6602860889`
    ## [1] "González-Espinosa, Mario (6602860889)"
    ## [2] "González‐Espinosa, Mario (6602860889)"
    ## 
    ## $`6602868669`
    ## [1] "Schaminée, Joop H.J. (6602868669)"  "Schaminée, Joop H. J. (6602868669)"
    ## [3] "Schaminée, J.H.J. (6602868669)"    
    ## 
    ## $`6602879848`
    ## [1] "Tuittila, Eeva-Stiina (6602879848)" "Tuittila, E.-T. (6602879848)"      
    ## [3] "Tuittila, E.-S. (6602879848)"       "Tuittila, E. (6602879848)"         
    ## 
    ## $`6602881253`
    ## [1] "Borgegård, Sven-Olov (6602881253)" "Borgegård, Sven‐Olov (6602881253)"
    ## 
    ## $`6602900129`
    ## [1] "Wamelink, G. W. Wieger (6602900129)" "Wieger Wamelink, G.W. (6602900129)" 
    ## [3] "Wamelink, G.W.W. (6602900129)"       "Wamelink, G.W.Wieger (6602900129)"  
    ## 
    ## $`6602917435`
    ## [1] "Gavilán, Rosario G. (6602917435)" "Gavilán, Rosario (6602917435)"   
    ## [3] "Gavilán, R.G. (6602917435)"      
    ## 
    ## $`6602946168`
    ## [1] "Jutila, H.M. (6602946168)"              
    ## [2] "Jutila B. Erkkilä, Heli M. (6602946168)"
    ## 
    ## $`6602980212`
    ## [1] "Hemmings, Frank A. (6602980212)" "Hemmings, Frank (6602980212)"   
    ## 
    ## $`6602985156`
    ## [1] "Díaz-Barradas, Mari Cruz (6602985156)"
    ## [2] "Díaz Barradas, M.C. (6602985156)"     
    ## [3] "Diaz Barradas, M.C. (6602985156)"     
    ## 
    ## $`6603014149`
    ## [1] "Ghermandi, Luciana (6603014149)" "Ghermandi, L. (6603014149)"     
    ## 
    ## $`6603019908`
    ## [1] "Engelmark, Ola (6603019908)" "Engelmark, O. (6603019908)" 
    ## 
    ## $`6603022673`
    ## [1] "Ingerpuu, Nele (6603022673)" "Ingerpuu, N. (6603022673)"  
    ## 
    ## $`6603024439`
    ## [1] "Bonser, Stephen Patrick (6603024439)"
    ## [2] "Bonser, Stephen P. (6603024439)"     
    ## [3] "Bonser, S.P (6603024439)"            
    ## 
    ## $`6603044539`
    ## [1] "Razzhivin, Vladimir Yu. (6603044539)"
    ## [2] "Razzhivin, V.Yu. (6603044539)"       
    ## 
    ## $`6603057734`
    ## [1] "Leuschner, Hanns H. (6603057734)"    
    ## [2] "Leuschner, Hanns Hubert (6603057734)"
    ## 
    ## $`6603063950`
    ## [1] "Vellend, Mark (6603063950)" "Vellend, M. (6603063950)"  
    ## 
    ## $`6603068605`
    ## [1] "Rivas-Martínez, S. (6603068605)"      
    ## [2] "Rivas‐Martinez, Salvador (6603068605)"
    ## 
    ## $`6603071963`
    ## [1] "Olde Venterink, H. (6603071963)"        
    ## [2] "Olde Venterink, Harry (6603071963)"     
    ## [3] "Olde Venterink, Harry G.M. (6603071963)"
    ## 
    ## $`6603084357`
    ## [1] "Dirnböck, Thomas (6603084357)" "Thomas, Dirnböck (6603084357)"
    ## [3] "Dirnböck, T. (6603084357)"    
    ## 
    ## $`6603125430`
    ## [1] "Bouzillé, Jan-Bernard (6603125430)" "Bouzillé, J.B. (6603125430)"       
    ## [3] "Bouzillé, J.-B. (6603125430)"      
    ## 
    ## $`6603129971`
    ## [1] "Suding, Katharine N. (6603129971)"   "Suding, Katharine Nash (6603129971)"
    ## 
    ## $`6603130417`
    ## [1] "Prévosto, Bernard (6603130417)" "Prevosto, B. (6603130417)"     
    ## 
    ## $`6603151773`
    ## [1] "Gowing, David J. (6603151773)"   "Gowing, David (6603151773)"     
    ## [3] "Gowing David, J.G. (6603151773)"
    ## 
    ## $`6603167358`
    ## [1] "Meentemeyer, Ross K. (6603167358)" "Meentemeyer, R.K. (6603167358)"   
    ## 
    ## $`6603173653`
    ## [1] "Meléndez-Ackerman, Elvia J. (6603173653)"
    ## [2] "Meléndez-Ackerman, Elvia (6603173653)"   
    ## 
    ## $`6603177264`
    ## [1] "Backéus, I. (6603177264)"     "Backéus, Ingvar (6603177264)"
    ## 
    ## $`6603271569`
    ## [1] "Wilds, S.P. (6603271569)"         "Wilds, Stephanie P. (6603271569)"
    ## 
    ## $`6603279893`
    ## [1] "Wahren, C.-H. (6603279893)"   "Wahren, C.-H.A. (6603279893)"
    ## 
    ## $`6603288856`
    ## [1] "Morellato, Leonor Patricia C (6603288856)"
    ## [2] "Morellato, Leonor P. C. (6603288856)"     
    ## 
    ## $`6603294724`
    ## [1] "Guerrero-Campo, Joaquín (6603294724)"
    ## [2] "Guerrero-Campo, J. (6603294724)"     
    ## 
    ## $`6603303519`
    ## [1] "Wallenius, Tuomo (6603303519)"    "Wallenius, Tuomo H. (6603303519)"
    ## 
    ## $`6603362433`
    ## [1] "López-Portillo, Jorge (6603362433)" "López-Portillo, J. (6603362433)"   
    ## 
    ## $`6603364869`
    ## [1] "Hely, Christelle (6603364869)" "Hély, C. (6603364869)"        
    ## 
    ## $`6603365481`
    ## [1] "Grabherr, Georg (6603365481)" "Grabherr, G. (6603365481)"   
    ## 
    ## $`6603367938`
    ## [1] "Zweifel, Roman (6603367938)" "Zweifel, R. (6603367938)"   
    ## 
    ## $`6603368671`
    ## [1] "Van Ruijven, Jasper (6603368671)" "van Ruijven, Jasper (6603368671)"
    ## 
    ## $`6603369808`
    ## [1] "Mitchley, Jonathan (6603369808)" "Mitchley, J. (6603369808)"      
    ## 
    ## $`6603370775`
    ## [1] "Rapson, Gillian L. (6603370775)" "Rapson, G.L. (6603370775)"      
    ## 
    ## $`6603398354`
    ## [1] "Burkart, Silvia E. (6603398354)" "Burkart, S.E. (6603398354)"     
    ## 
    ## $`6603403986`
    ## [1] "Menaut, Jean-Claude (6603403986)" "Menaut, Jean‐Claude (6603403986)"
    ## 
    ## $`6603408785`
    ## [1] "Pecháčková, Sylvie (6603408785)" "Pecháčková, S. (6603408785)"    
    ## 
    ## $`6603416341`
    ## [1] "Tomassen, H.B.M. (6603416341)"     "Tomassen, Hilde B.M. (6603416341)"
    ## 
    ## $`6603416948`
    ## [1] "Funes, Guillermo (6603416948)" "Funes, G. (6603416948)"       
    ## 
    ## $`6603418837`
    ## [1] "Pegtel, D.M. (6603418837)"    "Pegtel, Dick M. (6603418837)"
    ## 
    ## $`6603420637`
    ## [1] "Wondzell, Steve (6603420637)"     "Wondzell, Steven M. (6603420637)"
    ## 
    ## $`6603424687`
    ## [1] "Zechmeister, Harald G. (6603424687)" "Zechmeister, Harald (6603424687)"   
    ## 
    ## $`6603440101`
    ## [1] "Kleyer, Michael (6603440101)" "Michael, Kleyer (6603440101)"
    ## [3] "Kleyer, M. (6603440101)"     
    ## 
    ## $`6603472888`
    ## [1] "Suominen, Otso (6603472888)" "Suominen, O. (6603472888)"  
    ## 
    ## $`6603489521`
    ## [1] "Pavlů, Vilém V. (6603489521)" "Pavlů, Vilém (6603489521)"   
    ## 
    ## $`6603535786`
    ## [1] "Salemaa, Maija (6603535786)" "Salemaa, M. (6603535786)"   
    ## 
    ## $`6603537464`
    ## [1] "Froend, R. (6603537464)"         "Froend, Raymond H. (6603537464)"
    ## 
    ## $`6603547223`
    ## [1] "Erschbamer, Brigitta (6603547223)" "Brigitta, Erschbamer (6603547223)"
    ## 
    ## $`6603585122`
    ## [1] "García Novo, F. (6603585122)"        "García-Novo, Francisco (6603585122)"
    ## [3] "Garcia Novo, F. (6603585122)"       
    ## 
    ## $`6603630265`
    ## [1] "Bergmeier, Erwin (6603630265)" "Bergmeier, E. (6603630265)"   
    ## 
    ## $`6603642006`
    ## [1] "Sánchez-Mata, Daniel (6603642006)" "Sánchez-Mata, D. (6603642006)"    
    ## 
    ## $`6603648471`
    ## [1] "Moreno-Casasola, P. (6603648471)"      
    ## [2] "Moreno‐Casasola, P. (6603648471)"      
    ## [3] "Moreno‐Casasola, Patricia (6603648471)"
    ## 
    ## $`6603656423`
    ## [1] "Yurtsev, Boris A. (6603656423)" "Yurtsev, B.A. (6603656423)"    
    ## 
    ## $`6603660769`
    ## [1] "Slik, J. W. Ferry (6603660769)" "Slik, J.W. Ferry (6603660769)" 
    ## 
    ## $`6603663053`
    ## [1] "Vallejo, V. Ramon (6603663053)" "Vallejo, V.R. (6603663053)"    
    ## [3] "Vallejo, V. Ramón (6603663053)"
    ## 
    ## $`6603668522`
    ## [1] "Williams-Linera, Guadalupe (6603668522)"
    ## [2] "Williams-Linera, G. (6603668522)"       
    ## 
    ## $`6603676695`
    ## [1] "Marañón, Teodoro (6603676695)" "Marañón, T. (6603676695)"     
    ## [3] "Maranón, T. (6603676695)"     
    ## 
    ## $`6603689894`
    ## [1] "Klimešová, Jitka (6603689894)" "Klimešová, J. (6603689894)"   
    ## 
    ## $`6603694508`
    ## [1] "Weiher, Evan (6603694508)" "Weiher, E. (6603694508)"  
    ## 
    ## $`6603706057`
    ## [1] "Jarošik, Vojtech (6603706057)" "Jarošík, Vojtěch (6603706057)"
    ## 
    ## $`6603708025`
    ## [1] "Esler, Karen Joan (6603708025)" "Esler, Karen J. (6603708025)"  
    ## 
    ## $`6603729223`
    ## [1] "Anten, Niels P.R. (6603729223)"  "Anten, Niels P. R. (6603729223)"
    ## 
    ## $`6603739965`
    ## [1] "Fernández-Palacios, José María (6603739965)"
    ## [2] "Fernandez Palacios, Jose María (6603739965)"
    ## [3] "Fernández‐Palacios, José María (6603739965)"
    ## 
    ## $`6603742354`
    ## [1] "Pfadenhauer, Jörg (6603742354)" "Pfadenhauer, J. (6603742354)"  
    ## 
    ## $`6603744767`
    ## [1] "Verwijst, Theo (6603744767)" "Verwijst, T. (6603744767)"  
    ## 
    ## $`6603753892`
    ## [1] "Zobel, Kristjan (6603753892)" "Zobel, K. (6603753892)"      
    ## 
    ## $`6603779863`
    ## [1] "Balaguer, Luis (6603779863)" "Balaguer, L. (6603779863)"  
    ## 
    ## $`6603783118`
    ## [1] "Bossuyt, Beatrijs (6603783118)" "Bossuyt, B. (6603783118)"      
    ## 
    ## $`6603783422`
    ## [1] "Daws, Matthew Ian (6603783422)" "Daws, Matthew I. (6603783422)" 
    ## 
    ## $`6603800318`
    ## [1] "Ferré, Albert (6603800318)" "Ferré, A. (6603800318)"    
    ## 
    ## $`6603805322`
    ## [1] "Wardell-Johnson, Grant (6603805322)" "Wardell-Johnson, G.W. (6603805322)" 
    ## [3] "Wardell-Johnson, G. (6603805322)"   
    ## 
    ## $`6603810350`
    ## [1] "Kicklighter, D.W. (6603810350)"     "Kicklighter, David W. (6603810350)"
    ## 
    ## $`6603818974`
    ## [1] "Grillas, Patrick (6603818974)" "Grillas, P. (6603818974)"     
    ## 
    ## $`6603834154`
    ## [1] "Tømmervik, Hans (6603834154)" "Tømmervik, H. (6603834154)"  
    ## 
    ## $`6603834174`
    ## [1] "Font, Xavier (6603834174)" "Font, X. (6603834174)"    
    ## 
    ## $`6603842703`
    ## [1] "Van Dobben, Han F. (6603842703)" "van Dobben, H.F. (6603842703)"  
    ## [3] "Van Dobben, H.F. (6603842703)"  
    ## 
    ## $`6603844350`
    ## [1] "Orloci, L. (6603844350)"     "Orlóci, László (6603844350)"
    ## 
    ## $`6603845202`
    ## [1] "Barrat-Segretain, Marie-Hélène (6603845202)"
    ## [2] "Barrat-Segretain, M.H. (6603845202)"        
    ## 
    ## $`6603846043`
    ## [1] "Dupouey, Jean-Luc (6603846043)" "Dupouey, J.L. (6603846043)"    
    ## 
    ## $`6603847049`
    ## [1] "Heijmans, Monique M.P.D. (6603847049)"
    ## [2] "Heijmans, Monique M.P.D (6603847049)" 
    ## [3] "Heijmans, M.M.P.D. (6603847049)"      
    ## 
    ## $`6603856421`
    ## [1] "Gurvich, Diego E. (6603856421)" "Gurvich, D.E. (6603856421)"    
    ## 
    ## $`6603885391`
    ## [1] "Lawesson, Jonas Erik (6603885391)" "Lawesson, Jonas E. (6603885391)"  
    ## [3] "Lawesson, J.E. (6603885391)"      
    ## 
    ## $`6603897504`
    ## [1] "García-Fayos, P. (6603897504)"       "García-Fayos, Patricio (6603897504)"
    ## [3] "García‐Fayos, P. (6603897504)"      
    ## 
    ## $`6603899360`
    ## [1] "Puettmann, Klaus J. (6603899360)" "Puettmann Klaus, J. (6603899360)"
    ## 
    ## $`6603908475`
    ## [1] "Parmenter, Robert R. (6603908475)" "Parmenter, R.R. (6603908475)"     
    ## 
    ## $`6603909430`
    ## [1] "Oesterheld, Martín (6603909430)" "Oesterheld, Martin (6603909430)"
    ## [3] "Oesterheld, M. (6603909430)"    
    ## 
    ## $`6603922181`
    ## [1] "Ostertag, R. (6603922181)"      "Ostertag, Rebecca (6603922181)"
    ## 
    ## $`6603930958`
    ## [1] "Theurillat, Jean-Paul (6603930958)" "Theurillat, J.-P. (6603930958)"    
    ## 
    ## $`6603938145`
    ## [1] "Güsewell, S. (6603938145)"     "Güsewell, Sabine (6603938145)"
    ## [3] "Gusewell, S. (6603938145)"    
    ## 
    ## $`6603946834`
    ## [1] "Ganis, P. (6603946834)"    "Ganis, Paola (6603946834)"
    ## 
    ## $`6603950534`
    ## [1] "Sebastià, Maria Teresa (6603950534)" "Sebastià, Maria-Teresa (6603950534)"
    ## [3] "Sebastia, Maria-Teresa (6603950534)" "Maria-Teresa, Sebastia (6603950534)"
    ## 
    ## $`6603963897`
    ## [1] "Tóthmérész, Béla (6603963897)" "Tóthmérész, B. (6603963897)"  
    ## 
    ## $`6603965458`
    ## [1] "Shaltout, Kamal (6603965458)" "Shaltout, K.H. (6603965458)" 
    ## 
    ## $`6603978881`
    ## [1] "Freitas, Helena (6603978881)" "Freitas, H. (6603978881)"    
    ## 
    ## $`6603980594`
    ## [1] "van Bodegom, Peter M. (6603980594)" "Van Bodegom, Peter M. (6603980594)"
    ## [3] "Van Bodegom, P.M. (6603980594)"    
    ## 
    ## $`6604000285`
    ## [1] "Sah, Jay P. (6604000285)" "Sah, J.P. (6604000285)"  
    ## 
    ## $`6604020625`
    ## [1] "Gobat, Jean-Michel (6604020625)" "Gobat, J.-M. (6604020625)"      
    ## 
    ## $`6604028763`
    ## [1] "Oliveira-Filho, Ary Teixeira de (6604028763)"
    ## [2] "Oliveira-Filho, Ary T (6604028763)"          
    ## 
    ## $`6604029563`
    ## [1] "Gloaguen, Jean-Claude (6604029563)" "Gloaguen, J.C. (6604029563)"       
    ## 
    ## $`6604082511`
    ## [1] "Médail, Frédéric (6604082511)" "Médail, F. (6604082511)"      
    ## 
    ## $`6701310662`
    ## [1] "Seligman, Noam G. (6701310662)"  "Seligman, N.G. (6701310662)"    
    ## [3] "Seligman, No'am G. (6701310662)"
    ## 
    ## $`6701320483`
    ## [1] "Chessel, Daniel (6701320483)" "Chessel, D. (6701320483)"    
    ## 
    ## $`6701324518`
    ## [1] "Barendregt, A. (6701324518)"  "Barendregt, Aat (6701324518)"
    ## 
    ## $`6701338309`
    ## [1] "Michalet, Richard (6701338309)" "Michalet, R. (6701338309)"     
    ## 
    ## $`6701359794`
    ## [1] "Bellingham, Peter J. (6701359794)" "Bellingham, P.J. (6701359794)"    
    ## 
    ## $`6701369368`
    ## [1] "Cabido, Marcelo R. (6701369368)"    "Cabido, Marcelo Rubén (6701369368)"
    ## [3] "Cabido, Marcelo (6701369368)"       "Cabido, M.R. (6701369368)"         
    ## [5] "Cabido, M. (6701369368)"           
    ## 
    ## $`6701380728`
    ## [1] "Rey Benayas, José M. (6701380728)"   
    ## [2] "Rey-Benayas, José María (6701380728)"
    ## [3] "Rey-Benayas, José M. (6701380728)"   
    ## [4] "Rey Benayas, J.M. (6701380728)"      
    ## [5] "Rey Benayas, Jose M. (6701380728)"   
    ## 
    ## $`6701389712`
    ## [1] "Pärtel, Meelis (6701389712)" "Partei, Meelis (6701389712)"
    ## [3] "Pärtel, M. (6701389712)"    
    ## 
    ## $`6701397189`
    ## [1] "Elvebakk, A. (6701397189)"   "Elvebakk, Arve (6701397189)"
    ## 
    ## $`6701401842`
    ## [1] "Brizuela, Miguel Angel (6701401842)" "Brizuela, M.A. (6701401842)"        
    ## 
    ## $`6701404953`
    ## [1] "Peco, Begoña (6701404953)"  "Peco, B. (6701404953)"     
    ## [3] "Peco, Begonna (6701404953)"
    ## 
    ## $`6701414778`
    ## [1] "Harcombe, Paul A. (6701414778)" "Harcombe, P.A. (6701414778)"   
    ## 
    ## $`6701420717`
    ## [1] "Huhta, Ari-Pekka (6701420717)" "Huhta, A.-P. (6701420717)"    
    ## 
    ## $`6701443879`
    ## [1] "van Diggelen, Rudy (6701443879)" "Van Diggelen, R. (6701443879)"  
    ## [3] "Van Diggelen, Rudy (6701443879)"
    ## 
    ## $`6701449154`
    ## [1] "Poschlod, Peter (6701449154)" "Poschlod, P. (6701449154)"   
    ## 
    ## $`6701451805`
    ## [1] "Kneeshaw, Daniel (6701451805)"    "Kneeshaw, Daniel D. (6701451805)"
    ## [3] "Kneeshaw, D.D. (6701451805)"     
    ## 
    ## $`6701463107`
    ## [1] "Bragazza, Luca (6701463107)" "Bragazza, L. (6701463107)"  
    ## 
    ## $`6701511072`
    ## [1] "Aguilar, Salomón (6701511072)" "Aguilar, Salomon (6701511072)"
    ## [3] "Aguilar, S. (6701511072)"     
    ## 
    ## $`6701528428`
    ## [1] "Montaña, C. (6701528428)"     "Montaña, Carlos (6701528428)"
    ## [3] "Montana, Carlos (6701528428)"
    ## 
    ## $`6701536327`
    ## [1] "Rautio, Pasi (6701536327)" "Rautio, P. (6701536327)"  
    ## 
    ## $`6701538786`
    ## [1] "Podani, János (6701538786)" "Podani, J. (6701538786)"   
    ## 
    ## $`6701550009`
    ## [1] "Bradstock, Ross A. (6701550009)" "Bradstock, R.A. (6701550009)"   
    ## 
    ## $`6701553756`
    ## [1] "Vetaas, Ole Reidar (6701553756)" "Vetaas, Ole R. (6701553756)"    
    ## [3] "Vetaas, O.R. (6701553756)"      
    ## 
    ## $`6701555656`
    ## [1] "Floret, Ch. (6701555656)" "Floret, C. (6701555656)" 
    ## 
    ## $`6701578630`
    ## [1] "Boudreau, Stephane (6701578630)" "Boudreau, Stéphane (6701578630)"
    ## 
    ## $`6701583111`
    ## [1] "Santa Regina, Ignacio (6701583111)" "Santa Regina, I. (6701583111)"     
    ## 
    ## $`6701615556`
    ## [1] "Galatowitsch, Susan (6701615556)"    "Galatowitsch, Susan M. (6701615556)"
    ## 
    ## $`6701624354`
    ## [1] "Fynn, Richard W. S. (6701624354)" "Fynn, Richard W.S. (6701624354)" 
    ## [3] "Fynn, Richard (6701624354)"      
    ## 
    ## $`6701627983`
    ## [1] "Jalili, Adel (6701627983)" "Jalili, A. (6701627983)"  
    ## 
    ## $`6701639567`
    ## [1] "Bestelmeyer, Brandon Thomas (6701639567)"
    ## [2] "Bestelmeyer, Brandon T. (6701639567)"    
    ## 
    ## $`6701644918`
    ## [1] "Rego, Francisco C. (6701644918)" "Rego, F. (6701644918)"          
    ## 
    ## $`6701659121`
    ## [1] "El-Demerdash, M.A. (6701659121)" "El Demerdash, M.A. (6701659121)"
    ## [3] "El‐Demerdash, M.A. (6701659121)"
    ## 
    ## $`6701667284`
    ## [1] "Beltman, Boudewijn (6701667284)" "Beltman, B. (6701667284)"       
    ## 
    ## $`6701669530`
    ## [1] "Le Duc, Mike (6701669530)"    "Le Duc, M.G. (6701669530)"   
    ## [3] "Le Duc, Mike G. (6701669530)"
    ## 
    ## $`6701699872`
    ## [1] "Briske, David D. (6701699872)" "Briske, D.D. (6701699872)"    
    ## 
    ## $`6701706771`
    ## [1] "Ferrandis, Pablo (6701706771)" "Ferrandis, P. (6701706771)"   
    ## 
    ## $`6701724408`
    ## [1] "de Snoo, Geert R. (6701724408)" "De Snoo, Geert R. (6701724408)"
    ## 
    ## $`6701736764`
    ## [1] "Leathwick, John R. (6701736764)" "Leathwick, J.R. (6701736764)"   
    ## 
    ## $`6701742120`
    ## [1] "Loidi, Javier (6701742120)" "Loidi, J. (6701742120)"    
    ## 
    ## $`6701758453`
    ## [1] "Urbinati, Carlo (6701758453)" "Urbinati, C. (6701758453)"   
    ## 
    ## $`6701762058`
    ## [1] "van Rensburg, Berndt J. (6701762058)"
    ## [2] "Van Rensburg, Berndt J. (6701762058)"
    ## 
    ## $`6701765625`
    ## [1] "Nascimento, Henrique E.M. (6701765625)" 
    ## [2] "Nascimento, Henrique E. M. (6701765625)"
    ## [3] "Ascimento, E.M.Henrique (6701765625)"   
    ## 
    ## $`6701776177`
    ## [1] "Briones, Oscar (6701776177)" "Briones, O. (6701776177)"   
    ## 
    ## $`6701784716`
    ## [1] "Gosz, J.R. (6701784716)"     "Gosz, James R. (6701784716)"
    ## 
    ## $`6701786026`
    ## [1] "Dise, N. (6701786026)"    "Dise, Nancy (6701786026)"
    ## 
    ## $`6701789833`
    ## [1] "Limpens, Juul (6701789833)" "Limpens, J. (6701789833)"  
    ## 
    ## $`6701793539`
    ## [1] "Gulinck, Hubert (6701793539)" "Gulinck, H. (6701793539)"    
    ## 
    ## $`6701818106`
    ## [1] "Bradfield, G.E. (6701818106)"    "Bradfield, Gary E. (6701818106)"
    ## 
    ## $`6701827152`
    ## [1] "Chytrý, Milan (6701827152)" "Chytrỳ, Milan (6701827152)"
    ## [3] "Chytrý, M. (6701827152)"   
    ## 
    ## $`6701835524`
    ## [1] "Stenhouse, Gordon B. (6701835524)" "Stenhouse, G.B. (6701835524)"     
    ## 
    ## $`6701838004`
    ## [1] "Gitay, H. (6701838004)"     "Gitay, Habiba (6701838004)"
    ## 
    ## $`6701849853`
    ## [1] "Peltzer, Duane A. (6701849853)" "Peltzer, D.A. (6701849853)"    
    ## 
    ## $`6701852277`
    ## [1] "Jobbágy, Esteban G. (6701852277)" "Jobbagy, E.G. (6701852277)"      
    ## 
    ## $`6701860991`
    ## [1] "Honnay, Olivier (6701860991)" "Honnay, O. (6701860991)"     
    ## 
    ## $`6701868174`
    ## [1] "Pauchard, Anibal (6701868174)" "Pauchard, Aníbal (6701868174)"
    ## 
    ## $`6701878564`
    ## [1] "Dzwonko, Zbigniew (6701878564)" "Dzwonko, Z. (6701878564)"      
    ## 
    ## $`6701879014`
    ## [1] "Kienast, Felix (6701879014)" "Kienast, F. (6701879014)"   
    ## 
    ## $`6701900493`
    ## [1] "Valiente-Banuet, Alfonso (6701900493)"
    ## [2] "Valiente‐Banuet, Alfonso (6701900493)"
    ## [3] "Valiente‐Banuet, A. (6701900493)"     
    ## 
    ## $`6701909885`
    ## [1] "Escarré, J. (6701909885)" "Escarre, J. (6701909885)"
    ## 
    ## $`7003269957`
    ## [1] "Casagrande, Jose Carlos (7003269957)"
    ## [2] "Casagrande, José Carlos (7003269957)"
    ## 
    ## $`7003273684`
    ## [1] "Rydin, Håkan (7003273684)" "Rydin, H. (7003273684)"   
    ## 
    ## $`7003282896`
    ## [1] "Amoros, Claude (7003282896)" "Amoros, C. (7003282896)"    
    ## 
    ## $`7003286554`
    ## [1] "Sirois, L. (7003286554)"  "Sirois, Luc (7003286554)"
    ## 
    ## $`7003286849`
    ## [1] "Rejmánek, Marcel (7003286849)" "Rejmánek, M. (7003286849)"    
    ## 
    ## $`7003289125`
    ## [1] "Bonis, Anne (7003289125)" "Bonis, A. (7003289125)"  
    ## 
    ## $`7003301963`
    ## [1] "Seastedt, T.R. (7003301963)"       "Seastedt, Timothy R. (7003301963)"
    ## 
    ## $`7003308145`
    ## [1] "Wiser, Susan K. (7003308145)" "Wiser, Susan K (7003308145)" 
    ## [3] "Wiser, Susan (7003308145)"   
    ## 
    ## $`7003342554`
    ## [1] "Izco, Jesús (7003342554)" "Izco, J. (7003342554)"   
    ## 
    ## $`7003357337`
    ## [1] "Dalling, James William (7003357337)" "Dalling, James W. (7003357337)"     
    ## [3] "Dalling, J.W. (7003357337)"         
    ## 
    ## $`7003358004`
    ## [1] "Vasander, Harri (7003358004)" "Vasander, H. (7003358004)"   
    ## 
    ## $`7003370336`
    ## [1] "Cottrell, Tom R. (7003370336)" "Cottrell, T.R. (7003370336)"  
    ## 
    ## $`7003390764`
    ## [1] "Salonen, V. (7003390764)"     "Salonen, Veikko (7003390764)"
    ## 
    ## $`7003407069`
    ## [1] "Blasi, Carlo (7003407069)" "Blasi, C. (7003407069)"   
    ## 
    ## $`7003422919`
    ## [1] "Lavorel, Sandra (7003422919)" "Lavorel, S. (7003422919)"    
    ## 
    ## $`7003439068`
    ## [1] "Lamers, Leon P. M. (7003439068)" "Lamers, L.P.M. (7003439068)"    
    ## [3] "Lamers, Leon P.M. (7003439068)" 
    ## 
    ## $`7003440508`
    ## [1] "Kadmon, R. (7003440508)"    "Kadmon, Ronen (7003440508)"
    ## 
    ## $`7003448609`
    ## [1] "Bustamante, Ramiro O. (7003448609)" "Bustamante, R.O. (7003448609)"     
    ## 
    ## $`7003474461`
    ## [1] "Putz, Francis E. (7003474461)"  "Putz, Francis. E. (7003474461)"
    ## 
    ## $`7003488202`
    ## [1] "Tolvanen, Anne (7003488202)" "Tolvanen, A. (7003488202)"  
    ## 
    ## $`7003490199`
    ## [1] "Takehara, A. (7003490199)"      "Takehara, Akihide (7003490199)"
    ## 
    ## $`7003491477`
    ## [1] "Box, E.O. (7003491477)"      "Box, Elgene O. (7003491477)"
    ## 
    ## $`7003502176`
    ## [1] "Denslow, Julie S. (7003502176)" "Denslow, J.S. (7003502176)"    
    ## 
    ## $`7003504656`
    ## [1] "Leuschner, Christoph (7003504656)" "Leuschner, Ch. (7003504656)"      
    ## 
    ## $`7003507706`
    ## [1] "Leishman, Michelle R. (7003507706)" "Leishman, M.R. (7003507706)"       
    ## 
    ## $`7003514326`
    ## [1] "Van Groenendael, Jan M. (7003514326)"
    ## [2] "Van Groenendael, J.M. (7003514326)"  
    ## 
    ## $`7003519279`
    ## [1] "Heegaard, Einar (7003519279)" "Einar, Heegaard (7003519279)"
    ## 
    ## $`7003520808`
    ## [1] "Lusk, Christopher H. (7003520808)" "Lusk, C.H. (7003520808)"          
    ## 
    ## $`7003525019`
    ## [1] "Verbeek, Steven K. (7003525019)" "Verbeek, S. (7003525019)"       
    ## 
    ## $`7003526237`
    ## [1] "Lepart, Jacques (7003526237)" "Lepart, J. (7003526237)"     
    ## 
    ## $`7003528684`
    ## [1] "Flannigan, Mike (7003528684)" "Flannigan, M.D. (7003528684)"
    ## 
    ## $`7003535549`
    ## [1] "Moen, Asbjørn (7003535549)" "Moen, Absjørn (7003535549)"
    ## 
    ## $`7003542662`
    ## [1] "Agnew, Andrew D. Q. (7003542662)" "Agnew, A.D.Q. (7003542662)"      
    ## 
    ## $`7003548799`
    ## [1] "Busing, Richard T. (7003548799)" "Busing, R.T. (7003548799)"      
    ## 
    ## $`7003572996`
    ## [1] "Nigel Critchley, C. (7003572996)"    "Critchley, C.N.R. (7003572996)"     
    ## [3] "Critchley, C. Nigel R. (7003572996)"
    ## 
    ## $`7003594027`
    ## [1] "Pineda, F.D. (7003594027)"         "Pineda, Francisco D. (7003594027)"
    ## 
    ## $`7003603665`
    ## [1] "van der Maarel, Eddy (7003603665)" "Van Der Maarel, Eddy (7003603665)"
    ## 
    ## $`7003604942`
    ## [1] "Krahulec, František (7003604942)" "Krahulec, F. (7003604942)"       
    ## 
    ## $`7003608882`
    ## [1] "Rochefort, Line (7003608882)" "Rochefort, L. (7003608882)"  
    ## 
    ## $`7003621502`
    ## [1] "Delgadillo, José (7003621502)" "Delgadillo, J. (7003621502)"  
    ## 
    ## $`7003628253`
    ## [1] "Milchunas, Daniel G. (7003628253)" "Milchunas, Daniel (7003628253)"   
    ## [3] "Milchunas, D.G. (7003628253)"     
    ## 
    ## $`7003628254`
    ## [1] "Bornette, Gudrun (7003628254)"         
    ## [2] "Bornette, G. (7003628254)"             
    ## [3] "Bornette, G. & Amoros, C. (7003628254)"
    ## 
    ## $`7003650577`
    ## [1] "Paruelo, José María (7003650577)" "Paruelo, José M. (7003650577)"   
    ## [3] "Paruelo, J.M. (7003650577)"       "Paruelo Jose, M. (7003650577)"   
    ## 
    ## $`7003674132`
    ## [1] "Mueller-Dombois, Dieter (7003674132)"
    ## [2] "Mueller-Dombois, D. (7003674132)"    
    ## [3] "Mueller‐Dombois, Dieter (7003674132)"
    ## 
    ## $`7003675412`
    ## [1] "Gillet, François (7003675412)" "Gillet, F. (7003675412)"      
    ## 
    ## $`7003687876`
    ## [1] "Menges, Eric S. (7003687876)" "Menges, E.S. (7003687876)"   
    ## 
    ## $`7003689075`
    ## [1] "Fensham, Roderick (7003689075)"    "Fensham, Roderick J. (7003689075)"
    ## [3] "Fensham, Rod (7003689075)"         "Fensham, R.J. (7003689075)"       
    ## [5] "Fensham, Rod J. (7003689075)"     
    ## 
    ## $`7003696043`
    ## [1] "Bay, C. (7003696043)"        "Bay, Christian (7003696043)"
    ## 
    ## $`7003701955`
    ## [1] "Spada, Francesco (7003701955)" "Spada, F. (7003701955)"       
    ## 
    ## $`7003705691`
    ## [1] "Wiegleb, G. (7003705691)"      "Wiegleb, Gerhard (7003705691)"
    ## 
    ## $`7003707334`
    ## [1] "Carranza, Maria Laura (7003707334)" "Carranza, Maria L. (7003707334)"   
    ## [3] "Carranza, María L. (7003707334)"    "Carranza, M. Laura (7003707334)"   
    ## [5] "Carranza, M.L. (7003707334)"       
    ## 
    ## $`7003726521`
    ## [1] "Duru, Michel (7003726521)" "Duru, M. (7003726521)"    
    ## 
    ## $`7003732505`
    ## [1] "Thwaites, R.H. (7003732505)"       "Thwaites, Rachael H. (7003732505)"
    ## 
    ## $`7003733322`
    ## [1] "Hódar, Jose A. (7003733322)" "Hódar, José A. (7003733322)"
    ## 
    ## $`7003735120`
    ## [1] "Saracino, Antonio (7003735120)" "Saracino, A. (7003735120)"     
    ## 
    ## $`7003794072`
    ## [1] "Prach, Karel (7003794072)" "Prach, K. (7003794072)"   
    ## 
    ## $`7003797229`
    ## [1] "Olano, José M. (7003797229)"     "Olano, J.M. (7003797229)"       
    ## [3] "Olano, José Miguel (7003797229)"
    ## 
    ## $`7003828956`
    ## [1] "Mountford, J.Owen (7003828956)"  "Mountford, J. Owen (7003828956)"
    ## [3] "Owen, Mountford J. (7003828956)" "Mountford, J.O. (7003828956)"   
    ## 
    ## $`7003843226`
    ## [1] "Bongers, Frans (7003843226)" "Bongers, F. (7003843226)"   
    ## 
    ## $`7003854080`
    ## [1] "Lepš, Jan (7003854080)" "Leps, Jan (7003854080)" "Lepš, J. (7003854080)" 
    ## [4] "Leps, J. (7003854080)" 
    ## 
    ## $`7003856583`
    ## [1] "Pakeman, Robin J. (7003856583)" "Pakeman, R.J. (7003856583)"    
    ## 
    ## $`7003874259`
    ## [1] "Sukumar, Raman (7003874259)" "Sukumar, R. (7003874259)"   
    ## 
    ## $`7003877518`
    ## [1] "van der Wal, René (7003877518)" "Van Der Wal, René (7003877518)"
    ## 
    ## $`7003891193`
    ## [1] "Pugnaire, Francisco I. (7003891193)" "Pugnaire, F.I. (7003891193)"        
    ## 
    ## $`7003926817`
    ## [1] "Werger, Marinus J.A. (7003926817)"  "Werger, Marinus J. A. (7003926817)"
    ## [3] "Werger, M.J.A. (7003926817)"       
    ## 
    ## $`7003929943`
    ## [1] "Quesada, Carlos A. (7003929943)" "Quesada, C.A. (7003929943)"     
    ## 
    ## $`7003953689`
    ## [1] "Valladares, Fernando (7003953689)" "Valladares, F. (7003953689)"      
    ## 
    ## $`7003966029`
    ## [1] "Charman, D. (7003966029)"        "Charman, Daniel J. (7003966029)"
    ## 
    ## $`7003975371`
    ## [1] "Pélissier, Raphaël (7003975371)" "Pélissier, R. (7003975371)"     
    ## 
    ## $`7003982810`
    ## [1] "Armesto, Juan J. (7003982810)" "Armesto, J.J. (7003982810)"   
    ## 
    ## $`7003986549`
    ## [1] "Fairfax, Russell J. (7003986549)" "Fairfax, R.J. (7003986549)"      
    ## 
    ## $`7003987230`
    ## [1] "Gerdol, Renato (7003987230)" "Gerdol, R. (7003987230)"    
    ## 
    ## $`7003996720`
    ## [1] "Olff, Han (7003996720)" "Olff, H. (7003996720)" 
    ## 
    ## $`7004032732`
    ## [1] "Smits, N.A.C. (7004032732)"    "Smits, Nina A.C. (7004032732)"
    ## 
    ## $`7004035832`
    ## [1] "Malhi, Yadvinder (7004035832)" "Malhi, Y. (7004035832)"       
    ## 
    ## $`7004039799`
    ## [1] "Hermy, Martin (7004039799)" "Hermy, M. (7004039799)"    
    ## 
    ## $`7004049756`
    ## [1] "Skoglund, J. (7004049756)"    "Skoglund, Jerry (7004049756)"
    ## 
    ## $`7004063026`
    ## [1] "de Kroon, Hans (7004063026)" "De Kroon, H. (7004063026)"  
    ## [3] "De Kroon, Hans (7004063026)"
    ## 
    ## $`7004070688`
    ## [1] "Preece, Noel D. (7004070688)" "Preece, Noel (7004070688)"   
    ## 
    ## $`7004076643`
    ## [1] "Mladenoff, David J (7004076643)"  "Mladenoff, David J. (7004076643)"
    ## 
    ## $`7004084110`
    ## [1] "Rune, Halvorsen (7004084110)"        "Økland, Rune H. (7004084110)"       
    ## [3] "Økland, Rane Halvorsen (7004084110)" "Økland, R.H. (7004084110)"          
    ## [5] "Økland, Rune Halvorsen (7004084110)" "Okland, R.H. (7004084110)"          
    ## [7] "Okland, Rune H. (7004084110)"       
    ## 
    ## $`7004095579`
    ## [1] "Pyšek, Petr (7004095579)" "Pyšek, P. (7004095579)"  
    ## 
    ## $`7004097206`
    ## [1] "Einarsson, Eythor (7004097206)" "Einarsson, E. (7004097206)"    
    ## 
    ## $`7004115653`
    ## [1] "Burel, Françoise (7004115653)" "Burel, Francoise (7004115653)"
    ## 
    ## $`7004129531`
    ## [1] "Tomlinson, Kyle W. (7004129531)" "Tomlinson, K.W. (7004129531)"   
    ## 
    ## $`7004142646`
    ## [1] "Acker, S.A. (7004142646)"      "Acker, Steven A. (7004142646)"
    ## 
    ## $`7004145266`
    ## [1] "Fresco, L.F.M. (7004145266)"     "Fresco, Latzi F.M. (7004145266)"
    ## 
    ## $`7004148913`
    ## [1] "Junk, Wolfgang Johannes (7004148913)"
    ## [2] "Junk, W.J. (7004148913)"             
    ## 
    ## $`7004158298`
    ## [1] "Mazzarino, María Julia (7004158298)" "Mazzarino, M.J. (7004158298)"       
    ## 
    ## $`7004159021`
    ## [1] "De Grandpré, Louis (7004159021)" "De Grandpré, L. (7004159021)"   
    ## 
    ## $`7004184660`
    ## [1] "Cousens, Roger D. (7004184660)" "Cousens, Roger D (7004184660)" 
    ## 
    ## $`7004214029`
    ## [1] "Trabaud, L. (7004214029)"    "Trabaud, Louis (7004214029)"
    ## 
    ## $`7004214819`
    ## [1] "Ackerly, David D. (7004214819)" "Ackerly, David (7004214819)"   
    ## 
    ## $`7004227580`
    ## [1] "Pausas, Juli G. (7004227580)" "Pausas, J.G. (7004227580)"   
    ## 
    ## $`7004234223`
    ## [1] "Ramsay, Paul M (7004234223)"  "Ramsay, Paul M. (7004234223)"
    ## 
    ## $`7004243498`
    ## [1] "Wassen, Martin J. (7004243498)"     "Wassen, Martin (7004243498)"       
    ## [3] "Wassen, Martin Joseph (7004243498)"
    ## 
    ## $`7004245729`
    ## [1] "Romme, W.H. (7004245729)"       "Romme, William H. (7004245729)"
    ## 
    ## $`7004254254`
    ## [1] "Lao, Suzanne (7004254254)" "Lao, S. (7004254254)"     
    ## 
    ## $`7004271669`
    ## [1] "Buttler, Alexandre (7004271669)" "Buttler, A. (7004271669)"       
    ## 
    ## $`7004292050`
    ## [1] "Dickie, John (7004292050)"    "Dickie, John B. (7004292050)"
    ## 
    ## $`7004300326`
    ## [1] "Pezzi, Giovanna (7004300326)" "Pezzi, G. (7004300326)"      
    ## 
    ## $`7004308801`
    ## [1] "Lunt, Ian D. (7004308801)" "Lunt, I.D. (7004308801)"  
    ## 
    ## $`7004316721`
    ## [1] "Mead, B.R. (7004316721)"    "Mead, Bert R. (7004316721)"
    ## 
    ## $`7004322831`
    ## [1] "Alados, Concepción L. (7004322831)" "Alados, C.L. (7004322831)"         
    ## 
    ## $`7004381721`
    ## [1] "D'Antonio, Carla (7004381721)"    "D'Antonio, Carla M. (7004381721)"
    ## 
    ## $`7004402429`
    ## [1] "Ehrlén, Johan (7004402429)" "Ehrlén, J. (7004402429)"   
    ## 
    ## $`7004408177`
    ## [1] "Traveset, Anna (7004408177)" "Traveset, A. (7004408177)"  
    ## 
    ## $`7004416595`
    ## [1] "Smart, Simon M. (7004416595)" "Smart, S.M. (7004416595)"    
    ## 
    ## $`7004427241`
    ## [1] "Kavanagh, R.P. (7004427241)"      "Kavanagh, Rodney P. (7004427241)"
    ## 
    ## $`7004429557`
    ## [1] "Standish, Rachel Jayne (7004429557)" "Standish, Rachel J. (7004429557)"   
    ## 
    ## $`7004436948`
    ## [1] "Farji-Brener, Alejandro G. (7004436948)"
    ## [2] "Farji-Brener, A.G. (7004436948)"        
    ## 
    ## $`7004441652`
    ## [1] "Ooi, Mark K. J. (7004441652)" "Ooi, Mark K.J. (7004441652)" 
    ## 
    ## $`7004442823`
    ## [1] "Zajączkowski, Jacek (7004442823)" "Za̧jaczkowski, Jacek (7004442823)"
    ## 
    ## $`7004449388`
    ## [1] "Kiehl, Kathrin (7004449388)" "Kiehl, K. (7004449388)"     
    ## 
    ## $`7004454068`
    ## [1] "Aarssen, Lonnie (7004454068)"    "Aarssen, Lonnie W. (7004454068)"
    ## [3] "Aarssen, L.W. (7004454068)"     
    ## 
    ## $`7004460066`
    ## [1] "Birks, H. John B. (7004460066)" "Birks, H.J.B. (7004460066)"    
    ## 
    ## $`7004472358`
    ## [1] "Klimeš, Leoš (7004472358)" "Klimeš, L. (7004472358)"  
    ## 
    ## $`7004477665`
    ## [1] "Romanovsky, Vladimir E. (7004477665)"
    ## [2] "Romanovsky, V. (7004477665)"         
    ## 
    ## $`7004484104`
    ## [1] "Porembski, S. (7004484104)"     "Porembski, Stefan (7004484104)"
    ## 
    ## $`7004515951`
    ## [1] "Soussana, Jean-François (7004515951)"
    ## [2] "Soussana, J.-F. (7004515951)"        
    ## 
    ## $`7004517059`
    ## [1] "Gómez-Gutiérrez, J.M. (7004517059)"   
    ## [2] "Gómez‐Gutiérrez, José M. (7004517059)"
    ## 
    ## $`7004529467`
    ## [1] "Sala Osvaldo, E. (7004529467)" "Sala, Osvaldo E. (7004529467)"
    ## [3] "Sala, O.E. (7004529467)"      
    ## 
    ## $`7004535648`
    ## [1] "Watt, T.A. (7004535648)"     "Watt, Trudy A. (7004535648)"
    ## 
    ## $`7004538613`
    ## [1] "Woodin, Sarah J. (7004538613)" "Woodin, S.J. (7004538613)"    
    ## 
    ## $`7004568131`
    ## [1] "Tausch, R.J. (7004568131)"     "Tausch, Robin J. (7004568131)"
    ## 
    ## $`7004590620`
    ## [1] "Enquist, Brian (7004590620)"    "Enquist, Brian J. (7004590620)"
    ## 
    ## $`7004623576`
    ## [1] "Bouma, Tjeerd J. (7004623576)" "Bouma, T.J. (7004623576)"     
    ## 
    ## $`7004628271`
    ## [1] "Melillo, J. (7004628271)"       "Melillo, Jerry M. (7004628271)"
    ## 
    ## $`7004646858`
    ## [1] "Adema, E.B. (7004646858)"     "Adema, Erwin B. (7004646858)"
    ## 
    ## $`7004676970`
    ## [1] "Lafon, Charles W. (7004676970)" "Lafon, C.W. (7004676970)"      
    ## 
    ## $`7004682192`
    ## [1] "Bekker, Renée M. (7004682192)" "Bekker, R.M. (7004682192)"    
    ## 
    ## $`7004692154`
    ## [1] "Bhatti, Jagtar S. (7004692154)" "Bhatti, J. (7004692154)"       
    ## 
    ## $`7004707858`
    ## [1] "Cantero, Juan J. (7004707858)"   "Cantero, Juan José (7004707858)"
    ## [3] "Cantero, J.J. (7004707858)"     
    ## 
    ## $`7004785148`
    ## [1] "Buckley, Hannah (7004785148)"    "Buckley, Hannah L. (7004785148)"
    ## 
    ## $`7004795931`
    ## [1] "Hartley, S.E. (7004795931)"     "Hartley, Susan E. (7004795931)"
    ## 
    ## $`7004822392`
    ## [1] "Erasmus, Barend F. N. (7004822392)" "Erasmus, Barend F.N. (7004822392)" 
    ## 
    ## $`7004846059`
    ## [1] "Ladd, Philip G. (7004846059)"  "Ladd, Phillip G. (7004846059)"
    ## 
    ## $`7004861348`
    ## [1] "Keddy, P.A. (7004861348)"    "Keddy, Paul A. (7004861348)"
    ## [3] "Keddy, P. (7004861348)"      "Keddy, Paul (7004861348)"   
    ## 
    ## $`7004883651`
    ## [1] "Zavala, Miguel A. (7004883651)"    "Zavala, Miguel Angel (7004883651)"
    ## [3] "Zavala, M.A. (7004883651)"        
    ## 
    ## $`7004885768`
    ## [1] "Kuitunen, Markku (7004885768)"    "Kuitunen, Markku T. (7004885768)"
    ## 
    ## $`7004888026`
    ## [1] "Kuuluvainen, Timo (7004888026)" "Kuuluvainen, T. (7004888026)"  
    ## 
    ## $`7004916681`
    ## [1] "Pickett, S.T.A. (7004916681)"       "Pickett, Steward T.A. (7004916681)"
    ## 
    ## $`7004934132`
    ## [1] "Bobbink, Roland (7004934132)" "Bobbink, R. (7004934132)"    
    ## 
    ## $`7004997053`
    ## [1] "Lauenroth, William K. (7004997053)" "Lauenroth, W.K. (7004997053)"      
    ## 
    ## $`7004998563`
    ## [1] "Meester, Luc De (7004998563)" "de Meester, Luc (7004998563)"
    ## 
    ## $`7005009244`
    ## [1] "Monteagudo, Abel (7005009244)" "Monteagudo, A. (7005009244)"  
    ## 
    ## $`7005010313`
    ## [1] "Witkowski, Edward T. F. (7005010313)"
    ## [2] "Witkowski, Ed T. F. (7005010313)"    
    ## [3] "Witkowski, Ed T.F. (7005010313)"     
    ## [4] "Witkowski, Edward T.F. (7005010313)" 
    ## 
    ## $`7005021300`
    ## [1] "Woodcock, Ben A. (7005021300)" "Woodcock, B.A. (7005021300)"  
    ## 
    ## $`7005021359`
    ## [1] "Gries, Dirk (7005021359)" "Gries, D. (7005021359)"  
    ## 
    ## $`7005053303`
    ## [1] "Koike, Fumito (7005053303)" "Koike, F. (7005053303)"    
    ## 
    ## $`7005115672`
    ## [1] "Nygaard, Bettina (7005115672)" "Nygaard, B. (7005115672)"     
    ## 
    ## $`7005183850`
    ## [1] "Daniëls, Fred J.A. (7005183850)" "Daniëls Fred, J.A. (7005183850)"
    ## [3] "Daniëls, F.J.A. (7005183850)"   
    ## 
    ## $`7005211681`
    ## [1] "van Rooyen, Margaretha W. (7005211681)"
    ## [2] "Van Rooyen, M.W. (7005211681)"         
    ## 
    ## $`7005227707`
    ## [1] "Kasischke, Eric S. (7005227707)" "Kasischke, E. (7005227707)"     
    ## 
    ## $`7005295903`
    ## [1] "Steffen, W.L. (7005295903)"       "Steffen, William L. (7005295903)"
    ## 
    ## $`7005300538`
    ## [1] "Garnier, Eric (7005300538)" "Garnie, Eric (7005300538)" 
    ## [3] "Garnier, E. (7005300538)"  
    ## 
    ## $`7005313221`
    ## [1] "McCune, Bruce (7005313221)" "McCune, B. (7005313221)"   
    ## 
    ## $`7005315418`
    ## [1] "MacGregor, Christopher I. (7005315418)"
    ## [2] "Macgregor, Christopher I. (7005315418)"
    ## 
    ## $`7005326435`
    ## [1] "Burrows, Lawrence E. (7005326435)" "Burrows, Larry E. (7005326435)"   
    ## 
    ## $`7005346868`
    ## [1] "Mabry, Cathy M. (7005346868)" "Mabry, Cathy (7005346868)"   
    ## 
    ## $`7005350819`
    ## [1] "Makita, A. (7005350819)"      "Makita, Akifumi (7005350819)"
    ## 
    ## $`7005365706`
    ## [1] "Danell, K. (7005365706)"    "Danell, Kjell (7005365706)"
    ## 
    ## $`7005369833`
    ## [1] "de Groot, William J. (7005369833)" "De Groot, W.J. (7005369833)"      
    ## 
    ## $`7005391089`
    ## [1] "Burke, Ingrid C. (7005391089)" "Burke, I.C. (7005391089)"     
    ## 
    ## $`7005487323`
    ## [1] "Klinka, K. (7005487323)"    "Klinka, Karel (7005487323)"
    ## 
    ## $`7005510044`
    ## [1] "Sýkora, K.V. (7005510044)"     "Sýkora, Karle V. (7005510044)"
    ## [3] "Sýkora, Karlè V. (7005510044)" "Sýkora, Karle (7005510044)"   
    ## 
    ## $`7005516464`
    ## [1] "Carswell, Fiona E. (7005516464)" "Carswell, Fiona E. (7005516464)"
    ## 
    ## $`7005519490`
    ## [1] "Halvorsen, Rune (7005519490)" "Halvorsen, R. (7005519490)"  
    ## 
    ## $`7005538788`
    ## [1] "Lieffers, Victor J. (7005538788)" "Lieffers, V.J. (7005538788)"     
    ## 
    ## $`7005556770`
    ## [1] "Pinard, Michelle (7005556770)"    "Pinard, Michelle A. (7005556770)"
    ## 
    ## $`7005566711`
    ## [1] "Roelofs, Jan G.M. (7005566711)" "Roelofs, J.G.M. (7005566711)"  
    ## 
    ## $`7005569439`
    ## [1] "Rusch, Graciela M. (7005569439)" "Rusch, Graciela (7005569439)"   
    ## [3] "Rusch, G.M. (7005569439)"       
    ## 
    ## $`7005616902`
    ## [1] "Nakashizuka, Tohru (7005616902)" "Nakashizuka, T. (7005616902)"   
    ## 
    ## $`7005621941`
    ## [1] "Coffin, Debra P. (7005621941)" "Coffin, D.P. (7005621941)"    
    ## 
    ## $`7005630063`
    ## [1] "Duarte, Leandro (7005630063)"       "Duarte, Leandro D. S. (7005630063)"
    ## [3] "Duarte, Leandro da S. (7005630063)" "Duarte, Leandro D.S. (7005630063)" 
    ## [5] "Duarte, Leandro Da S. (7005630063)"
    ## 
    ## $`7005640660`
    ## [1] "Hauck, Markus (7005640660)" "Hauck, M. (7005640660)"    
    ## 
    ## $`7005650735`
    ## [1] "Moravec, J. (7005650735)"       "Moravec, Jaroslav (7005650735)"
    ## 
    ## $`7005660466`
    ## [1] "Whitmore, T.C. (7005660466)"       "Whitmore, Timothy C. (7005660466)"
    ## 
    ## $`7005695804`
    ## [1] "Mackey, Brendan (7005695804)"    "Mackey, Brendan G. (7005695804)"
    ## 
    ## $`7005710296`
    ## [1] "Veblen, Thomas Thorstein (7005710296)"
    ## [2] "Veblen, Thomas T. (7005710296)"       
    ## [3] "Veblen, Thomas (7005710296)"          
    ## [4] "Veblen, T.T. (7005710296)"            
    ## 
    ## $`7005712332`
    ## [1] "Prentice, I. Colin (7005712332)" "Prentice, I.C. (7005712332)"    
    ## 
    ## $`7005712821`
    ## [1] "Ewald, Jörg (7005712821)" "Ewald, J. (7005712821)"  
    ## 
    ## $`7005755464`
    ## [1] "Vesala, Timo (7005755464)" "Vesala, T. (7005755464)"  
    ## 
    ## $`7005761128`
    ## [1] "Landsberg, J. (7005761128)"   "Landsberg, Jill (7005761128)"
    ## 
    ## $`7005768098`
    ## [1] "Scarano, Fabio Rubio (7005768098)" "Scarano, Fabio R. (7005768098)"   
    ## 
    ## $`7005798342`
    ## [1] "Aguiar, Martín R. (7005798342)" "Aguiar, M.R. (7005798342)"     
    ## [3] "Aguiar, Martin R. (7005798342)"
    ## 
    ## $`7005815395`
    ## [1] "Delibes, Miguel (7005815395)" "Miguel, Delibes (7005815395)"
    ## 
    ## $`7005821127`
    ## [1] "Jacobi, James D. (7005821127)" "Jacobi, J.D. (7005821127)"    
    ## 
    ## $`7005856982`
    ## [1] "Drapeau, Pierre (7005856982)" "Drapeau, P. (7005856982)"    
    ## 
    ## $`7005861331`
    ## [1] "Gilliam, Frank S. (7005861331)" "Gilliam, F.S. (7005861331)"    
    ## 
    ## $`7005877011`
    ## [1] "Peet, Robert K. (7005877011)" "Peet, Robert K (7005877011)" 
    ## [3] "Peet, R.K. (7005877011)"     
    ## 
    ## $`7005969048`
    ## [1] "Buckley, Peter (7005969048)" "Buckley, G.P. (7005969048)" 
    ## 
    ## $`7005970209`
    ## [1] "Ponge, Jean-François (7005970209)" "Ponge, Jean‐François (7005970209)"
    ## 
    ## $`7005974776`
    ## [1] "Zedler, J.B. (7005974776)"   "Zedler, Joy B. (7005974776)"
    ## 
    ## $`7005983383`
    ## [1] "Vieira, Daniel Luis Mascia (7005983383)"
    ## [2] "Vieira, Daniel L.M. (7005983383)"       
    ## 
    ## $`7006015880`
    ## [1] "Shugart, Herman H. (7006015880)" "Shugart, H.H. (7006015880)"     
    ## 
    ## $`7006027543`
    ## [1] "Santiago, Louis Stephen (7006027543)"
    ## [2] "Santiago, Louis S. (7006027543)"     
    ## 
    ## $`7006037325`
    ## [1] "Turkington, Roy (7006037325)" "Roy, Turkington (7006037325)"
    ## [3] "Turkington, R. (7006037325)" 
    ## 
    ## $`7006082840`
    ## [1] "Kooijman, A.M. (7006082840)"         "Kooijman, Annemieke M. (7006082840)"
    ## 
    ## $`7006099704`
    ## [1] "Boer, Matthias M. (7006099704)" "Boer, Matthias (7006099704)"   
    ## 
    ## $`7006139195`
    ## [1] "Morissette, Jacques (7006139195)" "Morissette, J. (7006139195)"     
    ## 
    ## $`7006152105`
    ## [1] "Pyke, C.R. (7006152105)"           "Pyke, Christopher R. (7006152105)"
    ## 
    ## $`7006183995`
    ## [1] "Côté, Steeve D (7006183995)"  "Côté, Steeve D. (7006183995)"
    ## 
    ## $`7006190305`
    ## [1] "McQueen, Amelia A. M. (7006190305)" "McQueen, Amelia A.M. (7006190305)" 
    ## 
    ## $`7006215345`
    ## [1] "Reif, Albert (7006215345)" "Reif, A. (7006215345)"    
    ## 
    ## $`7006221205`
    ## [1] "Ricotta, Carlo (7006221205)" "Ricotta, C. (7006221205)"   
    ## 
    ## $`7006228379`
    ## [1] "Doležal, J. (7006228379)"   "Doležal, Jiří (7006228379)"
    ## 
    ## $`7006233160`
    ## [1] "Aragón, Gregorio (7006233160)" "Aragon, Gregorio (7006233160)"
    ## [3] "Aragón, G. (7006233160)"      
    ## 
    ## $`7006236509`
    ## [1] "Laurance, William F. (7006236509)" "Laurance, F.William (7006236509)" 
    ## [3] "Laurance, W.F. (7006236509)"      
    ## 
    ## $`7006258563`
    ## [1] "Boyce, R.L. (7006258563)"       "Boyce, Richard L. (7006258563)"
    ## 
    ## $`7006301169`
    ## [1] "Lavoie, Claude (7006301169)" "Lavoie, C. (7006301169)"    
    ## 
    ## $`7006307181`
    ## [1] "Dimopoulos, Panayotis (7006307181)"  "Dimopoulos, Panagiotis (7006307181)"
    ## 
    ## $`7006319477`
    ## [1] "Eldridge, David J. (7006319477)"   "Eldridge, David John (7006319477)"
    ## 
    ## $`7006383294`
    ## [1] "McAlister, Suzanne D. (7006383294)" "McAlister, Suzanne (7006383294)"   
    ## 
    ## $`7006384506`
    ## [1] "Bergeron, Yves (7006384506)" "Bergeron, Y. (7006384506)"  
    ## 
    ## $`7006509854`
    ## [1] "Oksanen, Jari (7006509854)" "Oksanen, J. (7006509854)"  
    ## 
    ## $`7006518879`
    ## [1] "Skidmore, Andrew K. (7006518879)" "Skidmore, A.K. (7006518879)"     
    ## 
    ## $`7006549169`
    ## [1] "Elias, R.B. (7006549169)"   "Elias, Rui B. (7006549169)"
    ## 
    ## $`7006549226`
    ## [1] "Cingolani, Ana María (7006549226)" "Cingolani, Ana M. (7006549226)"   
    ## [3] "Cingolani, A.M. (7006549226)"      "Cingolani, Ana (7006549226)"      
    ## 
    ## $`7006549393`
    ## [1] "Noble, I.R. (7006549393)"   "Noble, Ian R. (7006549393)"
    ## 
    ## $`7006607190`
    ## [1] "Virtanen, Risto (7006607190)" "Virtanen, R. (7006607190)"   
    ## 
    ## $`7006619647`
    ## [1] "del Moral, Roger (7006619647)" "Del Moral, Roger (7006619647)"
    ## [3] "Del Moral, R. (7006619647)"    "del Moral, R. (7006619647)"   
    ## 
    ## $`7006628605`
    ## [1] "Sha, Li-Qing (7006628605)" "Sha, Liqing (7006628605)" 
    ## 
    ## $`7006635197`
    ## [1] "Milberg, Per (7006635197)" "Milberg, P. (7006635197)" 
    ## 
    ## $`7006651613`
    ## [1] "Pellerin, Stéphanie (7006651613)" "Pellerin, S. (7006651613)"       
    ## 
    ## $`7006663225`
    ## [1] "Duckworth, Jennifer C. (7006663225)" "Duckworth, J.C. (7006663225)"       
    ## 
    ## $`7006673171`
    ## [1] "During, Heinjo J. (7006673171)" "During, Heinjo (7006673171)"   
    ## 
    ## $`7006700988`
    ## [1] "Fearnside, Philip M. (7006700988)"  "Fearnside, Phillip M. (7006700988)"
    ## [3] "Fearnside, M.Philip (7006700988)"  
    ## 
    ## $`7006716604`
    ## [1] "Aerts, Rien (7006716604)" "Aerts, R. (7006716604)"  
    ## 
    ## $`7006742178`
    ## [1] "Gottfried, Michael (7006742178)" "Gottfried, M. (7006742178)"     
    ## 
    ## $`7006747772`
    ## [1] "Peñuelas, Josep (7006747772)" "Penuelas, Josep (7006747772)"
    ## 
    ## $`7006755089`
    ## [1] "Huntley, B. (7006755089)"    "Huntley, Brian (7006755089)"
    ## 
    ## $`7006832345`
    ## [1] "van Rooyen, Noel (7006832345)" "Van Rooyen, Noel (7006832345)"
    ## 
    ## $`7006898899`
    ## [1] "Battaglia, Loretta L. (7006898899)" "Battaglia, L.L. (7006898899)"      
    ## 
    ## $`7006913433`
    ## [1] "Hulme, Philip E. (7006913433)" "Hulme, P.E. (7006913433)"     
    ## 
    ## $`7006992956`
    ## [1] "Verdú, Miguel (7006992956)" "Verdú, M. (7006992956)"    
    ## 
    ## $`7007033191`
    ## [1] "Chapin III, F. Stuart (7007033191)" "Chapin III, F.S. (7007033191)"     
    ## [3] "Chapin, F.S. (7007033191)"         
    ## 
    ## $`7007082693`
    ## [1] "Ohlson, Mikael (7007082693)" "Ohlson, M. (7007082693)"    
    ## 
    ## $`7007094108`
    ## [1] "Szewczyk, Janusz (7007094108)" "Szewczyk, J. (7007094108)"    
    ## 
    ## $`7007114324`
    ## [1] "Leduc, Alain (7007114324)" "Leduc, A. (7007114324)"   
    ## 
    ## $`7007146026`
    ## [1] "Lawes, Michael J. (7007146026)" "Lawes, Michael (7007146026)"   
    ## 
    ## $`7007159302`
    ## [1] "Harper, Karen A. (7007159302)"     "Harper, Karen Amanda (7007159302)"
    ## [3] "Harper, Karen (7007159302)"       
    ## 
    ## $`7007163910`
    ## [1] "Cowling, Richard M. (7007163910)" "Cowling, R.M. (7007163910)"      
    ## 
    ## $`7101602041`
    ## [1] "Titus, Jonathan H. (7101602041)" "Titus, J.H. (7101602041)"       
    ## 
    ## $`7101602875`
    ## [1] "Vogt, Kati (7101602875)" "Vogt, K. (7101602875)"  
    ## 
    ## $`7101605057`
    ## [1] "Mallik, Azim U. (7101605057)" "Mallik, A.U. (7101605057)"   
    ## 
    ## $`7101626890`
    ## [1] "Lawson Clare, S. (7101626890)" "Lawson, Clare S. (7101626890)"
    ## 
    ## $`7101640611`
    ## [1] "Pino, Joan (7101640611)" "Pino, J. (7101640611)"  
    ## 
    ## $`7101653509`
    ## [1] "Laine, Jukka (7101653509)" "Laine, J. (7101653509)"   
    ## 
    ## $`7101684872`
    ## [1] "Laine, Anna Maria (7101684872)" "Laine, Anna M. (7101684872)"   
    ## [3] "Laine, A.M. (7101684872)"      
    ## 
    ## $`7101749590`
    ## [1] "Woods, Kerry D. (7101749590)" "Woods, Kerry (7101749590)"   
    ## 
    ## $`7101772128`
    ## [1] "Mason, Norman W. H. (7101772128)" "Mason, Norman W.H. (7101772128)" 
    ## 
    ## $`7101790742`
    ## [1] "Fernandes, Geraldo W. (7101790742)"    
    ## [2] "Wilson Fernandes, Geraldo (7101790742)"
    ## 
    ## $`7101802759`
    ## [1] "Martínez, Isabel (7101802759)" "Martinez, Isabel (7101802759)"
    ## [3] "Martínez, I. (7101802759)"    
    ## 
    ## $`7101819504`
    ## [1] "Cruz, Pablo (7101819504)" "Cruz, P. (7101819504)"   
    ## 
    ## $`7101832645`
    ## [1] "Milton, Suzanne J. (7101832645)" "Milton, S.J. (7101832645)"      
    ## 
    ## $`7101911168`
    ## [1] "Sternberg, Marcelo (7101911168)" "Marcelo, Sternberg (7101911168)"
    ## 
    ## $`7101931743`
    ## [1] "Núñez, César Omar (7101931743)" "Nuñez, Cesar (7101931743)"     
    ## [3] "Nuñez, C. (7101931743)"        
    ## 
    ## $`7101940369`
    ## [1] "Runge, Michael (7101940369)" "Runge, M. (7101940369)"     
    ## 
    ## $`7101975190`
    ## [1] "Andrade, Ana (7101975190)"    "Andrade, Ana C. (7101975190)"
    ## 
    ## $`7102003896`
    ## [1] "Gould, W.A. (7102003896)"       "Gould, William A. (7102003896)"
    ## 
    ## $`7102015211`
    ## [1] "Moody, Aaron (7102015211)" "Moody, A. (7102015211)"   
    ## 
    ## $`7102059239`
    ## [1] "Luo, Tianxiang (7102059239)"  "Luo, Tiangxiang (7102059239)"
    ## 
    ## $`7102144937`
    ## [1] "Keith, David A. (7102144937)" "Keith, D.A. (7102144937)"    
    ## 
    ## $`7102166701`
    ## [1] "Dean, W. Richard J. (7102166701)" "Dean, W.R.J. (7102166701)"       
    ## 
    ## $`7102266405`
    ## [1] "McGuire, A.D. (7102266405)"     "McGuire, A. David (7102266405)"
    ## 
    ## $`7102295012`
    ## [1] "Gobbi, Miriam E. (7102295012)" "Gobbi, M. (7102295012)"       
    ## 
    ## $`7102300261`
    ## [1] "Dupuy, Juan Manuel (7102300261)" "Dupuy, J.M. (7102300261)"       
    ## 
    ## $`7102302303`
    ## [1] "Zak, Marcelo (7102302303)"    "Zak, M.R. (7102302303)"      
    ## [3] "Zak, Marcelo R. (7102302303)"
    ## 
    ## $`7102313066`
    ## [1] "Casal, Mercedes (7102313066)" "Casal, M. (7102313066)"      
    ## 
    ## $`7102314673`
    ## [1] "Proctor, Michael C.F. (7102314673)" "Proctor, M.C.F. (7102314673)"      
    ## 
    ## $`7102335860`
    ## [1] "Dale, Mark R. T. (7102335860)" "Dale, Mark R.T. (7102335860)" 
    ## [3] "Dale, M.R.T. (7102335860)"    
    ## 
    ## $`7102335873`
    ## [1] "Dale, M. Pamela (7102335873)" "Dale, M.P. (7102335873)"     
    ## 
    ## $`7102364105`
    ## [1] "Pages, Jean-Philippe (7102364105)" "Jean-Philippe, Pagès (7102364105)"
    ## 
    ## $`7102382115`
    ## [1] "McPherson, G.R. (7102382115)"   "McPherson, Guy R. (7102382115)"
    ## 
    ## $`7102399015`
    ## [1] "Talbot, Stephen S. (7102399015)" "Talbot, S.S. (7102399015)"      
    ## 
    ## $`7102421151`
    ## [1] "Bock, Carl E. (7102421151)" "Bock, C.E. (7102421151)"   
    ## 
    ## $`7102450017`
    ## [1] "Vieira, Simone Aparecida (7102450017)"
    ## [2] "Vieira, Simone (7102450017)"          
    ## 
    ## $`7102467149`
    ## [1] "Mitchell, N.D. (7102467149)"    "Mitchell, Neil D. (7102467149)"
    ## 
    ## $`7102485867`
    ## [1] "Ashton, Peter S. (7102485867)" "Ashton, P.S. (7102485867)"    
    ## 
    ## $`7102502356`
    ## [1] "Cornelissen, Johannes Hans C. (7102502356)"
    ## [2] "Cornelissen, Johannes H. C. (7102502356)"  
    ## [3] "Cornelissen, Johannes H.C. (7102502356)"   
    ## [4] "Cornelissen, J. Hans C. (7102502356)"      
    ## [5] "Cornelissen, J.H.C. (7102502356)"          
    ## 
    ## $`7102523760`
    ## [1] "León, R.J.C. (7102523760)"        "León, Rolando J. C. (7102523760)"
    ## [3] "Leon, R.J.C. (7102523760)"       
    ## 
    ## $`7102554539`
    ## [1] "Cummins, Roger P. (7102554539)" "Cummins, R.P. (7102554539)"    
    ## 
    ## $`7102564706`
    ## [1] "McDonnell, Mark J. (7102564706)" "Mcdonnell, Mark J. (7102564706)"
    ## 
    ## $`7102578068`
    ## [1] "Laiho, Raija (7102578068)" "Laiho, R. (7102578068)"   
    ## 
    ## $`7102582548`
    ## [1] "Vázquez, Gabriela (7102582548)" "Vázquez, G. (7102582548)"      
    ## 
    ## $`7102608843`
    ## [1] "Duke, Sara (7102608843)"    "Duke, Sara E. (7102608843)"
    ## 
    ## $`7102649054`
    ## [1] "Stephens, Scott L. (7102649054)" "Stephens, S.L. (7102649054)"    
    ## 
    ## $`7102707599`
    ## [1] "Epstein, Howard E. (7102707599)" "Epstein, H. (7102707599)"       
    ## [3] "Epstein, H.E. (7102707599)"     
    ## 
    ## $`7102716490`
    ## [1] "Aguirre, Juan Luis (7102716490)" "Aguirre, J.L. (7102716490)"     
    ## 
    ## $`7102750960`
    ## [1] "Middleton, Beth (7102750960)"    "Middleton, Beth A. (7102750960)"
    ## 
    ## $`7102779791`
    ## [1] "Kent, M. (7102779791)"     "Kent, Martin (7102779791)"
    ## 
    ## $`7102792686`
    ## [1] "Obeso, José Ramón (7102792686)" "Obeso, J.R. (7102792686)"      
    ## 
    ## $`7102793004`
    ## [1] "Fraser, Lauchlan H (7102793004)"  "Fraser, Lauchlan H. (7102793004)"
    ## 
    ## $`7102798089`
    ## [1] "Hansson, Margareta (7102798089)"    "Hansson, Margareta L. (7102798089)"
    ## 
    ## $`7102841648`
    ## [1] "Midgley, Jeremy J. (7102841648)" "Midgley, J.J. (7102841648)"     
    ## [3] "Midgley, J. (7102841648)"       
    ## 
    ## $`7102861004`
    ## [1] "Wheeler, Bryan D. (7102861004)" "Wheeler, B.D. (7102861004)"    
    ## 
    ## $`7102878427`
    ## [1] "Sanderson, Roy A. (7102878427)" "Sanderson, R.A. (7102878427)"  
    ## 
    ## $`7102909972`
    ## [1] "Mathieu, Renaud (7102909972)" "Mathieu, R. (7102909972)"    
    ## 
    ## $`7102924608`
    ## [1] "Marrs, Rob H. (7102924608)"    "Marrs, Robert (7102924608)"   
    ## [3] "Marrs, Robert H. (7102924608)" "Marrs, R.H. (7102924608)"     
    ## 
    ## $`7102924682`
    ## [1] "John, E.A. (7102924682)"      "John, Elizabeth (7102924682)"
    ## 
    ## $`7102941427`
    ## [1] "Legendre, Pierre (7102941427)" "Legendre, P. (7102941427)"    
    ## 
    ## $`7103072934`
    ## [1] "Clayton, Murray K (7103072934)"  "Clayton, Murray K. (7103072934)"
    ## 
    ## $`7103101622`
    ## [1] "Casado, Miguel A. (7103101622)"    "Casado, Miguel Angel (7103101622)"
    ## [3] "Casado, M.A. (7103101622)"        
    ## 
    ## $`7103143947`
    ## [1] "Arroyo, J. (7103143947)"   "Arroyo, Juan (7103143947)"
    ## 
    ## $`7103149928`
    ## [1] "Vilà, Montserrat (7103149928)" "Vilà, M. (7103149928)"        
    ## 
    ## $`7103188195`
    ## [1] "Rodrigues, Ricardo Ribeiro (7103188195)"
    ## [2] "Rodrigues, Ricardo R. (7103188195)"     
    ## 
    ## $`7103250354`
    ## [1] "Collins, Nacelle (7103250354)"    "Collins, Nacelle B. (7103250354)"
    ## 
    ## $`7103277600`
    ## [1] "Prentice, Honor C. (7103277600)"    "Prentice, Honor Clare (7103277600)"
    ## [3] "Prentice, H.C. (7103277600)"       
    ## 
    ## $`7103295840`
    ## [1] "Malo, Juan E. (7103295840)" "Malo, J.E. (7103295840)"   
    ## 
    ## $`7103297632`
    ## [1] "Schmidt, Inger Kappel (7103297632)" "Schmidt, I.K. (7103297632)"        
    ## 
    ## $`7103330104`
    ## [1] "McCarthy, Brian C. (7103330104)" "McCarthy, B.C. (7103330104)"    
    ## 
    ## $`7103370452`
    ## [1] "Cahill, James F. (7103370452)"     "Cahill Jr., James F. (7103370452)"
    ## 
    ## $`7103398985`
    ## [1] "Elston, David A. (7103398985)" "Elston David, A. (7103398985)"
    ## [3] "Elston, D.A. (7103398985)"    
    ## 
    ## $`7103402648`
    ## [1] "Souza, Alexandre F. (7103402648)"     
    ## [2] "Souza, Alexandre Fadigas (7103402648)"
    ## 
    ## $`7201436128`
    ## [1] "Masaki, Takashi (7201436128)" "Masaki, T. (7201436128)"     
    ## 
    ## $`7201545580`
    ## [1] "Perry, George L. W. (7201545580)" "Perry, George L.W. (7201545580)" 
    ## [3] "Perry, G.L.W. (7201545580)"      
    ## 
    ## $`7201601504`
    ## [1] "Bradshaw, Richard H.W. (7201601504)" 
    ## [2] "Bradshaw, Richard H. W. (7201601504)"
    ## [3] "Bradshaw, R. (7201601504)"           
    ## 
    ## $`7201618684`
    ## [1] "Ohkubo, Tatsuhiro (7201618684)" "Ohkubo, T. (7201618684)"       
    ## 
    ## $`7201722804`
    ## [1] "Blackburn, George Alan (7201722804)" "Blackburn, George A. (7201722804)"  
    ## 
    ## $`7201724751`
    ## [1] "Ogden, J. (7201724751)"   "Ogden, John (7201724751)"
    ## 
    ## $`7201855200`
    ## [1] "Burns, Bruce R. (7201855200)" "Burns, B.R. (7201855200)"    
    ## 
    ## $`7201876184`
    ## [1] "Collins, Beverly S. (7201876184)" "Collins, Beverly (7201876184)"   
    ## [3] "Collins, B. (7201876184)"        
    ## 
    ## $`7201937673`
    ## [1] "Dixon, Philip (7201937673)"    "Dixon, Philip M. (7201937673)"
    ## 
    ## $`7201961951`
    ## [1] "Pierce, S.M. (7201961951)"       "Pierce, Shirley M. (7201961951)"
    ## 
    ## $`7201966067`
    ## [1] "Bergström, R. (7201966067)"    "Bergström, Roger (7201966067)"
    ## 
    ## $`7201976513`
    ## [1] "Costa, Flavia Regina Capellotto (7201976513)"
    ## [2] "Costa, Flavia R.C. (7201976513)"             
    ## [3] "Costa, Flávia R.C. (7201976513)"             
    ## [4] "Costa, Flávia R. C. (7201976513)"            
    ## 
    ## $`7202012033`
    ## [1] "Witte, Jan-Philip M. (7202012033)" "Witte, J.P.M. (7202012033)"       
    ## 
    ## $`7202026121`
    ## [1] "Lucas, Diane E. (7202026121)" "Lucas, D.E. (7202026121)"    
    ## 
    ## $`7202028604`
    ## [1] "Gutierrez, Alvaro G. (7202028604)" "Gutiérrez, Alvaro G. (7202028604)"
    ## 
    ## $`7202049842`
    ## [1] "Herrera, Mercedes (7202049842)" "Herrera, M. (7202049842)"      
    ## 
    ## $`7202060770`
    ## [1] "Burke, Antje (7202060770)" "Burke, A. (7202060770)"   
    ## 
    ## $`7202193901`
    ## [1] "Austin, M.P. (7202193901)"    "Austin, Mike P. (7202193901)"
    ## 
    ## $`7202220137`
    ## [1] "Brown, Valerie K. (7202220137)" "Brown, V.K. (7202220137)"      
    ## 
    ## $`7202230723`
    ## [1] "Burton, Philip J. (7202230723)" "Burton, P.J. (7202230723)"     
    ## 
    ## $`7202233535`
    ## [1] "Chu, Lee Man (7202233535)" "Chu, L.M. (7202233535)"   
    ## 
    ## $`7202267633`
    ## [1] "Hobbs, Richard (7202267633)"    "Hobbs, Richard J. (7202267633)"
    ## [3] "Hobbs, R.J. (7202267633)"      
    ## 
    ## $`7202298181`
    ## [1] "de Oliveira, Alexandre A. (7202298181)"
    ## [2] "Oliveira, Alexandre A. (7202298181)"   
    ## 
    ## $`7202315606`
    ## [1] "Sanderson, Matt A. (7202315606)" "Sanderson, M.A. (7202315606)"   
    ## 
    ## $`7202432336`
    ## [1] "Field, Christopher B. (7202432336)" "Field, C.B. (7202432336)"          
    ## 
    ## $`7202451920`
    ## [1] "Bakker, Elisabeth S. (7202451920)" "Bakker, E.S. (7202451920)"        
    ## 
    ## $`7202456825`
    ## [1] "Archer, Steve (7202456825)"     "Archer, Steven R. (7202456825)"
    ## 
    ## $`7202515459`
    ## [1] "Cruz, Alberto (7202515459)" "Cruz, A. (7202515459)"     
    ## 
    ## $`7202572736`
    ## [1] "Mark, A.F. (7202572736)"    "Mark, Alan F. (7202572736)"
    ## 
    ## $`7202583498`
    ## [1] "Willems, J.H. (7202583498)"  "Willems, Jo H. (7202583498)"
    ## 
    ## $`7202731509`
    ## [1] "Carey, Pete D. (7202731509)" "Carey, P.D. (7202731509)"   
    ## 
    ## $`7202767563`
    ## [1] "Adler, Peter B. (7202767563)" "Adler, P.B. (7202767563)"    
    ## 
    ## $`7202841143`
    ## [1] "Gardner, Wendy C (7202841143)"  "Gardner, Wendy C. (7202841143)"
    ## 
    ## $`7202856568`
    ## [1] "Jordan, Greg (7202856568)"       "Jordan, Gregory J. (7202856568)"
    ## 
    ## $`7202858995`
    ## [1] "Rosén, Ejvind (7202858995)" "Rosén, E. (7202858995)"    
    ## 
    ## $`7202890425`
    ## [1] "Franklin, Jerry F. (7202890425)" "Jerry, Franklin F. (7202890425)"
    ## 
    ## $`7202936896`
    ## [1] "Franklin, Scott (7202936896)"    "Franklin, Scott B. (7202936896)"
    ## 
    ## $`7202946573`
    ## [1] "Nilsson, Christer (7202946573)" "Nilsson, C. (7202946573)"      
    ## 
    ## $`7202970955`
    ## [1] "Bock, Jane H. (7202970955)" "Bock, J.H. (7202970955)"   
    ## 
    ## $`7203013605`
    ## [1] "Martins, Aline R. (7203013605)"      "Martins, Aline Redondo (7203013605)"
    ## 
    ## $`7203025443`
    ## [1] "An, Shuqing (7203025443)" "An, S. (7203025443)"     
    ## 
    ## $`7203026388`
    ## [1] "Waller, Donald M. (7203026388)" "Waller, D.M. (7203026388)"     
    ## 
    ## $`7203034493`
    ## [1] "Roche, Ph. (7203034493)"    "Roche, Philip (7203034493)"
    ## 
    ## $`7203072579`
    ## [1] "Bakker, Jonathan D. (7203072579)" "Bakker, J.D. (7203072579)"       
    ## 
    ## $`7203078273`
    ## [1] "Doherty, M. (7203078273)"   "Doherty, M.D. (7203078273)"
    ## 
    ## $`7203083538`
    ## [1] "Naoyuki, Nishimura (7203083538)" "Nishimura, Naoyuki (7203083538)"
    ## [3] "Nishimura, N. (7203083538)"     
    ## 
    ## $`7203088583`
    ## [1] "McDonald, Alison W. (7203088583)" "McDonald, A.W. (7203088583)"     
    ## 
    ## $`7401442201`
    ## [1] "Peters, Rob (7401442201)" "Peters, R. (7401442201)" 
    ## 
    ## $`7401442520`
    ## [1] "Goldberg, Deborah E. (7401442520)" "Deborah, Goldberg (7401442520)"   
    ## [3] "Goldberg, D.E. (7401442520)"      
    ## 
    ## $`7401472713`
    ## [1] "Morris, Craig (7401472713)"    "Morris, Craig D. (7401472713)"
    ## 
    ## $`7401604644`
    ## [1] "Duncan, Richard P. (7401604644)" "Duncan, R.P. (7401604644)"      
    ## 
    ## $`7401653234`
    ## [1] "Gutiérrez, Julio Roberto (7401653234)"
    ## [2] "Gutiérrez, Julio R. (7401653234)"     
    ## [3] "Gutiérrez, J.R. (7401653234)"         
    ## 
    ## $`7401737276`
    ## [1] "Murray, D.F. (7401737276)"     "Murray, David F. (7401737276)"
    ## 
    ## $`7401780913`
    ## [1] "Palmer, Anthony R. (7401780913)" "Palmer, A.R. (7401780913)"      
    ## 
    ## $`7401841070`
    ## [1] "McDonald Robert, I. (7401841070)" "McDonald, R.I. (7401841070)"     
    ## 
    ## $`7401858713`
    ## [1] "Turner, Benjamin Luke (7401858713)" "Turner, Benjamin L. (7401858713)"  
    ## 
    ## $`7401881921`
    ## [1] "Edwards, Peter J. (7401881921)" "Edwards, P.J. (7401881921)"    
    ## [3] "Edwards, Peter (7401881921)"   
    ## 
    ## $`7401916688`
    ## [1] "Palmer, Michael W. (7401916688)" "Palmer, M.W. (7401916688)"      
    ## [3] "Palmer, M. (7401916688)"        
    ## 
    ## $`7401971586`
    ## [1] "Weber, Ewald (7401971586)"    "Weber, Ewald F. (7401971586)"
    ## 
    ## $`7402001961`
    ## [1] "Jiménez, María Dolores (7402001961)" "Jiménez, Maria Dolores (7402001961)"
    ## 
    ## $`7402089792`
    ## [1] "Stevens, Carly (7402089792)"    "Stevens, Carly J. (7402089792)"
    ## 
    ## $`7402142346`
    ## [1] "O'Connor, T.G. (7402142346)"       "O'Connor, Timothy G. (7402142346)"
    ## 
    ## $`7402217062`
    ## [1] "Cooper, Elisabeth J. (7402217062)" "Cooper, Elisabeth (7402217062)"   
    ## 
    ## $`7402287148`
    ## [1] "Stewart, Glenn H. (7402287148)" "Stewart, G.H. (7402287148)"    
    ## 
    ## $`7402353625`
    ## [1] "Hoffmann, Maurice (7402353625)" "Hoffmann, M. (7402353625)"     
    ## 
    ## $`7402361326`
    ## [1] "Walker, Lawrence R. (7402361326)" "Walker Lawrence, R. (7402361326)"
    ## [3] "Walker, L.R. (7402361326)"       
    ## 
    ## $`7402365467`
    ## [1] "Lloyd, Jon (7402365467)" "Lloyd, J. (7402365467)" 
    ## 
    ## $`7402429250`
    ## [1] "García, Luis V. (7402429250)" "García, Luís V. (7402429250)"
    ## [3] "García, L.V. (7402429250)"    "Garciá, L.V. (7402429250)"   
    ## 
    ## $`7402454506`
    ## [1] "Nielsen, Scott E. (7402454506)" "Nielsen, S.E. (7402454506)"    
    ## 
    ## $`7402464003`
    ## [1] "Cohn, Janet S. (7402464003)" "Cohn, J.S. (7402464003)"    
    ## 
    ## $`7402475966`
    ## [1] "Chambers, Jeanne C. (7402475966)" "Chambers, J.C. (7402475966)"     
    ## 
    ## $`7402535701`
    ## [1] "Collins, Scott L. (7402535701)" "Collins, S.L. (7402535701)"    
    ## 
    ## $`7402604855`
    ## [1] "Baker, T.R. (7402604855)" "Baker, T. (7402604855)"  
    ## 
    ## $`7402633655`
    ## [1] "Larson, Douglas W. (7402633655)" "Larson, D.W. (7402633655)"      
    ## 
    ## $`7402642042`
    ## [1] "Kiyoshi, Matsui (7402642042)" "Matsui, Kiyoshi (7402642042)"
    ## 
    ## $`7402647751`
    ## [1] "Harrison, Sandy P. (7402647751)" "Harrison, S.P. (7402647751)"    
    ## 
    ## $`7402653763`
    ## [1] "Andersen, Roxane (7402653763)" "Andersen, R. (7402653763)"    
    ## 
    ## $`7402758849`
    ## [1] "Shaw, Susan C. (7402758849)" "Shaw, S. (7402758849)"      
    ## 
    ## $`7402789328`
    ## [1] "Barnes, P.W. (7402789328)"    "Barnes, Paul W. (7402789328)"
    ## 
    ## $`7402825099`
    ## [1] "Muller, Serge (7402825099)" "Muller, S. (7402825099)"   
    ## 
    ## $`7402891837`
    ## [1] "Thompson, K. (7402891837)"  "Thompson, Ken (7402891837)"
    ## 
    ## $`7403011649`
    ## [1] "Tan, Hugh Tiang Wah (7403011649)" "Tan, Hugh T. W. (7403011649)"    
    ## [3] "Tan, Hugh T.W. (7403011649)"      "Tan, H.T.W. (7403011649)"        
    ## 
    ## $`7403037130`
    ## [1] "Mills, Robert T. E. (7403037130)" "Mills, Robert (7403037130)"      
    ## 
    ## $`7403053955`
    ## [1] "Andrew Scott, W. (7403053955)" "Scott, W. Andrew (7403053955)"
    ## 
    ## $`7403067266`
    ## [1] "Peters, Debra P. (7403067266)"   "Peters, Debra P.C. (7403067266)"
    ## [3] "Peters, D.P.C. (7403067266)"    
    ## 
    ## $`7403096732`
    ## [1] "Weber, Heinrich (7403096732)"    "Weber, Heinrich E. (7403096732)"
    ## [3] "Weber, H.E. (7403096732)"       
    ## 
    ## $`7403154726`
    ## [1] "Hoffman, Michael T. (7403154726)" "Hoffman, M. Timm (7403154726)"   
    ## 
    ## $`7403211594`
    ## [1] "Lane, D.R. (7403211594)"     "Lane, Diana R. (7403211594)"
    ## 
    ## $`7403215651`
    ## [1] "Turner, Monica G. (7403215651)" "Turner, M.G. (7403215651)"     
    ## 
    ## $`7403251869`
    ## [1] "Hunter, John T. (7403251869)" "Hunter, John (7403251869)"   
    ## 
    ## $`7403349141`
    ## [1] "Hara, M. (7403349141)"        "Hara, Masatoshi (7403349141)"
    ## 
    ## $`7403364940`
    ## [1] "Ward, David (7403364940)" "Ward, D. (7403364940)"   
    ## 
    ## $`7403444596`
    ## [1] "Richardson, David M. (7403444596)" "Richardson, D.M. (7403444596)"    
    ## 
    ## $`7403661652`
    ## [1] "Ross, Michael S. (7403661652)" "Ross, M.S. (7403661652)"      
    ## 
    ## $`7403868430`
    ## [1] "Walker, Marilyn D. (7403868430)" "Walker, Marilyn A. (7403868430)"
    ## 
    ## $`7403946201`
    ## [1] "Miller, Ben P. (7403946201)" "Miller, B.P. (7403946201)"  
    ## 
    ## $`7404002040`
    ## [1] "Takeda, Yoshiaki (7404002040)" "Takeda, Y. (7404002040)"      
    ## 
    ## $`7404024078`
    ## [1] "Green, Andy J (7404024078)" "Green, A.J. (7404024078)"  
    ## 
    ## $`7404224031`
    ## [1] "Allen, Robert B. (7404224031)" "Allen, R.B. (7404224031)"     
    ## 
    ## $`7404225607`
    ## [1] "Allen, R.B. (7404225607)"     "Allen, Ralph B. (7404225607)"
    ## 
    ## $`7404299078`
    ## [1] "Wagner, Robert G. (7404299078)" "Wagner, R.G. (7404299078)"     
    ## 
    ## $`7404367462`
    ## [1] "Wagner, Helene H. (7404367462)" "Wagner Helene, H. (7404367462)"
    ## 
    ## $`7404410415`
    ## [1] "Simon, Marcelo F. (7404410415)" "Simon, Marcelo F (7404410415)" 
    ## 
    ## $`7404441387`
    ## [1] "Walker, Donald A. (7404441387)" "Walker, D. (7404441387)"       
    ## [3] "Walker, D.A. (7404441387)"     
    ## 
    ## $`7404448051`
    ## [1] "Hill, Mark O. (7404448051)" "Hill, M.O. (7404448051)"   
    ## 
    ## $`7404470890`
    ## [1] "Moore, M.M. (7404470890)"        "Moore, Margaret M. (7404470890)"
    ## 
    ## $`7404722125`
    ## [1] "Hall, Rosine B.W. (7404722125)" "Hall, R.B.W. (7404722125)"     
    ## 
    ## $`7404790164`
    ## [1] "Clark, Deborah L. (7404790164)" "Clark, D.L. (7404790164)"      
    ## 
    ## $`7406379576`
    ## [1] "Lewis, J.P. (7406379576)"       "Lewis, Juan Pablo (7406379576)"
    ## 
    ## $`7406639791`
    ## [1] "Wilson, J. Bastow (7406639791)" "Bastow Wilson, J. (7406639791)"
    ## [3] "Wilson, J.Bastow (7406639791)"  "Wilson, Bastow (7406639791)"   
    ## [5] "Wilson, J.B. (7406639791)"     
    ## 
    ## $`7801325993`
    ## [1] "Luzuriaga, Arantzazu L. (7801325993)"
    ## [2] "Luzuriaga, A.L. (7801325993)"        
    ## 
    ## $`7801335936`
    ## [1] "Solomeshch, Ayzik (7801335936)" "Solomeshch, A.I. (7801335936)" 
    ## 
    ## $`7801410564`
    ## [1] "Azcárate, Francisco M. (7801410564)" "Azcárate, F.M. (7801410564)"        
    ## 
    ## $`7801455933`
    ## [1] "Austad, Ingvild (7801455933)" "Austad, I. (7801455933)"     
    ## 
    ## $`7801511431`
    ## [1] "Bik, L.P.M. (7801511431)" "Bik, L. (7801511431)"    
    ## 
    ## $`7801522619`
    ## [1] "Rasran, Leonid (7801522619)" "Rasran, L. (7801522619)"    
    ## 
    ## $`7801534133`
    ## [1] "Costa-Tenorio, Margarita (7801534133)"
    ## [2] "Costa-Tenorio, M. (7801534133)"       
    ## 
    ## $`7801620071`
    ## [1] "Tzonev, Rossen (7801620071)"    "Tzonev, R. (7801620071)"       
    ## [3] "Tzonev, Rossen T. (7801620071)"
    ## 
    ## $`7801620471`
    ## [1] "Vásquez Martínez, Rodolfo (7801620471)"
    ## [2] "Vásquez Martínez, R. (7801620471)"     
    ## 
    ## $`7801660831`
    ## [1] "Bloesch, U. (7801660831)"  "Bloesch, Urs (7801660831)"
    ## 
    ## $`8047826900`
    ## [1] "Brooker, Rob W. (8047826900)" "Brooker, Rob (8047826900)"   
    ## 
    ## $`8093318000`
    ## [1] "Otýpková, Zdenka (8093318000)" "Otýpková, Z. (8093318000)"    
    ## 
    ## $`8138798300`
    ## [1] "Skrindo, Astrid Brekke (8138798300)" "Skrindo, A.B. (8138798300)"         
    ## [3] "Skrindo, Astrid (8138798300)"       
    ## 
    ## $`8144850900`
    ## [1] "Brewer, Simon C. (8144850900)" "Brewer, Simon (8144850900)"   
    ## 
    ## $`8202754300`
    ## [1] "Tanaka, H. (8202754300)"      "Tanaka, Hiroshi (8202754300)"
    ## 
    ## $`8205687800`
    ## [1] "Veeneklaas, Roos M. (8205687800)" "Veeneklaas, R.M. (8205687800)"   
    ## 
    ## $`8241417600`
    ## [1] "Lomba, Angela (8241417600)" "Lomba, Ângela (8241417600)"
    ## 
    ## $`8264332700`
    ## [1] "le Roux, Peter Christiaan (8264332700)"
    ## [2] "le Roux, Peter C. (8264332700)"        
    ## [3] "Le Roux, Peter C. (8264332700)"        
    ## 
    ## $`8293385100`
    ## [1] "van den Berg, Leon J. L. (8293385100)"
    ## [2] "Van Den Berg, Leon J.L. (8293385100)" 
    ## 
    ## $`8293385600`
    ## [1] "Dorland, E. (8293385600)"  "Dorland, Edu (8293385600)"
    ## 
    ## $`8302685200`
    ## [1] "Kirkman, Kevin P. (8302685200)" "Kirkman, Kevin (8302685200)"   
    ## 
    ## $`8323441600`
    ## [1] "Montes, Fernando (8323441600)" "Montes, F. (8323441600)"      
    ## 
    ## $`8325186800`
    ## [1] "Zahawi, Rakan A. (8325186800)" "Zahawi, R.A. (8325186800)"    
    ## 
    ## $`8384048000`
    ## [1] "Knevel, Irma C. (8384048000)" "Knevel, I.C. (8384048000)"   
    ## 
    ## $`8423435900`
    ## [1] "Igić, Ružica (8423435900)" "Igić, Ruzica (8423435900)"
    ## 
    ## $`8429327500`
    ## [1] "El-Sheikh, Mohamed Abd El-Rouf Mousa (8429327500)"
    ## [2] "El‐Sheikh, M.A. (8429327500)"                     
    ## 
    ## $`8504546900`
    ## [1] "Paulissen, Maurice P.C.P. (8504546900)"
    ## [2] "Paulissen, M.P.C.P. (8504546900)"      
    ## 
    ## $`8517967900`
    ## [1] "González, Mauro E (8517967900)"  "González, Mauro E. (8517967900)"
    ## 
    ## $`8521370100`
    ## [1] "Hernández-Stefanoni, José Luis (8521370100)"
    ## [2] "Hernández-Stefanoni, Jose Luis (8521370100)"
    ## [3] "Hernández-Stefanoni, J.L. (8521370100)"     
    ## [4] "Hernandez-Stefanoni, J. Luis (8521370100)"  
    ## 
    ## $`8562009700`
    ## [1] "Chen, Han Y. H. (8562009700)" "Chen, Han Y.H. (8562009700)" 
    ## 
    ## $`8565091300`
    ## [1] "Boehmer, Hans Juergen (8565091300)" "Boehmer, H.J. (8565091300)"        
    ## 
    ## $`8586472500`
    ## [1] "Larrea-Alcázar, Daniel (8586472500)"   
    ## [2] "Larrea-Alcázar, Daniel M. (8586472500)"
    ## 
    ## $`8593639400`
    ## [1] "Mi, Xiangcheng (8593639400)" "Mi, X.C. (8593639400)"      
    ## 
    ## $`8597288700`
    ## [1] "Minden, Vanessa (8597288700)" "Minden, V. (8597288700)"     
    ## 
    ## $`8603839800`
    ## [1] "Piovesan, Gianluca (8603839800)" "Piovesan, G. (8603839800)"      
    ## 
    ## $`8610672000`
    ## [1] "Vandenberghe, C. (8610672000)"       
    ## [2] "Vandenberghe, Charlotte (8610672000)"
    ## 
    ## $`8618333200`
    ## [1] "von Oheimb, Goddert (8618333200)" "Von Oheimb, G. (8618333200)"     
    ## 
    ## $`8619074400`
    ## [1] "Leoni, E. (8619074400)"   "Leoni, Elsa (8619074400)"
    ## 
    ## $`8623837700`
    ## [1] "Cianciaruso, Marcus (8623837700)"         
    ## [2] "Cianciaruso, Marcus Vinicius (8623837700)"
    ## 
    ## $`8638436200`
    ## [1] "Mcewan, Ryan (8638436200)"    "Mcewan, Ryan W. (8638436200)"
    ## [3] "McEwan, Ryan W. (8638436200)"
    ## 
    ## $`8647707100`
    ## [1] "McGranahan, Devan A. (8647707100)"   
    ## [2] "Mcgranahan, Devan Allen (8647707100)"
    ## 
    ## $`8651760800`
    ## [1] "Guerin, Greg (8651760800)"    "Guerin, Greg R. (8651760800)"
    ## 
    ## $`8672368600`
    ## [1] "Blanco, Lisandro J. (8672368600)"    
    ## [2] "Blanco, Lisandro Javier (8672368600)"
    ## 
    ## $`8715617900`
    ## [1] "Hérault, Bruno (8715617900)" "Herault, Bruno (8715617900)"
    ## 
    ## $`8774213500`
    ## [1] "Mikkola, K. (8774213500)"   "Mikkola, Kari (8774213500)"
    ## 
    ## $`8863314400`
    ## [1] "Velle, Liv Guri (8863314400)" "Velle, Liv G. (8863314400)"  
    ## 
    ## $`8866321000`
    ## [1] "Šilc, Urban (8866321000)" "Šilc, U. (8866321000)"   
    ## 
    ## $`8888897100`
    ## [1] "Song, Ming-Hua (8888897100)" "Song, Minghua (8888897100)" 
    ## 
    ## $`8902739600`
    ## [1] "Rabasa, Sonia (8902739600)"    "Rabasa, Sonia G. (8902739600)"
    ## 
    ## $`8905790900`
    ## [1] "Larson, Andrew J. (8905790900)" "Andrew, Larson J. (8905790900)"
    ## 
    ## $`8922054400`
    ## [1] "Theau, Jean-Pierre (8922054400)" "Theau, Jean Pierre (8922054400)"
    ## 
    ## $`8937254200`
    ## [1] "Chevalier, Richard (8937254200)" "Richard, Chevalier (8937254200)"
    ## 
    ## $`9337462800`
    ## [1] "Mitchell, Ruth J. (9337462800)" "Mitchell, R.J. (9337462800)"   
    ## 
    ## $`9635236500`
    ## [1] "Bonanomi, Giuliano (9635236500)" "Bonanomi, G. (9635236500)"      
    ## 
    ## $`9636980900`
    ## [1] "Buffa, Gabriella (9636980900)" "Buffa, G. (9636980900)"       
    ## 
    ## $`9735276400`
    ## [1] "de Bello, Francesco (9735276400)" "De Bello, F. (9735276400)"       
    ## [3] "De Bello, Francesco (9735276400)" "de Bello, F. (9735276400)"       
    ## [5] "Bello, Francescode (9735276400)"  "Bello, Francesco (9735276400)"   
    ## 
    ## $`9738318400`
    ## [1] "Jiménez, María N. (9738318400)" "Jiménez, M.N. (9738318400)"    
    ## 
    ## $`9842242400`
    ## [1] "Poulin, Monique (9842242400)" "Poulin, M. (9842242400)"     
    ## 
    ## $`9846127000`
    ## [1] "Soudzilovskaia, Nadejda A. (9846127000)"
    ## [2] "Soudzilovskaia, N.A. (9846127000)"

``` r
B<-tapply(allInOne$lastName,allInOne$authorId,unique)
B[sapply(B,length)>1]
```

    ## $`10238977700`
    ## [1] "Šibík" "Šibik"
    ## 
    ## $`15520350800`
    ## [1] "von Wehrden" "Von Wehrden"
    ## 
    ## $`15836906900`
    ## [1] "de Lima" "De Lima"
    ## 
    ## $`16021876800`
    ## [1] "FitzPatrick" "Fitzpatrick"
    ## 
    ## $`16231951300`
    ## [1] "Thébault"  "The´bault"
    ## 
    ## $`16239227000`
    ## [1] "Martínez-Ruiz" "Martínez Ruiz"
    ## 
    ## $`16240059900`
    ## [1] "Rogers"      "Rogers Paul"
    ## 
    ## $`16419270700`
    ## [1] "Martinez Carretero" "Martínez Carretero"
    ## 
    ## $`16634984800`
    ## [1] "Martín Bruschetti" "Bruschetti"       
    ## 
    ## $`16837221900`
    ## [1] "Miranda"         "De Dios Miranda"
    ## 
    ## $`18436550200`
    ## [1] "Ferreira" "Joice N."
    ## 
    ## $`20734084800`
    ## [1] "Golodets" "Carly"   
    ## 
    ## $`20734998800`
    ## [1] "Moreno"        "Moreno-Marcos"
    ## 
    ## $`23088206100`
    ## [1] "Essl"  "Franz"
    ## 
    ## $`23110942100`
    ## [1] "Måren" "Maren"
    ## 
    ## $`23399257600`
    ## [1] "Zelený" "Zelenỳ"
    ## 
    ## $`23567460300`
    ## [1] "Javier"  "Cabello"
    ## 
    ## $`24069765900`
    ## [1] "Blanco-Moreno" "Bianco-Moreno"
    ## 
    ## $`24170041700`
    ## [1] "Uğurlu" "Uǧurlu"
    ## 
    ## $`24463232500`
    ## [1] "Domingo" "Alcaraz"
    ## 
    ## $`24597614700`
    ## [1] "Alday"          "González-Alday"
    ## 
    ## $`24783884000`
    ## [1] "Martín De Agar" "Martín de Agar"
    ## 
    ## $`25924716500`
    ## [1] "Afif"   "Khouri"
    ## 
    ## $`26024021000`
    ## [1] "Van Zonneveld" "van Zonneveld"
    ## 
    ## $`26641127100`
    ## [1] "De Frenne" "De Frenne"
    ## 
    ## $`34872657000`
    ## [1] "Li"          "Yonghong Li"
    ## 
    ## $`34975059800`
    ## [1] "Toshihiko" "Hara"     
    ## 
    ## $`35099260800`
    ## [1] "García Medina" "Medina"       
    ## 
    ## $`35183225600`
    ## [1] "Kaärlejarvi" "Kaarlejärvi"
    ## 
    ## $`35271661700`
    ## [1] "Cushman"      "Hall Cushman"
    ## 
    ## $`35551536200`
    ## [1] "ter Braak" "Ter Braak"
    ## 
    ## $`35590023900`
    ## [1] "Kavgacı" "Kavgaci"
    ## 
    ## $`35614159300`
    ## [1] "Bartha" "Sándor"
    ## 
    ## $`35615017800`
    ## [1] "Kigel" "Jaime"
    ## 
    ## $`35617128600`
    ## [1] "Valadares de Sá Barreto Sampaio" "Sampaio"                        
    ## 
    ## $`35618981300`
    ## [1] "St. J. Hardy" "Hardy"       
    ## 
    ## $`35747186200`
    ## [1] "Valdès" "Valdes"
    ## 
    ## $`35872086600`
    ## [1] "García Rodríguez" "García-Rodríguez"
    ## 
    ## $`35965868500`
    ## [1] "De Miguel" "de Miguel"
    ## 
    ## $`36003299500`
    ## [1] "Janssen" "Janßen" 
    ## 
    ## $`36160561900`
    ## [1] "Mcdaniel" "McDaniel"
    ## 
    ## $`36451686500`
    ## [1] "van der Merwe" "Rösch"        
    ## 
    ## $`36477019000`
    ## [1] "Dvorský" "Dvorskỳ"
    ## 
    ## $`36560595500`
    ## [1] "Wana"     "Desalegn"
    ## 
    ## $`36663473900`
    ## [1] "Bodin"  "Jeanne"
    ## 
    ## $`36793793700`
    ## [1] "Janík" "Janik"
    ## 
    ## $`36886740800`
    ## [1] "Dai"      "Xiaobing"
    ## 
    ## $`36981807900`
    ## [1] "Martín Vicente" "Vicente"       
    ## 
    ## $`41561051300`
    ## [1] "de Castilho" "Castilho"   
    ## 
    ## $`54413195800`
    ## [1] "Van Meerbeek" "Van Meerbeek"
    ## 
    ## $`54901779900`
    ## [1] "Hernández Plaza" "Plaza"          
    ## 
    ## $`55150995500`
    ## [1] "Rūsiņa" "Rusina" "Rusiņa"
    ## 
    ## $`55203945500`
    ## [1] "Duprè" "Dupré"
    ## 
    ## $`55232771500`
    ## [1] "Cousins" "Sara"   
    ## 
    ## $`55235055300`
    ## [1] "Ambarlı" "Ambarli"
    ## 
    ## $`55340780500`
    ## [1] "González-M"  "González-M."
    ## 
    ## $`55405194200`
    ## [1] "Tichý" "Tichỳ"
    ## 
    ## $`55543951000`
    ## [1] "Biţă-Nicolae" "Biţa-Nicolae" "Biță-Nicolae" "Biţǎ-Nicolae"
    ## 
    ## $`55618764700`
    ## [1] "Álvarez" "Alvarez"
    ## 
    ## $`55622009600`
    ## [1] "Marcenò" "Marcenó"
    ## 
    ## $`55653683500`
    ## [1] "Jędrzejewska" "Jedrzejewska"
    ## 
    ## $`55666328500`
    ## [1] "Rico-Gray" "Rico‐Gray"
    ## 
    ## $`55666800000`
    ## [1] "Del Galdo"        "Giusso del Galdo"
    ## 
    ## $`55901093800`
    ## [1] "Pérez-Harguindeguy" "Perez-Harguindeguy"
    ## 
    ## $`55911705800`
    ## [1] "Russell-Smith" "Russell‐Smith"
    ## 
    ## $`55950878200`
    ## [1] "Díaz" "Diaz"
    ## 
    ## $`55976929800`
    ## [1] "Skálová" "Skalova"
    ## 
    ## $`55995860500`
    ## [1] "Ramírez-Marcial" "Ramírez‐Marcial"
    ## 
    ## $`56013854700`
    ## [1] "Velazquez" "Velázquez"
    ## 
    ## $`56210277900`
    ## [1] "Doležal" "Dolezal"
    ## 
    ## $`56211234300`
    ## [1] "Eckart"  "Winkler"
    ## 
    ## $`56211795000`
    ## [1] "Jon"  "Moen"
    ## 
    ## $`56277542400`
    ## [1] "van der Maarel" "Van Der Maarel" "Van der Maarel"
    ## 
    ## $`56283729900`
    ## [1] "Roelofs"     "Roelofs Jan"
    ## 
    ## $`56309353400`
    ## [1] "López-Acosta" "López"       
    ## 
    ## $`56635153700`
    ## [1] "Noy-Meir" "Noy‐Meir"
    ## 
    ## $`56641711300`
    ## [1] "Borovyk"    "Shyriaieva"
    ## 
    ## $`56780380300`
    ## [1] "Padullés Cubino" "Padullés Cubino"
    ## 
    ## $`56800855300`
    ## [1] "Vasheniak" "Vashenyak"
    ## 
    ## $`56800948900`
    ## [1] "Işık Gürsoy" "Işik Gürsoy"
    ## 
    ## $`57188960395`
    ## [1] "Świerszcz" "Swierszcz"
    ## 
    ## $`57189186147`
    ## [1] "Camarero"       "Julio Camarero"
    ## 
    ## $`57190960917`
    ## [1] "Smith-Ramesh" "Smith"       
    ## 
    ## $`57191439732`
    ## [1] "dos Santos" "Santos"     "Dos Santos"
    ## 
    ## $`57191505150`
    ## [1] "Ćuk"              "Krstivojević-Ćuk" "Krstivojević Ćuk"
    ## 
    ## $`57194514028`
    ## [1] "González-Andújar" "González-Andujar"
    ## 
    ## $`57194615386`
    ## [1] "Vítovcová" "Lencová"  
    ## 
    ## $`57195523298`
    ## [1] "Cerdà" "Cerdá"
    ## 
    ## $`57196594030`
    ## [1] "de la Cruz" "De la Cruz" "De La Cruz"
    ## 
    ## $`57203140102`
    ## [1] "Fang"    "Jingyun"
    ## 
    ## $`57209574907`
    ## [1] "León" "Leon"
    ## 
    ## $`58289749000`
    ## [1] "Perez" "Pérez"
    ## 
    ## $`6504758211`
    ## [1] "Żybura" "Zybura"
    ## 
    ## $`6505763602`
    ## [1] "Stafford Smith" "Stafford"      
    ## 
    ## $`6506121063`
    ## [1] "Fernández-Santos" "Fernández‐Santos"
    ## 
    ## $`6506200561`
    ## [1] "Kącki" "Kacki"
    ## 
    ## $`6506336392`
    ## [1] "Mironycheva-Tokareva" "Mironycheva‐Tokareva"
    ## 
    ## $`6506467052`
    ## [1] "Lososová" "Lososova"
    ## 
    ## $`6506640528`
    ## [1] "Nunes da Cunha" "Nunes Da Cunha"
    ## 
    ## $`6506751747`
    ## [1] "Vegar"      "Bakkestuen"
    ## 
    ## $`6507040777`
    ## [1] "Fernández-Alés" "Fernández Ales"
    ## 
    ## $`6507120883`
    ## [1] "Franco-Pizaña" "Franco‐Pizaña"
    ## 
    ## $`6507318524`
    ## [1] "De Cáceres" "de Cáceres" "De Caceres"
    ## 
    ## $`6507458732`
    ## [1] "Gégout" "Gegout"
    ## 
    ## $`6507482052`
    ## [1] "Rodríguez-Rojo" "Rodríguez Rojo"
    ## 
    ## $`6508101557`
    ## [1] "Dančák" "Dančak"
    ## 
    ## $`6601981016`
    ## [1] "De Vries" "de Vries"
    ## 
    ## $`6601988081`
    ## [1] "de Pablo" "De Pablo"
    ## 
    ## $`6602101854`
    ## [1] "Pillar"    "D. Pillar"
    ## 
    ## $`6602108536`
    ## [1] "Vittoz" "Pascal"
    ## 
    ## $`6602118668`
    ## [1] "Quintana-Ascencio" "Quintana‐Ascencio"
    ## 
    ## $`6602179292`
    ## [1] "Olsvig-Whittaker" "Olsvig‐Whittaker"
    ## 
    ## $`6602303405`
    ## [1] "Münzbergová" "Munzbergova"
    ## 
    ## $`6602325354`
    ## [1] "Zavala-Hurtado" "Zavala‐Hurtado"
    ## 
    ## $`6602342301`
    ## [1] "Bråthen" "Brathen"
    ## 
    ## $`6602365069`
    ## [1] "Prober"  "Suzanne"
    ## 
    ## $`6602385947`
    ## [1] "Aranibar" "Araníbar"
    ## 
    ## $`6602458082`
    ## [1] "Økland" "Okland"
    ## 
    ## $`6602567605`
    ## [1] "Lucassen"        "Lucassen Esther"
    ## 
    ## $`6602583777`
    ## [1] "Gómez Sal" "Gómez-Sal" "Gómez‐Sal"
    ## 
    ## $`6602653533`
    ## [1] "Heitkönig" "Heitkonig"
    ## 
    ## $`6602762042`
    ## [1] "Sosinski"     "Sosinski Jr."
    ## 
    ## $`6602781868`
    ## [1] "Juergens" "Jürgens" 
    ## 
    ## $`6602798224`
    ## [1] "García-Mijangos" "Garcia-Mijangos"
    ## 
    ## $`6602800357`
    ## [1] "García-Franco" "García‐Franco"
    ## 
    ## $`6602848397`
    ## [1] "Ejrnæs"  "Ejrnaes"
    ## 
    ## $`6602860889`
    ## [1] "González-Espinosa" "González‐Espinosa"
    ## 
    ## $`6602900129`
    ## [1] "Wamelink"        "Wieger Wamelink"
    ## 
    ## $`6602946168`
    ## [1] "Jutila"            "Jutila B. Erkkilä"
    ## 
    ## $`6602985156`
    ## [1] "Díaz-Barradas" "Díaz Barradas" "Diaz Barradas"
    ## 
    ## $`6603068605`
    ## [1] "Rivas-Martínez" "Rivas‐Martinez"
    ## 
    ## $`6603084357`
    ## [1] "Dirnböck" "Thomas"  
    ## 
    ## $`6603130417`
    ## [1] "Prévosto" "Prevosto"
    ## 
    ## $`6603151773`
    ## [1] "Gowing"       "Gowing David"
    ## 
    ## $`6603364869`
    ## [1] "Hely" "Hély"
    ## 
    ## $`6603368671`
    ## [1] "Van Ruijven" "van Ruijven"
    ## 
    ## $`6603440101`
    ## [1] "Kleyer"  "Michael"
    ## 
    ## $`6603547223`
    ## [1] "Erschbamer" "Brigitta"  
    ## 
    ## $`6603585122`
    ## [1] "García Novo" "García-Novo" "Garcia Novo"
    ## 
    ## $`6603648471`
    ## [1] "Moreno-Casasola" "Moreno‐Casasola"
    ## 
    ## $`6603676695`
    ## [1] "Marañón" "Maranón"
    ## 
    ## $`6603706057`
    ## [1] "Jarošik" "Jarošík"
    ## 
    ## $`6603739965`
    ## [1] "Fernández-Palacios" "Fernandez Palacios" "Fernández‐Palacios"
    ## 
    ## $`6603842703`
    ## [1] "Van Dobben" "van Dobben"
    ## 
    ## $`6603844350`
    ## [1] "Orloci" "Orlóci"
    ## 
    ## $`6603897504`
    ## [1] "García-Fayos" "García‐Fayos"
    ## 
    ## $`6603899360`
    ## [1] "Puettmann"       "Puettmann Klaus"
    ## 
    ## $`6603938145`
    ## [1] "Güsewell" "Gusewell"
    ## 
    ## $`6603950534`
    ## [1] "Sebastià"     "Sebastia"     "Maria-Teresa"
    ## 
    ## $`6603980594`
    ## [1] "van Bodegom" "Van Bodegom"
    ## 
    ## $`6701380728`
    ## [1] "Rey Benayas" "Rey-Benayas"
    ## 
    ## $`6701389712`
    ## [1] "Pärtel" "Partei"
    ## 
    ## $`6701443879`
    ## [1] "van Diggelen" "Van Diggelen"
    ## 
    ## $`6701528428`
    ## [1] "Montaña" "Montana"
    ## 
    ## $`6701659121`
    ## [1] "El-Demerdash" "El Demerdash" "El‐Demerdash"
    ## 
    ## $`6701724408`
    ## [1] "de Snoo" "De Snoo"
    ## 
    ## $`6701762058`
    ## [1] "van Rensburg" "Van Rensburg"
    ## 
    ## $`6701765625`
    ## [1] "Nascimento" "Ascimento" 
    ## 
    ## $`6701827152`
    ## [1] "Chytrý" "Chytrỳ"
    ## 
    ## $`6701852277`
    ## [1] "Jobbágy" "Jobbagy"
    ## 
    ## $`6701900493`
    ## [1] "Valiente-Banuet" "Valiente‐Banuet"
    ## 
    ## $`6701909885`
    ## [1] "Escarré" "Escarre"
    ## 
    ## $`7003519279`
    ## [1] "Heegaard" "Einar"   
    ## 
    ## $`7003572996`
    ## [1] "Nigel Critchley" "Critchley"      
    ## 
    ## $`7003603665`
    ## [1] "van der Maarel" "Van Der Maarel"
    ## 
    ## $`7003628254`
    ## [1] "Bornette"              "Bornette, G. & Amoros"
    ## 
    ## $`7003650577`
    ## [1] "Paruelo"      "Paruelo Jose"
    ## 
    ## $`7003674132`
    ## [1] "Mueller-Dombois" "Mueller‐Dombois"
    ## 
    ## $`7003828956`
    ## [1] "Mountford" "Owen"     
    ## 
    ## $`7003854080`
    ## [1] "Lepš" "Leps"
    ## 
    ## $`7003877518`
    ## [1] "van der Wal" "Van Der Wal"
    ## 
    ## $`7004063026`
    ## [1] "de Kroon" "De Kroon"
    ## 
    ## $`7004084110`
    ## [1] "Rune"   "Økland" "Okland"
    ## 
    ## $`7004442823`
    ## [1] "Zajączkowski" "Za̧jaczkowski"
    ## 
    ## $`7004517059`
    ## [1] "Gómez-Gutiérrez" "Gómez‐Gutiérrez"
    ## 
    ## $`7004529467`
    ## [1] "Sala Osvaldo" "Sala"        
    ## 
    ## $`7004998563`
    ## [1] "Meester"    "de Meester"
    ## 
    ## $`7005183850`
    ## [1] "Daniëls"      "Daniëls Fred"
    ## 
    ## $`7005211681`
    ## [1] "van Rooyen" "Van Rooyen"
    ## 
    ## $`7005300538`
    ## [1] "Garnier" "Garnie" 
    ## 
    ## $`7005315418`
    ## [1] "MacGregor" "Macgregor"
    ## 
    ## $`7005369833`
    ## [1] "de Groot" "De Groot"
    ## 
    ## $`7005815395`
    ## [1] "Delibes" "Miguel" 
    ## 
    ## $`7006037325`
    ## [1] "Turkington" "Roy"       
    ## 
    ## $`7006233160`
    ## [1] "Aragón" "Aragon"
    ## 
    ## $`7006619647`
    ## [1] "del Moral" "Del Moral"
    ## 
    ## $`7006747772`
    ## [1] "Peñuelas" "Penuelas"
    ## 
    ## $`7006832345`
    ## [1] "van Rooyen" "Van Rooyen"
    ## 
    ## $`7007033191`
    ## [1] "Chapin III" "Chapin"    
    ## 
    ## $`7101626890`
    ## [1] "Lawson Clare" "Lawson"      
    ## 
    ## $`7101790742`
    ## [1] "Fernandes"        "Wilson Fernandes"
    ## 
    ## $`7101802759`
    ## [1] "Martínez" "Martinez"
    ## 
    ## $`7101911168`
    ## [1] "Sternberg" "Marcelo"  
    ## 
    ## $`7101931743`
    ## [1] "Núñez" "Nuñez"
    ## 
    ## $`7102364105`
    ## [1] "Pages"         "Jean-Philippe"
    ## 
    ## $`7102523760`
    ## [1] "León" "Leon"
    ## 
    ## $`7102564706`
    ## [1] "McDonnell" "Mcdonnell"
    ## 
    ## $`7103370452`
    ## [1] "Cahill"     "Cahill Jr."
    ## 
    ## $`7103398985`
    ## [1] "Elston"       "Elston David"
    ## 
    ## $`7202028604`
    ## [1] "Gutierrez" "Gutiérrez"
    ## 
    ## $`7202298181`
    ## [1] "de Oliveira" "Oliveira"   
    ## 
    ## $`7202890425`
    ## [1] "Franklin" "Jerry"   
    ## 
    ## $`7203083538`
    ## [1] "Naoyuki"   "Nishimura"
    ## 
    ## $`7401442520`
    ## [1] "Goldberg" "Deborah" 
    ## 
    ## $`7401841070`
    ## [1] "McDonald Robert" "McDonald"       
    ## 
    ## $`7402361326`
    ## [1] "Walker"          "Walker Lawrence"
    ## 
    ## $`7402429250`
    ## [1] "García" "Garciá"
    ## 
    ## $`7402642042`
    ## [1] "Kiyoshi" "Matsui" 
    ## 
    ## $`7403053955`
    ## [1] "Andrew Scott" "Scott"       
    ## 
    ## $`7404367462`
    ## [1] "Wagner"        "Wagner Helene"
    ## 
    ## $`7406639791`
    ## [1] "Wilson"        "Bastow Wilson"
    ## 
    ## $`8264332700`
    ## [1] "le Roux" "Le Roux"
    ## 
    ## $`8293385100`
    ## [1] "van den Berg" "Van Den Berg"
    ## 
    ## $`8429327500`
    ## [1] "El-Sheikh" "El‐Sheikh"
    ## 
    ## $`8521370100`
    ## [1] "Hernández-Stefanoni" "Hernandez-Stefanoni"
    ## 
    ## $`8618333200`
    ## [1] "von Oheimb" "Von Oheimb"
    ## 
    ## $`8638436200`
    ## [1] "Mcewan" "McEwan"
    ## 
    ## $`8647707100`
    ## [1] "McGranahan" "Mcgranahan"
    ## 
    ## $`8715617900`
    ## [1] "Hérault" "Herault"
    ## 
    ## $`8905790900`
    ## [1] "Larson" "Andrew"
    ## 
    ## $`8937254200`
    ## [1] "Chevalier" "Richard"  
    ## 
    ## $`9735276400`
    ## [1] "de Bello" "De Bello" "Bello"
