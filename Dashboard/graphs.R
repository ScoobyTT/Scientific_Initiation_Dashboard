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

dengue_data$months <- paste0(format(dengue_data$Noti_Date, "%Y-%m"),"-01")

dengue_conf <- dengue_conf %>%
  left_join(
    estado %>% st_drop_geometry() %>% select(code_state, abbrev_state, name_state, name_region),
    by = c("State" = "code_state")
  )

dengue_conf$months <- paste0(format(dengue_conf$Noti_Date, "%Y-%m"),"-01")

# Grafico 1
dengue_data_agre_n <- dengue_data %>%
  group_by(months, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()

datas_n <- names(table(dengue_data_agre_n$months)) 

dengue_data_agre_n_br <- dengue_data_agre_n[0, ]
for(i in 1:length(datas_n)){
  dengue_data_agre_n_br[i, ] <- NA
  dengue_data_agre_n_br$months[i] <- datas_n[i]
  dengue_data_agre_n_br$abbrev_state[i] <- "BR"
  dengue_data_agre_n_br$name_state[i] <- "Todos"
  dengue_data_agre_n_br$New_Cases[i] <- sum(dengue_data_agre_n$New_Cases[which(dengue_data_agre_n$months == datas_n[i])])
}

dengue_data_agre_n <- rbind(dengue_data_agre_n, dengue_data_agre_n_br)

dengue_data_agre_c <- dengue_conf %>%
  group_by(months, abbrev_state, name_state) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()
 
datas_c <- names(table(dengue_data_agre_c$months)) 

dengue_data_agre_c_br <- dengue_data_agre_c[0, ]
for(i in 1:length(datas_c)){
  dengue_data_agre_c_br[i, ] <- NA
  dengue_data_agre_c_br$months[i] <- datas_c[i]
  dengue_data_agre_c_br$abbrev_state[i] <- "BR"
  dengue_data_agre_c_br$name_state[i] <- "Todos"
  dengue_data_agre_c_br$New_Cases[i] <- sum(dengue_data_agre_c$New_Cases[which(dengue_data_agre_c$months == datas_c[i])])
}

dengue_data_agre_c <- rbind(dengue_data_agre_c, dengue_data_agre_c_br)

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
  group_by(Sex, Age_Group, abbrev_state, months) %>%
  summarise(New_Cases_Conf = sum(New_Cases), .groups = "drop") %>%
  drop_na()

dengue_data_pyramid_noti_agre <- dengue_data_pyramid_noti %>%
  group_by(Sex, Age_Group, abbrev_state, months) %>%
  summarise(New_Cases_Noti = sum(New_Cases), .groups = "drop") %>%
  drop_na()

datas_n <- names(table(dengue_data_pyramid_noti_agre$months))
sexo_n <- names(table(dengue_data_pyramid_noti_agre$Sex))
agegroup_n <- names(table(dengue_data_pyramid_noti_agre$Age_Group))
dengue_data_pyramid_noti_agre_br <- dengue_data_pyramid_noti_agre[0, ]
count <- 0
for (data_i in 1:length(datas_n)){
  for (sexo_i in 1:length(sexo_n)){
    for (agegroup_i in 1:length(agegroup_n)){
      count <- count + 1
      dengue_data_pyramid_noti_agre_br[count, ] <- NA
      dengue_data_pyramid_noti_agre_br$Sex[count] <- sexo_n[sexo_i]
      dengue_data_pyramid_noti_agre_br$Age_Group[count] <- agegroup_n[agegroup_i]
      dengue_data_pyramid_noti_agre_br$abbrev_state[count] <- "Todos"
      dengue_data_pyramid_noti_agre_br$months[count] <- datas_n[data_i]
      dengue_data_pyramid_noti_agre_br$New_Cases_Noti[count] <- sum(dengue_data_pyramid_noti_agre$New_Cases_Noti[which(dengue_data_pyramid_noti_agre$Sex == sexo_n[sexo_i] & dengue_data_pyramid_noti_agre$Age_Group == agegroup_n[agegroup_i] & dengue_data_pyramid_noti_agre$months == datas_n[data_i])])
    }
  }
}

datas_c <- names(table(dengue_data_pyramid_conf_agre$months))
sexo_c <- names(table(dengue_data_pyramid_conf_agre$Sex))
agegroup_c <- names(table(dengue_data_pyramid_conf_agre$Age_Group))

dengue_data_pyramid_conf_agre_br <- dengue_data_pyramid_conf_agre[0, ]
count <- 0
for (data_i in 1:length(datas_c)){
  for (sexo_i in 1:length(sexo_c)){
    for (agegroup_i in 1:length(agegroup_c)){
      count <- count + 1
      dengue_data_pyramid_conf_agre_br[count, ] <- NA
      dengue_data_pyramid_conf_agre_br$Sex[count] <- sexo_c[sexo_i]
      dengue_data_pyramid_conf_agre_br$Age_Group[count] <- agegroup_c[agegroup_i]
      dengue_data_pyramid_conf_agre_br$abbrev_state[count] <- "Todos"
      dengue_data_pyramid_conf_agre_br$months[count] <- datas_c[data_i]
      dengue_data_pyramid_conf_agre_br$New_Cases_Conf[count] <- sum(dengue_data_pyramid_conf_agre$New_Cases_Conf[which(dengue_data_pyramid_conf_agre$Sex == sexo_c[sexo_i] & dengue_data_pyramid_conf_agre$Age_Group == agegroup_c[agegroup_i] & dengue_data_pyramid_conf_agre$months == datas_c[data_i])])
    }
  }
}

dengue_data_pyramid_noti_agre <- rbind(dengue_data_pyramid_noti_agre, dengue_data_pyramid_noti_agre_br)
dengue_data_pyramid_conf_agre <- rbind(dengue_data_pyramid_conf_agre, dengue_data_pyramid_conf_agre_br)




dengue_data_pyramid <- left_join(dengue_data_pyramid_noti_agre, dengue_data_pyramid_conf_agre,
                                 by = c("Sex", "Age_Group", "abbrev_state", "months"))

write_tsv(subset(dengue_data_pyramid, Sex != "I"), file = "input/plot_3_pyramid.tsv")

# Grafico MAPA
conf_incidencia_mapa <- dengue_conf %>%
  mutate(years = year(as.Date(months))) %>%
  group_by(State, cod_municipio, nome_munic, populacao, years, abbrev_state, months) %>%
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
  group_by(years, Race_Colour, Noti_Date) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  group_by(years) %>%
  mutate(TotalAno = sum(New_Cases), Percentual = New_Cases / TotalAno * 100) %>%
  ungroup() %>%
  mutate(
    Race_Colour = factor(Race_Colour, levels = c("Branca","Preta","Parda","Amarela","Indígena")),
    years = as.factor(years)
  )%>%
  rename(months = Noti_Date)

write_tsv(dados_plot, file = "input/plot4.tsv")

# Tabela
dengue_data_noti <- dengue_data %>%
  group_by(State, uf, Noti_Date) %>%
  summarise(cases_noti = sum(New_Cases), .groups = "drop") %>%
  drop_na() %>%
  rename(months = Noti_Date)
dengue_data_conf <- dengue_conf %>%
  group_by(State, uf, Noti_Date) %>%
  summarise(cases_conf = sum(New_Cases), .groups = "drop") %>%
  drop_na() %>%
  rename(months = Noti_Date)
pop_estado <- pop %>%
  group_by(uf, codigo_uf) %>%
  summarise(populacao = sum(populacao), .groups = "drop") %>%
  drop_na()
dengue_data_agre_table <- left_join(dengue_data_noti, dengue_data_conf,
                                    by = c("State", "uf", "months"))
dengue_data_agre_table_final <- left_join(dengue_data_agre_table, pop_estado,
                                          by = c("State" = "codigo_uf", "uf"))
dengue_data_agre_table_final$incidenceNoti <- (dengue_data_agre_table_final$cases_noti / dengue_data_agre_table_final$populacao) * 100000
dengue_data_agre_table_final$incidenceConf <- (dengue_data_agre_table_final$cases_conf / dengue_data_agre_table_final$populacao) * 100000
# 
dengue_data_agre_table_final_f <- left_join(dengue_data_agre_table_final, estado,
                                            by = c("State" = "code_state", "uf" = "abbrev_state"))
dados_sem_geom <- select(dengue_data_agre_table_final_f, -geom)
write_tsv(dados_sem_geom, file = "input/plot_tabela.tsv")

#cards
cards_noti <- dengue_data %>%
  group_by(abbrev_state, Noti_Date) %>%
  summarise(notificados = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_mortes_not <- dengue_data %>%
  filter(EVOLUCAO == 2) %>%
  group_by(abbrev_state, Noti_Date) %>%
  summarise(mortes_noti = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_mortes_conf <- dengue_conf %>%
  filter(EVOLUCAO == 2)%>%
  group_by(abbrev_state, Noti_Date)%>%
  summarise(mortes_conf = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards_conf <- dengue_conf %>%
  group_by(abbrev_state, Noti_Date) %>%
  summarise(confirmados = sum(New_Cases, na.rm = TRUE), .groups = "drop")

cards <- cards_noti %>%
  left_join(cards_mortes_not, by = c ("abbrev_state", "Noti_Date")) %>%
  left_join(cards_conf, by = c ("abbrev_state", "Noti_Date"))%>%
  left_join(cards_mortes_conf, by = c("abbrev_state", "Noti_Date"))%>%
  rename(months = Noti_Date)%>%
mutate(
  mortes_noti = coalesce(mortes_noti, 0),
  confirmados = coalesce(confirmados, 0),
  mortes_conf = coalesce(mortes_conf, 0)
)

write_tsv(cards, file = "input/cardss.tsv")
cat("Graficos gerados com sucesso.\n")


# Diagrama de controle

plot_diagrama <- dengue_conf %>%
  group_by(State, Noti_Week, uf) %>%
  summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
  drop_na()

plot_diagrama$year <- substr(plot_diagrama$Noti_Week, 1, 4)
plot_diagrama$week <- substr(plot_diagrama$Noti_Week, 5, 6)

weeks <- names(table(plot_diagrama$Noti_Week))

plot_diagrama_br <- plot_diagrama[0, ]

for (i in 1:length(weeks)){
  plot_diagrama_br[i, ] <- NA
  plot_diagrama_br$State[i] <- 71
  plot_diagrama_br$uf[i] <- "BR"
  plot_diagrama_br$Noti_Week[i] <- weeks[i]
  plot_diagrama_br$year[i] <- substr(weeks[i], 1, 4)
  plot_diagrama_br$week[i] <- substr(weeks[i], 5, 6)
  plot_diagrama_br$New_Cases[i] <- sum(plot_diagrama$New_Cases[which(plot_diagrama$Noti_Week == weeks[i])])
}

plot_diagrama <- rbind(plot_diagrama, plot_diagrama_br)

pop2014 <- ribge::populacao_municipios(2014)
pop2015 <- ribge::populacao_municipios(2015)
pop2016 <- ribge::populacao_municipios(2016)
pop2017 <- ribge::populacao_municipios(2017)
pop2018 <- ribge::populacao_municipios(2018)
pop2019 <- ribge::populacao_municipios(2019)
pop2020 <- ribge::populacao_municipios(2020)
pop2021 <- ribge::populacao_municipios(2021)
pop2022 <- ribge::populacao_municipios(2022)
pop2023 <- ribge::populacao_municipios(2022)
pop2024 <- ribge::populacao_municipios(2024)
pop2025 <- ribge::populacao_municipios(2025)


pop_list <- list(
  pop2014, pop2015, pop2016, pop2017, pop2018, pop2019,
  pop2020, pop2021, pop2022, pop2023, pop2024, pop2025
)
years <- 2014:2025

# Por estado
pop_estados <- bind_rows(
  mapply(function(df, yr) {
    df |> group_by(uf) |> summarise(populacao = sum(populacao, na.rm = TRUE), .groups = "drop") |> mutate(ano = yr)
  }, pop_list, years, SIMPLIFY = FALSE)
)

# Brasil total
pop_brasil <- pop_estados |>
  group_by(ano) |>
  summarise(populacao = sum(populacao, na.rm = TRUE), .groups = "drop") |>
  mutate(uf = "BR")

