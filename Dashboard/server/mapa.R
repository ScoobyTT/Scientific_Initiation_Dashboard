library(geobr)
library(leaflet)
library(sf)


if (!file.exists(estados_path)) {
  estados <- geobr::read_state(year = 2020)
  saveRDS(estados, estados_path)
} else {
  estados <- readRDS(estados_path)
}
dados_filtradosMP <- reactive({
  req(input$uf_filter)
  
  if (input$uf_filter == "Todos") {
    estados
  } else {
    estados %>% filter(abbrev_state == input$uf_filter)
  }

})
output$mapaGeral_ou_mapaBrasilia <- renderUI({
  if(input$uf_filter == "DF") {
    leafletOutput("mapa_df", height = "570px")
  } else {
    leafletOutput("mapa_dengue", height = "570px")
  }
})

dados_filtradosMP2 <- reactive({
  req(input$uf_filter)
  
  dados <- plot5s
  
  if (input$uf_filter != "Todos") {
    dados <- dados %>% filter(abbrev_state == input$uf_filter)
    muni <- municipios %>% filter(abbrev_state == input$uf_filter)
  } else {
    muni <- municipios
  }
  
  dados <- dados %>%
    group_by(State, cod_municipio, nome_munic, populacao) %>%
    summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
    mutate(incidence = (New_Cases / populacao) * 100000)
  
  resultado <- muni %>%
    left_join(dados, by = c("code_state" = "State", "code_muni" = "cod_municipio"))
  
  resultado <- replace_na(resultado, list(incidence = 0))
  resultado$inc_cat <- cut(
    resultado$incidence,
    breaks = c(0, 100, 500, 2500, 10000, Inf),
    labels = c("0–100", "101–500", "501–2500", "2501–10k", ">10k"),
    include.lowest = TRUE
  )
  dados_filtradosMP2 <- reactive({
    req(input$uf_filter)
    
    dados <- as.data.frame(plot5)
    
    if (!is.null(input$ano_filter)) {
      dados <- dados %>%
        filter(years >= input$ano_filter[1],
               years <= input$ano_filter[2])
    }
    
    if (input$uf_filter != "Todos") {
      dados <- dados %>% filter(abbrev_state == input$uf_filter)
      muni <- municipios %>% filter(abbrev_state == input$uf_filter)
    } else {
      muni <- municipios
    }
    
    dados <- dados %>%
      group_by(State, cod_municipio, nome_munic, populacao) %>%
      summarise(New_Cases = sum(New_Cases), .groups = "drop") %>%
      mutate(incidence = (New_Cases / populacao) * 100000)
    
    resultado <- muni %>%
      left_join(dados, by = c("code_state" = "State", "code_muni" = "cod_municipio"))
    
    resultado <- replace_na(resultado, list(incidence = 0))
    resultado$inc_cat <- cut(
      resultado$incidence,
      breaks = c(0, 100, 500, 2500, 10000, Inf),
      labels = c("0–100", "101–500", "501–2500", "2501–10k", ">10k"),
      include.lowest = TRUE
    )
    
    st_transform(resultado, 4326)
    print(nrow(resultado))
    print(table(resultado$inc_cat, useNA = "always"))
  })
  resultado <- st_transform(resultado, 4326)
  resultado
  
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

