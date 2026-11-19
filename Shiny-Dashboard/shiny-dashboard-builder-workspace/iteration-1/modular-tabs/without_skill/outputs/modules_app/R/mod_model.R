# Model tab: lm(y ~ x) on two chosen columns, fitted on button click with a
# progress bar (the "slow" part is simulated with Sys.sleep).

modelUI <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      selectInput(ns("y"), "Response (y)", choices = NULL),
      selectInput(ns("x"), "Predictor (x)", choices = NULL),
      actionButton(ns("fit"), "Fit model", class = "btn-primary")
    ),
    mainPanel(verbatimTextOutput(ns("summary")))
  )
}

modelServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    # The button's click count is meaningless in a URL; we bookmark the
    # fitted formula instead (see onBookmark below).
    setBookmarkExclude("fit")

    restored <- list()
    onRestore(function(state) {
      restored <<- list(x = state$input$x, y = state$input$y)
      fitted_on(state$values$fitted_on)
    })

    observeEvent(data(), {
      cols <- numeric_cols(data())
      update_col_select(session, "y", cols, restored$y %||% input$y, 1)
      update_col_select(session, "x", cols, restored$x %||% input$x, 2)
      restored <<- list()
    })

    # What the last fit used: list(x, y). Only changes when the button is
    # clicked, so changing the selects doesn't silently refit.
    fitted_on <- reactiveVal(NULL)
    observeEvent(input$fit, fitted_on(list(x = input$x, y = input$y)))
    onBookmark(function(state) state$values$fitted_on <- fitted_on())

    output$summary <- renderPrint({
      f <- fitted_on()
      validate(need(f, "Choose x and y, then click 'Fit model'."))
      validate(need(all(unlist(f) %in% names(data())),
                    "Selected columns are not in this dataset; click 'Fit model' again."))

      withProgress(message = "Fitting model", value = 0, {
        for (i in 1:10) {
          Sys.sleep(0.2)  # pretend the fit is slow
          incProgress(1 / 10, detail = paste0(i * 10, "%"))
        }
        fit <- lm(reformulate(f$x, response = f$y), data = data())
      })
      summary(fit)
    })
  })
}
