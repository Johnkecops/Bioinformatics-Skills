# mtcars explorer: filter in the sidebar -> brush the scatter plot -> brushed cars in a
# table -> download that table as CSV.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

# Loaded once per R process. Car names live in rownames; make them a real column so
# they show up in the table and survive write.csv(row.names = FALSE).
cars <- cbind(car = rownames(mtcars), mtcars, row.names = NULL)
cars$transmission <- factor(cars$am, levels = c(0, 1), labels = c("Automatic", "Manual"))
cyl_choices <- sort(unique(cars$cyl))

ui <- page_sidebar(
  title = "mtcars explorer",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    checkboxGroupInput("cyl", "Cylinders", choices = cyl_choices,
                       selected = cyl_choices, inline = TRUE),
    checkboxGroupInput("transmission", "Transmission",
                       choices = levels(cars$transmission),
                       selected = levels(cars$transmission)),
    helpText("Drag a box over the plot to select cars."),
    downloadButton("download_csv", "Download selected cars (CSV)")
  ),
  card(
    card_header("Weight vs fuel economy"),
    # brush turns the plot into an input: input$scatter_brush holds the box bounds.
    # resetOnNew clears the box when the filters redraw the plot, so it never covers
    # stale points.
    plotOutput("scatter", brush = brushOpts("scatter_brush", resetOnNew = TRUE))
  ),
  card(
    card_header(textOutput("table_title", inline = TRUE)),
    DTOutput("brushed_table")
  )
)

server <- function(input, output, session) {
  # One shared reactive for the sidebar filters: the plot and the brush both use it,
  # so brushedPoints() always sees exactly the rows that were drawn.
  filtered <- reactive({
    validate(
      need(length(input$cyl) > 0, "Pick at least one cylinder count."),
      need(length(input$transmission) > 0, "Pick at least one transmission type.")
    )
    cars[cars$cyl %in% input$cyl & cars$transmission %in% input$transmission, ,
         drop = FALSE]
  })

  # Second stage: rows inside the brush box (NULL brush -> zero rows, no req() needed).
  # The helper "transmission" column is dropped; the original am column stays.
  brushed <- reactive({
    rows <- brushedPoints(filtered(), input$scatter_brush)
    rows[, names(rows) != "transmission", drop = FALSE]
  })

  output$scatter <- renderPlot({
    ggplot(filtered(), aes(wt, mpg, colour = factor(cyl), shape = transmission)) +
      geom_point(size = 3) +
      labs(x = "Weight (1000 lbs)", y = "Miles per gallon",
           colour = "Cylinders", shape = "Transmission") +
      theme_minimal(base_size = 14)
  })

  output$table_title <- renderText(
    paste0("Brushed cars (", nrow(brushed()), " of ", nrow(filtered()), " shown)")
  )

  output$brushed_table <- renderDT(
    datatable(brushed(),
              rownames = FALSE,
              options = list(pageLength = 10,
                             language = list(emptyTable = "Drag a box over the plot to select cars.")))
  )

  # Downloads the same reactive the table shows, so the CSV always matches the screen.
  output$download_csv <- downloadHandler(
    filename = function() paste0("mtcars-brushed-", Sys.Date(), ".csv"),
    content = function(file) {
      write.csv(brushed(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
