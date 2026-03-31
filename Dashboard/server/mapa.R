library(geobr)
library(leaflet)
library(sf)

estados <- read_state(code_state = "all", year = 2020, showProgress = FALSE)
  
  # Dados filtrados para estados 
  dados_filtradosMP <- reactive({
    if (input$uf_filter == "Todos") {
      estados #eu tirei o return, descobri q o R ja retorna por padrao o ultimo valor avaliado
    } else {
      estados %>% filter(abbrev_state == input$uf_filter) #tirei daqui tb, comentei pra nao ficar perdido dps. 
    } # e tambem nao guardo mais a variavel, nao tem necessidade
  })
  output$mapaGeral_ou_mapaBrasilia <- renderUI({
    if(input$uf_filter == "DF") {
      leafletOutput("mapa_df", height = "570px")
    } else {
      leafletOutput("mapa_dengue", height = "570px")
    }
  })
  
  # Dados filtrados para municípios 
  dados_filtradosMP2 <- reactive({
    req(input$uf_filter)
    
    if (input$uf_filter == "Todos") {
      dengue_final_filtrado <- dengue.final
    } else {
      dengue_final_filtrado <- dengue.final %>%
        filter(abbrev_state == input$uf_filter)
      dengue_final_filtrado <- replace_na(dengue_final_filtrado, list(incidence = 0))
      dengue_final_filtrado$inc_cat <- cut(
        dengue_final_filtrado$incidence,
        breaks = c(0, 100, 500, 2500, 10000, Inf),
        labels = c("0–100", "101–500", "501–2500", "2501–10k", ">10k"),
        include.lowest = TRUE
      )
    }
    dengue_final_filtrado <- st_transform(dengue_final_filtrado, st_crs(estados))
  })
  
  output$mapa_df <- renderLeaflet({
    shp <- st_read("input/regioes/regioes_administrativas.shp") |>
      st_set_crs(31983) |>
      st_transform(4326)
    
    leaflet(shp) |>
      addTiles() |>
      addPolygons(label = ~ra_nome)
  })
  
                 # MAPA - 
  output$mapa_dengue <- renderLeaflet({
    req(dados_filtradosMP(), dados_filtradosMP2())
    
    estadosMP <- dados_filtradosMP()
    dengue_final_filtrado <- dados_filtradosMP2()
    
    pal <- colorFactor(
      palette = "YlOrRd",
      domain = dengue_final_filtrado$inc_cat
    )
    
    leaflet() %>%
      addTiles() %>%
      # Camada 1: Municípios preenchidos
      addPolygons(
        data = dengue_final_filtrado,
        fillColor = ~pal(inc_cat),
        fillOpacity = 0.7,
        weight = 0.3,
        color = "white",
        label = ~paste(nome_munic, ": ", inc_cat, " casos")
      ) %>%
      # Camada 2: Contornos estaduais
      addPolygons(
        data = estadosMP,
        fill = FALSE,
        color = "black",
        weight = 0.2,
        opacity = 1,
        group = "Bordas Estaduais"
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = dengue_final_filtrado$inc_cat,
        title = "Incidência por 100 mil",
        opacity = 0.7
      ) %>%
      htmlwidgets::onRender("
        function(el, x) {
          document.getElementsByClassName('leaflet-container')[0].style.backgroundColor = 'white';
        }
      ")
  })
  
  ##
 
  