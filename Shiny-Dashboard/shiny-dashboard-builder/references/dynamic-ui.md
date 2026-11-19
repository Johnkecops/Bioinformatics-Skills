# Dynamic UI

UI that changes at runtime: generated in loops, rendered from the server, shown/hidden, inserted/removed, plus modals, notifications, progress bars and dynamic tabs.

## Contents
- [Choosing a technique](#choosing-a-technique)
- [UI generated in a loop](#ui-generated-in-a-loop)
- [renderUI / uiOutput](#renderui--uioutput)
- [conditionalPanel (show/hide on the client)](#conditionalpanel-showhide-on-the-client)
- [insertUI / removeUI](#insertui--removeui)
- [Dynamic tabs](#dynamic-tabs)
- [Modal dialogs](#modal-dialogs)
- [Notifications](#notifications)
- [Progress bars](#progress-bars)

## Choosing a technique

| Need | Use |
|---|---|
| Change choices/value/label of an existing input | `update*Input()` (see `inputs.md`), not renderUI |
| Fixed number of similar controls known at startup | loop with `lapply()` in the UI |
| Swap a whole block depending on server state | `renderUI()` + `uiOutput()` |
| Show/hide depending only on input values | `conditionalPanel()` |
| Add/remove items one at a time, keep the rest intact | `insertUI()` / `removeUI()` |
| Add/remove tabs | `nav_insert()` / `nav_remove()` (bslib) or `insertTab()` / `removeTab()` |
| Interrupt the user (confirm, form, message) | `showModal(modalDialog())` |
| Transient status message | `showNotification()` |
| Long computation feedback | `withProgress()` / `Progress$new()` |

## UI generated in a loop

Build N similar inputs/outputs from a vector. Access them with `input[[id]]` / `output[[id]]` because the id is a string.

```r
library(shiny)

ids <- paste0("a", 1:5)
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      lapply(seq_along(ids), function(i)
        selectInput(ids[i], paste("Select", i), choices = LETTERS[1:5]))
    ),
    mainPanel(
      verbatimTextOutput("all"),
      lapply(1:3, function(i) uiOutput(paste0("b", i)))
    )
  )
)

server <- function(input, output, session) {
  output$all <- renderPrint(str(lapply(setNames(ids, ids), \(id) input[[id]])))
  lapply(1:3, function(i) {
    output[[paste0("b", i)]] <- renderUI(strong("Output B#", i))
  })
}
```

Source: `025-loop-ui`

Pitfalls:
- Register outputs with `lapply()` (or `local()`), not a bare `for` loop: render functions evaluate lazily, so in a `for` loop every output sees the last `i`.
- A list of tags returned by `lapply()` is fine as a child of any layout function; no `tagList()` wrapper needed.

## renderUI / uiOutput

Server builds UI and sends it to a placeholder `uiOutput()`. Use when the *type* or *structure* of the UI depends on server state.

```r
library(shiny)

ui <- fluidPage(
  selectInput("type", "Input type", c("slider", "text", "numeric", "date")),
  uiOutput("dyn"),
  verbatimTextOutput("val")
)

server <- function(input, output, session) {
  output$dyn <- renderUI({
    switch(input$type,
      slider  = sliderInput("dynamic", "Dynamic", min = 1, max = 20, value = 10),
      text    = textInput("dynamic", "Dynamic", "starting value"),
      numeric = numericInput("dynamic", "Dynamic", 12),
      date    = dateInput("dynamic", "Dynamic")
    )
  })
  output$val <- renderPrint(str(req(input$dynamic)))
}
```

Source: `041-dynamic-ui`

Pitfalls:
- Every re-render destroys and recreates the inputs, resetting user values. If only choices/labels/values change, keep a static input and call `updateSelectInput()` etc.
- Generated inputs are `NULL` until the client has rendered them; guard downstream code with `req()`.
- Do not read the generated input inside the same `renderUI` that creates it (rebuild loop); wrap in `isolate()` if you need its old value to preserve state.
- Inside a module, ids in `renderUI` must use `session$ns("id")` (see `modules.md`).

## conditionalPanel (show/hide on the client)

Shows content when a JavaScript expression is true. Inputs are referenced as `input.id` (dot, not `$`). No server round trip.

```r
library(shiny)

ui <- fluidPage(
  sliderInput("n", "Number of points", min = 10, max = 200, value = 50, step = 10),
  conditionalPanel("input.n >= 50", plotOutput("scatter", height = 300))
)
server <- function(input, output, session) {
  output$scatter <- renderPlot(plot(rnorm(input$n), rnorm(input$n)))
}
```

Inside a module, pass `ns = ns` so `input.n` refers to *this instance's* `n`:

```r
library(shiny)

myPlotUI <- function(id, label = "My plot") {
  ns <- NS(id)
  tagList(
    h3(label),
    sliderInput(ns("n"), "Number of points", min = 10, max = 200, value = 50),
    conditionalPanel("input.n >= 50", ns = ns, plotOutput(ns("scatter"), height = 300))
  )
}
myPlotServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$scatter <- renderPlot(plot(rnorm(input$n), rnorm(input$n)))
  })
}

ui <- fluidPage(myPlotUI("p1", "First"), myPlotUI("p2", "Second"))
server <- function(input, output, session) {
  myPlotServer("p1")
  myPlotServer("p2")
}
```

Source: `033-conditionalpanel-demo`, `119-namespaced-conditionalpanel-demo` (uses old `callModule()`)

Pitfalls:
- Without `ns = ns`, the condition looks for a global `input.n` and the panel never shows (the real id is `p1-n`).
- Ids containing dots or dashes need bracket syntax: `"input['my.id'] == 'x'"`.
- Condition on an output (`output.flag`) only works if that output is not suspended: `outputOptions(output, "flag", suspendWhenHidden = FALSE)`.
- The condition is client-side JS: it cannot see R variables, only `input.*`/`output.*`. For server-side logic use `renderUI` or a hidden tabset (`bslib::navset_hidden()` + `nav_select()`).

## insertUI / removeUI

Append or delete individual elements without re-rendering siblings. Give each inserted element a wrapper `id` so it can be removed by CSS selector. Track ids in a `reactiveVal`.

```r
library(shiny)

ui <- fluidPage(
  actionButton("add", "Insert"),
  actionButton("remove", "Remove oldest"),
  tags$div(id = "placeholder")
)

server <- function(input, output, session) {
  inserted <- reactiveVal(character())

  observeEvent(input$add, {
    id <- paste0("item", input$add)
    insertUI("#placeholder", where = "beforeEnd",
             ui = tags$div(id = id, p("Element", input$add)))
    inserted(c(inserted(), id))
  })

  observeEvent(input$remove, {
    req(length(inserted()) > 0)
    removeUI(paste0("#", inserted()[1]))   # queue: remove oldest
    inserted(inserted()[-1])
  })
}
```

Source: `111-insert-ui` (original uses `<<-` on a plain vector; works but `reactiveVal` is the idiom)

Pitfalls:
- `insertUI` silently does nothing if the selector matches no element; check the `#id` spelling.
- Removing the DOM element does not remove `input$x` for inputs inside it; the last value stays in `input`. Ignore it in logic, or reset it with an `update*Input()` call first.
- Ids must be unique per insertion (use the button counter or a running counter).
- Default `where = "beforeEnd"` appends inside the placeholder; `"afterEnd"` places it after.

## Dynamic tabs

Add/remove tabs on a tabset that has an `id`. Modern bslib:

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  sidebar = sidebar(actionButton("add", "Add tab"), actionButton("rm", "Remove current")),
  navset_card_tab(id = "tabs", nav_panel("Hello", "Static tab"))
)

server <- function(input, output, session) {
  n <- reactiveVal(0)
  observeEvent(input$add, {
    n(n() + 1)
    title <- paste("Dynamic", n())
    nav_insert("tabs", nav_panel(title, value = title, p("Content", n())), select = TRUE)
  })
  observeEvent(input$rm, nav_remove("tabs", input$tabs))
}
```

Base-shiny equivalent: `tabsetPanel(id = "tabs", ...)` with `appendTab("tabs", tabPanel(...))`, `insertTab("tabs", tabPanel(...), target = "Hello", position = "after")`, `removeTab("tabs", target)`.

Source: `166-dynamic-hosted-tab` (a JS regression test for `appendTab` on a tabset inside `mainPanel`; read app.R only)

Pitfalls:
- Give each tab a unique `value`; removal and selection go by value (defaults to title).
- `input$tabs` holds the selected tab's value; it is `NULL` if no `id` was set.

## Modal dialogs

`showModal(modalDialog(...))` from an observer; `removeModal()` to close. Inputs inside the modal behave like normal inputs.

```r
library(shiny)

ui <- fluidPage(actionButton("ask", "Rename sample"), textOutput("name"))

server <- function(input, output, session) {
  observeEvent(input$ask, {
    showModal(modalDialog(
      title = "New name",
      textInput("newname", "Sample name"),
      easyClose = TRUE,
      footer = tagList(modalButton("Cancel"), actionButton("ok", "OK", class = "btn-primary"))
    ))
  })
  observeEvent(input$ok, {
    req(nzchar(input$newname))
    removeModal()
  })
  output$name <- renderText(input$newname)
}
```

Source: `114-modal-dialog`; modal inside a module with validation: `186-sv-module-1` (see `modules.md`)

Pitfalls:
- `easyClose = TRUE` closes on click-outside/Esc; default footer is a single Dismiss button.
- Inside a module, input ids in the modal need `session$ns("id")` because the modal is built in the server.
- Modal inputs persist in `input` after closing; re-opening shows a fresh widget with the default value.

## Notifications

`showNotification()` returns an id you can pass to `removeNotification()`.

```r
library(shiny)

ui <- fluidPage(actionButton("go", "Run"), actionButton("clear", "Clear"))

server <- function(input, output, session) {
  last <- reactiveVal(NULL)
  observeEvent(input$go, {
    last(showNotification("Analysis finished", type = "message", duration = 5))
  })
  observeEvent(input$clear, removeNotification(req(last())))
}
```

Source: `116-notifications`

Pitfalls:
- `type` is one of `"default"`, `"message"`, `"warning"`, `"error"`.
- `duration = NULL` keeps it until closed; `closeButton = FALSE` then makes it removable only from the server.
- Reusing `id = "status"` replaces an existing notification instead of stacking a new one.

## Progress bars

`withProgress()` wraps a block; update with `incProgress()` / `setProgress()`. Use the `Progress` R6 object when progress must be reported from a helper function.

```r
library(shiny)

ui <- fluidPage(actionButton("go", "Simulate"), plotOutput("plot"), tableOutput("tbl"))

server <- function(input, output, session) {
  output$plot <- renderPlot({
    req(input$go)
    withProgress(message = "Simulating", value = 0, {
      x <- numeric(10)
      for (i in 1:10) {
        x[i] <- rnorm(1)
        incProgress(1 / 10, detail = paste("step", i))
        Sys.sleep(0.1)
      }
    })
    plot(x, type = "b")
  })

  # Progress object passed into a non-Shiny helper as a callback
  compute <- function(update = NULL) {
    out <- data.frame(x = numeric(0))
    for (i in 1:5) {
      out[i, "x"] <- rnorm(1)
      if (is.function(update)) update(i / 5, paste("row", i))
    }
    out
  }
  output$tbl <- renderTable({
    req(input$go)
    p <- Progress$new(session, min = 0, max = 1)
    on.exit(p$close())
    p$set(message = "Computing table", value = 0)
    compute(function(v, d) p$set(value = v, detail = d))
  })
}
```

Source: `085-progress`

Pitfalls:
- Always `on.exit(p$close())` with `Progress$new()`, otherwise an error leaves the bar on screen.
- `value = NULL` shows a message with no bar (indeterminate). Nested `withProgress()` calls stack.
- `style = "old"` from the example is legacy; omit `style` (default `"notification"`).
- Progress only renders while the R process is busy in that session; for truly long jobs use `ExtendedTask` (see `async.md`).
