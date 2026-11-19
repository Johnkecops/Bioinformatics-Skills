# Inputs: widgets, selectize, dates, deferred actions, updates, validation

Purpose: choose the right input widget, know what `input$id` will contain, change inputs from the server, defer work behind a button, and validate user entries. Covers all `inputs` examples in `catalog.md`.

Target versions: shiny 1.14, bslib 0.12. `shinyvalidate` is not installed here (`install.packages("shinyvalidate")`).

## Contents

- [Widget -> value -> update cheat sheet](#widget---value---update-cheat-sheet)
- [1. Basic widgets and what they return](#1-basic-widgets-and-what-they-return)
- [2. Sliders: single, range, step, format, animation](#2-sliders-single-range-step-format-animation)
- [3. selectInput vs selectizeInput: choices, prompts, multiple](#3-selectinput-vs-selectizeinput-choices-prompts-multiple)
- [4. Option groups](#4-option-groups)
- [5. Server-side selectize for large choice sets](#5-server-side-selectize-for-large-choice-sets)
- [6. Dates and date ranges](#6-dates-and-date-ranges)
- [7. File upload](#7-file-upload)
- [8. Defer work until a button click (replaces submitButton)](#8-defer-work-until-a-button-click-replaces-submitbutton)
- [9. Updating inputs from the server](#9-updating-inputs-from-the-server)
- [10. Labels: hidden, HTML, changed at runtime](#10-labels-hidden-html-changed-at-runtime)
- [11. Validation: shinyvalidate and validate(need())](#11-validation-shinyvalidate-and-validateneed)
- [12. Custom input binding with validation feedback](#12-custom-input-binding-with-validation-feedback)

## Widget -> value -> update cheat sheet

| Widget | `input$id` contains | Update function | Source |
|---|---|---|---|
| `actionButton()` / `actionLink()` | integer click count (class `shinyActionButtonValue`), 0 before first click | `updateActionButton()` / `updateActionLink()` | 068, 007, 081 |
| `checkboxInput()` | `TRUE`/`FALSE` | `updateCheckboxInput()` | 070, 081 |
| `checkboxGroupInput()` | character vector of selected values; `NULL` when none ticked | `updateCheckboxGroupInput()` | 069, 081, 184 |
| `radioButtons()` | character (one value) | `updateRadioButtons()` | 075, 081 |
| `selectInput()` | character; character vector if `multiple = TRUE`; `""` for an empty prompt | `updateSelectInput()` | 076, 017, 160, 163 |
| `selectizeInput()` | as `selectInput()`; `NULL` when multiple and empty | `updateSelectizeInput()` | 013, 021, 023, 024, 140 |
| `varSelectInput()` / `varSelectizeInput()` | a **symbol** (column name); use with `!!input$id` or `.data[[input$id]]` | `updateVarSelectInput()` / `updateVarSelectizeInput()` | 158 |
| `numericInput()` | numeric; `NA` when the box is cleared | `updateNumericInput()` | 074, 007, 065 |
| `sliderInput()` | numeric (length 1), or length 2 for a range; `Date`/`POSIXct` if `value` is a date/time | `updateSliderInput()` | 005, 077, 078 |
| `textInput()` | character, `""` when empty | `updateTextInput()` | 080, 183 |
| `textAreaInput()` | character | `updateTextAreaInput()` | 158 |
| `passwordInput()` | character | `updateTextInput()` (no dedicated updater) | 158 |
| `dateInput()` | `Date` (length 1); `NULL`/`character(0)` when cleared | `updateDateInput()` | 071, 037, 157, 170 |
| `dateRangeInput()` | `Date` vector length 2 (start, end), either may be `NA` | `updateDateRangeInput()` | 072, 037, 157 |
| `fileInput()` | `NULL` until upload, then data.frame: `name`, `size`, `type`, `datapath` (one row per file) | none (reset by re-rendering) | 073, 185 |
| `submitButton()` | no input value; holds back **all** inputs | none | 062, 079 (avoid, see section 8) |
| `bslib::input_switch()` | `TRUE`/`FALSE` | `bslib::update_switch()` | not in examples |
| `tabsetPanel(id = )` | title/value of active tab | `updateTabsetPanel()` | 065 |

Inspect any value while developing: `output$dbg <- renderPrint(str(input$id))` with `verbatimTextOutput("dbg")` (the pattern used throughout 068-081 and 017).

## 1. Basic widgets and what they return

One `xxxInput(inputId, label, ...)` per control; read with `input$inputId` inside a reactive context. The 081 gallery is the teaching page: each widget beside `renderPrint()` of its value.

```r
library(shiny)
ui <- fluidPage(
  checkboxInput("log_scale", "Log scale", value = TRUE),
  checkboxGroupInput("genes", "Genes",
                     choices = c("TP53", "BRCA1", "EGFR"), selected = "TP53"),
  radioButtons("test", "Test", choices = c("t-test" = "t", "Wilcoxon" = "w")),
  numericInput("n", "Sample size", value = 10, min = 1, max = 500, step = 1),
  textInput("title", "Plot title", placeholder = "Enter text..."),
  verbatimTextOutput("dbg")
)
server <- function(input, output, session) {
  output$dbg <- renderPrint(str(reactiveValuesToList(input)))
}
shinyApp(ui, server)
```

Source: 068-widget-action-button, 069-widget-check-group, 070-widget-checkbox, 074-widget-numeric, 075-widget-radio, 076-widget-select, 080-widget-text, 081-widgets-gallery, 007-widgets.

Pitfalls:
- `choices = list("Choice 1" = 1, ...)` (069, 075, 076) still returns `"1"` as **character**. Convert with `as.numeric(input$select)`.
- Named choices: the name is the label shown, the value is what `input$id` returns.
- `numericInput` does not enforce `min`/`max` on typed values; check them in the server (`req()`, `validate()`).
- `checkboxGroupInput` with nothing ticked gives `NULL`, not `character(0)`; guard with `req(input$genes)` or `length()`.

## 2. Sliders: single, range, step, format, animation

`value` of length 2 makes a range slider. `step`, `pre`/`post`, `sep` format the display; `animate` adds a play button (useful for time series).

```r
sliderInput("integer", "Integer:", min = 0, max = 1000, value = 500)
sliderInput("decimal", "Decimal:", min = 0, max = 1, value = 0.5, step = 0.1)
sliderInput("range", "Range:", min = 1, max = 1000, value = c(200, 500))
sliderInput("format", "Custom format:", min = 0, max = 10000, value = 0,
            step = 2500, pre = "$", sep = ",", animate = TRUE)
sliderInput("anim", "Looping animation:", min = 1, max = 2000, value = 1, step = 10,
            animate = animationOptions(interval = 300, loop = TRUE))
```

Source: 005-sliders, 077-widget-slider, 078-widget-slider-range.

Pitfalls:
- Range value is `c(low, high)`; use `input$range[1]`, `input$range[2]`.
- `pre`/`post`/`sep` only change the display; `input$format` is still plain numeric.
- `updateSliderInput(value = c(NA, 10))` keeps the low end and moves only the high end (065).

## 3. selectInput vs selectizeInput: choices, prompts, multiple

`selectInput()` uses selectize.js by default; `selectize = FALSE` gives a plain browser `<select>`. `selectizeInput()` exposes selectize `options` (create, maxItems, placeholder, ...).

```r
# Empty "choose" prompt: lets the user clear the selection; value is "" until chosen
selectInput("state", "State", choices = c(Choose = "", state.name))

# Multiple selection; value is NULL when empty
selectInput("states", "States", choices = state.name, multiple = TRUE)

# Named vector: label shown, value returned
selectInput("var", "Variable:",
            c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear"))

# selectize options
selectizeInput("e3", "Allow new items", choices = state.name,
               options = list(create = TRUE))
selectizeInput("e5", "At most two", choices = state.name, multiple = TRUE,
               options = list(maxItems = 2))
selectizeInput("e6", "Placeholder", choices = c("", state.name),
               options = list(placeholder = "Please select an option below"))

# Factor choices: labels from names, values from levels (shiny >= 1.4)
selectInput("letter", "Letters", choices = factor(setNames(letters, LETTERS)))
```

Source: 013-selectize, 017-select-vs-selectize, 076-widget-select, 160-select-input, 163-select-factor.

Pitfalls:
- Always **character**, even for numeric choices: `selectInput("k", "k", 1:5)` gives `"3"`; use `as.integer(input$k)`.
- Without a `""` prompt, a single select always has a value (first choice); the selectize version cannot be cleared (017).
- Placeholder only shows when the current value is empty: put `""` in `choices` (or `selected = ""`); 013 used `onInitialize = I('function() { this.setValue(""); }')`, which still works but is unnecessary.
- `selectInput` ignores `""` as a real option (013 example e7); use the prompt idiom above.
- Factor choices (163): `input$letter` returns the level as character (`"a"`), the label is the name (`"A"`). Unnamed factors use levels for both. Do not rely on integer codes.
- The 013 GitHub "remote load" demo calls a retired GitHub API; treat `options = list(load = I("function(query, callback) {...}"))` as the pattern only.

## 4. Option groups

A named list of lists in `choices` produces `<optgroup>` headers; works for both `selectInput` and `selectizeInput`, and in `update*`.

```r
selectizeInput("x1", "Region", multiple = TRUE, choices = list(
  Eastern = list(`New York` = "NY", `New Jersey` = "NJ"),
  Western = list(California = "CA", Washington = "WA")
))
```

Server-filled groups (024):

```r
library(shiny)
ui <- fluidPage(selectizeInput("x2", "X2", choices = NULL))
server <- function(input, output, session) {
  updateSelectizeInput(session, "x2", selected = "IA", choices = list(
    Eastern = list(`Rhode Island` = "RI", `New Jersey` = "NJ"),
    Middle  = list(Iowa = "IA")
  ))
}
shinyApp(ui, server)
```

Source: 024-optgroup-selectize, 023-optgroup-server, 140-selectize-inputs.

Pitfalls:
- A group needs a **named** outer list; an inner element `list(3)` without a name is not grouped (140 tests this).
- Single-element group: `Middle = list(Iowa = "IA")` is a group; `Middle = "IA"` is a plain option labelled "Middle".

## 5. Server-side selectize for large choice sets

`updateSelectizeInput(..., server = TRUE)` keeps choices in R and sends only matches as the user types. Use for gene lists, sample IDs, anything over ~1000 options. Choices may be a vector, list, or data.frame (with `value`, `label`, and extra columns for search/render/optgroups).

```r
library(shiny)
genes <- paste0("GENE", 1:20000)
ui <- fluidPage(
  selectizeInput("gene", "Gene", choices = NULL,
                 options = list(placeholder = "Type a gene symbol", maxOptions = 50)),
  textOutput("picked")
)
server <- function(input, output, session) {
  updateSelectizeInput(session, "gene", choices = genes, server = TRUE)
  output$picked <- renderText({
    req(input$gene)
    paste("Selected:", input$gene)
  })
}
shinyApp(ui, server)
```

Data frame choices with optgroups, extra search fields, and custom JS rendering (023):

```r
library(shiny)
titanic <- as.data.frame(Titanic, stringsAsFactors = FALSE)
titanic$value <- seq_len(nrow(titanic))
titanic$label <- apply(titanic[, 2:4], 1, paste, collapse = ", ")
ui <- fluidPage(
  selectizeInput("group", NULL, NULL, multiple = TRUE, options = list(
    placeholder = "Select a category",
    optgroupField = "Class",
    optgroups = list(list(value = "1st", label = "First Class"),
                     list(value = "Crew", label = "Crew")),
    searchField = c("Sex", "Age", "Survived"),
    render = I("{ option: function(item, escape) {
      return '<div>' + escape(item.label) + '</div>'; } }")
  )),
  verbatimTextOutput("row")
)
server <- function(input, output, session) {
  updateSelectizeInput(session, "group", choices = titanic, server = TRUE)
  output$row <- renderPrint({
    validate(need(input$group, "Please type and search (e.g. Female)"))
    titanic[as.integer(input$group), 1:5]
  })
}
shinyApp(ui, server)
```

Source: 140-selectize-inputs, 023-optgroup-server, 021-selectize-plot.

Pitfalls:
- Start with `choices = NULL` in the UI; fill in the server.
- With a data.frame, `input$id` is the `value` column as **character**; convert before indexing.
- `I("...")` marks a string as raw JavaScript; without `I()` it is sent as a string.
- 021 renders map images inside options via `session$registerDataObj()` and the internal `shiny:::httpResponse()`. Advanced and relies on internals; do not copy for teaching.

## 6. Dates and date ranges

`dateInput()` and `dateRangeInput()` return `Date` objects. `value`/`start`/`end`/`min`/`max` accept `Date` or `"yyyy-mm-dd"` strings. `format` only controls display.

```r
dateInput("date", "Sampling date", value = Sys.Date(),
          min = Sys.Date() - 5, max = Sys.Date() + 5,
          format = "dd/mm/yy", startview = "year", weekstart = 1, language = "en")
dateRangeInput("period", "Study period",
               start = Sys.Date() - 30, end = Sys.Date(),
               min = "2020-01-01", max = Sys.Date(),
               separator = " to ", format = "yyyy-mm-dd")
```

Server use:

```r
library(shiny)
server <- function(input, output, session) {
  output$txt <- renderText({
    req(input$period)
    paste(format(input$period, "%d %b %Y"), collapse = " to ")
  })
}
```

Source: 037-date-and-date-range, 071-widget-date, 072-widget-date-range, 157-date-format, 170-date-range-max.

Pitfalls:
- `format` (display, bootstrap-datepicker syntax `dd/mm/yy`) differs from `value` (always ISO `yyyy-mm-dd` or `Date`). Passing `value = "01/02/2024"` is a mis-specified date: shiny warns and drops it (157).
- `paste()`/`cat()` on a Date inside `renderText` is fine, but `c()` with numbers coerces to integer days; use `as.character()` or `format()` (037 comment).
- `dateRangeInput` start/end can be `NA` if the user clears one box; guard with `req(all(!is.na(input$period)))`.
- `max = Sys.Date()` with no `value` must still produce a value (170 regression test); fine in shiny 1.14.
- `language` takes datepicker codes (`"fr"`, `"zh-TW"`, `"id"` for Indonesian).

## 7. File upload

```r
library(shiny)
ui <- fluidPage(
  fileInput("file", "Upload CSV", accept = c(".csv", "text/csv"), multiple = FALSE),
  tableOutput("head")
)
server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    ext <- tools::file_ext(input$file$name)
    validate(need(ext == "csv", "Please upload a .csv file"))
    read.csv(input$file$datapath)
  })
  output$head <- renderTable(head(data()))
}
shinyApp(ui, server)
```

Source: 073-widget-file, 081-widgets-gallery, 185-sv-custom-inputs.

Pitfalls:
- Read from `datapath` (a temp file), not `name` (original filename, only useful for extension checks).
- `accept` is a browser hint only; re-check the extension on the server.
- Default upload limit is 5 MB: `options(shiny.maxRequestSize = 50 * 1024^2)` before `shinyApp()`.

## 8. Defer work until a button click (replaces submitButton)

`submitButton()` (062, 079) freezes **every** input on the page until clicked and cannot be partially applied; shiny docs discourage it. Use `actionButton()` and tie only the expensive output to the click.

Modern (`bindEvent`, shiny >= 1.6):

```r
library(shiny)
ui <- fluidPage(
  selectInput("dataset", "Dataset", c("rock", "pressure", "cars")),
  numericInput("obs", "Rows to view", 10),
  actionButton("update", "Update view", class = "btn-primary"),
  verbatimTextOutput("summary"),
  tableOutput("view")
)
server <- function(input, output, session) {
  dataset <- reactive(get(input$dataset, "package:datasets")) |>
    bindEvent(input$update, ignoreNULL = FALSE)   # ignoreNULL = FALSE: run once at start
  output$summary <- renderPrint(summary(dataset()))
  output$view <- renderTable(head(dataset(), n = input$obs)) |>
    bindEvent(input$update, ignoreNULL = FALSE)
}
shinyApp(ui, server)
```

Equivalent older idioms (007): `eventReactive(input$update, {...}, ignoreNULL = FALSE)` for values; `observeEvent(input$go, {...})` for side effects; `isolate(input$obs)` to read without depending.

```r
library(shiny)
server <- function(input, output, session) {
  dataset <- eventReactive(input$update, {
    get(input$dataset, "package:datasets")
  }, ignoreNULL = FALSE)
  observeEvent(input$update, showNotification("Updated"))
  output$view <- renderTable(head(dataset(), n = isolate(input$obs)))
}
```

Source: 007-widgets, 062-submitbutton-demo, 079-widget-submit, 068-widget-action-button.

Pitfalls:
- Button value 0 counts as "NULL" for `ignoreNULL`; default `TRUE` means nothing renders until the first click.
- In 007, `head(..., isolate(input$obs))` still re-runs when `dataset()` changes; with `bindEvent` on the render, `obs` changes wait for the click too.
- Never mix `submitButton` with `actionButton` on one page.

## 9. Updating inputs from the server

Every `xxxInput` has an `updateXxx(session, inputId, ...)`; arguments not supplied are left unchanged. Typical use: dependent dropdowns (choices of B depend on A), reset buttons, syncing two controls.

```r
library(shiny)
ui <- fluidPage(
  selectInput("dataset", "Dataset", c("iris", "mtcars")),
  selectInput("column", "Column", choices = NULL),
  sliderInput("rng", "Range", min = 0, max = 1, value = c(0, 1))
)
server <- function(input, output, session) {
  observe({
    df <- get(input$dataset, "package:datasets")
    num <- names(df)[vapply(df, is.numeric, logical(1))]
    updateSelectInput(session, "column", choices = num, selected = num[1])
  }) |> bindEvent(input$dataset)

  observe({
    req(input$column)
    x <- get(input$dataset, "package:datasets")[[input$column]]
    updateSliderInput(session, "rng", min = min(x), max = max(x),
                      value = range(x))
  }) |> bindEvent(input$column)
}
shinyApp(ui, server)
```

Update calls from 065 (all widget types, driven by one slider):

```r
updateTextInput(session, "inText", label = "New label", value = "New text")
updateNumericInput(session, "inNumber2", value = 5, min = 0, max = 10, step = 5)
updateSliderInput(session, "inSlider2", value = c(4, 6))
updateDateInput(session, "inDate", value = "2013-04-15")
updateDateRangeInput(session, "inDateRange", start = "2013-01-15", end = "2013-12-15")
updateCheckboxInput(session, "inCheckbox", value = TRUE)
updateCheckboxGroupInput(session, "inCheckboxGroup",
                         choices = c("label A" = "a", "label B" = "b"), selected = "a")
updateRadioButtons(session, "inRadio", choices = c("A" = "a", "B" = "b"), selected = "b")
updateSelectInput(session, "inSelect", choices = c("A" = "a", "B" = "b"), selected = "a")
updateTabsetPanel(session, "inTabset", selected = "panel2")
```

Clearing values (184 reset form):

```r
updateTextInput(session, "name", value = "")
updateCheckboxGroupInput(session, "topics", selected = character(0))
updateCheckboxInput(session, "accept_terms", value = FALSE)
```

Source: 065-update-input-demo, 158-input-labels, 184-sv-deferred, 024-optgroup-selectize, 140-selectize-inputs.

Pitfalls:
- `session` may be omitted in shiny >= 1.6 if `inputId` is named: `updateTextInput(inputId = "x", value = "")`. Passing the ID positionally without `session` (`updateTextInput("x", ...)`) binds it to `session` and errors.
- Updates are sent after the current reactive flush; reading `input$x` right after `updateXxx()` in the same observer returns the old value.
- To clear a checkbox group or multi-select use `selected = character(0)`; `selected = NULL` means "leave unchanged".
- Two inputs updating each other loop forever; break the cycle with `bindEvent(..., ignoreInit = TRUE)` or a guard on equality.
- `clientData` as the 3rd server argument (065) is legacy; use `session$clientData`.

## 10. Labels: hidden, HTML, changed at runtime

`label = NULL` omits the label element (compact dashboards, table cells). Plain strings are HTML-escaped; wrap with `HTML()` or use tags for markup. `updateXxx(label = character(0))` removes a label; a string adds/replaces it.

```r
textInput("q", label = NULL, placeholder = "Search")
numericInput("dose", label = HTML("Dose (&micro;g/mL)"), value = 1)
checkboxInput("agree", label = strong("I accept the terms *"))
dateInput("d", label = h3("Date input"), value = "2014-01-01")
```

Source: 158-input-labels, 184-sv-deferred, 071-widget-date.

Pitfalls:
- `"An <i>escaped</i> Label"` as a plain string shows the literal `<i>` tags (158 checks this).
- For accessibility, prefer a short visible label over `label = NULL` unless a header already names the control.

## 11. Validation: shinyvalidate and validate(need())

Base shiny (no extra package): `req()` silently stops; `validate(need(cond, msg))` stops and shows `msg` in place of the output.

```r
library(shiny)
ui <- fluidPage(
  textInput("email", "Email"),
  numericInput("n", "n (2-500)", 10),
  textOutput("out")
)
server <- function(input, output, session) {
  output$out <- renderText({
    validate(
      need(nzchar(input$email), "Email is required"),
      need(grepl("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", input$email),
           "Please enter a valid email"),
      need(!is.na(input$n) && input$n >= 2 && input$n <= 500, "n must be 2-500")
    )
    paste("OK:", input$email, input$n)
  })
}
shinyApp(ui, server)
```

shinyvalidate (CRAN; `install.packages("shinyvalidate")`) puts red messages **under the input itself** and gives one `is_valid()` flag for the whole form.

Immediate feedback (183):

```r
library(shiny)
library(shinyvalidate)
ui <- fluidPage(textInput("name", "Name"), textInput("email", "Email"),
                textOutput("greeting"))
server <- function(input, output, session) {
  iv <- InputValidator$new()
  iv$add_rule("name", sv_required())
  iv$add_rule("email", sv_required())
  iv$add_rule("email", sv_email())
  iv$enable()                              # show feedback from the start
  output$greeting <- renderText({
    req(iv$is_valid())
    paste0("Nice to meet you, ", input$name, " <", input$email, ">!")
  })
}
shinyApp(ui, server)
```

Deferred until Submit (184), with formula rules and conditional sub-validators (185):

```r
library(shiny)
library(shinyvalidate)
server <- function(input, output, session) {
  iv <- InputValidator$new()
  iv$add_rule("topics", ~ if (length(.) < 2) "Please choose two or more topics")
  iv$add_rule("accept_terms", ~ if (!isTRUE(.)) "The terms must be accepted")

  upload_iv <- InputValidator$new()
  upload_iv$add_rule("upload", sv_required("Please choose a file"))
  upload_iv$add_rule("upload", function(f) {
    if (!tolower(tools::file_ext(f$name)) %in% c("jpg", "jpeg", "png"))
      "A JPEG or PNG file is required"
  })
  upload_iv$condition(~ input$type == "upload")   # only checked when relevant
  iv$add_validator(upload_iv)

  observe({
    if (iv$is_valid()) {
      showModal(modalDialog("Your submission has been accepted!"))
      iv$disable()
    } else {
      iv$enable()                                  # start showing messages now
      showNotification("Please correct the errors", type = "error")
    }
  }) |> bindEvent(input$submit)
}
```

Other built-in rules: `sv_optional()`, `sv_integer()`, `sv_numeric()`, `sv_between(left, right)`, `sv_gt()`/`sv_gte()`/`sv_lt()`/`sv_lte()`, `sv_in_set()`, `sv_regex(pattern, message)`, `sv_url()`.

Source: 183-sv-simple, 184-sv-deferred, 185-sv-custom-inputs.

Pitfalls:
- A rule returns `NULL` for valid, a character message for invalid.
- Must-tick checkbox: pair `sv_required()` with an `isTRUE()` rule as 184 does; do not rely on `sv_required()` alone to reject `FALSE`.
- Rules do nothing to outputs on their own: gate outputs/actions with `req(iv$is_valid())` or `if (iv$is_valid())`.
- 183/184 `library(markdown)` is unused leftover; drop it.
- Prefer base `validate(need())` in course material when you cannot install packages.

## 12. Custom input binding with validation feedback

A custom input = R function returning tags with a CSS class + a JS `Shiny.InputBinding` (`find`, `getValue`, `subscribe`, optional `getType`) + optional `registerInputHandler()` to convert the raw value in R. Adding `setInvalid(el, data)` / `clearInvalid(el)` to the binding lets shinyvalidate draw messages inside the widget.

```r
library(shiny)
my_input <- function(inputId, label) {
  tagList(
    tags$label(`for` = inputId, label),
    div(id = inputId, class = "my-input", tags$span(class = "feedback-message")),
    singleton(tags$head(tags$script(src = "my_input.js")))  # file in www/
  )
}
registerInputHandler("my-type", function(value, session, name) {
  if (is.null(value)) NULL else toupper(value)
}, force = TRUE)
```

```js
// www/my_input.js
var b = new Shiny.InputBinding();
$.extend(b, {
  find: function(scope) { return $(scope).find(".my-input"); },
  getType: function() { return "my-type"; },        // matches registerInputHandler
  getValue: function(el) { return el.dataset.value || null; },
  subscribe: function(el, cb) { $(el).on("change.b", function() { cb(); }); },
  unsubscribe: function(el) { $(el).off(".b"); },
  setInvalid: function(el, data) { el.querySelector(".feedback-message").innerText = data.message; },
  clearInvalid: function(el) { el.querySelector(".feedback-message").innerText = ""; }
});
Shiny.inputBindings.register(b);
```

Source: 185-sv-custom-inputs (`R/camera_input.R`, `www/camera_input.js`: webcam capture returning PNG bytes).

Pitfalls:
- R files in `R/` next to `app.R` are auto-sourced (shiny >= 1.5); `www/` is served at the app root.
- The camera example needs a browser with camera permission; does not work in the RStudio viewer.
- For a ready-made widget, check existing packages (`shinyWidgets`, `bslib::input_switch`) before writing a binding.
