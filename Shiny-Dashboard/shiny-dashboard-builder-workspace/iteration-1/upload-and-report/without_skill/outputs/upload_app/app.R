# Upload a CSV, summarise a numeric column by group, download an HTML report.
# Report is built without pandoc: knitr::kable for the table, base64 PNG for the plot.
library(shiny)
library(bslib)
library(ggplot2)
library(DT)

summarise_by_group <- function(df, value, group) {
  g <- addNA(factor(df[[group]]), ifany = TRUE)   # keep rows whose group is missing
  x <- df[[value]]
  out <- do.call(rbind, lapply(split(x, g), function(v) data.frame(
    n = length(v),
    n_missing = sum(is.na(v)),
    mean = if (all(is.na(v))) NA else mean(v, na.rm = TRUE),
    sd = if (sum(!is.na(v)) < 2) NA else sd(v, na.rm = TRUE)
  )))
  levs <- levels(g); levs[is.na(levs)] <- "(missing)"
  cbind(group = levs, out, row.names = NULL) |>
    transform(mean = round(mean, 2), sd = round(sd, 2))
}

make_boxplot <- function(df, value, group) {
  d <- df[!is.na(df[[value]]), , drop = FALSE]
  d[[group]] <- factor(d[[group]])
  ggplot(d, aes(.data[[group]], .data[[value]])) +
    geom_boxplot(fill = "#9ecae1", outlier.shape = NA) +
    geom_jitter(width = 0.15, alpha = 0.3, size = 1) +
    labs(x = group, y = value, title = paste(value, "by", group)) +
    theme_minimal(base_size = 13)
}

build_report <- function(file, tbl, p, value, group, source_name) {
  png_file <- tempfile(fileext = ".png")
  ggsave(png_file, p, width = 7, height = 4.5, dpi = 120)
  html <- c(
    "<!doctype html><html><head><meta charset='utf-8'><title>Summary report</title>",
    "<style>body{font-family:sans-serif;max-width:800px;margin:2em auto;}",
    "table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:4px 10px;text-align:right}</style></head><body>",
    sprintf("<h1>%s by %s</h1>", htmltools::htmlEscape(value), htmltools::htmlEscape(group)),
    sprintf("<p>Data file: %s<br>Generated: %s</p>",
            htmltools::htmlEscape(source_name), format(Sys.time(), "%Y-%m-%d %H:%M")),
    "<h2>Summary statistics</h2>",
    as.character(knitr::kable(tbl, format = "html")),
    "<p><small>n = rows in group; n_missing = rows with missing values (excluded from mean, sd and plot).</small></p>",
    "<h2>Boxplot</h2>",
    sprintf("<img src='%s' style='max-width:100%%'>", knitr::image_uri(png_file)),
    "</body></html>"
  )
  writeLines(html, file)
}

ui <- page_sidebar(
  title = "Group summary & report",
  sidebar = sidebar(
    fileInput("file", "Upload CSV", accept = ".csv"),
    selectInput("value", "Numeric column", choices = NULL),
    selectInput("group", "Grouping column", choices = NULL),
    downloadButton("report", "Download HTML report")
  ),
  card(card_header("Summary per group"), DTOutput("stats")),
  card(card_header("Boxplot"), plotOutput("box"))
)

server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    df <- tryCatch(read.csv(input$file$datapath, na.strings = c("", "NA")),
                   error = function(e) NULL)
    validate(need(!is.null(df) && nrow(df) > 0, "Could not read this file as a CSV."))
    df
  })

  observeEvent(data(), {
    df <- data()
    nums <- names(df)[vapply(df, is.numeric, logical(1))]
    validate(need(length(nums) > 0, "No numeric columns found."))
    updateSelectInput(session, "value", choices = nums)
    # Any column can group; prefer one that isn't the chosen numeric column.
    updateSelectInput(session, "group", choices = names(df),
                      selected = setdiff(names(df), nums[1])[1] %||% names(df)[1])
  })

  ready <- reactive({
    df <- data()
    req(input$value %in% names(df), input$group %in% names(df))
    validate(need(input$value != input$group, "Pick different numeric and grouping columns."),
             need(is.numeric(df[[input$value]]), ""))
    df
  })

  stats <- reactive(summarise_by_group(ready(), input$value, input$group))
  plot_obj <- reactive(make_boxplot(ready(), input$value, input$group))

  output$stats <- renderDT(datatable(stats(), rownames = FALSE, options = list(dom = "t", pageLength = 100)))
  output$box <- renderPlot(plot_obj())

  output$report <- downloadHandler(
    filename = function() paste0("report_", input$value, "_by_", input$group, ".html"),
    content = function(file) build_report(file, stats(), plot_obj(), input$value, input$group, input$file$name)
  )
}

shinyApp(ui, server)
