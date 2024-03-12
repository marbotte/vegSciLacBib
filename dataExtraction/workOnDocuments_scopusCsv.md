Managing the document data from the scopus CSV file
================
Marius Bottin
2024-03-12

- [1 Reading the csv file](#1-reading-the-csv-file)
- [2 Document Ids](#2-document-ids)
  - [2.1 Creating id](#21-creating-id)
- [3 Exporting documentsID](#3-exporting-documentsid)
- [4 Preparing pdf download (to be done in bash with
  sciDownl)](#4-preparing-pdf-download-to-be-done-in-bash-with-scidownl)

# 1 Reading the csv file

``` r
fileTot<-"../../Data/SCOPUS/scopus.csv"
datab <- read.csv(fileTot, h = T, row.names = NULL,sep=",")
```

# 2 Document Ids

Column `Art..No.`:

``` r
sum(datab$Art..No.=="")
```

    ## [1] 4369

Column ‘DOI’

``` r
sum(is.na(datab$DOI))
```

    ## [1] 0

``` r
sum(datab$DOI=="")
```

    ## [1] 13

``` r
table(datab$Document.Type,useNA = "ifany")
```

    ## 
    ##          Article Conference paper        Editorial          Erratum 
    ##             4529              126               65               19 
    ##           Letter             Note           Review     Short survey 
    ##                8               57               80               13

``` r
datab[datab$DOI=="",c("DOI","Document.Type","Title")]
```

<div class="kable-table">

|      | DOI | Document.Type    | Title                                                                                                                                                                                                                              |
|------|:----|:-----------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2655 |     | Article          | The decline of metallophyte vegetation in floodplain grasslands: Implications for conservation and restoration                                                                                                                     |
| 2669 |     | Article          | Forest response to chronic hurricane disturbance in coastal New England                                                                                                                                                            |
| 3189 |     | Erratum          | Erratum: Effect of leaf litter on germination and seedling survival under two regimes of simulated precipitation in Beilschmiedia miersii (Gay) Kosterm. A Chilean endangered tree (Applied Vegetation Science (2004) 7 (253-257)) |
| 3265 |     | Erratum          | Erratum: Experimental trampling and vegetation recovery in some forest and heathland communities                                                                                                                                   |
| 3633 |     | Erratum          | Erratum: Vertical structure of wet grassland under grazed and non-grazed conditions in Tierra del Fuego. (Journal of Vegetation Science (387-388))                                                                                 |
| 3652 |     | Erratum          | Erratum: Floristic composition across a climatic gradient in a neotropical lowland forest (J. Veg. Sci. (2001) 12 (553-556))                                                                                                       |
| 3974 |     | Erratum          | Erratum: Mechanistic explanations of community structure (Journal of Vegetation Science 10:2 (145))                                                                                                                                |
| 4015 |     | Article          | Competition between Quercus petraea and Carpinus betulus in an ancient wood in England: Seedling survivorship                                                                                                                      |
| 4019 |     | Erratum          | Erratum: (Journal of Vegetation Science (1998) 9 (201-212))                                                                                                                                                                        |
| 4052 |     | Erratum          | Erratum: (Journal of Vegetation Science (1998) (201-212))                                                                                                                                                                          |
| 4401 |     | Conference paper | The International Workshop on Classification of Arctic Vegetation, held at the Institute of Arctic and Alpine Research, University of Colorado, Boulder, CO, USA, 5th-9th March, 1992                                              |
| 4539 |     | Conference paper | Symposium of the Working Group for Theoretical Vegetation Science of the International Association for Vegetation Science, in Toledo, Spain from 26-29th October, 1992                                                             |
| 4578 |     | Conference paper | IAVS Workshop on Disturbance Dynamics in Boreal Forest, Umea, Sweden, 10-14 August, 1992                                                                                                                                           |

</div>

``` r
datab$DOI[duplicated(datab$DOI)]
```

    ##  [1] "" "" "" "" "" "" "" "" "" "" "" ""

There are 13 papers with empty DOI, most of them are only errata and/or
conference papers, but there are errata and conference papers which have
their DOI. However there is no repetition of DOI in the table, except
the 13 empty DOI.

## 2.1 Creating id

It seems that the best solution would be to create an id from the first
author + year + letter

``` r
fa<-gsub(" [-A-ZÁÖÈÅŽØŁ\\.]+(,? Jr.)?I*$","",sapply(strsplit(datab$Authors, "; "),function(x)x[1]),perl = T)
# fa[order(nchar(fa),decreasing = T)]
# fa[grep(" ",fa)]
```

It appears that it is complicated to extract the last name of the first
author. Since we did the work in the code for authors, it might be
smarter to use this code!

``` r
if(file.exists("./authors.RData"))
{
  (load("./authors.RData"))
}else{
  rmarkdown::render(workOnAuthors_scopusCsv.Rmd)
  (load("./authors.RData"))
}
```

    ## [1] "tabNamesFinal" "authDoc"

``` r
firstAuthors<-authDoc[authDoc$authOrder==1,c("doc","authId")]
fa<-rep(NA,nrow(datab))
fa[firstAuthors$doc]<-tabNamesFinal[firstAuthors$authId,"lastName"]
fa <- gsub("[[:punct:][:space:]]+","_",fa)
fa[is.na(fa)]<-"Anonymous"
py<-datab$Year
authYear<-paste0(fa,py)
dupliAuthYear <- duplicated(authYear)
nbRep <- table(authYear[dupliAuthYear])+1
resReplacement<-mapply(function(nb,na)list(origin=na,replacement=paste0(na,letters[1:nb])),nbRep,names(nbRep),SIMPLIFY = F)
all(sapply(resReplacement,function(a,b)length(b[b==a$origin])==length(a$replacement),b=authYear))
```

    ## [1] TRUE

``` r
docId<-authYear
for(i in 1:length(resReplacement))
{
  docId[docId == resReplacement[[i]]$origin] <- resReplacement[[i]]$replacement
}
docId[grep("[a-z]$",docId)]
```

    ##   [1] "Loidi2023a"               "Dengler2023a"            
    ##   [3] "Novák2023a"               "Novák2023b"              
    ##   [5] "Dengler2023b"             "Li2022a"                 
    ##   [7] "Loidi2023b"               "Dengler2023c"            
    ##   [9] "Dengler2023d"             "Mazalla2022a"            
    ##  [11] "Shi2022a"                 "Dengler2023e"            
    ##  [13] "Shi2022b"                 "Loidi2022a"              
    ##  [15] "Li2022b"                  "Świerkosz2022a"          
    ##  [17] "Loidi2022b"               "Świerkosz2022b"          
    ##  [19] "Liu2022a"                 "Liu2022b"                
    ##  [21] "Mazalla2022b"             "Silva2021a"              
    ##  [23] "Bahalkeh2021a"            "Zhang2021a"              
    ##  [25] "Luo2021a"                 "Dembicz2021a"            
    ##  [27] "Bonanomi2021a"            "Hunter2021a"             
    ##  [29] "Dembicz2021b"             "Luo2021b"                
    ##  [31] "Silva2021b"               "Willner2021a"            
    ##  [33] "Cupertino_Eisenlohr2021a" "Li2021a"                 
    ##  [35] "Luo2021c"                 "Willner2021b"            
    ##  [37] "Ónodi2021a"               "Bahalkeh2021b"           
    ##  [39] "Hunter2021b"              "Willner2021c"            
    ##  [41] "Zhang2021b"               "Silva2021c"              
    ##  [43] "Zhang2021c"               "Chaves2021a"             
    ##  [45] "Bonanomi2021b"            "Dembicz2021c"            
    ##  [47] "Li2021b"                  "Cupertino_Eisenlohr2021b"
    ##  [49] "Chaves2021b"              "Ónodi2021b"              
    ##  [51] "Dembicz2021d"             "Filazzola2020a"          
    ##  [53] "Chytrý2020a"              "Filazzola2020b"          
    ##  [55] "Silva2020a"               "Morgan2020a"             
    ##  [57] "Liu2020a"                 "Liu2020b"                
    ##  [59] "Biurrun2020a"             "Hunter2020a"             
    ##  [61] "Biurrun2020b"             "Silva2020b"              
    ##  [63] "Morgan2020b"              "Chytrý2020b"             
    ##  [65] "Hunter2020b"              "Brown2019a"              
    ##  [67] "Wang2019a"                "Liu2019a"                
    ##  [69] "Wang2019b"                "Tichý2019a"              
    ##  [71] "Wang2019c"                "Brown2019b"              
    ##  [73] "Tichý2019b"               "Song2018a"               
    ##  [75] "Song2018b"                "Liu2019b"                
    ##  [77] "Wang2018a"                "Wang2018b"               
    ##  [79] "Willner2017a"             "Wang2017a"               
    ##  [81] "Sun2017a"                 "Wang2017b"               
    ##  [83] "Jaroszewicz2017a"         "Kapfer2017a"             
    ##  [85] "Wang2017c"                "Wood2017a"               
    ##  [87] "Kapfer2017b"              "Sun2017b"                
    ##  [89] "Wang2017d"                "Willner2017b"            
    ##  [91] "Jaroszewicz2017b"         "Wood2017b"               
    ##  [93] "Lososová2016a"            "Wagner2016a"             
    ##  [95] "Lososová2016b"            "Wagner2016b"             
    ##  [97] "Liu2015a"                 "Ricotta2015a"            
    ##  [99] "Ricotta2015b"             "Liu2015b"                
    ## [101] "Jiménez_Alfaro2014a"      "Liu2015c"                
    ## [103] "Liu2015d"                 "Wilson2014a"             
    ## [105] "Céspedes2014a"            "Milberg2014a"            
    ## [107] "Le_Stradic2014a"          "Milberg2014b"            
    ## [109] "Chytrý2014a"              "Pärtel2014a"             
    ## [111] "Jiménez_Alfaro2014b"      "Wilson2014b"             
    ## [113] "Chytrý2014b"              "Wilson2014c"             
    ## [115] "Jiménez_Alfaro2014c"      "Pärtel2014b"             
    ## [117] "Céspedes2014b"            "Jiménez_Alfaro2014d"     
    ## [119] "Le_Stradic2014b"          "de_Bello2013a"           
    ## [121] "Chytrý2014c"              "Mason2013a"              
    ## [123] "Gibson2013a"              "de_Bello2013b"           
    ## [125] "Gibson2013b"              "Mason2013b"              
    ## [127] "Sparrius2013a"            "Mason2013c"              
    ## [129] "Pellissier2013a"          "Wilson2013a"             
    ## [131] "Li2012a"                  "Sparrius2013b"           
    ## [133] "Wilson2013b"              "Mason2013d"              
    ## [135] "Pellissier2013b"          "Liu2012a"                
    ## [137] "Liu2012b"                 "Wilson2012a"             
    ## [139] "Scott2012a"               "Li2012b"                 
    ## [141] "Ross2012a"                "Wilson2012b"             
    ## [143] "Soliveres2012a"           "Ross2012b"               
    ## [145] "Alday2011a"               "Kulmala2011a"            
    ## [147] "Scott2012b"               "Clark2012a"              
    ## [149] "Clark2012b"               "Chytrý2011a"             
    ## [151] "Wiser2011a"               "Wilson2012c"             
    ## [153] "Wilson2012d"              "Soliveres2012b"          
    ## [155] "Dengler2011a"             "Coops2011a"              
    ## [157] "Cochard2011a"             "Wilson2011a"             
    ## [159] "Coops2011b"               "Cochard2011b"            
    ## [161] "Chytrý2011b"              "Dengler2011b"            
    ## [163] "Wang2011a"                "Kulmala2011b"            
    ## [165] "Wilson2011b"              "Alday2011b"              
    ## [167] "Wang2011b"                "Chiarucci2010a"          
    ## [169] "Sonnier2010a"             "Yang2010a"               
    ## [171] "Matsumura2010a"           "Wiser2011b"              
    ## [173] "Wilson2011c"              "Yang2010b"               
    ## [175] "Matsumura2010b"           "Tichý2010a"              
    ## [177] "Tichý2010b"               "Chiarucci2010b"          
    ## [179] "Sonnier2010b"             "Li2009a"                 
    ## [181] "Yang2009a"                "Li2009b"                 
    ## [183] "Baeten2009a"              "Yang2009b"               
    ## [185] "Baeten2009b"              "Aavik2008a"              
    ## [187] "Aavik2008b"               "Sebastià2008a"           
    ## [189] "Li2008a"                  "Moran2008a"              
    ## [191] "Moran2008b"               "Jones2007a"              
    ## [193] "Wilson2008a"              "Wilson2008b"             
    ## [195] "Li2008b"                  "Sebastià2008b"           
    ## [197] "Bossuyt2007a"             "Endels2007a"             
    ## [199] "Chiarucci2007a"           "Endels2007b"             
    ## [201] "Vilà2007a"                "Chiarucci2007b"          
    ## [203] "Jones2007b"               "Vilà2007b"               
    ## [205] "Bossuyt2007b"             "Gilliam2006a"            
    ## [207] "Middleton2006a"           "Holdo2006a"              
    ## [209] "Holdo2006b"               "Middleton2006b"          
    ## [211] "Wilson2005a"              "Fynn2005a"               
    ## [213] "Bellingham2005a"          "Will_Wolf2006a"          
    ## [215] "Will_Wolf2006b"           "Gilliam2006b"            
    ## [217] "Wilson2004a"              "Bellingham2005b"         
    ## [219] "Roovers2004a"             "Matsui2004a"             
    ## [221] "Wilson2005b"              "Bossuyt2004a"            
    ## [223] "Fynn2005b"                "Guo2004a"                
    ## [225] "Guo2004b"                 "Wilson2004b"             
    ## [227] "Roovers2004b"             "Matsui2004b"             
    ## [229] "Thompson2004a"            "García2003a"             
    ## [231] "Matus2003a"               "Bossuyt2004b"            
    ## [233] "Wilson2003a"              "Thompson2004b"           
    ## [235] "Pausas2003a"              "Pausas2003b"             
    ## [237] "Walker2003a"              "Garcillán2003a"          
    ## [239] "Wilson2003b"              "Matus2003b"              
    ## [241] "García2003b"              "Walker2003b"             
    ## [243] "Garcillán2003b"           "Pausas2003c"             
    ## [245] "Pakeman2002a"             "Bakker2002a"             
    ## [247] "Bakker2002b"              "Wilson2001a"             
    ## [249] "Díaz_Barradas2001a"       "Pakeman2002b"            
    ## [251] "Wilson2001b"              "Chambers2001a"           
    ## [253] "Bergmeier2001a"           "Xiong2001a"              
    ## [255] "Ricotta2000a"             "Bergmeier2001b"          
    ## [257] "Prach2001a"               "Chambers2001b"           
    ## [259] "Díaz_Barradas2001b"       "Posse2000a"              
    ## [261] "Chytrý2001a"              "Xiong2001b"              
    ## [263] "Prach2001b"               "Chytrý2001b"             
    ## [265] "Ricotta2000b"             "Posse2000b"              
    ## [267] "Ejrnæs2000a"              "Ejrnæs2000b"             
    ## [269] "Bruelheide2000a"          "Bruelheide2000b"         
    ## [271] "Kadmon1999a"              "Lepš1999a"               
    ## [273] "Qian1999a"                "Díaz_Barradas1999a"      
    ## [275] "Kleyer1999a"              "Qian1999b"               
    ## [277] "McIntyre1999a"            "Güsewell1999a"           
    ## [279] "Kleyer1999b"              "Lepš1999b"               
    ## [281] "Pillar1999a"              "Güsewell1999b"           
    ## [283] "Kadmon1999b"              "Kuuluvainen1998a"        
    ## [285] "Anonymous1998a"           "McIntyre1999b"           
    ## [287] "Pillar1999b"              "Morgan1998a"             
    ## [289] "Bergeron1998a"            "Anonymous1998b"          
    ## [291] "Flannigan1998a"           "Morgan1998b"             
    ## [293] "Peco1998a"                "Díaz_Barradas1999b"      
    ## [295] "Bergeron1998b"            "Kuuluvainen1998b"        
    ## [297] "Morgan1998c"              "Flannigan1998b"          
    ## [299] "Pausas1997a"              "Laterra1997a"            
    ## [301] "Lawesson1997a"            "Lawesson1997b"           
    ## [303] "Laterra1997b"             "Pausas1997b"             
    ## [305] "Tsuyuzaki1997a"           "Oksanen1997a"            
    ## [307] "Tsuyuzaki1997b"           "Podani1997a"             
    ## [309] "Oksanen1997b"             "Peco1998b"               
    ## [311] "Oksanen1997c"             "Chytrý1998a"             
    ## [313] "Chytrý1998b"              "Podani1997b"             
    ## [315] "Rune1996a"                "Herben1996a"             
    ## [317] "Bakker1996a"              "Carleton1996a"           
    ## [319] "Bakker1996b"              "Herben1996b"             
    ## [321] "Carleton1996b"            "Steffen1996a"            
    ## [323] "Steffen1996b"             "Rune1996b"               
    ## [325] "Hietz1995a"               "Dale1995a"               
    ## [327] "Wilson1995a"              "Wilson1995b"             
    ## [329] "van_der_Maarel1995a"      "Kitayama1995a"           
    ## [331] "Kitayama1995b"            "Hietz1995b"              
    ## [333] "van_der_Maarel1995b"      "Wilson1995c"             
    ## [335] "Wilson1995d"              "Anonymous1994a"          
    ## [337] "Pineda1994a"              "Walker1994a"             
    ## [339] "Walker1994b"              "Anonymous1994b"          
    ## [341] "Austin1994a"              "Walsh1994a"              
    ## [343] "Austin1994b"              "Korning1994a"            
    ## [345] "Rune1994a"                "Walsh1994b"              
    ## [347] "Wilson1994a"              "Rune1994b"               
    ## [349] "Korning1994b"             "van_der_Maarel1995c"     
    ## [351] "Dale1995b"                "Wilson1994b"             
    ## [353] "Walker1994c"              "Wilson1994c"             
    ## [355] "Anonymous1994c"           "Hofgaard1993a"           
    ## [357] "Palmer1994a"              "Herben1993a"             
    ## [359] "Agnew1993a"               "Hofgaard1993b"           
    ## [361] "Engelmark1993a"           "van_der_Maarel1993a"     
    ## [363] "Palmer1994b"              "Pineda1994b"             
    ## [365] "Engelmark1993b"           "Vetaas1992a"             
    ## [367] "Salonen1992a"             "Herben1993b"             
    ## [369] "Agnew1993b"               "Anonymous1992a"          
    ## [371] "Noguchi1992a"             "Sundriyal1992a"          
    ## [373] "Anonymous1992b"           "Vetaas1992b"             
    ## [375] "van_der_Maarel1993b"      "Noguchi1992b"            
    ## [377] "Sundriyal1992b"           "Wilson1991a"             
    ## [379] "van_der_Maarel1991a"      "van_der_Maarel1991b"     
    ## [381] "Valiente_Banuet1991a"     "van_der_Maarel1991c"     
    ## [383] "Sykes1991a"               "Wilson1991b"             
    ## [385] "Anonymous1992c"           "Wilson1991c"             
    ## [387] "Salonen1992b"             "Anonymous1992d"          
    ## [389] "Dale1991a"                "Dale1991b"               
    ## [391] "van_der_Maarel1990a"      "Manders1990a"            
    ## [393] "Valiente_Banuet1991b"     "van_der_Eddy1990a"       
    ## [395] "Oksanen1990a"             "Manders1990b"            
    ## [397] "van_der_Eddy1990b"        "Sykes1991b"              
    ## [399] "Halpern1990a"             "Montaña1990a"            
    ## [401] "van_der_Maarel1990b"      "Anonymous1990a"          
    ## [403] "Halpern1990b"             "van_der_Eddy1990c"       
    ## [405] "Montaña1990b"             "Wilson1990a"             
    ## [407] "Oksanen1990b"             "Wilson1990b"             
    ## [409] "Anonymous1990b"

# 3 Exporting documentsID

``` r
save(docId,file="docId.RData")
```

# 4 Preparing pdf download (to be done in bash with sciDownl)

``` r
df_id_doi<-na.omit(data.frame(docId,DOI=datab$DOI))
if(!file.exists("../../vegSciLacBib_export/PDF")){dir.create("../../vegSciLacBib_export/PDF")}
file.remove("downloadPdf.sh")
```

    ## [1] TRUE

``` r
writeLines(paste0("scidownl download --doi \"",df_id_doi$DOI,"\" --out ../../vegSciLacBib_export/PDF/",df_id_doi$docId,".pdf"), con="downloadPdf.sh")
```
