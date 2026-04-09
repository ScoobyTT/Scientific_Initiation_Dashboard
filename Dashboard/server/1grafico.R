# Dados filtrados reativos
dados_filtrados <- reactive({
  req(input$uf_filter)  
  
  if (input$uf_filter == "Todos") {
    dados <- plot1
  } else {
    # dados <- plot1[UF == input$uf_filter]
    # "fread" é uma boa pra caso de ler arquivos separados 
    dados <- plot1 %>%
      filter(abbrev_state == input$uf_filter)
  }
  #nao precisa do *return* o R ja faz isso por padrao
})

# Output do PRIMEIRO GRAFICO
output$scatterplot <- renderPlot({
  dados <- dados_filtrados()
  
  validate(need(
    nrow(dados) > 0,
    "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
  ))
  
  ggplot(dados) +
    geom_col(aes(x = month, y = New_Cases_Noti, fill = "Notificados"), alpha = 0.7) +
    geom_smooth(aes(x = month, y = New_Cases_Conf , color = "Confirmados"), 
                method = "loess", se = FALSE, size = 1) +
    scale_y_continuous(
      name = "Casos Notificados", 
      sec.axis = sec_axis(~./5, name = 'Casos Confirmados')
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
      "previous_not_used_data" = "red",
      "used_input_data" = "blue",
      "prediction" = "black"
    )) +
    scale_fill_manual(values = c("prediction" = "gray")) +
    labs(x = "Epidemiological Week",
         y = "Weekly Dengue Cases",
         color = "Source",
         fill = "Prediction Interval",
         title = "Dengue Weekly Cases Forecast for Brazil") +
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
  