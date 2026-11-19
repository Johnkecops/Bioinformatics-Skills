# Data tab: pick a built-in dataset and show it.
data_ui <- function(id) {
  ns <- NS(id)                        # every id goes through ns() -> "data-dataset"
  layout_sidebar(
    sidebar = sidebar(
      selectInput(ns("dataset"), "Dataset", choices = names(datasets)),
      helpText("The Plot and Model tabs use the dataset chosen here.")
    ),
    card(card_header(textOutput(ns("title"))), DTOutput(ns("table")), full_screen = TRUE)
  )
}

# Returns a list of reactives: the data frame and its name.
data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # One shared reactive: every tab reads this, so the lookup and the check
    # happen once. validate() also catches a hand-edited bookmark URL.
    data <- reactive({
      validate(need(input$dataset %in% names(datasets), "Choose one of the listed datasets."))
      datasets[[input$dataset]]
    })

    output$title <- renderText(sprintf("%s: %d rows, %d columns",
                                       input$dataset, nrow(data()), ncol(data())))
    output$table <- renderDT(data(), options = list(pageLength = 10))

    # Return the reactives themselves (not data()), so callers stay live.
    list(data = data, name = reactive(input$dataset))
  })
}
