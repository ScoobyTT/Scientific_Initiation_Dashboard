gradient <- function(theme_color = "primary") {
  bg_color <- paste0("bg-", theme_color)
  bgg_color <- if ("4" %in% theme_version(theme)) {
    paste0("bg-gradient-", theme_color)
  } else {
    paste(bg_color, "bg-gradient")
  }
  bg_div <- function(color_class, ...) {
    display_classes <- paste(
      paste0(".", strsplit(color_class, "\\s+")[[1]]),
      collapse = " "
    )
    div(
      class = "p-3", class = color_class,
      display_classes, ...
    )
  }
  fluidRow(
    column(6, bg_div(bg_color)),
    column(6, bg_div(bgg_color))
  )
}

theme_colors <- c("primary", "secondary", "default", "success", "info", "warning", "danger", "dark")
gradients <- lapply(theme_colors, gradient)

progressBar <- div(
  class="progress",
  div(
    class="progress-bar w-25",
    role="progressbar",
    "aria-valuenow"="25",
    "aria-valuemin"="0",
    "aria-valuemax"="100"
  )
)

bs_table <- function(x, class = NULL, ...) {
  class <- paste(c("table", class), collapse = " ")
  class <- sprintf('class="%s"', class)
  HTML(knitr::kable(x, format = "html", table.attr = class))
}
