# Dados filtrados reativos
dados_filtradosPL3 <- reactive({
  req(input$uf_filter)  
  req(plot3) 
  
  if (input$uf_filter == "Todos") {
    dados <- plot3
  } else { 
    #escolha = input$uf_filter        else if(escolha != todos)  selecao == escolha
   
    dados <- fread("input/B/plot_3_pyramid.tsv")
    #dados <- left_join(
     # dados,
    #  plot3 %>% select(New_Cases_Conf, New_Cases_Noti, Age_Group, Sex),
    #  by = c("New_Cases_Noti" = "New_Cases_Noti")
    #)
  }
  return(dados)
})
 
  
#OUTPUT DO SEGUNDO GRAFICO
  output$scatterplotSegundo <- renderPlot({
    dadost <- dados_filtradosPL3()
    validate(need(
      nrow(dadost) > 0,
      "Nenhum dado disponível. Verifique se o arquivo foi carregado corretamente."
    ))
    

    ggplot(dadost) + 
      geom_col(aes(x = New_Cases_Noti,
                   y = factor(Age_Group),
                   fill = Sex), alpha = 0.6) +
      geom_col(aes(x = New_Cases_Conf,
                   y = factor(Age_Group),
                   fill = Sex)) +
      scale_x_continuous(labels = abs) +
      labs(
        x = "Número de Casos",
        y = "Faixa Etária",
        title = "Distribuição de Casos por Sexo e Faixa Etária",
        fill = "Sexo"
      ) +
      theme_minimal()
  })
