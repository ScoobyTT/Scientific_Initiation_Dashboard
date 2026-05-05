library(data.table)
library(tidyverse)
library(ribge)
library(geobr)

setwd("/home/christian/Scientific_Initiation_Dashboard/Dashboard/")

# Grafico 1
dengue_data <- fread("input/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
dengue_conf <- fread("input/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
pop <- ribge::populacao_municipios(2024)
estado <- read_state(year = 2020)


dengue_data <- dengue_data %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state),
    by = c("State" = "code_state")
  )

dengue_conf <- dengue_conf %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state),
    by = c("State" = "code_state")
  )
#pro caso de ser nessario o uso das colunas de 'meses(month), codigo do estado(code_state) e estado(name_state)'
'
dengue_data <- dengue_data %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state),
    by = c("State" = "code_state")
  )
dengue_conf <- dengue_conf %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state),
    by = c("State" = "code_state")
    
  )

dengue_data_agre_n <- dengue_data %>%
  group_by(Noti_Date, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases)) %>%
  drop_na()

dengue_data_agre_c <- dengue_conf %>%
  group_by(Noti_Date, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases)) %>%
  drop_na()

names(dengue_data_agre_n) <- c("months", "abbrev_state", "New_Cases_Noti")
names(dengue_data_agre_c) <- c("months", "abbrev_state", "New_Cases_Conf")

dengue_data_agre_p1 <- left_join(dengue_data_agre_n, dengue_data_agre_c, 
                                 by = c("months", "abbrev_state"))

write_tsv(dengue_data_agre_p1, file = "input/plot_1_ultimoTeste.tsv")
'


dengue_data_agre_n <- dengue_data %>%
  group_by(weekStart) %>%
  summarise(New_Cases = sum(New_Cases)) %>%
  drop_na()

dengue_data_agre_c <- dengue_conf %>%
  group_by(weekStart) %>% 
  summarise(New_Cases = sum(New_Cases)) %>%
  drop_na()

names(dengue_data_agre_n) <- c("weekStart", "New_Cases_Noti")
names(dengue_data_agre_c) <- c("weekStart", "New_Cases_Conf")

dengue_data_agre_p1 <- left_join(dengue_data_agre_n, dengue_data_agre_c, by=c("weekStart"="weekStart"))

write_tsv(dengue_data_agre_p1, file = "input/plot_1.tsv")

# Grafico 3 Piramide

dengue_data_pyramid_noti <- dengue_data %>% 
  mutate(
    New_Cases = case_when(
      Sex == "M" ~ -New_Cases,
      TRUE ~ New_Cases
    ),
    Age_Group = cut(
      Age,
      breaks = c(0, 4, 9, 19, 29, 39, 49, 59, 69, 79, Inf),
      labels = c("0-4", "5-9", "10-19", "20-29", "30-39", "40-49", 
                 "50-59", "60-69", "70-79", "80+"),
      right = FALSE
    )
  )


dengue_data_pyramid_conf <- dengue_conf %>% 
  mutate(
    New_Cases = case_when(
      Sex == "M" ~ -New_Cases,
      TRUE ~ New_Cases
    ),
    Age_Group = cut(
      Age,
      breaks = c(0, 4, 9, 19, 29, 39, 49, 59, 69, 79, Inf),
      labels = c("0-4", "5-9", "10-19", "20-29", "30-39", "40-49", 
                 "50-59", "60-69", "70-79", "80+"),
      right = FALSE
    )
  )

dengue_data_pyramid_conf_agre <- dengue_data_pyramid_conf %>%
  group_by(Sex, Age, Age_Group, abbrev_state) %>%
  summarise(New_Cases_Conf = sum(New_Cases)) %>%
  drop_na()


dengue_data_pyramid_noti_agre <- dengue_data_pyramid_noti %>%
  group_by(Sex, Age, Age_Group, abbrev_state) %>%
  summarise(New_Cases_Noti = sum(New_Cases)) %>%
  drop_na()


dengue_data_pyramid <- left_join(dengue_data_pyramid_noti_agre, dengue_data_pyramid_conf_agre,
                                 by=c("Sex", "Age", "Age_Group", "abbrev_state"))



write_tsv(subset(dengue_data_pyramid, Sex != "I"), file = "input/plot_3_pyramid.tsv")


# Grafico MAPA
dengue_confdata_agre <- dengue_conf
conf_incidencia_mapa <- dengue_confdata_agre %>%
  group_by(State, cod_municipio, nome_munic, populacao) %>%
  summarise(New_Cases = sum(New_Cases)) %>%
  drop_na()

conf_incidencia_mapa$incidence <- ((conf_incidencia_mapa$New_Cases / conf_incidencia_mapa$populacao) * 100000)


write_tsv(conf_incidencia_mapa, file = "input/plot_mapa.tsv")

# Grafico 4
dengue_data <- dengue_data |> mutate(years = format(as.Date(weekStart), "%Y"))
dados_plot <- dengue_data %>%
  mutate(Race_Colour = case_when(
    Race_Colour == "Branca" ~ "Branca",
    Race_Colour == "Preta" ~ "Preta",
    Race_Colour == "Parda" ~ "Parda",
    Race_Colour == "Amarela" ~ "Amarela",
    Race_Colour == "Indígena" ~ "Indígena",
    TRUE ~ NA_character_  # Ignorado ou outros
  )) %>%
  filter(!is.na(Race_Colour)) %>%
  group_by(years, Race_Colour) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  group_by(years) %>%
  mutate(
    TotalAno = sum(New_Cases),
    Percentual = New_Cases / TotalAno * 100
  ) %>%
  ungroup() %>%
  mutate(
    Race_Colour = factor(Race_Colour, levels = c("Branca", "Preta", "Parda", "Amarela", "Indígena")),
    years = as.factor(years)
  )


