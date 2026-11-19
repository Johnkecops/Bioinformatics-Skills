# Upload a CSV -> pick a numeric column and a grouping column -> per-group
# summary table + boxplot -> download both as a short HTML report.
#
# Reactive graph (each stage reruns only when its own inputs change):
#   input$file -> data() -> [dropdowns updated] -> summary_tbl(), box_plot()
#                                               -> table, plot, report download
library(shiny)
library(bslib)
library(ggplot2)

options(shiny.maxRequestSize = 20 * 1024^2)  # default upload limit is 5 MB
app_dir <- getwd()  # runApp() starts in the app folder; the report template lives here

# ---- Pure helpers (outside server, so they can be tested in the console) ----

# Missing group labels become an explicit "(missing)" group instead of vanishing.
as_group <- function(x) {
  x <- as.character(x)
  x[is.na(x) | x == ""] <- "(missing)"
  factor(x)
}

# One row per group: n = non-missing values, missing = NA values in that group.
summarise_groups <- function(df, value, group) {
  g <- as_group(df[[group]])
  rows <- lapply(split(df[[value]], g), function(v) data.frame(
    n       = sum(!is.na(v)),
    missing = sum(is.na(v)),
    mean    = if (any(!is.na(v))) mean(v, na.rm = TRUE) else NA_real_,
    sd      = if (sum(!is.na(v)) > 1) sd(v, na.rm = TRUE) else NA_real_
  ))
  out <- cbind(group = names(rows), do.call(rbind, rows))
  names(out)[1] <- group
  rownames(out) <- NULL
  out
}

make_boxplot <- function(df, value, group) {
  df$.group <- as_group(df[[group]])
  df <- df[!is.na(df[[value]]), , drop = FALSE]  # drop NAs here, not via a ggplot warning
  ggplot(df, aes(.group, .data[[value]])) +
    geom_boxplot(fill = "#cfe2f3", outlier.shape = NA) +
    geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
    labs(x = group, y = value) +
    theme_minimal(base_size = 14)
}

# Knit report_template.Rmd to one self-contained HTML file. knitr + markdown
# need no pandoc, so this works from plain R as well as RStudio.
render_report <- function(file, params) {
  dir <- tempfile(); dir.create(dir)          # per-download dir: no clashes between users
  owd <- setwd(dir); on.exit(setwd(owd))      # knitr writes figure files here
  env <- new.env(parent = globalenv())        # report objects stay out of the app
  env$params <- params
  md <- knitr::knit(file.path(app_dir, "report_template.Rmd"), envir = env, quiet = TRUE)
  # Write next to the figure files first: images are embedded (base64) relative
  # to the output's folder, so writing straight to `file` would lose the plot.
  markdown::mark_html(md, output = "report.html", options = "+embed_resources")
  file.copy("report.html", file, overwrite = TRUE)
}

# ---- UI ----

ui <- page_sidebar(
  title = "Group summary from an uploaded CSV",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    fileInput("file", "Upload a CSV file", accept = c(".csv", "text/csv")),
    # Choices are empty until a file is uploaded; the server fills them in.
    selectInput("value_col", "Numeric column", choices = NULL),
    selectInput("group_col", "Grouping column", choices = NULL),
    downloadButton("download_report", "Download HTML report", class = "btn-primary")
  ),
  card(card_header("Summary per group"), tableOutput("summary")),
  card(card_header("Boxplot"), plotOutput("boxplot"))
)

# ---- Server ----

server <- function(input, output, session) {

  # One reactive reads the file; everything else reads data().
  data <- reactive({
    req(input$file)
    validate(need(tolower(tools::file_ext(input$file$name)) == "csv",
                  "Please upload a .csv file."))
    df <- tryCatch(
      read.csv(input$file$datapath, na.strings = c("NA", ""), check.names = FALSE),
      error = function(e) stop(safeError(e))  # show parse errors to the student
    )
    validate(need(nrow(df) > 0, "The file has no rows."))
    df
  })

  # Refill both dropdowns whenever a new file arrives (side effect -> observer).
  observe({
    df <- data()
    num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    # Default grouping column: the one with the fewest distinct values
    # (e.g. Diet rather than weight); students can still pick any column.
    n_levels <- vapply(df, function(x) length(unique(x)), integer(1))
    updateSelectInput(session, "value_col", choices = num_cols, selected = num_cols[1])
    updateSelectInput(session, "group_col", choices = names(df),
                      selected = names(df)[which.min(n_levels)])
  }) |> bindEvent(data())

  # Shared checks live here once, so the table, plot and report all show the
  # same readable message instead of an R error.
  checked <- reactive({
    df <- data()
    validate(need(input$value_col %in% names(df) && is.numeric(df[[input$value_col]]),
                  "The file needs at least one numeric column. Pick it under 'Numeric column'."),
             need(input$group_col %in% names(df), "Pick a grouping column."),
             need(input$value_col != input$group_col,
                  "Pick different columns for the value and the grouping."))
    df
  })

  summary_tbl <- reactive(summarise_groups(checked(), input$value_col, input$group_col))
  box_plot    <- reactive(make_boxplot(checked(), input$value_col, input$group_col))

  output$summary <- renderTable(summary_tbl(), digits = 2, na = "-",
                                striped = TRUE, width = "100%")
  output$boxplot <- renderPlot(box_plot())

  output$download_report <- downloadHandler(
    filename = function() {
      paste0(tools::file_path_sans_ext(input$file$name), "-", input$value_col,
             "-by-", input$group_col, "-report.html")
    },
    content = function(file) {
      render_report(file, list(
        file_name = input$file$name,
        value     = input$value_col,
        group     = input$group_col,
        n_rows    = nrow(checked()),
        n_missing = sum(is.na(checked()[[input$value_col]])),
        table     = summary_tbl(),
        plot      = box_plot()
      ))
    }
  )
}

shinyApp(ui, server)
