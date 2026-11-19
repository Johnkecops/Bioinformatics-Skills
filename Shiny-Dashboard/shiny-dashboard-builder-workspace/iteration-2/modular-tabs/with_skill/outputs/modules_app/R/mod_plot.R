# Plot tab: histogram of one numeric column, with a bins slider.
plot_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      # Start with iris's columns (the default dataset); the server swaps them
      # when another dataset is chosen.
      selectInput(ns("column"), "Numeric column", choices = numeric_cols(datasets$iris)),
      sliderInput(ns("bins"), "Number of bins", min = 5, max = 50, value = 20)
    ),
    card(plotOutput(ns("hist")), full_screen = TRUE)
  )
}

# `data` and `name` are reactives from the Data module.
plot_server <- function(id, data, name) {
  stopifnot(is.reactive(data), is.reactive(name))
  moduleServer(id, function(input, output, session) {
    # A bookmark may hold a column of another dataset (e.g. mpg), which the
    # startup choices don't contain. Keep it here until the choices are updated.
    restored <- reactiveVal(NULL)
    onRestore(function(state) restored(state$input$column))

    # Column choices follow the dataset; keep the current pick if still valid.
    observe({
      cols <- numeric_cols(data())
      updateSelectInput(session, "column", choices = cols,
                        selected = pick_col(c(restored(), input$column), cols))
      restored(NULL)
    }) |> bindEvent(data())

    output$hist <- renderPlot({
      d <- data()
      req(input$column)
      # Right after a dataset switch the old column name can arrive first.
      validate(need(input$column %in% numeric_cols(d), "Updating the column list..."))
      ggplot(d, aes(.data[[input$column]])) +
        geom_histogram(bins = input$bins, fill = "#4C78A8", colour = "white") +
        labs(title = sprintf("%s: %s", name(), input$column), y = "Count") +
        theme_minimal(base_size = 14)
    })
  })
}
