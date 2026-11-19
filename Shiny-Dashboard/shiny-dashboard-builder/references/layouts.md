# Layouts

Page skeletons, navigation, grids, panels, themes and icons for Shiny apps, in bslib idiom with the classic equivalent.

## Contents
- [Choosing a layout](#choosing-a-layout)
- [Minimal page and single-file app](#minimal-page-and-single-file-app)
- [Sidebar page](#sidebar-page)
- [Tabs inside a page](#tabs-inside-a-page)
- [Multi-page navbar](#multi-page-navbar)
- [Vertical nav list](#vertical-nav-list)
- [Column grids](#column-grids)
- [Vertical stack](#vertical-stack)
- [Conditional panels](#conditional-panels)
- [Floating and fixed panels](#floating-and-fixed-panels)
- [Dashboard: value boxes and cards](#dashboard-value-boxes-and-cards)
- [shinydashboard (legacy dashboards)](#shinydashboard-legacy-dashboards)
- [Themes](#themes)
- [Icons](#icons)
- [Inline outputs in R Markdown / Quarto](#inline-outputs-in-r-markdown--quarto)

## Choosing a layout

| Need | bslib (modern) | Classic shiny | Source |
|---|---|---|---|
| One plot, a few controls | `page_sidebar()` | `fluidPage(sidebarLayout())` | 001, 015-layout-sidebar |
| Several views of one dataset | `navset_card_tab()` in a page | `tabsetPanel()` | 006 |
| Separate app sections | `page_navbar()` + `nav_panel()` | `navbarPage()` + `tabPanel()` | 015-layout-navbar, 052 |
| Many sections, side nav | `navset_pill_list()` | `navlistPanel()` | 053 |
| Plot on top, controls in columns | `layout_columns()` | `fluidRow(column())` | 057, 144 |
| KPI dashboard | `page_sidebar()` + `value_box()` + `card()` | `shinydashboard::dashboardPage()` | 086 |
| Map/plot with overlay controls | `page_fillable()` + `absolutePanel()` | `fluidPage()` + `absolutePanel()` | 027 |
| Bare minimum / embedding | `page_fluid()` | `bootstrapPage()` | 083, 084 |

Rule of thumb: start from `page_sidebar()`; switch to `page_navbar()` once there are 3+ distinct sections. Wrap every output in `card()` so it gets a header, border and full-screen toggle.

## Minimal page and single-file app

One `app.R` holding `ui`, `server` and `shinyApp()`. Preferred over the old `ui.R` + `server.R` pair (which still runs; in that layout `ui.R` ends with the UI object and `server.R` with the function, no `shinyApp()` call).

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  textInput("custom_text", "Input some text here:"),
  numericInput("n", "Number of obs", 200),
  strong("Text is shown below:"),
  textOutput("user_text"),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$user_text <- renderText(input$custom_text)
  output$plot <- renderPlot(hist(runif(input$n)))
}

shinyApp(ui, server)
```

Classic: `bootstrapPage()` (no container padding) or `fluidPage()` in place of `page_fluid()`.

Source: `084-single-file`, `503-server-function`, `083-front-page`

Pitfalls:
- Always give `server` the `session` argument; modules, `update*()` and bookmarking need it.
- `ui.R`/`server.R` and `app.R` in the same folder: `app.R` wins. Pick one.

## Sidebar page

Controls in a collapsible sidebar, outputs in the main area. The default for single-purpose apps.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "Old Faithful",
  sidebar = sidebar(
    position = "right",          # default "left"
    width = 300,
    sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30)
  ),
  card(
    card_header("Waiting time histogram"),
    plotOutput("distPlot"),
    full_screen = TRUE
  )
)

server <- function(input, output, session) {
  output$distPlot <- renderPlot({
    x <- faithful$waiting
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(x, breaks = bins, col = "#75AADB", border = "white")
  })
}

shinyApp(ui, server)
```

Classic equivalent:

```r
ui <- fluidPage(
  titlePanel("Hello Shiny!"),
  sidebarLayout(
    position = "right",
    sidebarPanel(sliderInput("bins", "Number of bins:", 1, 50, 30), width = 4),
    mainPanel(plotOutput("distPlot"), width = 8)
  )
)
```

Source: `001-hello`, `015-layout-sidebar`, `502-random-number` (custom widths 5/7), `144-colors` (widths 2/10)

Pitfalls:
- Classic `sidebarPanel(width=)` + `mainPanel(width=)` must sum to 12 grid units; bslib `sidebar(width=)` is pixels/CSS.
- `page_sidebar()` fills the window; tall content in one card scrolls inside the card. Use `fillable = FALSE` if you want normal page scrolling.

## Tabs inside a page

Several views (plot / summary / table) of the same reactive data without leaving the page.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "Tabsets",
  sidebar = sidebar(
    radioButtons("dist", "Distribution type:",
      c(Normal = "norm", Uniform = "unif", "Log-normal" = "lnorm", Exponential = "exp")),
    sliderInput("n", "Number of observations:", value = 500, min = 1, max = 1000)
  ),
  navset_card_tab(
    id = "tab",
    nav_panel("Plot", plotOutput("plot")),
    nav_panel("Summary", verbatimTextOutput("summary")),
    nav_panel("Table", tableOutput("table"))
  )
)

server <- function(input, output, session) {
  d <- reactive(switch(input$dist,
    norm = rnorm, unif = runif, lnorm = rlnorm, exp = rexp)(input$n))
  output$plot <- renderPlot(hist(d(), main = paste0("r", input$dist, "(", input$n, ")")))
  output$summary <- renderPrint(summary(d()))
  output$table <- renderTable(data.frame(x = d()))
}

shinyApp(ui, server)
```

Classic: `mainPanel(tabsetPanel(type = "tabs", tabPanel("Plot", plotOutput("plot")), ...))`. Other bslib variants: `navset_tab()`, `navset_pill()`, `navset_underline()`, `navset_card_pill()`.

Source: `006-tabsets`

Pitfalls:
- Give the navset an `id` to read the active tab as `input$tab` or switch it with `nav_select("tab", "Table")` (classic: `updateTabsetPanel()`).
- Outputs on hidden tabs are not computed until shown (`suspendWhenHidden`), so the first switch can lag.

## Multi-page navbar

Top navigation bar with one page per section; `nav_menu()` groups extra pages in a dropdown.

```r
library(shiny)
library(bslib)

ui <- page_navbar(
  title = "Navbar!",
  id = "page",
  nav_panel("Plot",
    layout_sidebar(
      sidebar = sidebar(radioButtons("plotType", "Plot type", c(Scatter = "p", Line = "l"))),
      card(plotOutput("plot"))
    )
  ),
  nav_panel("Summary", verbatimTextOutput("summary")),
  nav_menu("More",
    nav_panel("Table", DT::DTOutput("table")),
    nav_panel("About", markdown("Built with **Shiny**. Data: `cars`."))
  ),
  nav_spacer(),
  nav_item(tags$a("Docs", href = "https://shiny.posit.co", target = "_blank"))
)

server <- function(input, output, session) {
  output$plot <- renderPlot(plot(cars, type = input$plotType))
  output$summary <- renderPrint(summary(cars))
  output$table <- DT::renderDT(cars)
}

shinyApp(ui, server)
```

Classic: `navbarPage("Navbar!", tabPanel("Plot", sidebarLayout(...)), navbarMenu("More", tabPanel("Table", ...)))`.

Source: `015-layout-navbar`, `052-navbar-example`

Pitfalls:
- A page-level sidebar shared by all pages: `page_navbar(sidebar = sidebar(...))`. A per-page sidebar: `layout_sidebar()` inside that `nav_panel()`.
- `includeMarkdown("about.md")` needs the markdown package; `shiny::markdown()` covers inline text without it.
- `DT::dataTableOutput`/`renderDataTable` are the old names; use `DT::DTOutput`/`DT::renderDT`.

## Vertical nav list

Pill links stacked on the left, content on the right. Good for many short sections (e.g. one per gene or assay).

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  h2("Navlist panel example"),
  navset_pill_list(
    nav_item(tags$b("Header")),
    nav_panel("First", h3("This is the first panel")),
    nav_panel("Second", h3("This is the second panel")),
    nav_panel("Third", h3("This is the third panel")),
    widths = c(3, 9)
  )
)
```

Classic: `navlistPanel("Header", tabPanel("First", ...), ..., widths = c(4, 8))`; a bare string inside it becomes a section header.

Source: `053-navlistpanel-example`

## Column grids

Place inputs or outputs side by side on the 12-column Bootstrap grid. `layout_columns()` takes widths once; `layout_column_wrap()` gives equal-width tiles.

```r
library(shiny)
library(bslib)
library(ggplot2)

ui <- page_fillable(
  title = "Diamonds Explorer",
  card(plotOutput("plot")),
  layout_columns(
    col_widths = c(3, -1, 4, 4),   # negative = empty offset column
    fill = FALSE,
    card(
      sliderInput("sampleSize", "Sample size", 1, nrow(diamonds), 1000, step = 500),
      checkboxInput("smooth", "Smooth")
    ),
    card(
      selectInput("x", "X", names(diamonds)),
      selectInput("y", "Y", names(diamonds), names(diamonds)[[2]])
    ),
    card(selectInput("color", "Color", c("None", names(diamonds))))
  )
)

server <- function(input, output, session) {
  d <- reactive(diamonds[sample(nrow(diamonds), input$sampleSize), ])
  output$plot <- renderPlot({
    p <- ggplot(d(), aes(.data[[input$x]], .data[[input$y]])) + geom_point()
    if (input$color != "None") p <- p + aes(colour = .data[[input$color]])
    if (input$smooth) p <- p + geom_smooth()
    p
  })
}

shinyApp(ui, server)
```

Equal 2 x 2 tiles of a repeated module (pattern from 144-colors):

```r
layout_column_wrap(width = 1/2, mapUI("one"), mapUI("two"), mapUI("three"), mapUI("four"))
```

Classic: `fluidRow(column(3, ...), column(4, offset = 1, ...), column(4, ...))`.

Source: `057-plot-plus-three-columns`, `144-colors`

Pitfalls:
- `aes_string()` (057) is deprecated in ggplot2; use `.data[[input$x]]`.
- 144-colors uses `callModule()` and `rgdal::readOGR()`; use `moduleServer()` and `sf::st_read()` (rgdal is archived).
- Return the ggplot object from `renderPlot()`; `print(p)` is not needed.

## Vertical stack

Title, plot and controls stacked full-width; simplest layout for narrow screens and embedding.

```r
library(shiny)
library(bslib)

ui <- page_fluid(
  h2("Vertical layout example"),
  card(plotOutput("plot1")),
  card(sliderInput("n", "Number of points", 10, 200, value = 50, step = 10))
)
```

Classic: `fluidPage(verticalLayout(titlePanel(...), plotOutput("plot1"), wellPanel(sliderInput(...))))`.

Source: `067-vertical-layout`

## Conditional panels

Show a control only when another input has a given value, evaluated in the browser (no server round trip).

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  sidebar = sidebar(
    checkboxInput("density", "Show density estimate", FALSE),
    conditionalPanel(
      condition = "input.density == true",
      sliderInput("bw_adjust", "Bandwidth adjustment:", min = 0.2, max = 2, value = 1, step = 0.2)
    ),
    selectInput("digit_type", "Number of digits:", c("any", "selected")),
    conditionalPanel(
      "input.digit_type == 'selected'",
      sliderInput("digit_count", "How many digits?", 1, 10, 4)
    )
  ),
  card(plotOutput("main_plot"))
)
```

Source: `083-front-page`, `502-random-number`

Pitfalls:
- `condition` is JavaScript: `true`/`false` lowercase, `==` with quoted strings, `input.id` with a dot.
- Inside a module use `conditionalPanel(..., ns = ns)` and write `input.density`; the namespace is added for you.
- A hidden input still holds its last value on the server; guard with `if (input$density)`.

## Floating and fixed panels

Panels positioned over the page: draggable control boxes over a big plot or map, or a banner docked to the top.

```r
library(shiny)
library(bslib)

ui <- page_fillable(
  padding = 0,
  plotOutput("plot", height = "100%"),
  absolutePanel(
    bottom = 20, right = 20, width = 300, draggable = TRUE,
    style = "opacity: 0.92; z-index: 10;",
    card(
      card_header("Controls"),
      sliderInput("n", NULL, min = 3, max = 20, value = 5),
      plotOutput("plot2", height = "200px")
    )
  ),
  absolutePanel(
    top = 0, left = 0, right = 0, fixed = TRUE,
    div(class = "bg-light border-bottom p-2", "Docked to the top; does not scroll.")
  )
)
```

Source: `027-absolutely-positioned-panels`

Pitfalls:
- `fixed = TRUE` positions relative to the window, otherwise relative to the page; `fixedPanel()` is the shortcut.
- `markdown::markdownToHTML()` (027) is superseded; use `shiny::markdown("text")`.
- Add a `z-index` so the panel sits above leaflet maps.

## Dashboard: value boxes and cards

KPI row on top, cards below. This is the bslib replacement for shinydashboard.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "Lab dashboard",
  theme = bs_theme(version = 5, preset = "shiny"),
  sidebar = sidebar(
    selectInput("species", "Species", c("All", levels(iris$Species))),
    actionButton("refresh", "Refresh now", icon = icon("rotate"))
  ),
  layout_columns(
    fill = FALSE,
    value_box("Samples", textOutput("n_samples"), showcase = icon("vial"), theme = "primary"),
    value_box("Mean petal length", textOutput("mean_pl"), showcase = icon("ruler"), theme = "teal"),
    value_box("Last update", textOutput("updated"), showcase = icon("clock"))
  ),
  layout_columns(
    col_widths = c(8, 4),
    card(card_header("Scatter"), plotOutput("scatter"), full_screen = TRUE),
    card(card_header("Data"), tableOutput("tbl"))
  )
)

server <- function(input, output, session) {
  d <- reactive(if (input$species == "All") iris else subset(iris, Species == input$species))
  output$n_samples <- renderText(nrow(d()))
  output$mean_pl <- renderText(round(mean(d()$Petal.Length), 2))
  output$updated <- renderText(format(Sys.time(), "%H:%M:%S")) |> bindEvent(input$refresh, d())
  output$scatter <- renderPlot(plot(d()$Petal.Length, d()$Petal.Width, col = d()$Species))
  output$tbl <- renderTable(head(d()))
}

shinyApp(ui, server)
```

Source: `086-bus-dashboard` (layout idea; its boxes map to `card()`)

Pitfalls:
- Put value boxes in `layout_columns(fill = FALSE)`, or they stretch to fill the page height.
- `bsicons::bs_icon()` is the bslib-native icon set; `icon()` (Font Awesome) works too.

## shinydashboard (legacy dashboards)

Header + optional sidebar + body of `box()`es. Still on CRAN but in maintenance mode; new apps should use the bslib dashboard above. Read it so you can port old code.

```r
library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "Twin Cities Buses"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    fluidRow(
      column(width = 9,
        box(width = NULL, solidHeader = TRUE, plotOutput("busmap", height = 500))
      ),
      column(width = 3,
        box(width = NULL, status = "warning",
          selectInput("interval", "Refresh interval", c("30 s" = 30, "1 min" = 60)),
          actionButton("refresh", "Refresh now")
        )
      )
    )
  )
)
```

Port map: `dashboardPage` -> `page_sidebar`/`page_navbar`; `dashboardSidebar(sidebarMenu(menuItem()))` -> `page_navbar(nav_panel())`; `box()` -> `card()`; `valueBox()`/`infoBox()` -> `value_box()`; `box(status = "warning")` -> `card(class = "border-warning")`.

Source: `086-bus-dashboard`

## Themes

Restyle the whole app (colours, fonts, Bootswatch theme) from R.

```r
library(shiny)
library(bslib)

ui <- page_navbar(
  title = "Themed app",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",        # or preset = "shiny"; NULL for plain Bootstrap
    primary = "#00629B",
    base_font = font_google("Inter", local = FALSE)
  ),
  nav_panel("Inputs",
    textInput("txt", "Text input:", "general"),
    actionButton("action2", "Action button", class = "btn-primary")
  ),
  nav_spacer(),
  nav_item(input_dark_mode())
)

server <- function(input, output, session) {
  # bs_themer()   # live theme editor while developing (replaces shinythemes::themeSelector())
}
```

Source: `117-shinythemes`

Pitfalls:
- `shinythemes` (117) only does Bootstrap 3 and is superseded; use `bs_theme(bootswatch = "...")` and `bs_themer()`.
- `bs_themer()` is a dev tool; remove before deploying.
- `font_google()` downloads fonts at first run; use `local = FALSE` or a system font offline.

## Icons

Font Awesome icons for buttons, value boxes, nav items, via `icon()`.

```r
library(shiny)
ui <- fluidPage(
  actionButton("go", "Run", icon = icon("chart-line")),
  p(icon("github", lib = "font-awesome"), "Brand icons need no extra argument."),
  p(icon("flask"), icon("dna"), icon("microscope"), icon("vial"))
)
```

Source: `138-icon-fontawesome`

Pitfalls:
- FA4 names in old code (`eur`, `bar-chart-o`) warn or render blank; use the FA6 name (`euro-sign`, `chart-column`). Check names with `fontawesome::fa_metadata()$icon_names`.
- For Bootstrap Icons use `bsicons::bs_icon("name")`.

## Inline outputs in R Markdown / Quarto

Shiny inputs and `render*()` calls embedded directly in a document, including outputs inline in a sentence.

````markdown
---
title: "Inline output"
runtime: shiny            # Quarto: server: shiny
output: html_document
---

```{r}
selectInput("main", "Main title", LETTERS)
renderPlot(plot(cars, main = input$main), width = 600, height = 400)
```

The title is **`r renderText(input$main)`**.
````

Source: `026-shiny-inline`

Pitfalls:
- Inline `renderPlot()` needs explicit `width` and `height` in pixels.
- Needs a live R process (run with `rmarkdown::run()` or a Shiny server); it will not work as a static HTML file.
