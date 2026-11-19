# Modular Shiny app: Data / Plot / Model tabs, with URL bookmarking.
# Modules live in R/ and are sourced automatically by shiny::runApp().
library(shiny)
library(ggplot2)
library(DT)

# ui must be a function(request) for bookmarking to work
ui <- function(request) {
  navbarPage(
    "R Course: Modules Demo",
    id = "tabs",                       # so the active tab is bookmarked too
    tabPanel("Data",  dataUI("data")),
    tabPanel("Plot",  plotUI("plot")),
    tabPanel("Model", modelUI("model"))
  )
}

server <- function(input, output, session) {
  dataset <- dataServer("data")        # returns a reactive data frame
  plotServer("plot", dataset)
  modelServer("model", dataset)

  # Keep the browser URL in sync with the app state: copy it at any time
  # to bookmark / share the current view.
  observe({
    reactiveValuesToList(input)
    session$doBookmark()
  })
  onBookmarked(updateQueryString)
}

shinyApp(ui, server, enableBookmarking = "url")
