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

dados_filtrados <- reactive({
  req(input$uf_filter)
  req(input$ano_filter)
  
  dados <- plot1_new
  
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
  
  if (!is.null(input$ano_filter)) {
    anos <- input$ano_filter[1]:input$ano_filter[2]
    cols_casos <- paste0("casos_", anos)
    cols_casos <- cols_casos[cols_casos %in% names(plot4_new)]
    cols_pop   <- paste0("pop_", anos)
    cols_pop   <- cols_pop[cols_pop %in% names(plot4_new)]
    }
  df_filtrado <- plot4_new |>
    select(uf, week, all_of(cols_casos), all_of(cols_pop))
  
  df_resultado <- df_filtrado |>
    rowwise() |>
    mutate(
      q1       = quantile(c_across(all_of(cols_casos)), 0.25, na.rm = TRUE),
      median  = quantile(c_across(all_of(cols_casos)), 0.50, na.rm = TRUE),
      q3       = quantile(c_across(all_of(cols_casos)), 0.75, na.rm = TRUE),
      soma     = sum(c_across(all_of(cols_casos)), na.rm = TRUE),
      pop_media = mean(c_across(all_of(cols_pop)), na.rm = TRUE)
    ) |>
    ungroup()
  
  df_resultado <- df_resultado |>
    mutate(
      ci_soma = (soma / pop_media) * 100000
    )
  
  if (input$uf_filter != "Todos") {
    df_resultado_final <- df_resultado %>% filter(uf == input$uf_filter)
  }else{
    df_resultado_final <- df_resultado %>% filter(uf == "BR")
  }
  
  df_resultado_final
  
})



# if (!is.null(input$ano_filter)) {
#   plot4_new <- plot4_new %>%
#     filter(year(months) >= input$ano_filter[1],
#            year(months) <= input$ano_filter[2])
# }

  #OUTPUT DA TABELA: RAÇA COR
  output$scatterplotTerceiro <- renderPlot({
    dados <- dados_filtrados()
    validate(need(
      nrow(dados) > 0,
      "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
    ))
    fator_escala <- max(dados$q3, na.rm = TRUE) / max(dados$ci_soma, na.rm = TRUE)
    
    ggplot(dados, aes(x = week)) +
      geom_ribbon(aes(ymin = q1, ymax = q3, fill = "Q1 a Q3"), alpha = 0.5) +
      geom_line(aes(y = median, color = "Mediana"), linetype = "dashed", size = 1) +
      geom_line(aes(y = ci_soma * fator_escala, color = "Coeficiente de Incidência"), size = 1) +
      scale_y_continuous(
        name = "Canal Endêmico", 
        sec.axis = sec_axis(~./fator_escala, name = 'Coef. de Incidência (por 100 mil hab.)')
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

