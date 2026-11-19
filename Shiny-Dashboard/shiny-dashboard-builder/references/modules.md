# Modules

Split a dashboard into reusable, namespaced UI + server pairs; pass reactives in, return values out, test them headless, and organise them in `R/`.

## Contents
- [Module template](#module-template)
- [Passing reactives in, getting values out](#passing-reactives-in-getting-values-out)
- [callModule() to moduleServer() mapping](#callmodule-to-moduleserver-mapping)
- [Testing with testServer()](#testing-with-testserver)
- [Module returning a selection (linked plots)](#module-returning-a-selection-linked-plots)
- [R/ directory auto-sourcing](#r-directory-auto-sourcing)
- [Namespacing dynamic UI inside modules](#namespacing-dynamic-ui-inside-modules)
- [Validation inside modules (shinyvalidate)](#validation-inside-modules-shinyvalidate)
- [Sub-apps (embedding whole apps)](#sub-apps-embedding-whole-apps)

## Module template

Two functions sharing an `id`. UI wraps every id in `ns()`; server wraps its body in `moduleServer()` and returns a reactive.

```r
library(shiny)

# UI: every input/output id goes through ns()
histUI <- function(id, label = "Bins") {
  ns <- NS(id)
  tagList(
    sliderInput(ns("bins"), label, min = 5, max = 50, value = 20),
    plotOutput(ns("plot"))
  )
}

# Server: `data` is a reactive (passed uncalled), returns a reactive
histServer <- function(id, data) {
  stopifnot(is.reactive(data))
  moduleServer(id, function(input, output, session) {
    breaks <- reactive({
      x <- data()
      seq(min(x), max(x), length.out = input$bins + 1)
    })
    output$plot <- renderPlot(hist(data(), breaks = breaks(), main = NULL))
    breaks                       # return the reactive, NOT breaks()
  })
}

# App: two independent instances
ui <- fluidPage(
  selectInput("var", "Variable", names(iris)[1:4]),
  histUI("h1"),
  histUI("h2", label = "Bins (copy)"),
  textOutput("nbreaks")
)
server <- function(input, output, session) {
  col <- reactive(iris[[input$var]])
  br1 <- histServer("h1", data = col)
  histServer("h2", data = col)
  output$nbreaks <- renderText(paste(length(br1()), "breaks in h1"))
}
```

Naming convention: `xxxUI(id, ...)` / `xxxServer(id, ...)`. Inside the module, ids are written plain (`input$bins`); outside, the real id is `"h1-bins"`.

Source: pattern generalised from `108-module-output`, `168-supporting-r-dir`

## Passing reactives in, getting values out

- **In**: pass the reactive itself (`data = col`, not `col()`), call it inside the module (`data()`). Constants (labels, choices, `required = TRUE`) are passed as plain values. Wrap a literal in `reactive()` if the module expects a reactive: `histServer("h", reactive(mtcars$mpg))`.
- **Out**: the last value of the `moduleServer()` function is returned. Return one reactive, or a list for several things (reactive values, validators, helper functions):

```r
library(shiny)

filterServer <- function(id, df) {
  moduleServer(id, function(input, output, session) {
    list(
      data  = reactive(df()[df()[[1]] > input$min, , drop = FALSE]),
      min   = reactive(input$min),
      reset = function() updateNumericInput(session, "min", value = 0)
    )
  })
}
# caller: f <- filterServer("f", reactive(mtcars)); f$data(); f$reset()
```

Pitfalls:
- Passing `input$x` (a value) instead of `reactive(input$x)` freezes the value at startup; the module never updates.
- Never read `input$x` of the parent from inside a module; the module's `input` only sees its own namespace. Pass it in as a reactive.
- Returning `breaks()` instead of `breaks` evaluates outside a reactive context and errors.

## callModule() to moduleServer() mapping

Every example before 2020 (`108`, `119`, `168`) uses `callModule()`. It still works but is superseded.

| Old (`callModule`) | Modern (`moduleServer`, shiny >= 1.5) |
|---|---|
| `counter <- function(input, output, session, label) { ... }` | `counterServer <- function(id, label) { moduleServer(id, function(input, output, session) { ... }) }` |
| `callModule(counter, "c1", label = "x")` | `counterServer("c1", label = "x")` |
| `res <- callModule(mod, "m", reactive(df))` | `res <- modServer("m", reactive(df))` |
| UI function unchanged | UI function unchanged (`ns <- NS(id)`) |

```r
library(shiny)

# Modern version of 168-supporting-r-dir/R/counter.R
counterButton <- function(id, label = "Counter") {
  ns <- NS(id)
  tagList(actionButton(ns("button"), label), verbatimTextOutput(ns("out")))
}
counterServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    count <- reactiveVal(0)
    observeEvent(input$button, count(count() + 1))
    output$out <- renderText(count())
    count
  })
}
ui <- fluidPage(counterButton("counter1", "Counter #1"))
server <- function(input, output, session) counterServer("counter1")
```

## Testing with testServer()

Runs the module server without a browser. Set inputs with `session$setInputs()`; read module-local reactives and outputs by name; the return value is `session$returned`.

```r
library(shiny)

testServer(histServer, args = list(data = reactive(c(1, 5, 10))), {
  session$setInputs(bins = 3)
  stopifnot(length(breaks()) == 4)                 # internal reactive
  stopifnot(identical(session$returned(), breaks()))  # returned reactive
  stopifnot(nzchar(output$plot$src))               # output rendered
})

testServer(counterServer, {
  session$setInputs(button = 1)
  session$setInputs(button = 2)
  stopifnot(count() == 2, output$out == "2")
})
```

Put these in `tests/testthat/test-*.R` with `expect_equal()` instead of `stopifnot()`; `shiny::runTests()` runs them.

Pitfalls:
- `testServer()` exercises server logic only; `ns()`/UI typos are not caught. Check UI with `as.character(histUI("x"))`.
- Each `session$setInputs()` call flushes reactives; set inputs that must change together in one call.

## Module returning a selection (linked plots)

A module owns two brushed plots sharing one brush id, and returns the data with a `selected_` column; the caller summarises it.

```r
library(shiny)
library(ggplot2)

linkedScatterUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(6, plotOutput(ns("plot1"), brush = ns("brush"))),
    column(6, plotOutput(ns("plot2"), brush = ns("brush")))
  )
}

linkedScatterServer <- function(id, data, left, right) {
  moduleServer(id, function(input, output, session) {
    with_sel <- reactive(brushedPoints(data(), input$brush, allRows = TRUE))
    scatter <- function(d, cols) {
      ggplot(d, aes(.data[[cols[1]]], .data[[cols[2]]], colour = selected_)) +
        geom_point() +
        scale_colour_manual(values = c("black", "#66D65C"), guide = "none")
    }
    output$plot1 <- renderPlot(scatter(with_sel(), left()))
    output$plot2 <- renderPlot(scatter(with_sel(), right()))
    with_sel
  })
}

ui <- fixedPage(linkedScatterUI("scatters"), textOutput("summary"))
server <- function(input, output, session) {
  df <- linkedScatterServer("scatters", reactive(mpg),
                            left = reactive(c("cty", "hwy")),
                            right = reactive(c("drv", "hwy")))
  output$summary <- renderText(sprintf("%d observation(s) selected", sum(df()$selected_)))
}
```

Source: `108-module-output` (original: `callModule`, `aes_string()` and `guide = FALSE`, all deprecated; replaced above)

Pitfalls:
- The brush id must be `ns("brush")` in the UI and read as `input$brush` in the server.

## R/ directory auto-sourcing

Put module files in `R/` next to `app.R` (or `ui.R`/`server.R`). Since shiny 1.5 every top-level `R/*.R` file is sourced automatically before the app starts, so no `source()` calls are needed.

```
myapp/
  app.R            # ui + server only, calls histUI()/histServer()
  global.R         # optional; sourced before R/
  R/
    mod_hist.R     # histUI + histServer
    mod_filter.R
    utils.R
```

Source: `168-supporting-r-dir` (README says the opt-in `options(shiny.autoload.r = TRUE)` is required; that was only for shiny 1.3.x, now default)

Pitfalls:
- Files are sourced alphabetically; only define functions/objects there, do not depend on load order.
- Only top-level `R/*.R` is loaded; subfolders are ignored.
- Opt out with an `R/_disable_autoload.R` file (needed if `R/` holds scripts that should not run).
- `108-module-output` uses an explicit `source("linked_scatter.R")` instead; works but moving the file into `R/` is cleaner.

## Namespacing dynamic UI inside modules

UI built in the module *server* (renderUI, modals, insertUI) has no `NS(id)` in scope; use `session$ns`. `conditionalPanel()` in module UI needs `ns = ns` (see `dynamic-ui.md`).

```r
library(shiny)

pickerUI <- function(id) uiOutput(NS(id, "ui"))
pickerServer <- function(id, choices) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$ui <- renderUI(selectInput(ns("pick"), "Pick", choices()))
    observeEvent(input$pick, showModal(modalDialog(
      textInput(ns("note"), paste("Note for", input$pick)), easyClose = TRUE
    )), ignoreInit = TRUE)
    reactive(input$pick)
  })
}
```

Source: `186-sv-module-1` (modal built with `session$ns`), `119-namespaced-conditionalpanel-demo`

Pitfalls:
- Forgetting `ns()` here gives inputs the global id; `input$pick` inside the module stays `NULL` forever with no error.
- `insertUI(selector = ...)` selectors are page-global: use `paste0("#", ns("placeholder"))`.

## Validation inside modules (shinyvalidate)

`shinyvalidate` is not installed here: `install.packages("shinyvalidate")`. Three patterns:

1. **Self-contained** (`186-sv-module-1`): the module creates its own `InputValidator`, calls `iv$enable()` on submit, and `iv$disable()` when the modal closes.
2. **Return the validator** (`187-sv-module-2`): module returns `list(value, iv, reset)`; the caller decides when to `enable()`.
3. **Rules passed in + child validator** (`188-sv-module-3`): caller passes a rule function; parent combines with `iv$add_validator(child$iv)`.

```r
library(shiny)
library(shinyvalidate)

emailUI <- function(id, label = "Email") textInput(NS(id, "email"), label)

emailServer <- function(id, required = TRUE, extra_rule = NULL) {
  moduleServer(id, function(input, output, session) {
    iv <- InputValidator$new()
    if (required) iv$add_rule("email", sv_required())
    iv$add_rule("email", sv_email())
    if (!is.null(extra_rule)) iv$add_rule("email", extra_rule)
    list(
      value = reactive(if (iv$is_valid()) input$email),
      iv    = iv,
      reset = function() updateTextInput(session, "email", value = "")
    )
  })
}

ui <- fluidPage(emailUI("contact"), actionButton("send", "Send"))
server <- function(input, output, session) {
  em <- emailServer("contact", extra_rule = ~ if (!grepl("\\.ac\\.id$", .)) "Use an institutional address")
  iv <- InputValidator$new()
  iv$add_validator(em$iv)        # parent validator aggregates children
  observeEvent(input$send, {
    iv$enable()                  # show messages only after first submit
    req(iv$is_valid())
    showNotification(paste("Sent to", em$value()), type = "message")
    em$reset()
  })
}
```

Rules are functions or `~` formulas (`.` is the value) returning an error string or `NULL`. Rule ids are unnamespaced inside the module; shinyvalidate resolves them through the module session.

Source: `186-sv-module-1`, `187-sv-module-2`, `188-sv-module-3` (188 also uses `digest` to hash the password)

Pitfalls:
- Messages show only after `iv$enable()`; enabling at startup flags empty fields before the user types.
- Add child validators to the parent once at setup, not inside an observer (they accumulate).

## Sub-apps (embedding whole apps)

A full app can be embedded in an R Markdown document (`runtime: shiny`) with `shinyAppDir("subdir")` or an inline `shinyApp(ui, server)` in a chunk. An app may also use `ui = NULL` and serve a hand-written `www/index.html`.

````markdown
---
title: "Subapp test"
output: html_document
runtime: shiny
---
```{r}
shinyAppDir("app2")   # app2/app.R: shinyApp(NULL, server) + app2/www/index.html
```
````

Source: `156-subapps` (a regression test for shiny#2385; run with `rmarkdown::run("index.Rmd")`, needs pandoc; `app3` needs leaflet)

Pitfalls:
- Each embedded app runs in its own iframe with its own session; they cannot share reactives. For one dashboard with shared state, use modules instead.
- With `ui = NULL` + `www/index.html`, the HTML must load Shiny's JS itself (see `app2/www/index.html`); `htmlTemplate()` is the modern route.
