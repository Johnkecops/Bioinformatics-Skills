# Modular Shiny app: Data / Plot / Model tabs, with URL bookmarking.
# Run with: shiny::runApp("modules_app")
library(shiny)
library(bslib)
library(DT)

datasets <- c("iris", "mtcars", "ToothGrowth")

numeric_cols <- function(df) names(df)[vapply(df, is.numeric, logical(1))]

# ---- Data module: choose a dataset, show it, return it as a reactive ----
dataUI <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(selectInput(ns("dataset"), "Dataset", choices = datasets)),
    DTOutput(ns("table"))
  )
}

dataServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # DT sends many housekeeping inputs; keep them out of the bookmark URL
    setBookmarkExclude(paste0("table_", c(
      "rows_current", "rows_all", "rows_selected", "row_last_clicked",
      "cell_clicked", "cells_selected", "columns_selected", "search", "state"
    )))
    data <- reactive(get(input$dataset, "package:datasets"))
    output$table <- renderDT(data(), options = list(pageLength = 10))
    data
  })
}

# ---- Plot module: histogram of a numeric column ----
plotUI <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      uiOutput(ns("col_ui")),
      sliderInput(ns("bins"), "Bins", min = 5, max = 50, value = 20)
    ),
    plotOutput(ns("hist"))
  )
}

plotServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    # renderUI so choices follow the dataset; selectInput() restores bookmarked values itself
    output$col_ui <- renderUI(
      selectInput(session$ns("col"), "Numeric column", choices = numeric_cols(data()))
    )
    # render even when the tab is hidden, so restoring a bookmark works from any tab
    outputOptions(output, "col_ui", suspendWhenHidden = FALSE)

    output$hist <- renderPlot({
      req(input$col %in% names(data()))
      x <- data()[[input$col]]
      hist(x, breaks = input$bins, main = paste("Histogram of", input$col),
           xlab = input$col, col = "steelblue", border = "white")
    })
  })
}

# ---- Model module: lm(y ~ x) behind a button, with a progress bar ----
modelUI <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      uiOutput(ns("xy_ui")),
      actionButton(ns("fit"), "Fit model", class = "btn-primary")
    ),
    verbatimTextOutput(ns("summary"))
  )
}

modelServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    setBookmarkExclude("fit")  # a restored click count would refit on load; user clicks again

    output$xy_ui <- renderUI({
      cols <- numeric_cols(data())
      tagList(
        selectInput(session$ns("y"), "Response (y)", choices = cols),
        selectInput(session$ns("x"), "Predictor (x)", choices = cols, selected = cols[min(2, length(cols))])
      )
    })
    outputOptions(output, "xy_ui", suspendWhenHidden = FALSE)

    fit <- eventReactive(input$fit, {
      df <- data()
      req(input$x %in% names(df), input$y %in% names(df))
      withProgress(message = "Fitting model", value = 0, {
        for (i in 1:10) {  # pretend the fit is slow
          Sys.sleep(0.2)
          incProgress(1 / 10, detail = paste0(i * 10, "%"))
        }
        # bquote puts the real formula (e.g. mpg ~ wt) into the printed Call
        eval(bquote(lm(.(reformulate(input$x, input$y)), data = df)))
      })
    })

    output$summary <- renderPrint({
      validate(need(input$fit > 0, "Choose x and y, then click 'Fit model'."))
      summary(fit())
    })
  })
}

# ---- App ----
ui <- function(request) {
  page_navbar(
    title = "R Course Explorer",
    id = "tabs",  # an id makes the active tab part of the bookmark
    nav_panel("Data", dataUI("data")),
    nav_panel("Plot", plotUI("plot")),
    nav_panel("Model", modelUI("model")),
    nav_spacer(),
    nav_item(bookmarkButton())
  )
}

server <- function(input, output, session) {
  data <- dataServer("data")
  plotServer("plot", data)
  modelServer("model", data)
}

shinyApp(ui, server, enableBookmarking = "url")
