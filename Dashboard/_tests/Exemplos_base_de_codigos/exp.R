
# Tabela de dados
# output$table_data <- renderDataTable({
# datatable(
#  tips,
#     style = "auto",
#    options = list(
#   pageLength = 5,
#     dom = "tp", # Controle de elementos (apenas tabela e paginação)
#     autoWidth = TRUE
#  ),
#     class = "table-striped table-hover"
##    )
#  })
#--------------------------------------------------------------------------------------------------------
# # Density plot
# output$density_plot <- renderPlot({
#   ggplot(tips, aes(x = tip / total_bill, fill = day)) +
#     geom_density(alpha = 0.5) +
#     facet_wrap(~day) +
#     labs(x = "Tip Percentage", y = "Density") +
#     theme_minimal()
# })

#-------------------------------------------------------------------------------------------------------- 
#  tips_data <- reactive({
#   d <- tips
#   #d <- d[d$total_bill >= input$total_bill[1] & d$total_bill <= input$total_bill[2], ]
#d <- d[d$time %in% input$time, ]
#   d
# })
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
