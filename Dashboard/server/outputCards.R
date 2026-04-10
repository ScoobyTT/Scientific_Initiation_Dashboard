# Reactive com filtro de estado
teste <- fread("input/cards.csv")
dados_filtradosC <- reactive({
  req(input$uf_filter)  
  if (input$uf_filter == "Todos") {
    dados <- cards
  } else {
    dados <- cards %>%
      filter(abbrev_state == input$uf_filter)
  }
  dados <- tidyr::replace_na(dados, list(incidence = 0))
    #nao precisa de return, o R ja faz isso por padrao.
})

# ---- VALUE BOXES / CARDS ----
output$total_cases <- renderUI({
  df <- dados_filtradosC()
  format(sum(df$notificados, na.rm = TRUE), big.mark = ".", decimal.mark = ",", nsmall = 0)
})

output$new_cases <- renderUI({
  df <- dados_filtradosC()
  format(sum(df$confirmados, na.rm = TRUE), big.mark = ".", decimal.mark = ",", nsmall = 0)
})

output$total_deaths <- renderUI({
  df <- dados_filtradosC()
  format(sum(df$noti_deaths, na.rm = TRUE), big.mark = ".", decimal.mark = ",", nsmall = 0)
})

output$new_deaths <- renderUI({
  df <- dados_filtradosC()
  format(sum(df$confi_deaths, na.rm = TRUE), big.mark = ".", decimal.mark = ",", nsmall = 0)
})
