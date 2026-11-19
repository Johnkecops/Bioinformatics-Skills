# Model tab: fit lm(y ~ x) on two numeric columns when a button is clicked,
# with a progress bar for the (simulated) slow fit.
model_ui <- function(id) {
  ns <- NS(id)
  cols <- numeric_cols(datasets$iris)
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("y"), "Response (y)", choices = cols, selected = cols[1]),
      selectInput(ns("x"), "Predictor (x)", choices = cols, selected = cols[2]),
      actionButton(ns("fit"), "Fit model", class = "btn-primary")
    ),
    card(card_header("Model summary"), verbatimTextOutput(ns("summary")), full_screen = TRUE)
  )
}

# `data` and `name` are reactives from the Data module.
model_server <- function(id, data, name) {
  stopifnot(is.reactive(data), is.reactive(name))
  moduleServer(id, function(input, output, session) {
    # Don't store the button count in bookmarks: a restored link should not
    # look like "already clicked". Ids here are local; Shiny adds the namespace.
    setBookmarkExclude("fit")

    # Same restore trick as the Plot module, for both pickers.
    restored <- reactiveVal(list())
    onRestore(function(state) restored(state$input[c("y", "x")]))

    observe({
      cols <- numeric_cols(data())
      r <- restored()
      updateSelectInput(session, "y", choices = cols,
                        selected = pick_col(c(r$y, input$y), cols, cols[1]))
      updateSelectInput(session, "x", choices = cols,
                        selected = pick_col(c(r$x, input$x), cols, cols[min(2, length(cols))]))
      restored(list())
    }) |> bindEvent(data())

    # The fit runs only when the button is clicked (bindEvent), not on every
    # change of a picker. All checks live here, so the output shows a message.
    fit <- reactive({
      req(input$x, input$y)          # pickers not filled yet: do nothing
      d <- data()
      validate(
        need(input$x != input$y, "Choose two different columns: y ~ y is not a model."),
        need(all(c(input$x, input$y) %in% names(d)), "Columns are updating, click Fit again.")
      )
      f <- reformulate(input$x, response = input$y)

      # Pretend the fit is slow so the progress bar is visible.
      withProgress(message = "Fitting model", value = 0, {
        for (i in 1:10) {
          Sys.sleep(0.2)
          incProgress(1 / 10, detail = sprintf("step %d of 10", i))
        }
        m <- lm(f, data = d)
      })
      # Make the printed call readable: lm(formula = y ~ x, data = iris)
      m$call <- call("lm", formula = f, data = as.name(name()))
      m
    }) |> bindEvent(input$fit)

    output$summary <- renderPrint({
      validate(need(input$fit > 0, "Choose y and x, then click 'Fit model'."))
      summary(fit())
    })
  })
}
