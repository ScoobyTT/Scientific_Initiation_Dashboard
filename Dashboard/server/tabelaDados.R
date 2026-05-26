
  #OUTPUT DA TABELA
 # output$table <- DT::renderDataTable({
   # DT::datatable(tabela_final, options = list(pageLength = 10), rownames = FALSE)
 # })


dengue.finalREG <- dengue.final %>%
  filter(cod_municipio == "5300108")
dengue.finalREG <- replace_na(dengue.finalREG, list(incidence = 0))
dengue.finalREG$inc_cat <- cut(
  dengue.finalREG$incidence,
  breaks = c(0, 100, 500, 2500, 10000, Inf),
  labels = c("0–100", "101–500", "501–2500", "2501–10k", ">10k"),
  include.lowest = TRUE
)


dados_filtradosTAB <- reactive({
  req(input$uf_filter)
  dadosTAB <- plot2 %>%
  mutate(ano = as.integer(format(months, "%Y")))
  if (input$uf_filter == "Todos") {
    dadosTAB <- dengue.final
  } else if (input$uf_filter == "DF") {
    dadosTAB <- dengue.finalREG
  } else {
    dadosTAB <- dengue.final %>%
      filter(abbrev_state == input$uf_filter)
  }
  
  if (!is.null(input$ano_filter)) {
    dadosTAB <- dadosTAB %>%
    as.data.frame() %>%
      filter(year(as.Date(months)) >= input$ano_filter[1],
             year(as.Date(months)) <= input$ano_filter[2])
        
  }
  
  dadosTAB
})

# OUTPUT DA TABELA 
output$table <- DT::renderDataTable({
  req(dados_filtradosTAB())  
  DT::datatable(
    dados_filtradosTAB(),  
    options = list(pageLength = 10), 
    rownames = FALSE
  )
})

