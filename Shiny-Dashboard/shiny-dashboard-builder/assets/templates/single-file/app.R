# Single-file dashboard template: sidebar filters -> one filtered dataset -> cards.
# Replace `dat` and the column names; keep the shape:
#   static data loaded once  ->  one reactive filtered()  ->  every output reads filtered()
library(shiny)
library(bslib)
library(ggplot2)

# Loaded once per R process, shared by all sessions (see full-dashboards.md, rule 1).
dat <- iris
num_cols <- names(dat)[vapply(dat, is.numeric, logical(1))]

ui <- page_sidebar(
  title = "Dashboard title",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    selectInput("group", "Species", choices = levels(dat$Species),
                selected = levels(dat$Species), multiple = TRUE),
    selectInput("x", "X variable", choices = num_cols, selected = num_cols[1]),
    selectInput("y", "Y variable", choices = num_cols, selected = num_cols[2]),
    downloadButton("download", "Download filtered CSV")
  ),
  layout_columns(
    fill = FALSE,
    value_box(title = "Rows shown", value = textOutput("n_rows")),
    value_box(title = "Mean of X", value = textOutput("mean_x"))
  ),
  layout_columns(
    card(card_header("Scatter plot"), plotOutput("scatter")),
    card(card_header("Data"), tableOutput("table"))
  )
)

server <- function(input, output, session) {
  filtered <- reactive({
    req(input$group)
    dat[dat$Species %in% input$group, , drop = FALSE]
  })

  output$n_rows <- renderText(nrow(filtered()))
  output$mean_x <- renderText(round(mean(filtered()[[input$x]]), 2))

  output$scatter <- renderPlot({
    ggplot(filtered(), aes(.data[[input$x]], .data[[input$y]], colour = Species)) +
      geom_point(size = 2) +
      theme_minimal(base_size = 14)
  })

  output$table <- renderTable(head(filtered(), 20))

  output$download <- downloadHandler(
    filename = function() paste0("filtered-", Sys.Date(), ".csv"),
    content = function(file) write.csv(filtered(), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
