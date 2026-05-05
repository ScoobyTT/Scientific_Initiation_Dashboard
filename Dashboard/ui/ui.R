ui <- page_navbar(
  theme = bs_theme(version = 5, bootswatch = "minty"),
  title = "Dashboard Dengue 2014 a 2025-SE05",
  collapsible = TRUE,
  inverse = TRUE,
  fillable = FALSE,
  nav_spacer(),
  nav_item(input_dark_mode()),
  
  header = tagList(
    tags$style(HTML("
      .selectize-dropdown { z-index: 9999 !important; }
    ")),
    
    # Filtros
    div(
      style = "margin-top: 30px; padding: 0 15px;",
      card(
        card_header(div("Filtros de Dados", style = "text-align: center;")),
        card_body(
          fluidRow(
            column(
              width = 3,
              selectInput(
                inputId = "uf_filter",
                label = "Estado:",
                choices = c("Todos", "AC", "AL", "AP", "AM", "BA", "CE", "DF",
                            "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB",
                            "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR",
                            "SC", "SP", "SE", "TO"),
                selected = "Todos"
              )
            ),
            column(width = 3),
            column(width = 3),
            column(width = 3)
          )
        )
      )
    ),
    
    # Cards de valores
    layout_column_wrap(
      width = 1/4,
      fill = FALSE,
      class = "mt-3",
      style = "padding: 0 15px;",
      value_box(
        "Casos Notificados",
        uiOutput("total_cases", container = h2),
        showcase = bsicons::bs_icon("clipboard-check"),
        theme_color = "primary"
      ),
      value_box(
        "Casos Confirmados",
        uiOutput("new_cases", container = h2),
        showcase = bsicons::bs_icon("bookmark-plus"),
        theme_color = "secondary"
      ),
      value_box(
        "Óbitos Notificados",
        uiOutput("total_deaths", container = h2),
        showcase = bsicons::bs_icon("person-fill-dash"),
        theme_color = "success"
      ),
      value_box(
        "Óbitos Confirmados",
        uiOutput("new_deaths", container = h2),
        showcase = bsicons::bs_icon("person-fill-exclamation"),
        theme_color = "danger"
      )
    ),
    
    verbatimTextOutput("debug_info"),
    
    # Gráfico 1 e Previsão
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 15px;",
      card(
        full_screen = TRUE,
        card_header(
          "Gráfico de casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_color", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplot"), type = 6, color = "#0d6efd")
      ),
      card(
        full_screen = TRUE,
        card_header(
          "Previsão de Casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_color2", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotPrev"), type = 6, color = "#0d6efd")
      )
    ),
    
    # Gráfico 2 e Diagrama
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 15px;",
      card(
        full_screen = TRUE,
        card_header(
          "Pirâmide por idade",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_colorS", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotSegundo"), type = 6, color = "#0d6efd")
      ),
      card(
        full_screen = TRUE,
        card_header(
          "Diagrama de Controle",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_colorS2", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotTerceiro"), type = 6, color = "#0d6efd")
      )
    ),
    
    # Mapa e Tabela
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 15px;",
      card(
        full_screen = TRUE,
        card_header("Mapa de Casos de Dengue por Município"),
        withSpinner(uiOutput("mapaGeral_ou_mapaBrasilia", height = "570px"), type = 6, color = "#0d6efd")
      ),
      card(
        full_screen = TRUE,
        class = "bslib-card-table-sm",
        card_header("Casos de Dengue por Estado"),
        withSpinner(DT::dataTableOutput("table"), type = 6, color = "#0d6efd")
      )
    )
  ),
  
  footer = tags$footer(
    style = "background-color: #f8f9fa; padding: 20px; font-size: 14px; border-top: 1px solid #dee2e6; margin-top: 30px;",
    div(
      style = "display: flex; justify-content: space-between; flex-wrap: wrap; align-items: center;",
      div(
        style = "flex: 1; min-width: 200px;",
        tags$b("Developed using: "), "UNEB G2BC/PIMAT", tags$br(),
        img(src = "imagem.png", height = "40px", style = "margin: 5px;"),
        img(src = "cnpq.png", height = "40px", style = "margin: 5px;")
      ),
      div(
        style = "flex: 2; min-width: 300px; text-align: center;",
        tags$b("Developed using: "), "UNEB G2BC/PIMAT", tags$br(),
        img(src = "unb.png", height = "40px", style = "margin: 5px;")
      ),
      div(
        style = "flex: 1; min-width: 200px; text-align: center;",
        "Dados: ", tags$a("SINAN/DATASUS", href = "https://datasus.saude.gov.br/", target = "_blank"),
        " · UNEB G2BC/PIMAT", tags$br(),
        tags$em(paste0("Atualizado: ", format(Sys.Date(), "%d/%m/%Y")))
      )
      
    )
  )
)