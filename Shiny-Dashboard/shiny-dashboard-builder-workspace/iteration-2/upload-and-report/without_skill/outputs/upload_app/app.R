library(shiny)
library(ggplot2)

# Summary per group: n (non-missing), missing, mean, sd. Missing groups become "(missing)".
group_summary <- function(df, value, group) {
  g <- addNA(factor(df[[group]]), ifany = TRUE)
  levels(g)[is.na(levels(g))] <- "(missing)"
  x <- df[[value]]
  out <- do.call(rbind, lapply(split(x, g), function(v) data.frame(
    n = sum(!is.na(v)), missing = sum(is.na(v)),
    mean = round(mean(v, na.rm = TRUE), 2), sd = round(sd(v, na.rm = TRUE), 2)
  )))
  cbind(group = rownames(out), out, row.names = NULL)
}

make_plot <- function(df, value, group) {
  df <- df[!is.na(df[[value]]), , drop = FALSE]
  df[[group]] <- factor(df[[group]])
  ggplot(df, aes(.data[[group]], .data[[value]])) +
    geom_boxplot(fill = "lightblue", outlier.shape = NA) +
    geom_jitter(width = 0.15, alpha = 0.4, size = 1) +
    labs(x = group, y = value) +
    theme_minimal(base_size = 14)
}

ui <- fluidPage(
  titlePanel("Group summary and boxplot"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload a CSV file", accept = ".csv"),
      selectInput("value", "Numeric column", choices = NULL),
      selectInput("group", "Grouping column", choices = NULL),
      downloadButton("report", "Download HTML report")
    ),
    mainPanel(
      h4("Summary statistics per group"),
      tableOutput("summary"),
      plotOutput("boxplot")
    )
  )
)

server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    df <- tryCatch(read.csv(input$file$datapath, na.strings = c("", "NA")),
                   error = function(e) NULL)
    validate(need(!is.null(df) && nrow(df) > 0, "Could not read that file as a CSV."))
    df
  })

  observeEvent(data(), {
    df <- data()
    nums <- names(df)[vapply(df, is.numeric, logical(1))]
    if (length(nums) == 0) {
      showNotification("The file has no numeric columns.", type = "error")
      return()
    }
    updateSelectInput(session, "value", choices = nums)
    updateSelectInput(session, "group", choices = names(df),
                      selected = setdiff(names(df), nums[1])[1])
  })

  ok <- reactive({
    df <- data()
    req(input$value %in% names(df), input$group %in% names(df))
    validate(need(input$value != input$group, "Pick different columns for value and group."))
    df
  })

  stats <- reactive(group_summary(ok(), input$value, input$group))
  plot_obj <- reactive(make_plot(ok(), input$value, input$group))

  output$summary <- renderTable(stats(), na = "-")
  output$boxplot <- renderPlot(plot_obj())

  # Report is built as plain HTML (no pandoc needed): kable table + base64-embedded PNG.
  output$report <- downloadHandler(
    filename = function() paste0("report_", input$value, "_by_", input$group, ".html"),
    content = function(file) {
      png <- tempfile(fileext = ".png")
      ggsave(png, plot_obj(), width = 7, height = 4.5, dpi = 100)
      html <- paste0(
        "<!doctype html><html><head><meta charset='utf-8'><title>Group summary report</title>",
        "<style>body{font-family:sans-serif;max-width:800px;margin:2em auto}",
        "table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:4px 10px}</style></head><body>",
        "<h1>Group summary report</h1>",
        "<p>File: ", htmltools::htmlEscape(input$file$name), "<br>Value: <b>",
        htmltools::htmlEscape(input$value), "</b>, grouped by <b>",
        htmltools::htmlEscape(input$group), "</b><br>Generated: ", format(Sys.time()), "</p>",
        "<h2>Summary statistics</h2>",
        paste(knitr::kable(stats(), format = "html"), collapse = "\n"),
        "<p><i>n = non-missing values; missing = NA values excluded from mean and sd.</i></p>",
        "<h2>Boxplot</h2><img style='max-width:100%' src='", knitr::image_uri(png), "'>",
        "</body></html>"
      )
      writeLines(html, file)
    }
  )
}

shinyApp(ui, server)
