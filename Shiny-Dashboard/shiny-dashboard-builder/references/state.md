# State

Reading the URL and browser info, and saving/restoring app state through bookmarks and the query string.

## Contents
- [Client data and query string](#client-data-and-query-string)
- [Bookmark button (URL or server store)](#bookmark-button-url-or-server-store)
- [Live URL that tracks inputs](#live-url-that-tracks-inputs)
- [Bookmarking dynamic UI and custom state](#bookmarking-dynamic-ui-and-custom-state)

## Client data and query string

`session$clientData` is a read-only reactive list of browser facts: URL parts, pixel ratio, and each output's width/height/hidden state. Use it to preselect inputs from a link such as `?gene=TP53&n=50`.

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  textInput("gene", "Gene"),
  numericInput("n", "n", 10),
  verbatimTextOutput("summary"),
  verbatimTextOutput("queryText", placeholder = TRUE),
  plotOutput("plot")
)

server <- function(input, output, session) {
  # One-off: copy ?gene=...&n=... into inputs on load
  observe({
    q <- getQueryString()          # = parseQueryString(session$clientData$url_search)
    if (!is.null(q$gene)) updateTextInput(session, "gene", value = q$gene)
    if (!is.null(q$n)) updateNumericInput(session, "n", value = as.numeric(q$n))
  }) |> bindEvent(session$clientData$url_search, once = TRUE)

  output$queryText <- renderText({
    q <- getQueryString()
    paste(names(q), q, sep = "=", collapse = ", ")
  })

  output$summary <- renderText({
    cd <- reactiveValuesToList(session$clientData)
    paste(names(cd), vapply(cd, \(v) paste(v, collapse = " "), ""), sep = " = ", collapse = "\n")
  })

  # Size-aware plot: output_<id>_width is in CSS pixels
  output$plot <- renderPlot(
    plot(1:10, main = paste("width", session$clientData$output_plot_width)),
    res = 96
  )
}

shinyApp(ui, server)
```

Useful keys: `url_protocol`, `url_hostname`, `url_port`, `url_pathname`, `url_search`, `url_hash`, `url_hash_initial`, `pixelratio`, `output_<id>_width`, `output_<id>_height`, `output_<id>_hidden`.

Source: `032-client-data-and-query-string`

Pitfalls:
- Query values are always character strings; convert with `as.numeric()` and validate before use.
- Never trust query parameters for anything security-relevant; users can edit the URL.
- `getQueryString()` / `getUrlHash()` must be called inside a reactive context.

## Bookmark button (URL or server store)

Lets users save the current inputs as a shareable link. `store = "url"` encodes inputs in the URL; `store = "server"` saves to disk on the server and keeps URLs short (needed for long text inputs or file uploads).

```r
library(shiny)
library(bslib)

ui <- function(request) {          # UI must be a function of `request` for bookmarking
  page_sidebar(
    sidebar = sidebar(
      sliderInput("n", "Number of observations", 1, nrow(faithful), 100),
      bookmarkButton()
    ),
    card(plotOutput("plot"))
  )
}

server <- function(input, output, session) {
  output$plot <- renderPlot(hist(faithful$eruptions[seq_len(input$n)], breaks = 40))
}

shinyApp(ui, server, enableBookmarking = "url")   # or "server"
```

Classic placement: `enableBookmarking(store = "url")` as a top-level call before `shinyApp()`; same effect.

Source: `113-bookmarking-url`

Pitfalls:
- Forgetting `ui <- function(request)` gives an error when a bookmark URL is opened.
- `actionButton` values and passwords should not be restored: `setBookmarkExclude(c("go", "password"))` in the server.
- `store = "server"` needs a writable app directory (`shiny_bookmarks/`); fine on Posit Connect / Shiny Server, not on read-only hosts.

## Live URL that tracks inputs

Update the browser address bar on every input change, so copying the URL always captures current state (no button).

```r
library(shiny)

ui <- function(request) {
  fluidPage(
    textInput("txt", "Text"),
    checkboxInput("chk", "Checkbox")
  )
}

server <- function(input, output, session) {
  observe({
    reactiveValuesToList(input)    # take a dependency on every input
    session$doBookmark()
  })
  onBookmarked(\(url) updateQueryString(url))
}

shinyApp(ui, server, enableBookmarking = "url")
```

Source: `115-bookmarking-updatequerystring`

Pitfalls:
- Fires on every keystroke; for text inputs wrap the trigger in `debounce()` if the URL update feels jumpy.
- `updateQueryString(url, mode = "replace")` (default) avoids flooding browser history; `mode = "push"` makes Back step through states.
- `setBookmarkExclude()` inputs are not written to the URL, which also keeps it short.

## Bookmarking dynamic UI and custom state

Inputs created by `renderUI()` restore their bookmarked value automatically (shiny >= 1.2). Non-input state (a `reactiveVal`, a computed selection) needs `onBookmark()` / `onRestore()`.

```r
library(shiny)

ui <- function(request) {
  fluidPage(
    uiOutput("ui"),
    actionButton("reset", "Reset slider"),
    actionButton("add", "Add one"),
    textOutput("count"),
    bookmarkButton()
  )
}

server <- function(input, output, session) {
  output$ui <- renderUI(sliderInput("x", "x", 1, 10, 5)) |> bindEvent(input$reset)

  clicks <- reactiveVal(0)
  observe(clicks(clicks() + 1)) |> bindEvent(input$add)
  output$count <- renderText(paste("Clicks:", clicks()))

  setBookmarkExclude(c("reset", "add"))
  onBookmark(\(state) state$values$clicks <- clicks())
  onRestore(\(state) clicks(state$values$clicks))
}

shinyApp(ui, server, enableBookmarking = "url")
```

Source: `135-bookmark-uioutput`

Pitfalls:
- 135 wraps `renderUI` in a `promises::promise()` only to test async restore; not needed in normal apps.
- After restore, re-rendering the `renderUI` (here via Reset) brings back the default value, not the bookmarked one; that is intended.
- Inside modules, bookmarking works per namespace; call `onBookmark()`/`onRestore()` inside `moduleServer()`.
