dados_filtrados <- reactive({
  req(input$uf_filter)
  req(input$ano_filter)
  
  dados <- plot1
  
  if (input$uf_filter != "Todos") {
    dados <- dados %>% filter(abbrev_state == input$uf_filter)
  }else{
    dados <- dados %>% filter(abbrev_state == "BR")
  }
  
  if (!is.null(input$ano_filter)) {
  dados <- dados %>%
    filter(year(months) >= input$ano_filter[1],
           year(months) <= input$ano_filter[2])
}
  
  dados 
})
# Output do PRIMEIRO GRAFICO
output$scatterplot <- renderPlot({
  dados <- dados_filtrados()
  
  validate(need(
    nrow(dados) > 0,
    "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
  ))
  dados$months <- as.Date(dados$months) 
  dados$New_Cases_Conf <- as.numeric(dados$New_Cases_Conf)  
  dados$New_Cases_Noti <- as.numeric(dados$New_Cases_Noti)  
  valor <- max(dados$New_Cases_Noti, na.rm = TRUE) / max(dados$New_Cases_Conf, na.rm = TRUE)
  ggplot(dados) +
    geom_col(aes(x = months, y = New_Cases_Noti, fill = "Notificados"), alpha = 0.7) +
    geom_line(aes(x = months, y = New_Cases_Conf * valor, color = "Confirmados"), 
              size = 1) +
    scale_y_continuous(
      name = "Casos Notificados", 
      sec.axis = sec_axis(~./valor, name = 'Casos Confirmados')
    ) +
    scale_fill_manual(name = "Tipo de Caso", values = c("Notificados" = "blue")) +
    scale_color_manual(name = "Tipo de Caso", values = c("Confirmados" = "firebrick")) +
    labs(title = "Evolução dos Casos de Dengue", 
         x = "Data de Notificação", 
         y = "Número de Casos") +
    theme_minimal() +
    theme(legend.position = "bottom")
})

# Output da Previsão
output$scatterplotPrev <- renderPlot({
  validate(need(
    nrow(plot1_pred) > 0,
    "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
  ))
  
  ggplot(plot1_pred, aes(x = week, y = cases, color = source, group = source)) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    geom_ribbon(data = subset(plot1_pred, source == "prediction"),
                aes(x = week, ymin = lower_bound, ymax = upper_bound, fill = "prediction"),
                alpha = 0.3) +
    scale_color_manual(values = c(
      "dados_anteriores_não_utilizados" = "red",
      "dados_de_entrada_usados" = "blue",
      "previsão" = "black"
    )) +
    scale_fill_manual(values = c("prediction" = "gray")) +
    labs(x = "Semana Epidemiológica",
         y = "Casos semanais de dengue",
         color = "Intervalor (source)",
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
  