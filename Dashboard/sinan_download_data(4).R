library(downloader)
library(RCurl)
library(data.table)
library(read.dbc)
library(openxlsx)
library(lubridate)
library(dplyr)
library(tidyverse)
library(foreign)
library(ribge)
library(stringr)
library(devtools)
library(sf)
library(readxl)
# devtools::install_github("danicat/read.dbc")


dir <- "/home/christian/Scientific_Initiation_Dashboard/Dashboard/input/"
B_fin <- paste0(dir, "finais/")
B_par <- paste0(dir, "parciais/")
SUF <- c("DENG")
tam = 63
mypath <- B_fin

if (mypath == B_fin){
  DOWN <- c("ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/FINAIS/")
  options(timeout = 300)
}else{
  DOWN <- c("ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/")
  options(timeout = 300)
}

if(interactive() && url.exists(DOWN)) {
  url = c(DOWN)    
  filenames = getURL(url, ftp.use.epsv = FALSE, dirlistonly = TRUE)
  filenames = paste(url, strsplit(filenames, "\r*\n")[[1]], sep = "")
}

filenames  <- filenames[grep(SUF, filenames)]

setwd(mypath)
fil <- cbind(list.files(pattern="$"));
fil <- fil[substring(fil,1,4)==SUF]

if(length(fil) > 0) {
  arq <- NULL
  for (i in  1:length(fil)) {
    arq_  <- grep(fil[i], filenames); 
    arq   <- rbind(arq,arq_); 
    arq_  <- filenames[-arq]
  }
  
  cat(" ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ",
      "#------------------------------------------------------------------------", 
      " ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ")
  
  print(paste("Aviso: Existem ",length(filenames),"arquivos no sitio pesquisado"))
  print(paste("Aviso: Existem ",length(arq_),"arquivos para atualizar"))               
  
  cat(" ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ",
      "#------------------------------------------------------------------------", 
      " ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ")
  
  if(length(arq_) > 0) {
    setwd(mypath)
    k=1
    for (i in  k:length(arq_)) {
      download.file(url=paste0(arq_[i]), destfile=paste0(substring(arq_[i],tam)), mode="wb")
    }
  }                                  
} else {
  
  cat(" ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ",
      "#------------------------------------------------------------------------", 
      " ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ")
  
  print(paste("Aviso: Existem ",length(filenames),"arquivos no sitio pesquisado"))
  print(paste("Aviso: Existem ",length(filenames),"arquivos para atualizar"))
  
  cat(" ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ",
      "#------------------------------------------------------------------------", 
      " ","\n", " "," ","\n", " "," ","\n", " "," ","\n", " ")
  
  setwd(mypath)
  k=1
  for (i in  k:length(filenames)) {
    download.file(url=paste0(filenames[i]), destfile=paste0(substring(filenames[i],tam)), mode="wb")
  }     
}


setwd(mypath)
files_dbc <- list.files(path = mypath, pattern = ".dbc")
files_dbf <- list.files(path = mypath, pattern = ".dbf")
files <- setdiff(str_replace_all(files_dbc, ".dbc", ""), str_replace_all(files_dbf, ".dbf", ""))
onlydbf <- FALSE