write_tsv(dados_plot, file = "input/plot4.tsv")



# grafico Tabela

pop_estado <- pop %>%
  group_by(uf, codigo_uf) %>%
  summarise(populacao = sum(populacao)) %>%
  drop_na()

dengue_data_noti <- dengue_data %>%
  group_by(State, uf) %>%
  summarise(cases_noti = sum(New_Cases)) %>%
  drop_na()

dengue_data_conf <- dengue_conf %>%
  group_by(State, uf) %>%
  summarise(cases_conf = sum(New_Cases)) %>%
  drop_na()

dengue_data_agre_table <- left_join(dengue_data_noti, dengue_data_conf, by=c("State", "uf"))

dengue_data_agre_table_final <- left_join(dengue_data_agre_table, pop_estado, by=c("State"="codigo_uf", "uf"="uf"))

dengue_data_agre_table_final$incidenceNoti <- (dengue_data_agre_table_final$cases_noti / dengue_data_agre_table_final$populacao) * 100000
dengue_data_agre_table_final$incidenceConf <- (dengue_data_agre_table_final$cases_conf / dengue_data_agre_table_final$populacao) * 100000

dengue_data_agre_table_final_f <- left_join(dengue_data_agre_table_final, estado,
                                            by=c("State"="code_state", "uf"="abbrev_state"))


dados_sem_geom <- select(dengue_data_agre_table_final_f, -geom)

write_tsv(dados_sem_geom, file = "input/plot_tabela.tsv")

#####################################################################################################################################
library(geobr)
library(sf)
estado <- read_state(year = 2020)
estado <- read_state(year = 2020)
print(estado)
cards_noti <- dengue_data %>%
  group_by(abbrev_state) %>%
  summarise(notificados = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_mortes_not <- dengue_data %>%
  filter(EVOLUCAO == 2) %>%
  group_by(abbrev_state) %>%
  summarise(mortes_noti = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_mortes_conf <- dengue_conf %>%
  filter(EVOLUCAO == 2)%>%
  group_by(abbrev_state)%>%
  summarise(mortes_conf = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_conf <- dengue_conf %>%
  group_by(abbrev_state) %>%
  summarise(confirmados = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards <- cards_noti %>%
  left_join(cards_mortes_not, by = "abbrev_state") %>%
  left_join(cards_conf, by = "abbrev_state")%>%
  left_join(cards_mortes_conf, by = "abbrev_state")
write_tsv(cards, file = "input/cardss.tsv")

write_tsv(dengue_data_agre_p1, file = "input/plot_1_ultimoTeste.tsv")

' 

#arquivo do mapa especifico de brasilia
##################################
setwd("/home/christian/Scientific_Initiation_Dashboard/Dashboard/")

# Lista todos os arquivos relevantes de uma pasta
base <- list.files("input/regioes/", pattern = "\\.(csv|dbf|qmd|shp|shx)$", 
                   full.names = FALSE)

# Extrai só os nomes base (sem extensão)
regioes <- unique(tools::file_path_sans_ext(base))

regioes
# [1] "brasil_municipios"  "estados_2022"  "rodovias"

# Lista todos os arquivos relevantes de uma pasta
base_2 <- list.files("input/centros/", pattern = "\\.(cpg|dbf|prj|qix|shp|shx)$", 
                     full.names = FALSE)

# Extrai só os nomes base (sem extensão)
centros <- unique(tools::file_path_sans_ext(base))

centros
# [1] "brasil_municipios"  "estados_2022"  "rodovias"

######################################################################################################


#arquivo bruto pra gerar os cards de brasilia
  
library(microdatasus)
library(dplyr)

dados_dengue <- fetch_datasus(
  year_start = 2014,
  year_end   = 2023,
  uf = "DF",
  information_system = "SINAN-DENGUE"
)

# Agrupa por região administrativa
por_regiao <- dados_dengue |>
  group_by(regiao_administrativa) |>  # nome da coluna pode variar
  summarise(total_casos = n())

########################################################################


######################################################################
#downkload do arquivo bruto pra gerar o plot  "cards" 
remotes::install_github("rfsaldanha/microdatasus")
library(microdatasus)

# Baixa os dados
dengue_raw <- fetch_datasus(
  year_start = 2014,
  year_end = 2025,
  information_system = "SINAN-DENGUE"
)
# Processa
dengue_raw <- process_sinan_dengue(dengue_raw)
library(data.table)
library(tidyverse)
library(ribge)
library(geobr)

setwd("/home/christian/Scientific_Initiation_Dashboard/Dashboard/")

# Grafico 1
dengue_data <- fread("input/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
dengue_conf <- fread("input/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
pop <- ribge::populacao_municipios(2024)
estado <- read_state(year = 2020)

cards1 <- fread("input/dengue_raw.csv")
names(cards1)

cards <- cards1 %>%
  mutate(year = NU_ANO) %>%
  group_by(year) %>%
  summarise(
    noti_deaths = sum(EVOLUCAO == 2, na.rm = TRUE),           # todos os óbitos notificados
    confi_deaths = sum(EVOLUCAO == 2 & CLASSI_FIN %in% c(10, 11, 12), na.rm = TRUE)  # óbitos confirmados
  )

obitos <- dengue_data %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state),
    by = c("State" = "code_state")
  )
  
'