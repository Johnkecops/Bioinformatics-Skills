# Three-tab Shiny app built from modules: Data, Plot, Model.
# The modules live in R/ and are sourced automatically before this file runs.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

# Static data, loaded once per R process and shared by every visitor.
datasets <- list(iris = iris, mtcars = mtcars, ToothGrowth = ToothGrowth)

# The UI is a function of `request`: required for bookmarking.
ui <- function(request) {
  # When a bookmark URL is opened, build the column pickers with the columns of
  # the bookmarked dataset, so the bookmarked column choices are valid on restore.
  # URL values can be edited by anyone, so fall back to iris if it is not one of ours.
  start <- restoreInput("data-dataset", "iris")
  if (!isTRUE(start %in% names(datasets))) start <- "iris"
  start_cols <- numeric_cols(datasets[[start]])

  page_navbar(
    id = "tab",                       # an id makes the selected tab part of the bookmark
    title = "R course: modules demo",
    theme = bs_theme(version = 5),
    nav_panel("Data", data_ui("data", choices = names(datasets))),
    nav_panel("Plot", plot_ui("plot", cols = start_cols)),
    nav_panel("Model", model_ui("model", cols = start_cols)),
    nav_spacer(),
    nav_item(bookmarkButton(label = "Share link"))
  )
}

server <- function(input, output, session) {
  # The Data module returns a reactive data frame; the other two modules receive
  # it uncalled, so they update whenever the dataset changes.
  dataset <- data_server("data", datasets)
  plot_server("plot", dataset)
  model_server("model", dataset)

  # Keep the address bar in sync with the inputs, so the URL is always a bookmark.
  observe({
    reactiveValuesToList(input)       # depend on every input
    session$doBookmark()
  })
  onBookmarked(\(url) updateQueryString(url))
}

shinyApp(ui, server, enableBookmarking = "url")
