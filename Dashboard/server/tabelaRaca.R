'
preciso terminar de ajeitar o filtro para estado
# Reactive com filtro de estado  
dados_filtradosRACA <- reactive({
  req(input$uf_filter)  
  if (input$uf_filter == "Todos") {
    dados <- plot4
  } else {
    dados <- cards %>%
      filter(State == input$uf_filter)
  }
  dados <- tidyr::replace_na(dados, list(incidence = 0))
  return(dados)
})'
  #OUTPUT DA TABELA: RAÇA COR
  output$scatterplotTerceiro <- renderPlot({
    
    validate(need(
      nrow(plot4) > 0,
      "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
    ))
    
    ggplot(plot4_new, aes(x = week)) +
      geom_ribbon(aes(ymin = Q1, ymax = Q3, fill = "Q1 a Q3"), alpha = 0.5) +
      geom_line(aes(y = median, color = "Mediana"), linetype = "dashed", size = 1) +
      geom_line(aes(y = CI * 270, color = "Coeficiente de Incidência"), size = 1) +
      scale_y_continuous(
        name = "Canal Endêmico", 
        sec.axis = sec_axis(~./270, name = 'Coef. de Incidência (por 100 mil hab.)')
      ) +
      scale_color_manual(
        name = NULL,
        values = c("Mediana" = "darkred", "Coeficiente de Incidência" = "blue")
      ) +
      scale_fill_manual(
        name = NULL,
        values = c("Q1 a Q3" = "gray80")
      ) +
      labs(
        title = "Diagrama de Controle de Dengue"
      ) +
      xlab("Semana Epidemiológica") +
      theme_minimal() +
      theme(legend.position = "bottom")
    
    # ggplot(plot4, aes(x = Race_Colour, y = Percentual, fill = years)) +
    #   geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    #   geom_text(aes(label = paste0(round(Percentual, 1), "%")),
    #             position = position_dodge(width = 0.8), vjust = -0.5, size = 3) +
    #   scale_y_continuous(labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0, 0.1))) +
    #   labs(
    #     title = "Distribuição dos Casos de Dengue por Raça/Cor (2014–2025)",
    #     x = NULL,
    #     y = "Percentual de Casos Notificados"
    #   ) +
    #   theme_minimal(base_size = 12) +
    #   theme(
    #     legend.position = "top",
    #     axis.text.x = element_text(angle = 45, hjust = 1)
    #   )
  })  

