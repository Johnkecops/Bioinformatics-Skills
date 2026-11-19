# One module per file in R/. UI function wraps every id in ns(); server uses moduleServer().
explore_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(3, 9),
    card(
      radioButtons(ns("geom"), "Plot type", c("Boxplot" = "box", "Points" = "point")),
      actionButton(ns("redraw"), "Redraw", class = "btn-primary")
    ),
    card(card_header("Tooth length by dose"), plotOutput(ns("plot")))
  )
}

# `data` is a reactive. Returns the plotted data as a reactive for the caller.
explore_server <- function(id, data) {
  stopifnot(is.reactive(data))
  moduleServer(id, function(input, output, session) {
    plot_data <- reactive(data()) |> bindEvent(input$redraw, data(), ignoreNULL = FALSE)

    output$plot <- renderPlot({
      p <- ggplot(plot_data(), aes(dose, len, colour = supp))
      p <- if (input$geom == "box") p + geom_boxplot() else p + geom_jitter(width = 0.15)
      p + theme_minimal(base_size = 14)
    })

    plot_data
  })
}
