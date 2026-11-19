# Model tab: fit lm(y ~ x) on two numeric columns when the button is clicked.
model_ui <- function(id, cols) {
  ns <- NS(id)
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("y"), "Response (y)", choices = cols, selected = cols[1]),
      selectInput(ns("x"), "Predictor (x)", choices = cols, selected = cols[2]),
      actionButton(ns("fit"), "Fit model", class = "btn-primary")
    ),
    card(card_header("lm(y ~ x) summary"), verbatimTextOutput(ns("summary")))
  )
}

model_server <- function(id, dataset) {
  stopifnot(is.reactive(dataset))
  moduleServer(id, function(input, output, session) {
    # Same idea as the Plot tab: refresh choices, keep still-valid selections.
    observeEvent(dataset(), {
      cols <- numeric_cols(dataset())
      pick <- function(cur, default) if (isTRUE(cur %in% cols)) cur else default
      updateSelectInput(session, "y", choices = cols, selected = pick(input$y, cols[1]))
      updateSelectInput(session, "x", choices = cols, selected = pick(input$x, cols[2]))
    })

    # The (pretend) slow fit runs only when the button is clicked, not every time
    # a dropdown changes. bindEvent ignores the button's initial 0, so nothing
    # runs at startup.
    fit <- reactive({
      df <- dataset()
      validate(
        need(all(c(input$x, input$y) %in% names(df)), "Choose two columns"),
        need(input$x != input$y, "Choose two different columns for x and y")
      )
      withProgress(message = "Fitting model", value = 0, {
        for (i in 1:10) {
          Sys.sleep(0.2)                # pretend this is expensive
          incProgress(1 / 10, detail = paste0(i * 10, "%"))
        }
        # reformulate() builds y ~ x from the column names; backticks handle odd names
        lm(reformulate(sprintf("`%s`", input$x), response = input$y), data = df)
      })
    }) |> bindEvent(input$fit)

    output$summary <- renderPrint(summary(fit()))
  })
}
