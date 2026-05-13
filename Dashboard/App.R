source("global/global.R")
source("theme/theme.R")
options(scipen = 999)

ui <- source("ui/ui.R")$value


server <- function(input, output, session) {
  thematic::thematic_shiny()
  source("server/read.R", local = TRUE)
  source("server/mapa.R", local = TRUE)
  source("server/tabelaDados.R", local = TRUE)
  source("server/1grafico.R", local = TRUE)
  source("server/diagramaControle.R", local = TRUE)
  source("server/2grafico.R", local = TRUE)
  source("server/outputCards.R", local = TRUE)
}

shinyApp(ui = ui, server = server)