library(shiny)
library(bslib)
library(ggplot2)
library(DT)

cars <- cbind(car = rownames(mtcars), mtcars)
cars$transmission <- factor(cars$am, levels = c(0, 1), labels = c("Automatic", "Manual"))

ui <- page_sidebar(
  title = "mtcars explorer",
  sidebar = sidebar(
    checkboxGroupInput("cyl", "Cylinders", choices = sort(unique(cars$cyl)),
                       selected = sort(unique(cars$cyl))),
    checkboxGroupInput("trans", "Transmission", choices = levels(cars$transmission),
                       selected = levels(cars$transmission)),
    downloadButton("download", "Download table as CSV")
  ),
  card(
    card_header("Weight vs MPG (drag a box to select cars)"),
    plotOutput("scatter", brush = brushOpts("brush", resetOnNew = TRUE))
  ),
  card(
    card_header("Brushed cars"),
    DTOutput("table")
  )
)

server <- function(input, output, session) {
  filtered <- reactive({
    cars[cars$cyl %in% input$cyl & cars$transmission %in% input$trans, ]
  })

  # Empty until the user brushes; brushedPoints returns 0 rows when brush is NULL.
  brushed <- reactive(brushedPoints(filtered(), input$brush, xvar = "wt", yvar = "mpg"))

  output$scatter <- renderPlot({
    ggplot(filtered(), aes(wt, mpg, colour = factor(cyl), shape = transmission)) +
      geom_point(size = 3) +
      labs(x = "Weight (1000 lbs)", y = "Miles per gallon", colour = "Cylinders",
           shape = "Transmission") +
      theme_minimal(base_size = 14)
  })

  output$table <- renderDT(
    datatable(brushed(), rownames = FALSE,
              options = list(pageLength = 10, language = list(emptyTable = "Drag a box on the plot to select cars")))
  )

  output$download <- downloadHandler(
    filename = function() paste0("brushed_cars_", Sys.Date(), ".csv"),
    content = function(file) write.csv(brushed(), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
