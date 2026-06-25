dados_filtrados_plot1 <- reactive({
  req(input$uf_filter)
  req(input$ano_filter)
  
  dados_plot1 <- plot1_new
  dados_plot1$months <- as.Date(dados_plot1$months)
  
  if (input$uf_filter != "Todos") {
    dados_plot1 <- dados_plot1 %>% filter(abbrev_state == input$uf_filter)
  }else{
    dados_plot1 <- dados_plot1 %>% filter(abbrev_state == "BR")
  }
  
  if (!is.null(input$ano_filter)) {
    dados_plot1 <- dados_plot1 %>%
      filter(year(months) >= input$ano_filter[1],
             year(months) <= input$ano_filter[2])
  }
  
  dados_plot1 
})
# Output do PRIMEIRO GRAFICO
output$scatterplot <- renderPlot({
  print(paste("1: ",names(plot1_new)))
  dados_plot1 <- dados_filtrados_plot1()
  print(paste("2: ",names(dados_plot1)))
  validate(need(
    nrow(dados_plot1) > 0,
    "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
  ))
  dados_plot1$months <- as.Date(dados_plot1$months) 
  dados_plot1$New_Cases_Conf <- as.numeric(dados_plot1$New_Cases_Conf)  
  dados_plot1$New_Cases_Noti <- as.numeric(dados_plot1$New_Cases_Noti)  
  valorp1 <- max(dados_plot1$New_Cases_Noti, na.rm = TRUE) / max(dados_plot1$New_Cases_Conf, na.rm = TRUE)
  ggplot(dados_plot1) +
    geom_col(aes(x = months, y = New_Cases_Noti, fill = "Notificados"), alpha = 0.7) +
    geom_line(aes(x = months, y = New_Cases_Conf * valorp1, color = "Confirmados"), 
              size = 1) +
    scale_y_continuous(
      name = "Casos Notificados", 
      sec.axis = sec_axis(~./valorp1, name = 'Casos Confirmados')
    ) +
    scale_fill_manual(name = "Tipo de Caso", values = c("Notificados" = "blue")) +
    scale_color_manual(name = "Tipo de Caso", values = c("Confirmados" = "firebrick")) +
    labs(title = "Evolução dos Casos de Dengue", 
         x = "Data de Notificação", 
         y = "Número de Casos") +
    theme_minimal() +
    theme(legend.position = "bottom")
})
dados_filtrados_pred <- reactive({
  req(input$uf_filter)
  
  dados <- plot1_pred
  
  if (input$uf_filter != "Todos") {
    dados <- dados %>% filter(abbrev_state == input$uf_filter)
  } else {
    dados <- dados %>% filter(abbrev_state == "BR")
  }
  
  dados
})
output$scatterplotPrev <- renderPlot({
  dados <- dados_filtrados_pred()
  
  validate(need(nrow(dados) > 0, "Nenhum dado disponível."))
  #cases
  dados$week <- factor(dados$week, levels = sort(unique(dados$week)))
  names(plot1_pred)
  ggplot(dados, aes(x = week, y = cases, color = source, group = source)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_ribbon(data = subset(dados, source == "predicted"),
                aes(ymin = lower_bound, ymax = upper_bound, fill = "predicted", group = 1),
                alpha = 0.3, color = NA) +
    scale_x_discrete(breaks = levels(dados$week)[seq(1, nlevels(dados$week), by = 10)]) +
    scale_color_manual(values = c(
      "previous_not_used_data" = "red",
      "used_input_data" = "blue",
      "predicted" = "black"
    )) +
    scale_fill_manual(values = c("predicted" = "gray")) +
    labs(x = "Semana Epidemiológica",
         y = "Casos semanais de dengue",
         color = "Fonte",
         fill = "Intervalo de previsão",
         title = "Previsão semanal de casos de dengue no Brasil") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom")
})

#extra_colunas <- dengue_data %>%
#  mutate(months = as.Date(floor_date(Noti_Date, "month"))) %>%
#  group_by(months, State, nome_munic, cod_municipio) %>%
#  summarise(populacao = sum(populacao, na.rm = TRUE)) %>%
#  drop_na()

#plot1 <- plot1 %>%
#  mutate(months = as.Date(months)) %>%
#  left_join(extra_colunas, by = "months")

#plot1 <- plot1 %>%
#  left_join(dengue.final, by = months)

' 
observe({
  session$setCurrentTheme(
    if (isTRUE(input$dark_mode)) {
      bs_theme(version = 5, bootswatch = "cyborg",
               base_font = font_google("DM Sans"),
               heading_font = font_google("DM Sans"))
    } else {
      bs_theme(version = 5, bootswatch = "minty",
               base_font = font_google("DM Sans"),
               heading_font = font_google("DM Sans"))
    }
  )
})

observe({
  if (isTRUE(input$dark_mode)) {
    session$setCurrentTheme(
      bs_theme(version = 5, bootswatch = "cyborg",
               base_font = font_google("DM Sans"),
               heading_font = font_google("DM Sans"))
    )
    theme_set(theme_minimal(base_family = "DM Sans") +
                theme(
                  plot.background = element_rect(fill = "#161616", color = NA),
                  panel.background = element_rect(fill = "#161616", color = NA),
                  text = element_text(color = "#e8e8e8"),
                  axis.text = element_text(color = "#aaa"),
                  panel.grid = element_line(color = "rgba(255,255,255,0.06)")
                ))
  } else {
    session$setCurrentTheme(
      bs_theme(version = 5, bootswatch = "minty",
               base_font = font_google("DM Sans"),
               heading_font = font_google("DM Sans"))
    )
    theme_set(theme_minimal(base_family = "DM Sans"))
  }
})' 
