# Data tab: pick a dataset and show it. Returns the chosen data frame as a reactive.
data_ui <- function(id, choices) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("dataset"), "Dataset", choices = choices, selected = "iris")
    ),
    card(card_header(textOutput(ns("title"), inline = TRUE)), DTOutput(ns("table")))
  )
}

data_server <- function(id, datasets) {
  moduleServer(id, function(input, output, session) {
    # DT sends many table-state inputs (search, rows shown, clicks); keep them out
    # of the bookmark URL, which should only hold the user's choices.
    setBookmarkExclude(paste0("table_", c(
      "rows_current", "rows_all", "rows_selected", "columns_selected",
      "cells_selected", "cell_clicked", "state", "search", "search_columns"
    )))

    # The one shared reactive: every tab reads the dataset from here.
    dataset <- reactive({
      req(input$dataset %in% names(datasets))   # guards against edited URLs
      datasets[[input$dataset]]
    })

    output$title <- renderText(sprintf("%s: %d rows, %d columns",
                                       input$dataset, nrow(dataset()), ncol(dataset())))
    output$table <- renderDT(dataset(), options = list(pageLength = 10))

    dataset                             # return the reactive, not dataset()
  })
}
