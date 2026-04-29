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
library(sf)

cat("[", format(Sys.time()), "] Iniciando pipeline dengue\n")

dir    <- "/data/input/"
B_fin  <- paste0(dir, "finais/")
B_par  <- paste0(dir, "parciais/")
SUF    <- "DENG"
tam    <- 63
mypath <- B_fin

DOWN <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/FINAIS/"
options(timeout = 300)

# ── Download ──────────────────────────────────────────────────────────────────
cat("[", format(Sys.time()), "] Listando arquivos no FTP...\n")
url       <- DOWN
filenames <- getURL(url, ftp.use.epsv = FALSE, dirlistonly = TRUE)
filenames <- paste(url, strsplit(filenames, "\r*\n")[[1]], sep = "")
filenames <- filenames[grep(SUF, filenames)]

setwd(mypath)
fil <- list.files(pattern = ".dbc")
fil <- fil[substring(fil, 1, 4) == SUF]

if (length(fil) > 0) {
  arq <- NULL
  for (i in seq_along(fil)) {
    arq_ <- grep(fil[i], filenames)
    arq  <- rbind(arq, arq_)
  }
  arq_ <- filenames[-arq]
} else {
  arq_ <- filenames
}

cat("[", format(Sys.time()), "] Arquivos para atualizar:", length(arq_), "\n")

if (length(arq_) > 0) {
  for (i in seq_along(arq_)) {
    cat("[", format(Sys.time()), "] Baixando:", basename(arq_[i]), "\n")
    download.file(url = arq_[i], destfile = substring(arq_[i], tam), mode = "wb")
  }
}

# ── Conversão .dbc → .dbf → .tsv ─────────────────────────────────────────────
cat("[", format(Sys.time()), "] Convertendo arquivos DBC...\n")
setwd(mypath)
files_dbc <- list.files(path = mypath, pattern = "\\.dbc$")
files_dbf <- list.files(path = mypath, pattern = "\\.dbf$")
files     <- setdiff(
  str_replace_all(files_dbc, "\\.dbc$", ""),
  str_replace_all(files_dbf, "\\.dbf$", "")
)

for (i in seq_along(files)) {
  file <- files[i]
  cat("[", format(Sys.time()), "] Convertendo:", file, "\n")
  tryCatch({
    dbc2dbf(paste0(file, ".dbc"), paste0(file, ".dbf"))
    base <- tryCatch(
      read.dbf(paste0(file, ".dbf")),
      error = function(e) as.data.frame(sf::st_read(paste0(file, ".dbf")))
    )
    write.table(base, paste0(dir, "tsv/", file, ".tsv"), sep = "\t", row.names = FALSE)
    cat("[", format(Sys.time()), "]", file, "ok\n")
  }, error = function(e) {
    cat("[", format(Sys.time()), "] ERRO em", file, ":", conditionMessage(e), "\n")
  })
}

# ── Agregação ─────────────────────────────────────────────────────────────────
calendario <- fread(paste0(dir, "sinan_calendario.txt"))
myfiles    <- list.files(paste0(dir, "tsv/"), pattern = paste0(SUF, ".*\\.tsv$"))
myfiles    <- myfiles[13:length(myfiles)]

run_aggregation <- function(confirmados) {
  cat("[", format(Sys.time()), "] Agregando - confirmados =", confirmados, "\n")
  result <- NULL

  for (i in seq_along(myfiles)) {
    cat("[", format(Sys.time()), "] Processando:", myfiles[i], "\n")
    tempFile <- fread(paste0(dir, "tsv/", myfiles[i]),
                      stringsAsFactors = FALSE, showProgress = FALSE)

    myYearCalen <- paste0("20", str_replace_all(myfiles[i], "[^0-9]", ""))
    cale_year   <- subset(calendario, ANO == myYearCalen)

    tempFile$weekStart <- NA
    for (icale in seq_len(nrow(cale_year))) {
      idx <- which(tempFile$DT_NOTIFIC >= cale_year$Início[icale] &
                   tempFile$DT_NOTIFIC <= cale_year$Término[icale])
      tempFile$SEM_NOT[idx]   <- cale_year$SEM_NOT[icale]
      tempFile$weekStart[idx] <- as.character(cale_year$Início[icale])
    }

    if (confirmados) {
      temp <- subset(tempFile, CRITERIO < 3 & (CLASSI_FIN >= 10 & CLASSI_FIN <= 12))
    } else {
      temp <- tempFile
    }

    if ("total" %in% colnames(temp)) {
      temp_agre <- temp %>%
        group_by(DT_NOTIFIC, SEM_NOT, weekStart, SG_UF_NOT, ID_MUNICIP,
                 NU_IDADE_N, CS_SEXO, CS_RACA) %>%
        dplyr::summarise(new_cases = sum(total), .groups = "drop") %>%
        drop_na()
    } else {
      temp_agre <- temp %>%
        group_by(DT_NOTIFIC, SEM_NOT, weekStart, SG_UF_NOT, ID_MUNICIP,
                 NU_IDADE_N, CS_SEXO, CS_RACA) %>%
        dplyr::summarise(new_cases = n(), .groups = "drop") %>%
        drop_na()
    }

    names(temp_agre) <- c("Noti_Date", "Noti_Week", "weekStart", "State",
                          "City", "Age_temp", "Sex", "Race_Colour", "New_Cases")

    temp_agre$Noti_Date    <- as.Date(temp_agre$Noti_Date)
    temp_agre$Race_Colour  <- factor(temp_agre$Race_Colour,
                                     levels = c(1, 2, 3, 4, 5, 9),
                                     labels = c("Branca", "Preta", "Amarela",
                                                "Parda", "Indigena", "Ignorado"))
    temp_agre$Age <- ifelse(
      nchar(temp_agre$Age_temp) == 2,
      as.numeric(temp_agre$Age_temp),
      ifelse(substr(temp_agre$Age_temp, 1, 2) == "40",
             as.numeric(substr(temp_agre$Age_temp, 3, 4)), 0)
    )

    temp_agre_final <- temp_agre %>%
      ungroup() %>%
      dplyr::select(Noti_Date, Noti_Week, weekStart, State, City,
                    New_Cases, Age, Sex, Race_Colour)
    temp_agre_final$City <- as.numeric(temp_agre_final$City)

    result <- if (is.null(result)) temp_agre_final else rbind(result, temp_agre_final)
  }

  # Join com população e regiões
  pop2024      <- populacao_municipios(2024)
  meso_regiao  <- readxl::read_xls(paste0(dir,
    "regioes_geograficas_composicao_por_municipios_2017_20180911.xls"))
  meso_regiao_pop <- left_join(pop2024, meso_regiao, by = c("cod_municipio" = "CD_GEOCODI"))
  
  result$State <- as.numeric(result$State)
  result$City  <- as.numeric(result$City)
  
  baseFinal <- left_join(result, meso_regiao_pop,
                         by = c("State" = "codigo_uf", "City" = "cod_munic6"))
  baseFinal       <- left_join(result, meso_regiao_pop,
                               by = c("State" = "codigo_uf", "City" = "cod_munic6"))

  outfile <- if (confirmados) {
    paste0(dir, "2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
  } else {
    paste0(dir, "2014-2025_DENGUE_NOTIFICADOS_dash_new.tsv")
  }

  write.table(baseFinal, outfile, sep = "\t", row.names = FALSE)
  cat("[", format(Sys.time()), "] Salvo:", outfile, "\n")
}

run_aggregation(confirmados = FALSE)
run_aggregation(confirmados = TRUE)

cat("[", format(Sys.time()), "] Pipeline concluído.\n")