for(i in 16:length(files)){
  if (onlydbf == FALSE){
    file <- tools::file_path_sans_ext(paste0(files[i], ".dbc"))
    temp <- dbc2dbf(paste0(file, ".dbc"), paste0(file, ".dbf"))
    base <- read.dbf(paste0(file, ".dbf"))
    write.table(base, paste0(dir, "tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
    cat(file, "ok - \n") 
  }else{
    file <- tools::file_path_sans_ext(paste0(files[i], "dbf"))
    # base <- read.dbf(paste0(file, ".dbf"))
    base <- sf::st_read(paste0(file, ".dbf"))
    write.table(base, paste0(dir, "tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
    cat(file, "ok - \n")
  } 
}

# Input file name
input  <- system.file(paste0(files,".dbc"), package = "read.dbc")

# Output file name
output <- tempfile(fileext = ".dbc")

# The call returns TRUE on success
if( dbc2dbf(input.file = paste0(files,".dbc"), output.file = output) ) {
  print("File decompressed!")
  # do things with the file
}


################################
#parte do tsv
startFile <- 1
myfiles <- list.files(paste0(dir, "tsv/"), pattern = paste0(SUF, "*"))
myfiles <- myfiles[13:length(myfiles)]
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
confirmados <- TRUE #agora vou gerar o confirmados
for(i in startFile:length(myfiles)){
  tempFile <- fread(paste0(dir, "tsv/", myfiles[i]), stringsAsFactors = FALSE, showProgress = FALSE)
  myYearCalen <- paste0(20,str_replace_all(myfiles[i], "[^0-9]", ""))
  cale_year <- subset(calendario, ANO == myYearCalen)
  tempFile$weekStart <- NA
  for (icale in 1:nrow(cale_year)){
    tempFile$SEM_NOT[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- cale_year$SEM_NOT[icale]
    tempFile$weekStart[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- as.character(cale_year$Início[icale])
  }
  cat("i:", i, "- File: ", myfiles[i], "\n")
  # temp <- subset(tempFile, SG_UF_NOT == 31)
  if (confirmados == TRUE){
    temp <- subset(tempFile, CRITERIO < 3 & (CLASSI_FIN >= 10 & CLASSI_FIN <= 12 ))
  }else{
    temp <- tempFile
  }
  
  if ("total" %in% colnames(temp)) {
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, weekStart, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, weekStart, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "weekStart", "State", "City", "Age_temp", "Sex", "Race_Colour", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                          as.numeric(temp_agre$Age_temp), 
                          ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                 as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  temp_agre_final <- temp_agre %>%
    ungroup() %>%
    dplyr::select(Noti_Date, Noti_Week, weekStart, State, City, New_Cases, Age, Sex, Race_Colour)
  
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == startFile){
    newBahia <- temp_agre_final
  }else{
    newBahia <- rbind(newBahia, temp_agre_final)
  }
}
#depois de baixado, coverte e consolida os arquivos
newBahia$State=as.numeric(newBahia$State)

pop2024 <- populacao_municipios(2024)
meso_regiao <- read_xls(paste0(dir, "regioes_geograficas_composicao_por_municipios_2017_20180911.xls"))

meso_regiao_pop <- left_join(pop2024, meso_regiao, by = c("cod_municipio"="CD_GEOCODI"))

baseFinal <- left_join(newBahia, meso_regiao_pop, by=c("State"="codigo_uf", "City"="cod_munic6"))


if (confirmados == TRUE){
  write.table(baseFinal, paste0(dir, "/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(baseFinal, paste0(dir, "/2014-2025_DENGUE_NOTIFICADOS_dash_new.tsv"), sep = "\t", row.names = FALSE)
}
#############################################################
#consolidando arquvivo final q eu preciso


temp_1 <- temp %>%
  group_by(CLASSI_FIN, CRITERIO, EVOLUCAO) %>%
  dplyr::summarise(count = n()) %>%
  drop_na()




###### para ZE
t <- c("DENGBR00", "DENGBR01", "DENGBR02", "DENGBR03", "DENGBR04", "DENGBR05", "DENGBR06",
       "DENGBR07", "DENGBR08", "DENGBR09", "DENGBR10", "DENGBR11", "DENGBR12", "DENGBR13",
       "DENGBR14", "DENGBR15", "DENGBR16", "DENGBR17", "DENGBR18", "DENGBR19", "DENGBR20",
       "DENGBR21", "DENGBR22", "DENGBR23", "DENGBR24", "DENGBR25"
)
lists <- list()
i <- 1
confirmados <- FALSE
for (file in t){
  cat(file, "\n")
  base <- st_read(paste0(file, ".dbf"))
  pos0 <- which(names(base) %in% "CON_CLASSI")
  pos1 <- which(names(base) %in% "CON_CRITER")
  pos2 <- which(names(base) %in% "NU_IDADE")
  idade <- FALSE
  if (!identical(pos0, integer(0))){
    names(base)[pos0] <- "CLASSI_FIN"
    class <- TRUE
  }
  if (!identical(pos1, integer(0))){
    names(base)[pos1] <- "CRITERIO"
  }
  if (!identical(pos2, integer(0))){
    names(base)[pos2] <- "NU_IDADE_N"
    idade <- TRUE
  }
  leve      <- c(1, 6, 10)
  moderada  <- c(2, 7, 11)
  grave     <- c(3, 4, 8, 12)
  base$Dengue_class <- NA_character_
  base$Dengue_class[base$CLASSI_FIN %in% leve]     <- "1"
  base$Dengue_class[base$CLASSI_FIN %in% moderada] <- "2"
  base$Dengue_class[base$CLASSI_FIN %in% grave]    <- "3"
  if (confirmados == TRUE){
    base_temp <- subset(base, CRITERIO < 3 & !is.na(Dengue_class))
  }else{
    base_temp <- base
  }
  base_temp$Noti_Year <- as.numeric(paste0("20", gsub("[^0-9]", "", file)))
  
  if ("total" %in% colnames(base_temp)) {
    temp_agre <- base_temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, Noti_Year, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- base_temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, Noti_Year, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "Noti_Year", "State", "City", "Age_temp", "Sex", "Race_Colour", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  if (idade == FALSE){
    temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                            as.numeric(temp_agre$Age_temp), 
                            ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                   as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  }else{
    temp_agre$Age <-ifelse(substr(temp_agre$Age_temp, 1, 1) %in% c("M", "D", "I"), 0,
                           ifelse(substr(temp_agre$Age_temp, 1, 1) == "A",
                                  as.numeric(substr(temp_agre$Age_temp, 2, 4)),
                                  ifelse(nchar(temp_agre$Age_temp) == 2,
                                         as.numeric(temp_agre$Age_temp),
                                         as.numeric(substr(temp_agre$Age_temp, 3, 4)))))
  }
  temp_agre_final <- temp_agre %>% ungroup() %>%  select(Noti_Date, Noti_Week, Noti_Year, State, City, New_Cases, Age, Sex, Race_Colour)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == 1){
    newData <- temp_agre_final
  }else{
    newData <- rbind(newData, temp_agre_final)
  }
  i <- i + 1
}

if (confirmados == TRUE){
  write.table(newData, paste0(dir, "/2000-2025_DENGUE_CONFIRMADOS_new_ze.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(newData, paste0(dir, "/2000-2025_DENGUE_NOTIFICADOS_new_ze.tsv"), sep = "\t", row.names = FALSE)
}

calendario <- fread("../sinan_calendario.txt")
file <- "DENGBR20"
base <- st_read(paste0(file, ".dbf"))
temp <- subset(base, CRITERIO < 3 & (CLASSI_FIN >= 10 & CLASSI_FIN <= 12 ))
cale_2020 <- subset(calendario, ANO == 2020)
for (i in 1:nrow(cale_2020)){
  temp$SEM_NOT[which(temp$DT_NOTIFIC >= cale_2020$Início[i] & temp$DT_NOTIFIC <= cale_2020$Término[i])] <- cale_2020$SEM_NOT[i]
}

temp_agre <- temp %>%
  group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP) %>%
  dplyr::summarise(new_cases = n()) %>%
  # mutate(cum_cases = cumsum(new_cases)) %>%
  drop_na()

names(temp_agre) <- c("Noti_Date", "Noti_Week", "State", "City", "New_Cases")
temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
temp_agre_final <- temp_agre %>%
  ungroup() %>%
  dplyr::select(Noti_Date, Noti_Week, State, City, New_Cases)
temp_agre_final$City <- as.numeric(temp_agre_final$City)
temp_agre_final$City <- as.numeric(temp_agre_final$City)


pop2024 <- populacao_municipios(2024)
temp_agre_final$State <- as.numeric(temp_agre_final$State)

temp_agre_final_1 <- left_join(temp_agre_final, pop2024, by=c("State"="codigo_uf", "City"="cod_munic6"))

write.table(temp_agre_final_1, paste0(dir, "/2020_DENGUE_CONFIRMADOS_new.tsv"), sep = "\t", row.names = FALSE)

names(temp)
###### para Walter
setwd(mypath)
t <- c("DENGBR14", "DENGBR15", "DENGBR16", "DENGBR17", "DENGBR18", "DENGBR19", "DENGBR20",
       "DENGBR21", "DENGBR22", "DENGBR23", "DENGBR24", "DENGBR25"
)
lists <- list()
i <- 1
confirmados <- TRUE
for (file in t){
  cat(file, "\n")
  base <- st_read(paste0(file, ".dbf"))
  pos0 <- which(names(base) %in% "CON_CLASSI")
  pos1 <- which(names(base) %in% "CON_CRITER")
  pos2 <- which(names(base) %in% "NU_IDADE")
  idade <- FALSE
  if (!identical(pos0, integer(0))){
    names(base)[pos0] <- "CLASSI_FIN"
    class <- TRUE
  }
  if (!identical(pos1, integer(0))){
    names(base)[pos1] <- "CRITERIO"
  }
  if (!identical(pos2, integer(0))){
    names(base)[pos2] <- "NU_IDADE_N"
    idade <- TRUE
  }
  leve      <- c(1, 6, 10)
  moderada  <- c(2, 7, 11)
  grave     <- c(3, 4, 8, 12)
  base$Dengue_class <- NA_character_
  base$Dengue_class[base$CLASSI_FIN %in% leve]     <- "1"
  base$Dengue_class[base$CLASSI_FIN %in% moderada] <- "2"
  base$Dengue_class[base$CLASSI_FIN %in% grave]    <- "3"
  if (confirmados == TRUE){
    base_temp <- subset(base, CRITERIO < 3 & !is.na(Dengue_class) & EVOLUCAO == 2)
  }else{
    base_temp <- subset(base, EVOLUCAO == 2 | EVOLUCAO == 4)
  }
  base_temp$Noti_Year <- as.numeric(paste0("20", gsub("[^0-9]", "", file)))
  
  if ("total" %in% colnames(base_temp)) {
    temp_agre <- base_temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, Noti_Year, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, EVOLUCAO) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- base_temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, Noti_Year, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, EVOLUCAO) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "Noti_Year", "State", "City", "Age_temp", "Sex", "Race_Colour", "Deaths", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  if (idade == FALSE){
    temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                            as.numeric(temp_agre$Age_temp), 
                            ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                   as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  }else{
    temp_agre$Age <-ifelse(substr(temp_agre$Age_temp, 1, 1) %in% c("M", "D", "I"), 0,
                           ifelse(substr(temp_agre$Age_temp, 1, 1) == "A",
                                  as.numeric(substr(temp_agre$Age_temp, 2, 4)),
                                  ifelse(nchar(temp_agre$Age_temp) == 2,
                                         as.numeric(temp_agre$Age_temp),
                                         as.numeric(substr(temp_agre$Age_temp, 3, 4)))))
  }
  temp_agre_final <- temp_agre %>% ungroup() %>%  select(Noti_Date, Noti_Week, Noti_Year, State, City, New_Cases, Age, Sex, Race_Colour, Deaths)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == 1){
    newData <- temp_agre_final
  }else{
    newData <- rbind(newData, temp_agre_final)
  }
  i <- i + 1
}

if (confirmados == TRUE){
  write.table(newData, paste0(dir, "/2014-2025_DENGUE_CONFIRMADOS_new_Walter_deaths.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(newData, paste0(dir, "/2014-2025_DENGUE_NOTIFICADOS_new_Walter_deaths.tsv"), sep = "\t", row.names = FALSE)
}


notificados <- fread(paste0(dir, "/2014-2025_DENGUE_NOTIFICADOS_new_Walter_deaths.tsv"))

notificados

noti_agre <- notificados %>%
  group_by(Noti_Year) %>%
  dplyr::summarise(noti_deaths = n()) %>%
  drop_na()

confi_agre <- newData %>%
  group_by(Noti_Year) %>%
  dplyr::summarise(confi_deaths = n()) %>%
  drop_na()

deaths <- left_join(noti_agre, confi_agre)

write.table(deaths, paste0(dir, "/deaths.tsv"), sep = "\t", row.names = FALSE)

file <- t[i]
cat(file, "\n")

base <- read.dbf(paste0(file, ".dbf"))
lists[[i]] <- names(base) 
i <- i + 1

library(sf)
base0 <- st_read(paste0("DENGBR01.dbf"))
base1 <- st_read(paste0("DENGBR13.dbf"))

# [1] "ID_MUNICIP" "ID_UNIDADE" "DT_NOTIFIC" "CS_RACA"    "CS_ESCOLAR" "NU_ANO"     "SEM_NOT"   
# [8] "SG_UF_NOT"  "ID_REGIONA" "DT_SIN_PRI" "SEM_PRI"    "NU_IDADE"   "CS_SEXO"    "ID_MN_RESI"
# [15] "ID_RG_RESI" "SG_UF"      "ID_PAIS"    "ID_DG_NOT"  "ID_EV_NOT"  "ANT_DT_INV" "OCUPACAO"  
# [22] "DENGUE"     "ANO"        "VACINADO"   "DT_DOSE"    "FEBRE"      "DT_FEBRE"   "DURACAO"   
# [29] "LACO"       "CEFALEIA"   "EXANTEMA"   "DOR"        "PROSTACAO"  "MIALGIA"    "NAUSEAS"   
# [36] "ARTRALGIA"  "DIARREIA"   "OUTROS"     "SIN_OUT"    "EPISTAXE"   "PETEQUIAS"  "GENGIVO"   
# [43] "METRO"      "HEMATURA"   "SANGRAM"    "OUTROS_M"   "OUTROS_M_D" "ASCITE"     "PLEURAL"   
# [50] "PERICARDI"  "ABDOMINAL"  "HEPATO"     "MIOCARDI"   "HIPOTENSAO" "CHOQUE"     "MANIFESTA" 
# [57] "INSUFICIEN" "OUTRO_S"    "OUTRO_S_D"  "DT_CHOQUE"  "HOSPITALIZ" "DT_INTERNA" "UF"        
# [64] "MUNICIPIO"  "DT_COL_HEM" "HEMA_MAIOR" "DT_COL_PLQ" "PALQ_MAIOR" "DT_COL_HE2" "HEMA_MENOR"
# [71] "DT_COL_PL2" "PLAQ_MENOR" "DT_SORO1"   "DT_SORO2"   "DT_SOROR1"  "DT_SOROR2"  "S1_IGM"    
# [78] "S1_IGG"     "S2_IGM"     "S2_IGG"     "S1_TIT1"    "S2_TIT1"    "MATERIAL"   "SORO1"     
# [85] "SORO2"      "TECIDOS"    "RESUL_VIRA" "HISTOPA"    "IMUNOH"     "AMOS_PCR"   "RESUL_PCR" 
# [92] "AMOS_OUT"   "TECNICA"    "RESUL_OUT"  "CON_CLASSI" "CON_CRITER" "CON_FHD"    "CON_INF_MU"
# [99] "CON_INF_UF" "CON_INF_PA" "CON_DOENCA" "CON_EVOLUC" "CON_DT_OBI" "CON_DT_ENC" "IN_VINCULA"
# [106] "NDUPLIC"    "IN_AIDS"  
# 

names(table(base1$CRITERIO))
unique(base1$CRITERIO)



# CLASSI_FIN = CON_CLASSI
# CRITERIO = CON_CRITER
NU_IDADE_N = NU_IDADE
# 
# DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N = NU_IDADE, CS_SEXO, CS_RACA

pos0 <- which(names(base0) %in% "CON_CLASSI")
pos1 <- which(names(base0) %in% "CON_CRITER")
pos2 <- which(names(base0) %in% "NU_IDADE")

if (!identical(pos0, integer(0))){
  names(base0)[pos0] <- "CLASSI_FIN"
}
if (!identical(pos1, integer(0))){
  names(base0)[pos1] <- "CRITERIO"
}
if (!identical(pos2, integer(0))){
  names(base0)[pos2] <- "NU_IDADE_N"
}

if (which(names(base1) %in% "CON_CRITER")) {
  print(paste("A coluna CRITERIO existe no dataframe."))
} else {
  print(paste("A coluna CRITERIO não existe no dataframe."))
}



nome_da_coluna %in% nomes_das_colunas

# sort(unique(base0$NU_IDADE))


setwd(paste0(dir,"arb"))
files_dbc <- list.files(path = paste0(dir,"arb"), pattern = ".dbc")
files_dbf <- list.files(path = paste0(dir,"arb"), pattern = ".dbf")
files <- setdiff(str_replace_all(files_dbc, ".dbc", ""), str_replace_all(files_dbf, ".dbf", ""))


for(i in 1:length(files)){
  file <- tools::file_path_sans_ext(paste0(files[i], ".dbc"))
  temp <- dbc2dbf(paste0(file, ".dbc"), paste0(file, ".dbf"))
  base <- read.dbf(paste0(file, ".dbf"))
  write.table(base, paste0(dir, "arb_tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
  cat(file, "ok - \n")
}




startFile <- 1
SUF = "DENG"
myfiles <- list.files(paste0(dir, "arb_tsv/"), pattern = paste0(SUF, "*"))
# myfiles <- myfiles[substring(fil,1,4)=="DEN"]
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
confirmados <- TRUE
for(i in startFile:length(myfiles)){
  tempFile <- fread(paste0(dir, "arb_tsv/", myfiles[i]), stringsAsFactors = FALSE, showProgress = FALSE)
  tempFile$weekStart <- NA
  myYearCalen <- paste0(20,str_replace_all(myfiles[i], "[^0-9]", ""))
  cale_year <- subset(calendario, ANO == myYearCalen)
  for (icale in 1:nrow(cale_year)){
    tempFile$SEM_NOT[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- cale_year$SEM_NOT[icale]
    tempFile$weekStart[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- as.character(cale_year$Início[icale])
  }
  cat("i:", i, "- File: ", myfiles[i], "\n")
  # temp <- subset(tempFile, SG_UF_NOT == 31)
  if (confirmados == TRUE){
    temp <- subset(tempFile, CRITERIO < 3 & (CLASSI_FIN >= 10 & CLASSI_FIN <= 12 ))
  }else{
    temp <- tempFile
  }
  
  if ("total" %in% colnames(temp)) {
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "State", "City", "Age_temp", "Sex", "Race_Colour", "weekStart", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                          as.numeric(temp_agre$Age_temp), 
                          ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                 as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  temp_agre_final <- temp_agre %>%
    ungroup() %>%
    dplyr::select(Noti_Date, Noti_Week, State, City, New_Cases, Age, Sex, Race_Colour, weekStart)
  
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == startFile){
    newBahia <- temp_agre_final
  }else{
    newBahia <- rbind(newBahia, temp_agre_final)
  }
}

pop2024 <- populacao_municipios(2024)
meso_regiao <- read_xls(paste0(dir, "regioes_geograficas_composicao_por_municipios_2017_20180911.xls"))
meso_regiao_pop <- left_join(pop2024, meso_regiao, by = c("cod_municipio"="CD_GEOCODI"))
baseFinal <- left_join(newBahia, meso_regiao_pop, by=c("State"="codigo_uf", "City"="cod_munic6"))

if (confirmados == TRUE){
  write.table(baseFinal, paste0(dir, "/2014-2025_DENV_CONFIRMADOS_new.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(baseFinal, paste0(dir, "/2014-2025_DENV_NOTIFICADOS_new.tsv"), sep = "\t", row.names = FALSE)
}




startFile <- 1
SUF = "CHIK"
myfiles <- list.files(paste0(dir, "arb_tsv/"), pattern = paste0(SUF, "*"))
# myfiles <- myfiles[substring(fil,1,4)=="DEN"]
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
confirmados <- FALSE
for(i in startFile:length(myfiles)){
  tempFile <- fread(paste0(dir, "arb_tsv/", myfiles[i]), stringsAsFactors = FALSE, showProgress = FALSE)
  tempFile$weekStart <- NA
  myYearCalen <- paste0(20,str_replace_all(myfiles[i], "[^0-9]", ""))
  cale_year <- subset(calendario, ANO == myYearCalen)
  for (icale in 1:nrow(cale_year)){
    tempFile$SEM_NOT[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- cale_year$SEM_NOT[icale]
    tempFile$weekStart[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- as.character(cale_year$Início[icale])
  }
  cat("i:", i, "- File: ", myfiles[i], "\n")
  # temp <- subset(tempFile, SG_UF_NOT == 31)
  if (confirmados == TRUE){
    temp <- subset(tempFile, CRITERIO < 3 & (CLASSI_FIN <= 2 | CLASSI_FIN == 13 ))
  }else{
    temp <- tempFile
  }
  
  if ("total" %in% colnames(temp)) {
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "State", "City", "Age_temp", "Sex", "Race_Colour", "weekStart", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                          as.numeric(temp_agre$Age_temp), 
                          ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                 as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  temp_agre_final <- temp_agre %>%
    ungroup() %>%
    dplyr::select(Noti_Date, Noti_Week, State, City, New_Cases, Age, Sex, Race_Colour, weekStart)
  
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == startFile){
    newBahia <- temp_agre_final
  }else{
    newBahia <- rbind(newBahia, temp_agre_final)
  }
}

pop2024 <- populacao_municipios(2024)
meso_regiao <- read_xls(paste0(dir, "regioes_geograficas_composicao_por_municipios_2017_20180911.xls"))
meso_regiao_pop <- left_join(pop2024, meso_regiao, by = c("cod_municipio"="CD_GEOCODI"))
baseFinal <- left_join(newBahia, meso_regiao_pop, by=c("State"="codigo_uf", "City"="cod_munic6"))

if (confirmados == TRUE){
  write.table(baseFinal, paste0(dir, "/2015-2025_CHIKV_CONFIRMADOS_new.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(baseFinal, paste0(dir, "/2015-2025_CHIKV_NOTIFICADOS_new.tsv"), sep = "\t", row.names = FALSE)
}



startFile <- 1
SUF = "ZIKA"
myfiles <- list.files(paste0(dir, "arb_tsv/"), pattern = paste0(SUF, "*"))
# myfiles <- myfiles[substring(fil,1,4)=="DEN"]
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
confirmados <- FALSE
for(i in startFile:length(myfiles)){
  tempFile <- fread(paste0(dir, "arb_tsv/", myfiles[i]), stringsAsFactors = FALSE, showProgress = FALSE)
  tempFile$weekStart <- NA
  myYearCalen <- paste0(20,str_replace_all(myfiles[i], "[^0-9]", ""))
  cale_year <- subset(calendario, ANO == myYearCalen)
  for (icale in 1:nrow(cale_year)){
    tempFile$SEM_NOT[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- cale_year$SEM_NOT[icale]
    tempFile$weekStart[which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] & tempFile$DT_NOTIFIC <= cale_year$Término[icale])] <- as.character(cale_year$Início[icale])
  }
  cat("i:", i, "- File: ", myfiles[i], "\n")
  # temp <- subset(tempFile, SG_UF_NOT == 31)
  if (confirmados == TRUE){
    temp <- subset(tempFile, CRITERIO < 3 & (CLASSI_FIN >= 1 & CLASSI_FIN <= 2 ))
  }else{
    temp <- tempFile
  }
  
  if ("total" %in% colnames(temp)) {
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = sum(total)) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }else{
    temp_agre <- temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, weekStart) %>%
      dplyr::summarise(new_cases = n()) %>%
      # mutate(cum_cases = cumsum(new_cases)) %>%
      drop_na()
  }
  
  names(temp_agre) <- c("Noti_Date", "Noti_Week", "State", "City", "Age_temp", "Sex", "Race_Colour", "weekStart", "New_Cases")
  temp_agre$Noti_Date <- as.Date(temp_agre$Noti_Date)
  temp_agre$Race_Colour <- factor(temp_agre$Race_Colour, levels = c(1, 2, 3, 4, 5, 9), labels = c("Branca", "Preta", "Amarela", "Parda", "Indigena", "Ignorado"))
  temp_agre$Age <- ifelse(nchar(temp_agre$Age_temp) == 2, 
                          as.numeric(temp_agre$Age_temp), 
                          ifelse(substr(temp_agre$Age_temp, 1, 2) == "40", 
                                 as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0))
  temp_agre_final <- temp_agre %>%
    ungroup() %>%
    dplyr::select(Noti_Date, Noti_Week, State, City, New_Cases, Age, Sex, Race_Colour, weekStart)
  
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)
  if (i == startFile){
    newBahia <- temp_agre_final
  }else{
    newBahia <- rbind(newBahia, temp_agre_final)
  }
}

pop2024 <- populacao_municipios(2024)
meso_regiao <- read_xls(paste0(dir, "regioes_geograficas_composicao_por_municipios_2017_20180911.xls"))
meso_regiao_pop <- left_join(pop2024, meso_regiao, by = c("cod_municipio"="CD_GEOCODI"))
baseFinal <- left_join(newBahia, meso_regiao_pop, by=c("State"="codigo_uf", "City"="cod_munic6"))

if (confirmados == TRUE){
  write.table(baseFinal, paste0(dir, "/2016-2025_ZIKV_CONFIRMADOS_new.tsv"), sep = "\t", row.names = FALSE)
}else{
  write.table(baseFinal, paste0(dir, "/2016-2025_ZIKV_NOTIFICADOS_new.tsv"), sep = "\t", row.names = FALSE)
}




zikv <- fread(paste0(dir, "/2016-2025_ZIKV_CONFIRMADOS_new.tsv"))
chikv <- fread(paste0(dir, "/2015-2025_CHIKV_CONFIRMADOS_new.tsv"))
denv <- fread(paste0(dir, "/2014-2025_DENV_CONFIRMADOS_new.tsv"))


arbo <- rbind(denv, chikv, zikv)

# "Noti_Date"     "Noti_Week"     "State"         "City"          "New_Cases"
# "weekStart"     "uf"            "codigo_munic"  "nome_munic"

arbo_agre <- arbo %>%
  group_by(weekStart, Noti_Week, State, City, uf, cod_municipio, nome_munic) %>%
  dplyr::summarise(new_cases = sum(New_Cases)) %>%
  drop_na()

write.table(arbo_agre, paste0(dir, "/2014-2025_ARBO_CONFIRMADOS_new.tsv"), sep = "\t", row.names = FALSE)



'
# Cheque se os arquivos .dbc têm tamanho razoável (> 0 bytes)
file.info(list.files(mypath, pattern = ".dbc", full.names = TRUE))$size


files_dbc <- list.files(path = mypath, pattern = "\\.dbc$", full.names = TRUE)

for(f in files_dbc){
  result <- tryCatch({
    out <- sub("\\.dbc$", ".dbf", f)
    dbc2dbf(f, out)
    "OK"
  }, error = function(e) paste("ERRO:", conditionMessage(e)))
  
  cat(basename(f), "->", result, "\n")
}

# Apaga o arquivo corrompido
file.remove(paste0(mypath, "DENGBR08.dbc"))

# Re-download
options(timeout = 300)
download.file(
  url      = "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/FINAIS/DENGBR08.dbc",
  destfile = paste0(mypath, "DENGBR08.dbc"),
  mode     = "wb",
  quiet    = FALSE
)

# Testa depois do download
tryCatch({
  dbc2dbf(paste0(mypath, "DENGBR08.dbc"), paste0(mypath, "DENGBR08.dbf"))
  cat("OK - arquivo convertido com sucesso\n")
}, error = function(e) cat("Ainda com erro:", conditionMessage(e), "\n"))


list.files(mypath, pattern = "\\.dbc$")

# A URL deve terminar assim: .../FINAIS/DENGBR00.dbc
# Pegue a posição onde começa "DENG"
url_exemplo <- filenames[1]
cat(url_exemplo, "\n")
cat("tam correto:", regexpr("DENG", url_exemplo)[1], "\n")

file.remove(list.files(mypath, pattern = "\\.dbc$", full.names = TRUE))
file.remove(list.files(mypath, pattern = "\\.dbf$", full.names = TRUE))

url <- DOWN
filenames <- getURL(url, ftp.use.epsv = FALSE, dirlistonly = TRUE)
filenames <- paste(url, strsplit(filenames, "\r*\n")[[1]], sep = "")
filenames <- filenames[grep(SUF, filenames)]

tam = 63
options(timeout = 300)

for (i in 1:length(filenames)) {
  destfile <- paste0(mypath, substring(filenames[i], tam))
  cat("Baixando:", substring(filenames[i], tam), "\n")
  download.file(url = filenames[i], destfile = destfile, mode = "wb", quiet = FALSE)
}

 

list.files(mypath, pattern = "\\.dbc$")

setwd(mypath)
files_dbc <- list.files(path = mypath, pattern = ".dbc")
files_dbf <- list.files(path = mypath, pattern = ".dbf")
files <- setdiff(str_replace_all(files_dbc, ".dbc", ""), str_replace_all(files_dbf, ".dbf", ""))

for(i in 1:length(files)){
  file <- tools::file_path_sans_ext(paste0(files[i], ".dbc"))
  tryCatch({
    temp <- dbc2dbf(paste0(file, ".dbc"), paste0(file, ".dbf"))
    base <- read.dbf(paste0(file, ".dbf"))
    write.table(base, paste0(dir, "tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
    cat(file, "ok\n")
  }, error = function(e) cat("ERRO em", file, ":", conditionMessage(e), "\n"))
}
#####
problemas <- c("DENGBR08.dbc", "DENGBR13.dbc")

# Remove os corrompidos
file.remove(paste0(mypath, problemas))

# Re-baixa
options(timeout = 600)  # timeout maior pois podem ser arquivos grandes
for(arq in problemas){
  cat("Baixando:", arq, "\n")
  download.file(
    url      = paste0("ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/FINAIS/", arq),
    destfile = paste0(mypath, arq),
    mode     = "wb",
    quiet    = FALSE
  )
}

####


for(arq in c("DENGBR08", "DENGBR13")){
  tryCatch({
    dbc2dbf(paste0(arq, ".dbc"), paste0(arq, ".dbf"))
    base <- read.dbf(paste0(arq, ".dbf"))
    write.table(base, paste0(dir, "tsv/", arq, ".tsv"), sep = "\t", row.names = FALSE)
    cat(arq, "ok\n")
  }, error = function(e) cat("ERRO em", arq, ":", conditionMessage(e), "\n"))
}

####
dbc2dbf("DENGBR08.dbc", "DENGBR08.dbf")
base <- read.dbf("DENGBR08.dbf")

# Identifica colunas problemáticas
for(col in names(base)){
  tryCatch({
    max_char <- max(nchar(as.character(base[[col]])), na.rm = TRUE)
    if(max_char > 1000) cat("Coluna:", col, "- max chars:", max_char, "\n")
  }, error = function(e) cat("Coluna com problema:", col, "\n"))
}


library(sf)

base <- st_read("DENGBR08.dbf")

# Se funcionar, salva como tsv
write.table(base, paste0(dir, "tsv/DENGBR08.tsv"), sep = "\t", row.names = FALSE)
cat("DENGBR08 ok\n")

write.table(base, paste0(dir, "tsv/DENGBR08.tsv"), sep = "\t", row.names = FALSE)
cat("DENGBR08 ok\n")


cat("DENGBR08 ok\n")
' 
#
