page_navbar(
  title = tags$span(
    bsicons::bs_icon("virus"), " Dashboard Dengue Brasil",
    style = "font-weight: 600; letter-spacing: 0.5px;"
  ),
  collapsible = TRUE,
  navbar_options = navbar_options(
    theme = "dark",
    collapsible = TRUE
  ),
  theme = bs_theme(
    version = 5,
    bootswatch = "minty",
    base_font = font_google("Inter"),
    heading_font = font_google("Inter")
  ),
  fillable = FALSE,

  # Toggle modo escuro
  nav_item(
    input_dark_mode(id = "dark_mode", mode = "light")
  ),

  # ── Filtros ────────────────────────────────────────────────────────────────
  card(
    class = "mb-3 mt-3",
    card_body(
      fluidRow(
        column(
          width = 3,
          selectInput(
            inputId = "uf_filter",
            label   = "Estado:",
            choices = c("Todos", "AC","AL","AP","AM","BA","CE","DF","ES",
                        "GO","MA","MT","MS","MG","PA","PB","PR","PE","PI",
                        "RJ","RN","RS","RO","RR","SC","SP","SE","TO"),
            selected = "Todos"
          )
        ),
        column(
          width = 3,
          tags$label("Período:", class = "form-label"),
          tags$p(
            class = "text-muted small mt-1",
            "2014 – 2025"
          )
        ),
        column(width = 3),
        column(
          width = 3,
          tags$label(" ", class = "form-label d-block"),
          actionButton(
            inputId = "apply_filters",
            label   = tagList(bsicons::bs_icon("funnel"), " Aplicar Filtros"),
            class   = "btn-primary w-100"
          )
        )
      )
    )
  ),

  # ── Cards de resumo ────────────────────────────────────────────────────────
  layout_column_wrap(
    width = 1/4,
    fill  = FALSE,
    class = "mb-3",
    value_box(
      "Casos Notificados",
      uiOutput("total_cases", container = h2),
      showcase   = bsicons::bs_icon("clipboard-check"),
      theme      = "primary"
    ),
    value_box(
      "Casos Confirmados",
      uiOutput("new_cases", container = h2),
      showcase   = bsicons::bs_icon("bookmark-plus"),
      theme      = "secondary"
    ),
    value_box(
      "Óbitos Notificados",
      uiOutput("total_deaths", container = h2),
      showcase   = bsicons::bs_icon("person-fill-dash"),
      theme      = "success"
    ),
    value_box(
      "Óbitos Confirmados",
      uiOutput("new_deaths", container = h2),
      showcase   = bsicons::bs_icon("person-fill-exclamation"),
      theme      = "danger"
    )
  ),

  # ── Gráfico 1 + Previsão ──────────────────────────────────────────────────
  layout_column_wrap(
    width = 1/2,
    class = "mb-3",
    card(
      full_screen = TRUE,
      card_header("Evolução de Casos"),
      withSpinner(plotOutput("scatterplot"), type = 6, color = "#0d6efd")
    ),
    card(
      full_screen = TRUE,
      card_header("Previsão de Casos"),
      withSpinner(plotOutput("scatterplotPrev"), type = 6, color = "#0d6efd")
    )
  ),

  # ── Pirâmide + Diagrama ───────────────────────────────────────────────────
  layout_column_wrap(
    width = 1/2,
    class = "mb-3",
    card(
      full_screen = TRUE,
      card_header("Pirâmide Etária"),
      withSpinner(plotOutput("scatterplotSegundo"), type = 6, color = "#0d6efd")
    ),
    card(
      full_screen = TRUE,
      card_header("Diagrama de Controle"),
      withSpinner(plotOutput("scatterplotTerceiro"), type = 6, color = "#0d6efd")
    )
  ),

  # ── Mapa + Tabela ─────────────────────────────────────────────────────────
  layout_column_wrap(
    width = 1/2,
    class = "mb-3",
    card(
      full_screen = TRUE,
      card_header("Mapa de Incidência por Município"),
      withSpinner(
        uiOutput("mapaGeral_ou_mapaBrasilia", height = "570px"),
        type = 6, color = "#0d6efd"
      )
    ),
    card(
      full_screen = TRUE,
      card_header("Casos por Estado"),
      withSpinner(DT::dataTableOutput("table"), type = 6, color = "#0d6efd")
    )
  ),

  # ── Footer ────────────────────────────────────────────────────────────────
  footer = tags$footer(
    class = "mt-4 py-3 border-top",
    style = "font-size: 13px;",
    div(
      class = "d-flex justify-content-between align-items-center flex-wrap px-3",
      div(
        class = "d-flex align-items-center gap-3",
        img(src = "imagem.png", height = "35px"),
        img(src = "cnpq.png",   height = "35px"),
        img(src = "unb.png",    height = "35px")
      ),
      div(
        class = "text-muted",
        "Dados: ", tags$a("SINAN/DATASUS", href = "https://datasus.saude.gov.br", target = "_blank"),
        " · UNEB G2BC/PIMAT · ",
        paste0("Atualizado: ", format(Sys.Date(), "%d/%m/%Y"))
      )
    )
  )
)