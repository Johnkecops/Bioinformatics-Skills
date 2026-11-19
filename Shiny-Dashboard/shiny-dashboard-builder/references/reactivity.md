# Reactivity patterns

Which reactive construct to use, with modern (shiny >= 1.7, tested on 1.14) versions of the reactivity examples.

## Contents

- [Which construct do I use](#which-construct-do-i-use)
- [Action buttons: patterns 1-5 side by side](#action-buttons-patterns-1-5-side-by-side)
- [Reactive expressions (cached computation)](#reactive-expressions-cached-computation)
- [Run on click only: bindEvent / eventReactive](#run-on-click-only-bindevent--eventreactive)
- [isolate: read without depending](#isolate-read-without-depending)
- [Observers for side effects](#observers-for-side-effects)
- [Timers: invalidateLater and reactiveTimer](#timers-invalidatelater-and-reactivetimer)
- [Watching files and databases: reactiveFileReader / reactivePoll](#watching-files-and-databases-reactivefilereader--reactivepoll)
- [State: reactiveVal and reactiveValues](#state-reactiveval-and-reactivevalues)
- [Rate limiting: debounce, throttle, input rate policy](#rate-limiting-debounce-throttle-input-rate-policy)
- [Flush callbacks: onFlush / onFlushed](#flush-callbacks-onflush--onflushed)

## Which construct do I use

| Need | Use | Returns a value? | Runs when |
|---|---|---|---|
| Derived data shared by several outputs (filter, model fit) | `reactive({ ... })` | yes, cached | lazily, when a reader needs it and a dependency changed |
| Same, but only recompute on a button click | `reactive({ ... }) \|> bindEvent(input$go)` (old: `eventReactive(input$go, { ... })`) | yes | when `input$go` changes |
| Side effect (write file, notify, update an input, set state) | `observe({ ... })` | no | eagerly, whenever a dependency changes |
| Side effect on a click | `observe({ ... }) \|> bindEvent(input$go)` (old: `observeEvent(input$go, { ... })`) | no | when `input$go` changes |
| A single piece of mutable state (last result, counter, "show plot" flag) | `rv <- reactiveVal(init)`; read `rv()`, write `rv(new)` | yes | readers update when it is set to a new value |
| Several related pieces of state | `rv <- reactiveValues(a = 1, b = NULL)`; `rv$a` | yes | per field |
| Read an input without re-running when it changes | `isolate(input$x)` | n/a | n/a |
| Periodic refresh | `invalidateLater(ms)` inside a reactive/output, or `reactiveTimer(ms)` | n/a | every `ms` |
| Slow down a chatty input | `reactive(input$x) \|> debounce(ms)` / `throttle(ms)` | yes | after quiet period / at most every `ms` |

Rules of thumb: compute with `reactive`, act with `observe`, trigger with `bindEvent`, store with `reactiveVal`. Never assign to a global from a `reactive()` to share data; return the value instead.

## Action buttons: patterns 1-5 side by side

All five assume `ui` has the buttons/inputs named below. Each shows the modern `bindEvent()` form; the commented line is the `observeEvent`/`eventReactive` form used in the original example. Both are fine in current shiny.

| # | Goal | Construct |
|---|---|---|
| 1 | Button triggers a side effect | `observe() \|> bindEvent()` |
| 2 | Button triggers a computation; output waits for it | `reactive() \|> bindEvent()` |
| 3 | Several buttons write the same output | `reactiveVal` + one observer per button |
| 4 | One button sets data, another clears it | `reactiveVal` + reset observer |
| 5 | Button plots current tab's settings; switching tabs clears | `reactive \|> bindEvent` + `reactiveVal` flag |

```r
library(shiny)

# Pattern 1 (088): button -> side effect
server1 <- function(input, output, session) {
  observe({
    showNotification("Thank you for clicking")
  }) |> bindEvent(input$do)
  # observeEvent(input$do, { showNotification("Thank you for clicking") })
}

# Pattern 2 (089): button -> delayed computation
server2 <- function(input, output, session) {
  random_vals <- reactive(runif(input$n)) |> bindEvent(input$go)
  # random_vals <- eventReactive(input$go, { runif(input$n) })
  output$plot <- renderPlot(hist(random_vals()))
}

# Pattern 3 (090): two buttons, one output
server3 <- function(input, output, session) {
  v <- reactiveVal(NULL)
  observe(v(runif(100))) |> bindEvent(input$runif)
  observe(v(rnorm(100))) |> bindEvent(input$rnorm)
  output$plot <- renderPlot({
    req(v())
    hist(v())
  })
}

# Pattern 4 (091): action + reset
server4 <- function(input, output, session) {
  v <- reactiveVal(NULL)
  observe(v(runif(100))) |> bindEvent(input$runif)
  observe(v(NULL)) |> bindEvent(input$reset)
  output$plot <- renderPlot({
    req(v())
    hist(v())
  })
}

# Pattern 5 (092): tabset of settings + one Go button; changing tab clears plot
server5 <- function(input, output, session) {
  plot_data <- reactive({
    if (input$tabset == "Uniform") {
      runif(input$unifCount, input$unifRange[1], input$unifRange[2])
    } else {
      rnorm(input$normCount, input$normMean, input$normSd)
    }
  }) |> bindEvent(input$go)
  shown <- reactiveVal(FALSE)
  observe(shown(TRUE)) |> bindEvent(input$go)
  observe(shown(FALSE)) |> bindEvent(input$tabset)
  output$plot <- renderPlot({
    req(shown())
    hist(plot_data())
  })
}
```

Source: `088-action-pattern1`, `089-action-pattern2`, `090-action-pattern3`, `091-action-pattern4`, `092-action-pattern5`, `028-actionbutton-demo` (same as pattern 2 with `renderText`).

Pitfalls:
- `bindEvent()` / `eventReactive()` ignore the initial `NULL`/0 of an `actionButton` (`ignoreNULL = TRUE`), so pattern 2's output is empty until the first click. Pass `ignoreNULL = FALSE` to compute on startup too.
- `req(v())` replaces the old `if (is.null(v$data)) return()`. `req()` also stops downstream outputs cleanly.
- Pattern 1 originally used `session$sendCustomMessage()` plus a JS handler in `www/message-handler.js`. Use that only for custom JS; for a user message use `showNotification()` or `showModal()`.
- Pattern 5 originally wrapped the whole render in `isolate()` and stored the click count. `bindEvent()` expresses the same "only on click" intent without `isolate`.

## Reactive expressions (cached computation)

Put shared derived data in a `reactive()`; every output that calls it reuses one cached value until an input it read changes. Outputs that don't call it (e.g. a caption) never trigger it.

```r
server <- function(input, output, session) {
  dataset <- reactive(switch(input$dataset, rock = rock, pressure = pressure, cars = cars))
  output$caption <- renderText(input$caption)          # does not re-run dataset()
  output$summary <- renderPrint(summary(dataset()))
  output$view    <- renderTable(head(dataset(), n = input$obs))
}
```

Source: `003-reactivity`.

Pitfalls:
- Call it with parentheses: `dataset()`, not `dataset`.
- `get(input$dataset)` is shorter than `switch()` but lets the user request any object name; keep the whitelist.

## Run on click only: bindEvent / eventReactive

See action-button patterns 2 and 5. `bindEvent()` also works on `render*()` directly, and accepts several events (fires when any changes):

```r
server <- function(input, output, session) {
  output$nText <- renderText(input$n) |> bindEvent(input$goButton)
  # several triggers: bindEvent(input$go, input$refresh)
  # also run once at startup: bindEvent(input$go, ignoreNULL = FALSE)
}
```

Source: `028-actionbutton-demo`, `089-action-pattern2`.

## isolate: read without depending

`isolate(expr)` reads reactive values without registering a dependency, so the surrounding output only re-runs for the non-isolated inputs. Here the text updates on typing and on click, but moving the slider alone does nothing.

```r
server <- function(input, output, session) {
  output$summary <- renderText({
    input$goButton                                      # take a dependency on the button
    paste0('text is "', input$text, '", n is ', isolate(input$n))
  })
}
```

Source: `049-isolate-demo`.

Pitfalls:
- For "only on click" prefer `bindEvent()`; it ignores every input in the body, whereas `isolate` is per-value and easy to forget for one input.
- `isolate()` is still needed inside an observer that both reads and writes the same `reactiveVal` (e.g. `v(isolate(v()) + 1)`), or it re-triggers itself forever.

## Observers for side effects

`observe()` runs eagerly whenever any value it reads changes. Use for logging, writing files, `update*Input()`, setting state. It returns a handle you can `$suspend()`, `$resume()`, `$destroy()`. Clean up per-session resources in `session$onSessionEnded()`.

```r
server <- function(input, output, session) {
  logfile <- tempfile("log", fileext = ".txt")
  obs <- observe(cat(input$n, "\n", file = logfile, append = TRUE))
  session$onSessionEnded(function() {
    obs$destroy()
    unlink(logfile)
  })
  output$text <- renderText(paste("n is", input$n))
}
```

Source: `055-observer-demo`.

Pitfalls:
- An observer's return value is discarded; if you want a value, it should be a `reactive()`.
- Observers run even when no output is visible; heavy work here is never skipped.

## Timers: invalidateLater and reactiveTimer

`invalidateLater(ms)` inside a reactive context schedules that context to re-run after `ms`; the interval may itself be reactive. `reactiveTimer(ms)` creates a reactive "tick" several consumers can share. A timer created outside `server` is global (one for all sessions); inside `server` it is per session.

```r
options(digits.secs = 3)
server <- function(input, output, session) {
  output$time <- renderText({
    invalidateLater(as.integer(input$interval))         # e.g. selectInput of "500"/"1000"
    format(Sys.time())
  })

  tick <- reactiveTimer(1000)                           # per-session
  n <- reactiveVal(0)
  observe({
    tick()
    n(isolate(n()) + 1)
  })
  output$count <- renderText(n())
}
```

Source: `011-timer`, `034-current-time`, `142-reactive-timer`.

Pitfalls:
- `142-reactive-timer` shows that a busy synchronous observer (`Sys.sleep`) freezes all timers in the R process; an async (promise) observer pauses only its own session's timers. See [async.md](async.md#what-gets-held-while-a-promise-is-pending).
- Prefer `reactive(...) |> bindEvent(tick())` over a `<<-` counter inside a reactive (the original used `on.exit(i <<- i + 1)`).

## Watching files and databases: reactiveFileReader / reactivePoll

`reactiveFileReader(ms, session, path, readFunc)` re-reads a file when its mtime changes, checking every `ms`. `reactivePoll(ms, session, checkFunc, valueFunc)` generalises it: a cheap `checkFunc` (e.g. `SELECT max(updated_at)`) runs every `ms`, and the expensive `valueFunc` only when the check value changes. Use for log files, instrument output folders, shared result tables.

```r
server <- function(input, output, session) {
  path <- file.path(tempdir(), "results.csv")

  file_data <- reactiveFileReader(500, session, path, read.csv)

  poll_data <- reactivePoll(4000, session,
    checkFunc = function() if (file.exists(path)) file.info(path)$mtime else "",
    valueFunc = function() read.csv(path)
  )

  output$table <- renderTable(head(file_data()))
}
```

Source: `059-reactive-poll-and-file-reader`.

Pitfalls:
- `reactiveFileReader` errors if the file does not exist yet; create it first or use `reactivePoll` with a guarded `checkFunc` and `req(file.exists(path))` in `valueFunc`.
- Define it in `global.R`/top-level with `session = NULL` to share one poller among all sessions.

## State: reactiveVal and reactiveValues

`reactiveVal()` holds one value (`rv()` to read, `rv(x)` to write). `reactiveValues()` is a named list of them (`rv$x`). Readers update only when a set value differs from the previous one (`identical()` check for `reactiveVal`). Use them as the target of event observers (action patterns 3-5).

```r
server <- function(input, output, session) {
  history <- reactiveVal(numeric(0))
  observe(history(c(history(), input$n))) |> bindEvent(input$add)

  st <- reactiveValues(fit = NULL, msg = "not fitted")
  observe({
    st$fit <- lm(dist ~ speed, data = cars)
    st$msg <- "fitted"
  }) |> bindEvent(input$fit)

  output$hist <- renderPrint(history())
  output$msg <- renderText(st$msg)
}
```

Source: `152-set-reactivevalue` (regression test: assigning a large nested list to a `reactiveValues` field must be fast), `090-action-pattern3`, `091-action-pattern4`, `121-async-timer` (`reactiveVal` counter).

Pitfalls:
- Inside `bindEvent()`'d observers the body is already isolated, so `history(c(history(), ...))` is safe. In a plain `observe()` wrap the read in `isolate()` or it loops.
- `reactiveValues` fields compare by reference for environments/R6; mutating an object in place does not notify readers. Assign a new object.

## Rate limiting: debounce, throttle, input rate policy

`debounce(r, ms)`: emit only after `r` has been quiet for `ms` (good for text search boxes). `throttle(r, ms)`: emit at most every `ms` while changing (good for live sliders driving a plot). Both wrap a reactive expression, not `input$x` directly.

```r
server <- function(input, output, session) {
  clicks <- reactive(input$click)
  clicks_throttled <- clicks |> throttle(1000)
  clicks_debounced <- clicks |> debounce(1000)
  output$raw      <- renderText(clicks())
  output$throttle <- renderText(clicks_throttled())
  output$debounce <- renderText(clicks_debounced())
}
```

Some inputs are also rate-limited in the browser: `sliderInput` debounces by 250 ms before sending, `textInput` too. Updating a slider to `Date` values with `updateSliderInput()` keeps that client-side policy.

```r
server <- function(input, output, session) {
  observe({
    rng <- as.Date(c("2012-12-22", "2017-08-09"))
    updateSliderInput(session, "slider", min = rng[1], max = rng[2], value = rng)
  }) |> bindEvent(input$update)
  output$output <- renderPrint(str(input$slider))
}
```

Source: `174-throttle-debounce`, `159-rate-policy` (regression test for #2387).

## Flush callbacks: onFlush / onFlushed

A "flush" is Shiny sending the current batch of output values to the browser. `session$onFlush(fn)` runs before, `session$onFlushed(fn)` after; `once = TRUE` (default) runs it a single time. `014-onflushed` uses it to show a placeholder for slow outputs so fast outputs appear first.

```r
server <- function(input, output, session) {
  starting <- reactiveVal(TRUE)
  session$onFlushed(function() starting(FALSE))        # after first batch is sent

  output$fast <- renderText("This happens right away")
  output$slow <- renderText({
    if (starting()) return("Please wait...")
    Sys.sleep(5)                                       # stand-in for slow work
    "This happens later"
  })
}
```

Source: `014-onflushed`, `127-async-flush` (flush callbacks fire after an async observer's promise resolves), `121-async-timer` (`onFlushed(once = FALSE)` for logging).

Pitfalls:
- This only reorders work; the session is still blocked during `Sys.sleep`. For genuinely long work use `ExtendedTask` ([async.md](async.md#extendedtask-long-computations-without-blocking-the-session)).
- The original used `invalidateLater(0)` plus a `reactiveValues` flag; a `reactiveVal` set from `onFlushed` is enough because setting it invalidates readers.
