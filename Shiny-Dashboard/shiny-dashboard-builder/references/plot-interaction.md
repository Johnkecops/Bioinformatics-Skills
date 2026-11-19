# Plot interaction

Click, double-click, hover and brush on `renderPlot()` / `renderImage()` output, and turning those events into selected rows, zoom, exclusion and linked views.

## Contents
- [Interaction arguments](#interaction-arguments)
- [Show selected rows](#show-selected-rows)
- [Zoom on brush, double-click to reset](#zoom-on-brush-double-click-to-reset)
- [Linked plots](#linked-plots)
- [Toggle / exclude points](#toggle--exclude-points)
- [Brush and hover options](#brush-and-hover-options)
- [Base graphics, facets, scales](#base-graphics-facets-scales)
- [Interaction on renderImage](#interaction-on-renderimage)
- [Alternative: plotly event_data()](#alternative-plotly-event_data)
- [Example index](#example-index)

## Interaction arguments

Passing any of these to `plotOutput()` / `imageOutput()` creates `input$<id>`. A bare string is shorthand for `*Opts(id = "...")`.

| `plotOutput()` arg | Opts helper (key options) | `input$<id>` contains | Turn into rows with |
|---|---|---|---|
| `click` | `clickOpts(id, clip)` | `x`, `y` (data units), `coords_css`, `coords_img`, `mapping`, `domain`, `range`, `log`, `panelvar1/2` (facets) | `nearPoints(df, input$id)` |
| `dblclick` | `dblclickOpts(id, clip, delay = 400)` | same as click | `nearPoints()` |
| `hover` | `hoverOpts(id, delay = 300, delayType = "debounce"/"throttle", clip, nullOutside = TRUE)` | same as click; `NULL` when pointer leaves (if `nullOutside`) | `nearPoints()` |
| `brush` | `brushOpts(id, fill, stroke, opacity, delay, delayType, clip, direction = "xy"/"x"/"y", resetOnNew = FALSE)` | `xmin`, `xmax`, `ymin`, `ymax` (data units), `direction`, `mapping`, `domain`, `range`, `log`, `panelvar1/2` | `brushedPoints(df, input$id)` |

All are `NULL` until the user interacts; a brush goes back to `NULL` when cleared. `nearPoints()` / `brushedPoints()` accept `NULL` and return zero rows (or all rows with `selected_ = FALSE` if `allRows = TRUE`), so no `req()` is needed.

Helper arguments: `nearPoints(df, coordinfo, xvar, yvar, panelvar1, panelvar2, threshold = 5, maxpoints = NULL, addDist = FALSE, allRows = FALSE)`; `brushedPoints(df, brush, xvar, yvar, panelvar1, panelvar2, allRows = FALSE)`. `allRows = TRUE` adds a logical `selected_` column instead of filtering; `addDist = TRUE` adds `dist_` (pixels).

Source: `093-plot-interaction-basic`, `096-plot-interaction-article-1`, `097-plot-interaction-article-2`

## Show selected rows

The basic dashboard pattern: click picks the nearest point, brush picks a region, both feed a table.

```r
library(shiny)
library(bslib)
library(ggplot2)

ui <- page_fluid(
  card(plotOutput("plot", click = "plot_click", hover = "plot_hover",
                  brush = brushOpts("plot_brush"))),
  layout_columns(
    card(card_header("Near click"), tableOutput("clicked")),
    card(card_header("Brushed"), tableOutput("brushed"))
  )
)

server <- function(input, output, session) {
  output$plot <- renderPlot(ggplot(mtcars, aes(wt, mpg)) + geom_point())

  clicked <- reactive(
    nearPoints(mtcars, input$plot_click, threshold = 10, maxpoints = 1, addDist = TRUE)
  )
  brushed <- reactive(brushedPoints(mtcars, input$plot_brush))

  output$clicked <- renderTable(clicked(), rownames = TRUE)
  output$brushed <- renderTable(brushed(), rownames = TRUE)
}

shinyApp(ui, server)
```

Swap `tableOutput`/`renderTable` for `DT::DTOutput`/`DT::renderDT` for sortable tables (as in `095`).

Source: `098`–`102-plot-interaction-article-*`, `104-plot-interaction-select`, `095-plot-interaction-advanced`

Pitfalls:
- `brushedPoints()`/`nearPoints()` read the column names from the plot's `aes()`. They must name columns of the `df` you pass. `aes(.data[[var]], mpg)` records the mapping as the literal string `.data[["wt"]]` and the helper errors "xvar not in names of input"; pass `xvar = var` (and `yvar`) explicitly whenever the aesthetic is programmatic, or derived (`aes(log(wt), ...)`).
- The `df` you pass must be the data that was plotted (same columns, same transformations). If the plot shows a filtered subset, pass that subset.
- Default `threshold = 5` px: points closer than that to each other are all returned on one click. Use `maxpoints = 1` for "the" point.

## Zoom on brush, double-click to reset

Brush a region, double-click to zoom into it; double-click with no brush resets. `resetOnNew = TRUE` clears the brush after the plot redraws at the new zoom.

```r
library(shiny)
library(bslib)
library(ggplot2)

ui <- page_fluid(
  card(
    card_header("Brush, then double-click to zoom; double-click again to reset"),
    plotOutput("plot", dblclick = "plot_dblclick",
               brush = brushOpts("plot_brush", resetOnNew = TRUE))
  )
)

server <- function(input, output, session) {
  ranges <- reactiveVal(list(x = NULL, y = NULL))

  observeEvent(input$plot_dblclick, {
    b <- input$plot_brush
    ranges(if (is.null(b)) list(x = NULL, y = NULL)
           else list(x = c(b$xmin, b$xmax), y = c(b$ymin, b$ymax)))
  })

  output$plot <- renderPlot(
    ggplot(mtcars, aes(wt, mpg)) + geom_point() +
      coord_cartesian(xlim = ranges()$x, ylim = ranges()$y, expand = FALSE)
  )
}

shinyApp(ui, server)
```

Source: `105-plot-interaction-zoom`

Pitfalls:
- Zoom with `coord_cartesian(xlim, ylim)`, not `xlim()`/`scale_*(limits=)`: scale limits drop out-of-range data and change fitted smooths.
- Without `resetOnNew = TRUE` the old brush rectangle stays drawn in pixel position over the re-scaled plot, now covering different data.

## Linked plots

One plot's brush drives others: zoom a detail view, or highlight the same rows in a plot of other variables. A plain `reactive()` on the brush is enough; no observer.

```r
library(shiny)
library(bslib)
library(ggplot2)

ui <- page_fluid(
  layout_columns(
    card(card_header("Overview: brush here"),
         plotOutput("overview", brush = brushOpts("ov_brush", resetOnNew = TRUE))),
    card(card_header("Detail (zoomed)"), plotOutput("detail")),
    card(card_header("Same rows, other variables"), plotOutput("other"))
  )
)

server <- function(input, output, session) {
  # zoom: brush bounds drive the second plot's limits
  zoom <- reactive({
    b <- input$ov_brush
    if (is.null(b)) list(x = NULL, y = NULL)
    else list(x = c(b$xmin, b$xmax), y = c(b$ymin, b$ymax))
  })
  # highlight: brushed rows flagged in the full data
  flagged <- reactive(brushedPoints(mtcars, input$ov_brush, allRows = TRUE))

  output$overview <- renderPlot(ggplot(mtcars, aes(wt, mpg)) + geom_point())
  output$detail <- renderPlot(
    ggplot(mtcars, aes(wt, mpg)) + geom_point() +
      coord_cartesian(xlim = zoom()$x, ylim = zoom()$y, expand = FALSE)
  )
  output$other <- renderPlot(
    ggplot(flagged(), aes(hp, qsec, colour = selected_)) + geom_point() +
      scale_colour_manual(values = c(`FALSE` = "grey70", `TRUE` = "firebrick"))
  )
}

shinyApp(ui, server)
```

Source: `105-plot-interaction-zoom` (right-hand pair)

Pitfalls:
- Do not put a brush on a plot whose own limits depend on that same brush; every redraw moves the data under the rectangle and loops. Brush the overview, zoom the detail.

## Toggle / exclude points

Click a point (or brush + button) to drop it from a model fit; excluded points stay visible as hollow circles. State is a logical vector in a `reactiveVal`, flipped with `xor()` against `allRows = TRUE` output.

```r
library(shiny)
library(bslib)
library(ggplot2)

ui <- page_fluid(
  card(
    plotOutput("plot", click = "plot_click", brush = brushOpts("plot_brush")),
    div(actionButton("toggle", "Toggle brushed points"),
        actionButton("reset", "Reset"))
  )
)

server <- function(input, output, session) {
  keep <- reactiveVal(rep(TRUE, nrow(mtcars)))

  observeEvent(input$plot_click, {
    hit <- nearPoints(mtcars, input$plot_click, allRows = TRUE)$selected_
    keep(xor(keep(), hit))
  })
  observeEvent(input$toggle, {
    hit <- brushedPoints(mtcars, input$plot_brush, allRows = TRUE)$selected_
    keep(xor(keep(), hit))
  })
  observeEvent(input$reset, keep(rep(TRUE, nrow(mtcars))))

  output$plot <- renderPlot({
    kept <- mtcars[keep(), , drop = FALSE]
    gone <- mtcars[!keep(), , drop = FALSE]
    ggplot(kept, aes(wt, mpg)) +
      geom_point() +
      geom_smooth(method = "lm", formula = y ~ x, fullrange = TRUE, colour = "black") +
      geom_point(data = gone, shape = 21, fill = NA, alpha = 0.25) +
      coord_cartesian(xlim = c(1.5, 5.5), ylim = c(5, 35))
  })
}

shinyApp(ui, server)
```

Lab use: outlier removal before a standard curve / regression; show `coef(lm(mpg ~ wt, mtcars[keep(), ]))` beside the plot.

Source: `106-plot-interaction-exclude`

Pitfalls:
- Use `allRows = TRUE` so the `selected_` vector lines up with the full data; without it you get only matching rows and `xor()` recycles silently.
- Run the helpers on the full data (`mtcars`), not `kept`, or excluded points can never be clicked back in.
- Fixed `coord_cartesian()` limits keep the axes from jumping as points are dropped.

## Brush and hover options

| Need | Option |
|---|---|
| Time series: select a time window only | `brushOpts(id, direction = "x")`; `brushedPoints()` then filters on x only |
| Fewer server round-trips while dragging | `delay = 500`, `delayType = "debounce"` (fires after pause) or `"throttle"` (fires every `delay` ms) |
| Clear brush when plot redraws | `resetOnNew = TRUE` |
| Restrict brush/hover to plot panel | `clip = TRUE` (default) |
| Keep last hover value when pointer leaves | `hoverOpts(id, nullOutside = FALSE)` |
| Brush colour | `fill = "#ccc"`, `stroke`, `opacity` |
| Slower double-click detection | `dblclickOpts(id, delay = 600)` |

```r
plotOutput("ts", height = 250,
  brush = brushOpts("ts_brush", direction = "x", fill = "#ccc",
                    delay = 300, delayType = "debounce"),
  hover = hoverOpts("ts_hover", delay = 100, delayType = "throttle")
)
```

Source: `103-plot-interaction-article-8` (x-only brush on `ChickWeight`), `095-plot-interaction-advanced` (all options as live controls)

Pitfalls:
- An interactive plot is no longer draggable as an image (any of click/hover/brush disables native image dragging). Expected; only matters if users drag plots into documents. Source: `162-plot-dragging`.

## Base graphics, facets, scales

- Base graphics (`plot()`) record no mapping: always pass `xvar`/`yvar`.
  ```r
  brushedPoints(mtcars, input$plot_brush, xvar = "wt", yvar = "mpg")
  nearPoints(mtcars, input$plot_click, xvar = "wt", yvar = "mpg")
  ```
  Without them: "not able to automatically infer `xvar`".
- ggplot2 facets: the event carries `panelvar1`/`panelvar2`; helpers restrict to the clicked/brushed panel automatically (`101-plot-interaction-article-6`). A brush cannot span panels.
- Log/reversed scales (`scale_x_log10()`, `scale_*_reverse()`, `coord_transform()`, called `coord_trans()` in older ggplot2), `coord_flip()`, `coord_fixed()`, factor and date/datetime axes all map correctly; brush values come back in data units. `coord_polar()` does not work (`095`).
- `renderCachedPlot()` and fixed `renderPlot(width =, height =)` keep correct brush coordinates after browser resize / HiDPI (`139-plot-brush-scaling`). Prefer `renderPlot(...) |> bindCache(...)` over `renderCachedPlot()` in new code.

Source: `095-plot-interaction-advanced`, `100-plot-interaction-article-5`, `101-plot-interaction-article-6`, `139-plot-brush-scaling`

## Interaction on renderImage

`imageOutput()` takes the same `click`/`dblclick`/`hover`/`brush` args. Coordinates are image pixels, origin top-left, y increasing downward. Use for annotating micrographs, gels, plate photos.

```r
library(shiny)
library(bslib)

cells <- data.frame(id = 1:3, px = c(40, 120, 300), py = c(30, 80, 200))  # pixel positions

ui <- page_fluid(
  card(imageOutput("img", click = "img_click", brush = brushOpts("img_brush"))),
  verbatimTextOutput("hit"),
  tableOutput("in_box")
)

server <- function(input, output, session) {
  output$img <- renderImage(
    list(src = "www/micrograph.png", contentType = "image/png", alt = "micrograph"),
    deleteFile = FALSE
  )
  output$hit <- renderPrint({
    req(input$img_click)
    d2 <- (cells$px - input$img_click$x)^2 + (cells$py - input$img_click$y)^2
    cells[which.min(d2), ]
  })
  output$in_box <- renderTable(
    brushedPoints(cells, input$img_brush, xvar = "px", yvar = "py")
  )
}

shinyApp(ui, server)
```

To draw an image sized to the container, read `session$clientData$output_img_width` / `_height` inside `renderImage()` (`094`).

Source: `094-image-interaction-basic`, `139-plot-brush-scaling` (imageOutput part)

Pitfalls:
- Set `deleteFile = FALSE` for static files; `TRUE` deletes the file after sending (right only for a `tempfile()` made inside `renderImage()`). Omitting it gives a warning.
- If CSS scales the `<img>` (e.g. `max-width: 100%`), coordinates are still reported in image pixels; `139` checks this.

## Alternative: plotly event_data()

For hover tooltips, lasso select and zoom built into the widget, use plotly instead of `plotOutput` events. Identify rows with `key` and read `event_data()`.

```r
library(shiny)
library(bslib)
library(plotly)

ui <- page_fluid(
  card(plotlyOutput("p")),
  card(tableOutput("sel"))
)

server <- function(input, output, session) {
  output$p <- renderPlotly(
    plot_ly(mtcars, x = ~wt, y = ~mpg, key = rownames(mtcars),
            type = "scatter", mode = "markers", source = "scatter") |>
      layout(dragmode = "lasso") |>
      event_register("plotly_selected")
  )
  output$sel <- renderTable({
    d <- event_data("plotly_selected", source = "scatter")
    if (is.null(d)) mtcars[0, ] else mtcars[d$key, ]
  }, rownames = TRUE)
}

shinyApp(ui, server)
```

Other events: `"plotly_click"`, `"plotly_hover"`, `"plotly_relayout"` (zoom ranges), `"plotly_deselect"`. Use `plotOutput` + `brushedPoints()` when the plot is ggplot-heavy (facets, smooths) or must match a static publication figure; use plotly for exploratory hover/lasso.

## Example index

| Folder | Shows |
|---|---|
| `093-plot-interaction-basic` | All four events on base and ggplot2, `str()` of each input |
| `094-image-interaction-basic` | Same on `imageOutput()`; image sized from `clientData` |
| `095-plot-interaction-advanced` | Every `*Opts` option, scale/coord/facet variants, `nearPoints`/`brushedPoints` into DT |
| `096`–`097-plot-interaction-article-1/2` | Reading `x`/`y` and brush bounds |
| `098`/`100-plot-interaction-article-3/5` | `nearPoints`/`brushedPoints` on base graphics (xvar/yvar) |
| `099-plot-interaction-article-4` | `threshold`, `maxpoints`, `addDist` |
| `101-plot-interaction-article-6` | Brushing a faceted ggplot |
| `102-plot-interaction-article-7` | `allRows = TRUE` → `selected_` column |
| `103-plot-interaction-article-8` | x-only brush on a time series |
| `104-plot-interaction-select` | Click + brush selection tables |
| `105-plot-interaction-zoom` | Brush/dblclick zoom; linked overview/detail |
| `106-plot-interaction-exclude` | Toggle/exclude points, refit `lm` |
| `139-plot-brush-scaling` | Manual test: brush accuracy on log scales, cached plots, resized images |
| `162-plot-dragging` | Manual test: interactive plots are not image-draggable |
