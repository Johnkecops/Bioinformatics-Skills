# Full dashboards: assembly reference

How the 13 complete apps in `assets/examples/` fit inputs, shared reactive data, outputs, layout and data loading together. Use them as wiring diagrams. Most of their idioms date from 2013-2020; each section names the modern replacement.

## Contents
- [Summary table](#summary-table)
- [040 dynamic-clustering](#040-dynamic-clustering)
- [050 kmeans-example](#050-kmeans-example)
- [051 movie-explorer](#051-movie-explorer)
- [060 retirement-simulation](#060-retirement-simulation)
- [063 superzip-example](#063-superzip-example)
- [064 telephones-by-region](#064-telephones-by-region)
- [086 bus-dashboard](#086-bus-dashboard)
- [087 crandash](#087-crandash)
- [120 goog-index](#120-goog-index)
- [141 radiant](#141-radiant)
- [146 ames-explorer](#146-ames-explorer)
- [500 movie-browser / 501 movie-browser-nav](#500-movie-browser--501-movie-browser-nav)
- [Assembly rules distilled from these apps](#assembly-rules-distilled-from-these-apps)

## Summary table

| app | what it is | layout | key features | packages | legacy issues |
|---|---|---|---|---|---|
| 040 | Click on a plot to add points, then Gaussian-mixture clustering | `fluidPage` + `fluidRow`s | `plotOutput(click=)`, `reactiveValues` accumulator, clear button, `tryCatch` fallback plot | mclust | `observe`+`isolate` instead of `observeEvent`; `tryCatch` instead of `validate()` |
| 050 | k-means on iris | `pageWithSidebar` | chained reactives (`selectedData` -> `clusters`) | base | `pageWithSidebar`/`headerPanel` are superseded |
| 051 | Movie explorer with filters over a SQLite DB | `fluidPage`, `column(3)` controls + `column(9)` plot | one filtered reactive shared by plot + count; lazy dbplyr query; hover tooltip; `global.R` for shared choices | ggvis, dplyr, dbplyr, RSQLite | ggvis is unmaintained; `src_sqlite()` is defunct; DB removed (see DATA-REMOVED.txt) |
| 060 | Two-scenario Monte Carlo retirement simulation | `fluidPage` + `fluidRow`/`column(6)` side-by-side, CSS theme in `www/` | prefixed input-ID factory `renderInputs(prefix)`; recalc button read for its dependency | base | hand-rolled ID prefixes (use modules); local `simplex.min.css` (use bslib bootswatch); every slider move reruns the simulation |
| 063 | SuperZIP: full-screen map with floating controls + data explorer tab | `navbarPage`, `absolutePanel` over `leafletOutput`, custom CSS/JS | `leafletProxy` redraws, `input$map_bounds` drives plots, cascading selectize, table-to-map jump via custom JS input | leaflet, DT, dplyr, lattice, RColorBrewer, scales | `Shiny.onInputChange`; `DT::dataTableAjax`; `observe`+`isolate`; Bootstrap 3 `panel` classes; data removed |
| 064 | Bar plot of one column of `WorldPhones` | `fluidPage` + `sidebarLayout` | single input -> single render | datasets | none worth noting |
| 086 | Live Twin Cities bus map | `shinydashboard` with sidebar disabled, `box(width=NULL)` columns | polling with `invalidateLater` + manual refresh button; memoised download cache; `renderUI` select | shinydashboard, leaflet, dplyr, memoise, cachem, gtfstools, RProtoBuf, purrr | shinydashboard (use bslib); whole map rerendered each poll (use `leafletProxy`); thunderforest tiles need an API key now |
| 087 | Streaming CRAN download dashboard | `shinydashboard` with `sidebarMenu`/`tabItems`, `valueBox`es | socket stream polled each second; accumulators over time; bloom filter; CSV download | shinydashboard, shinySignals, bubbles, dplyr, digest, bit | shinySignals and bubbles are GitHub-only and dead; demo socket server is gone; FA4 icon names; counting bug (see Anatomy) |
| 120 | Google Trends line plot with optional lowess | `fluidPage(theme = shinytheme())` + `sidebarLayout` | `req()` + `validate(need())` on date range; `conditionalPanel`; animated slider | shinythemes, dplyr, readr | shinythemes (use `bslib::bs_theme(bootswatch=)`) |
| 141 | Launcher for the radiant analytics app | none (delegates) | `shinyAppDir(system.file("app", package="radiant"))` | radiant | none; it contains no app code |
| 146 | Ames housing explorer with linked brushing across two plots and a table | `fluidPage`, 3-6-3 columns + full-width table | modules returning lists of reactives; shared brush id across two plots; DT filter rows fed back to plot labels | shiny, dplyr, ggplot2, ggrepel, DT, AmesHousing, scales, rlang | `callModule` (use `moduleServer`); `guide = FALSE`; `one_of()`; circular reactive wiring |
| 500 | Movie browser: plot / summary / table tabs | `sidebarLayout` + `tabsetPanel` | one filtered reactive shared by three outputs | tidyverse, DT | `load()` called twice (top level and per session) |
| 501 | Same as 500 with `navlistPanel` | `sidebarLayout` + `navlistPanel` | same | tidyverse, DT | downloads the data on every session; two identical reactives |

---

## 040 dynamic-clustering

**Files:** `ui.R`, `server.R`. No data; points come from clicks.

**Reactive graph:** `input$clusterClick` -> observer appends to `val$x, val$y` (`reactiveValues`) -> `output$numPoints`, `output$clusterPlot` (Mclust fit + plot). `input$clear` -> observer empties `val`.

**Copy:**
- `reactiveValues` as a per-session store that user events add to (event log, annotation list, clicked points).
- `plotOutput(click = "id")` turns a plot into an input.

**Dated -> modern:**
- `observe({ if (is.null(input$x)) return(); isolate(...) })` -> `observeEvent(input$clusterClick, {...})`. `observe({ if (input$clear > 0) ... })` -> `observeEvent(input$clear, ...)`.
- `tryCatch(..., error = function(e) fallback plot)` hides real errors. Use `validate(need(length(val$x) > 1, "Click to add at least 2 points"))`.
- Layout puts `mainPanel`/`sidebarPanel` in a bare `fluidRow`, which works only by accident of their column widths. Use `layout_columns()` or `column()`.

```r
server <- function(input, output, session) {
  val <- reactiveValues(x = NULL, y = NULL)
  observeEvent(input$clusterClick, {
    val$x <- c(val$x, input$clusterClick$x)
    val$y <- c(val$y, input$clusterClick$y)
  })
  observeEvent(input$clear, { val$x <- NULL; val$y <- NULL })
  output$clusterPlot <- renderPlot({
    validate(need(length(val$x) > 1, "Click to add at least 2 points"))
    fit <- mclust::Mclust(cbind(val$x, val$y))
    mclust::mclust2Dplot(cbind(val$x, val$y), what = "classification",
                         classification = fit$classification)
  })
}
```

## 050 kmeans-example

**Files:** `ui.R`, `server.R`. Data: built-in `iris`. `vars` computed at the top of `ui.R`.

**Reactive graph:** `xcol, ycol` -> `selectedData()` -> `clusters()` (kmeans on `selectedData()` + `input$clusters`) -> `plot1`.

**Copy:** split data selection and modelling into two chained reactives, so changing only `clusters` reruns kmeans without re-subsetting, and later outputs (a centres table, say) can share `clusters()`.

**Dated -> modern:** `pageWithSidebar(headerPanel(), sidebarPanel(), mainPanel())` -> `bslib::page_sidebar(title=, sidebar = sidebar(...), card(plotOutput(...)))`. `palette()` changes global graphics state; pass colours directly.

## 051 movie-explorer

**Files:** `global.R` (`axis_vars` named vector used by `ui.R` and `server.R`), `ui.R`, `server.R`, `.Renviron` (`LANG=C.UTF-8`), `movies.db` (removed, 13 MB SQLite).

**Data loading:** top of `server.R`, outside `function(input, output, session)`: open the DB once, build a lazy `all_movies` query (join + filter + select). No rows load at startup; each session's reactive adds filters and collects with `as.data.frame()`, so SQLite does the filtering.

**Reactive graph:** 6 sliders/selects + 2 text boxes -> `movies()` (lazy query -> collect -> add `has_oscar` column) -> `vis()` (ggvis, also reads `xvar`, `yvar`) -> `plot1`; `movies()` -> `n_movies`. Tooltip function reads `isolate(movies())` to look up the hovered `ID`.

**Copy:**
- One filtered-data reactive feeding every output; the record count text is a free sanity check.
- Optional filters added conditionally (`if (input$genre != "All") m <- filter(m, ...)`), so an empty text box means "no filter".
- `global.R` holds the label -> column map that both the select choices and axis titles need.
- Copy inputs to local variables before a dbplyr `filter()` (the comment cites dplyr #318). Still a safe habit; `.env$` or `!!` also work.

**Dated -> modern:**
- `src_sqlite("movies.db")` is defunct -> `con <- DBI::dbConnect(RSQLite::SQLite(), "movies.db")`; `tbl(con, "omdb")`; close it with `onStop(function() DBI::dbDisconnect(con))`.
- ggvis (`ggvisOutput`, `bind_shiny`, `add_tooltip`) -> plotly: `plotly::renderPlotly()` with `text =` aesthetic for hover, or ggplot2 + `plotOutput(hover=)`.
- `ui.R` redefines `actionLink()` (shadows Shiny's own, and never used). Delete it.
- `%like%` only works because dbplyr passes unknown infix operators through to SQL. On an in-memory data frame use `grepl(x, col, fixed = TRUE)`.

```r
library(shiny); library(dplyr)
con <- DBI::dbConnect(RSQLite::SQLite(), "movies.db")
onStop(function() DBI::dbDisconnect(con))
all_movies <- tbl(con, "omdb") |> inner_join(tbl(con, "tomatoes"), by = "ID")

server <- function(input, output, session) {
  movies <- reactive({
    min_rev <- input$reviews
    m <- all_movies |> filter(Reviews >= min_rev)
    if (input$genre != "All") {
      pat <- paste0("%", input$genre, "%")
      m <- m |> filter(Genre %like% pat)
    }
    collect(m)
  })
  output$plot1 <- plotly::renderPlotly({
    m <- movies()
    plotly::plot_ly(x = m[[input$xvar]], y = m[[input$yvar]], text = m$Title,
                    type = "scatter", mode = "markers")
  })
  output$n_movies <- renderText(nrow(movies()))
}
```

## 060 retirement-simulation

**Files:** `ui.r`, `server.r` (lowercase `.r` works), `www/simplex.min.css` (served at `/simplex.min.css`, used via `fluidPage(theme = "simplex.min.css")`).

**Data loading:** none; `simulate_nav()` and `plot_nav()` are defined at the top of `server.r`, outside the server function.

**Reactive graph:** `a_*` sliders + `a_recalc` -> `navA()` -> `a_distPlot`; same for `b_*`. `getParams(prefix)` reads `input[[paste0(prefix, "_recalc")]]` purely to take a dependency on the button, so pressing it reruns `rnorm`.

**Copy:**
- Pure computation functions (`simulate_nav`, `plot_nav`) kept outside the server and testable without Shiny.
- Two identical control panels side by side for scenario comparison.
- `.recalculating { opacity: 1 }` CSS stops outputs greying out during recompute.

**Dated -> modern:**
- `renderInputs(prefix)` + `paste0(prefix, "_", name)` is a hand-rolled module. Use a module (`scenarioUI(id)` / `scenarioServer(id)`) and call it twice.
- Every slider drag reruns a 2000 x 480 simulation. Wrap it: `reactive(...) |> bindEvent(input$recalc, ignoreNULL = FALSE)`, or debounce.
- Local Bootswatch CSS -> `bslib::bs_theme(bootswatch = "simplex")`.
- `n_sim` slider allows 0, which breaks `plot_nav`; set `min = 1`.

```r
scenarioUI <- function(id) {
  ns <- NS(id)
  tagList(
    sliderInput(ns("n_obs"), "Years", 1, 40, 20),
    sliderInput(ns("n_sim"), "Simulations", 1, 2000, 200),
    actionButton(ns("recalc"), "Re-run simulation"),
    plotOutput(ns("dist"), height = "600px")
  )
}
scenarioServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    nav <- reactive(simulate_nav(n_obs = input$n_obs, n_sim = input$n_sim)) |>
      bindEvent(input$recalc, ignoreNULL = FALSE)
    output$dist <- renderPlot(plot_nav(nav()))
  })
}
```

## 063 superzip-example

**Files:** `global.R` (reads `data/superzip.rds`, jitters coords, builds `allzips` and display table `cleantable`), `ui.R`, `server.R`, `styles.css`, `gomap.js`, `data/` (rds/csv/xls removed; `deps.sh` shows the original sources).

**Data loading:** `global.R` once per process. Top of `server.R` (still once per process) samples 10,000 rows into `zipdata` and sorts by centile so SuperZIPs draw last. `centileBreaks` is computed inside the server, so once per session; it could move up too.

**Reactive graph:**
- Map tab: `renderLeaflet` draws only tiles + view, once. `input$map_bounds` (set by leaflet) -> `zipsInBounds()` -> `histCentile`, `scatterCollegeIncome`. `color`, `size`, `threshold` -> observer -> `leafletProxy("map") |> clearShapes() |> addCircles() |> addLegend()`. `input$map_shape_click` -> popup via proxy.
- Explorer tab: `states` -> observer -> `updateSelectizeInput("cities", server = TRUE)`; `states`, `cities` -> observer -> update `zipcodes`; keeps still-valid selections via `isolate(input$cities[input$cities %in% cities])`. All filters -> `ziptable`, whose rows carry an HTML link with `data-lat/long/zip`.
- Cross-tab: `gomap.js` catches clicks on `.go-map`, switches to the map tab, sends `input$goto`; observer pans and opens a popup.

**Copy:**
- Full-screen map: `div(class="outer")` with `position: fixed; top: 41px` (navbar height) and `leafletOutput(height="100%")`, plus a draggable `absolutePanel` that fades when not hovered.
- Draw the base map once, then change markers with `leafletProxy`. The map keeps its zoom and pan, and redraws are cheap.
- Map viewport as an input: `input$<id>_bounds` filters side plots to what is visible.
- Cascading selects that keep the user's still-valid picks.
- Server-side selectize (`server = TRUE`) for long choice lists.

**Dated -> modern:**
- `Shiny.onInputChange(name, {..., nonce: Math.random()})` -> `Shiny.setInputValue(name, value, {priority: "event"})`; no nonce needed.
- `observe({ if (is.null(input$goto)) return(); isolate(...) })` -> `observeEvent(input$goto, ...)`.
- `DT::dataTableAjax()` + `options(ajax=)` -> `DT::renderDT(df, server = TRUE, escape = FALSE)`; server-side processing is already the default.
- `conditionalPanel("false", icon("crosshair"))` is a trick to load Font Awesome for the `<i class="fa ...">` in table HTML. Build the link with `as.character(icon("crosshairs"))` instead, or keep the trick and comment it.
- `lattice::xyplot` -> ggplot2. `class = "panel panel-default"` is Bootstrap 3; under bslib/BS5 use `class = "card"` or `bslib::card` inside the panel.
- For new apps: `bslib::page_navbar` + `nav_panel`; the `absolutePanel` pattern still works.

```r
# server side of the table -> map jump
observeEvent(input$goto, {
  g <- input$goto
  leaflet::leafletProxy("map") |>
    leaflet::clearPopups() |>
    leaflet::fitBounds(g$lng - 0.5, g$lat - 0.5, g$lng + 0.5, g$lat + 0.5)
})
# client side (www/gomap.js):
# $(document).on("click", ".go-map", function(e) {
#   e.preventDefault(); var d = $(this).data();
#   Shiny.setInputValue("goto", {lat: d.lat, lng: d.long, zip: d.zip}, {priority: "event"});
# });
```

## 064 telephones-by-region

**Files:** `ui.R`, `server.R`. Data: `datasets::WorldPhones`; choices are `colnames(WorldPhones)`.

**Reactive graph:** `region` -> `phonePlot` (barplot).

**Copy:** smallest complete sidebar app. Deriving choices from the data (`colnames(...)`) keeps UI and data in sync. `helpText()` for a data source credit.

**Dated -> modern:** nothing broken; for new apps write `page_sidebar()` in a single `app.R`.

## 086 bus-dashboard

**Files:** `ui.R`, `server.R`, `R/utils.R`, `R/gtfs.R`, `R/realtime.R`. Shiny (>= 1.5) sources every file in `R/` before the app, which replaces `global.R` + `source()`.

**Data loading:**
- Static timetable (GTFS zip): `get_transit_gtfs()` is `memoise`d and downloads to `tempdir()` only if absent; called once at the top of `server.R`.
- Live positions: `realtime_info()` is memoised with `cachem::cache_mem(max_age = 10)`, so many sessions polling at once share one download every 10 s.

**Reactive graph:** `refresh` button + `interval` -> `vehicleLocations()` (calls `invalidateLater(interval*1000)`) -> `routeVehicleLocations()` (filtered by `routeNum`) -> `numVehiclesTable`, `busmap`. `vehicleLocations()` -> `lastUpdateTime()` -> `timeSinceLastUpdate` (also ticks every 5 s). `routeSelect` is `renderUI` built from current vehicles.

**Copy:**
- Polling: `invalidateLater()` inside the data reactive + a "Refresh now" button the reactive also reads.
- Shared cache for external data: `memoise(f, cache = cachem::cache_mem(max_age = N))`. This cuts load on the external API and on the app.
- `R/` folder for helpers; the server stays readable.
- "Data refreshed N seconds ago" text for any live dashboard.
- Detecting a button press inside a render with a stored last value (`lastZoomButtonValue`): it works, but `observeEvent` + `leafletProxy |> fitBounds` is clearer.

**Dated -> modern:**
- shinydashboard (`dashboardPage`, `box(width=NULL)`, `dashboardSidebar(disable=TRUE)`) -> `bslib::page_fillable` / `page_sidebar` + `layout_columns(col_widths = c(9, 3))` + `card()`.
- `renderLeaflet` rebuilds the whole map on each poll. Render the base map once, then `leafletProxy("busmap") |> clearMarkers() |> addCircleMarkers(...)` from an observer.
- `renderUI` for one `selectInput` -> static `selectInput` + `updateSelectInput()`.
- Thunderforest tile URL over plain http without an API key: use `addTiles()` or `addProviderTiles(providers$CartoDB.Positron)`.
- The hand-written direction table could be a `tableOutput` over a `count()`.

```r
# R/data.R: shared cache across all sessions
fetch_live <- memoise::memoise(function() {
  data.frame(id = 1:3, lat = 44.97 + runif(3) / 100, lng = -93.26)
}, cache = cachem::cache_mem(max_age = 10))

server <- function(input, output, session) {
  live <- reactive({
    input$refresh
    invalidateLater(max(as.numeric(input$interval), 30) * 1000)
    fetch_live()
  })
  output$busmap <- leaflet::renderLeaflet(leaflet::leaflet() |> leaflet::addTiles())
  observe({
    leaflet::leafletProxy("busmap", data = live()) |>
      leaflet::clearMarkers() |>
      leaflet::addCircleMarkers(~lng, ~lat)
  })
}
```

## 087 crandash

**Files:** `global.R` (libraries, `prototype` empty data frame, stream/accumulator factories), `bloomfilter.R` (Reference Class), `ui.R`, `server.R`.

**Data loading:** per session. `packageStream(session)` opens a non-blocking socket to `cransim.rstudio.com:6789` (no longer online) and registers `session$onSessionEnded(close(sock))`.

**Reactive graph:** `invalidateLater(1000)` -> `newLines()` (readLines socket) -> `pkgStream()` (parse CSV + `received` timestamp). From `pkgStream`: `pkgData` (rolling 5-min window, `reducePast`), `dlCount` (running total), `usrCount` (bloom-filter unique users). `pkgData` -> `rate` valueBox (colour switches on `input$rateThreshold`), `packagePlot` (bubbles), `packageTable`, `rawtable`, `downloadCsv`.

**Copy:**
- Factory functions in `global.R` that take `session` and return reactives (`packageStream(session)`): a pre-module way to package reusable reactive logic.
- `session$onSessionEnded()` to release per-session connections.
- Rolling time window: accumulate, then `filter(received > now - window)`.
- `valueBox` whose colour reacts to a threshold input; a raw-data tab with `downloadHandler`.
- Bounded-memory unique count (bloom filter) for unbounded streams.

**Dated -> modern:**
- `shinySignals::reducePast` -> a `reactiveVal` updated by `observeEvent` on the stream (snippet below).
- `bubbles` -> `plotly` treemap or bar chart, or `echarts4r`.
- shinydashboard `valueBox`/`box`/`tabItems` -> `bslib::value_box`, `card`, `page_navbar`/`navset_*`.
- FA4 icon names (`"area-chart"`) -> FA6 (`"chart-area"`).
- Bug in `userCount()`: `total + length(newIds)` adds every id, because `newIds` is a logical vector. It should be `sum(newIds)`.
- `print(tail(...))` in `renderPrint` for a raw table -> `DT::renderDT`.

```r
server <- function(input, output, session) {
  pkgStream <- reactive({
    invalidateLater(1000)
    data.frame(package = sample(letters, 5), received = as.numeric(Sys.time()))
  })
  pkgData <- reactiveVal(data.frame(package = character(), received = numeric()))
  dlCount <- reactiveVal(0)
  observeEvent(pkgStream(), {
    new <- pkgStream()
    keep <- rbind(pkgData(), new)
    pkgData(keep[keep$received > as.numeric(Sys.time()) - 300, ])
    dlCount(dlCount() + nrow(new))
  })
  output$count <- renderText(dlCount())
}
```

## 120 goog-index

**Files:** single `app.R`; `data/trend_data.csv` (type, date, close), `data/trend_description.csv` (type, text).

**Data loading:** `readr::read_csv()` at the top of `app.R`, once per process.

**Reactive graph:** `type`, `date` -> `selected_trends()` (with `req` + two `validate(need())` checks) -> `lineplot` (also reads `smoother`, `f`). `type` -> `desc`.

**Copy:**
- Input validation inside the shared reactive, so every output shows the same friendly message: `req(input$date)`, then `validate(need(input$date[1] < input$date[2], "Start date should be earlier than end date."))`.
- `conditionalPanel("input.smoother == true", sliderInput(...))` shows dependent controls without a server round trip.
- `sliderInput(animate = animationOptions(interval = 100))` for a cheap animation.
- Long-format data (`type` column) so one `filter()` serves every series.

**Dated -> modern:** `shinythemes::shinytheme("lumen")` -> `bslib::bs_theme(bootswatch = "lumen")`. `tags$a` source link points to a retired Google Finance page.

## 141 radiant

**Files:** `app.R`, `README.md`. The app is one line: `shiny::shinyAppDir(system.file("app", package = "radiant"))`.

It contains no dashboard code: it launches the app shipped inside the CRAN package `radiant`. To study radiant's structure, read the package source (radiant.data, radiant.model, ...), not this folder.

**Copy:** the technique itself. Ship a Shiny app inside a package under `inst/app/` and expose it with `shinyAppDir(system.file("app", package = "pkg"))` or a `run_app()` function. That is how a course app can be installed with `install.packages()` or `remotes::install_github()`.

## 146 ames-explorer

**Files:** `app.R` (loads data, sources helpers and modules, defines `ui`/`server`), `helpers/plot_functions.R` (`scatter_sales()` ggplot builder, label formatter), `helpers/data_functions.R` (`highlight_prep()`, unused), `modules/data_modules.R` (`varselect_mod_*`, `dataviewer_mod_*`), `modules/plot_modules.R` (`scatterplot_mod_*`). README lists gghighlight, but the code uses ggrepel.

**Data loading:** `ames <- AmesHousing::make_ames()` once at the top of `app.R`.

**Reactive graph:**
- `varselect_mod_server` x2 -> each returns `list(xvar, yvar, facetvar)` of reactives.
- `plotdf()` = `brushedPoints(ames, res$brush(), allRows = TRUE)` (adds logical `selected_`).
- `scatterplot_mod_server(dataset = plotdf, plot1vars, plot2vars, highlight_ind, highlight_rows = dt_highlight)` -> two plots that share one brush id, so brushing either one selects in both; returns `list(processed, brush)`.
- `dataviewer_mod_server(dataset = res$processed)` -> DT of selected rows with column filters; returns `reactive(input$table_rows_all)`, which goes back into the plot module to label the filtered points.

**Copy:**
- Module servers return a named list of reactives; the parent wires them into other modules as arguments. Pass reactives uncalled (`plotdf`, not `plotdf()`).
- `brushOpts(id = ns("brush"))` on two plots with the same id gives linked brushing; `brushedPoints(allRows = TRUE)` keeps all rows and flags selection, which suits colouring.
- Plot construction in a plain function (`scatter_sales(data, xvar, yvar, facetvar)`) using `rlang::sym()` + `!!` (now `.data[[xvar]]`); the module only calls it.
- `input$<dt_id>_rows_all` gives the rows left after the table's own filters.

**Dated -> modern:**
- `callModule(fun, id, ...)` with `function(input, output, session, ...)` -> `fun <- function(id, ...) moduleServer(id, function(input, output, session) {...})`, called as `fun("id", ...)`.
- Circular wiring: `plotdf` reads `res$brush()` before `res` exists, and `dt_highlight` is passed before it is assigned. It works only because R arguments and reactives evaluate lazily. Declare things in dependency order, or pass a `reactiveVal` that the later module fills.
- `scale_color_manual(guide = FALSE)` -> `guide = "none"`; `select(one_of(...))` -> `select(all_of(...))`; `aes(x = !!x)` -> `aes(.data[[xvar]])`.
- `plot1_obj`/`plot2_obj` are copy-pasted; one helper function called twice would do.

```r
varselect_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(xvar = reactive(input$xvar), yvar = reactive(input$yvar))
  })
}
scatter_server <- function(id, data, vars) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({
      ggplot2::ggplot(data(), ggplot2::aes(.data[[vars$xvar()]], .data[[vars$yvar()]])) +
        ggplot2::geom_point()
    })
    reactive(input$brush)
  })
}
server <- function(input, output, session) {
  vars <- varselect_server("vars")
  brush <- scatter_server("plot", reactive(mtcars), vars)
}
```

## 500 movie-browser / 501 movie-browser-nav

**Files:** single `app.R` + `movies.RData` (data frame `movies`).

**Data loading:**
- 500: `load("movies.RData")` at top level, and again inside `server`, so it runs once more per session for no reason.
- 501: top-level `load()`, then inside `server` it calls `download.file()` from GitHub and `load()` again on every session. Every visitor re-downloads the data and overwrites the app's own file. Never do this.

**Reactive graph:** `type` (checkbox group) -> `movies_subset()` -> `plot` (ggplot scatter), `summary` (`group_by` + `summarise` table), `data` (DT). 501 defines an identical `movies_subset2()` for two of the outputs, which duplicates work.

**Copy:** the minimal "one filter -> plot + summary + table" dashboard; `choices = levels(movies$title_type)` drawn from data; reference tab with an inline `nrow(movies)`. 500 vs 501 shows `tabsetPanel` vs `navlistPanel` with the same contents.

**Dated -> modern:** drop the in-server `load()`/`download.file()`; `library(tidyverse)` -> load only `dplyr` + `ggplot2`; layouts -> `page_sidebar` + `navset_card_tab` (500) or `navset_pill_list` (501). Guard the empty case: `req(input$type)`, because with no checkbox ticked the plot and the `cor()` summary get zero rows.

---

## Assembly rules distilled from these apps

1. **Load static data once, at top level.** Code outside `server` runs once per R process and is shared by all sessions; inside `server` it reruns for every visitor (063, 120, 146 do this right; 500/501 do it wrong).
2. **Never download or write files inside `server`.** Per-session downloads multiply network cost and race on the same file (501). Fetch at startup or behind a shared cache.
3. **One filtered-data reactive, shared by every output.** Filtering happens once per input change and all views stay consistent (051, 120, 500); a duplicate reactive (501) doubles the work.
4. **Chain reactives by stage: select -> compute -> render.** Each stage reruns only when its own inputs change (050 `selectedData` -> `clusters`).
5. **Put `req()`/`validate(need())` in the shared reactive, not in each output.** One check covers every output and shows a readable message instead of an R error (120).
6. **Gate heavy computation behind a button with `bindEvent()`.** Otherwise each slider drag reruns the simulation or model (060); use `ignoreNULL = FALSE` so the first result renders on load.
7. **Use `observeEvent()` for side effects triggered by events, not `observe()` + `isolate()` + NULL checks.** It states the trigger explicitly and skips the initial NULL (040, 063).
8. **Accumulate event data in `reactiveValues`/`reactiveVal`.** A reactive cannot remember its previous value; a stored value updated from an observer can (040 clicks, 087 stream).
9. **Use a `global.R` (or `R/` folder) for objects both UI and server need.** Choice vectors and label maps (051 `axis_vars`, 063 `allzips`) must exist before `ui.R` is evaluated. In single-file `app.R`, put them above `ui`.
10. **Keep helpers in `R/` and pure functions outside `server`.** Shiny auto-sources `R/*.R`; pure functions (060 `simulate_nav`, 146 `scatter_sales`) can be tested in the console without running the app.
11. **Repeat UI blocks with modules, not ID prefixes.** `NS(id)` + `moduleServer()` gives collision-free IDs and private state (060 `paste0(prefix, ...)` -> module; 146).
12. **Modules return named lists of reactives; the parent wires them.** It keeps data flow explicit and one-directional; pass reactives uncalled, and declare them in dependency order (146's circular wiring works only through lazy evaluation).
13. **Render a map or widget once, update it with a proxy.** `leafletProxy()` keeps zoom/pan and avoids rebuilding the widget on each change or poll (063 right, 086 wrong).
14. **Treat widget state as inputs.** `input$map_bounds`, `input$map_shape_click`, `plotOutput(click=, brush=)`, `input$tbl_rows_all` let one view filter another without extra controls (063, 146, 040).
15. **Live data: `invalidateLater()` in the fetch reactive + a manual refresh button + a "last updated" label.** Users can control freshness and see staleness (086).
16. **Cache external calls across sessions with `memoise` + `cachem::cache_mem(max_age=)`.** N viewers then cost one API call per interval, not N (086).
17. **Release per-session resources in `session$onSessionEnded()` (or `onStop()` for app-wide ones).** Sockets and DB connections otherwise leak (087 socket; 051 DB should `dbDisconnect`).
18. **Query databases lazily with dbplyr and `collect()` at the end.** The database filters and only the needed rows come into R (051).
19. **Update choices with `update*Input()` instead of `renderUI()` for an existing control.** It avoids re-creating the widget and losing its state; keep still-valid selections (063 cascading selects; 086 should).
20. **Use `conditionalPanel()` for show/hide that depends only on inputs.** It runs in the browser with no server round trip (063 threshold, 120 smoother span).
21. **Custom JS sends data with `Shiny.setInputValue(id, value, {priority: "event"})`.** `priority: "event"` fires even when the value repeats, which replaces the old `nonce: Math.random()` trick (063).
22. **Choose the layout by purpose:** sidebar + tabs for explorers (500), `page_navbar` for map + table apps (063), value boxes + cards for monitoring (086/087), side-by-side columns for comparisons (060). Build all of them with bslib rather than shinydashboard or shinythemes.
23. **Swap dead packages, keep the wiring.** ggvis -> plotly/ggplot2 (051), bubbles -> plotly (087), shinySignals -> `reactiveVal` + `observeEvent` (087), shinydashboard -> bslib (086/087), shinythemes -> `bs_theme(bootswatch=)` (120), `callModule` -> `moduleServer` (146), `DT::dataTableAjax` -> `renderDT(server = TRUE)` (063).
24. **Ship a reusable app inside a package and launch it with `shinyAppDir(system.file("app", package=))`.** The app then installs and versions like any package (141).
