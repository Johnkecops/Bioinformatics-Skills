# Three-tab Shiny app built from modules.
# Files in R/ (helpers + one module per tab) are sourced automatically before
# this file runs (shiny >= 1.5), so no source() calls are needed.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

# For bookmarking, the UI must be a function of `request`: Shiny calls it with
# the restored state when someone opens a bookmark link.
ui <- function(request) {
  page_navbar(
    title = "Datasets, plots and models",
    id = "tab",                       # an id makes the active tab part of the bookmark
    theme = bs_theme(version = 5),
    nav_panel("Data",  data_ui("data")),
    nav_panel("Plot",  plot_ui("plot")),
    nav_panel("Model", model_ui("model")),
    nav_spacer(),
    nav_item(bookmarkButton(label = "Bookmark"))
  )
}

server <- function(input, output, session) {
  # The Data module owns the dataset choice and returns it as reactives.
  # The other modules receive those reactives (uncalled), so they stay live.
  ds <- data_server("data")
  plot_server("plot", data = ds$data, name = ds$name)
  model_server("model", data = ds$data, name = ds$name)
}

# "url": the whole state is encoded in the link, nothing is stored on the server.
shinyApp(ui, server, enableBookmarking = "url")
