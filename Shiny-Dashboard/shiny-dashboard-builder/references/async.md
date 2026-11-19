# Async patterns

Keep long computations (model fits, BLAST/API calls, big file reads) from freezing the app, using `ExtendedTask` first and plain promises second. Tested on shiny 1.14, promises 1.5, future 1.82, bslib 0.12.

## Contents

- [Setup: future plan](#setup-future-plan)
- [ExtendedTask vs plain promises](#extendedtask-vs-plain-promises)
- [ExtendedTask: long computations without blocking the session](#extendedtask-long-computations-without-blocking-the-session)
- [Plain promises in render functions](#plain-promises-in-render-functions)
- [Async downloads](#async-downloads)
- [req / validate / errors inside promise chains](#req--validate--errors-inside-promise-chains)
- [Async events: eventReactive / observeEvent](#async-events-eventreactive--observeevent)
- [What gets held while a promise is pending](#what-gets-held-while-a-promise-is-pending)
- [Caching async plots](#caching-async-plots)
- [Async HTTP calls (connection header test)](#async-http-calls-connection-header-test)

## Setup: future plan

```r
library(shiny)
library(promises)
library(future)
plan(multisession)   # background R processes; works on Windows, macOS, Linux, RStudio
```

- Call `plan()` once, at the top of `app.R` / `global.R`, not inside `server`.
- `plan(multiprocess)` (examples 123-127) no longer exists in future; replace with `multisession`.
- `plan(multicore)` (129) forks: faster to start, but not on Windows or inside RStudio.
- Without a parallel plan (`plan(sequential)` is the default) `future()` runs immediately in the main process, so nothing is async. Handy in tests.
- Code inside `future({ ... })` runs in another R process: it cannot read `input$`, reactives, or `session`. Read them first, pass values in. Globals and packages used inside are detected automatically; pass `seed = TRUE` when using random numbers.

## ExtendedTask vs plain promises

| | `ExtendedTask` (shiny >= 1.8.1) | Plain promise returned from `render*`/`observe` (examples 121-153) |
|---|---|---|
| Other sessions (users) | not blocked | not blocked |
| Same session while running | stays responsive: other inputs/outputs update | frozen: inputs and timers held until the promise resolves |
| Status / button feedback | `task$status()`, `bslib::input_task_button` spinner | none built in |
| Use for | anything that takes seconds or longer | short async steps, or making one output async without UI changes |

Default to `ExtendedTask` for dashboards. Use a plain promise only when blocking the current user is acceptable.

## ExtendedTask: long computations without blocking the session

Wrap the slow function in `ExtendedTask$new()`; it must return a promise (`future_promise()` or `future()`). Start it with `$invoke(args)` from an event observer, read the value with `$result()` in an output. `bind_task_button()` disables and spins the `input_task_button` while running.

```r
library(shiny)
library(bslib)
library(promises)
library(future)
plan(multisession)

ui <- page_sidebar(
  sidebar = sidebar(
    numericInput("n", "Sample size", 1e6),
    input_task_button("go", "Run simulation")
  ),
  verbatimTextOutput("result"),
  textOutput("clock")                                   # keeps ticking while the task runs
)

server <- function(input, output, session) {
  sim <- ExtendedTask$new(function(n) {
    future_promise({
      Sys.sleep(3)                                      # stand-in for slow work
      summary(rnorm(n))
    }, seed = TRUE)
  }) |> bind_task_button("go")

  observe(sim$invoke(input$n)) |> bindEvent(input$go)   # read inputs here, pass as args

  output$result <- renderPrint(sim$result())
  output$clock <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S")
  })
}

shinyApp(ui, server)
```

Status values: `"initial"`, `"running"`, `"success"`, `"error"`. `sim$result()` silently stops (`req(FALSE)`) while `initial` (output blank), keeps the previous output in progress state while `running`, and re-throws the error on `error`.

```r
server <- function(input, output, session) {
  # ... sim as above ...
  output$status <- renderText(switch(sim$status(),
    initial = "Press Run", running = "Running...", success = "Done", error = "Failed"))
}
```

Source: none of the bundled examples (they predate shiny 1.8.1); this replaces the plain-promise pattern in 121-129.

Pitfalls:
- `invoke()` while running queues the call; `input_task_button` prevents double clicks for you. With a plain `actionButton`, call `bind_task_button()` anyway or guard with `req(sim$status() != "running")`.
- Without `plan(multisession)` the task still "works" but runs in the main process and blocks everything.
- Pass every input the task needs as an argument to `invoke()`; reading `input$x` inside `future_promise()` fails (different process).

## Plain promises in render functions

Every `render*()` accepts a promise as its return value: return a `future()` (or a chain on one) and the output renders when it resolves. `%...>%` is the promise pipe; `then()` is the function form.

```r
server <- function(input, output, session) {
  output$text <- renderText(future({ Sys.sleep(1); "hello" }))
  output$table <- renderTable(future({ Sys.sleep(1); head(cars) }))
  output$plot <- renderPlot({
    future({ Sys.sleep(1); cars }) %...>% plot()      # plot in main process
  })
  output$print <- renderPrint({
    future("Hello") %...>% invisible()                # invisible -> prints nothing, like sync
  })
  output$ui <- renderUI({
    future({ Sys.sleep(1); 42 }) |> then(function(x) h1("Answer:", x))
  })
}
```

Source: `122-async-outputs` (every render function, sync vs async), `123-async-renderprint` (visible vs invisible), `126-async-ticks` (sync code runs in the current tick, promise callbacks after it), `129-async-perf` (overhead of a trivial async output is a few ms).

Pitfalls:
- Draw plots in the `%...>%` callback, not inside `future()`: the graphics device belongs to the main process. Compute data in the future, plot after.
- `renderDataTable()` in 122/126 is deprecated; use `DT::renderDT()`, which also accepts promises.
- 122 downloads an image from the web in `renderImage`; it needs network access.

## Async downloads

`downloadHandler()`'s `content` function may return a promise; the download starts when it resolves. Do the slow work in `future()`, write the file in the callback.

```r
server <- function(input, output, session) {
  output$download <- downloadHandler(
    filename = "rock.csv",
    content = function(file) {
      throw <- input$throw                               # read input before going async
      future({ Sys.sleep(5); rock }) %...>% {
        if (throw) stop("boom")
        write.csv(., file)
      }
    }
  )
}
```

Source: `124-async-download`.

## req / validate / errors inside promise chains

`req()`, `req(cancelOutput = TRUE)` and `validate(need())` behave the same inside a `%...>%` callback as in sync code: blank output, keep previous output, grey message. Use `finally()` for cleanup that must run on success and failure (closing a `Progress`, recording timings), and `%...!%` / `catch()` to handle errors.

```r
server <- function(input, output, session) {
  ready <- future(Sys.sleep(1))
  output$req_async <- renderText({
    ready %...>% { req(!isTruthy(input$boom)) } %...>% { "visible until boom" }
  })
  output$validate_async <- renderText({
    ready %...>% { validate(need(!isTruthy(input$boom), "Self destructed")) } %...>% { "ok" }
  })
  output$safe <- renderText({
    prog <- Progress$new(session)
    prog$set(message = "Working...")
    future(stop("remote failure")) %...!%
      (function(err) paste("Failed:", conditionMessage(err))) |>
      finally(function() prog$close())
  })
}
```

Source: `125-async-req`, `129-async-perf` (`finally()` for timing), `133-async-hold-inputs` (`finally(~prog$close())`).

Pitfalls:
- An unhandled error in an async `observe()` disconnects the session, exactly like a sync observer error (132). In outputs it shows as the red error text.

## Async events: eventReactive / observeEvent

The *event* expression of `eventReactive()` / `observeEvent()` / `bindEvent()` may itself be a promise; the handler runs once it resolves. `req(FALSE)` or `validate()` failures inside it silently cancel the handler; a real error ends the session.

```r
delay <- function(expr, secs = 1) {
  promise(function(resolve, reject) later::later(~resolve(TRUE), secs)) %...>% { force(expr) }
}

server <- function(input, output, session) {
  observeEvent({ req(input$success); delay(input$success) }, {
    message("Success!")                                   # runs 1 s after click
  })
  async_er <- eventReactive(promise_resolve(TRUE) %...>% { input$type }, "normal value")
  output$async_output <- renderText(async_er())
}
```

Source: `132-async-events`.

Pitfalls:
- An `eventReactive()` with a promise event returns a promise, so `async_er()` is not the value; consume it in a `render*()` or with `%...>%`.

## What gets held while a promise is pending

While an output or observer of a session is waiting on a plain promise, Shiny holds that session: new input values, `invalidateLater()` and `reactiveTimer()` ticks, and flush callbacks wait until the promise resolves. Other sessions keep running. This keeps a promise chain consistent (it sees the same `input$choice` at every step) and is the reason to prefer `ExtendedTask` for long work.

```r
wait <- function(secs) promise(~later::later(~resolve(TRUE), secs))

server <- function(input, output, session) {
  output$out <- renderPrint({
    req(input$go)
    isolate({
      cat(input$choice, "\n")
      wait(1) %...>% { cat(input$choice, "\n") }      # same letter even if user changed it
    })
  })
}
```

Source: `133-async-hold-inputs`, `134-async-hold-timers` (timers do not fire mid-promise), `121-async-timer` (`invalidateLater` in a promise output; output stays "recalculating"), `127-async-flush` (onFlush/onFlushed fire after the async observer resolves), `142-reactive-timer` (async observer pauses only its own session's timers; `Sys.sleep` pauses all).

## Caching async plots

`renderCachedPlot()` (143) is superseded by `renderPlot() |> bindCache(key)`. Both the plot and the cache key may be promises; an async key makes the whole cached output async.

```r
server <- function(input, output, session) {
  output$plot <- renderPlot({
    promise_resolve(cars) %...>% plot()
  }) |> bindCache(input$dataset)

  output$gg <- renderPlot({
    promise_resolve(cars) %...>% {
      ggplot2::ggplot(., ggplot2::aes(speed, dist)) + ggplot2::geom_point()
    }
  }) |> bindCache(input$dataset, promise_resolve("v1"))
}
```

Source: `143-async-plot-caching`.

Pitfalls:
- 143 uses `Sys.time()` as the key, so it never hits the cache; it is a test of the mechanism. Real keys are the inputs that determine the plot.
- `bindCache()` must come before `bindEvent()` when both are used: `renderPlot(...) |> bindCache(...) |> bindEvent(...)`.

## Async HTTP calls (connection header test)

`153-connection-header` is a regression test (spurious `Connection: Upgrade` header behind NGINX). The reusable part: run blocking HTTP requests in `future()` and return the result to an output. Read `session$request` in the main process and pass the URL in.

```r
library(curl)

async_status_code <- function(url, headers) {
  future({
    h <- curl::new_handle()
    do.call(curl::handle_setheaders, c(list(h), headers))
    curl::curl_fetch_memory(url, handle = h)$status_code
  })
}

server <- function(input, output, session) {
  url <- reactive({
    port <- session$request$SERVER_PORT
    sprintf("http://localhost:%s/shared/jquery.min.js", if (port == "") "80" else port)
  })
  output$status <- renderText(async_status_code(url(), list(Connection = "Upgrade")))
}
```

Source: `153-connection-header`.

Pitfalls:
- `url()` is evaluated in the main process before `future()` captures it; passing the reactive itself into the future would fail.
- For a slow external API in a dashboard, use `ExtendedTask` with the same function body.
