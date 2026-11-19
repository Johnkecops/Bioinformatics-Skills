# Outputs

Patterns for every render/output pair in the `outputs` category: text, tables, plots, caching, images, HTML/markdown/MathJax, upload, download, reports, htmlwidgets, errors, clearing outputs.

Snippets use modern idiom (shiny >= 1.7, bslib, `DTOutput`/`renderDT`, `bindCache`, native `|>`). Examples are 2013-2020 code; where they differ, follow the snippet.

## Contents
- [Render/output pairs](#renderoutput-pairs)
- [Text and printed output](#text-and-printed-output)
- [Static tables: renderTable](#static-tables-rendertable)
- [Interactive tables: DT](#interactive-tables-dt)
- [Plots and renderPlot arguments](#plots-and-renderplot-arguments)
- [Plot caching with bindCache](#plot-caching-with-bindcache)
- [Images: renderImage](#images-renderimage)
- [Static HTML, markdown and MathJax](#static-html-markdown-and-mathjax)
- [File upload](#file-upload)
- [File download (data and plots)](#file-download-data-and-plots)
- [Upload -> summarise -> download (full app)](#upload---summarise---download-full-app)
- [Reports: R Markdown download](#reports-r-markdown-download)
- [Reports: HTML download without pandoc](#reports-html-download-without-pandoc)
- [Reports: embed knitr output in the page](#reports-embed-knitr-output-in-the-page)
- [htmlwidgets](#htmlwidgets)
- [Archived chart packages -> plotly](#archived-chart-packages---plotly)
- [Error sanitization](#error-sanitization)
- [Clearing an output (NULL)](#clearing-an-output-null)

## Render/output pairs

| render (server) | output (UI) | typical use | source |
|---|---|---|---|
| `renderText` | `textOutput` | caption, single value, inline text | 002, 004, 110 |
| `renderPrint` | `verbatimTextOutput` | `summary()`, model print, `str()` | 002, 022 |
| `renderTable` | `tableOutput` | small static data frame | 002, 009, 109 |
| `DT::renderDT` | `DT::DTOutput` | searchable/sortable/paged table | 012, 018, 030, 145 |
| `renderPlot` (+ `bindCache`) | `plotOutput` | base/ggplot2 graphics | 004, 082, 131, 136, 137, 161 |
| `renderImage` | `imageOutput` | pre-made or generated PNG/JPEG | 047 |
| `renderUI` | `uiOutput` / `htmlOutput` | generated HTML, MathJax, knitr fragment | 019, 020, 109 |
| `includeHTML/Markdown/Text` | (static, in UI) | help pages, about text | 048 |
| `downloadHandler` | `downloadButton` | CSV/TSV/PNG/report download | 010, 039, 016, 112 |
| `renderLeaflet` | `leafletOutput` | maps | 178, 179, 180 |
| `renderPlotly` | `plotlyOutput` | interactive charts; replaces 054, 182 | 054, 182 |
| `renderHighchart` | `highchartOutput` | highcharter charts | 118 |
| `renderSankeyNetwork` | `sankeyNetworkOutput` | networkD3 sankey/force graphs | 150 |
| (input) `fileInput` | `input$<id>` data frame | CSV/TSV upload | 009, 066 |

## Text and printed output

`renderText` pastes a character vector into HTML; `renderPrint` captures console output into a `<pre>`. Put shared data in one `reactive()` and reuse it.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "Text outputs",
  sidebar = sidebar(
    selectInput("dataset", "Dataset", c("rock", "pressure", "cars")),
    numericInput("obs", "Rows", 10, min = 1)
  ),
  h3(textOutput("caption")),
  verbatimTextOutput("summary"),
  tableOutput("view")
)

server <- function(input, output, session) {
  data <- reactive(get(input$dataset, "package:datasets"))
  output$caption <- renderText(paste("Summary of", input$dataset))
  output$summary <- renderPrint(summary(data()))
  output$view <- renderTable(head(data(), input$obs))
}

shinyApp(ui, server)
```

Source: `002-text`, `004-mpg`, `022-unicode-chinese`

Pitfalls:
- `textOutput(..., inline = TRUE)` for text inside a sentence (`span` instead of `div`).
- `renderText` escapes HTML. To emit markup use `renderUI(HTML(...))` + `uiOutput` (109 pairs `renderText` with `htmlOutput`, which also renders raw HTML; never do that with user-supplied text).
- Non-ASCII (022): save files as UTF-8; labels, choices and even output IDs may be non-ASCII. For CJK text in plots, install `ragg` (shiny uses it automatically) or use `showtext`; 022's font-download hack is unnecessary today.

## Static tables: renderTable

`renderTable` makes an HTML table via xtable. Formatting arguments go to `renderTable`, not the UI; each argument can be a value or a function (109 passes functions so they react to inputs).

```r
output$view <- renderTable(
  head(data(), input$obs),
  striped = TRUE, hover = TRUE, bordered = TRUE,
  spacing = "s",          # "xs", "s", "m", "l"
  width = "100%",
  align = "l",            # one letter for all, or one per column ("lcr?")
  digits = 2,
  na = "-",
  rownames = FALSE
)
```

Source: `109-render-table`, `002-text`, `010-download`

Pitfalls:
- Not for more than a few hundred rows; use DT.
- Row names are dropped by default; set `rownames = TRUE` for matrices or named rows.

## Interactive tables: DT

`DT::datatable()` inside `renderDT()`; DataTables options go in `options = list(...)`. Server-side processing (default `server = TRUE`) handles large tables.

```r
library(DT)

ui <- page_fillable(
  selectInput("cyl", "Cylinders", c("All", sort(unique(mtcars$cyl)))),
  DTOutput("tbl")
)

server <- function(input, output, session) {
  filtered <- reactive({
    if (input$cyl == "All") mtcars else mtcars[mtcars$cyl == input$cyl, ]
  })
  output$tbl <- renderDT(
    datatable(
      filtered(),
      filter = "top",
      options = list(
        pageLength = 15,
        lengthMenu = list(c(5, 15, -1), c("5", "15", "All")),
        rowCallback = JS(
          "function(row, data) {",
          "  if (parseFloat(data[1]) >= 25) $('td:eq(1)', row).css('font-weight', 'bold');",
          "}"
        )
      )
    ) |> formatRound(c("wt", "qsec"), 2)
  )
}
```

Update values without re-rendering (keeps page, sort, search) via a proxy:

```r
server <- function(input, output, session) {
  x <- reactiveVal(0L)
  output$tbl <- renderDT(
    datatable(data.frame(value = isolate(x())), rownames = FALSE,
              options = list(dom = "t", ordering = FALSE))
  )
  observeEvent(input$inc, x(x() + 1L))
  observeEvent(x(), replaceData(dataTableProxy("tbl"), data.frame(value = x()),
                                rownames = FALSE))
}
```

Useful options: `paging = FALSE`, `searching = FALSE`, `orderClasses = TRUE`, `dom = "t"` (table only). Selection: `input$<id>_rows_selected`; filtered rows: `input$<id>_rows_all`.

Source: `012-datatables`, `018-datatable-options`, `030-basic-datatable`, `145-dt-replacedata`

Pitfalls:
- Use `DT::DTOutput`/`DT::renderDT`; `shiny::renderDataTable` is deprecated. Namespace-qualify or load DT after shiny.
- `isolate()` the data in the initial render when a proxy updates it, else the table re-renders on every change (145).
- `replaceData()` needs the same `rownames` setting as the original `datatable()`.
- Selecting columns with a checkbox (012): `df[, input$cols, drop = FALSE]` so one column stays a data frame.
- Large data with `server = FALSE` ships everything to the browser.

## Plots and renderPlot arguments

`renderPlot` draws base or ggplot2 graphics at the browser's size. Extra arguments: `width`, `height` (pixels or function), `res`, `bg`, `alt`.

```r
output$plot <- renderPlot(
  {
    boxplot(reformulate(input$var, "mpg"), data = mtcars,
            outline = input$outliers, col = "#75AADB")
  },
  res = 96,
  bg = "transparent",      # page background shows through (131)
  alt = "Boxplot of mpg by selected variable"
)
```

Stable random layout plus memoised heavy prep (082, word cloud):

```r
term_freq <- memoise::memoise(function(book) {
  # expensive text processing, cached per book for the whole app
  sort(table(strsplit(tolower(readLines(book)), "\\W+")[[1]]), decreasing = TRUE)
})
wordcloud_rep <- repeatable(wordcloud::wordcloud)  # same seed each redraw

server <- function(input, output, session) {
  terms <- reactive(term_freq(input$book)) |> bindEvent(input$update, ignoreNULL = FALSE)
  output$cloud <- renderPlot({
    v <- terms()
    wordcloud_rep(names(v), v, min.freq = input$freq, max.words = input$max)
  })
}
```

Source: `004-mpg`, `131-renderplot-args`, `082-word-cloud`, `161-discrete-limits`

Pitfalls:
- `bg = "transparent"` needs `par(bg = NA)` for base graphics or `theme(plot.background = element_blank())` for ggplot2.
- Use `reformulate()` or `as.formula(paste())` to build a formula from an input; never `eval(parse())` user text.
- `bindEvent()` replaces 082's `input$update; isolate({...})` idiom.
- 161 is a regression test that `brushedPoints()` respects facets and discrete `scale_x_discrete(limits = )`; see the plot-interaction reference for brushing.
- `wordcloud`/`tm` are not installed here; install before using 082's pattern.

## Plot caching with bindCache

`bindCache(...)` on a `renderPlot` caches the PNG keyed by the listed values plus the plot size. It replaces `renderCachedPlot(cacheKeyExpr = ...)`.

```r
library(shiny)

dataset <- reactiveVal(data.frame(x = rnorm(400), y = rnorm(400)))

ui <- fluidPage(
  sliderInput("n", "Points", 50, 400, 100, step = 50),
  actionButton("newdata", "New data"),
  plotOutput("plot")
)

server <- function(input, output, session) {
  observeEvent(input$newdata, dataset(data.frame(x = rnorm(400), y = rnorm(400))))
  output$plot <- renderPlot({
    Sys.sleep(2)  # stand-in for slow work
    d <- dataset()
    i <- seq_len(input$n)
    plot(d$x[i], d$y[i], xlim = range(d$x), ylim = range(d$y))
  }) |>
    bindCache(input$n, dataset())
}

shinyApp(ui, server)
```

Source: `136-plot-cache` (key = `input$n`), `137-plot-cache-key` (key = input + data)

Pitfalls:
- Every value the plot reads must be in the key, or users get stale plots. Include the data (137), not just inputs.
- Hashing a large data frame on every call costs time; key on a cheap proxy instead (file path + mtime, a version counter `reactiveVal`).
- Default cache is app-wide (shared across sessions, in memory). For multi-process deploys: `bindCache(..., cache = cachem::cache_disk("./cache"))`.
- `bindCache` also works on `reactive()` and other render functions (DT, plotly).

## Images: renderImage

Return a list with `src`, `contentType`, `width`, `height`, `alt`. Read the output's size from `session$clientData`.

```r
output$image1 <- renderImage({
  w <- session$clientData$output_image1_width
  h <- session$clientData$output_image1_height
  outfile <- tempfile(fileext = ".png")
  png(outfile, width = w, height = h)
  hist(rnorm(input$n))
  dev.off()
  list(src = outfile, contentType = "image/png", width = w, height = h,
       alt = "Histogram")
}, deleteFile = TRUE)

output$image2 <- renderImage({
  req(input$picture)
  list(src = file.path("images", paste0(input$picture, ".png")),
       contentType = "image/png", alt = input$picture)
}, deleteFile = FALSE)
```

Source: `047-image-output`

Pitfalls:
- Always pass `deleteFile` explicitly: `TRUE` for temp files, `FALSE` for files shipped with the app (or they get deleted).
- Static images that never change: put them in `www/` and use `tags$img(src = "x.png")`; no server code needed.
- 047 uses `filetype =` for the JPEG; the correct key is `contentType`.

## Static HTML, markdown and MathJax

Static files go in the UI with `includeHTML()`, `includeMarkdown()`, `includeText()`. MathJax needs `withMathJax()` once in the UI and again around dynamically rendered math.

```r
ui <- page_fluid(
  withMathJax(),
  layout_columns(
    card(pre(includeText("include.txt"))),
    card(includeHTML("include.html")),     # fragment, not a full <html> page
    card(includeMarkdown("include.md"))
  ),
  p("Inline \\(\\sqrt{2}\\) and display $$\\frac{1}{1+e^{-x}}$$"),
  uiOutput("prob")
)

server <- function(input, output, session) {
  output$prob <- renderUI({
    invalidateLater(5000)
    x <- round(rcauchy(1), 3)
    withMathJax(sprintf("$$P(X \\leq %.3f) = %.3f$$", x, pcauchy(x)))
  })
}
```

Source: `048-including-html-text-and-markdown-files`, `019-mathjax`

Pitfalls:
- Double the backslashes in R strings (`"\\alpha"`), or use raw strings `r"(\alpha)"`.
- `includeMarkdown` needs the `markdown` package.
- `includeHTML` of a full document (with `<html>`/`<head>`) breaks the page; include fragments only, or use `tags$iframe`.
- Returning `NULL` from `renderUI` hides the block (019 ex5).

## File upload

`fileInput` gives a data frame: `name`, `size`, `type`, `datapath`. Read `datapath` (server temp copy), not `name`.

```r
ui <- page_sidebar(
  sidebar = sidebar(
    fileInput("file", "CSV/TSV", accept = c(".csv", ".tsv", "text/csv")),
    checkboxInput("header", "Header", TRUE)
  ),
  tableOutput("contents")
)

server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    ext <- tolower(tools::file_ext(input$file$name))
    validate(need(ext %in% c("csv", "tsv"), "Please upload a .csv or .tsv file"))
    tryCatch(
      read.delim(input$file$datapath, header = input$header,
                 sep = if (ext == "tsv") "\t" else ","),
      error = function(e) stop(safeError(e))
    )
  })
  output$contents <- renderTable(head(data()))
}
```

Source: `009-upload`, `066-upload-file` (also `073-widget-file` in inputs)

Pitfalls:
- `req(input$file)`: it is `NULL` until a file is chosen.
- `accept` only filters the browser dialog; validate the extension/content on the server.
- Default size limit is 5 MB: `options(shiny.maxRequestSize = 50 * 1024^2)` at top level (066).
- `multiple = TRUE` gives one row per file; loop over `input$file$datapath`.
- Wrap the reader in `tryCatch(..., error = \(e) stop(safeError(e)))` so parse errors reach the user under sanitized errors.
- Excel: `readxl::read_excel(input$file$datapath)`.

## File download (data and plots)

`downloadHandler(filename, content)`: `filename` is a function (so it can read inputs); `content(file)` must write to the path `file`.

```r
ui <- page_sidebar(
  sidebar = sidebar(
    selectInput("dataset", "Dataset", c("rock", "pressure", "cars")),
    radioButtons("type", "Format", c("csv", "tsv"), inline = TRUE),
    downloadButton("dl_data", "Data"),
    downloadButton("dl_plot", "Plot (PNG)")
  ),
  plotOutput("plot")
)

server <- function(input, output, session) {
  data <- reactive(get(input$dataset, "package:datasets"))
  make_plot <- function() plot(data())
  output$plot <- renderPlot(make_plot())

  output$dl_data <- downloadHandler(
    filename = function() paste0(input$dataset, "-", Sys.Date(), ".", input$type),
    content = function(file) {
      write.table(data(), file, sep = if (input$type == "tsv") "\t" else ",",
                  row.names = FALSE)
    }
  )
  output$dl_plot <- downloadHandler(
    filename = function() paste0(input$dataset, ".png"),
    content = function(file) {
      png(file, width = 1600, height = 1200, res = 200)
      on.exit(dev.off())
      make_plot()
    }
  )
}
```

ggplot2: `ggsave(file, plot = p(), width = 8, height = 6, dpi = 300)` where `p` is a reactive returning the ggplot object (call `print()` if writing via `png()`).

Source: `010-download`, `039-download-file`

Pitfalls:
- Write to `file`, never to `getwd()`; return value of `content` is ignored.
- `filename` as a string is fine only if it never changes.
- Downloads do not work in the RStudio Viewer pane on some versions; test in a browser.
- `downloadButton` can't be triggered by `actionButton`; style it instead (`class = "btn-primary"`).
- Excel: `writexl::write_xlsx(data(), file)`.

## Upload -> summarise -> download (full app)

Verified end-to-end with `shiny::testServer()`.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "Upload, summarise, download",
  sidebar = sidebar(
    fileInput("file", "CSV or TSV", accept = c(".csv", ".tsv")),
    downloadButton("dl", "Download summary")
  ),
  card(card_header("Numeric summary"), tableOutput("summary"))
)

server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    ext <- tolower(tools::file_ext(input$file$name))
    validate(need(ext %in% c("csv", "tsv"), "Upload a .csv or .tsv file"))
    tryCatch(
      read.delim(input$file$datapath, sep = if (ext == "tsv") "\t" else ","),
      error = function(e) stop(safeError(e))
    )
  })
  summ <- reactive({
    num <- Filter(is.numeric, data())
    validate(need(ncol(num) > 0, "No numeric columns found"))
    data.frame(
      variable = names(num),
      n = vapply(num, \(v) sum(!is.na(v)), integer(1)),
      mean = vapply(num, mean, numeric(1), na.rm = TRUE),
      sd = vapply(num, sd, numeric(1), na.rm = TRUE),
      row.names = NULL
    )
  })
  output$summary <- renderTable(summ(), digits = 3)
  output$dl <- downloadHandler(
    filename = function() {
      paste0(tools::file_path_sans_ext(input$file$name), "-summary.csv")
    },
    content = function(file) write.csv(summ(), file, row.names = FALSE)
  )
}

shinyApp(ui, server)
```

Test pattern (no browser):

```r
shiny::testServer(server, {
  csv <- tempfile(fileext = ".csv")
  write.csv(mtcars, csv, row.names = FALSE)
  session$setInputs(file = data.frame(name = "mtcars.csv", size = file.size(csv),
                                      type = "text/csv", datapath = csv))
  stopifnot(nrow(summ()) == ncol(mtcars))
  out <- read.csv(output$dl)   # output$<download id> is the written file's path
  stopifnot(identical(out$variable, names(mtcars)))
})
```

## Reports: R Markdown download

Parameterised `.Rmd` rendered inside `downloadHandler`. Pass values via `params`, never by letting the Rmd read `input` (016 does; that couples the report to the session).

`report.Rmd`:

````markdown
---
title: "Regression report"
output: html_document
params:
  xvar: wt
  data: NULL
---

```{r}
fit <- lm(reformulate(params$xvar, "mpg"), data = params$data)
summary(fit)
plot(reformulate(params$xvar, "mpg"), data = params$data, pch = 19)
abline(fit, col = "red")
```
````

Server:

```r
has_latex <- nzchar(Sys.which("pdflatex")) || tinytex::is_tinytex()
formats <- c("HTML", if (has_latex) "PDF", "Word")

ui <- page_sidebar(
  sidebar = sidebar(
    selectInput("x", "Predictor", names(mtcars)[-1]),
    radioButtons("format", "Format", formats, inline = TRUE),
    downloadButton("report", "Generate report")
  ),
  plotOutput("reg")
)

server <- function(input, output, session) {
  output$reg <- renderPlot(plot(reformulate(input$x, "mpg"), data = mtcars))
  output$report <- downloadHandler(
    filename = function() {
      paste0("report.", switch(input$format, HTML = "html", PDF = "pdf", Word = "docx"))
    },
    content = function(file) {
      dir <- tempfile(); dir.create(dir)               # per-download dir: no clashes
      tmp <- file.path(dir, "report.Rmd")
      file.copy("report.Rmd", tmp, overwrite = TRUE)  # app dir may be read-only
      id <- showNotification("Rendering report...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      rmarkdown::render(
        tmp,
        output_format = switch(input$format, HTML = "html_document",
                               PDF = "pdf_document", Word = "word_document"),
        output_file = file,
        params = list(xvar = input$x, data = mtcars),
        envir = new.env(parent = globalenv())
      )
    }
  )
}
```

Source: `112-generate-report` (params pattern), `016-knitr-pdf` (format choice; dated `setwd` + `input` inside Rmd)

Pitfalls:
- Copy the template to a temp dir: knitting writes intermediates next to the Rmd, and deployed app dirs are often read-only.
- `envir = new.env(parent = globalenv())` isolates report objects from the app session.
- PDF needs LaTeX (`tinytex::install_tinytex()`); offer the choice only when present, keep HTML as the fallback.
- All formats need pandoc. RStudio bundles it, plain `Rscript`/servers may not: check `rmarkdown::pandoc_available()`.
- Long renders block the R process for every user of that process; for heavy reports see the async reference (`ExtendedTask`).
- Quarto equivalent: `quarto::quarto_render(tmp, execute_params = list(...))`.

## Reports: HTML download without pandoc

Same download, but `knitr::knit` + `markdown::mark_html` instead of `rmarkdown::render`. Works with plain `Rscript` and on servers without pandoc; output is one self-contained HTML file. HTML only (no PDF/Word).

`report.Rmd` (YAML `title:` becomes the page `<h1>`; `params` is injected, not declared):

````markdown
---
title: "Group summary"
---

```{r, echo = FALSE}
knitr::kable(params$table, digits = 2)
```

```{r, echo = FALSE, fig.width = 6, fig.height = 4}
print(params$plot)
```
````

Server:

```r
output$report <- downloadHandler(
  filename = function() paste0("report-", Sys.Date(), ".html"),
  content = function(file) {
    dir <- tempfile(); dir.create(dir)
    file.copy("report.Rmd", file.path(dir, "report.Rmd"))
    owd <- setwd(dir); on.exit(setwd(owd), add = TRUE)  # knitr writes figure/ here
    env <- new.env(parent = globalenv())
    env$params <- list(table = summ(), plot = plt())    # reactives read here, values passed in
    knitr::knit("report.Rmd", "report.md", envir = env, quiet = TRUE)
    markdown::mark_html("report.md", output = "report.html",
                        options = "+embed_resources")    # plots become base64
    file.copy("report.html", file, overwrite = TRUE)
  }
)
```

Source: pattern derived from `020-knit-html` + `112-generate-report`; tested with `testServer()` (HTML contains the table and a `data:image/png;base64` plot).

Pitfalls:
- Write the HTML **inside the knit directory**, then copy to `file`. `mark_html(..., output = file)` resolves figure paths relative to `file`'s folder, so plots silently disappear.
- Don't repeat the YAML title as a `# heading` in the body; it shows twice.
- Markdown hard line breaks (two trailing spaces) are fragile; use a list or separate paragraphs for header lines.
- Read reactives (`summ()`, `plt()`) in `content`, not inside the Rmd; the Rmd sees only `params`.

## Reports: embed knitr output in the page

Show a knitted report inside the app instead of downloading it. `knitr::knit` + `markdown::mark_html` needs no pandoc and embeds plots as base64.

```r
ui <- page_sidebar(
  sidebar = sidebar(withMathJax(), selectInput("x", "Predictor", names(mtcars)[-1])),
  uiOutput("report")
)

server <- function(input, output, session) {
  output$report <- renderUI({
    dir <- tempfile(); dir.create(dir)
    owd <- setwd(dir); on.exit(setwd(owd))   # knitr writes figure files here
    env <- new.env(parent = globalenv())
    env$params <- list(xvar = input$x, data = mtcars)
    md <- knitr::knit(text = readLines(file.path(owd, "report-body.Rmd")),
                      envir = env, quiet = TRUE)
    tagList(
      HTML(markdown::mark_html(text = md, template = FALSE)),
      tags$script("if (window.MathJax) MathJax.Hub.Queue(['Typeset', MathJax.Hub]);")
    )
  })
}
```

Source: `020-knit-html`

Pitfalls:
- `report-body.Rmd` has no YAML header here; `params` is injected into `envir`.
- 020's `knitr::knit2html` and evaluate hook workaround are obsolete.
- If pandoc is available, `rmarkdown::render(..., html_fragment())` + `includeHTML()` also works.

## htmlwidgets

Every htmlwidget package ships an `xxxOutput()`/`renderXxx()` pair. They work inside `renderUI` too (dependencies load lazily, 178/180). `htmlwidgets::onRender()` attaches JS after the widget draws.

```r
library(leaflet)
library(plotly)

ui <- page_fillable(
  layout_columns(
    card(leafletOutput("map")),
    card(plotlyOutput("chart"))
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet(
    leaflet(quakes) |> addTiles() |> addCircleMarkers(radius = ~mag, stroke = FALSE)
  )
  output$chart <- renderPlotly(
    plot_ly(quakes, x = ~depth, y = ~mag, type = "scatter", mode = "markers")
  )
}
```

highcharter (118) and networkD3 (150) follow the same shape:

```r
# highcharter (118)
output$hc <- highcharter::renderHighchart({
  highcharter::highchart() |>
    highcharter::hc_add_series(data = summary_df()$value, type = input$type) |>
    highcharter::hc_xAxis(categories = summary_df()$label) |>
    highcharter::hc_add_theme(highcharter::hc_theme_538())
})
# UI: highcharter::highchartOutput("hc", height = "500px")

# networkD3 sankey (150)
output$sankey <- networkD3::renderSankeyNetwork({
  links <- data.frame(source = c(0, 0, 1, 1), target = c(2, 3, 2, 3), value = c(100, 25, 10, 20))
  nodes <- data.frame(name = paste("Group", 1:4))
  networkD3::sankeyNetwork(Links = links, Nodes = nodes, Source = "source",
                           Target = "target", Value = "value", NodeID = "name")
})
# UI: networkD3::sankeyNetworkOutput("sankey")
```

Source: `118-highcharter-births`, `150-networkD3-sankey`, `178-delayed-widget`, `179-nondelayed-widget`, `180-delayed-staticwidget`

Pitfalls:
- Update a leaflet map without redrawing: `leafletProxy("map") |> clearMarkers() |> addMarkers(...)`; same idea `plotlyProxy()`.
- networkD3 node indices are 0-based.
- Highcharts is free only for non-commercial use; check licensing before deploying for an institution.
- highcharter and networkD3 are not installed in this R; plotly covers both use cases (`plot_ly(type = "sankey")`).
- 178-180 and 150 are Shiny regression tests (lazy widget deps, SVG `<body>` clash fixed in shiny 1.4); the lesson is that both work now.

## Archived chart packages -> plotly

054 (`rCharts`-era NVD3 via a hand-written JS output binding) and 182 (`googleCharts`, archived) should not be used. Pattern they show: a custom output binding (054: `Shiny.OutputBinding` + `renderValue`) and an animated bubble chart (182). Use plotly instead:

```r
# 182 replacement: animated bubble chart over years
output$bubble <- renderPlotly({
  plot_ly(healthexp, x = ~Health.Expenditure, y = ~Life.Expectancy,
          size = ~Population, color = ~Region, frame = ~Year,
          text = ~Country, hoverinfo = "text",
          type = "scatter", mode = "markers", marker = list(opacity = 0.5)) |>
    layout(xaxis = list(title = "Health expenditure per capita (USD)"),
           yaxis = list(title = "Life expectancy (years)"))
})

# 054 replacement: multi-series line chart reacting to sliders
output$lines <- renderPlotly({
  t <- 1:100 / 10
  plot_ly(x = t) |>
    add_lines(y = sin(t + input$phase * pi / 180) * input$amp, name = "Sine") |>
    add_lines(y = 0.5 * cos(t), name = "Cosine")
})
```

Write a custom output binding (054 style) only for a JS library with no htmlwidget; prefer `htmlwidgets::scaffoldWidget()` for that.

Source: `054-nvd3-line-chart-output`, `182-google-charts`

## Error sanitization

With `options(shiny.sanitize.errors = TRUE)` users see a generic message instead of the error text (which can leak paths, SQL, credentials). `safeError()` marks messages that are safe to show. For expected problems use `validate(need())`, which is never sanitized and renders as grey text.

```r
options(shiny.sanitize.errors = TRUE)  # top level, once; default on Posit Connect/shinyapps.io

server <- function(input, output, session) {
  output$secret <- renderText(stop("db password is hunter2"))  # user sees generic error
  output$shown <- renderText(stop(safeError("Column 'conc' is missing")))
  output$times100 <- renderText({
    validate(need(is.numeric(input$n) && !is.na(input$n), "Enter a number"))
    input$n * 100
  })
  output$wrapped <- renderText(
    tryCatch(as.numeric(input$txt) * 100, error = \(e) stop(safeError(e)))
  )
}
```

Source: `110-error-sanitization`

Pitfalls:
- 110 toggles the option inside `observe()` for demo purposes; set it once at top level in real apps.
- 110's download handler deliberately errors (`datasetInpute()` typo, `write.csv` without `file`); do not copy it.
- `req()` fails silently (blank output); `validate(need())` shows a message. Choose deliberately.

## Clearing an output (NULL)

Assigning `NULL` to `output$id` removes the rendered content; returning `NULL` or failing `req()` from a render function leaves it empty.

```r
server <- function(input, output, session) {
  output$plot <- renderPlot(plot(cars))
  observeEvent(input$clear, output$plot <- NULL)
}
```

Alternative that can be undone: a `reactiveVal(TRUE)` flag plus `req(show())` inside `renderPlot`.

Source: `130-output-null`
