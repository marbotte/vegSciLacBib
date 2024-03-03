Managing the affiliation data from the scopus CSV file
================
Marius Bottin
2024-03-03

- [1 Reading the csv file](#1-reading-the-csv-file)
- [2 The affiliation column](#2-the-affiliation-column)
  - [2.1 Parenthesis problem](#21-parenthesis-problem)
- [3 Cities](#3-cities)

# 1 Reading the csv file

``` r
fileTot<-"../../Data/SCOPUS/scopus.csv"
datab <- read.csv(fileTot, h = T, row.names = NULL,sep=",")
```

# 2 The affiliation column

The column `Authors.with.affiliations` allows to link authors and
institutions

``` r
head(datab$Authors.with.affiliations)
```

    ## [1] "Buyens I.P.R., Department of Plant and Soil Sciences, University of Pretoria, Hatfield, South Africa; Raath-Krüger M.J., Department of Plant and Soil Sciences, University of Pretoria, Hatfield, South Africa; Haddad W.A., Department of Zoology, University of Johannesburg, Johannesburg, South Africa; le Roux P.C., Department of Plant and Soil Sciences, University of Pretoria, Hatfield, South Africa"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    ## [2] "Restrepo-Carvajal I.C., Escola Nacional de Botânica Tropical – Jardim Botânico do Rio de Janeiro, RJ, Rio de Janeiro, Brazil; Manhães A.P., Universidade Federal do Rio de Janeiro – UFRJ, RJ, Rio de Janeiro, Brazil; Pantaleão L.C., Departamento de Ciências Ambientais, Universidade Federal Rural do Rio de Janeiro – UFRRJ, RJ, Seropédica, Brazil; de Moraes L.F.D., Embrapa Agrobiologia, RJ, Seropédica, Brazil; Mantuano D.G., Universidade Federal do Rio de Janeiro – UFRJ, RJ, Rio de Janeiro, Brazil; Sansevero J.B.B., Departamento de Ciências Ambientais, Universidade Federal Rural do Rio de Janeiro – UFRRJ, RJ, Seropédica, Brazil"                                                                                                                                                                                                                                                                                                                                                                                            
    ## [3] "Thomsen A.M., Centre for Ecosystem Science, School of Biological, Earth and Environmental Sciences, University of New South Wales, UNSW, Sydney, NSW, Australia; Davies R.J.P., Centre for Ecosystem Science, School of Biological, Earth and Environmental Sciences, University of New South Wales, UNSW, Sydney, NSW, Australia; Ooi M.K.J., Centre for Ecosystem Science, School of Biological, Earth and Environmental Sciences, University of New South Wales, UNSW, Sydney, NSW, Australia"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    ## [4] "Wang H., International Joint Research Laboratory for Global Change Ecology, Laboratory of Biodiversity Conservation and Ecological Restoration, School of Life Sciences, Henan University, Kaifeng, China; He Y., International Joint Research Laboratory for Global Change Ecology, Laboratory of Biodiversity Conservation and Ecological Restoration, School of Life Sciences, Henan University, Kaifeng, China; Qiao D., International Joint Research Laboratory for Global Change Ecology, Laboratory of Biodiversity Conservation and Ecological Restoration, School of Life Sciences, Henan University, Kaifeng, China; Xiao R., International Joint Research Laboratory for Global Change Ecology, Laboratory of Biodiversity Conservation and Ecological Restoration, School of Life Sciences, Henan University, Kaifeng, China; Yang Z., International Joint Research Laboratory for Global Change Ecology, Laboratory of Biodiversity Conservation and Ecological Restoration, School of Life Sciences, Henan University, Kaifeng, China"
    ## [5] "Huang C., Key Laboratory of Forest Ecology and Environment of National Forestry and Grassland Administration, Institute of Forest Ecology, Environment and Nature Conservation, Chinese Academy of Forestry, Beijing, 100091, China; Xu Y., Key Laboratory of Forest Ecology and Environment of National Forestry and Grassland Administration, Institute of Forest Ecology, Environment and Nature Conservation, Chinese Academy of Forestry, Beijing, 100091, China, Co-Innovation Center for Sustainable Forestry in Southern China, Nanjing Forestry University, Nanjing, 210037, China; Zang R., Key Laboratory of Forest Ecology and Environment of National Forestry and Grassland Administration, Institute of Forest Ecology, Environment and Nature Conservation, Chinese Academy of Forestry, Beijing, 100091, China, Co-Innovation Center for Sustainable Forestry in Southern China, Nanjing Forestry University, Nanjing, 210037, China"                                                                                              
    ## [6] "Marquart A., Unit for Environmental Sciences and Management, North-West University, Potchefstroom, South Africa; van Coller H., Unit for Environmental Sciences and Management, North-West University, Potchefstroom, South Africa; van Staden N., Unit for Environmental Sciences and Management, North-West University, Potchefstroom, South Africa; Kellner K., Unit for Environmental Sciences and Management, North-West University, Potchefstroom, South Africa"

``` r
sepAffil <- lapply(strsplit(datab$Authors.with.affiliations,"; "),strsplit,", ")
```

There are various problems with the separating fields operation here:

- when there are comma in an expression (e.g faculty of plant, animal
  and ecology)…
- when there are opening parenthesis

## 2.1 Parenthesis problem

Concerning the parentheses:

Let’s try and find the closing parentheses which are not associated with
opening parenthesis:

``` r
pbI<-integer()
pbJ<-integer()
pbK<-integer()
for(i in 1:length(sepAffil))
{
  if(length(sepAffil[[i]])==0){next}
  for(j in 1:length(sepAffil[[i]]))
  {
    A<-grep("^[^(]+\\)",sepAffil[[i]][[j]])
    pbI<-c(pbI,rep(i,length(A)))
    pbJ<-c(pbJ,rep(j,length(A)))
    pbK<-c(pbK,A)
  }
}
```

Showing the problems

``` r
for(i in 1:length(pbI))
{
  print(sepAffil[[pbI[i]]][[pbJ[i]]])
}
```

    ## [1] "Sánchez-Martín R."                                    
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ## [1] "Verdú M."                                             
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ## [1] "Montesinos-Navarro A."                                
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ##  [1] "Renault D."                       "Univ Rennes"                     
    ##  [3] "CNRS"                             "ECOBIO [(Ecosystèmes"            
    ##  [5] "biodiversité"                     "évolution)]"                     
    ##  [7] "Rennes"                           "France"                          
    ##  [9] "Institut Universitaire de France" "Paris cedex 05"                  
    ## [11] "France"                          
    ## [1] "Gonzalez S."                       "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## [1] "Salazar C.V."                      "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## [1] "Ghermandi L."                      "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## [1] "Jiménez-Alfaro B."                           
    ## [2] "Biodiversity Research Institute (Univ.Oviedo"
    ## [3] "CSIC"                                        
    ## [4] "Princ. Asturias)"                            
    ## [5] "University of Oviedo"                        
    ## [6] "Mieres"                                      
    ## [7] "Spain"                                       
    ## [1] "Chabrerie O."                                          
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## [1] "Decocq G."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## [1] "Bazzichetto M."        "CNRS"                  "EcoBio (Ecosystèmes"  
    ## [4] "Biodiversité"          "Évolution) - UMR 6553" "Université de Rennes" 
    ## [7] "Rennes"                "France"               
    ## [1] "Joly R."               "CNRS"                  "EcoBio (Ecosystèmes"  
    ## [4] "Biodiversité"          "Évolution) - UMR 6553" "Université de Rennes" 
    ## [7] "Rennes"                "France"               
    ##  [1] "Renault D."                       "CNRS"                            
    ##  [3] "EcoBio (Ecosystèmes"              "Biodiversité"                    
    ##  [5] "Évolution) - UMR 6553"            "Université de Rennes"            
    ##  [7] "Rennes"                           "France"                          
    ##  [9] "Institut Universitaire de France" "Paris Cedex 05"                  
    ## [11] "France"                          
    ##  [1] "Schmitt S."                      "French Institute of Pondicherry"
    ##  [3] "UMIFRE 21/USR 3330 CNRS-MAEE"    "Pondicherry"                    
    ##  [5] "India"                           "CNRS"                           
    ##  [7] "UMR EcoFoG (Agroparistech"       "Cirad"                          
    ##  [9] "INRAE"                           "Université des Antilles"        
    ## [11] "Université de la Guyane)"        "Kourou"                         
    ## [13] "French Guiana"                  
    ##  [1] "Dengler J."                                                                  
    ##  [2] "Vegetation Ecology Group"                                                    
    ##  [3] "Institute of Natural Resource Sciences (IUNR)"                               
    ##  [4] "Zurich University of Applied Sciences (ZHAW)"                                
    ##  [5] "Wädenswil"                                                                   
    ##  [6] "Switzerland"                                                                 
    ##  [7] "Plant Ecology"                                                               
    ##  [8] "Bayreuth Center of Ecology and Environmental Research (BayCEER)"             
    ##  [9] "University of Bayreuth"                                                      
    ## [10] "Bayreuth"                                                                    
    ## [11] "Germany"                                                                     
    ## [12] "German Centre for Integrative Biodiversity Research iDiv) Halle-Jena-Leipzig"
    ## [13] "Leipzig"                                                                     
    ## [14] "Germany"                                                                     
    ##  [1] "Matthews T.J."                                                                
    ##  [2] "CE3C – Centre for Ecology"                                                    
    ##  [3] "Evolution and Environmental Changes/Azorean Biodiversity Group"               
    ##  [4] "Univ. dos Açores"                                                             
    ##  [5] "Açores"                                                                       
    ##  [6] "Portugal"                                                                     
    ##  [7] "GEES (School of Geography"                                                    
    ##  [8] "Earth and Environmental Sciences) and Birmingham Institute of Forest Research"
    ##  [9] "University of Birmingham"                                                     
    ## [10] "Birmingham"                                                                   
    ## [11] "United Kingdom"                                                               
    ## [1] "Jiménez-Alfaro B."                   "Research Unit of Biodiversity (CSIC"
    ## [3] "UO"                                  "PA)"                                
    ## [5] "Oviedo University"                   "Mieres"                             
    ## [7] "Spain"                              
    ##  [1] "Matthews T.J."                                     
    ##  [2] "GEES (School of Geography"                         
    ##  [3] "Earth and Environmental Sciences)"                 
    ##  [4] "Birmingham Institute of Forest Research"           
    ##  [5] "University of Birmingham"                          
    ##  [6] "United Kingdom"                                    
    ##  [7] "CE3C – Centre for Ecology"                         
    ##  [8] "Evolution and Environmental Changes"               
    ##  [9] "Azorean Biodiversity Group"                        
    ## [10] "Universidade dos Açores"                           
    ## [11] "Depto de Ciências Agráriase Engenharia do Ambiente"
    ## [12] "Angra do Heroísmo"                                 
    ## [13] "Açores"                                            
    ## [14] "Portugal"                                          
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardy"                     
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ##  [1] "Matthews T.J."                                                                                                                                   
    ##  [2] "GEES (School of Geography"                                                                                                                       
    ##  [3] "Earth and Environmental Sciences)"                                                                                                               
    ##  [4] "Birmingham Institute of Forest Research"                                                                                                         
    ##  [5] "University of Birmingham"                                                                                                                        
    ##  [6] "Birmingham"                                                                                                                                      
    ##  [7] "United Kingdom"                                                                                                                                  
    ##  [8] "CE3C – Centre for Ecology"                                                                                                                       
    ##  [9] "Evolution and Environmental Changes/Azorean Biodiversity Group and Universidade. dos Açores – Depto de Ciências Agráriase Engenharia do Ambiente"
    ## [10] "Angra do Heroísmo"                                                                                                                               
    ## [11] "Portugal"                                                                                                                                        
    ## [1] "Lenoir J."                                                    
    ## [2] "UR \"Ecologie et Dynamique des Systèmes Anthropisés\" (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                               
    ## [4] "Université de Picardie Jules Verne"                           
    ## [5] "Amiens"                                                       
    ## [6] "France"                                                       
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## [1] "Silva V."                                             
    ## [2] "Centre for Applied Ecology “Prof. Baeta Neves” (CEABN"
    ## [3] "InBIO)"                                               
    ## [4] "School of Agriculture"                                
    ## [5] "University of Lisbon"                                 
    ## [6] "Lisbon"                                               
    ## [7] "Portugal"                                             
    ## [1] "Lenoir J."                                                    
    ## [2] "UR « Ecologie et Dynamique des Systèmes Anthropisés » (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                               
    ## [4] "Université de Picardie Jules Verne"                           
    ## [5] "Amiens"                                                       
    ## [6] "France"                                                       
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Spicher F."                                                                 
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Gallet-Moron E."                                                            
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Buridant J."                                                                
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Closset-Kopp D."                                                            
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Closset-Kopp D."                                             
    ## [2] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                         
    ## [4] "Université de Picardie Jules Verne"                          
    ## [5] "Amiens Cedex"                                                
    ## [6] "France"                                                      
    ## [1] "Decocq G."                                                   
    ## [2] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                         
    ## [4] "Université de Picardie Jules Verne"                          
    ## [5] "Amiens Cedex"                                                
    ## [6] "France"                                                      
    ## [1] "Bazzichetto M."        "Université de Rennes"  "CNRS"                 
    ## [4] "EcoBio (Ecosystèmes"   "biodiversité"          "évolution) – UMR 6553"
    ## [7] "Rennes"                "France"               
    ## [1] "Ecology Unit) and Research Unit of Biodiversity (UO-CSIC-PA)"
    ## [2] "University of Oviedo"                                        
    ## [3] "Oviedo"                                                      
    ## [4] "Spain"                                                       
    ## [1] "Decocq G."                                                  
    ## [2] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## [1] "Lenoir J."                                                  
    ## [2] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## [1] "Jiménez-Alfaro B."               "Institute of Biodiversity (IMIB"
    ## [3] "CISC-UO-PA)"                     "University of Oviedo"           
    ## [5] "Oviedo"                          "Spain"                          
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Spicher F."                                                                 
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## [1] "Franzese J."                               
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## [1] "Raffaele E."                               
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## [1] "Blackhall M."                              
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## [1] "Lenoir J."                                              
    ## [2] "Ecologie et Dynamiques des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                    
    ## [4] "Université de Picardie Jules Verne"                     
    ## [5] "Amiens"                                                 
    ## [6] "France"                                                 
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ##  [1] "Koffi K.F."                                            
    ##  [2] "UFR des Sciences de la Nature"                         
    ##  [3] "Laboratoire d'Ecologie et Développement Durable (LEDD)"
    ##  [4] "Université Nangui Abrogoua"                            
    ##  [5] "Abidjan"                                               
    ##  [6] "Cote d'Ivoire"                                         
    ##  [7] "UMR 7618 IEES-Paris (IRD"                              
    ##  [8] "CNRS"                                                  
    ##  [9] "Université Paris Diderot"                              
    ## [10] "UPEC"                                                  
    ## [11] "INRA)"                                                 
    ## [12] "Sorbonne Université"                                   
    ## [13] "Paris"                                                 
    ## [14] "France"                                                
    ##  [1] "Lata J.-C."                               
    ##  [2] "UMR 7618 IEES-Paris (IRD"                 
    ##  [3] "CNRS"                                     
    ##  [4] "Université Paris Diderot"                 
    ##  [5] "UPEC"                                     
    ##  [6] "INRA)"                                    
    ##  [7] "Sorbonne Université"                      
    ##  [8] "Paris"                                    
    ##  [9] "France"                                   
    ## [10] "Department of Geoecology and Geochemistry"
    ## [11] "Institute of Natural Resources"           
    ## [12] "Tomsk Polytechnic University"             
    ## [13] "Tomsk"                                    
    ## [14] "Russian Federation"                       
    ## [1] "Srikanthasamy T."         "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ## [1] "Konaré S."                "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ## [1] "Barot S."                 "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ##  [1] "Mateo R.G."                                                         
    ##  [2] "MONTES (ETSI Montes"                                                
    ##  [3] "Forestal y del Medio Natural)"                                      
    ##  [4] "Universidad Politécnica de Madrid"                                  
    ##  [5] "Madrid"                                                             
    ##  [6] "Spain"                                                              
    ##  [7] "Departamento de Biología (Botánica)"                                
    ##  [8] "Universidad Autónoma de Madrid"                                     
    ##  [9] "Madrid"                                                             
    ## [10] "Spain"                                                              
    ## [11] "Centro de Investigación en Biodiversidad y Cambio Global (CIBC-UAM)"
    ## [12] "Universidad Autónoma de Madrid"                                     
    ## [13] "Madrid"                                                             
    ## [14] "Spain"                                                              
    ## [1] "Gastón A."                         "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ## [1] "Aroca-Fernández M.J."              "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ##  [1] "Saura S."                          "MONTES (ETSI Montes"              
    ##  [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ##  [5] "Madrid"                            "Spain"                            
    ##  [7] "European Commission"               "Joint Research Centre (JRC)"      
    ##  [9] "Ispra"                             "Italy"                            
    ## [1] "García-Viñas J.I."                 "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ##  [1] "Wasof S."                                                                   
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Department of Forest and Water Management"                                  
    ##  [8] "Forest & Nature Lab (ForNaLab)"                                             
    ##  [9] "Ghent University"                                                           
    ## [10] "Gontrode"                                                                   
    ## [11] "Belgium"                                                                    
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [1] "Hattab T."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [7] "IFREMER UMR 248 MARBEC"                                                     
    ## [8] "Sète Cedex"                                                                 
    ## [9] "France"                                                                     
    ##  [1] "Jamoneau A."                                                                
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Unité de Recherche “Ecosystèmes aquatiques et changements globaux” (EABX)"  
    ##  [8] "IRSTEA"                                                                     
    ##  [9] "Cestas"                                                                     
    ## [10] "France"                                                                     
    ## [1] "Gallet-Moron E."                                                            
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [1] "Saguez R."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [1] "Bennsadek L."                                                               
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ##  [1] "Valdès A."                                                                  
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Department of Ecology"                                                      
    ##  [8] "Environment and Plant Sciences"                                             
    ##  [9] "Stockholm University"                                                       
    ## [10] "Stockholm"                                                                  
    ## [11] "Sweden"                                                                     
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [1] "Lenoir J."                                                 
    ## [2] "UR “Ecologie et dynamique des systems anthropisés” (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                       
    ## [4] "Université de Picardie Jules Verne"                        
    ## [5] "1 Rue des Louvels"                                         
    ## [6] "Amiens"                                                    
    ## [7] "80000"                                                     
    ## [8] "France"                                                    
    ## [1] "Chabrerie O."                                          
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardie"                    
    ## [5] "1 rue des Louvels"                                     
    ## [6] "Amiens Cedex"                                          
    ## [7] "F-80037"                                               
    ## [8] "France"                                                
    ## [1] "Decocq G."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardie"                    
    ## [5] "1 rue des Louvels"                                     
    ## [6] "Amiens Cedex"                                          
    ## [7] "F-80037"                                               
    ## [8] "France"                                                
    ## [1] "Lenoir J."                                                
    ## [2] "UR Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                      
    ## [4] "Université de Picardie Jules Verne"                       
    ## [5] "1 Rue des Louvels"                                        
    ## [6] "Amiens Cedex 1"                                           
    ## [7] "80037"                                                    
    ## [8] "France"                                                   
    ##  [1] "Martín-Duque J.F."                                         
    ##  [2] "Department of Geomodynamic and Geosciences Institute (CSIC"
    ##  [3] "UCM)"                                                      
    ##  [4] "Faculty of Geological Sciences"                            
    ##  [5] "Complutense University of Madrid"                          
    ##  [6] "Madrid"                                                    
    ##  [7] "28040"                                                     
    ##  [8] "Jose Antonio Nováis"                                       
    ##  [9] "2"                                                         
    ## [10] "Spain"                                                     
    ## [1] "Semboli O."                                              
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## [1] "Beina D."                                                
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## [1] "Closset-Kopp D."                                         
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## [1] "Decocq G."                                               
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## [1] "Kopp C.W."                               
    ## [2] "Division of Biological Sciences (Ecology"
    ## [3] "Behavior and Evolution Section)"         
    ## [4] "University of California San Diego"      
    ## [5] "La Jolla"                                
    ## [6] "CA"                                      
    ## [7] "9500 Gilman Dr. #0116"                   
    ## [8] "United States"                           
    ## [1] "Cleland E.E."                            
    ## [2] "Division of Biological Sciences (Ecology"
    ## [3] "Behavior and Evolution Section)"         
    ## [4] "University of California San Diego"      
    ## [5] "La Jolla"                                
    ## [6] "CA"                                      
    ## [7] "9500 Gilman Dr. #0116"                   
    ## [8] "United States"                           
    ## [1] "Fernandez C."                                               
    ## [2] "Institut Mediterranéen d'Ecologie et de Paléoécologie (IMEP"
    ## [3] "UMR CNRS 6116)"                                             
    ## [4] "Aix-Marseille Université"                                   
    ## [5] "Centre St-Charles"                                          
    ## [6] "Marseille cedex 03"                                         
    ## [7] "13331"                                                      
    ## [8] "3 place Victor Hugo"                                        
    ## [9] "France"                                                     
    ## [1] "Université Montpellier 2 CNRS)"             
    ## [2] "Paleoenvironments and Chronoecology (PALECO"
    ## [1] "Ecole Pratique des Hautes Etudes)" "UR Band SEF (CIRAD)"              
    ## [3] "Montpellier"                       "France"                           
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## [1] "Ecole Pratique des Hautes Etudes)" "Montpellier"                      
    ## [3] "France"                           
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## [1] "Ecole Pratique des Hautes Etudes)" "Montpellier"                      
    ## [3] "France"                           
    ##  [1] "Urbieta I.R."                                        
    ##  [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ##  [3] "CSIC)"                                               
    ##  [4] "E-41080"                                             
    ##  [5] "Seville"                                             
    ##  [6] "PO Box 1052"                                         
    ##  [7] "Spain"                                               
    ##  [8] "Departamento de Ecología"                            
    ##  [9] "Universidad de Alcalá"                               
    ## [10] "28871 Alcalá de Henares"                             
    ## [11] "Ctra. Madrid-Barcelona km 33.6"                      
    ## [12] "Spain"                                               
    ## [1] "García L.V."                                         
    ## [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ## [3] "CSIC)"                                               
    ## [4] "E-41080"                                             
    ## [5] "Seville"                                             
    ## [6] "PO Box 1052"                                         
    ## [7] "Spain"                                               
    ## [1] "Marañón T."                                          
    ## [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ## [3] "CSIC)"                                               
    ## [4] "E-41080"                                             
    ## [5] "Seville"                                             
    ## [6] "PO Box 1052"                                         
    ## [7] "Spain"                                               
    ## [1] "Valdes A."                                        
    ## [2] "Departamento de Biología de Organismos y Sistemas"
    ## [3] "Universidad de Oviedo"                            
    ## [4] "Instituto Cantábrico de Biodiversidad (ICAB"      
    ## [5] "CSIC-UO-PA)"                                      
    ## [6] "E-33071"                                          
    ## [7] "Oviedo"                                           
    ## [8] "Spain"                                            
    ## [1] "García D."                                        
    ## [2] "Departamento de Biología de Organismos y Sistemas"
    ## [3] "Universidad de Oviedo"                            
    ## [4] "Instituto Cantábrico de Biodiversidad (ICAB"      
    ## [5] "CSIC-UO-PA)"                                      
    ## [6] "E-33071"                                          
    ## [7] "Oviedo"                                           
    ## [8] "Spain"                                            
    ## [1] "Pausas J.G."                                          
    ## [2] "Centro de Investigaciones sobre Desertificación (CIDE"
    ## [3] "CSIC)"                                                
    ## [4] "ES-46470 Albal"                                       
    ## [5] "Valencia"                                             
    ## [6] "Apartado Oficial"                                     
    ## [7] "Spain"                                                
    ## [1] "Gómez-Aparicio L."                                     
    ## [2] "Instituto de Recursos Naturales y Agrobiología (IRNASE"
    ## [3] "CSIC)"                                                 
    ## [4] "41080 Seville"                                         
    ## [5] "PO Box 1052"                                           
    ## [6] "Spain"                                                 
    ##  [1] "Gómez-Aparicio L."                                               
    ##  [2] "Grupo de Ecología Terrestre"                                     
    ##  [3] "Dpto. Ecología"                                                  
    ##  [4] "Universidadde Granada"                                           
    ##  [5] "Granada"                                                         
    ##  [6] "ES-18071"                                                        
    ##  [7] "Spain"                                                           
    ##  [8] "Instituto de Recursos Naturales Y Agrobiología de Sevilla (IRNAS"
    ##  [9] "CSIC)"                                                           
    ## [10] "Sevilla"                                                         
    ## [11] "ES-41080"                                                        
    ## [12] "PO Box 1052"                                                     
    ## [13] "Spain"                                                           
    ## [1] "Navarro F.B."                            
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ## [1] "Ripoll M.A."                             
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ## [1] "Jiménez M.N."                            
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ##  [1] "Khater C."                          "National Center for Remote Sensing"
    ##  [3] "Lebanese Natl. Cncl. for Sci. Res." "Beirut"                            
    ##  [5] "BP 11-8281"                         "Lebanon"                           
    ##  [7] "Ctr. Bio-Archeologie et d'Ecologie" "UMR 5059 (CNRS"                    
    ##  [9] "UM 11)"                             "Institut de Botanique"             
    ## [11] "F-34090 Montpellier"                "163 rue Auguste Broussonet"        
    ## [13] "France"                            
    ## [1] "Mesléard F."                                                       
    ## [2] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger"
    ## [3] "Montpellier"                                                       
    ## [4] "F-34033"                                                           
    ## [5] "C.E.P.E. L. Emberger"                                              
    ## [6] "C.N.R.S.)"                                                         
    ## [7] " B.P. 5051"                                                        
    ## [8] "France"                                                            
    ## [1] "Lepart J."                                                         
    ## [2] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger"
    ## [3] "Montpellier"                                                       
    ## [4] "F-34033"                                                           
    ## [5] "C.E.P.E. L. Emberger"                                              
    ## [6] "C.N.R.S.)"                                                         
    ## [7] " B.P. 5051"                                                        
    ## [8] "France"

Finding the potential resolutions:

``` r
resolK<-integer(length(pbI))
resolJK<-integer(length(pbI))
for(i in 1:length(pbI))
{
  A<-grep("\\([^)]+$",sepAffil[[pbI[i]]][[pbJ[i]]][1:pbK[[i]]])
  if(length(A)!=0){
    resolK[i]<-A[length(A)]
    resolJK[i]<-pbJ[i]
  }else{
    if(pbJ[i]>1){
      A<-grep("\\([^)]+$",sepAffil[[pbI[i]]][[pbJ[i]-1]])
      if(length(A)!=0){
        resolK[i]<-A[length(A)]
        resolJK[i]<-pbJ[i]-1
      }else{
        resolK[i]<-NA
        resolJK[i]<-NA
      }
    }else{
      resolK[i]<-NA
      resolJK[i]<-NA
    }
  }
}
```

Showing the resolution

``` r
for(i in 1:length(pbI))
{
  cat("problem",i,":",pbI[i],ifelse(is.na(resolJK[i])|resolJK[i]==pbJ[i],pbJ[i],paste(resolJK[i],pbJ[i],sep="-")),pbK[i],"resol:",resolK[i],"\n")
  print(sepAffil[[pbI[i]]][unique(c(resolJK[i],pbJ[i]))])
  cat("Resolution:\n")
  if(!is.na(resolK[i])&pbJ[i]==resolJK[i])
  {
    print(paste(sepAffil[[pbI[i]]][[pbJ[i]]][resolK[i]:pbK[i]],collapse=", "))
    cat("\n\n")
  }else{
    if(!is.na(resolK[i])&pbJ[i]!=resolJK[i])
    {
      print(paste(c(sepAffil[[pbI[i]]][[resolJK[i]]][resolK[i]:length(sepAffil[[pbI[i]]][[resolJK[i]]])],
                    sepAffil[[pbI[i]]][[pbJ[i]]][1:pbK[i]])
                    ,collapse=", "))
      cat("\n\n")
    }else{
      cat("!!!!! No solution !!!!!!!!!!\n\n")}
  }
}
```

    ## problem 1 : 48 1 3 resol: 2 
    ## [[1]]
    ## [1] "Sánchez-Martín R."                                    
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ## 
    ## Resolution:
    ## [1] "Centro de Investigaciones Sobre Desertificación (CIDE, CSIC-UV-GV)"
    ## 
    ## 
    ## problem 2 : 48 2 3 resol: 2 
    ## [[1]]
    ## [1] "Verdú M."                                             
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ## 
    ## Resolution:
    ## [1] "Centro de Investigaciones Sobre Desertificación (CIDE, CSIC-UV-GV)"
    ## 
    ## 
    ## problem 3 : 48 3 3 resol: 2 
    ## [[1]]
    ## [1] "Montesinos-Navarro A."                                
    ## [2] "Centro de Investigaciones Sobre Desertificación (CIDE"
    ## [3] "CSIC-UV-GV)"                                          
    ## [4] "Moncada"                                              
    ## [5] "Spain"                                                
    ## 
    ## Resolution:
    ## [1] "Centro de Investigaciones Sobre Desertificación (CIDE, CSIC-UV-GV)"
    ## 
    ## 
    ## problem 4 : 93 2 6 resol: 4 
    ## [[1]]
    ##  [1] "Renault D."                       "Univ Rennes"                     
    ##  [3] "CNRS"                             "ECOBIO [(Ecosystèmes"            
    ##  [5] "biodiversité"                     "évolution)]"                     
    ##  [7] "Rennes"                           "France"                          
    ##  [9] "Institut Universitaire de France" "Paris cedex 05"                  
    ## [11] "France"                          
    ## 
    ## Resolution:
    ## [1] "ECOBIO [(Ecosystèmes, biodiversité, évolution)]"
    ## 
    ## 
    ## problem 5 : 123 1 3 resol: 2 
    ## [[1]]
    ## [1] "Gonzalez S."                       "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (CONICET, Universidad Nacional del Comahue)"
    ## 
    ## 
    ## problem 6 : 123 2 3 resol: 2 
    ## [[1]]
    ## [1] "Salazar C.V."                      "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (CONICET, Universidad Nacional del Comahue)"
    ## 
    ## 
    ## problem 7 : 123 3 3 resol: 2 
    ## [[1]]
    ## [1] "Ghermandi L."                      "INIBIOMA (CONICET"                
    ## [3] "Universidad Nacional del Comahue)" "Bariloche"                        
    ## [5] "Argentina"                        
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (CONICET, Universidad Nacional del Comahue)"
    ## 
    ## 
    ## problem 8 : 168 27 4 resol: 2 
    ## [[1]]
    ## [1] "Jiménez-Alfaro B."                           
    ## [2] "Biodiversity Research Institute (Univ.Oviedo"
    ## [3] "CSIC"                                        
    ## [4] "Princ. Asturias)"                            
    ## [5] "University of Oviedo"                        
    ## [6] "Mieres"                                      
    ## [7] "Spain"                                       
    ## 
    ## Resolution:
    ## [1] "Biodiversity Research Institute (Univ.Oviedo, CSIC, Princ. Asturias)"
    ## 
    ## 
    ## problem 9 : 254 8 3 resol: 2 
    ## [[1]]
    ## [1] "Chabrerie O."                                          
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR CNRS 7058)"
    ## 
    ## 
    ## problem 10 : 254 9 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR CNRS 7058)"
    ## 
    ## 
    ## problem 11 : 254 20 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR CNRS 7058)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR CNRS 7058)"
    ## 
    ## 
    ## problem 12 : 325 1 5 resol: 3 
    ## [[1]]
    ## [1] "Bazzichetto M."        "CNRS"                  "EcoBio (Ecosystèmes"  
    ## [4] "Biodiversité"          "Évolution) - UMR 6553" "Université de Rennes" 
    ## [7] "Rennes"                "France"               
    ## 
    ## Resolution:
    ## [1] "EcoBio (Ecosystèmes, Biodiversité, Évolution) - UMR 6553"
    ## 
    ## 
    ## problem 13 : 325 6 5 resol: 3 
    ## [[1]]
    ## [1] "Joly R."               "CNRS"                  "EcoBio (Ecosystèmes"  
    ## [4] "Biodiversité"          "Évolution) - UMR 6553" "Université de Rennes" 
    ## [7] "Rennes"                "France"               
    ## 
    ## Resolution:
    ## [1] "EcoBio (Ecosystèmes, Biodiversité, Évolution) - UMR 6553"
    ## 
    ## 
    ## problem 14 : 325 7 5 resol: 3 
    ## [[1]]
    ##  [1] "Renault D."                       "CNRS"                            
    ##  [3] "EcoBio (Ecosystèmes"              "Biodiversité"                    
    ##  [5] "Évolution) - UMR 6553"            "Université de Rennes"            
    ##  [7] "Rennes"                           "France"                          
    ##  [9] "Institut Universitaire de France" "Paris Cedex 05"                  
    ## [11] "France"                          
    ## 
    ## Resolution:
    ## [1] "EcoBio (Ecosystèmes, Biodiversité, Évolution) - UMR 6553"
    ## 
    ## 
    ## problem 15 : 345 1 11 resol: 7 
    ## [[1]]
    ##  [1] "Schmitt S."                      "French Institute of Pondicherry"
    ##  [3] "UMIFRE 21/USR 3330 CNRS-MAEE"    "Pondicherry"                    
    ##  [5] "India"                           "CNRS"                           
    ##  [7] "UMR EcoFoG (Agroparistech"       "Cirad"                          
    ##  [9] "INRAE"                           "Université des Antilles"        
    ## [11] "Université de la Guyane)"        "Kourou"                         
    ## [13] "French Guiana"                  
    ## 
    ## Resolution:
    ## [1] "UMR EcoFoG (Agroparistech, Cirad, INRAE, Université des Antilles, Université de la Guyane)"
    ## 
    ## 
    ## problem 16 : 381 2 12 resol: NA 
    ## [[1]]
    ## NULL
    ## 
    ## [[2]]
    ##  [1] "Dengler J."                                                                  
    ##  [2] "Vegetation Ecology Group"                                                    
    ##  [3] "Institute of Natural Resource Sciences (IUNR)"                               
    ##  [4] "Zurich University of Applied Sciences (ZHAW)"                                
    ##  [5] "Wädenswil"                                                                   
    ##  [6] "Switzerland"                                                                 
    ##  [7] "Plant Ecology"                                                               
    ##  [8] "Bayreuth Center of Ecology and Environmental Research (BayCEER)"             
    ##  [9] "University of Bayreuth"                                                      
    ## [10] "Bayreuth"                                                                    
    ## [11] "Germany"                                                                     
    ## [12] "German Centre for Integrative Biodiversity Research iDiv) Halle-Jena-Leipzig"
    ## [13] "Leipzig"                                                                     
    ## [14] "Germany"                                                                     
    ## 
    ## Resolution:
    ## !!!!! No solution !!!!!!!!!!
    ## 
    ## problem 17 : 381 4 8 resol: 7 
    ## [[1]]
    ##  [1] "Matthews T.J."                                                                
    ##  [2] "CE3C – Centre for Ecology"                                                    
    ##  [3] "Evolution and Environmental Changes/Azorean Biodiversity Group"               
    ##  [4] "Univ. dos Açores"                                                             
    ##  [5] "Açores"                                                                       
    ##  [6] "Portugal"                                                                     
    ##  [7] "GEES (School of Geography"                                                    
    ##  [8] "Earth and Environmental Sciences) and Birmingham Institute of Forest Research"
    ##  [9] "University of Birmingham"                                                     
    ## [10] "Birmingham"                                                                   
    ## [11] "United Kingdom"                                                               
    ## 
    ## Resolution:
    ## [1] "GEES (School of Geography, Earth and Environmental Sciences) and Birmingham Institute of Forest Research"
    ## 
    ## 
    ## problem 18 : 386 23 4 resol: 2 
    ## [[1]]
    ## [1] "Jiménez-Alfaro B."                   "Research Unit of Biodiversity (CSIC"
    ## [3] "UO"                                  "PA)"                                
    ## [5] "Oviedo University"                   "Mieres"                             
    ## [7] "Spain"                              
    ## 
    ## Resolution:
    ## [1] "Research Unit of Biodiversity (CSIC, UO, PA)"
    ## 
    ## 
    ## problem 19 : 406 4 3 resol: 2 
    ## [[1]]
    ##  [1] "Matthews T.J."                                     
    ##  [2] "GEES (School of Geography"                         
    ##  [3] "Earth and Environmental Sciences)"                 
    ##  [4] "Birmingham Institute of Forest Research"           
    ##  [5] "University of Birmingham"                          
    ##  [6] "United Kingdom"                                    
    ##  [7] "CE3C – Centre for Ecology"                         
    ##  [8] "Evolution and Environmental Changes"               
    ##  [9] "Azorean Biodiversity Group"                        
    ## [10] "Universidade dos Açores"                           
    ## [11] "Depto de Ciências Agráriase Engenharia do Ambiente"
    ## [12] "Angra do Heroísmo"                                 
    ## [13] "Açores"                                            
    ## [14] "Portugal"                                          
    ## 
    ## Resolution:
    ## [1] "GEES (School of Geography, Earth and Environmental Sciences)"
    ## 
    ## 
    ## problem 20 : 409 3 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 21 : 413 16 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardy"                     
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 22 : 423 5 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 23 : 440 5 3 resol: 2 
    ## [[1]]
    ##  [1] "Matthews T.J."                                                                                                                                   
    ##  [2] "GEES (School of Geography"                                                                                                                       
    ##  [3] "Earth and Environmental Sciences)"                                                                                                               
    ##  [4] "Birmingham Institute of Forest Research"                                                                                                         
    ##  [5] "University of Birmingham"                                                                                                                        
    ##  [6] "Birmingham"                                                                                                                                      
    ##  [7] "United Kingdom"                                                                                                                                  
    ##  [8] "CE3C – Centre for Ecology"                                                                                                                       
    ##  [9] "Evolution and Environmental Changes/Azorean Biodiversity Group and Universidade. dos Açores – Depto de Ciências Agráriase Engenharia do Ambiente"
    ## [10] "Angra do Heroísmo"                                                                                                                               
    ## [11] "Portugal"                                                                                                                                        
    ## 
    ## Resolution:
    ## [1] "GEES (School of Geography, Earth and Environmental Sciences)"
    ## 
    ## 
    ## problem 24 : 481 20 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                    
    ## [2] "UR \"Ecologie et Dynamique des Systèmes Anthropisés\" (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                               
    ## [4] "Université de Picardie Jules Verne"                           
    ## [5] "Amiens"                                                       
    ## [6] "France"                                                       
    ## 
    ## Resolution:
    ## [1] "UR \"Ecologie et Dynamique des Systèmes Anthropisés\" (EDYSAN, UMR 7058 CNRS)"
    ## 
    ## 
    ## problem 25 : 484 27 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                        
    ## [4] "Université de Picardie Jules Verne"                    
    ## [5] "Amiens"                                                
    ## [6] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR 7058 CNRS)"
    ## 
    ## 
    ## problem 26 : 487 12 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 27 : 500 1 3 resol: 2 
    ## [[1]]
    ## [1] "Silva V."                                             
    ## [2] "Centre for Applied Ecology “Prof. Baeta Neves” (CEABN"
    ## [3] "InBIO)"                                               
    ## [4] "School of Agriculture"                                
    ## [5] "University of Lisbon"                                 
    ## [6] "Lisbon"                                               
    ## [7] "Portugal"                                             
    ## 
    ## Resolution:
    ## [1] "Centre for Applied Ecology “Prof. Baeta Neves” (CEABN, InBIO)"
    ## 
    ## 
    ## problem 28 : 553 11 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                    
    ## [2] "UR « Ecologie et Dynamique des Systèmes Anthropisés » (EDYSAN"
    ## [3] "UMR 7058 CNRS)"                                               
    ## [4] "Université de Picardie Jules Verne"                           
    ## [5] "Amiens"                                                       
    ## [6] "France"                                                       
    ## 
    ## Resolution:
    ## [1] "UR « Ecologie et Dynamique des Systèmes Anthropisés » (EDYSAN, UMR 7058 CNRS)"
    ## 
    ## 
    ## problem 29 : 555 1 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 30 : 555 2 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 31 : 555 3 3 resol: 2 
    ## [[1]]
    ## [1] "Spicher F."                                                                 
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 32 : 555 4 3 resol: 2 
    ## [[1]]
    ## [1] "Gallet-Moron E."                                                            
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 33 : 555 5 3 resol: 2 
    ## [[1]]
    ## [1] "Buridant J."                                                                
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 34 : 555 6 3 resol: 2 
    ## [[1]]
    ## [1] "Closset-Kopp D."                                                            
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 35 : 578 9 3 resol: 2 
    ## [[1]]
    ## [1] "Closset-Kopp D."                                             
    ## [2] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                         
    ## [4] "Université de Picardie Jules Verne"                          
    ## [5] "Amiens Cedex"                                                
    ## [6] "France"                                                      
    ## 
    ## Resolution:
    ## [1] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 36 : 578 10 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                                   
    ## [2] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                         
    ## [4] "Université de Picardie Jules Verne"                          
    ## [5] "Amiens Cedex"                                                
    ## [6] "France"                                                      
    ## 
    ## Resolution:
    ## [1] "Unité Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 37 : 597 2 6 resol: 4 
    ## [[1]]
    ## [1] "Bazzichetto M."        "Université de Rennes"  "CNRS"                 
    ## [4] "EcoBio (Ecosystèmes"   "biodiversité"          "évolution) – UMR 6553"
    ## [7] "Rennes"                "France"               
    ## 
    ## Resolution:
    ## [1] "EcoBio (Ecosystèmes, biodiversité, évolution) – UMR 6553"
    ## 
    ## 
    ## problem 38 : 614 2-3 1 resol: 2 
    ## [[1]]
    ## [1] "Suárez-Seoane S."                                
    ## [2] "Department of Organisms and Systems Biology (BOS"
    ## 
    ## [[2]]
    ## [1] "Ecology Unit) and Research Unit of Biodiversity (UO-CSIC-PA)"
    ## [2] "University of Oviedo"                                        
    ## [3] "Oviedo"                                                      
    ## [4] "Spain"                                                       
    ## 
    ## Resolution:
    ## [1] "Department of Organisms and Systems Biology (BOS, Ecology Unit) and Research Unit of Biodiversity (UO-CSIC-PA)"
    ## 
    ## 
    ## problem 39 : 691 5 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                                  
    ## [2] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 40 : 691 9 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                  
    ## [2] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "UR «Ecologie et Dynamique des Systèmes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 41 : 725 1 3 resol: 2 
    ## [[1]]
    ## [1] "Jiménez-Alfaro B."               "Institute of Biodiversity (IMIB"
    ## [3] "CISC-UO-PA)"                     "University of Oviedo"           
    ## [5] "Oviedo"                          "Spain"                          
    ## 
    ## Resolution:
    ## [1] "Institute of Biodiversity (IMIB, CISC-UO-PA)"
    ## 
    ## 
    ## problem 42 : 784 12 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 43 : 784 19 3 resol: 2 
    ## [[1]]
    ## [1] "Spicher F."                                                                 
    ## [2] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                                        
    ## [4] "Université de Picardie Jules Verne"                                         
    ## [5] "Amiens"                                                                     
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche «Ecologie et Dynamique des Systémes Anthropisés» (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 44 : 789 1 4 resol: 3 
    ## [[1]]
    ## [1] "Franzese J."                               
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (Universidad Nacional del Comahue, CONICET)"
    ## 
    ## 
    ## problem 45 : 789 2 4 resol: 3 
    ## [[1]]
    ## [1] "Raffaele E."                               
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (Universidad Nacional del Comahue, CONICET)"
    ## 
    ## 
    ## problem 46 : 789 3 4 resol: 3 
    ## [[1]]
    ## [1] "Blackhall M."                              
    ## [2] "Laboratorio Ecotono"                       
    ## [3] "INIBIOMA (Universidad Nacional del Comahue"
    ## [4] "CONICET)"                                  
    ## [5] "S. C. Bariloche"                           
    ## [6] "Argentina"                                 
    ## 
    ## Resolution:
    ## [1] "INIBIOMA (Universidad Nacional del Comahue, CONICET)"
    ## 
    ## 
    ## problem 47 : 855 16 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                              
    ## [2] "Ecologie et Dynamiques des Systèmes Anthropisés (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                    
    ## [4] "Université de Picardie Jules Verne"                     
    ## [5] "Amiens"                                                 
    ## [6] "France"                                                 
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamiques des Systèmes Anthropisés (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 48 : 860 19 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                  
    ## [2] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058 CNRS-UPJV)"                                        
    ## [4] "Université de Picardie Jules Verne"                         
    ## [5] "Amiens"                                                     
    ## [6] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "UR “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058 CNRS-UPJV)"
    ## 
    ## 
    ## problem 49 : 880 1 11 resol: 7 
    ## [[1]]
    ##  [1] "Koffi K.F."                                            
    ##  [2] "UFR des Sciences de la Nature"                         
    ##  [3] "Laboratoire d'Ecologie et Développement Durable (LEDD)"
    ##  [4] "Université Nangui Abrogoua"                            
    ##  [5] "Abidjan"                                               
    ##  [6] "Cote d'Ivoire"                                         
    ##  [7] "UMR 7618 IEES-Paris (IRD"                              
    ##  [8] "CNRS"                                                  
    ##  [9] "Université Paris Diderot"                              
    ## [10] "UPEC"                                                  
    ## [11] "INRA)"                                                 
    ## [12] "Sorbonne Université"                                   
    ## [13] "Paris"                                                 
    ## [14] "France"                                                
    ## 
    ## Resolution:
    ## [1] "UMR 7618 IEES-Paris (IRD, CNRS, Université Paris Diderot, UPEC, INRA)"
    ## 
    ## 
    ## problem 50 : 880 3 6 resol: 2 
    ## [[1]]
    ##  [1] "Lata J.-C."                               
    ##  [2] "UMR 7618 IEES-Paris (IRD"                 
    ##  [3] "CNRS"                                     
    ##  [4] "Université Paris Diderot"                 
    ##  [5] "UPEC"                                     
    ##  [6] "INRA)"                                    
    ##  [7] "Sorbonne Université"                      
    ##  [8] "Paris"                                    
    ##  [9] "France"                                   
    ## [10] "Department of Geoecology and Geochemistry"
    ## [11] "Institute of Natural Resources"           
    ## [12] "Tomsk Polytechnic University"             
    ## [13] "Tomsk"                                    
    ## [14] "Russian Federation"                       
    ## 
    ## Resolution:
    ## [1] "UMR 7618 IEES-Paris (IRD, CNRS, Université Paris Diderot, UPEC, INRA)"
    ## 
    ## 
    ## problem 51 : 880 5 6 resol: 2 
    ## [[1]]
    ## [1] "Srikanthasamy T."         "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ## 
    ## Resolution:
    ## [1] "UMR 7618 IEES-Paris (IRD, CNRS, Université Paris Diderot, UPEC, INRA)"
    ## 
    ## 
    ## problem 52 : 880 6 6 resol: 2 
    ## [[1]]
    ## [1] "Konaré S."                "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ## 
    ## Resolution:
    ## [1] "UMR 7618 IEES-Paris (IRD, CNRS, Université Paris Diderot, UPEC, INRA)"
    ## 
    ## 
    ## problem 53 : 880 8 6 resol: 2 
    ## [[1]]
    ## [1] "Barot S."                 "UMR 7618 IEES-Paris (IRD"
    ## [3] "CNRS"                     "Université Paris Diderot"
    ## [5] "UPEC"                     "INRA)"                   
    ## [7] "Sorbonne Université"      "Paris"                   
    ## [9] "France"                  
    ## 
    ## Resolution:
    ## [1] "UMR 7618 IEES-Paris (IRD, CNRS, Université Paris Diderot, UPEC, INRA)"
    ## 
    ## 
    ## problem 54 : 920 1 3 resol: 2 
    ## [[1]]
    ##  [1] "Mateo R.G."                                                         
    ##  [2] "MONTES (ETSI Montes"                                                
    ##  [3] "Forestal y del Medio Natural)"                                      
    ##  [4] "Universidad Politécnica de Madrid"                                  
    ##  [5] "Madrid"                                                             
    ##  [6] "Spain"                                                              
    ##  [7] "Departamento de Biología (Botánica)"                                
    ##  [8] "Universidad Autónoma de Madrid"                                     
    ##  [9] "Madrid"                                                             
    ## [10] "Spain"                                                              
    ## [11] "Centro de Investigación en Biodiversidad y Cambio Global (CIBC-UAM)"
    ## [12] "Universidad Autónoma de Madrid"                                     
    ## [13] "Madrid"                                                             
    ## [14] "Spain"                                                              
    ## 
    ## Resolution:
    ## [1] "MONTES (ETSI Montes, Forestal y del Medio Natural)"
    ## 
    ## 
    ## problem 55 : 920 2 3 resol: 2 
    ## [[1]]
    ## [1] "Gastón A."                         "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ## 
    ## Resolution:
    ## [1] "MONTES (ETSI Montes, Forestal y del Medio Natural)"
    ## 
    ## 
    ## problem 56 : 920 3 3 resol: 2 
    ## [[1]]
    ## [1] "Aroca-Fernández M.J."              "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ## 
    ## Resolution:
    ## [1] "MONTES (ETSI Montes, Forestal y del Medio Natural)"
    ## 
    ## 
    ## problem 57 : 920 6 3 resol: 2 
    ## [[1]]
    ##  [1] "Saura S."                          "MONTES (ETSI Montes"              
    ##  [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ##  [5] "Madrid"                            "Spain"                            
    ##  [7] "European Commission"               "Joint Research Centre (JRC)"      
    ##  [9] "Ispra"                             "Italy"                            
    ## 
    ## Resolution:
    ## [1] "MONTES (ETSI Montes, Forestal y del Medio Natural)"
    ## 
    ## 
    ## problem 58 : 920 7 3 resol: 2 
    ## [[1]]
    ## [1] "García-Viñas J.I."                 "MONTES (ETSI Montes"              
    ## [3] "Forestal y del Medio Natural)"     "Universidad Politécnica de Madrid"
    ## [5] "Madrid"                            "Spain"                            
    ## 
    ## Resolution:
    ## [1] "MONTES (ETSI Montes, Forestal y del Medio Natural)"
    ## 
    ## 
    ## problem 59 : 1095 1 3 resol: 2 
    ## [[1]]
    ##  [1] "Wasof S."                                                                   
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Department of Forest and Water Management"                                  
    ##  [8] "Forest & Nature Lab (ForNaLab)"                                             
    ##  [9] "Ghent University"                                                           
    ## [10] "Gontrode"                                                                   
    ## [11] "Belgium"                                                                    
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 60 : 1095 2 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 61 : 1095 3 3 resol: 2 
    ## [[1]]
    ## [1] "Hattab T."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## [7] "IFREMER UMR 248 MARBEC"                                                     
    ## [8] "Sète Cedex"                                                                 
    ## [9] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 62 : 1095 4 3 resol: 2 
    ## [[1]]
    ##  [1] "Jamoneau A."                                                                
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Unité de Recherche “Ecosystèmes aquatiques et changements globaux” (EABX)"  
    ##  [8] "IRSTEA"                                                                     
    ##  [9] "Cestas"                                                                     
    ## [10] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 63 : 1095 5 3 resol: 2 
    ## [[1]]
    ## [1] "Gallet-Moron E."                                                            
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 64 : 1095 7 3 resol: 2 
    ## [[1]]
    ## [1] "Saguez R."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 65 : 1095 8 3 resol: 2 
    ## [[1]]
    ## [1] "Bennsadek L."                                                               
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 66 : 1095 10 3 resol: 2 
    ## [[1]]
    ##  [1] "Valdès A."                                                                  
    ##  [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ##  [3] "UMR 7058)"                                                                  
    ##  [4] "Jules Verne University of Picardie"                                         
    ##  [5] "Amiens Cedex 1"                                                             
    ##  [6] "France"                                                                     
    ##  [7] "Department of Ecology"                                                      
    ##  [8] "Environment and Plant Sciences"                                             
    ##  [9] "Stockholm University"                                                       
    ## [10] "Stockholm"                                                                  
    ## [11] "Sweden"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 67 : 1095 12 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                                                  
    ## [2] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN"
    ## [3] "UMR 7058)"                                                                  
    ## [4] "Jules Verne University of Picardie"                                         
    ## [5] "Amiens Cedex 1"                                                             
    ## [6] "France"                                                                     
    ## 
    ## Resolution:
    ## [1] "Unité de Recherche “Ecologie et Dynamique des Systèmes Anthropisés” (EDYSAN, UMR 7058)"
    ## 
    ## 
    ## problem 68 : 1116 16 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                 
    ## [2] "UR “Ecologie et dynamique des systems anthropisés” (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                       
    ## [4] "Université de Picardie Jules Verne"                        
    ## [5] "1 Rue des Louvels"                                         
    ## [6] "Amiens"                                                    
    ## [7] "80000"                                                     
    ## [8] "France"                                                    
    ## 
    ## Resolution:
    ## [1] "UR “Ecologie et dynamique des systems anthropisés” (EDYSAN, FRE 3498 CNRS-UPJV)"
    ## 
    ## 
    ## problem 69 : 1283 5 3 resol: 2 
    ## [[1]]
    ## [1] "Chabrerie O."                                          
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardie"                    
    ## [5] "1 rue des Louvels"                                     
    ## [6] "Amiens Cedex"                                          
    ## [7] "F-80037"                                               
    ## [8] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, FRE 3498 CNRS-UPJV)"
    ## 
    ## 
    ## problem 70 : 1283 6 3 resol: 2 
    ## [[1]]
    ## [1] "Decocq G."                                             
    ## [2] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                   
    ## [4] "Jules Verne University of Picardie"                    
    ## [5] "1 rue des Louvels"                                     
    ## [6] "Amiens Cedex"                                          
    ## [7] "F-80037"                                               
    ## [8] "France"                                                
    ## 
    ## Resolution:
    ## [1] "Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, FRE 3498 CNRS-UPJV)"
    ## 
    ## 
    ## problem 71 : 1473 59 3 resol: 2 
    ## [[1]]
    ## [1] "Lenoir J."                                                
    ## [2] "UR Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN"
    ## [3] "FRE 3498 CNRS-UPJV)"                                      
    ## [4] "Université de Picardie Jules Verne"                       
    ## [5] "1 Rue des Louvels"                                        
    ## [6] "Amiens Cedex 1"                                           
    ## [7] "80037"                                                    
    ## [8] "France"                                                   
    ## 
    ## Resolution:
    ## [1] "UR Ecologie et Dynamique des Systèmes Anthropisés (EDYSAN, FRE 3498 CNRS-UPJV)"
    ## 
    ## 
    ## problem 72 : 1719 6 3 resol: 2 
    ## [[1]]
    ##  [1] "Martín-Duque J.F."                                         
    ##  [2] "Department of Geomodynamic and Geosciences Institute (CSIC"
    ##  [3] "UCM)"                                                      
    ##  [4] "Faculty of Geological Sciences"                            
    ##  [5] "Complutense University of Madrid"                          
    ##  [6] "Madrid"                                                    
    ##  [7] "28040"                                                     
    ##  [8] "Jose Antonio Nováis"                                       
    ##  [9] "2"                                                         
    ## [10] "Spain"                                                     
    ## 
    ## Resolution:
    ## [1] "Department of Geomodynamic and Geosciences Institute (CSIC, UCM)"
    ## 
    ## 
    ## problem 73 : 1772 1 4 resol: 3 
    ## [[1]]
    ## [1] "Semboli O."                                              
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## 
    ## Resolution:
    ## [1] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN, FRE 3498 CNRS)"
    ## 
    ## 
    ## problem 74 : 1772 2 4 resol: 3 
    ## [[1]]
    ## [1] "Beina D."                                                
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## 
    ## Resolution:
    ## [1] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN, FRE 3498 CNRS)"
    ## 
    ## 
    ## problem 75 : 1772 3 4 resol: 3 
    ## [[1]]
    ## [1] "Closset-Kopp D."                                         
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## 
    ## Resolution:
    ## [1] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN, FRE 3498 CNRS)"
    ## 
    ## 
    ## problem 76 : 1772 5 4 resol: 3 
    ## [[1]]
    ## [1] "Decocq G."                                               
    ## [2] "Jules Verne University of Picardie"                      
    ## [3] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN"
    ## [4] "FRE 3498 CNRS)"                                          
    ## [5] "1 rue des Louvels"                                       
    ## [6] "AMIENS Cedex"                                            
    ## [7] "F-80037"                                                 
    ## [8] "France"                                                  
    ## 
    ## Resolution:
    ## [1] "UR Ecologie et Dynamique des Systèmes Anthropisés(EDYSAN, FRE 3498 CNRS)"
    ## 
    ## 
    ## problem 77 : 1983 1 3 resol: 2 
    ## [[1]]
    ## [1] "Kopp C.W."                               
    ## [2] "Division of Biological Sciences (Ecology"
    ## [3] "Behavior and Evolution Section)"         
    ## [4] "University of California San Diego"      
    ## [5] "La Jolla"                                
    ## [6] "CA"                                      
    ## [7] "9500 Gilman Dr. #0116"                   
    ## [8] "United States"                           
    ## 
    ## Resolution:
    ## [1] "Division of Biological Sciences (Ecology, Behavior and Evolution Section)"
    ## 
    ## 
    ## problem 78 : 1983 2 3 resol: 2 
    ## [[1]]
    ## [1] "Cleland E.E."                            
    ## [2] "Division of Biological Sciences (Ecology"
    ## [3] "Behavior and Evolution Section)"         
    ## [4] "University of California San Diego"      
    ## [5] "La Jolla"                                
    ## [6] "CA"                                      
    ## [7] "9500 Gilman Dr. #0116"                   
    ## [8] "United States"                           
    ## 
    ## Resolution:
    ## [1] "Division of Biological Sciences (Ecology, Behavior and Evolution Section)"
    ## 
    ## 
    ## problem 79 : 2189 5 3 resol: 2 
    ## [[1]]
    ## [1] "Fernandez C."                                               
    ## [2] "Institut Mediterranéen d'Ecologie et de Paléoécologie (IMEP"
    ## [3] "UMR CNRS 6116)"                                             
    ## [4] "Aix-Marseille Université"                                   
    ## [5] "Centre St-Charles"                                          
    ## [6] "Marseille cedex 03"                                         
    ## [7] "13331"                                                      
    ## [8] "3 place Victor Hugo"                                        
    ## [9] "France"                                                     
    ## 
    ## Resolution:
    ## [1] "Institut Mediterranéen d'Ecologie et de Paléoécologie (IMEP, UMR CNRS 6116)"
    ## 
    ## 
    ## problem 80 : 2294 1-2 1 resol: 2 
    ## [[1]]
    ## [1] "Aleman J."                                  
    ## [2] "Centre for Bio-Archeology and Ecology (CBAE"
    ## 
    ## [[2]]
    ## [1] "Université Montpellier 2 CNRS)"             
    ## [2] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## Resolution:
    ## [1] "Centre for Bio-Archeology and Ecology (CBAE, Université Montpellier 2 CNRS)"
    ## 
    ## 
    ## problem 81 : 2294 2-3 1 resol: 2 
    ## [[1]]
    ## [1] "Université Montpellier 2 CNRS)"             
    ## [2] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## [[2]]
    ## [1] "Ecole Pratique des Hautes Etudes)" "UR Band SEF (CIRAD)"              
    ## [3] "Montpellier"                       "France"                           
    ## 
    ## Resolution:
    ## [1] "Paleoenvironments and Chronoecology (PALECO, Ecole Pratique des Hautes Etudes)"
    ## 
    ## 
    ## problem 82 : 2294 4-5 2 resol: 2 
    ## [[1]]
    ## [1] "Leys B."                                    
    ## [2] "Centre for Bio-Archeology and Ecology (CBAE"
    ## 
    ## [[2]]
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## Resolution:
    ## [1] "Centre for Bio-Archeology and Ecology (CBAE, Université Montpellier 2, CNRS)"
    ## 
    ## 
    ## problem 83 : 2294 5-6 1 resol: 3 
    ## [[1]]
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## [[2]]
    ## [1] "Ecole Pratique des Hautes Etudes)" "Montpellier"                      
    ## [3] "France"                           
    ## 
    ## Resolution:
    ## [1] "Paleoenvironments and Chronoecology (PALECO, Ecole Pratique des Hautes Etudes)"
    ## 
    ## 
    ## problem 84 : 2294 17-18 2 resol: 2 
    ## [[1]]
    ## [1] "Bremond L."                                 
    ## [2] "Centre for Bio-Archeology and Ecology (CBAE"
    ## 
    ## [[2]]
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## Resolution:
    ## [1] "Centre for Bio-Archeology and Ecology (CBAE, Université Montpellier 2, CNRS)"
    ## 
    ## 
    ## problem 85 : 2294 18-19 1 resol: 3 
    ## [[1]]
    ## [1] "Université Montpellier 2"                   
    ## [2] "CNRS)"                                      
    ## [3] "Paleoenvironments and Chronoecology (PALECO"
    ## 
    ## [[2]]
    ## [1] "Ecole Pratique des Hautes Etudes)" "Montpellier"                      
    ## [3] "France"                           
    ## 
    ## Resolution:
    ## [1] "Paleoenvironments and Chronoecology (PALECO, Ecole Pratique des Hautes Etudes)"
    ## 
    ## 
    ## problem 86 : 2365 1 3 resol: 2 
    ## [[1]]
    ##  [1] "Urbieta I.R."                                        
    ##  [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ##  [3] "CSIC)"                                               
    ##  [4] "E-41080"                                             
    ##  [5] "Seville"                                             
    ##  [6] "PO Box 1052"                                         
    ##  [7] "Spain"                                               
    ##  [8] "Departamento de Ecología"                            
    ##  [9] "Universidad de Alcalá"                               
    ## [10] "28871 Alcalá de Henares"                             
    ## [11] "Ctra. Madrid-Barcelona km 33.6"                      
    ## [12] "Spain"                                               
    ## 
    ## Resolution:
    ## [1] "Instituto de Recursos Naturales y Agrobiología(IRNAS, CSIC)"
    ## 
    ## 
    ## problem 87 : 2365 2 3 resol: 2 
    ## [[1]]
    ## [1] "García L.V."                                         
    ## [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ## [3] "CSIC)"                                               
    ## [4] "E-41080"                                             
    ## [5] "Seville"                                             
    ## [6] "PO Box 1052"                                         
    ## [7] "Spain"                                               
    ## 
    ## Resolution:
    ## [1] "Instituto de Recursos Naturales y Agrobiología(IRNAS, CSIC)"
    ## 
    ## 
    ## problem 88 : 2365 4 3 resol: 2 
    ## [[1]]
    ## [1] "Marañón T."                                          
    ## [2] "Instituto de Recursos Naturales y Agrobiología(IRNAS"
    ## [3] "CSIC)"                                               
    ## [4] "E-41080"                                             
    ## [5] "Seville"                                             
    ## [6] "PO Box 1052"                                         
    ## [7] "Spain"                                               
    ## 
    ## Resolution:
    ## [1] "Instituto de Recursos Naturales y Agrobiología(IRNAS, CSIC)"
    ## 
    ## 
    ## problem 89 : 2552 1 5 resol: 4 
    ## [[1]]
    ## [1] "Valdes A."                                        
    ## [2] "Departamento de Biología de Organismos y Sistemas"
    ## [3] "Universidad de Oviedo"                            
    ## [4] "Instituto Cantábrico de Biodiversidad (ICAB"      
    ## [5] "CSIC-UO-PA)"                                      
    ## [6] "E-33071"                                          
    ## [7] "Oviedo"                                           
    ## [8] "Spain"                                            
    ## 
    ## Resolution:
    ## [1] "Instituto Cantábrico de Biodiversidad (ICAB, CSIC-UO-PA)"
    ## 
    ## 
    ## problem 90 : 2552 2 5 resol: 4 
    ## [[1]]
    ## [1] "García D."                                        
    ## [2] "Departamento de Biología de Organismos y Sistemas"
    ## [3] "Universidad de Oviedo"                            
    ## [4] "Instituto Cantábrico de Biodiversidad (ICAB"      
    ## [5] "CSIC-UO-PA)"                                      
    ## [6] "E-33071"                                          
    ## [7] "Oviedo"                                           
    ## [8] "Spain"                                            
    ## 
    ## Resolution:
    ## [1] "Instituto Cantábrico de Biodiversidad (ICAB, CSIC-UO-PA)"
    ## 
    ## 
    ## problem 91 : 2594 2 3 resol: 2 
    ## [[1]]
    ## [1] "Pausas J.G."                                          
    ## [2] "Centro de Investigaciones sobre Desertificación (CIDE"
    ## [3] "CSIC)"                                                
    ## [4] "ES-46470 Albal"                                       
    ## [5] "Valencia"                                             
    ## [6] "Apartado Oficial"                                     
    ## [7] "Spain"                                                
    ## 
    ## Resolution:
    ## [1] "Centro de Investigaciones sobre Desertificación (CIDE, CSIC)"
    ## 
    ## 
    ## problem 92 : 2671 2 3 resol: 2 
    ## [[1]]
    ## [1] "Gómez-Aparicio L."                                     
    ## [2] "Instituto de Recursos Naturales y Agrobiología (IRNASE"
    ## [3] "CSIC)"                                                 
    ## [4] "41080 Seville"                                         
    ## [5] "PO Box 1052"                                           
    ## [6] "Spain"                                                 
    ## 
    ## Resolution:
    ## [1] "Instituto de Recursos Naturales y Agrobiología (IRNASE, CSIC)"
    ## 
    ## 
    ## problem 93 : 2811 1 9 resol: 8 
    ## [[1]]
    ##  [1] "Gómez-Aparicio L."                                               
    ##  [2] "Grupo de Ecología Terrestre"                                     
    ##  [3] "Dpto. Ecología"                                                  
    ##  [4] "Universidadde Granada"                                           
    ##  [5] "Granada"                                                         
    ##  [6] "ES-18071"                                                        
    ##  [7] "Spain"                                                           
    ##  [8] "Instituto de Recursos Naturales Y Agrobiología de Sevilla (IRNAS"
    ##  [9] "CSIC)"                                                           
    ## [10] "Sevilla"                                                         
    ## [11] "ES-41080"                                                        
    ## [12] "PO Box 1052"                                                     
    ## [13] "Spain"                                                           
    ## 
    ## Resolution:
    ## [1] "Instituto de Recursos Naturales Y Agrobiología de Sevilla (IRNAS, CSIC)"
    ## 
    ## 
    ## problem 94 : 2854 1 5 resol: 4 
    ## [[1]]
    ## [1] "Navarro F.B."                            
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ## 
    ## Resolution:
    ## [1] "IFAPA Centre Camino de Purchil (C.I.C.E., Junta de Andalucía)"
    ## 
    ## 
    ## problem 95 : 2854 4 5 resol: 4 
    ## [[1]]
    ## [1] "Ripoll M.A."                             
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ## 
    ## Resolution:
    ## [1] "IFAPA Centre Camino de Purchil (C.I.C.E., Junta de Andalucía)"
    ## 
    ## 
    ## problem 96 : 2854 5 5 resol: 4 
    ## [[1]]
    ## [1] "Jiménez M.N."                            
    ## [2] "Grupo de Sistemas Y Recursos Forestales" 
    ## [3] "Área de Recursos Naturales"              
    ## [4] "IFAPA Centre Camino de Purchil (C.I.C.E."
    ## [5] "Junta de Andalucía)"                     
    ## [6] "Granada"                                 
    ## [7] "Camino de Purchil s/no. 18080"           
    ## [8] "Spain"                                   
    ## 
    ## Resolution:
    ## [1] "IFAPA Centre Camino de Purchil (C.I.C.E., Junta de Andalucía)"
    ## 
    ## 
    ## problem 97 : 3468 1 9 resol: 8 
    ## [[1]]
    ##  [1] "Khater C."                          "National Center for Remote Sensing"
    ##  [3] "Lebanese Natl. Cncl. for Sci. Res." "Beirut"                            
    ##  [5] "BP 11-8281"                         "Lebanon"                           
    ##  [7] "Ctr. Bio-Archeologie et d'Ecologie" "UMR 5059 (CNRS"                    
    ##  [9] "UM 11)"                             "Institut de Botanique"             
    ## [11] "F-34090 Montpellier"                "163 rue Auguste Broussonet"        
    ## [13] "France"                            
    ## 
    ## Resolution:
    ## [1] "UMR 5059 (CNRS, UM 11)"
    ## 
    ## 
    ## problem 98 : 4782 1 6 resol: 2 
    ## [[1]]
    ## [1] "Mesléard F."                                                       
    ## [2] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger"
    ## [3] "Montpellier"                                                       
    ## [4] "F-34033"                                                           
    ## [5] "C.E.P.E. L. Emberger"                                              
    ## [6] "C.N.R.S.)"                                                         
    ## [7] " B.P. 5051"                                                        
    ## [8] "France"                                                            
    ## 
    ## Resolution:
    ## [1] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger, Montpellier, F-34033, C.E.P.E. L. Emberger, C.N.R.S.)"
    ## 
    ## 
    ## problem 99 : 4782 2 6 resol: 2 
    ## [[1]]
    ## [1] "Lepart J."                                                         
    ## [2] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger"
    ## [3] "Montpellier"                                                       
    ## [4] "F-34033"                                                           
    ## [5] "C.E.P.E. L. Emberger"                                              
    ## [6] "C.N.R.S.)"                                                         
    ## [7] " B.P. 5051"                                                        
    ## [8] "France"                                                            
    ## 
    ## Resolution:
    ## [1] "Centre d'Ecologie Fonctionnelle et Evolutive (C.E.P.E. L. Emberger, Montpellier, F-34033, C.E.P.E. L. Emberger, C.N.R.S.)"

Applying resolution:

``` r
for(i in 1:length(pbI))
{
  if(is.na(resolJK[i])){next}
  # same J (author)
  if(pbJ[i]==resolJK[i]){
  ## prepare the resolution (sep by ",")
    sepAffil[[pbI[i]]][[pbJ[i]]][resolK[i]] <- paste(sepAffil[[pbI[i]]][[pbJ[i]]][resolK[i]:pbK[i]], collapse = ", ")
  ## suppress the affected K
    toSuppress<-(resolK[i]+1):pbK[i]
    sepAffil[[pbI[i]]][[pbJ[i]]]<-sepAffil[[pbI[i]]][[pbJ[i]]][-toSuppress]
  ## if any other problems in the same J, later K change numbers of problems and resolutions
    w_same<-which(pbI==pbI[i]&pbJ==pbJ[i])
    w_same<-w_same[w_same>i]
    if(length(w_same)>0)
    {
      pbK[w_same]<-pbK[w_same]-length(toSuppress)
      resolK[w_same]<-resolK[w_same]-length(toSuppress)
    }
  }
  
  # (wrongly) different J 
  ## prepare the resolution (J sep by ";", K sep by ","), followed by wrongly affected different j
  ## suppress the affected k and j
  ## if any other problem in the same I, change J and K numbers

}
```

The difficulty is that the numbers of elements from the list depends on
the corrections we make… Then maybe doing everything in a ´while´ loop
(to be able to control better the counters) might result better

``` r
keep<-sepAffil
checkItOut<-data.frame(i=integer(0),j=integer(0),k=integer(0))
i<-1
while(i<=length(sepAffil))
{
  #cat("i",i,"\n")
  if(length(sepAffil[[i]])==0){i<-i+1}
  j<-1
  while(j<=length(sepAffil[[i]]))
  {
    #cat("j",j,"\n")
    k<-1
    while(k<=length(sepAffil[[i]][[j]]))
    {
      #cat("k",k,"\n")
      if(any(grepl("\\([^)]+$",sepAffil[[i]][[j]][k:length(sepAffil[[i]][[j]])])))
      {
        w<-grep("\\([^)]+$",sepAffil[[i]][[j]])
        k<-w[w>=k]
        cat("i",i,"j",j,"k",k,"...")
        checkItOut<-rbind(checkItOut,data.frame(i=i,j=j,k=k))
        # Do everything here
        closingParenthesis <- grep("^[^(]+\\)",sepAffil[[i]][[j]])
        if(length(closingParenthesis)>0){
          cl<-closingParenthesis[1]
          sepAffil[[i]][[j]][k]<-paste(sepAffil[[i]][[j]][k:cl],collapse=", ", sep=", ")
          toSupp <- (k+1):cl
          sepAffil[[i]][[j]]<-sepAffil[[i]][[j]][-toSupp]
          cat("done\n")
        }else{
          j2<-j+1
          closingParenthesis <- grep("^[^(]+\\)",sepAffil[[i]][[j2]])
          if(length(closingParenthesis)>0){
            cl<-closingParenthesis[1]
            sepAffil[[i]][[j]][k]<-
              paste(
                paste(sepAffil[[i]][[j]][k:length(sepAffil[[i]][[j]])],collapse=", ", sep=", "),
                paste(sepAffil[[i]][[j2]][1:cl],collapse=", ", sep=", ")
                ,sep="; ")
            if(length(sepAffil[[i]][[j]])>k){
              toSupp <- (k+1):length(sepAffil[[i]][[j]])
              sepAffil[[i]][[j]]<-sepAffil[[i]][[j]][-toSupp]
            }
            sepAffil[[i]][[j]]<-c(sepAffil[[i]][[j]],sepAffil[[i]][[j2]][(cl+1):length(sepAffil[[i]][[j2]])])
            sepAffil[[i]]<-sepAffil[[i]][-j2]
            cat("done next\n")
          }else{
            cat("unresolved\n")
          }
        }
        k<-k+1
      }else{k<-length(sepAffil[[i]][[j]])+1}
    }
      
    j<-j+1
  }
  i<-i+1
  #cat("n\n")
}
```

    ## i 48 j 1 k 2 ...done
    ## i 48 j 2 k 2 ...done
    ## i 48 j 3 k 2 ...done
    ## i 93 j 2 k 4 ...done
    ## i 123 j 1 k 2 ...done
    ## i 123 j 2 k 2 ...done
    ## i 123 j 3 k 2 ...done
    ## i 168 j 27 k 2 ...done
    ## i 254 j 8 k 2 ...done
    ## i 254 j 9 k 2 ...done
    ## i 254 j 20 k 2 ...done
    ## i 304 j 1 k 10 ...unresolved
    ## i 304 j 2 k 4 ...unresolved
    ## i 325 j 1 k 3 ...done
    ## i 325 j 6 k 3 ...done
    ## i 325 j 7 k 3 ...done
    ## i 345 j 1 k 7 ...done
    ## i 381 j 4 k 7 ...done
    ## i 386 j 23 k 2 ...done
    ## i 406 j 4 k 2 ...done
    ## i 409 j 3 k 2 ...done
    ## i 413 j 16 k 2 ...done
    ## i 423 j 5 k 2 ...done
    ## i 440 j 5 k 2 ...done
    ## i 481 j 20 k 2 ...done
    ## i 484 j 27 k 2 ...done
    ## i 487 j 12 k 2 ...done
    ## i 500 j 1 k 2 ...done
    ## i 553 j 11 k 2 ...done
    ## i 555 j 1 k 2 ...done
    ## i 555 j 2 k 2 ...done
    ## i 555 j 3 k 2 ...done
    ## i 555 j 4 k 2 ...done
    ## i 555 j 5 k 2 ...done
    ## i 555 j 6 k 2 ...done
    ## i 578 j 9 k 2 ...done
    ## i 578 j 10 k 2 ...done
    ## i 597 j 2 k 4 ...done
    ## i 614 j 2 k 2 ...done next
    ## i 691 j 5 k 2 ...done
    ## i 691 j 9 k 2 ...done
    ## i 725 j 1 k 2 ...done
    ## i 784 j 12 k 2 ...done
    ## i 784 j 19 k 2 ...done
    ## i 789 j 1 k 3 ...done
    ## i 789 j 2 k 3 ...done
    ## i 789 j 3 k 3 ...done
    ## i 855 j 16 k 2 ...done
    ## i 860 j 19 k 2 ...done
    ## i 880 j 1 k 7 ...done
    ## i 880 j 3 k 2 ...done
    ## i 880 j 5 k 2 ...done
    ## i 880 j 6 k 2 ...done
    ## i 880 j 8 k 2 ...done
    ## i 920 j 1 k 2 ...done
    ## i 920 j 2 k 2 ...done
    ## i 920 j 3 k 2 ...done
    ## i 920 j 6 k 2 ...done
    ## i 920 j 7 k 2 ...done
    ## i 1095 j 1 k 2 ...done
    ## i 1095 j 2 k 2 ...done
    ## i 1095 j 3 k 2 ...done
    ## i 1095 j 4 k 2 ...done
    ## i 1095 j 5 k 2 ...done
    ## i 1095 j 7 k 2 ...done
    ## i 1095 j 8 k 2 ...done
    ## i 1095 j 10 k 2 ...done
    ## i 1095 j 12 k 2 ...done
    ## i 1116 j 16 k 2 ...done
    ## i 1283 j 5 k 2 ...done
    ## i 1283 j 6 k 2 ...done
    ## i 1473 j 59 k 2 ...done
    ## i 1719 j 6 k 2 ...done
    ## i 1772 j 1 k 3 ...done
    ## i 1772 j 2 k 3 ...done
    ## i 1772 j 3 k 3 ...done
    ## i 1772 j 5 k 3 ...done
    ## i 1983 j 1 k 2 ...done
    ## i 1983 j 2 k 2 ...done
    ## i 2189 j 5 k 2 ...done
    ## i 2294 j 1 k 2 ...done next
    ## i 2294 j 1 k 3 ...done next
    ## i 2294 j 2 k 2 ...done next
    ## i 2294 j 2 k 3 ...done next
    ## i 2294 j 13 k 2 ...done next
    ## i 2294 j 13 k 3 ...done next
    ## i 2365 j 1 k 2 ...done
    ## i 2365 j 2 k 2 ...done
    ## i 2365 j 4 k 2 ...done
    ## i 2552 j 1 k 4 ...done
    ## i 2552 j 2 k 4 ...done
    ## i 2594 j 2 k 2 ...done
    ## i 2671 j 2 k 2 ...done
    ## i 2811 j 1 k 8 ...done
    ## i 2854 j 1 k 4 ...done
    ## i 2854 j 4 k 4 ...done
    ## i 2854 j 5 k 4 ...done
    ## i 3468 j 1 k 8 ...done
    ## i 4782 j 1 k 2 ...done
    ## i 4782 j 2 k 2 ...done

``` r
ln_affil <- sapply(sepAffil,sapply,length)
tabAffil<-data.frame(
  doc=rep(1:length(sepAffil),sapply(ln_affil,function(x)ifelse(length(x)==0,0,sum(x)))),
  auth=unlist(lapply(sepAffil[sapply(sepAffil,length)>0],function(x)rep(1:length(x),sapply(x,length)))),
  string=unlist(sepAffil)
)
```

One easy thing to do which could help us make sense of the data here
would be to recognize all country fields. Then we could maybe have an
idea of the number of affiliations by authors… That would mean
downloading a dataset that contains all country names, in various
languages in case!

``` r
require(rnaturalearth)
```

    ## Loading required package: rnaturalearth

    ## Support for Spatial objects (`sp`) will be deprecated in {rnaturalearth} and will be removed in a future release of the package. Please use `sf` objects with {rnaturalearth}. For example: `ne_download(returnclass = 'sf')`

``` r
require(rnaturalearthdata)
```

    ## Loading required package: rnaturalearthdata

    ## 
    ## Attaching package: 'rnaturalearthdata'

    ## The following object is masked from 'package:rnaturalearth':
    ## 
    ##     countries110

``` r
require(sf)
```

    ## Loading required package: sf

    ## Linking to GEOS 3.11.2, GDAL 3.8.0, PROJ 9.2.1; sf_use_s2() is TRUE

``` r
worldMap_tot<-ne_countries(returnclass = "sf")
tinyCountries<-ne_download(type="admin_0_tiny_countries",returnclass = "sf")

colnames(worldMap_tot)[grepl("name",colnames(worldMap_tot))]
```

    ##  [1] "name"       "name_long"  "brk_name"   "name_ciawf" "name_sort" 
    ##  [6] "name_alt"   "name_len"   "name_ar"    "name_bn"    "name_de"   
    ## [11] "name_en"    "name_es"    "name_fa"    "name_fr"    "name_el"   
    ## [16] "name_he"    "name_hi"    "name_hu"    "name_id"    "name_it"   
    ## [21] "name_ja"    "name_ko"    "name_nl"    "name_pl"    "name_pt"   
    ## [26] "name_ru"    "name_sv"    "name_tr"    "name_uk"    "name_ur"   
    ## [31] "name_vi"    "name_zh"    "name_zht"

``` r
head(worldMap_tot)
```

    ## Simple feature collection with 6 features and 168 fields
    ## Geometry type: MULTIPOLYGON
    ## Dimension:     XY
    ## Bounding box:  xmin: -180 ymin: -18.28799 xmax: 180 ymax: 83.23324
    ## Geodetic CRS:  WGS 84
    ##        featurecla scalerank labelrank                  sovereignt sov_a3
    ## 1 Admin-0 country         1         6                        Fiji    FJI
    ## 2 Admin-0 country         1         3 United Republic of Tanzania    TZA
    ## 3 Admin-0 country         1         7              Western Sahara    SAH
    ## 4 Admin-0 country         1         2                      Canada    CAN
    ## 5 Admin-0 country         1         2    United States of America    US1
    ## 6 Admin-0 country         1         3                  Kazakhstan    KA1
    ##   adm0_dif level              type tlc                       admin adm0_a3
    ## 1        0     2 Sovereign country   1                        Fiji     FJI
    ## 2        0     2 Sovereign country   1 United Republic of Tanzania     TZA
    ## 3        0     2     Indeterminate   1              Western Sahara     SAH
    ## 4        0     2 Sovereign country   1                      Canada     CAN
    ## 5        1     2           Country   1    United States of America     USA
    ## 6        1     1       Sovereignty   1                  Kazakhstan     KAZ
    ##   geou_dif                  geounit gu_a3 su_dif        subunit su_a3 brk_diff
    ## 1        0                     Fiji   FJI      0           Fiji   FJI        0
    ## 2        0                 Tanzania   TZA      0       Tanzania   TZA        0
    ## 3        0           Western Sahara   SAH      0 Western Sahara   SAH        1
    ## 4        0                   Canada   CAN      0         Canada   CAN        0
    ## 5        0 United States of America   USA      0  United States   USA        0
    ## 6        0               Kazakhstan   KAZ      0     Kazakhstan   KAZ        0
    ##                       name      name_long brk_a3      brk_name brk_group
    ## 1                     Fiji           Fiji    FJI          Fiji      <NA>
    ## 2                 Tanzania       Tanzania    TZA      Tanzania      <NA>
    ## 3                W. Sahara Western Sahara    B28     W. Sahara      <NA>
    ## 4                   Canada         Canada    CAN        Canada      <NA>
    ## 5 United States of America  United States    USA United States      <NA>
    ## 6               Kazakhstan     Kazakhstan    KAZ    Kazakhstan      <NA>
    ##    abbrev postal                        formal_en formal_fr     name_ciawf
    ## 1    Fiji     FJ                 Republic of Fiji      <NA>           Fiji
    ## 2   Tanz.     TZ      United Republic of Tanzania      <NA>       Tanzania
    ## 3 W. Sah.     WS Sahrawi Arab Democratic Republic      <NA> Western Sahara
    ## 4    Can.     CA                           Canada      <NA>         Canada
    ## 5  U.S.A.     US         United States of America      <NA>  United States
    ## 6    Kaz.     KZ           Republic of Kazakhstan      <NA>     Kazakhstan
    ##   note_adm0                        note_brk                name_sort name_alt
    ## 1      <NA>                            <NA>                     Fiji     <NA>
    ## 2      <NA>                            <NA>                 Tanzania     <NA>
    ## 3      <NA> Self admin.; Claimed by Morocco           Western Sahara     <NA>
    ## 4      <NA>                            <NA>                   Canada     <NA>
    ## 5      <NA>                            <NA> United States of America     <NA>
    ## 6      <NA>                            <NA>               Kazakhstan     <NA>
    ##   mapcolor7 mapcolor8 mapcolor9 mapcolor13   pop_est pop_rank pop_year   gdp_md
    ## 1         5         1         2          2    889953       11     2019     5496
    ## 2         3         6         2          2  58005463       16     2019    63177
    ## 3         4         7         4          4    603253       11     2017      907
    ## 4         6         6         2          2  37589262       15     2019  1736425
    ## 5         4         5         1          1 328239523       17     2019 21433226
    ## 6         6         1         6          1  18513930       14     2019   181665
    ##   gdp_year                   economy             income_grp fips_10 iso_a2
    ## 1     2019      6. Developing region 4. Lower middle income      FJ     FJ
    ## 2     2019 7. Least developed region          5. Low income      TZ     TZ
    ## 3     2007 7. Least developed region          5. Low income      WI     EH
    ## 4     2019   1. Developed region: G7   1. High income: OECD      CA     CA
    ## 5     2019   1. Developed region: G7   1. High income: OECD      US     US
    ## 6     2019      6. Developing region 3. Upper middle income      KZ     KZ
    ##   iso_a2_eh iso_a3 iso_a3_eh iso_n3 iso_n3_eh un_a3 wb_a2 wb_a3   woe_id
    ## 1        FJ    FJI       FJI    242       242   242    FJ   FJI 23424813
    ## 2        TZ    TZA       TZA    834       834   834    TZ   TZA 23424973
    ## 3        EH    ESH       ESH    732       732   732   -99   -99 23424990
    ## 4        CA    CAN       CAN    124       124   124    CA   CAN 23424775
    ## 5        US    USA       USA    840       840   840    US   USA 23424977
    ## 6        KZ    KAZ       KAZ    398       398   398    KZ   KAZ      -90
    ##   woe_id_eh                                                    woe_note
    ## 1  23424813                                  Exact WOE match as country
    ## 2  23424973                                  Exact WOE match as country
    ## 3  23424990                                  Exact WOE match as country
    ## 4  23424775                                  Exact WOE match as country
    ## 5  23424977                                  Exact WOE match as country
    ## 6  23424871 Includes Baykonur Cosmodrome as an Admin-1 states provinces
    ##   adm0_iso adm0_diff adm0_tlc adm0_a3_us adm0_a3_fr adm0_a3_ru adm0_a3_es
    ## 1      FJI      <NA>      FJI        FJI        FJI        FJI        FJI
    ## 2      TZA      <NA>      TZA        TZA        TZA        TZA        TZA
    ## 3      B28      <NA>      B28        SAH        MAR        SAH        SAH
    ## 4      CAN      <NA>      CAN        CAN        CAN        CAN        CAN
    ## 5      USA      <NA>      USA        USA        USA        USA        USA
    ## 6      KAZ      <NA>      KAZ        KAZ        KAZ        KAZ        KAZ
    ##   adm0_a3_cn adm0_a3_tw adm0_a3_in adm0_a3_np adm0_a3_pk adm0_a3_de adm0_a3_gb
    ## 1        FJI        FJI        FJI        FJI        FJI        FJI        FJI
    ## 2        TZA        TZA        TZA        TZA        TZA        TZA        TZA
    ## 3        SAH        SAH        MAR        SAH        SAH        SAH        SAH
    ## 4        CAN        CAN        CAN        CAN        CAN        CAN        CAN
    ## 5        USA        USA        USA        USA        USA        USA        USA
    ## 6        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ
    ##   adm0_a3_br adm0_a3_il adm0_a3_ps adm0_a3_sa adm0_a3_eg adm0_a3_ma adm0_a3_pt
    ## 1        FJI        FJI        FJI        FJI        FJI        FJI        FJI
    ## 2        TZA        TZA        TZA        TZA        TZA        TZA        TZA
    ## 3        SAH        SAH        MAR        MAR        SAH        MAR        SAH
    ## 4        CAN        CAN        CAN        CAN        CAN        CAN        CAN
    ## 5        USA        USA        USA        USA        USA        USA        USA
    ## 6        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ
    ##   adm0_a3_ar adm0_a3_jp adm0_a3_ko adm0_a3_vn adm0_a3_tr adm0_a3_id adm0_a3_pl
    ## 1        FJI        FJI        FJI        FJI        FJI        FJI        FJI
    ## 2        TZA        TZA        TZA        TZA        TZA        TZA        TZA
    ## 3        SAH        SAH        SAH        SAH        MAR        MAR        MAR
    ## 4        CAN        CAN        CAN        CAN        CAN        CAN        CAN
    ## 5        USA        USA        USA        USA        USA        USA        USA
    ## 6        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ
    ##   adm0_a3_gr adm0_a3_it adm0_a3_nl adm0_a3_se adm0_a3_bd adm0_a3_ua adm0_a3_un
    ## 1        FJI        FJI        FJI        FJI        FJI        FJI        -99
    ## 2        TZA        TZA        TZA        TZA        TZA        TZA        -99
    ## 3        SAH        SAH        MAR        SAH        SAH        SAH        -99
    ## 4        CAN        CAN        CAN        CAN        CAN        CAN        -99
    ## 5        USA        USA        USA        USA        USA        USA        -99
    ## 6        KAZ        KAZ        KAZ        KAZ        KAZ        KAZ        -99
    ##   adm0_a3_wb     continent region_un        subregion
    ## 1        -99       Oceania   Oceania        Melanesia
    ## 2        -99        Africa    Africa   Eastern Africa
    ## 3        -99        Africa    Africa  Northern Africa
    ## 4        -99 North America  Americas Northern America
    ## 5        -99 North America  Americas Northern America
    ## 6        -99          Asia      Asia     Central Asia
    ##                    region_wb name_len long_len abbrev_len tiny homepart
    ## 1        East Asia & Pacific        4        4          4  -99        1
    ## 2         Sub-Saharan Africa        8        8          5  -99        1
    ## 3 Middle East & North Africa        9       14          7  -99        1
    ## 4              North America        6        6          4  -99        1
    ## 5              North America       24       13          6  -99        1
    ## 6      Europe & Central Asia       10       10          4  -99        1
    ##   min_zoom min_label max_label    label_x    label_y      ne_id wikidataid
    ## 1      0.0       3.0       8.0  177.97543 -17.826099 1159320625       Q712
    ## 2      0.0       3.0       8.0   34.95918  -6.051866 1159321337       Q924
    ## 3      4.7       6.0      11.0  -12.63030  23.967592 1159321223      Q6250
    ## 4      0.0       1.7       5.7 -101.91070  60.324287 1159320467        Q16
    ## 5      0.0       1.7       5.7  -97.48260  39.538479 1159321369        Q30
    ## 6      0.0       2.7       7.0   68.68555  49.054149 1159320967       Q232
    ##            name_ar         name_bn            name_de                  name_en
    ## 1             فيجي            ফিজি            Fidschi                     Fiji
    ## 2          تنزانيا       তানজানিয়া           Tansania                 Tanzania
    ## 3  الصحراء الغربية    পশ্চিম সাহারা         Westsahara           Western Sahara
    ## 4             كندا          কানাডা             Kanada                   Canada
    ## 5 الولايات المتحدة মার্কিন যুক্তরাষ্ট্র Vereinigte Staaten United States of America
    ## 6        كازاخستان       কাজাখস্তান         Kasachstan               Kazakhstan
    ##             name_es             name_fa           name_fr
    ## 1              Fiyi                فیجی             Fidji
    ## 2          Tanzania            تانزانیا          Tanzanie
    ## 3 Sahara Occidental          صحرای غربی Sahara occidental
    ## 4            Canadá              کانادا            Canada
    ## 5    Estados Unidos ایالات متحده آمریکا        États-Unis
    ## 6        Kazajistán            قزاقستان        Kazakhstan
    ##                       name_el      name_he          name_hi
    ## 1                       Φίτζι        פיג'י             फ़िजी
    ## 2                    Τανζανία       טנזניה          तंज़ानिया
    ## 3               Δυτική Σαχάρα סהרה המערבית     पश्चिमी सहारा
    ## 4                     Καναδάς         קנדה            कनाडा
    ## 5 Ηνωμένες Πολιτείες Αμερικής  ארצות הברית संयुक्त राज्य अमेरिका
    ## 6                   Καζακστάν       קזחסטן        कज़ाख़िस्तान
    ##                     name_hu         name_id               name_it
    ## 1           Fidzsi-szigetek            Fiji                  Figi
    ## 2                  Tanzánia        Tanzania              Tanzania
    ## 3            Nyugat-Szahara    Sahara Barat    Sahara Occidentale
    ## 4                    Kanada          Kanada                Canada
    ## 5 Amerikai Egyesült Államok Amerika Serikat Stati Uniti d'America
    ## 6                Kazahsztán      Kazakhstan            Kazakistan
    ##          name_ja    name_ko                      name_nl           name_pl
    ## 1       フィジー       피지                         Fiji             Fidżi
    ## 2     タンザニア   탄자니아                     Tanzania          Tanzania
    ## 3       西サハラ   서사하라            Westelijke Sahara  Sahara Zachodnia
    ## 4         カナダ     캐나다                       Canada            Kanada
    ## 5 アメリカ合衆国       미국 Verenigde Staten van Amerika Stany Zjednoczone
    ## 6   カザフスタン 카자흐스탄                   Kazachstan        Kazachstan
    ##          name_pt         name_ru    name_sv                     name_tr
    ## 1           Fiji           Фиджи       Fiji                        Fiji
    ## 2       Tanzânia        Танзания   Tanzania                    Tanzanya
    ## 3 Sara Ocidental Западная Сахара Västsahara                  Batı Sahra
    ## 4         Canadá          Канада     Kanada                      Kanada
    ## 5 Estados Unidos             США        USA Amerika Birleşik Devletleri
    ## 6    Cazaquistão       Казахстан  Kazakstan                  Kazakistan
    ##                   name_uk                name_ur    name_vi    name_zh name_zht
    ## 1                   Фіджі                    فجی       Fiji       斐济     斐濟
    ## 2                Танзанія                تنزانیہ   Tanzania   坦桑尼亚 坦尚尼亞
    ## 3          Західна Сахара            مغربی صحارا Tây Sahara   西撒哈拉 西撒哈拉
    ## 4                  Канада                 کینیڈا     Canada     加拿大   加拿大
    ## 5 Сполучені Штати Америки ریاستہائے متحدہ امریکا     Hoa Kỳ       美国     美國
    ## 6               Казахстан               قازقستان Kazakhstan 哈萨克斯坦   哈薩克
    ##           fclass_iso tlc_diff         fclass_tlc fclass_us    fclass_fr
    ## 1    Admin-0 country     <NA>    Admin-0 country      <NA>         <NA>
    ## 2    Admin-0 country     <NA>    Admin-0 country      <NA>         <NA>
    ## 3 Admin-0 dependency     <NA> Admin-0 dependency      <NA> Unrecognized
    ## 4    Admin-0 country     <NA>    Admin-0 country      <NA>         <NA>
    ## 5    Admin-0 country     <NA>    Admin-0 country      <NA>         <NA>
    ## 6    Admin-0 country     <NA>    Admin-0 country      <NA>         <NA>
    ##   fclass_ru fclass_es fclass_cn fclass_tw    fclass_in fclass_np fclass_pk
    ## 1      <NA>      <NA>      <NA>      <NA>         <NA>      <NA>      <NA>
    ## 2      <NA>      <NA>      <NA>      <NA>         <NA>      <NA>      <NA>
    ## 3      <NA>      <NA>      <NA>      <NA> Unrecognized      <NA>      <NA>
    ## 4      <NA>      <NA>      <NA>      <NA>         <NA>      <NA>      <NA>
    ## 5      <NA>      <NA>      <NA>      <NA>         <NA>      <NA>      <NA>
    ## 6      <NA>      <NA>      <NA>      <NA>         <NA>      <NA>      <NA>
    ##   fclass_de fclass_gb fclass_br fclass_il    fclass_ps    fclass_sa fclass_eg
    ## 1      <NA>      <NA>      <NA>      <NA>         <NA>         <NA>      <NA>
    ## 2      <NA>      <NA>      <NA>      <NA>         <NA>         <NA>      <NA>
    ## 3      <NA>      <NA>      <NA>      <NA> Unrecognized Unrecognized      <NA>
    ## 4      <NA>      <NA>      <NA>      <NA>         <NA>         <NA>      <NA>
    ## 5      <NA>      <NA>      <NA>      <NA>         <NA>         <NA>      <NA>
    ## 6      <NA>      <NA>      <NA>      <NA>         <NA>         <NA>      <NA>
    ##      fclass_ma fclass_pt fclass_ar fclass_jp fclass_ko fclass_vn    fclass_tr
    ## 1         <NA>      <NA>      <NA>      <NA>      <NA>      <NA>         <NA>
    ## 2         <NA>      <NA>      <NA>      <NA>      <NA>      <NA>         <NA>
    ## 3 Unrecognized      <NA>      <NA>      <NA>      <NA>      <NA> Unrecognized
    ## 4         <NA>      <NA>      <NA>      <NA>      <NA>      <NA>         <NA>
    ## 5         <NA>      <NA>      <NA>      <NA>      <NA>      <NA>         <NA>
    ## 6         <NA>      <NA>      <NA>      <NA>      <NA>      <NA>         <NA>
    ##      fclass_id    fclass_pl fclass_gr fclass_it    fclass_nl fclass_se
    ## 1         <NA>         <NA>      <NA>      <NA>         <NA>      <NA>
    ## 2         <NA>         <NA>      <NA>      <NA>         <NA>      <NA>
    ## 3 Unrecognized Unrecognized      <NA>      <NA> Unrecognized      <NA>
    ## 4         <NA>         <NA>      <NA>      <NA>         <NA>      <NA>
    ## 5         <NA>         <NA>      <NA>      <NA>         <NA>      <NA>
    ## 6         <NA>         <NA>      <NA>      <NA>         <NA>      <NA>
    ##   fclass_bd fclass_ua                       geometry
    ## 1      <NA>      <NA> MULTIPOLYGON (((180 -16.067...
    ## 2      <NA>      <NA> MULTIPOLYGON (((33.90371 -0...
    ## 3      <NA>      <NA> MULTIPOLYGON (((-8.66559 27...
    ## 4      <NA>      <NA> MULTIPOLYGON (((-122.84 49,...
    ## 5      <NA>      <NA> MULTIPOLYGON (((-122.84 49,...
    ## 6      <NA>      <NA> MULTIPOLYGON (((87.35997 49...

``` r
colnames(tinyCountries)
```

    ##   [1] "scalerank"  "featurecla" "sr_label_i" "sr_label_o" "LABELRANK" 
    ##   [6] "SOVEREIGNT" "SOV_A3"     "ADM0_DIF"   "LEVEL"      "TYPE"      
    ##  [11] "TLC"        "ADMIN"      "ADM0_A3"    "GEOU_DIF"   "GEOUNIT"   
    ##  [16] "GU_A3"      "SU_DIF"     "SUBUNIT"    "SU_A3"      "BRK_DIFF"  
    ##  [21] "NAME"       "NAME_LONG"  "BRK_A3"     "BRK_NAME"   "BRK_GROUP" 
    ##  [26] "ABBREV"     "POSTAL"     "FORMAL_EN"  "FORMAL_FR"  "NAME_CIAWF"
    ##  [31] "NOTE_ADM0"  "NOTE_BRK"   "NAME_SORT"  "NAME_ALT"   "MAPCOLOR7" 
    ##  [36] "MAPCOLOR8"  "MAPCOLOR9"  "MAPCOLOR13" "POP_EST"    "POP_RANK"  
    ##  [41] "POP_YEAR"   "GDP_MD"     "GDP_YEAR"   "ECONOMY"    "INCOME_GRP"
    ##  [46] "FIPS_10"    "ISO_A2"     "ISO_A2_EH"  "ISO_A3"     "ISO_A3_EH" 
    ##  [51] "ISO_N3"     "ISO_N3_EH"  "UN_A3"      "WB_A2"      "WB_A3"     
    ##  [56] "WOE_ID"     "WOE_ID_EH"  "WOE_NOTE"   "ADM0_ISO"   "ADM0_DIFF" 
    ##  [61] "ADM0_TLC"   "ADM0_A3_US" "ADM0_A3_FR" "ADM0_A3_RU" "ADM0_A3_ES"
    ##  [66] "ADM0_A3_CN" "ADM0_A3_TW" "ADM0_A3_IN" "ADM0_A3_NP" "ADM0_A3_PK"
    ##  [71] "ADM0_A3_DE" "ADM0_A3_GB" "ADM0_A3_BR" "ADM0_A3_IL" "ADM0_A3_PS"
    ##  [76] "ADM0_A3_SA" "ADM0_A3_EG" "ADM0_A3_MA" "ADM0_A3_PT" "ADM0_A3_AR"
    ##  [81] "ADM0_A3_JP" "ADM0_A3_KO" "ADM0_A3_VN" "ADM0_A3_TR" "ADM0_A3_ID"
    ##  [86] "ADM0_A3_PL" "ADM0_A3_GR" "ADM0_A3_IT" "ADM0_A3_NL" "ADM0_A3_SE"
    ##  [91] "ADM0_A3_BD" "ADM0_A3_UA" "ADM0_A3_UN" "ADM0_A3_WB" "CONTINENT" 
    ##  [96] "REGION_UN"  "SUBREGION"  "REGION_WB"  "NAME_LEN"   "LONG_LEN"  
    ## [101] "ABBREV_LEN" "TINY"       "HOMEPART"   "MIN_ZOOM"   "MIN_LABEL" 
    ## [106] "MAX_LABEL"  "LABEL_X"    "LABEL_Y"    "NE_ID"      "WIKIDATAID"
    ## [111] "NAME_AR"    "NAME_BN"    "NAME_DE"    "NAME_EN"    "NAME_ES"   
    ## [116] "NAME_FA"    "NAME_FR"    "NAME_EL"    "NAME_HE"    "NAME_HI"   
    ## [121] "NAME_HU"    "NAME_ID"    "NAME_IT"    "NAME_JA"    "NAME_KO"   
    ## [126] "NAME_NL"    "NAME_PL"    "NAME_PT"    "NAME_RU"    "NAME_SV"   
    ## [131] "NAME_TR"    "NAME_UK"    "NAME_UR"    "NAME_VI"    "NAME_ZH"   
    ## [136] "NAME_ZHT"   "FCLASS_ISO" "TLC_DIFF"   "FCLASS_TLC" "FCLASS_US" 
    ## [141] "FCLASS_FR"  "FCLASS_RU"  "FCLASS_ES"  "FCLASS_CN"  "FCLASS_TW" 
    ## [146] "FCLASS_IN"  "FCLASS_NP"  "FCLASS_PK"  "FCLASS_DE"  "FCLASS_GB" 
    ## [151] "FCLASS_BR"  "FCLASS_IL"  "FCLASS_PS"  "FCLASS_SA"  "FCLASS_EG" 
    ## [156] "FCLASS_MA"  "FCLASS_PT"  "FCLASS_AR"  "FCLASS_JP"  "FCLASS_KO" 
    ## [161] "FCLASS_VN"  "FCLASS_TR"  "FCLASS_ID"  "FCLASS_PL"  "FCLASS_GR" 
    ## [166] "FCLASS_IT"  "FCLASS_NL"  "FCLASS_SE"  "FCLASS_BD"  "FCLASS_UA" 
    ## [171] "geometry"

``` r
names_toKeep<-c("formal_en","name","name_long","name_en","name_es","name_pt","name_fr")
toupper(names_toKeep) %in% colnames(tinyCountries)
```

    ## [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE

``` r
countryNames<-Reduce(rbind,lapply(names_toKeep,function(x,t1,t2,t3){
  tab1<-data.frame(string=st_drop_geometry(t1[,x]),name=st_drop_geometry(t1["name"]),type=x)
  tab2<-data.frame(string=st_drop_geometry(t2[,toupper(x)]),name=st_drop_geometry(t2["NAME"]),type=x)
  if(x%in%colnames(t3)){
    tab3<-data.frame(string=st_drop_geometry(t3[,x]),name=st_drop_geometry(t3["name"]),type=x)
  }else{
    tab3<-data.frame(string=character(0),name=character(0),type=character(0))
  }
  colnames(tab1)<-colnames(tab2)<-colnames(tab3)<-c("string","name","type")
  return(rbind(tab1,tab2,tab3))},t1=worldMap_tot,t2=tinyCountries,t3=map_units50))
countryNames[!duplicated(countryNames$string),]
```

    ##                                                    string
    ## 1                                        Republic of Fiji
    ## 2                             United Republic of Tanzania
    ## 3                        Sahrawi Arab Democratic Republic
    ## 4                                                  Canada
    ## 5                                United States of America
    ## 6                                  Republic of Kazakhstan
    ## 7                                  Republic of Uzbekistan
    ## 8                   Independent State of Papua New Guinea
    ## 9                                   Republic of Indonesia
    ## 10                                     Argentine Republic
    ## 11                                      Republic of Chile
    ## 12                       Democratic Republic of the Congo
    ## 13                            Federal Republic of Somalia
    ## 14                                      Republic of Kenya
    ## 15                                  Republic of the Sudan
    ## 16                                       Republic of Chad
    ## 17                                      Republic of Haiti
    ## 18                                     Dominican Republic
    ## 19                                     Russian Federation
    ## 20                            Commonwealth of the Bahamas
    ## 21                                       Falkland Islands
    ## 22                                      Kingdom of Norway
    ## 23                                              Greenland
    ## 24   Territory of the French Southern and Antarctic Lands
    ## 25                     Democratic Republic of Timor-Leste
    ## 26                               Republic of South Africa
    ## 27                                     Kingdom of Lesotho
    ## 28                                  United Mexican States
    ## 29                           Oriental Republic of Uruguay
    ## 30                          Federative Republic of Brazil
    ## 31                         Plurinational State of Bolivia
    ## 32                                       Republic of Peru
    ## 33                                   Republic of Colombia
    ## 34                                     Republic of Panama
    ## 35                                 Republic of Costa Rica
    ## 36                                  Republic of Nicaragua
    ## 37                                   Republic of Honduras
    ## 38                                Republic of El Salvador
    ## 39                                  Republic of Guatemala
    ## 40                                                 Belize
    ## 41                       Bolivarian Republic of Venezuela
    ## 42                        Co-operative Republic of Guyana
    ## 43                                   Republic of Suriname
    ## 44                                        French Republic
    ## 45                                    Republic of Ecuador
    ## 46                            Commonwealth of Puerto Rico
    ## 47                                                Jamaica
    ## 48                                       Republic of Cuba
    ## 49                                   Republic of Zimbabwe
    ## 50                                   Republic of Botswana
    ## 51                                    Republic of Namibia
    ## 52                                    Republic of Senegal
    ## 53                                       Republic of Mali
    ## 54                         Islamic Republic of Mauritania
    ## 55                                      Republic of Benin
    ## 56                                      Republic of Niger
    ## 57                            Federal Republic of Nigeria
    ## 58                                   Republic of Cameroon
    ## 59                                      Togolese Republic
    ## 60                                      Republic of Ghana
    ## 61                                Republic of Ivory Coast
    ## 62                                     Republic of Guinea
    ## 63                              Republic of Guinea-Bissau
    ## 64                                    Republic of Liberia
    ## 65                               Republic of Sierra Leone
    ## 66                                           Burkina Faso
    ## 67                               Central African Republic
    ## 68                                  Republic of the Congo
    ## 69                                      Gabonese Republic
    ## 70                          Republic of Equatorial Guinea
    ## 71                                     Republic of Zambia
    ## 72                                     Republic of Malawi
    ## 73                                 Republic of Mozambique
    ## 74                                    Kingdom of eSwatini
    ## 75                            People's Republic of Angola
    ## 76                                    Republic of Burundi
    ## 77                                        State of Israel
    ## 78                                      Lebanese Republic
    ## 79                                 Republic of Madagascar
    ## 80                                     West Bank and Gaza
    ## 81                                 Republic of the Gambia
    ## 82                                    Republic of Tunisia
    ## 83                People's Democratic Republic of Algeria
    ## 84                            Hashemite Kingdom of Jordan
    ## 85                                   United Arab Emirates
    ## 86                                         State of Qatar
    ## 87                                        State of Kuwait
    ## 88                                       Republic of Iraq
    ## 89                                      Sultanate of Oman
    ## 90                                    Republic of Vanuatu
    ## 91                                    Kingdom of Cambodia
    ## 92                                    Kingdom of Thailand
    ## 93                       Lao People's Democratic Republic
    ## 94                       Republic of the Union of Myanmar
    ## 95                          Socialist Republic of Vietnam
    ## 96                  Democratic People's Republic of Korea
    ## 97                                      Republic of Korea
    ## 98                                               Mongolia
    ## 99                                      Republic of India
    ## 100                       People's Republic of Bangladesh
    ## 101                                     Kingdom of Bhutan
    ## 102                                                 Nepal
    ## 103                          Islamic Republic of Pakistan
    ## 104                          Islamic State of Afghanistan
    ## 105                                Republic of Tajikistan
    ## 106                                       Kyrgyz Republic
    ## 107                                          Turkmenistan
    ## 108                              Islamic Republic of Iran
    ## 109                                  Syrian Arab Republic
    ## 110                                   Republic of Armenia
    ## 111                                     Kingdom of Sweden
    ## 112                                   Republic of Belarus
    ## 113                                               Ukraine
    ## 114                                    Republic of Poland
    ## 115                                   Republic of Austria
    ## 116                                   Republic of Hungary
    ## 117                                   Republic of Moldova
    ## 118                                               Romania
    ## 119                                 Republic of Lithuania
    ## 120                                    Republic of Latvia
    ## 121                                   Republic of Estonia
    ## 122                           Federal Republic of Germany
    ## 123                                  Republic of Bulgaria
    ## 124                                     Hellenic Republic
    ## 125                                    Republic of Turkey
    ## 126                                   Republic of Albania
    ## 127                                   Republic of Croatia
    ## 128                                   Swiss Confederation
    ## 129                             Grand Duchy of Luxembourg
    ## 130                                    Kingdom of Belgium
    ## 131                            Kingdom of the Netherlands
    ## 132                                   Portuguese Republic
    ## 133                                      Kingdom of Spain
    ## 134                                               Ireland
    ## 135                                         New Caledonia
    ## 136                                                  <NA>
    ## 137                                           New Zealand
    ## 138                             Commonwealth of Australia
    ## 139            Democratic Socialist Republic of Sri Lanka
    ## 140                            People's Republic of China
    ## 142                                      Italian Republic
    ## 143                                    Kingdom of Denmark
    ## 144  United Kingdom of Great Britain and Northern Ireland
    ## 145                                   Republic of Iceland
    ## 146                                Republic of Azerbaijan
    ## 147                                               Georgia
    ## 148                           Republic of the Philippines
    ## 149                                              Malaysia
    ## 150                              Negara Brunei Darussalam
    ## 151                                  Republic of Slovenia
    ## 152                                   Republic of Finland
    ## 153                                       Slovak Republic
    ## 154                                        Czech Republic
    ## 155                                      State of Eritrea
    ## 156                                                 Japan
    ## 157                                  Republic of Paraguay
    ## 158                                     Republic of Yemen
    ## 159                               Kingdom of Saudi Arabia
    ## 161                   Turkish Republic of Northern Cyprus
    ## 162                                    Republic of Cyprus
    ## 163                                    Kingdom of Morocco
    ## 164                                Arab Republic of Egypt
    ## 165                                                 Libya
    ## 166               Federal Democratic Republic of Ethiopia
    ## 167                                  Republic of Djibouti
    ## 168                                Republic of Somaliland
    ## 169                                    Republic of Uganda
    ## 170                                    Republic of Rwanda
    ## 171                                Bosnia and Herzegovina
    ## 172                           Republic of North Macedonia
    ## 173                                    Republic of Serbia
    ## 174                                            Montenegro
    ## 175                                    Republic of Kosovo
    ## 176                       Republic of Trinidad and Tobago
    ## 177                               Republic of South Sudan
    ## 180                              Turks and Caicos Islands
    ## 182                            Independent State of Samoa
    ## 183                                      Kingdom of Tonga
    ## 184                                      French Polynesia
    ## 185           Pitcairn, Henderson, Ducie and Oeno Islands
    ## 186                                              Barbados
    ## 188          Democratic Republic of São Tomé and Principe
    ## 191                                     Republic of Malta
    ## 192                                    Kingdom of Bahrain
    ## 193                                  Republic of Maldives
    ## 195                                 Republic of Singapore
    ## 197                                     Republic of Palau
    ## 198          Commonwealth of the Northern Mariana Islands
    ## 199                                     Territory of Guam
    ## 200                        Federated States of Micronesia
    ## 201                      Republic of the Marshall Islands
    ## 202                                  Republic of Kiribati
    ## 203                                     Republic of Nauru
    ## 204                                                Tuvalu
    ## 205                                 Republic of Mauritius
    ## 206                                  Union of the Comoros
    ## 207                              Føroyar Is. (Faeroe Is.)
    ## 209                             Saint Pierre and Miquelon
    ## 210                          The Bermudas or Somers Isles
    ## 214                         South Georgia and the Islands
    ## 220                             State of the Vatican City
    ## 227                   Virgin Islands of the United States
    ## 229                                        American Samoa
    ## 238                                        Cayman Islands
    ## 240                                British Virgin Islands
    ## 243                                   Bailiwick of Jersey
    ## 244                                 Bailiwick of Guernsey
    ## 283                                Republic of Seychelles
    ## 289                                Republic of San Marino
    ## 291                      Saint Vincent and the Grenadines
    ## 292                                           Saint Lucia
    ## 293                   Federation of Saint Kitts and Nevis
    ## 305                                      Papua New Guinea
    ## 306                     Autonomous Region of Bougainville
    ## 323                                                 Aruba
    ## 324                     Bonaire, Sint Eustatius, and Saba
    ## 325                                               Curaçao
    ## 335                                Principality of Monaco
    ## 348                         Principality of Liechtenstein
    ## 366                                            Gaza Strip
    ## 367                                             West Bank
    ## 381                                               Grenada
    ## 388                                   Metropolitan France
    ## 389                                 Department of Mayotte
    ## 390                                 Department of Reunion
    ## 391                              Department of Martinique
    ## 392                              Department of Guadeloupe
    ## 393                                  Department of Guiana
    ## 395                             Wallis and Futuna Islands
    ## 396                            Saint-Martin (French part)
    ## 397                                      Saint-Barthélemy
    ## 401                                         Åland Islands
    ## 412                              Commonwealth of Dominica
    ## 429              Macao Special Administrative Region, PRC
    ## 430          Hong Kong Special Administrative Region, PRC
    ## 434                                Republic of Cabo Verde
    ## 451                                         Vlaams Gewest
    ## 452                                          Waals Gewest
    ## 453                        Brussels Hoofdstedelijk Gewest
    ## 462                         Territory of Christmas Island
    ## 463                  Territory of Cocos (Keeling) Islands
    ## 464        Territory of Heard Island and McDonald Islands
    ## 465                           Territory of Norfolk Island
    ## 466              Territory of Ashmore and Cartier Islands
    ## 472                               Principality of Andorra
    ## 478                             Sint Maarten (Dutch part)
    ## 480                                                  Fiji
    ## 481                                              Tanzania
    ## 482                                             W. Sahara
    ## 485                                            Kazakhstan
    ## 486                                            Uzbekistan
    ## 488                                             Indonesia
    ## 489                                             Argentina
    ## 490                                                 Chile
    ## 491                                       Dem. Rep. Congo
    ## 492                                               Somalia
    ## 493                                                 Kenya
    ## 494                                                 Sudan
    ## 495                                                  Chad
    ## 496                                                 Haiti
    ## 497                                        Dominican Rep.
    ## 498                                                Russia
    ## 499                                               Bahamas
    ## 500                                          Falkland Is.
    ## 501                                                Norway
    ## 503                                Fr. S. Antarctic Lands
    ## 504                                           Timor-Leste
    ## 505                                          South Africa
    ## 506                                               Lesotho
    ## 507                                                Mexico
    ## 508                                               Uruguay
    ## 509                                                Brazil
    ## 510                                               Bolivia
    ## 511                                                  Peru
    ## 512                                              Colombia
    ## 513                                                Panama
    ## 514                                            Costa Rica
    ## 515                                             Nicaragua
    ## 516                                              Honduras
    ## 517                                           El Salvador
    ## 518                                             Guatemala
    ## 520                                             Venezuela
    ## 521                                                Guyana
    ## 522                                              Suriname
    ## 523                                                France
    ## 524                                               Ecuador
    ## 525                                           Puerto Rico
    ## 527                                                  Cuba
    ## 528                                              Zimbabwe
    ## 529                                              Botswana
    ## 530                                               Namibia
    ## 531                                               Senegal
    ## 532                                                  Mali
    ## 533                                            Mauritania
    ## 534                                                 Benin
    ## 535                                                 Niger
    ## 536                                               Nigeria
    ## 537                                              Cameroon
    ## 538                                                  Togo
    ## 539                                                 Ghana
    ## 540                                         Côte d'Ivoire
    ## 541                                                Guinea
    ## 542                                         Guinea-Bissau
    ## 543                                               Liberia
    ## 544                                          Sierra Leone
    ## 546                                  Central African Rep.
    ## 547                                                 Congo
    ## 548                                                 Gabon
    ## 549                                            Eq. Guinea
    ## 550                                                Zambia
    ## 551                                                Malawi
    ## 552                                            Mozambique
    ## 553                                              eSwatini
    ## 554                                                Angola
    ## 555                                               Burundi
    ## 556                                                Israel
    ## 557                                               Lebanon
    ## 558                                            Madagascar
    ## 559                                             Palestine
    ## 560                                                Gambia
    ## 561                                               Tunisia
    ## 562                                               Algeria
    ## 563                                                Jordan
    ## 565                                                 Qatar
    ## 566                                                Kuwait
    ## 567                                                  Iraq
    ## 568                                                  Oman
    ## 569                                               Vanuatu
    ## 570                                              Cambodia
    ## 571                                              Thailand
    ## 572                                                  Laos
    ## 573                                               Myanmar
    ## 574                                               Vietnam
    ## 575                                           North Korea
    ## 576                                           South Korea
    ## 578                                                 India
    ## 579                                            Bangladesh
    ## 580                                                Bhutan
    ## 582                                              Pakistan
    ## 583                                           Afghanistan
    ## 584                                            Tajikistan
    ## 585                                            Kyrgyzstan
    ## 587                                                  Iran
    ## 588                                                 Syria
    ## 589                                               Armenia
    ## 590                                                Sweden
    ## 591                                               Belarus
    ## 593                                                Poland
    ## 594                                               Austria
    ## 595                                               Hungary
    ## 596                                               Moldova
    ## 598                                             Lithuania
    ## 599                                                Latvia
    ## 600                                               Estonia
    ## 601                                               Germany
    ## 602                                              Bulgaria
    ## 603                                                Greece
    ## 604                                                Turkey
    ## 605                                               Albania
    ## 606                                               Croatia
    ## 607                                           Switzerland
    ## 608                                            Luxembourg
    ## 609                                               Belgium
    ## 610                                           Netherlands
    ## 611                                              Portugal
    ## 612                                                 Spain
    ## 615                                           Solomon Is.
    ## 617                                             Australia
    ## 618                                             Sri Lanka
    ## 619                                                 China
    ## 620                                                Taiwan
    ## 621                                                 Italy
    ## 622                                               Denmark
    ## 623                                        United Kingdom
    ## 624                                               Iceland
    ## 625                                            Azerbaijan
    ## 627                                           Philippines
    ## 629                                                Brunei
    ## 630                                              Slovenia
    ## 631                                               Finland
    ## 632                                              Slovakia
    ## 633                                               Czechia
    ## 634                                               Eritrea
    ## 636                                              Paraguay
    ## 637                                                 Yemen
    ## 638                                          Saudi Arabia
    ## 639                                            Antarctica
    ## 640                                             N. Cyprus
    ## 641                                                Cyprus
    ## 642                                               Morocco
    ## 643                                                 Egypt
    ## 645                                              Ethiopia
    ## 646                                              Djibouti
    ## 647                                            Somaliland
    ## 648                                                Uganda
    ## 649                                                Rwanda
    ## 650                                      Bosnia and Herz.
    ## 651                                       North Macedonia
    ## 652                                                Serbia
    ## 654                                                Kosovo
    ## 655                                   Trinidad and Tobago
    ## 656                                              S. Sudan
    ## 659                                  Turks and Caicos Is.
    ## 660                                              Cook Is.
    ## 661                                                 Samoa
    ## 662                                                 Tonga
    ## 663                                         Fr. Polynesia
    ## 664                                          Pitcairn Is.
    ## 667                                 São Tomé and Principe
    ## 668                                             Ascension
    ## 669                                          Saint Helena
    ## 670                                                 Malta
    ## 671                                               Bahrain
    ## 672                                              Maldives
    ## 673                                 Br. Indian Ocean Ter.
    ## 674                                             Singapore
    ## 676                                                 Palau
    ## 677                                        N. Mariana Is.
    ## 678                                                  Guam
    ## 679                                            Micronesia
    ## 680                                          Marshall Is.
    ## 681                                              Kiribati
    ## 682                                                 Nauru
    ## 684                                             Mauritius
    ## 685                                               Comoros
    ## 686                                            Faeroe Is.
    ## 687                                          Jan Mayen I.
    ## 688                               St. Pierre and Miquelon
    ## 689                                               Bermuda
    ## 690                                                Azores
    ## 691                                            Canary Is.
    ## 692                                               Madeira
    ## 693                                   S. Geo. and the Is.
    ## 699                                               Vatican
    ## 706                                       U.S. Virgin Is.
    ## 715                                              Anguilla
    ## 717                                            Cayman Is.
    ## 719                                    British Virgin Is.
    ## 721                                            Montserrat
    ## 722                                                Jersey
    ## 723                                              Guernsey
    ## 724                                           Isle of Man
    ## 725                                                 Wales
    ## 726                                              Scotland
    ## 727                                            N. Ireland
    ## 728                                               England
    ## 740                                              Zanzibar
    ## 762                                            Seychelles
    ## 764                                             Vojvodina
    ## 768                                            San Marino
    ## 770                                    St. Vin. and Gren.
    ## 772                                   St. Kitts and Nevis
    ## 785                                          Bougainville
    ## 792                                          Svalbard Is.
    ## 798                                                  Niue
    ## 799                                               Tokelau
    ## 803                                 Caribbean Netherlands
    ## 814                                                Monaco
    ## 827                                         Liechtenstein
    ## 845                                                  Gaza
    ## 868                                               Mayotte
    ## 869                                               Réunion
    ## 870                                            Martinique
    ## 871                                            Guadeloupe
    ## 872                                         French Guiana
    ## 874                                 Wallis and Futuna Is.
    ## 875                                             St-Martin
    ## 876                                         St-Barthélemy
    ## 880                                                 Åland
    ## 891                                              Dominica
    ## 908                                                 Macao
    ## 909                                             Hong Kong
    ## 913                                            Cabo Verde
    ## 924                                           Rep. Srpska
    ## 925                                  Fed. of Bos. & Herz.
    ## 930                                               Flemish
    ## 931                                               Walloon
    ## 932                                              Brussels
    ## 941                                          Christmas I.
    ## 942                                             Cocos Is.
    ## 943                             Heard I. and McDonald Is.
    ## 944                                        Norfolk Island
    ## 945                               Ashmore and Cartier Is.
    ## 948                                               Antigua
    ## 949                                               Barbuda
    ## 951                                               Andorra
    ## 955                                       Siachen Glacier
    ## 957                                          Sint Maarten
    ## 961                                        Western Sahara
    ## 963                                         United States
    ## 979                           Falkland Islands / Malvinas
    ## 982                   French Southern and Antarctic Lands
    ## 1028                                    Equatorial Guinea
    ## 1039                                           The Gambia
    ## 1051                                              Lao PDR
    ## 1054                                      Dem. Rep. Korea
    ## 1094                                      Solomon Islands
    ## 1108                                    Brunei Darussalam
    ## 1119                                      Northern Cyprus
    ## 1135                                          South Sudan
    ## 1139                                         Cook Islands
    ## 1143                                     Pitcairn Islands
    ## 1152                       British Indian Ocean Territory
    ## 1156                             Northern Mariana Islands
    ## 1159                                     Marshall Islands
    ## 1165                                       Faeroe Islands
    ## 1166                                     Jan Mayen Island
    ## 1170                                       Canary Islands
    ## 1185                         United States Virgin Islands
    ## 1206                                     Northern Ireland
    ## 1251                                Saint Kitts and Nevis
    ## 1271                                     Svalbard Islands
    ## 1354                                         Saint-Martin
    ## 1403                                      Republic Srpska
    ## 1404                 Federation of Bosnia and Herzegovina
    ## 1409                                       Flemish Region
    ## 1410                                       Walloon Region
    ## 1420                                     Christmas Island
    ## 1421                                        Cocos Islands
    ## 1422                        Heard I. and McDonald Islands
    ## 1424                          Ashmore and Cartier Islands
    ## 1457                                          The Bahamas
    ## 1462                                           East Timor
    ## 1498                                          Ivory Coast
    ## 1511                                             Eswatini
    ## 1625                                São Tomé and Príncipe
    ## 1644                                        Faroe Islands
    ## 1645                                            Jan Mayen
    ## 1651         South Georgia and the South Sandwich Islands
    ## 1657                                         Vatican City
    ## 1750                                             Svalbard
    ## 1832                                    Wallis and Futuna
    ## 1833                                         Saint Martin
    ## 1834                                     Saint Barthélemy
    ## 1866                                                Macau
    ## 1871                                           Cape Verde
    ## 1882                                     Republika Srpska
    ## 1888                                      Flemish Brabant
    ## 1889                                      Walloon Brabant
    ## 1890                              Brussels Capital Region
    ## 1900                                                Cocos
    ## 1901                    Heard Island and McDonald Islands
    ## 1917                                                 Fiyi
    ## 1919                                    Sahara Occidental
    ## 1920                                               Canadá
    ## 1921                                       Estados Unidos
    ## 1922                                           Kazajistán
    ## 1923                                           Uzbekistán
    ## 1924                                   Papúa Nueva Guinea
    ## 1928                      República Democrática del Congo
    ## 1930                                                Kenia
    ## 1931                                                Sudán
    ## 1933                                                Haití
    ## 1934                                 República Dominicana
    ## 1935                                                Rusia
    ## 1937                                       Islas Malvinas
    ## 1938                                              Noruega
    ## 1939                                          Groenlandia
    ## 1940             Tierras Australes y Antárticas Francesas
    ## 1941                                       Timor Oriental
    ## 1942                                            Sudáfrica
    ## 1943                                               Lesoto
    ## 1944                                               México
    ## 1946                                               Brasil
    ## 1948                                                 Perú
    ## 1950                                               Panamá
    ## 1956                                               Belice
    ## 1959                                              Surinam
    ## 1960                                              Francia
    ## 1965                                             Zimbabue
    ## 1966                                             Botsuana
    ## 1969                                                 Malí
    ## 1971                                                Benín
    ## 1972                                                Níger
    ## 1974                                              Camerún
    ## 1977                                      Costa de Marfil
    ## 1979                                         Guinea-Bisáu
    ## 1981                                         Sierra Leona
    ## 1983                             República Centroafricana
    ## 1984                                  República del Congo
    ## 1985                                                Gabón
    ## 1986                                    Guinea Ecuatorial
    ## 1988                                               Malaui
    ## 1990                                          Suazilandia
    ## 1994                                               Líbano
    ## 1996                                            Palestina
    ## 1998                                                Túnez
    ## 1999                                              Argelia
    ## 2000                                             Jordania
    ## 2001                               Emiratos Árabes Unidos
    ## 2002                                                Catar
    ## 2004                                                 Irak
    ## 2005                                                 Omán
    ## 2007                                              Camboya
    ## 2008                                            Tailandia
    ## 2010                                             Birmania
    ## 2012                                      Corea del Norte
    ## 2013                                        Corea del Sur
    ## 2016                                            Bangladés
    ## 2017                                                Bután
    ## 2019                                             Pakistán
    ## 2020                                           Afganistán
    ## 2021                                           Tayikistán
    ## 2022                                           Kirguistán
    ## 2023                                         Turkmenistán
    ## 2024                                                 Irán
    ## 2025                                                Siria
    ## 2027                                               Suecia
    ## 2028                                          Bielorrusia
    ## 2029                                              Ucrania
    ## 2030                                              Polonia
    ## 2032                                              Hungría
    ## 2033                                             Moldavia
    ## 2034                                              Rumania
    ## 2035                                             Lituania
    ## 2036                                              Letonia
    ## 2038                                             Alemania
    ## 2040                                               Grecia
    ## 2041                                              Turquía
    ## 2043                                              Croacia
    ## 2044                                                Suiza
    ## 2045                                           Luxemburgo
    ## 2046                                              Bélgica
    ## 2047                                         Países Bajos
    ## 2049                                               España
    ## 2050                                              Irlanda
    ## 2051                                      Nueva Caledonia
    ## 2052                                        Islas Salomón
    ## 2053                                        Nueva Zelanda
    ## 2057                                   República de China
    ## 2058                                               Italia
    ## 2059                                            Dinamarca
    ## 2060                                          Reino Unido
    ## 2061                                             Islandia
    ## 2062                                           Azerbaiyán
    ## 2064                                            Filipinas
    ## 2065                                              Malasia
    ## 2066                                               Brunéi
    ## 2067                                            Eslovenia
    ## 2068                                            Finlandia
    ## 2069                                           Eslovaquia
    ## 2070                                      República Checa
    ## 2072                                                Japón
    ## 2075                                       Arabia Saudita
    ## 2076                                            Antártida
    ## 2077                  República Turca del Norte de Chipre
    ## 2078                                               Chipre
    ## 2079                                            Marruecos
    ## 2080                                               Egipto
    ## 2081                                                Libia
    ## 2082                                              Etiopía
    ## 2083                                               Yibuti
    ## 2084                                         Somalilandia
    ## 2086                                               Ruanda
    ## 2087                                 Bosnia y Herzegovina
    ## 2088                                  Macedonia del Norte
    ## 2092                                    Trinidad y Tobago
    ## 2093                                        Sudán del Sur
    ## 2096                                Islas Turcas y Caicos
    ## 2097                                           Islas Cook
    ## 2100                                   Polinesia Francesa
    ## 2101                                       Islas Pitcairn
    ## 2104                                Santo Tomé y Príncipe
    ## 2105                                       Isla Ascensión
    ## 2106                                     Isla Santa Elena
    ## 2108                                               Baréin
    ## 2109                                             Maldivas
    ## 2110               Territorio Británico del Océano Índico
    ## 2111                                             Singapur
    ## 2113                                               Palaos
    ## 2114                             Islas Marianas del Norte
    ## 2116                      Estados Federados de Micronesia
    ## 2117                                       Islas Marshall
    ## 2121                                             Mauricio
    ## 2122                                              Comoras
    ## 2123                                          Islas Feroe
    ## 2125                                 San Pedro y Miquelón
    ## 2126                                             Bermudas
    ## 2128                                             Canarias
    ## 2130            Islas Georgias del Sur y Sandwich del Sur
    ## 2136                                  Ciudad del Vaticano
    ## 2143                 Islas Vírgenes de los Estados Unidos
    ## 2145                                 Samoa Estadounidense
    ## 2152                                              Anguila
    ## 2154                                         Islas Caimán
    ## 2156                            Islas Vírgenes Británicas
    ## 2161                                          Isla de Man
    ## 2162                                                Gales
    ## 2163                                              Escocia
    ## 2164                                    Irlanda del Norte
    ## 2165                                           Inglaterra
    ## 2177                                             Zanzíbar
    ## 2201                                            Voivodina
    ## 2207                         San Vicente y las Granadinas
    ## 2208                                          Santa Lucía
    ## 2209                               San Cristóbal y Nieves
    ## 2240                                    Caribe neerlandés
    ## 2241                                              Curazao
    ## 2251                                               Mónaco
    ## 2282                                       Franja de Gaza
    ## 2283                                          Cisjordania
    ## 2297                                              Granada
    ## 2306                                              Reunión
    ## 2307                                            Martinica
    ## 2308                                            Guadalupe
    ## 2309                                     Guayana Francesa
    ## 2311                                      Wallis y Futuna
    ## 2312                                           San Martín
    ## 2313                                        San Bartolomé
    ## 2361                                     República Srpska
    ## 2362                   Federación de Bosnia y Herzegovina
    ## 2367                                    Brabante Flamenco
    ## 2368                         Provincia del Brabante Valón
    ## 2369                           Región de Bruselas-Capital
    ## 2378                                      Isla de Navidad
    ## 2379                                          islas Cocos
    ## 2380                               Islas Heard y McDonald
    ## 2381                                         Isla Norfolk
    ## 2382                              Islas Ashmore y Cartier
    ## 2385                                         Isla Antigua
    ## 2392                                   Glaciar de Siachen
    ## 2397                                             Tanzânia
    ## 2398                                       Sara Ocidental
    ## 2401                                          Cazaquistão
    ## 2402                                          Uzbequistão
    ## 2403                                     Papua-Nova Guiné
    ## 2404                                            Indonésia
    ## 2407                       República Democrática do Congo
    ## 2408                                              Somália
    ## 2409                                               Quénia
    ## 2410                                                Sudão
    ## 2411                                                Chade
    ## 2414                                               Rússia
    ## 2416                                       Ilhas Malvinas
    ## 2418                                          Groenlândia
    ## 2419               Terras Austrais e Antárticas Francesas
    ## 2421                                        África do Sul
    ## 2424                                              Uruguai
    ## 2426                                              Bolívia
    ## 2428                                             Colômbia
    ## 2431                                            Nicarágua
    ## 2437                                               Guiana
    ## 2439                                               França
    ## 2440                                              Equador
    ## 2441                                           Porto Rico
    ## 2444                                             Zimbábue
    ## 2446                                              Namíbia
    ## 2449                                           Mauritânia
    ## 2450                                                Benim
    ## 2452                                              Nigéria
    ## 2453                                             Camarões
    ## 2455                                                 Gana
    ## 2456                                      Costa do Marfim
    ## 2457                                                Guiné
    ## 2458                                         Guiné-Bissau
    ## 2459                                              Libéria
    ## 2460                                           Serra Leoa
    ## 2462                            República Centro-Africana
    ## 2463                                   República do Congo
    ## 2464                                                Gabão
    ## 2465                                     Guiné Equatorial
    ## 2466                                               Zâmbia
    ## 2468                                           Moçambique
    ## 2469                                            Essuatíni
    ## 2474                                           Madagáscar
    ## 2476                                               Gâmbia
    ## 2477                                              Tunísia
    ## 2478                                              Argélia
    ## 2479                                             Jordânia
    ## 2480                               Emirados Árabes Unidos
    ## 2483                                               Iraque
    ## 2484                                                  Omã
    ## 2486                                              Camboja
    ## 2487                                            Tailândia
    ## 2490                                             Vietname
    ## 2491                                      Coreia do Norte
    ## 2492                                        Coreia do Sul
    ## 2493                                             Mongólia
    ## 2494                                                Índia
    ## 2496                                                Butão
    ## 2498                                            Paquistão
    ## 2499                                          Afeganistão
    ## 2500                                          Tajiquistão
    ## 2501                                          Quirguistão
    ## 2502                                       Turquemenistão
    ## 2503                                                 Irão
    ## 2504                                                Síria
    ## 2505                                              Arménia
    ## 2506                                               Suécia
    ## 2507                                         Bielorrússia
    ## 2508                                              Ucrânia
    ## 2509                                              Polónia
    ## 2510                                              Áustria
    ## 2511                                              Hungria
    ## 2512                                             Moldávia
    ## 2513                                              Roménia
    ## 2514                                             Lituânia
    ## 2515                                              Letónia
    ## 2516                                              Estónia
    ## 2517                                             Alemanha
    ## 2518                                             Bulgária
    ## 2519                                               Grécia
    ## 2520                                              Turquia
    ## 2521                                              Albânia
    ## 2522                                              Croácia
    ## 2523                                                Suíça
    ## 2526                                        Países Baixos
    ## 2528                                              Espanha
    ## 2529                                 República da Irlanda
    ## 2530                                       Nova Caledónia
    ## 2531                                        Ilhas Salomão
    ## 2532                                        Nova Zelândia
    ## 2533                                            Austrália
    ## 2537                                               Itália
    ## 2540                                             Islândia
    ## 2541                                           Azerbaijão
    ## 2542                                              Geórgia
    ## 2544                                              Malásia
    ## 2546                                            Eslovénia
    ## 2547                                            Finlândia
    ## 2548                                           Eslováquia
    ## 2549                                              Chéquia
    ## 2550                                             Eritreia
    ## 2551                                                Japão
    ## 2552                                             Paraguai
    ## 2553                                                Iémen
    ## 2554                                       Arábia Saudita
    ## 2556                   República Turca do Chipre do Norte
    ## 2558                                             Marrocos
    ## 2559                                                Egito
    ## 2560                                                Líbia
    ## 2561                                              Etiópia
    ## 2563                                         Somalilândia
    ## 2566                                 Bósnia e Herzegovina
    ## 2567                                   Macedónia do Norte
    ## 2568                                               Sérvia
    ## 2571                                    Trinidad e Tobago
    ## 2572                                         Sudão do Sul
    ## 2575                                       Turks e Caicos
    ## 2576                                           Ilhas Cook
    ## 2579                                   Polinésia Francesa
    ## 2580                                       Ilhas Pitcairn
    ## 2583                                  São Tomé e Príncipe
    ## 2584                                     Ilha de Ascensão
    ## 2585                                         Santa Helena
    ## 2587                                              Bahrein
    ## 2589                Território Britânico do Oceano Índico
    ## 2590                                            Singapura
    ## 2593                              Ilhas Marianas do Norte
    ## 2595                                           Micronésia
    ## 2596                                       Ilhas Marshall
    ## 2600                                             Maurícia
    ## 2601                                              Comores
    ## 2602                                          Ilhas Feroe
    ## 2604                              Saint-Pierre e Miquelon
    ## 2606                           Região Autónoma dos Açores
    ## 2607                                             Canárias
    ## 2608                           Região Autónoma da Madeira
    ## 2609               Ilhas Geórgia do Sul e Sandwich do Sul
    ## 2615                                             Vaticano
    ## 2622                             Ilhas Virgens Americanas
    ## 2624                                      Samoa Americana
    ## 2633                                         Ilhas Caimão
    ## 2635                             Ilhas Virgens Britânicas
    ## 2640                                          Ilha de Man
    ## 2641                                        País de Gales
    ## 2642                                              Escócia
    ## 2643                                     Irlanda do Norte
    ## 2686                             São Vicente e Granadinas
    ## 2687                                          Santa Lúcia
    ## 2688                                São Cristóvão e Nevis
    ## 2719                             Países Baixos Caribenhos
    ## 2761                                        Faixa de Gaza
    ## 2762                                          Cisjordânia
    ## 2785                                              Reunião
    ## 2788                                      Guiana Francesa
    ## 2790                                      Wallis e Futuna
    ## 2791                                         São Martinho
    ## 2792                       Coletividade de São Bartolomeu
    ## 2840                                     República Sérvia
    ## 2841                    Federação da Bósnia e Herzegovina
    ## 2846                                    Brabante Flamengo
    ## 2847                                       Brabante Valão
    ## 2848                           Região de Bruxelas-Capital
    ## 2857                                       Ilha Christmas
    ## 2858                                          Ilhas Cocos
    ## 2859                          Ilha Heard e Ilhas McDonald
    ## 2860                                         Ilha Norfolk
    ## 2861                              Ilhas Ashmore e Cartier
    ## 2864                                              Antígua
    ## 2875                                                Fidji
    ## 2876                                             Tanzanie
    ## 2877                                    Sahara occidental
    ## 2879                                           États-Unis
    ## 2881                                          Ouzbékistan
    ## 2882                            Papouasie-Nouvelle-Guinée
    ## 2883                                            Indonésie
    ## 2884                                            Argentine
    ## 2885                                                Chili
    ## 2886                     République démocratique du Congo
    ## 2887                                              Somalie
    ## 2889                                               Soudan
    ## 2890                                                Tchad
    ## 2891                                                Haïti
    ## 2892                               République dominicaine
    ## 2893                                               Russie
    ## 2895                                       îles Malouines
    ## 2896                                              Norvège
    ## 2897                                            Groenland
    ## 2898          Terres australes et antarctiques françaises
    ## 2899                                       Timor oriental
    ## 2900                                       Afrique du Sud
    ## 2902                                              Mexique
    ## 2904                                               Brésil
    ## 2905                                              Bolivie
    ## 2906                                                Pérou
    ## 2907                                             Colombie
    ## 2912                                             Salvador
    ## 2919                                             Équateur
    ## 2921                                             Jamaïque
    ## 2925                                              Namibie
    ## 2926                                              Sénégal
    ## 2928                                           Mauritanie
    ## 2929                                                Bénin
    ## 2932                                             Cameroun
    ## 2936                                               Guinée
    ## 2937                                        Guinée-Bissau
    ## 2941                            République centrafricaine
    ## 2942                                  République du Congo
    ## 2944                                   Guinée équatoriale
    ## 2945                                               Zambie
    ## 2951                                               Israël
    ## 2952                                                Liban
    ## 2955                                               Gambie
    ## 2956                                              Tunisie
    ## 2957                                              Algérie
    ## 2958                                             Jordanie
    ## 2959                                  Émirats arabes unis
    ## 2961                                               Koweït
    ## 2965                                             Cambodge
    ## 2966                                            Thaïlande
    ## 2968                                             Birmanie
    ## 2969                                             Viêt Nam
    ## 2970                                        Corée du Nord
    ## 2971                                         Corée du Sud
    ## 2972                                             Mongolie
    ## 2973                                                 Inde
    ## 2975                                              Bhoutan
    ## 2976                                                Népal
    ## 2979                                          Tadjikistan
    ## 2980                                         Kirghizistan
    ## 2981                                         Turkménistan
    ## 2983                                                Syrie
    ## 2984                                              Arménie
    ## 2985                                                Suède
    ## 2986                                          Biélorussie
    ## 2988                                              Pologne
    ## 2989                                             Autriche
    ## 2990                                              Hongrie
    ## 2991                                             Moldavie
    ## 2992                                             Roumanie
    ## 2993                                             Lituanie
    ## 2994                                             Lettonie
    ## 2995                                              Estonie
    ## 2996                                            Allemagne
    ## 2997                                             Bulgarie
    ## 2998                                                Grèce
    ## 2999                                              Turquie
    ## 3000                                              Albanie
    ## 3001                                              Croatie
    ## 3002                                               Suisse
    ## 3004                                             Belgique
    ## 3005                                             Pays-Bas
    ## 3007                                              Espagne
    ## 3008                                              Irlande
    ## 3009                                   Nouvelle-Calédonie
    ## 3010                                         Îles Salomon
    ## 3011                                     Nouvelle-Zélande
    ## 3012                                            Australie
    ## 3014                        République populaire de Chine
    ## 3015                                               Taïwan
    ## 3016                                               Italie
    ## 3017                                             Danemark
    ## 3018                                          Royaume-Uni
    ## 3019                                              Islande
    ## 3020                                          Azerbaïdjan
    ## 3021                                              Géorgie
    ## 3023                                             Malaisie
    ## 3025                                             Slovénie
    ## 3026                                             Finlande
    ## 3027                                            Slovaquie
    ## 3028                                             Tchéquie
    ## 3029                                             Érythrée
    ## 3030                                                Japon
    ## 3032                                                Yémen
    ## 3033                                      Arabie saoudite
    ## 3034                                          Antarctique
    ## 3035                                       Chypre du Nord
    ## 3036                                               Chypre
    ## 3037                                                Maroc
    ## 3038                                               Égypte
    ## 3039                                                Libye
    ## 3040                                             Éthiopie
    ## 3043                                              Ouganda
    ## 3045                                   Bosnie-Herzégovine
    ## 3046                                    Macédoine du Nord
    ## 3047                                               Serbie
    ## 3048                                           Monténégro
    ## 3050                                    Trinité-et-Tobago
    ## 3051                                        Soudan du Sud
    ## 3054                              îles Turques-et-Caïques
    ## 3055                                            Îles Cook
    ## 3058                                  Polynésie française
    ## 3059                                        Iles Pitcairn
    ## 3060                                              Barbade
    ## 3062                                 Sao Tomé-et-Principe
    ## 3063                                   île de l'Ascension
    ## 3064                                        Sainte-Hélène
    ## 3065                                                Malte
    ## 3066                                              Bahreïn
    ## 3068             Territoire britannique de l’océan Indien
    ## 3069                                            Singapour
    ## 3072                               îles Mariannes du Nord
    ## 3074                          États fédérés de Micronésie
    ## 3075                                        Îles Marshall
    ## 3079                                              Maurice
    ## 3081                                           îles Féroé
    ## 3083                             Saint-Pierre-et-Miquelon
    ## 3084                                             Bermudes
    ## 3085                                               Açores
    ## 3086                                        Îles Canaries
    ## 3087                                               Madère
    ## 3088           Géorgie du Sud-et-les Îles Sandwich du Sud
    ## 3094                                      Cité du Vatican
    ## 3101                          îles Vierges des États-Unis
    ## 3103                                    Samoa américaines
    ## 3112                                         îles Caïmans
    ## 3114                            îles Vierges britanniques
    ## 3118                                            Guernesey
    ## 3119                                           île de Man
    ## 3120                                       pays de Galles
    ## 3121                                               Écosse
    ## 3122                                      Irlande du Nord
    ## 3123                                           Angleterre
    ## 3159                                            Voïvodine
    ## 3163                                          Saint-Marin
    ## 3165                      Saint-Vincent-et-les-Grenadines
    ## 3166                                         Sainte-Lucie
    ## 3167                           Saint-Christophe-et-Niévès
    ## 3198                                   Pays-Bas caribéens
    ## 3240                                        bande de Gaza
    ## 3241                                          Cisjordanie
    ## 3255                                              Grenade
    ## 3264                                           La Réunion
    ## 3267                                               Guyane
    ## 3269                                     Wallis-et-Futuna
    ## 3286                                            Dominique
    ## 3308                                             Cap-Vert
    ## 3319                           République serbe de Bosnie
    ## 3320                  Fédération de Bosnie-et-Herzégovine
    ## 3325                                      Brabant flamand
    ## 3326                                       Brabant wallon
    ## 3327                         Région de Bruxelles-Capitale
    ## 3336                                        île Christmas
    ## 3337                                           îles Cocos
    ## 3338                              îles Heard-et-MacDonald
    ## 3339                                          Île Norfolk
    ## 3340                              Îles Ashmore-et-Cartier
    ## 3346                                              Andorre
    ## 3350                                   glacier de Siachen
    ##                           name      type
    ## 1                         Fiji formal_en
    ## 2                     Tanzania formal_en
    ## 3                    W. Sahara formal_en
    ## 4                       Canada formal_en
    ## 5     United States of America formal_en
    ## 6                   Kazakhstan formal_en
    ## 7                   Uzbekistan formal_en
    ## 8             Papua New Guinea formal_en
    ## 9                    Indonesia formal_en
    ## 10                   Argentina formal_en
    ## 11                       Chile formal_en
    ## 12             Dem. Rep. Congo formal_en
    ## 13                     Somalia formal_en
    ## 14                       Kenya formal_en
    ## 15                       Sudan formal_en
    ## 16                        Chad formal_en
    ## 17                       Haiti formal_en
    ## 18              Dominican Rep. formal_en
    ## 19                      Russia formal_en
    ## 20                     Bahamas formal_en
    ## 21                Falkland Is. formal_en
    ## 22                      Norway formal_en
    ## 23                   Greenland formal_en
    ## 24      Fr. S. Antarctic Lands formal_en
    ## 25                 Timor-Leste formal_en
    ## 26                South Africa formal_en
    ## 27                     Lesotho formal_en
    ## 28                      Mexico formal_en
    ## 29                     Uruguay formal_en
    ## 30                      Brazil formal_en
    ## 31                     Bolivia formal_en
    ## 32                        Peru formal_en
    ## 33                    Colombia formal_en
    ## 34                      Panama formal_en
    ## 35                  Costa Rica formal_en
    ## 36                   Nicaragua formal_en
    ## 37                    Honduras formal_en
    ## 38                 El Salvador formal_en
    ## 39                   Guatemala formal_en
    ## 40                      Belize formal_en
    ## 41                   Venezuela formal_en
    ## 42                      Guyana formal_en
    ## 43                    Suriname formal_en
    ## 44                      France formal_en
    ## 45                     Ecuador formal_en
    ## 46                 Puerto Rico formal_en
    ## 47                     Jamaica formal_en
    ## 48                        Cuba formal_en
    ## 49                    Zimbabwe formal_en
    ## 50                    Botswana formal_en
    ## 51                     Namibia formal_en
    ## 52                     Senegal formal_en
    ## 53                        Mali formal_en
    ## 54                  Mauritania formal_en
    ## 55                       Benin formal_en
    ## 56                       Niger formal_en
    ## 57                     Nigeria formal_en
    ## 58                    Cameroon formal_en
    ## 59                        Togo formal_en
    ## 60                       Ghana formal_en
    ## 61               Côte d'Ivoire formal_en
    ## 62                      Guinea formal_en
    ## 63               Guinea-Bissau formal_en
    ## 64                     Liberia formal_en
    ## 65                Sierra Leone formal_en
    ## 66                Burkina Faso formal_en
    ## 67        Central African Rep. formal_en
    ## 68                       Congo formal_en
    ## 69                       Gabon formal_en
    ## 70                  Eq. Guinea formal_en
    ## 71                      Zambia formal_en
    ## 72                      Malawi formal_en
    ## 73                  Mozambique formal_en
    ## 74                    eSwatini formal_en
    ## 75                      Angola formal_en
    ## 76                     Burundi formal_en
    ## 77                      Israel formal_en
    ## 78                     Lebanon formal_en
    ## 79                  Madagascar formal_en
    ## 80                   Palestine formal_en
    ## 81                      Gambia formal_en
    ## 82                     Tunisia formal_en
    ## 83                     Algeria formal_en
    ## 84                      Jordan formal_en
    ## 85        United Arab Emirates formal_en
    ## 86                       Qatar formal_en
    ## 87                      Kuwait formal_en
    ## 88                        Iraq formal_en
    ## 89                        Oman formal_en
    ## 90                     Vanuatu formal_en
    ## 91                    Cambodia formal_en
    ## 92                    Thailand formal_en
    ## 93                        Laos formal_en
    ## 94                     Myanmar formal_en
    ## 95                     Vietnam formal_en
    ## 96                 North Korea formal_en
    ## 97                 South Korea formal_en
    ## 98                    Mongolia formal_en
    ## 99                       India formal_en
    ## 100                 Bangladesh formal_en
    ## 101                     Bhutan formal_en
    ## 102                      Nepal formal_en
    ## 103                   Pakistan formal_en
    ## 104                Afghanistan formal_en
    ## 105                 Tajikistan formal_en
    ## 106                 Kyrgyzstan formal_en
    ## 107               Turkmenistan formal_en
    ## 108                       Iran formal_en
    ## 109                      Syria formal_en
    ## 110                    Armenia formal_en
    ## 111                     Sweden formal_en
    ## 112                    Belarus formal_en
    ## 113                    Ukraine formal_en
    ## 114                     Poland formal_en
    ## 115                    Austria formal_en
    ## 116                    Hungary formal_en
    ## 117                    Moldova formal_en
    ## 118                    Romania formal_en
    ## 119                  Lithuania formal_en
    ## 120                     Latvia formal_en
    ## 121                    Estonia formal_en
    ## 122                    Germany formal_en
    ## 123                   Bulgaria formal_en
    ## 124                     Greece formal_en
    ## 125                     Turkey formal_en
    ## 126                    Albania formal_en
    ## 127                    Croatia formal_en
    ## 128                Switzerland formal_en
    ## 129                 Luxembourg formal_en
    ## 130                    Belgium formal_en
    ## 131                Netherlands formal_en
    ## 132                   Portugal formal_en
    ## 133                      Spain formal_en
    ## 134                    Ireland formal_en
    ## 135              New Caledonia formal_en
    ## 136                Solomon Is. formal_en
    ## 137                New Zealand formal_en
    ## 138                  Australia formal_en
    ## 139                  Sri Lanka formal_en
    ## 140                      China formal_en
    ## 142                      Italy formal_en
    ## 143                    Denmark formal_en
    ## 144             United Kingdom formal_en
    ## 145                    Iceland formal_en
    ## 146                 Azerbaijan formal_en
    ## 147                    Georgia formal_en
    ## 148                Philippines formal_en
    ## 149                   Malaysia formal_en
    ## 150                     Brunei formal_en
    ## 151                   Slovenia formal_en
    ## 152                    Finland formal_en
    ## 153                   Slovakia formal_en
    ## 154                    Czechia formal_en
    ## 155                    Eritrea formal_en
    ## 156                      Japan formal_en
    ## 157                   Paraguay formal_en
    ## 158                      Yemen formal_en
    ## 159               Saudi Arabia formal_en
    ## 161                  N. Cyprus formal_en
    ## 162                     Cyprus formal_en
    ## 163                    Morocco formal_en
    ## 164                      Egypt formal_en
    ## 165                      Libya formal_en
    ## 166                   Ethiopia formal_en
    ## 167                   Djibouti formal_en
    ## 168                 Somaliland formal_en
    ## 169                     Uganda formal_en
    ## 170                     Rwanda formal_en
    ## 171           Bosnia and Herz. formal_en
    ## 172            North Macedonia formal_en
    ## 173                     Serbia formal_en
    ## 174                 Montenegro formal_en
    ## 175                     Kosovo formal_en
    ## 176        Trinidad and Tobago formal_en
    ## 177                   S. Sudan formal_en
    ## 180       Turks and Caicos Is. formal_en
    ## 182                      Samoa formal_en
    ## 183                      Tonga formal_en
    ## 184              Fr. Polynesia formal_en
    ## 185               Pitcairn Is. formal_en
    ## 186                   Barbados formal_en
    ## 188      São Tomé and Principe formal_en
    ## 191                      Malta formal_en
    ## 192                    Bahrain formal_en
    ## 193                   Maldives formal_en
    ## 195                  Singapore formal_en
    ## 197                      Palau formal_en
    ## 198             N. Mariana Is. formal_en
    ## 199                       Guam formal_en
    ## 200                 Micronesia formal_en
    ## 201               Marshall Is. formal_en
    ## 202                   Kiribati formal_en
    ## 203                      Nauru formal_en
    ## 204                     Tuvalu formal_en
    ## 205                  Mauritius formal_en
    ## 206                    Comoros formal_en
    ## 207                 Faeroe Is. formal_en
    ## 209    St. Pierre and Miquelon formal_en
    ## 210                    Bermuda formal_en
    ## 214        S. Geo. and the Is. formal_en
    ## 220                    Vatican formal_en
    ## 227            U.S. Virgin Is. formal_en
    ## 229             American Samoa formal_en
    ## 238                 Cayman Is. formal_en
    ## 240         British Virgin Is. formal_en
    ## 243                     Jersey formal_en
    ## 244                   Guernsey formal_en
    ## 283                 Seychelles formal_en
    ## 289                 San Marino formal_en
    ## 291         St. Vin. and Gren. formal_en
    ## 292                Saint Lucia formal_en
    ## 293        St. Kitts and Nevis formal_en
    ## 305           Papua New Guinea formal_en
    ## 306               Bougainville formal_en
    ## 323                      Aruba formal_en
    ## 324      Caribbean Netherlands formal_en
    ## 325                    Curaçao formal_en
    ## 335                     Monaco formal_en
    ## 348              Liechtenstein formal_en
    ## 366                       Gaza formal_en
    ## 367                  West Bank formal_en
    ## 381                    Grenada formal_en
    ## 388                     France formal_en
    ## 389                    Mayotte formal_en
    ## 390                    Réunion formal_en
    ## 391                 Martinique formal_en
    ## 392                 Guadeloupe formal_en
    ## 393              French Guiana formal_en
    ## 395      Wallis and Futuna Is. formal_en
    ## 396                  St-Martin formal_en
    ## 397              St-Barthélemy formal_en
    ## 401                      Åland formal_en
    ## 412                   Dominica formal_en
    ## 429                      Macao formal_en
    ## 430                  Hong Kong formal_en
    ## 434                 Cabo Verde formal_en
    ## 451                    Flemish formal_en
    ## 452                    Walloon formal_en
    ## 453                   Brussels formal_en
    ## 462               Christmas I. formal_en
    ## 463                  Cocos Is. formal_en
    ## 464  Heard I. and McDonald Is. formal_en
    ## 465             Norfolk Island formal_en
    ## 466    Ashmore and Cartier Is. formal_en
    ## 472                    Andorra formal_en
    ## 478               Sint Maarten formal_en
    ## 480                       Fiji      name
    ## 481                   Tanzania      name
    ## 482                  W. Sahara      name
    ## 485                 Kazakhstan      name
    ## 486                 Uzbekistan      name
    ## 488                  Indonesia      name
    ## 489                  Argentina      name
    ## 490                      Chile      name
    ## 491            Dem. Rep. Congo      name
    ## 492                    Somalia      name
    ## 493                      Kenya      name
    ## 494                      Sudan      name
    ## 495                       Chad      name
    ## 496                      Haiti      name
    ## 497             Dominican Rep.      name
    ## 498                     Russia      name
    ## 499                    Bahamas      name
    ## 500               Falkland Is.      name
    ## 501                     Norway      name
    ## 503     Fr. S. Antarctic Lands      name
    ## 504                Timor-Leste      name
    ## 505               South Africa      name
    ## 506                    Lesotho      name
    ## 507                     Mexico      name
    ## 508                    Uruguay      name
    ## 509                     Brazil      name
    ## 510                    Bolivia      name
    ## 511                       Peru      name
    ## 512                   Colombia      name
    ## 513                     Panama      name
    ## 514                 Costa Rica      name
    ## 515                  Nicaragua      name
    ## 516                   Honduras      name
    ## 517                El Salvador      name
    ## 518                  Guatemala      name
    ## 520                  Venezuela      name
    ## 521                     Guyana      name
    ## 522                   Suriname      name
    ## 523                     France      name
    ## 524                    Ecuador      name
    ## 525                Puerto Rico      name
    ## 527                       Cuba      name
    ## 528                   Zimbabwe      name
    ## 529                   Botswana      name
    ## 530                    Namibia      name
    ## 531                    Senegal      name
    ## 532                       Mali      name
    ## 533                 Mauritania      name
    ## 534                      Benin      name
    ## 535                      Niger      name
    ## 536                    Nigeria      name
    ## 537                   Cameroon      name
    ## 538                       Togo      name
    ## 539                      Ghana      name
    ## 540              Côte d'Ivoire      name
    ## 541                     Guinea      name
    ## 542              Guinea-Bissau      name
    ## 543                    Liberia      name
    ## 544               Sierra Leone      name
    ## 546       Central African Rep.      name
    ## 547                      Congo      name
    ## 548                      Gabon      name
    ## 549                 Eq. Guinea      name
    ## 550                     Zambia      name
    ## 551                     Malawi      name
    ## 552                 Mozambique      name
    ## 553                   eSwatini      name
    ## 554                     Angola      name
    ## 555                    Burundi      name
    ## 556                     Israel      name
    ## 557                    Lebanon      name
    ## 558                 Madagascar      name
    ## 559                  Palestine      name
    ## 560                     Gambia      name
    ## 561                    Tunisia      name
    ## 562                    Algeria      name
    ## 563                     Jordan      name
    ## 565                      Qatar      name
    ## 566                     Kuwait      name
    ## 567                       Iraq      name
    ## 568                       Oman      name
    ## 569                    Vanuatu      name
    ## 570                   Cambodia      name
    ## 571                   Thailand      name
    ## 572                       Laos      name
    ## 573                    Myanmar      name
    ## 574                    Vietnam      name
    ## 575                North Korea      name
    ## 576                South Korea      name
    ## 578                      India      name
    ## 579                 Bangladesh      name
    ## 580                     Bhutan      name
    ## 582                   Pakistan      name
    ## 583                Afghanistan      name
    ## 584                 Tajikistan      name
    ## 585                 Kyrgyzstan      name
    ## 587                       Iran      name
    ## 588                      Syria      name
    ## 589                    Armenia      name
    ## 590                     Sweden      name
    ## 591                    Belarus      name
    ## 593                     Poland      name
    ## 594                    Austria      name
    ## 595                    Hungary      name
    ## 596                    Moldova      name
    ## 598                  Lithuania      name
    ## 599                     Latvia      name
    ## 600                    Estonia      name
    ## 601                    Germany      name
    ## 602                   Bulgaria      name
    ## 603                     Greece      name
    ## 604                     Turkey      name
    ## 605                    Albania      name
    ## 606                    Croatia      name
    ## 607                Switzerland      name
    ## 608                 Luxembourg      name
    ## 609                    Belgium      name
    ## 610                Netherlands      name
    ## 611                   Portugal      name
    ## 612                      Spain      name
    ## 615                Solomon Is.      name
    ## 617                  Australia      name
    ## 618                  Sri Lanka      name
    ## 619                      China      name
    ## 620                     Taiwan      name
    ## 621                      Italy      name
    ## 622                    Denmark      name
    ## 623             United Kingdom      name
    ## 624                    Iceland      name
    ## 625                 Azerbaijan      name
    ## 627                Philippines      name
    ## 629                     Brunei      name
    ## 630                   Slovenia      name
    ## 631                    Finland      name
    ## 632                   Slovakia      name
    ## 633                    Czechia      name
    ## 634                    Eritrea      name
    ## 636                   Paraguay      name
    ## 637                      Yemen      name
    ## 638               Saudi Arabia      name
    ## 639                 Antarctica      name
    ## 640                  N. Cyprus      name
    ## 641                     Cyprus      name
    ## 642                    Morocco      name
    ## 643                      Egypt      name
    ## 645                   Ethiopia      name
    ## 646                   Djibouti      name
    ## 647                 Somaliland      name
    ## 648                     Uganda      name
    ## 649                     Rwanda      name
    ## 650           Bosnia and Herz.      name
    ## 651            North Macedonia      name
    ## 652                     Serbia      name
    ## 654                     Kosovo      name
    ## 655        Trinidad and Tobago      name
    ## 656                   S. Sudan      name
    ## 659       Turks and Caicos Is.      name
    ## 660                   Cook Is.      name
    ## 661                      Samoa      name
    ## 662                      Tonga      name
    ## 663              Fr. Polynesia      name
    ## 664               Pitcairn Is.      name
    ## 667      São Tomé and Principe      name
    ## 668                  Ascension      name
    ## 669               Saint Helena      name
    ## 670                      Malta      name
    ## 671                    Bahrain      name
    ## 672                   Maldives      name
    ## 673      Br. Indian Ocean Ter.      name
    ## 674                  Singapore      name
    ## 676                      Palau      name
    ## 677             N. Mariana Is.      name
    ## 678                       Guam      name
    ## 679                 Micronesia      name
    ## 680               Marshall Is.      name
    ## 681                   Kiribati      name
    ## 682                      Nauru      name
    ## 684                  Mauritius      name
    ## 685                    Comoros      name
    ## 686                 Faeroe Is.      name
    ## 687               Jan Mayen I.      name
    ## 688    St. Pierre and Miquelon      name
    ## 689                    Bermuda      name
    ## 690                     Azores      name
    ## 691                 Canary Is.      name
    ## 692                    Madeira      name
    ## 693        S. Geo. and the Is.      name
    ## 699                    Vatican      name
    ## 706            U.S. Virgin Is.      name
    ## 715                   Anguilla      name
    ## 717                 Cayman Is.      name
    ## 719         British Virgin Is.      name
    ## 721                 Montserrat      name
    ## 722                     Jersey      name
    ## 723                   Guernsey      name
    ## 724                Isle of Man      name
    ## 725                      Wales      name
    ## 726                   Scotland      name
    ## 727                 N. Ireland      name
    ## 728                    England      name
    ## 740                   Zanzibar      name
    ## 762                 Seychelles      name
    ## 764                  Vojvodina      name
    ## 768                 San Marino      name
    ## 770         St. Vin. and Gren.      name
    ## 772        St. Kitts and Nevis      name
    ## 785               Bougainville      name
    ## 792               Svalbard Is.      name
    ## 798                       Niue      name
    ## 799                    Tokelau      name
    ## 803      Caribbean Netherlands      name
    ## 814                     Monaco      name
    ## 827              Liechtenstein      name
    ## 845                       Gaza      name
    ## 868                    Mayotte      name
    ## 869                    Réunion      name
    ## 870                 Martinique      name
    ## 871                 Guadeloupe      name
    ## 872              French Guiana      name
    ## 874      Wallis and Futuna Is.      name
    ## 875                  St-Martin      name
    ## 876              St-Barthélemy      name
    ## 880                      Åland      name
    ## 891                   Dominica      name
    ## 908                      Macao      name
    ## 909                  Hong Kong      name
    ## 913                 Cabo Verde      name
    ## 924                Rep. Srpska      name
    ## 925       Fed. of Bos. & Herz.      name
    ## 930                    Flemish      name
    ## 931                    Walloon      name
    ## 932                   Brussels      name
    ## 941               Christmas I.      name
    ## 942                  Cocos Is.      name
    ## 943  Heard I. and McDonald Is.      name
    ## 944             Norfolk Island      name
    ## 945    Ashmore and Cartier Is.      name
    ## 948                    Antigua      name
    ## 949                    Barbuda      name
    ## 951                    Andorra      name
    ## 955            Siachen Glacier      name
    ## 957               Sint Maarten      name
    ## 961                  W. Sahara name_long
    ## 963   United States of America name_long
    ## 979               Falkland Is. name_long
    ## 982     Fr. S. Antarctic Lands name_long
    ## 1028                Eq. Guinea name_long
    ## 1039                    Gambia name_long
    ## 1051                      Laos name_long
    ## 1054               North Korea name_long
    ## 1094               Solomon Is. name_long
    ## 1108                    Brunei name_long
    ## 1119                 N. Cyprus name_long
    ## 1135                  S. Sudan name_long
    ## 1139                  Cook Is. name_long
    ## 1143              Pitcairn Is. name_long
    ## 1152     Br. Indian Ocean Ter. name_long
    ## 1156            N. Mariana Is. name_long
    ## 1159              Marshall Is. name_long
    ## 1165                Faeroe Is. name_long
    ## 1166              Jan Mayen I. name_long
    ## 1170                Canary Is. name_long
    ## 1185           U.S. Virgin Is. name_long
    ## 1206                N. Ireland name_long
    ## 1251       St. Kitts and Nevis name_long
    ## 1271              Svalbard Is. name_long
    ## 1354                 St-Martin name_long
    ## 1403               Rep. Srpska name_long
    ## 1404      Fed. of Bos. & Herz. name_long
    ## 1409                   Flemish name_long
    ## 1410                   Walloon name_long
    ## 1420              Christmas I. name_long
    ## 1421                 Cocos Is. name_long
    ## 1422 Heard I. and McDonald Is. name_long
    ## 1424   Ashmore and Cartier Is. name_long
    ## 1457                   Bahamas   name_en
    ## 1462               Timor-Leste   name_en
    ## 1498             Côte d'Ivoire   name_en
    ## 1511                  eSwatini   name_en
    ## 1625     São Tomé and Principe   name_en
    ## 1644                Faeroe Is.   name_en
    ## 1645              Jan Mayen I.   name_en
    ## 1651       S. Geo. and the Is.   name_en
    ## 1657                   Vatican   name_en
    ## 1750              Svalbard Is.   name_en
    ## 1832     Wallis and Futuna Is.   name_en
    ## 1833                 St-Martin   name_en
    ## 1834             St-Barthélemy   name_en
    ## 1866                     Macao   name_en
    ## 1871                Cabo Verde   name_en
    ## 1882               Rep. Srpska   name_en
    ## 1888                   Flemish   name_en
    ## 1889                   Walloon   name_en
    ## 1890                  Brussels   name_en
    ## 1900                 Cocos Is.   name_en
    ## 1901 Heard I. and McDonald Is.   name_en
    ## 1917                      Fiji   name_es
    ## 1919                 W. Sahara   name_es
    ## 1920                    Canada   name_es
    ## 1921  United States of America   name_es
    ## 1922                Kazakhstan   name_es
    ## 1923                Uzbekistan   name_es
    ## 1924          Papua New Guinea   name_es
    ## 1928           Dem. Rep. Congo   name_es
    ## 1930                     Kenya   name_es
    ## 1931                     Sudan   name_es
    ## 1933                     Haiti   name_es
    ## 1934            Dominican Rep.   name_es
    ## 1935                    Russia   name_es
    ## 1937              Falkland Is.   name_es
    ## 1938                    Norway   name_es
    ## 1939                 Greenland   name_es
    ## 1940    Fr. S. Antarctic Lands   name_es
    ## 1941               Timor-Leste   name_es
    ## 1942              South Africa   name_es
    ## 1943                   Lesotho   name_es
    ## 1944                    Mexico   name_es
    ## 1946                    Brazil   name_es
    ## 1948                      Peru   name_es
    ## 1950                    Panama   name_es
    ## 1956                    Belize   name_es
    ## 1959                  Suriname   name_es
    ## 1960                    France   name_es
    ## 1965                  Zimbabwe   name_es
    ## 1966                  Botswana   name_es
    ## 1969                      Mali   name_es
    ## 1971                     Benin   name_es
    ## 1972                     Niger   name_es
    ## 1974                  Cameroon   name_es
    ## 1977             Côte d'Ivoire   name_es
    ## 1979             Guinea-Bissau   name_es
    ## 1981              Sierra Leone   name_es
    ## 1983      Central African Rep.   name_es
    ## 1984                     Congo   name_es
    ## 1985                     Gabon   name_es
    ## 1986                Eq. Guinea   name_es
    ## 1988                    Malawi   name_es
    ## 1990                  eSwatini   name_es
    ## 1994                   Lebanon   name_es
    ## 1996                 Palestine   name_es
    ## 1998                   Tunisia   name_es
    ## 1999                   Algeria   name_es
    ## 2000                    Jordan   name_es
    ## 2001      United Arab Emirates   name_es
    ## 2002                     Qatar   name_es
    ## 2004                      Iraq   name_es
    ## 2005                      Oman   name_es
    ## 2007                  Cambodia   name_es
    ## 2008                  Thailand   name_es
    ## 2010                   Myanmar   name_es
    ## 2012               North Korea   name_es
    ## 2013               South Korea   name_es
    ## 2016                Bangladesh   name_es
    ## 2017                    Bhutan   name_es
    ## 2019                  Pakistan   name_es
    ## 2020               Afghanistan   name_es
    ## 2021                Tajikistan   name_es
    ## 2022                Kyrgyzstan   name_es
    ## 2023              Turkmenistan   name_es
    ## 2024                      Iran   name_es
    ## 2025                     Syria   name_es
    ## 2027                    Sweden   name_es
    ## 2028                   Belarus   name_es
    ## 2029                   Ukraine   name_es
    ## 2030                    Poland   name_es
    ## 2032                   Hungary   name_es
    ## 2033                   Moldova   name_es
    ## 2034                   Romania   name_es
    ## 2035                 Lithuania   name_es
    ## 2036                    Latvia   name_es
    ## 2038                   Germany   name_es
    ## 2040                    Greece   name_es
    ## 2041                    Turkey   name_es
    ## 2043                   Croatia   name_es
    ## 2044               Switzerland   name_es
    ## 2045                Luxembourg   name_es
    ## 2046                   Belgium   name_es
    ## 2047               Netherlands   name_es
    ## 2049                     Spain   name_es
    ## 2050                   Ireland   name_es
    ## 2051             New Caledonia   name_es
    ## 2052               Solomon Is.   name_es
    ## 2053               New Zealand   name_es
    ## 2057                    Taiwan   name_es
    ## 2058                     Italy   name_es
    ## 2059                   Denmark   name_es
    ## 2060            United Kingdom   name_es
    ## 2061                   Iceland   name_es
    ## 2062                Azerbaijan   name_es
    ## 2064               Philippines   name_es
    ## 2065                  Malaysia   name_es
    ## 2066                    Brunei   name_es
    ## 2067                  Slovenia   name_es
    ## 2068                   Finland   name_es
    ## 2069                  Slovakia   name_es
    ## 2070                   Czechia   name_es
    ## 2072                     Japan   name_es
    ## 2075              Saudi Arabia   name_es
    ## 2076                Antarctica   name_es
    ## 2077                 N. Cyprus   name_es
    ## 2078                    Cyprus   name_es
    ## 2079                   Morocco   name_es
    ## 2080                     Egypt   name_es
    ## 2081                     Libya   name_es
    ## 2082                  Ethiopia   name_es
    ## 2083                  Djibouti   name_es
    ## 2084                Somaliland   name_es
    ## 2086                    Rwanda   name_es
    ## 2087          Bosnia and Herz.   name_es
    ## 2088           North Macedonia   name_es
    ## 2092       Trinidad and Tobago   name_es
    ## 2093                  S. Sudan   name_es
    ## 2096      Turks and Caicos Is.   name_es
    ## 2097                  Cook Is.   name_es
    ## 2100             Fr. Polynesia   name_es
    ## 2101              Pitcairn Is.   name_es
    ## 2104     São Tomé and Principe   name_es
    ## 2105                 Ascension   name_es
    ## 2106              Saint Helena   name_es
    ## 2108                   Bahrain   name_es
    ## 2109                  Maldives   name_es
    ## 2110     Br. Indian Ocean Ter.   name_es
    ## 2111                 Singapore   name_es
    ## 2113                     Palau   name_es
    ## 2114            N. Mariana Is.   name_es
    ## 2116                Micronesia   name_es
    ## 2117              Marshall Is.   name_es
    ## 2121                 Mauritius   name_es
    ## 2122                   Comoros   name_es
    ## 2123                Faeroe Is.   name_es
    ## 2125   St. Pierre and Miquelon   name_es
    ## 2126                   Bermuda   name_es
    ## 2128                Canary Is.   name_es
    ## 2130       S. Geo. and the Is.   name_es
    ## 2136                   Vatican   name_es
    ## 2143           U.S. Virgin Is.   name_es
    ## 2145            American Samoa   name_es
    ## 2152                  Anguilla   name_es
    ## 2154                Cayman Is.   name_es
    ## 2156        British Virgin Is.   name_es
    ## 2161               Isle of Man   name_es
    ## 2162                     Wales   name_es
    ## 2163                  Scotland   name_es
    ## 2164                N. Ireland   name_es
    ## 2165                   England   name_es
    ## 2177                  Zanzibar   name_es
    ## 2201                 Vojvodina   name_es
    ## 2207        St. Vin. and Gren.   name_es
    ## 2208               Saint Lucia   name_es
    ## 2209       St. Kitts and Nevis   name_es
    ## 2240     Caribbean Netherlands   name_es
    ## 2241                   Curaçao   name_es
    ## 2251                    Monaco   name_es
    ## 2282                      Gaza   name_es
    ## 2283                 West Bank   name_es
    ## 2297                   Grenada   name_es
    ## 2306                   Réunion   name_es
    ## 2307                Martinique   name_es
    ## 2308                Guadeloupe   name_es
    ## 2309             French Guiana   name_es
    ## 2311     Wallis and Futuna Is.   name_es
    ## 2312                 St-Martin   name_es
    ## 2313             St-Barthélemy   name_es
    ## 2361               Rep. Srpska   name_es
    ## 2362      Fed. of Bos. & Herz.   name_es
    ## 2367                   Flemish   name_es
    ## 2368                   Walloon   name_es
    ## 2369                  Brussels   name_es
    ## 2378              Christmas I.   name_es
    ## 2379                 Cocos Is.   name_es
    ## 2380 Heard I. and McDonald Is.   name_es
    ## 2381            Norfolk Island   name_es
    ## 2382   Ashmore and Cartier Is.   name_es
    ## 2385                   Antigua   name_es
    ## 2392           Siachen Glacier   name_es
    ## 2397                  Tanzania   name_pt
    ## 2398                 W. Sahara   name_pt
    ## 2401                Kazakhstan   name_pt
    ## 2402                Uzbekistan   name_pt
    ## 2403          Papua New Guinea   name_pt
    ## 2404                 Indonesia   name_pt
    ## 2407           Dem. Rep. Congo   name_pt
    ## 2408                   Somalia   name_pt
    ## 2409                     Kenya   name_pt
    ## 2410                     Sudan   name_pt
    ## 2411                      Chad   name_pt
    ## 2414                    Russia   name_pt
    ## 2416              Falkland Is.   name_pt
    ## 2418                 Greenland   name_pt
    ## 2419    Fr. S. Antarctic Lands   name_pt
    ## 2421              South Africa   name_pt
    ## 2424                   Uruguay   name_pt
    ## 2426                   Bolivia   name_pt
    ## 2428                  Colombia   name_pt
    ## 2431                 Nicaragua   name_pt
    ## 2437                    Guyana   name_pt
    ## 2439                    France   name_pt
    ## 2440                   Ecuador   name_pt
    ## 2441               Puerto Rico   name_pt
    ## 2444                  Zimbabwe   name_pt
    ## 2446                   Namibia   name_pt
    ## 2449                Mauritania   name_pt
    ## 2450                     Benin   name_pt
    ## 2452                   Nigeria   name_pt
    ## 2453                  Cameroon   name_pt
    ## 2455                     Ghana   name_pt
    ## 2456             Côte d'Ivoire   name_pt
    ## 2457                    Guinea   name_pt
    ## 2458             Guinea-Bissau   name_pt
    ## 2459                   Liberia   name_pt
    ## 2460              Sierra Leone   name_pt
    ## 2462      Central African Rep.   name_pt
    ## 2463                     Congo   name_pt
    ## 2464                     Gabon   name_pt
    ## 2465                Eq. Guinea   name_pt
    ## 2466                    Zambia   name_pt
    ## 2468                Mozambique   name_pt
    ## 2469                  eSwatini   name_pt
    ## 2474                Madagascar   name_pt
    ## 2476                    Gambia   name_pt
    ## 2477                   Tunisia   name_pt
    ## 2478                   Algeria   name_pt
    ## 2479                    Jordan   name_pt
    ## 2480      United Arab Emirates   name_pt
    ## 2483                      Iraq   name_pt
    ## 2484                      Oman   name_pt
    ## 2486                  Cambodia   name_pt
    ## 2487                  Thailand   name_pt
    ## 2490                   Vietnam   name_pt
    ## 2491               North Korea   name_pt
    ## 2492               South Korea   name_pt
    ## 2493                  Mongolia   name_pt
    ## 2494                     India   name_pt
    ## 2496                    Bhutan   name_pt
    ## 2498                  Pakistan   name_pt
    ## 2499               Afghanistan   name_pt
    ## 2500                Tajikistan   name_pt
    ## 2501                Kyrgyzstan   name_pt
    ## 2502              Turkmenistan   name_pt
    ## 2503                      Iran   name_pt
    ## 2504                     Syria   name_pt
    ## 2505                   Armenia   name_pt
    ## 2506                    Sweden   name_pt
    ## 2507                   Belarus   name_pt
    ## 2508                   Ukraine   name_pt
    ## 2509                    Poland   name_pt
    ## 2510                   Austria   name_pt
    ## 2511                   Hungary   name_pt
    ## 2512                   Moldova   name_pt
    ## 2513                   Romania   name_pt
    ## 2514                 Lithuania   name_pt
    ## 2515                    Latvia   name_pt
    ## 2516                   Estonia   name_pt
    ## 2517                   Germany   name_pt
    ## 2518                  Bulgaria   name_pt
    ## 2519                    Greece   name_pt
    ## 2520                    Turkey   name_pt
    ## 2521                   Albania   name_pt
    ## 2522                   Croatia   name_pt
    ## 2523               Switzerland   name_pt
    ## 2526               Netherlands   name_pt
    ## 2528                     Spain   name_pt
    ## 2529                   Ireland   name_pt
    ## 2530             New Caledonia   name_pt
    ## 2531               Solomon Is.   name_pt
    ## 2532               New Zealand   name_pt
    ## 2533                 Australia   name_pt
    ## 2537                     Italy   name_pt
    ## 2540                   Iceland   name_pt
    ## 2541                Azerbaijan   name_pt
    ## 2542                   Georgia   name_pt
    ## 2544                  Malaysia   name_pt
    ## 2546                  Slovenia   name_pt
    ## 2547                   Finland   name_pt
    ## 2548                  Slovakia   name_pt
    ## 2549                   Czechia   name_pt
    ## 2550                   Eritrea   name_pt
    ## 2551                     Japan   name_pt
    ## 2552                  Paraguay   name_pt
    ## 2553                     Yemen   name_pt
    ## 2554              Saudi Arabia   name_pt
    ## 2556                 N. Cyprus   name_pt
    ## 2558                   Morocco   name_pt
    ## 2559                     Egypt   name_pt
    ## 2560                     Libya   name_pt
    ## 2561                  Ethiopia   name_pt
    ## 2563                Somaliland   name_pt
    ## 2566          Bosnia and Herz.   name_pt
    ## 2567           North Macedonia   name_pt
    ## 2568                    Serbia   name_pt
    ## 2571       Trinidad and Tobago   name_pt
    ## 2572                  S. Sudan   name_pt
    ## 2575      Turks and Caicos Is.   name_pt
    ## 2576                  Cook Is.   name_pt
    ## 2579             Fr. Polynesia   name_pt
    ## 2580              Pitcairn Is.   name_pt
    ## 2583     São Tomé and Principe   name_pt
    ## 2584                 Ascension   name_pt
    ## 2585              Saint Helena   name_pt
    ## 2587                   Bahrain   name_pt
    ## 2589     Br. Indian Ocean Ter.   name_pt
    ## 2590                 Singapore   name_pt
    ## 2593            N. Mariana Is.   name_pt
    ## 2595                Micronesia   name_pt
    ## 2596              Marshall Is.   name_pt
    ## 2600                 Mauritius   name_pt
    ## 2601                   Comoros   name_pt
    ## 2602                Faeroe Is.   name_pt
    ## 2604   St. Pierre and Miquelon   name_pt
    ## 2606                    Azores   name_pt
    ## 2607                Canary Is.   name_pt
    ## 2608                   Madeira   name_pt
    ## 2609       S. Geo. and the Is.   name_pt
    ## 2615                   Vatican   name_pt
    ## 2622           U.S. Virgin Is.   name_pt
    ## 2624            American Samoa   name_pt
    ## 2633                Cayman Is.   name_pt
    ## 2635        British Virgin Is.   name_pt
    ## 2640               Isle of Man   name_pt
    ## 2641                     Wales   name_pt
    ## 2642                  Scotland   name_pt
    ## 2643                N. Ireland   name_pt
    ## 2686        St. Vin. and Gren.   name_pt
    ## 2687               Saint Lucia   name_pt
    ## 2688       St. Kitts and Nevis   name_pt
    ## 2719     Caribbean Netherlands   name_pt
    ## 2761                      Gaza   name_pt
    ## 2762                 West Bank   name_pt
    ## 2785                   Réunion   name_pt
    ## 2788             French Guiana   name_pt
    ## 2790     Wallis and Futuna Is.   name_pt
    ## 2791                 St-Martin   name_pt
    ## 2792             St-Barthélemy   name_pt
    ## 2840               Rep. Srpska   name_pt
    ## 2841      Fed. of Bos. & Herz.   name_pt
    ## 2846                   Flemish   name_pt
    ## 2847                   Walloon   name_pt
    ## 2848                  Brussels   name_pt
    ## 2857              Christmas I.   name_pt
    ## 2858                 Cocos Is.   name_pt
    ## 2859 Heard I. and McDonald Is.   name_pt
    ## 2860            Norfolk Island   name_pt
    ## 2861   Ashmore and Cartier Is.   name_pt
    ## 2864                   Antigua   name_pt
    ## 2875                      Fiji   name_fr
    ## 2876                  Tanzania   name_fr
    ## 2877                 W. Sahara   name_fr
    ## 2879  United States of America   name_fr
    ## 2881                Uzbekistan   name_fr
    ## 2882          Papua New Guinea   name_fr
    ## 2883                 Indonesia   name_fr
    ## 2884                 Argentina   name_fr
    ## 2885                     Chile   name_fr
    ## 2886           Dem. Rep. Congo   name_fr
    ## 2887                   Somalia   name_fr
    ## 2889                     Sudan   name_fr
    ## 2890                      Chad   name_fr
    ## 2891                     Haiti   name_fr
    ## 2892            Dominican Rep.   name_fr
    ## 2893                    Russia   name_fr
    ## 2895              Falkland Is.   name_fr
    ## 2896                    Norway   name_fr
    ## 2897                 Greenland   name_fr
    ## 2898    Fr. S. Antarctic Lands   name_fr
    ## 2899               Timor-Leste   name_fr
    ## 2900              South Africa   name_fr
    ## 2902                    Mexico   name_fr
    ## 2904                    Brazil   name_fr
    ## 2905                   Bolivia   name_fr
    ## 2906                      Peru   name_fr
    ## 2907                  Colombia   name_fr
    ## 2912               El Salvador   name_fr
    ## 2919                   Ecuador   name_fr
    ## 2921                   Jamaica   name_fr
    ## 2925                   Namibia   name_fr
    ## 2926                   Senegal   name_fr
    ## 2928                Mauritania   name_fr
    ## 2929                     Benin   name_fr
    ## 2932                  Cameroon   name_fr
    ## 2936                    Guinea   name_fr
    ## 2937             Guinea-Bissau   name_fr
    ## 2941      Central African Rep.   name_fr
    ## 2942                     Congo   name_fr
    ## 2944                Eq. Guinea   name_fr
    ## 2945                    Zambia   name_fr
    ## 2951                    Israel   name_fr
    ## 2952                   Lebanon   name_fr
    ## 2955                    Gambia   name_fr
    ## 2956                   Tunisia   name_fr
    ## 2957                   Algeria   name_fr
    ## 2958                    Jordan   name_fr
    ## 2959      United Arab Emirates   name_fr
    ## 2961                    Kuwait   name_fr
    ## 2965                  Cambodia   name_fr
    ## 2966                  Thailand   name_fr
    ## 2968                   Myanmar   name_fr
    ## 2969                   Vietnam   name_fr
    ## 2970               North Korea   name_fr
    ## 2971               South Korea   name_fr
    ## 2972                  Mongolia   name_fr
    ## 2973                     India   name_fr
    ## 2975                    Bhutan   name_fr
    ## 2976                     Nepal   name_fr
    ## 2979                Tajikistan   name_fr
    ## 2980                Kyrgyzstan   name_fr
    ## 2981              Turkmenistan   name_fr
    ## 2983                     Syria   name_fr
    ## 2984                   Armenia   name_fr
    ## 2985                    Sweden   name_fr
    ## 2986                   Belarus   name_fr
    ## 2988                    Poland   name_fr
    ## 2989                   Austria   name_fr
    ## 2990                   Hungary   name_fr
    ## 2991                   Moldova   name_fr
    ## 2992                   Romania   name_fr
    ## 2993                 Lithuania   name_fr
    ## 2994                    Latvia   name_fr
    ## 2995                   Estonia   name_fr
    ## 2996                   Germany   name_fr
    ## 2997                  Bulgaria   name_fr
    ## 2998                    Greece   name_fr
    ## 2999                    Turkey   name_fr
    ## 3000                   Albania   name_fr
    ## 3001                   Croatia   name_fr
    ## 3002               Switzerland   name_fr
    ## 3004                   Belgium   name_fr
    ## 3005               Netherlands   name_fr
    ## 3007                     Spain   name_fr
    ## 3008                   Ireland   name_fr
    ## 3009             New Caledonia   name_fr
    ## 3010               Solomon Is.   name_fr
    ## 3011               New Zealand   name_fr
    ## 3012                 Australia   name_fr
    ## 3014                     China   name_fr
    ## 3015                    Taiwan   name_fr
    ## 3016                     Italy   name_fr
    ## 3017                   Denmark   name_fr
    ## 3018            United Kingdom   name_fr
    ## 3019                   Iceland   name_fr
    ## 3020                Azerbaijan   name_fr
    ## 3021                   Georgia   name_fr
    ## 3023                  Malaysia   name_fr
    ## 3025                  Slovenia   name_fr
    ## 3026                   Finland   name_fr
    ## 3027                  Slovakia   name_fr
    ## 3028                   Czechia   name_fr
    ## 3029                   Eritrea   name_fr
    ## 3030                     Japan   name_fr
    ## 3032                     Yemen   name_fr
    ## 3033              Saudi Arabia   name_fr
    ## 3034                Antarctica   name_fr
    ## 3035                 N. Cyprus   name_fr
    ## 3036                    Cyprus   name_fr
    ## 3037                   Morocco   name_fr
    ## 3038                     Egypt   name_fr
    ## 3039                     Libya   name_fr
    ## 3040                  Ethiopia   name_fr
    ## 3043                    Uganda   name_fr
    ## 3045          Bosnia and Herz.   name_fr
    ## 3046           North Macedonia   name_fr
    ## 3047                    Serbia   name_fr
    ## 3048                Montenegro   name_fr
    ## 3050       Trinidad and Tobago   name_fr
    ## 3051                  S. Sudan   name_fr
    ## 3054      Turks and Caicos Is.   name_fr
    ## 3055                  Cook Is.   name_fr
    ## 3058             Fr. Polynesia   name_fr
    ## 3059              Pitcairn Is.   name_fr
    ## 3060                  Barbados   name_fr
    ## 3062     São Tomé and Principe   name_fr
    ## 3063                 Ascension   name_fr
    ## 3064              Saint Helena   name_fr
    ## 3065                     Malta   name_fr
    ## 3066                   Bahrain   name_fr
    ## 3068     Br. Indian Ocean Ter.   name_fr
    ## 3069                 Singapore   name_fr
    ## 3072            N. Mariana Is.   name_fr
    ## 3074                Micronesia   name_fr
    ## 3075              Marshall Is.   name_fr
    ## 3079                 Mauritius   name_fr
    ## 3081                Faeroe Is.   name_fr
    ## 3083   St. Pierre and Miquelon   name_fr
    ## 3084                   Bermuda   name_fr
    ## 3085                    Azores   name_fr
    ## 3086                Canary Is.   name_fr
    ## 3087                   Madeira   name_fr
    ## 3088       S. Geo. and the Is.   name_fr
    ## 3094                   Vatican   name_fr
    ## 3101           U.S. Virgin Is.   name_fr
    ## 3103            American Samoa   name_fr
    ## 3112                Cayman Is.   name_fr
    ## 3114        British Virgin Is.   name_fr
    ## 3118                  Guernsey   name_fr
    ## 3119               Isle of Man   name_fr
    ## 3120                     Wales   name_fr
    ## 3121                  Scotland   name_fr
    ## 3122                N. Ireland   name_fr
    ## 3123                   England   name_fr
    ## 3159                 Vojvodina   name_fr
    ## 3163                San Marino   name_fr
    ## 3165        St. Vin. and Gren.   name_fr
    ## 3166               Saint Lucia   name_fr
    ## 3167       St. Kitts and Nevis   name_fr
    ## 3198     Caribbean Netherlands   name_fr
    ## 3240                      Gaza   name_fr
    ## 3241                 West Bank   name_fr
    ## 3255                   Grenada   name_fr
    ## 3264                   Réunion   name_fr
    ## 3267             French Guiana   name_fr
    ## 3269     Wallis and Futuna Is.   name_fr
    ## 3286                  Dominica   name_fr
    ## 3308                Cabo Verde   name_fr
    ## 3319               Rep. Srpska   name_fr
    ## 3320      Fed. of Bos. & Herz.   name_fr
    ## 3325                   Flemish   name_fr
    ## 3326                   Walloon   name_fr
    ## 3327                  Brussels   name_fr
    ## 3336              Christmas I.   name_fr
    ## 3337                 Cocos Is.   name_fr
    ## 3338 Heard I. and McDonald Is.   name_fr
    ## 3339            Norfolk Island   name_fr
    ## 3340   Ashmore and Cartier Is.   name_fr
    ## 3346                   Andorra   name_fr
    ## 3350           Siachen Glacier   name_fr

``` r
countryNames<-rbind(countryNames,
                    data.frame(
                      string=c("Democratic Republic Congo","Cote d'Ivoire"),
                      name=c("Dem. Rep. Congo","Côte d'Ivoire"),
                      type="manual"
                    ))
list_countryAffil<-list()
for(i in 1:length(sepAffil)){
  list_countryAffil[[i]]<-list()
  if(length(sepAffil[[i]])==0)next
  for(j in 1:length(sepAffil[[i]]))
  {
    list_countryAffil[[i]][[j]]<-sepAffil[[i]][[j]]%in%countryNames$string
  }
}
nbCountriesByAuthors<-lapply(list_countryAffil,sapply,sum)
noCountry<-sapply(nbCountriesByAuthors,function(x)which(x==0))
nb_noCountry<-sapply(noCountry,function(x)length(x))
tabNoCountryRef<-data.frame(
  doc=rep(which(nb_noCountry!=0),nb_noCountry[nb_noCountry>0]),
  auth=unlist(noCountry)
)
apply(tabNoCountryRef,1,function(x,l)l[[x[1]]][[x[2]]],l=sepAffil)
```

    ## [[1]]
    ## [1] "Gabriel R."                                
    ## [2] "Centre for Ecology"                        
    ## [3] "Evolution and Environmental Changes (cE3c)"
    ## [4] "Azorean Biodiversity Group (ABG)"          
    ## 
    ## [[2]]
    ## [1] "Giarrizzo E."
    ## 
    ## [[3]]
    ## [1] "Maleki K."
    ## 
    ## [[4]]
    ## [1] "Weber H."
    ## 
    ## [[5]]
    ## [1] "Twidwell J.J."
    ## 
    ## [[6]]
    ## [1] "Sebastia M.-T."
    ## 
    ## [[7]]
    ## [1] "Brooker R.W."       "Macaulay Institute" "Craigiebuckler"    
    ## 
    ## [[8]]
    ## [1] "Ansquer P."
    ## 
    ## [[9]]
    ## [1] "Castro H."
    ## 
    ## [[10]]
    ## [1] "Cruz P."
    ## 
    ## [[11]]
    ## [1] "Doležal J."
    ## 
    ## [[12]]
    ## [1] "Eriksson Ove."
    ## 
    ## [[13]]
    ## [1] "Fortunel C."
    ## 
    ## [[14]]
    ## [1] "Freitas H."
    ## 
    ## [[15]]
    ## [1] "Golodets C."
    ## 
    ## [[16]]
    ## [1] "Grigfulis K."
    ## 
    ## [[17]]
    ## [1] "Jouany C."
    ## 
    ## [[18]]
    ## [1] "Kazakou E."
    ## 
    ## [[19]]
    ## [1] "Kigel J."
    ## 
    ## [[20]]
    ## [1] "Lehsten V."
    ## 
    ## [[21]]
    ## [1] "Meier T."
    ## 
    ## [[22]]
    ## [1] "Papadimitriou M."
    ## 
    ## [[23]]
    ## [1] "Papanastasis V.P."
    ## 
    ## [[24]]
    ## [1] "Quested H."
    ## 
    ## [[25]]
    ## [1] "Que´tier F."
    ## 
    ## [[26]]
    ## [1] "Robson M."
    ## 
    ## [[27]]
    ## [1] "Roumet C."
    ## 
    ## [[28]]
    ## [1] "Rusch G."
    ## 
    ## [[29]]
    ## [1] "Skarpe C."
    ## 
    ## [[30]]
    ## [1] "Sternberg M."
    ## 
    ## [[31]]
    ## [1] "Theau J.-P."
    ## 
    ## [[32]]
    ## [1] "The´bault A."
    ## 
    ## [[33]]
    ## [1] "Vile D."
    ## 
    ## [[34]]
    ## [1] "Zarovali M.P."
    ## 
    ## [[35]]
    ## [1] "Bauwens B."
    ## 
    ## [[36]]
    ## [1] "Legg C.J."
    ## 
    ## [[37]]
    ## [1] "Rameau J.-C."
    ## 
    ## [[38]]
    ## [1] "Augenstein I."                                   
    ## [2] "Technical University Munich"                     
    ## [3] "Department of Strategies of Landscape Management"
    ## 
    ## [[39]]
    ## [1] "Large A.R.G."                              
    ## [2] "School of Geography Politics and Sociology"
    ## [3] "Daysh Building"                            
    ## 
    ## [[40]]
    ## [1] "Mayes W.M."                                                  
    ## [2] "Hydrogeochemical Engineering Research and Outreach Group"    
    ## [3] "Institute for Research on the Environment and Sustainability"
    ## 
    ## [[41]]
    ## [1] "Newson M.D."                               
    ## [2] "School of Geography Politics and Sociology"
    ## [3] "Daysh Building"                            
    ## 
    ## [[42]]
    ## [1] "Escarré J."
    ## 
    ## [[43]]
    ## [1] "McCarthy B.C."
    ## 
    ## [[44]]
    ## [1] "Campeau S."
    ## 
    ## [[45]]
    ## [1] "Stewart G.H."
    ## 
    ## [[46]]
    ## [1] "Duncan R.P."
    ## 
    ## [[47]]
    ## [1] "Bradfield G.E."
    ## 
    ## [[48]]
    ## [1] "Müller S.W."
    ## 
    ## [[49]]
    ## [1] "Baur B."
    ## 
    ## [[50]]
    ## [1] "Laine A.-L."                         
    ## [2] "Dept. of Biol. and Environ. Sciences"
    ## [3] "University of Helsinki"              
    ## [4] "FIN-00014"                           
    ## 
    ## [[51]]
    ## [1] "Aikio S."                            
    ## [2] "Dept. of Biol. and Environ. Sciences"
    ## [3] "University of Helsinki"              
    ## [4] "FIN-00014"                           
    ## 
    ## [[52]]
    ## [1] "Meire P."
    ## 
    ## [[53]]
    ## [1] "Karadžić B."                       "Institute for Biological Research"
    ## [3] "Siniša Stanković"                  "11060 Belgrade"                   
    ## [5] "29 Novembra 142"                  
    ## 
    ## [[54]]
    ## [1] "Marinković S."                     "Institute for Biological Research"
    ## [3] "Siniša Stanković"                  "11060 Belgrade"                   
    ## [5] "29 Novembra 142"                  
    ## 
    ## [[55]]
    ## [1] "Katarinovski D."                   "Institute for Biological Research"
    ## [3] "Siniša Stanković"                  "11060 Belgrade"                   
    ## [5] "29 Novembra 142"                  
    ## 
    ## [[56]]
    ## [1] "Pyšek A."
    ## 
    ## [[57]]
    ## [1] "Herben T."
    ## 
    ## [[58]]
    ## [1] "Malloch A.J.C."
    ## 
    ## [[59]]
    ## [1] "Blasi C."
    ## 
    ## [[60]]
    ## [1] "Stanisci A."
    ## 
    ## [[61]]
    ## [1] "Tanghe M."
    ## 
    ## [[62]]
    ## [1] "Kollmann J."
    ## 
    ## [[63]]
    ## [1] "Ash A.J."
    ## 
    ## [[64]]
    ## [1] "Vitousek P.M."
    ## 
    ## [[65]]
    ## [1] "Hietz‐Seifert U."
    ## 
    ## [[66]]
    ## [1] "Varnamkhasti A.S."                        
    ## [2] "Department of Rangeland Ecosystem Science"
    ## 
    ## [[67]]
    ## [1] "Goetz H."                                 
    ## [2] "Department of Rangeland Ecosystem Science"
    ## 
    ## [[68]]
    ## [1] "Noest V."                        "Department of Ecological Botany"
    ## 
    ## [[69]]
    ## [1] "Aguirre J.L."
    ## 
    ## [[70]]
    ## [1] "Karadži B."                        "Institute for Biological Research"
    ## [3] "Belgrade"                          "11060"                            
    ## [5] "29 Novembra 142"                  
    ## 
    ## [[71]]
    ## [1] "Popovi R."                         "Institute for Biological Research"
    ## [3] "Belgrade"                          "11060"                            
    ## [5] "29 Novembra 142"                  
    ## 
    ## [[72]]
    ## [1] "Zechmeister H."                                            
    ## [2] "Department of Vegetation Ecology & Biological Conservation"
    ## 
    ## [[73]]
    ## [1] "Tatoni T."                                                          
    ## [2] "Institut Mediterranéen d'Ecologie et de Paléoécologie URA CNRS 1152"
    ## [3] "Case 461"                                                           
    ## 
    ## [[74]]
    ## [1] "Harcombe P.A."                                           
    ## [2] "Dwept. of Ecology & Evolutionary Biology Rice University"
    ## [3] "Houston"                                                 
    ## [4] "TX 77251"                                                
    ## [5] "USa."                                                    
    ## 
    ## [[75]]
    ## [1] "Cameron G.N."                                            
    ## [2] "Dwept. of Ecology & Evolutionary Biology Rice University"
    ## [3] "Houston"                                                 
    ## [4] "TX 77251"                                                
    ## [5] "USa."                                                    
    ## 
    ## [[76]]
    ## [1] "Glumac E.G."                                             
    ## [2] "Dwept. of Ecology & Evolutionary Biology Rice University"
    ## [3] "Houston"                                                 
    ## [4] "TX 77251"                                                
    ## [5] "USa."                                                    
    ## 
    ## [[77]]
    ## [1] "Peet R.K."
    ## 
    ## [[78]]
    ## [1] "Laborde J."
    ## 
    ## [[79]]
    ## [1] "Palmer M.W."
    ## 
    ## [[80]]
    ## [1] "Lloret F."                                          
    ## [2] "Centre de Recerca Ecológica I Aplicacions Forestáis"
    ## 
    ## [[81]]
    ## [1] "Kull K."                          "Department of Botany and Ecology"
    ## [3] "Tartu University"                 "Tartu"                           
    ## 
    ## [[82]]
    ## [1] "Zobel M."                         "Department of Botany and Ecology"
    ## [3] "Tartu University"                 "Tartu"                           
    ## 
    ## [[83]]
    ## [1] "Pyšek P."                     "Institute of Applied Ecology"
    ## [3] "Kostelec Nad Cernymi Lesy"    "CS-281 63"                   
    ## 
    ## [[84]]
    ## [1] "Lepš J."                          "Department of Biomathematics"    
    ## [3] "Czechoslovak Academy of Sciences" "Ceske Budejovice"                
    ## [5] "CS-370 05"                        "Branisovská 31"                  
    ## 
    ## [[85]]
    ## [1] "Neuhäusl R."                          
    ## [2] "Botanical Institute"                  
    ## [3] "Czechoslovak Academy of Sciences Cs -"
    ## [4] "Praha"                                
    ## [5] "252 43"                               
    ## [6] "Pruhonice near"                       
    ## 
    ## [[86]]
    ## [1] "Lepš J."                                                   
    ## [2] "Biological Faculty"                                        
    ## [3] "University of South Bohemia & Department of Biomathematics"
    ## [4] "Czechoslovak Academy of Sciences"                          
    ## [5] "Ceske Budejovice"                                          
    ## [6] "CS-370 05"                                                 
    ## [7] "Branǐsovská 31"                                            
    ## 
    ## [[87]]
    ## [1] "Hadincová V."                     "Botanical Institute"             
    ## [3] "Czechoslovak Academy of Sciences" "Prahy"                           
    ## [5] "CS-252 43"                        "Průhonice u"                     
    ## 
    ## [[88]]
    ## [1] "Moravec J."                                                 
    ## [2] "Botanical Institute of the Czechoslovak Academy of Sciences"
    ## [3] "Prague"                                                     
    ## [4] "CS-252 43"                                                  
    ## [5] "43 Průhonice near Prague"                                   
    ## 
    ## [[89]]
    ## [1] "Dostálek J."                      "Botanical Institute"             
    ## [3] "Czechoslovak Academy of Sciences" "Průhonice"                       
    ## [5] "CS-252 43"                       
    ## 
    ## [[90]]
    ## [1] "Jarolímek I."               "Botanical Institute"       
    ## [3] "Slovak Academy of Sciences" "Bratislava"                
    ## [5] "CS-842 23"                  "Sienkiewiczova 1"          
    ## 
    ## [[91]]
    ## [1] "Kolbek J."                        "Botanical Institute"             
    ## [3] "Czechoslovak Academy of Sciences" "Průhonice"                       
    ## [5] "CS-252 43"                       
    ## 
    ## [[92]]
    ## [1] "Ostrý I."                         "Botanical Institute"             
    ## [3] "Czechoslovak Academy of Sciences" "Průhonice"                       
    ## [5] "CS-252 43"                       
    ## 
    ## [[93]]
    ## [1] "Titlyanova A.A."                            
    ## [2] "Laboratory of Biogeocoenology"              
    ## [3] "Institute of Soil Science and Agrochemistry"
    ## [4] "Siberian Branch"                            
    ## [5] "Academy of Sciences"                        
    ## [6] "Novosibirsk"                                
    ## [7] "630099"                                     
    ## 
    ## [[94]]
    ## [1] "Mironycheva‐Tokareva N.P."                  
    ## [2] "Laboratory of Biogeocoenology"              
    ## [3] "Institute of Soil Science and Agrochemistry"
    ## [4] "Siberian Branch"                            
    ## [5] "Academy of Sciences"                        
    ## [6] "Novosibirsk"                                
    ## [7] "630099"                                     
    ## 
    ## [[95]]
    ## [1] "Duda J."            "Silesian Museum"    "Opava"             
    ## [4] "746 46"             "Vitezného unora 35"
    ## 
    ## [[96]]
    ## [1] "Herben T."                                                  
    ## [2] "Botanical Institute of the Czechoslovak Academy of Sciences"
    ## [3] "Pruhonice"                                                  
    ## [4] "252 43"                                                     
    ## 
    ## [[97]]
    ## [1] "Ivan N."         "Moravian Museum" "Brno"            "602 00"         
    ## [5] "Preslova 1"

# 3 Cities

``` r
require(geojsonR)
```

    ## Loading required package: geojsonR

``` r
cityData <- FROM_GeoJson("../../Data/geog/geonames-all-cities-with-a-population-1000.geojson")
namesCity1<-data.frame(string=sapply(cityData$features,function(x)x$properties$name),
                       name=sapply(cityData$features,function(x)x$properties$name),
                       country=sapply(cityData$features,function(x) ifelse(length(x$properties$cou_name_en)==0,NA,x$properties$cou_name_en)),
                       population=sapply(cityData$features,function(x)x$properties$population)
)
alternateNames<-lapply(cityData$features,function(x)unlist(x$properties$alternate_names))
alterNameCity<-data.frame(string=unlist(alternateNames),
           name=rep(namesCity1$string,sapply(alternateNames,length)),
           country=rep(namesCity1$country,sapply(alternateNames,length)),
           population=rep(namesCity1$population,sapply(alternateNames,length))
)
cityTab<-rbind(namesCity1,alterNameCity)
cityTab<-cityTab[order(cityTab$population,decreasing = T),]
```

``` r
list_cityAffil<-list()
for(i in 1:length(sepAffil)){
  list_cityAffil[[i]]<-list()
  if(length(sepAffil[[i]])==0)next
  for(j in 1:length(sepAffil[[i]]))
  {
    list_cityAffil[[i]][[j]]<-sepAffil[[i]][[j]]%in%cityTab$string
  }
}
```

``` r
tabAffil$country<-tabAffil$string%in%countryNames$string
tabAffil$city<-tabAffil$string%in%cityTab$string
write.csv(tabAffil,file="../../vegSciLacBib_export/tabAffil.csv")
```
