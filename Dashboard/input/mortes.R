library(sf)
library(dplyr)
library(tidyverse)

dir <- "/home/christian/Scientific_Initiation_Dashboard/Dashboard/input"
setwd("/home/christian/Scientific_Initiation_Dashboard/Dashboard/input/finais")

t <- c("DENGBR14", "DENGBR15", "DENGBR16", "DENGBR17", "DENGBR18", "DENGBR19", "DENGBR20",
       "DENGBR21", "DENGBR22", "DENGBR23", "DENGBR24", "DENGBR25")

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
      dplyr::summarise(new_cases = sum(total), .groups = "drop") %>%
      drop_na()
  }else{
    temp_agre <- base_temp %>%
      group_by(DT_NOTIFIC, SEM_NOT, Noti_Year, SG_UF_NOT, ID_MUNICIP, NU_IDADE_N, CS_SEXO, CS_RACA, EVOLUCAO) %>%
      dplyr::summarise(new_cases = n(), .groups = "drop") %>%
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
    temp_agre$Age <- ifelse(substr(temp_agre$Age_temp, 1, 1) %in% c("M", "D", "I"), 0,
                            ifelse(substr(temp_agre$Age_temp, 1, 1) == "A",
                                   as.numeric(substr(temp_agre$Age_temp, 2, 4)),
                                   ifelse(nchar(temp_agre$Age_temp) == 2,
                                          as.numeric(temp_agre$Age_temp),
                                          as.numeric(substr(temp_agre$Age_temp, 3, 4)))))
  }
  temp_agre_final <- temp_agre %>%
    ungroup() %>%
    select(Noti_Date, Noti_Week, Noti_Year, State, City, New_Cases, Age, Sex, Race_Colour, Deaths)
  temp_agre_final$City <- as.numeric(temp_agre_final$City)

  # Salva no disco em vez de acumular na RAM
  write.table(temp_agre_final,
              paste0(dir, "/mortes_temp_", file, ".tsv"),
              sep = "\t", row.names = FALSE)

  cat("[", format(Sys.time()), "]", file, "salvo\n")
  rm(base, base_temp, temp_agre, temp_agre_final)
  gc()
  i <- i + 1
}

cat("Todos processados. Concatenando...\n")

outfile <- if (confirmados) {
  paste0(dir, "/2014-2025_DENGUE_MORTES_CONFIRMADOS_.tsv")
} else {
  paste0(dir, "/2014-2025_DENGUE_MORTES_NOTIFICADOS_.tsv")
}

primeiro <- TRUE
for (file in t) {
  temp_path <- paste0(dir, "/mortes_temp_", file, ".tsv")
  chunk <- read.table(temp_path, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
  write.table(chunk, outfile, sep = "\t", row.names = FALSE,
              col.names = primeiro, append = !primeiro)
  primeiro <- FALSE
  rm(chunk)
  gc()
}

cat("Concluido:", outfile, "\n")
