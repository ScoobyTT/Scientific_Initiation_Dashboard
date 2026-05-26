dados_filtradosC <- reactive({
  req(input$uf_filter)
  
  dados <- cards %>%
    mutate(ano = as.integer(format(months, "%Y")))
  
  if (input$uf_filter != "Todos") {
    dados <- cards %>%
      mutate(ano = as.integer(format(as.Date(months), "%Y")))
  }
  
  if (!is.null(input$ano_filter)) {
    
    dados <- dados %>%
      filter(
        ano >= input$ano_filter[1],
        ano <= input$ano_filter[2]
      )
  }
  print(head(dados))
  print(input$ano_filter)
  print(head(dados))
  dados
})
# ---- VALUE BOXES / CARDS ----
output$total_cases <- renderUI({
  df <- dados_filtradosC()
  h2(format(sum(df$notificados, na.rm = TRUE), big.mark = ".", decimal.mark = ","))
})

output$new_cases <- renderUI({
  df <- dados_filtradosC()
  h2(format(sum(df$confirmados, na.rm = TRUE), big.mark = ".", decimal.mark = ","))
})

output$total_deaths <- renderUI({
  df <- dados_filtradosC()
  h2(format(sum(df$mortes_noti, na.rm = TRUE), big.mark = ".", decimal.mark = ","))
})

output$new_deaths <- renderUI({
  df <- dados_filtradosC()
  h2(format(sum(df$mortes_conf, na.rm = TRUE), big.mark = ".", decimal.mark = ","))
})