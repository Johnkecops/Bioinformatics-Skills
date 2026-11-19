# Upload a CSV -> pick a numeric column and a grouping column -> per-group summary,
# boxplot, and a downloadable HTML report.
# Run with: shiny::runApp("upload_app")
library(shiny)
library(bslib)
library(ggplot2)

options(shiny.maxRequestSize = 20 * 1024^2)  # allow CSVs up to 20 MB (default is 5 MB)

# Pure helper outside server: it can be tested in the console without running the app.
# Missing values are counted per group, then dropped before mean/sd.
group_summary <- function(df, value, group) {
  g <- as.character(df[[group]])
  g[is.na(g)] <- "(missing group)"  # keep rows whose group is NA visible, not silently dropped
  rows <- lapply(split(df[[value]], g), function(v) {
    data.frame(n = sum(!is.na(v)),
               mean = if (all(is.na(v))) NA else mean(v, na.rm = TRUE),
               sd = sd(v, na.rm = TRUE),  # NA when a group has fewer than 2 values
               missing = sum(is.na(v)))
  })
  out <- do.call(rbind, rows)
  cbind(group = names(rows), out, row.names = NULL)
}

ui <- page_sidebar(
  title = "Group summary and boxplot",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    fileInput("file", "Upload a CSV file", accept = c(".csv", "text/csv")),
    # Choices are empty until a file is uploaded; the server fills them in.
    selectInput("value_col", "Numeric column", choices = NULL),
    selectInput("group_col", "Grouping column", choices = NULL),
    downloadButton("report", "Download HTML report", class = "btn-primary")
  ),
  card(card_header("Summary per group"), tableOutput("summary_table")),
  card(card_header("Boxplot"), plotOutput("boxplot"))
)

server <- function(input, output, session) {
  # Stage 1: read the upload. All file checks live here, so every output shows the
  # same readable message instead of an R error.
  data <- reactive({
    validate(need(input$file, "Upload a CSV file to begin."))
    ext <- tolower(tools::file_ext(input$file$name))
    validate(need(ext == "csv", "That is not a .csv file. Please upload a CSV."))
    df <- tryCatch(read.csv(input$file$datapath, na.strings = c("", "NA")),
                   error = function(e) NULL)
    validate(need(is.data.frame(df) && nrow(df) > 0,
                  "Could not read any rows from this file. Is it a comma-separated CSV?"))
    df
  })

  num_cols <- reactive(names(data())[vapply(data(), is.numeric, logical(1))])

  # When a new file arrives, refill both dropdowns from its columns.
  observeEvent(data(), {
    df <- data()
    nums <- num_cols()
    # Default grouping column: the column (other than the first numeric one) with the
    # fewest distinct values, e.g. Diet rather than Chick in chick_weights.csv.
    others <- setdiff(names(df), nums[1])
    n_levels <- vapply(df[others], function(x) length(unique(x)), integer(1))
    updateSelectInput(session, "value_col", choices = nums, selected = nums[1])
    updateSelectInput(session, "group_col", choices = names(df),
                      selected = if (length(others)) others[which.min(n_levels)])
  })

  # Stage 2: the summary. Checks on the chosen columns are here, shared by all outputs.
  checked <- reactive({
    df <- data()
    validate(need(length(num_cols()) > 0,
                  "This file has no numeric columns, so there is nothing to summarise."))
    req(input$value_col, input$group_col)  # filled by the server after upload
    validate(
      need(input$value_col %in% names(df) && input$group_col %in% names(df),
           "Updating column choices..."),
      need(input$value_col != input$group_col,
           "Pick a grouping column that is different from the numeric column."),
      need(is.numeric(df[[input$value_col]]),
           "The chosen value column is not numeric.")
    )
    df
  })

  summ <- reactive(group_summary(checked(), input$value_col, input$group_col))

  plt <- reactive({
    df <- checked()
    df$.group <- as.character(df[[input$group_col]])  # helper column for the plot only
    df$.group[is.na(df$.group)] <- "(missing group)"
    df <- df[!is.na(df[[input$value_col]]), , drop = FALSE]
    validate(need(nrow(df) > 0, "The numeric column has only missing values."))
    ggplot(df, aes(.group, .data[[input$value_col]])) +
      geom_boxplot(fill = "#9ecae1") +
      labs(x = input$group_col, y = input$value_col) +
      theme_minimal(base_size = 14)
  })

  output$summary_table <- renderTable(summ(), digits = 2, na = "NA")
  output$boxplot <- renderPlot(plt())

  # Report: knitr + markdown, which needs no pandoc (works outside RStudio too).
  output$report <- downloadHandler(
    filename = function() paste0("group-summary-", Sys.Date(), ".html"),
    content = function(file) {
      # Read reactives here; the Rmd only sees the values passed in `params`.
      params <- list(file_name = input$file$name, value_col = input$value_col,
                     group_col = input$group_col, table = summ(), plot = plt())
      dir <- tempfile(); dir.create(dir)  # per-download folder: users don't clash
      file.copy("report.Rmd", file.path(dir, "report.Rmd"))
      owd <- setwd(dir); on.exit(setwd(owd), add = TRUE)  # knitr writes figure/ here
      env <- new.env(parent = globalenv())  # report objects stay out of the app session
      env$params <- params
      knitr::knit("report.Rmd", "report.md", envir = env, quiet = TRUE)
      markdown::mark_html("report.md", output = "report.html",
                          options = "+embed_resources")  # plot embedded as base64
      file.copy("report.html", file, overwrite = TRUE)
    }
  )
}

shinyApp(ui, server)
