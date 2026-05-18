ui <- page_navbar(
  theme = bs_theme(
    version = 5,
    bootswatch = "minty",
    base_font = font_google("DM Sans"),
    heading_font = font_google("DM Sans"),
    code_font = font_google("JetBrains Mono")
  ),
  title = tags$span(
    tags$img(src = "logo.png", height = "24px", style = "margin-right: 8px; opacity: 0.9;"),
    "Dashboard Dengue"
  ),
  collapsible = TRUE,
  fillable = FALSE,
  nav_spacer(),
  nav_item(input_dark_mode(id = "dark_mode")),
  
  header = tagList(
    tags$head(
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$style(HTML("
        /* ── Base ── */
        :root {
          --dengue-accent: #e63946;
          --dengue-accent2: #2a9d8f;
          --radius: 12px;
          --transition: 0.2s ease;
        }
        .bslib-input-dark-mode svg {
  fill: #333333 !important;
  color: #333333 !important;
        }
.shiny-plot-output {
  background: transparent !important;
}

html[data-bs-theme='dark'] .bslib-input-dark-mode svg {
  fill: #e8e8e8 !important;
  color: #e8e8e8 !important;
}

        /* ── Light mode ── */
        body {
          background-color: #f5f5f0 !important;
          color: #1a1a2e !important;
          font-family: 'DM Sans', sans-serif !important;
          letter-spacing: -0.01em;
        }

        .navbar {
          background: rgba(255,255,255,0.85) !important;
          backdrop-filter: blur(12px) !important;
          border-bottom: 1px solid rgba(0,0,0,0.07) !important;
          box-shadow: 0 1px 12px rgba(0,0,0,0.06) !important;
          padding: 10px 20px !important;
        }

        .navbar-brand {
          font-weight: 700 !important;
          font-size: 1.1rem !important;
          color: #1a1a2e !important;
          letter-spacing: -0.02em;
        }

        /* Cards */
        .card {
          overflow: visible !important;
          border: 1px solid rgba(0,0,0,0.07) !important;
          border-radius: var(--radius) !important;
          box-shadow: 0 2px 12px rgba(0,0,0,0.05) !important;
          background: #ffffff !important;
          transition: box-shadow var(--transition), transform var(--transition);
        }

        .card:hover {
          box-shadow: 0 6px 24px rgba(0,0,0,0.09) !important;
          transform: translateY(-1px);
        }

        .card-header {
          background: transparent !important;
          border-bottom: 1px solid rgba(0,0,0,0.06) !important;
          font-weight: 600 !important;
          font-size: 0.88rem !important;
          letter-spacing: 0.02em !important;
          text-transform: uppercase !important;
          color: #555 !important;
          padding: 14px 18px !important;
        }

        .card-body {
          overflow: visible !important;
          padding: 16px 18px !important;
        }

        /* Value boxes */
        .bslib-value-box {
          border-radius: var(--radius) !important;
          border: none !important;
          box-shadow: 0 2px 12px rgba(0,0,0,0.07) !important;
          transition: transform var(--transition), box-shadow var(--transition);
        }

        .bslib-value-box:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(0,0,0,0.12) !important;
        }

        .bslib-value-box .value-box-title {
          font-size: 0.78rem !important;
          font-weight: 600 !important;
          letter-spacing: 0.06em !important;
          text-transform: uppercase !important;
          opacity: 0.85;
        }

        .bslib-value-box .value-box-value {
          font-size: 1.8rem !important;
          font-weight: 700 !important;
          letter-spacing: -0.03em !important;
        }

        /* Selectize */
        .selectize-dropdown { z-index: 99999 !important; }
        .selectize-input {
          border-radius: 8px !important;
          border: 1px solid rgba(0,0,0,0.12) !important;
          box-shadow: none !important;
          font-size: 0.9rem !important;
        }
        .selectize-dropdown {
          border-radius: 8px !important;
          border: 1px solid rgba(0,0,0,0.1) !important;
          box-shadow: 0 8px 24px rgba(0,0,0,0.1) !important;
        }

        /* Footer */
        .dengue-footer {
          background: #ffffff !important;
          border-top: 1px solid rgba(0,0,0,0.07) !important;
          margin-top: 40px;
        }

        /* Scrollbar */
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 3px; }

        /* ── Dark mode ── */
        [data-bs-theme='dark'] body,
        html[data-bs-theme='dark'] {
          background-color: #0d0d0d !important;
          color: #e8e8e8 !important;
        }

        html[data-bs-theme='dark'] .navbar {
          background: rgba(13,13,13,0.9) !important;
          border-bottom: 1px solid rgba(255,255,255,0.06) !important;
          box-shadow: 0 1px 12px rgba(0,0,0,0.4) !important;
        }

        html[data-bs-theme='dark'] .navbar-brand {
          color: #e8e8e8 !important;
        }

        html[data-bs-theme='dark'] body {
          background-color: #0d0d0d !important;
        }

        html[data-bs-theme='dark'] .card {
          background: #161616 !important;
          border: 1px solid rgba(255,255,255,0.06) !important;
          box-shadow: 0 2px 16px rgba(0,0,0,0.3) !important;
        }

        html[data-bs-theme='dark'] .card:hover {
          box-shadow: 0 6px 28px rgba(0,0,0,0.5) !important;
          border-color: rgba(255,255,255,0.1) !important;
        }

        html[data-bs-theme='dark'] .card-header {
          border-bottom: 1px solid rgba(255,255,255,0.06) !important;
          color: #aaa !important;
        }

        html[data-bs-theme='dark'] .selectize-input {
          background: #1e1e1e !important;
          border-color: rgba(255,255,255,0.1) !important;
          color: #e8e8e8 !important;
        }

        html[data-bs-theme='dark'] .selectize-dropdown {
          background: #1e1e1e !important;
          border-color: rgba(255,255,255,0.08) !important;
          box-shadow: 0 8px 32px rgba(0,0,0,0.5) !important;
          color: #e8e8e8 !important;
        }

        html[data-bs-theme='dark'] .dengue-footer {
          background: #111111 !important;
          border-top: 1px solid rgba(255,255,255,0.06) !important;
        }

        html[data-bs-theme='dark'] ::-webkit-scrollbar-thumb {
          background: rgba(255,255,255,0.12);
        }

        html[data-bs-theme='dark'] .form-label {
          color: #bbb !important;
        }
      "))
    ),
    
    # Filtros
    div(
      style = "margin-top: 24px; padding: 0 20px;",
      card(
        card_header(div("Filtros", style = "text-align: center;")),
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
          ),
          fluidRow(
            column(
              width = 3,
              sliderInput(
                inputId = "ano_filter",
                label = "Ano:",
                min = 2014,
                max = 2025,
                value = c(2014, 2025),  # intervalo padrão (dois handles)
                step = 1,
                sep = ""  # remove o separador de milhar (evita "2.014")
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
      style = "padding: 0 20px;",
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
        theme = "secondary"
      ),
      value_box(
        "Óbitos Notificados",
        uiOutput("total_deaths", container = h2),
        showcase = bsicons::bs_icon("person-fill-dash"),
        theme = "success"
      ),
      value_box(
        "Óbitos Confirmados",
        uiOutput("new_deaths", container = h2),
        showcase = bsicons::bs_icon("person-fill-exclamation"),
        theme = "danger"
      )
    ),
    
    verbatimTextOutput("debug_info"),
    
    # Gráfico 1 e Previsão
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 20px;",
      card(
        full_screen = TRUE,
        card_header(
          "Evolução de Casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_color", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Opções",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplot"), type = 6, color = "#e63946")
      ),
      card(
        full_screen = TRUE,
        card_header(
          "Previsão de Casos",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_color2", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Opções",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotPrev"), type = 6, color = "#e63946")
      )
    ),
    
    # Gráfico 2 e Diagrama
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 20px;",
      card(
        full_screen = TRUE,
        card_header(
          "Pirâmide Etária",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_colorS", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Opções",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotSegundo"), type = 6, color = "#e63946")
      ),
      card(
        full_screen = TRUE,
        card_header(
          "Diagrama de Controle",
          popover(
            bsicons::bs_icon("gear"),
            radioButtons("scatter_colorS2", NULL, inline = TRUE,
                         c("none", "sex", "smoker", "day", "time")),
            title = "Opções",
            placement = "top"
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        withSpinner(plotOutput("scatterplotTerceiro"), type = 6, color = "#e63946")
      )
    ),
    
    # Mapa e Tabela
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      style = "padding: 0 20px;",
      card(
        full_screen = TRUE,
        card_header("Mapa de Incidência por Município"),
        withSpinner(uiOutput("mapaGeral_ou_mapaBrasilia", height = "570px"), type = 6, color = "#e63946")
      ),
      card(
        full_screen = TRUE,
        class = "bslib-card-table-sm",
        card_header("Casos por Estado"),
        withSpinner(DT::dataTableOutput("table"), type = 6, color = "#e63946")
      )
    )
  ),
  
  footer = tags$footer(
    class = "dengue-footer",
    style = "padding: 24px 20px; font-size: 13px; margin-top: 40px;",
    div(
      style = "display: flex; justify-content: space-between; flex-wrap: wrap; align-items: center; gap: 16px;",
      div(
        style = "flex: 1; min-width: 200px;",
        tags$b("UNEB G2BC/PIMAT"), tags$br(),
        img(src = "imagem.png", height = "36px", style = "margin: 6px 6px 0 0; opacity: 0.85;"),
        img(src = "cnpq.png", height = "36px", style = "margin: 6px 6px 0 0; opacity: 0.85;")
      ),
      div(
        style = "flex: 2; min-width: 300px; text-align: center;",
        img(src = "unb.png", height = "36px", style = "opacity: 0.85;")
      ),
      div(
        style = "flex: 1; min-width: 200px; text-align: right; opacity: 0.7;",
        "Dados: ", tags$a("SINAN/DATASUS", href = "https://datasus.saude.gov.br/", target = "_blank"),
        tags$br(),
        tags$em(paste0("Atualizado: ", format(Sys.Date(), "%d/%m/%Y")))
      )
    )
  )
)