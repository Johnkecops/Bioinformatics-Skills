# Plot tab: histogram of a numeric column of the chosen dataset.

# Refresh a column selectInput whenever the dataset changes. `wanted` is the
# value to keep if it still exists (e.g. a value restored from a bookmark).
update_col_select <- function(session, id, cols, wanted, fallback = 1) {
  sel <- if (!is.null(wanted) && wanted %in% cols) wanted else cols[min(fallback, length(cols))]
  updateSelectInput(session, id, choices = cols, selected = sel)
}

plotUI <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      selectInput(ns("col"), "Numeric column", choices = NULL),
      sliderInput(ns("bins"), "Bins", min = 5, max = 50, value = 20)
    ),
    mainPanel(plotOutput(ns("hist")))
  )
}

plotServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    # The select starts empty, so a bookmarked column can't be restored by
    # Shiny itself; remember it and apply it once the choices exist.
    restored <- NULL
    onRestore(function(state) restored <<- state$input$col)

    observeEvent(data(), {
      update_col_select(session, "col", numeric_cols(data()),
                        if (is.null(restored)) input$col else restored)
      restored <<- NULL
    })

    output$hist <- renderPlot({
      req(input$col %in% names(data()))
      ggplot(data(), aes(.data[[input$col]])) +
        geom_histogram(bins = input$bins, fill = "steelblue", colour = "white") +
        theme_minimal(base_size = 14)
    })
  })
}
