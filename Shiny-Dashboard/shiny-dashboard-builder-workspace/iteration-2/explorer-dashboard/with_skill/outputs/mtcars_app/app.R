# mtcars explorer: filter -> brush the scatter plot -> table of brushed cars -> CSV download.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

# Loaded once per R process. Car names live in row names, which brushedPoints() keeps
# but write.csv(row.names = FALSE) would drop, so make them a real column.
cars <- data.frame(car = rownames(mtcars), mtcars, row.names = NULL)

ui <- page_sidebar(
  title = "mtcars explorer",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    checkboxGroupInput("cyl", "Cylinders", choices = sort(unique(cars$cyl)),
                       selected = sort(unique(cars$cyl))),
    checkboxGroupInput("am", "Transmission",
                       choices = c("Automatic" = 0, "Manual" = 1),
                       selected = c(0, 1)),
    downloadButton("download_csv", "Download brushed cars (CSV)")
  ),
  card(
    card_header("Weight vs MPG (drag a box to select cars)"),
    # resetOnNew: clear the brush when the filters redraw the plot, so the table
    # never shows cars selected from a previous view
    plotOutput("scatter", brush = brushOpts("scatter_brush", resetOnNew = TRUE))
  ),
  card(
    card_header(textOutput("table_title")),
    DTOutput("brushed_table")
  )
)

server <- function(input, output, session) {
  # one shared reactive: filtering runs once and the plot and brush both use it
  filtered <- reactive({
    validate(
      need(length(input$cyl) > 0, "Select at least one cylinder count."),
      need(length(input$am) > 0, "Select at least one transmission type.")
    )
    cars[cars$cyl %in% input$cyl & cars$am %in% input$am, , drop = FALSE]
  })

  output$scatter <- renderPlot({
    validate(need(nrow(filtered()) > 0, "No cars match these filters."))
    # factor(cyl) is computed inside aes(), so no helper column ends up in the table/CSV
    ggplot(filtered(), aes(wt, mpg, colour = factor(cyl))) +
      geom_point(size = 3) +
      labs(x = "Weight (1000 lbs)", y = "Miles per gallon", colour = "Cylinders") +
      theme_minimal(base_size = 14)
  })

  # brushedPoints() must get the same data that was plotted; NULL brush -> 0 rows
  brushed <- reactive(brushedPoints(filtered(), input$scatter_brush))

  output$table_title <- renderText(paste("Brushed cars:", nrow(brushed())))

  output$brushed_table <- renderDT({
    validate(need(nrow(brushed()) > 0, "Drag a box over points in the plot to list cars here."))
    datatable(brushed(), rownames = FALSE, options = list(pageLength = 10))
  })

  # downloads exactly what the table shows (an empty CSV with headers if nothing is brushed)
  output$download_csv <- downloadHandler(
    filename = function() paste0("mtcars-brushed-", Sys.Date(), ".csv"),
    content = function(file) write.csv(brushed(), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
