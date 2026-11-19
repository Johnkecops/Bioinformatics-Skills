# Data tab: pick a built-in dataset and show it.

datasets <- list(iris = iris, mtcars = mtcars, ToothGrowth = ToothGrowth)

# Numeric columns of a data frame (used by the Plot and Model modules)
numeric_cols <- function(df) names(df)[vapply(df, is.numeric, logical(1))]

dataUI <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      selectInput(ns("dataset"), "Dataset", choices = names(datasets))
    ),
    mainPanel(DTOutput(ns("table")))
  )
}

dataServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # DT creates many helper inputs; keep them out of the bookmark URL
    setBookmarkExclude(paste0("table_", c(
      "rows_current", "rows_all", "state", "search", "cell_clicked",
      "row_last_clicked", "rows_selected", "columns_selected", "cells_selected"
    )))

    data <- reactive(datasets[[input$dataset]])
    output$table <- renderDT(data(), options = list(pageLength = 10))
    data
  })
}
