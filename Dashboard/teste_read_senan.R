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
# devtools::install_github("danicat/read.dbc")


dir <- "/Users/vagner/Documents/Vagner/uneb/sinan/"
B_fin <- paste0(dir, "finais/")
B_par <- paste0(dir, "parciais/")
SUF <- c("DENG")
tam = 64
mypath <- B_fin

if (mypath == B_fin){
  DOWN <- c("ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/FINAIS/")
  options(timeout = 60)
}else{
  DOWN <- c("ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/")
  options(timeout = 1000)
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


for(i in 1:length(files)){
  file <- tools::file_path_sans_ext(paste0(files[i], ".dbc"))
  temp <- dbc2dbf(paste0(file, ".dbc"), paste0(file, ".dbf"))
  base <- read.dbf(paste0(file, ".dbf"))
  write.table(base, paste0(dir, "tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
  cat(file, "ok - \n")
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

startFile <- 1
myfiles <- list.files(paste0(dir, "tsv/"), pattern = paste0(SUF, "*"))
myfiles <- myfiles[13:length(myfiles)]
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
confirmados <- FALSE
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
