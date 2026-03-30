ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = 'minty'),
  page_navbar(
    title = "Dashboard Dengue 2014 a 2025-SE05",
    collapsible = TRUE,
    inverse = TRUE,
    fillable = "Dashboard",
    
    filtros <- bs4Dash::box(
      title = "Filtros de Dados",
      width = 12,
      status = "primary",
      collapsible = TRUE,
      collapsed = FALSE,
      fluidRow(
        column(
          width = 3,
          selectInput(
            inputId = "uf_filter",
            label = "Selecione o Estado:",
            choices = c("Todos", "DF", "AC", "AL", "AP", "AM", "CE","ES",
                        "GO", "MA", "MT", "MS","MG", "PA", "PB", "PR", "PE",
                        "PI", "RJ", "RN", "RS", "RO","RR", "SC", "SP", "SE", "TO", "BA"),
            selected = "Todos"
          )
        ),
        column(width = 3),
        column(width = 3),
        # column(
        #   width = 3,
        #   dateRangeInput(
        #     inputId = "date_filter",
        #     label = "Período:",
        #     start = Sys.Date() - 365,
        #     end = Sys.Date(),
        #     language = "pt-BR"
        #   )
        # ),
        # column(
        #   width = 3,
        #   sliderInput(
        #     inputId = "incidencia_filter",
        #     label = "Faixa de Incidência (por 100k hab):",
        #     min = 0,
        #     max = 500,
        #     value = c(0, 500)
        #   )
        # ),
        column(
          width = 3,
          actionButton(
            inputId = "apply_filters",  # <-- aqui
            label = "Aplicar Filtros",
            icon = icon("filter"),
            class = "btn-primary",
            width = "100%"
          )
        )
      )
    ),
    #barras casos
    layout_column_wrap(
      width = 1/4,
      fill = FALSE,
      value_box(
        "Casos Notificados",
        uiOutput(("total_cases"), container = h2),
        showcase = bsicons::bs_icon("clipboard-check"),
        theme_color = "primary"
      ),
      value_box(
        "Casos Confirmados",
        uiOutput(("new_cases"), container = h2),
        showcase = bsicons::bs_icon("bookmark-plus"),
        theme_color = "secondary"
      ),
      value_box(
        "Óbitos Notificados",
        uiOutput(("total_deaths"), container = h2),
        showcase = bsicons::bs_icon("person-fill-dash"),
        theme_color = "success"
      ),
      value_box(
        "Óbitos Confirmados",
        uiOutput(("new_deaths"), container = h2),
        showcase = bsicons::bs_icon("person-fill-exclamation"),
        theme_color = "danger"
      )
    ),
    verbatimTextOutput("debug_info"),
    
    #
    #PRIMEIRO gráfico de casos
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      card(
        full_screen = TRUE,
        card_header(
          "Gráfico de casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons(
              ("scatter_color"), NULL, inline = TRUE,
              c("none", "sex", "smoker", "day", "time")
            ),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput(("scatterplot")), type = 6, color = "#0d6efd")
      ),
      #-----------------------------------------------------------
      card(
        full_screen = TRUE,
        card_header(
          "Previsão de Casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons(
              ("scatter_color"), NULL, inline = TRUE,
              c("none", "sex", "smoker", "day", "time")
            ),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput(("scatterplotPrev")), type = 6, color = "#0d6efd")
      ),
    ),
    #====================================================================================================================================================================
    #SEGUNDO gráfico de casos
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      card(
        full_screen = TRUE,
        card_header(
          "Piramide por idade",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons(
              ("scatter_colorS"), NULL, inline = TRUE,
              c("none", "sex", "smoker", "day", "time")
            ),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput(("scatterplotSegundo")), type = 6, color = "#0d6efd")
      ),
      #-------------------------------------------------------------
      card(
        full_screen = TRUE,
        card_header(
          "Diagrama de Controle",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons(
              ("scatter_colorS"), NULL, inline = TRUE,
              c("none", "sex", "smoker", "day", "time")
            ),
            title = "Add a color variable",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput(("scatterplotTerceiro")), type = 6, color = "#0d6efd")
      ),
    ),
    #---------------------------------------------------------------
    #LAYOUT DO MAPA
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
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
      ),
    )
  ),
  #------------------------------------------------------------------------------------
  #LAYOUT DO FOOTER
  tags$footer(
    style = "background-color: #f8f9fa; padding: 20px; font-size: 14px; border-top: 1px solid #dee2e6;",
    
    # Seção de parceiros
    div(style = "display: flex; justify-content: space-between; flex-wrap: wrap; align-items: center;",
        
        # Coluna 1: desenvolvimento e dados
        div(style = "flex: 1; min-width: 200px;",
            tags$b("Developed using: "), "UNEB G2BC/PIMAT", tags$br(),
            img(src = "imagem.png", height = "40px", style = "margin: 5px;"),
            img(src = "cnpq.png", height = "40px", style = "margin: 5px;"),
        ),
        
        # Coluna 2: logos
        div(style = "flex: 2; min-width: 300px; text-align: center;",
            tags$b("Developed using: "), "UNEB G2BC/PIMAT", tags$br(),
            img(src = "unb.png", height = "40px", style = "margin: 5px;"),
        ),
        
        # # Coluna 3: instruções
        # div(style = "flex: 1; min-width: 200px; text-align: right;",
        #     "Best viewed using ",
        #     tags$b("Chrome"),
        #     " on 1920x1080 resolution and above.", tags$br(),
        #     tags$em("This website is free and open to all users.")
        # )
    )
  )
) #table_data
