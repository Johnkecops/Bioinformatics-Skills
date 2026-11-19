# JavaScript in Shiny

Moving data between browser JS and R: `Shiny.setInputValue`, custom messages, JS events, widget hooks, custom HTML pages, and full input bindings. Ordered from most to least often needed in a dashboard.

## Contents
- [Where JS/CSS files go](#where-jscss-files-go)
- [JS → R: Shiny.setInputValue](#js--r-shinysetinputvalue)
- [R → JS: sendCustomMessage](#r--js-sendcustommessage)
- [Shiny JS events](#shiny-js-events)
- [Hook into an htmlwidget: onRender](#hook-into-an-htmlwidget-onrender)
- [Third-party head snippets (Google Analytics)](#third-party-head-snippets-google-analytics)
- [Custom HTML page: htmlTemplate / www/index.html](#custom-html-page-htmltemplate--wwwindexhtml)
- [Prerendered R Markdown](#prerendered-r-markdown)
- [React component as an input: reactR](#react-component-as-an-input-reactr)
- [Full custom input binding](#full-custom-input-binding)
- [R as a WebSocket client](#r-as-a-websocket-client)
- [Example index](#example-index)

## Where JS/CSS files go

| Situation | Put file | Reference with |
|---|---|---|
| App-specific script/style | `www/` next to `app.R` (served at `/`) | `tags$script(src = "js/app.js")`, `tags$link(rel = "stylesheet", href = "app.css")` |
| Small script, inline it | anywhere in app dir | `includeScript("script.js")`, `includeCSS("x.css")`, `includeHTML("snippet.html")` |
| Folder outside `www/` | any dir | `addResourcePath("assets", "path/to/dir")` then `src = "assets/x.js"` |
| Reusable component / package | `inst/` dir | `htmltools::htmlDependency(name, version, src = c(file = dir), script = "x.js")` attached to the tag; deduplicated automatically |
| Inline one-off | — | `tags$script(HTML("..."))` |

```r
library(shiny)
library(bslib)

addResourcePath("vendor", "vendor")   # ./vendor/chart.js -> /vendor/chart.js

ui <- page_fluid(
  tags$head(
    tags$link(rel = "stylesheet", href = "app.css"),   # www/app.css
    tags$script(src = "vendor/chart.js")
  ),
  h3(id = "msg", "waiting"),
  tags$script(src = "js/run.js")                       # www/js/run.js, runs after #msg exists
)

server <- function(input, output, session) {}

shinyApp(ui, server)
```

Source: `061-server-to-client-custom-messages`, `169-prerender-b` (`www/js/`), `175-setInputValue` (`includeScript`), `151-reactr-input` (`htmlDependency`), `181-google-analytics` (`includeHTML`, `includeCSS`)

Pitfalls:
- Paths in `src`/`href` are relative to `www/`; do not write `www/` in them.
- A script in `tags$head` runs before the body exists: wrap DOM code in `$(function() { ... })` or place the `tags$script` at the end of the UI (as `169-prerender-b` does).
- When a function emits the same `tags$head(tags$script(...))` per call (custom inputs), wrap in `singleton()` or use `htmlDependency()` so it loads once.

## JS → R: Shiny.setInputValue

Any JS can create or set `input$<name>`. Use it for clicks on custom HTML, values from browser APIs (time zone, window size, geolocation), or events from JS libraries.

```r
library(shiny)
library(bslib)

genes <- c("TP53", "BRCA1", "EGFR")

ui <- page_fluid(
  tags$script(HTML("
    // JS: send which gene button was clicked
    $(document).on('click', '.gene', function() {
      Shiny.setInputValue('gene_clicked', this.dataset.gene, {priority: 'event'});
    });
    // JS: send browser time zone once connected
    $(document).on('shiny:connected', function() {
      Shiny.setInputValue('client_tz', Intl.DateTimeFormat().resolvedOptions().timeZone);
    });
  ")),
  lapply(genes, function(g)
    tags$button(class = "btn btn-outline-primary gene", `data-gene` = g, g)),
  textOutput("picked"),
  textOutput("tz")
)

server <- function(input, output, session) {
  # R: fires on every click, even the same gene twice (priority: 'event')
  clicks <- reactiveVal(0)
  observeEvent(input$gene_clicked, clicks(clicks() + 1))
  output$picked <- renderText(paste("Clicked:", req(input$gene_clicked), "| total clicks:", clicks()))
  output$tz <- renderText(paste("Browser time zone:", req(input$client_tz)))
}

shinyApp(ui, server)
```

Value conversion: JS number → numeric, string → character, array of scalars → vector, object → named list.

Source: `175-setInputValue`

Pitfalls:
- Shiny ignores a value identical to the last one sent. For click-like events pass `{priority: "event"}` so every call fires; `175` checks 5 identical event-priority sends fire 5 times, 5 identical normal sends fire once.
- `Shiny.setInputValue` does not exist until Shiny initialises. Code that runs at page load must be inside `$(document).on('shiny:connected', ...)`.
- Inside a module, the JS name must be namespaced: build the string in R with `session$ns("gene_clicked")` / `NS(id, "gene_clicked")`.

## R → JS: sendCustomMessage

Server pushes a JSON message; a JS handler registered under the same type acts on it (highlight elements, call a JS library, scroll, play a sound).

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  tags$style(".gene.active { background: gold; }"),
  tags$script(HTML("
    // JS: handler name must match the R `type`
    Shiny.addCustomMessageHandler('highlight', function(msg) {
      document.querySelectorAll('.gene').forEach(function(el) {
        el.classList.toggle('active', msg.genes.includes(el.dataset.gene));
      });
    });
  ")),
  checkboxGroupInput("pick", "Highlight", c("TP53", "BRCA1", "EGFR")),
  lapply(c("TP53", "BRCA1", "EGFR"), function(g) tags$span(class = "gene badge text-bg-light", `data-gene` = g, g))
)

server <- function(input, output, session) {
  # R: list() becomes a JS object; I() keeps a length-1 vector as an array
  observe(session$sendCustomMessage("highlight", list(genes = I(input$pick %||% character()))))
}

shinyApp(ui, server)
```

For one-liners without a handler file, `shinyjs::runjs("...")` (needs `shinyjs::useShinyjs()` in UI). Updating a custom *input* uses `session$sendInputMessage()` instead (see [Full custom input binding](#full-custom-input-binding)).

Source: `061-server-to-client-custom-messages`, `107-events` (`special` message)

Pitfalls:
- jsonlite unboxes length-1 vectors: `c("TP53")` arrives as `"TP53"` (string, not array) and `.includes` then matches substrings. Wrap vectors in `I()` or `as.list()`. `NULL` arrives as `{}`; send `character()` instead.
- Register the handler at top level (not inside an event) so it exists before the first message.

## Shiny JS events

jQuery events on `document` (or a specific element) at lifecycle points. Listen with `$(document).on('shiny:<event>', fn)`.

| Event | When | Useful fields / actions |
|---|---|---|
| `shiny:connected` | websocket open | safe to call `Shiny.setInputValue` |
| `shiny:disconnected` | session ended / network lost | show "reload" notice |
| `shiny:busy` / `shiny:idle` | server computing / done | custom spinners |
| `shiny:inputchanged` | before an input value is sent | `event.name`, `event.value` (editable); `preventDefault()` cancels |
| `shiny:message` | any server message arrives | `event.message` |
| `shiny:bound` / `shiny:unbound` | input/output bound | `event.binding.name`, `event.bindingType` |
| `shiny:updateinput` | `update*Input()` message received | `event.message` |
| `shiny:value` | output value arrives | `event.name`, `event.value` (editable) |
| `shiny:error` | output errors | `event.error.message` (editable) |
| `shiny:recalculating` / `shiny:recalculated` | output starts/finishes | per-output progress |
| `shiny:visualchange` | output resized/shown | |

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  tags$script(HTML("
    $(document).on('shiny:disconnected', function() {
      document.body.insertAdjacentHTML('afterbegin',
        '<div class=\"alert alert-danger\">Connection lost. Reload the page.</div>');
    });
    $(document).on('shiny:inputchanged', function(e) {
      if (e.name === 'sample_id') e.value = e.value.trim().toUpperCase();  // clean before R sees it
      if (e.name === 'locked') e.preventDefault();                         // never reaches R
    });
    $(document).on('shiny:recalculating', function(e) {
      if (e.target.id === 'summary') console.log('summary recomputing');
    });
  ")),
  textInput("sample_id", "Sample ID"),
  verbatimTextOutput("summary")
)

server <- function(input, output, session) {
  output$summary <- renderPrint(input$sample_id)
}

shinyApp(ui, server)
```

For busy indicators prefer built-in `useBusyIndicators()` (shiny >= 1.8) over hand-rolled `shiny:busy` modals.

Source: `107-events`

Pitfalls:
- Editing `event.value` in `shiny:inputchanged` affects only what R receives, not the widget display.

## Hook into an htmlwidget: onRender

`htmlwidgets::onRender(widget, jsCode, data)` runs JS after a widget (plotly, leaflet, DT via widget, visNetwork) renders; `el` is the container, `x` the widget data. Typical use: attach a widget event and forward it with `Shiny.setInputValue`.

```r
library(shiny)
library(bslib)
library(plotly)

ui <- page_fluid(card(plotlyOutput("p")), verbatimTextOutput("pt"))

server <- function(input, output, session) {
  output$p <- renderPlotly(
    plot_ly(mtcars, x = ~wt, y = ~mpg, type = "scatter", mode = "markers") |>
      htmlwidgets::onRender("
        function(el, x, data) {
          el.on('plotly_click', function(d) {
            Shiny.setInputValue(data.id, {x: d.points[0].x, y: d.points[0].y}, {priority: 'event'});
          });
          Plotly.relayout(el, {title: {text: data.title}});
        }", data = list(id = "pt_click", title = "Click a point"))
  )
  output$pt <- renderPrint(input$pt_click)
}

shinyApp(ui, server)
```

For plotly specifically, `event_data()` covers clicks without JS (see `plot-interaction.md`); `onRender` is for anything the R API lacks.

Source: `149-onRender`

Pitfalls:
- Pass R values through the `data` argument, not by `paste0()`-ing them into the JS string (quoting bugs, injection).
- The JS may be a function declaration, a parenthesised expression or a statement (`149` tests all three, needs htmlwidgets >= 1.4).

## Third-party head snippets (Google Analytics)

Vendor snippets (analytics, fonts, consent banners) go in `<head>` via `includeHTML()`. Track Shiny interactions by listening to Shiny events instead of generic DOM events.

`google-analytics.html`:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXX');
  $(document).on('shiny:inputchanged', function(e) {
    if (e.name === 'var') gtag('event', 'select_variable', {value: String(e.value)});
  });
</script>
```

```r
ui <- page_fluid(
  tags$head(includeHTML("google-analytics.html")),
  selectInput("var", "Display", c("sun_percent", "total_hours", "clear_days"))
)
```

Source: `181-google-analytics`

Pitfalls:
- `shiny:inputchanged` also fires for internal inputs (`.clientdata_*`); filter on `e.name`.
- Analytics on student/patient-facing apps may need consent under institutional privacy policy; do not ship the placeholder ID.

## Custom HTML page: htmlTemplate / www/index.html

Write the whole page in HTML and keep R for the server. Two forms:

1. `www/index.html` with only a server: `server.R` alone, or `shinyApp(ui = NULL, server)`. The page must load `shared/jquery.js` and `shared/shiny.js` itself.
2. `htmlTemplate("template.html", ...)` as `ui`: `{{ }}` placeholders evaluate R, so R widgets and dependencies can be mixed in. `{{ headContent() }}` injects Shiny's JS/CSS.

`template.html` (keep it outside `www/` so it is not also served raw):
```html
<!DOCTYPE html>
<html>
<head>{{ headContent() }}{{ bootstrapLib() }}</head>
<body class="container">
  <h1>HTML UI</h1>
  <label for="dist">Distribution</label>
  <select id="dist">
    <option value="norm">Normal</option>
    <option value="unif">Uniform</option>
  </select>
  {{ sliderInput("n", "Observations", 1, 1000, 500) }}
  <pre id="summary" class="shiny-text-output"></pre>
  <div id="plot" class="shiny-plot-output" style="width:100%;height:300px"></div>
  <div id="table" class="shiny-html-output"></div>
</body>
</html>
```

```r
library(shiny)

server <- function(input, output, session) {
  d <- reactive(switch(input$dist, norm = rnorm, unif = runif)(input$n))
  output$summary <- renderPrint(summary(d()))
  output$plot <- renderPlot(hist(d(), col = "#75AADB", border = "white"))
  output$table <- renderTable(head(data.frame(x = d())))
}

shinyApp(htmlTemplate("template.html"), server)
```

Output element classes: `shiny-text-output` (`renderText`/`renderPrint`), `shiny-html-output` (`renderUI`, `renderTable`), `shiny-plot-output`, `shiny-image-output`. Plain `<input>`/`<select>` with an `id` become inputs through Shiny's built-in bindings.

Source: `008-html` (`htmlTemplate("www/index.html")`), `154-index-html-server-r` (`server.R` + `www/index.html`), `155-index-html-app-r` (`shinyApp(NULL, server)` + `www/index.html`)

Pitfalls:
- A `www/index.html` is served as-is and overrides any `ui`; `{{ }}` is not evaluated there.
- Without `{{ headContent() }}` (or the manual `shared/*.js` tags) nothing is reactive.
- `bootstrapLib()` loads Bootstrap (bslib theme optional); without it R widgets render unstyled.

## Prerendered R Markdown

`runtime: shiny_prerendered` renders the document once and runs only `context="server"` chunks per session: faster start than `runtime: shiny`. `169-prerender-a` loads `js/log-rmd.js` from a folder beside `index.Rmd`.

````markdown
---
title: "Growth curve explorer"
output: html_document
runtime: shiny_prerendered
---

```{r, context="setup"}
library(shiny)
```

```{r}
tags$script(src = "js/log-rmd.js")
sliderInput("od", "OD600 threshold", 0, 2, 0.6)
textOutput("echo")
```

```{r, context="server"}
output$echo <- renderText(paste("Threshold:", input$od))
```
````

Source: `169-prerender-a` (Rmd + `js/`), `169-prerender-b` (equivalent `app.R` + `www/js/`)

Pitfalls:
- Server code in a chunk without `context="server"` runs at render time only; outputs stay empty.

## React component as an input: reactR

`reactR::createReactShinyInput()` turns a React component into a Shiny input; JS calls `props.setValue(v)`, R reads `input$<id>`. Bookmarking works.

`js/input.js` (plain `React.createElement`, no build step):
```js
(function() {
  function SimpleTextInput(props) {
    return React.createElement('input', {
      value: props.value,
      onChange: function(e) { props.setValue(e.target.value); }
    });
  }
  reactR.reactShinyInput('.simple-text-input', 'app.simpleText', SimpleTextInput);
})();
```

```r
library(shiny)
library(bslib)
library(reactR)

simpleTextInput <- function(inputId, default = "") {
  createReactShinyInput(
    inputId = inputId,
    class = "simple-text-input",
    dependencies = htmltools::htmlDependency(
      "simple-text-input", "1.0.0",
      src = c(file = normalizePath("js")), script = "input.js"
    ),
    default = default,
    container = tags$span
  )
}

ui <- function(request) {
  page_fluid(simpleTextInput("txt"), textOutput("echo"), bookmarkButton())
}

server <- function(input, output, session) {
  output$echo <- renderText(input$txt)
}

shinyApp(ui, server, enableBookmarking = "url")
```

Source: `151-reactr-input`

Pitfalls:
- The CSS class in R (`class =`) and the selector in `reactShinyInput('.simple-text-input', ...)` must match.
- Real React components (JSX, npm libs) need a bundler; `reactR::scaffoldReactShinyInput()` sets one up in a package.

## Full custom input binding

A `Shiny.InputBinding` makes any DOM widget a first-class input: value to R, `update*()` from R, rate limiting, bookmarking. Needs three parts: JS binding, R constructor, R updater.

`www/rating-binding.js`:
```js
(function() {
  var binding = new Shiny.InputBinding();
  $.extend(binding, {
    find: function(scope) { return $(scope).find('.rating-input'); },
    initialize: function(el) { this.setValue(el, Number(el.dataset.value)); },
    getValue: function(el) { return Number(el.dataset.value); },
    setValue: function(el, value) {
      el.dataset.value = value;
      $(el).children('span').each(function(i, s) { s.classList.toggle('on', i < value); });
    },
    subscribe: function(el, callback) {
      var self = this;
      $(el).on('click.ratingBinding', 'span', function() {
        self.setValue(el, $(this).index() + 1);
        $(el).trigger('change');
      });
      $(el).on('change.ratingBinding', function() { callback(false); });  // false = send now
    },
    unsubscribe: function(el) { $(el).off('.ratingBinding'); },
    receiveMessage: function(el, data) {          // from session$sendInputMessage()
      if (data.hasOwnProperty('value')) this.setValue(el, data.value);
      if (data.hasOwnProperty('label')) $('label[for="' + el.id + '"]').text(data.label);
      $(el).trigger('change');
    },
    getState: function(el) { return { value: this.getValue(el) }; }
  });
  Shiny.inputBindings.register(binding, 'app.ratingInput');
})();
```

```r
library(shiny)
library(bslib)

ratingInput <- function(inputId, label, value = 0, max = 5) {
  tagList(
    singleton(tags$head(
      tags$script(src = "rating-binding.js"),
      tags$style(".rating-input span{cursor:pointer;color:#ccc;font-size:1.5rem}
                  .rating-input span.on{color:#f5a623}")
    )),
    tags$label(label, `for` = inputId),
    div(id = inputId, class = "rating-input", `data-value` = value,
        lapply(seq_len(max), function(i) tags$span(HTML("&#9733;"))))
  )
}

updateRatingInput <- function(session, inputId, label = NULL, value = NULL) {
  msg <- list(label = label, value = value)
  session$sendInputMessage(inputId, msg[!vapply(msg, is.null, logical(1))])
}

ui <- page_fluid(
  ratingInput("quality", "Slide quality", value = 3),
  actionButton("reset", "Reset"),
  textOutput("val")
)

server <- function(input, output, session) {
  output$val <- renderText(paste("Rating:", input$quality))
  observeEvent(input$reset, updateRatingInput(session, "quality", value = 0))
}

shinyApp(ui, server)
```

Optional binding methods:
- `getRatePolicy: function() { return {policy: 'debounce', delay: 500}; }` then `callback(true)` in `subscribe` to apply it (text-like inputs, `035`).
- `getType: function() { return 'app.chooser'; }` plus an R-side converter, so R gets a clean structure (`036`):
  ```r
  registerInputHandler("app.chooser", function(data, ...) {
    if (is.null(data)) NULL else list(left = as.character(data$left), right = as.character(data$right))
  }, force = TRUE)
  ```

Source: `035-custom-input-bindings` (URL input with update + rate policy), `036-custom-input-control` (two-list chooser, `getType` + `registerInputHandler`)

Pitfalls:
- `find()` must match only your widget; a generic selector (`input[type="url"]` in `035`) also captures any other such element on the page.
- Namespace jQuery events (`click.ratingBinding`) so `unsubscribe` removes only yours.
- `036` uses Font Awesome 4 icon names (`arrow-circle-o-right`); current `icon()` needs FA6 names (`circle-arrow-right`).
- Prefer an existing package input (shinyWidgets, `bslib::input_switch`, sortable for drag lists) before writing a binding.

## R as a WebSocket client

The `websocket` package lets the *server* subscribe to an external WebSocket feed (instrument stream, lab sensor, message bus) and push updates into reactives. No browser JS involved.

```r
library(shiny)
library(bslib)
library(websocket)

ui <- page_fluid(
  textInput("msg", "Message"), actionButton("send", "Send"),
  textOutput("status"), tableOutput("log")
)

server <- function(input, output, session) {
  status <- reactiveVal("connecting")
  log <- reactiveVal(data.frame(time = character(), message = character()))

  ws <- WebSocket$new("wss://example.org/feed", autoConnect = FALSE)
  ws$onOpen(function(event) status("connected"))
  ws$onClose(function(event) status(paste("closed:", event$code)))
  ws$onError(function(event) status(paste("error:", event$message)))
  ws$onMessage(function(event) {
    log(rbind(data.frame(time = format(Sys.time()), message = event$data), isolate(log())))
  })
  ws$connect()
  session$onSessionEnded(function() ws$close())

  observeEvent(input$send, ws$send(input$msg))
  output$status <- renderText(status())
  output$log <- renderTable(log())
}

shinyApp(ui, server)
```

Source: `147-websocket`

Pitfalls:
- Callbacks run outside the reactive context. Setting a `reactiveVal` is fine; calls needing `session` (e.g. `shinyjs::toggleState`) must be wrapped in `withReactiveDomain(session, ...)` as `147` does.
- Use `isolate()` when reading reactives inside callbacks.
- `147` hardcodes `ws://echo.websocket.org` (service retired) and ignores the URL typed in its modal; supply your own endpoint.
- One connection per session; for a shared feed open it once at top level and fan out with a `reactivePoll`/`reactiveVal` in `global.R`.

## Example index

| Folder | Shows |
|---|---|
| `008-html` | Hand-written HTML page via `htmlTemplate("www/index.html")` |
| `035-custom-input-bindings` | URL input binding: `receiveMessage`, `getState`, rate policy, `updateUrlInput()` |
| `036-custom-input-control` | Chooser (two lists) binding, `getType` + `registerInputHandler` |
| `061-server-to-client-custom-messages` | `sendCustomMessage` → `addCustomMessageHandler` |
| `107-events` | Every `shiny:*` JS event, cancel/modify input and output values |
| `147-websocket` | R `websocket` client feeding reactives; `shinyjs` enable/disable |
| `149-onRender` | `htmlwidgets::onRender` on plotly |
| `151-reactr-input` | React component input with bookmarking |
| `154-index-html-server-r` | `server.R` + `www/index.html`, no UI file |
| `155-index-html-app-r` | `shinyApp(NULL, server)` + `www/index.html` |
| `169-prerender-a` | `runtime: shiny_prerendered` Rmd loading `js/` |
| `169-prerender-b` | Same script from `www/js/` in an `app.R` |
| `175-setInputValue` | `Shiny.setInputValue` priorities (`event`, `immediate`, `deferred`) |
| `181-google-analytics` | gtag snippet via `tags$head(includeHTML())` |
