
# 1. Lê o arquivo carregado
dados_upload <- reactive({
  req(input$upload_arquivo)  # só roda quando um arquivo for enviado
  read.csv(input$upload_arquivo$datapath, sep = ";")  # ou sep = "," se for vírgula
})

# 2. Exibe os dados
output$tabela_upload <- renderTable({
  head(dados_upload(), 10)
})
#carrega os dados dos municipios e aplica no primeiro grafico

plot1 <- fread("input/plot_1.tsv")
plot1_pred <- fread("input/plot1_pred.csv", colClasses = c(week = "character"))
plot3 <- fread("input/plot_3_pyramid.tsv")
plot4 <- fread("input/plot4.tsv")
plot2 <- fread("input/plot_tabela.tsv")
plot5 <- fread("input/plot_mapa.tsv")
cards <- fread("input/cardss.tsv")
plot4_new <- fread("input/plot4_new.tsv")
plot1_pred$week <- factor(plot1_pred$week)

tabela_final <- select(plot2, name_region, name_state, incidenceNoti, incidenceConf)
tabela_final$incidenceNoti <- round(as.numeric(tabela_final$incidenceNoti), 2)
tabela_final$incidenceConf <- round(as.numeric(tabela_final$incidenceConf), 2)
names(tabela_final) <- c("Região", "Estado", "Casos Notificados por 100 mil", "Casos Confirmados por 100 mil")

plot3$Age_Group <- factor(plot3$Age_Group, levels = c("0-4", "5-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80+"))

municipios <- read_municipality(code_muni = "all", year = 2020, showProgress = FALSE, cache = TRUE)




# dengue <- fread("input/2014-2025_DENGUE_CONFIRMADOS.tsv")
# 
# dengue1 <- dengue %>%
#   mutate(
#     year = as.integer(substr(Noti_Week, 1, 4)),
#     week = as.integer(substr(Noti_Week, 5, 6))
#   )
# 
# dengue1$date_week <- as.Date(cut(dengue1$Noti_Date,
#                                  breaks = "week",
#                                  start.on.monday = FALSE))
# 
# pop <- ribge::populacao_municipios(2024)
# 
# dengue2 <- dengue1 %>%
#   group_by(year, week, date_week) %>%
#   summarise(New_Cases = sum(New_Cases)) %>%
#   drop_na()
# 
# dengue2$week[which(dengue2$year == 2015 & dengue2$week == 8 & dengue2$date_week == "2015-02-15")] <- 7
# dengue2$week[which(dengue2$year == 2015 & dengue2$week == 9 & dengue2$date_week == "2015-02-22")] <- 8
# dengue2$week[which(dengue2$year == 2015 & dengue2$week == 13 & dengue2$date_week == "2015-03-22")] <- 12
# dengue2$week[which(dengue2$year == 2016 & dengue2$week == 3 & dengue2$date_week == "2016-01-24")] <- 4
# dengue2$week[which(dengue2$year == 2016 & dengue2$week == 3 & dengue2$date_week == "2016-03-06")] <- 10
# 
# dengue2 <- dengue2 %>%
#   group_by(year, week) %>%
#   summarise(New_Cases = sum(New_Cases)) %>%
#   drop_na()
# 
# 
# dengue4 <- dengue2 %>%
#   pivot_wider(names_from = year, values_from = New_Cases)
# dengue4 <- dengue4[1:52, ]
# 
# dengue5 <- dengue4 %>%
#   pivot_longer(
#     cols = -week,
#     names_to = "year",
#     values_to = "cases"
#   ) %>%
#   mutate(
#     year = as.integer(year),
#     week = as.integer(week),
#     year_week = sprintf("%d.%02d", year, week)
#   ) %>%
#   select(year_week, cases) %>%
#   pivot_wider(
#     names_from = year_week,
#     values_from = cases
#   ) %>%
#   mutate(country = "Brazil") %>%
#   relocate(country) %>%
#   select(country, sort(colnames(.)[-1]))  # ordena as colunas exceto a primeira
# 
# write.csv(dengue5, "new_new_selected_dengue_data_utf8.csv", row.names = FALSE)
# 

# dengue3 <- dengue2 %>%
#   pivot_wider(names_from = year, values_from = New_Cases)
# 
# dengue3 <- dengue3[1:52, ]
# dengue3$median <- NA
# dengue3$Q1 <- NA
# dengue3$Q3 <- NA
# dengue3$sum <- NA
# for(i in 1:nrow(dengue3)){
#   dengue3$median[i] <- median(as.numeric(dengue3[i, c(2:ncol(dengue3))]), na.rm=TRUE)
#   dengue3$sum[i] <- sum(as.numeric(dengue3[i, c(2:ncol(dengue3))]), na.rm=TRUE)
#   dengue3$Q1[i] <- quantile(as.numeric(dengue3[i, c(2:ncol(dengue3))]), na.rm=TRUE)[2]
#   dengue3$Q3[i] <- quantile(as.numeric(dengue3[i, c(2:ncol(dengue3))]), na.rm=TRUE)[4]
# }
# 
# dengue3 <- dengue3 %>%
#   mutate(CI = (sum / sum(pop$populacao)) * 100000)
# 
# write_tsv(dengue3, "input/plot4_new.tsv")

# ggplot(dengue3, aes(x = week)) +
#   geom_ribbon(aes(ymin = Q1, ymax = Q3), fill = "gray80") +
#   geom_line(aes(y = median), color = "darkred", linetype = "dashed", size = 1) +
#   geom_line(aes(y = CI*270), color = "blue", size = 1) +
#   scale_y_continuous(
#     name = "Canal Endemico", sec.axis = sec_axis(~./270, name = 'Coeficiente de Incidência (por 100 mil hab.)')) +
#   labs(
#     title = paste("Diagrama de Controle de Dengue")
#   ) +
#   xlab("Semana Epidemilogica") +
#   theme_minimal() +
#   theme(legend.position = "bottom")


# #dengue_data <- fread("input/dengue_notificados.tsv")
# 
# total_casos <- dengue_data %>%
#   group_by(years) %>%
#   summarise(total = sum(New_Cases)) %>%
#   drop_na()
# 
# 
# total <- left_join(total_casos, total_Ccasos, by=c("years"="years"))
# names(total) <- c("years", "notificados", "confirmados")
# write_tsv(total, "input/plot_cards.tsv")
# 
# 
# #dengue_conf <- fread("input/dengue_confirmados.tsv")
# 
# total_Ccasos <- dengue_conf %>%
#   group_by(years) %>%
#   summarise(total = sum(New_Cases)) %>%
#   drop_na()

dengue.final <- left_join(municipios, plot5, by = c("code_state" = "State", "code_muni" = "cod_municipio"))

dengue.final <- replace_na(dengue.final, list(incidence = 0))

dengue.final$inc_cat <- cut(
  dengue.final$incidence,
  breaks = c(0, 100, 500, 2500, 10000, Inf),
  labels = c("0–100", "101–500", "501–2500", "2501–10k", ">10k"),
  include.lowest = TRUE
)

# Criar paleta de cores
pal <- colorNumeric(palette = "YlOrRd", domain = dengue.final$incidence, na.color = "gray")  