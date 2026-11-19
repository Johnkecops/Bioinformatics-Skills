# Plot tab: histogram of one numeric column of the current dataset.
plot_ui <- function(id, cols) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("column"), "Numeric column", choices = cols),
      sliderInput(ns("bins"), "Number of bins", min = 5, max = 50, value = 20)
    ),
    card(card_header("Histogram"), plotOutput(ns("hist")))
  )
}

plot_server <- function(id, dataset) {
  stopifnot(is.reactive(dataset))
  moduleServer(id, function(input, output, session) {
    # When the dataset changes, offer its numeric columns. Keep the current choice
    # if it still exists (this is also what keeps a restored bookmark intact).
    observeEvent(dataset(), {
      cols <- numeric_cols(dataset())
      keep <- if (isTRUE(input$column %in% cols)) input$column else cols[1]
      updateSelectInput(session, "column", choices = cols, selected = keep)
    })

    output$hist <- renderPlot({
      # For a moment after a dataset switch, the old column name is still selected.
      validate(need(input$column %in% names(dataset()), "Choose a column"))
      ggplot(dataset(), aes(.data[[input$column]])) +
        geom_histogram(bins = input$bins, fill = "steelblue", colour = "white") +
        labs(x = input$column, y = "Count") +
        theme_minimal(base_size = 14)
    })
  })
}
