library(data.table)
library(tidyverse)
library(ribge)
library(geobr)
library(sf)

setwd("/data/")

dengue_data <- fread("input/2014-2025_DENGUE_NOTIFICADOS_dash_new.tsv")
dengue_conf <- fread("input/2014-2025_DENGUE_CONFIRMADOS_dash_new.tsv")
pop    <- ribge::populacao_municipios(2024)
estado <- read_state(year = 2020)

dengue_data <- dengue_data %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state, name_region),
    by = c("State" = "code_state")
  )

dengue_conf <- dengue_conf %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state, name_region),
    by = c("State" = "code_state")
  )

# Grafico 1
dengue_data_agre_n <- dengue_data %>%
  group_by(Noti_Date, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_agre_c <- dengue_conf %>%
  group_by(Noti_Date, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()

names(dengue_data_agre_n) <- c("months", "abbrev_state", "name_state", "New_Cases_Noti")
names(dengue_data_agre_c) <- c("months", "abbrev_state", "name_state", "New_Cases_Conf")

dengue_data_agre_p1 <- left_join(dengue_data_agre_n, dengue_data_agre_c,
                                 by = c("months", "abbrev_state", "name_state"))

write_tsv(dengue_data_agre_p1, file = "input/plot_1.tsv")

# Grafico 3 Piramide
dengue_data_pyramid_noti <- dengue_data %>%
  mutate(
    New_Cases = case_when(Sex == "M" ~ -New_Cases, TRUE ~ New_Cases),
    Age_Group = cut(Age,
                    breaks = c(0, 4, 9, 19, 29, 39, 49, 59, 69, 79, Inf),
                    labels = c("0-4","5-9","10-19","20-29","30-39","40-49","50-59","60-69","70-79","80+"),
                    right = FALSE)
  )

dengue_data_pyramid_conf <- dengue_conf %>%
  mutate(
    New_Cases = case_when(Sex == "M" ~ -New_Cases, TRUE ~ New_Cases),
    Age_Group = cut(Age,
                    breaks = c(0, 4, 9, 19, 29, 39, 49, 59, 69, 79, Inf),
                    labels = c("0-4","5-9","10-19","20-29","30-39","40-49","50-59","60-69","70-79","80+"),
                    right = FALSE)
  )

dengue_data_pyramid_conf_agre <- dengue_data_pyramid_conf %>%
  group_by(Sex, Age, Age_Group, abbrev_state) %>%
  summarise(New_Cases_Conf = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_pyramid_noti_agre <- dengue_data_pyramid_noti %>%
  group_by(Sex, Age, Age_Group, abbrev_state) %>%
  summarise(New_Cases_Noti = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_pyramid <- left_join(dengue_data_pyramid_noti_agre, dengue_data_pyramid_conf_agre,
                                 by = c("Sex", "Age", "Age_Group", "abbrev_state"))

write_tsv(subset(dengue_data_pyramid, Sex != "I"), file = "input/plot_3_pyramid.tsv")

# Grafico MAPA
conf_incidencia_mapa <- dengue_conf %>%
  group_by(State, cod_municipio, nome_munic, populacao) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()

conf_incidencia_mapa$incidence <- (conf_incidencia_mapa$New_Cases / conf_incidencia_mapa$populacao) * 100000

write_tsv(conf_incidencia_mapa, file = "input/plot_mapa.tsv")

# Grafico 4
dengue_data <- dengue_data %>% mutate(years = format(as.Date(weekStart), "%Y"))

dados_plot <- dengue_data %>%
  mutate(Race_Colour = case_when(
    Race_Colour %in% c("Branca","Preta","Parda","Amarela","Indígena") ~ Race_Colour,
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(Race_Colour)) %>%
  group_by(years, Race_Colour) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  group_by(years) %>%
  mutate(TotalAno = sum(New_Cases), Percentual = New_Cases / TotalAno * 100) %>%
  ungroup() %>%
  mutate(
    Race_Colour = factor(Race_Colour, levels = c("Branca","Preta","Parda","Amarela","Indígena")),
    years = as.factor(years)
  )

write_tsv(dados_plot, file = "input/plot4.tsv")

# Tabela
pop_estado <- pop %>%
  group_by(uf, codigo_uf) %>%
  summarise(populacao = sum(populacao), .groups = "drop") %>%
  drop_na()

dengue_data_noti <- dengue_data %>%
  group_by(State, uf) %>%
  summarise(cases_noti = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_conf <- dengue_conf %>%
  group_by(State, uf) %>%
  summarise(cases_conf = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_agre_table <- left_join(dengue_data_noti, dengue_data_conf, by = c("State", "uf"))

dengue_data_agre_table_final <- left_join(dengue_data_agre_table, pop_estado,
                                          by = c("State" = "codigo_uf", "uf"))

dengue_data_agre_table_final$incidenceNoti <- (dengue_data_agre_table_final$cases_noti / dengue_data_agre_table_final$populacao) * 100000
dengue_data_agre_table_final$incidenceConf <- (dengue_data_agre_table_final$cases_conf / dengue_data_agre_table_final$populacao) * 100000

dengue_data_agre_table_final_f <- left_join(dengue_data_agre_table_final, estado,
                                            by = c("State" = "code_state", "uf" = "abbrev_state"))

dados_sem_geom <- select(dengue_data_agre_table_final_f, -geom)
write_tsv(dados_sem_geom, file = "input/plot_tabela.tsv")

cat("Graficos gerados com sucesso.\n")