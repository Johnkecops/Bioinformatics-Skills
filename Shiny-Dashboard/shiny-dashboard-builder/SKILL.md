---
name: shiny-dashboard-builder
description: Build, extend, debug or explain R Shiny apps and dashboards by assembling proven patterns from a bundled catalog of ~170 RStudio Shiny examples (layouts, widgets, reactivity, plots, tables, file upload/download, Rmarkdown reports, modules, dynamic UI, plot brushing/clicking, async, bookmarking, custom JavaScript), modernized to bslib and current Shiny idioms, with a script that smoke-tests the finished app headlessly. Use this whenever the user wants a Shiny app, an interactive R dashboard, a web front-end for an R analysis, or asks how to do something in Shiny (add a download button, tabs, filters, a reactive, a module, a map, an upload form, a progress bar), even if they don't say "Shiny" but are working in R and want something interactive in a browser. Also use for Shiny teaching material and for fixing broken Shiny code.
---

# Shiny dashboard builder

Shiny code written from memory tends to fail in the same few ways: output IDs that don't
match between UI and server, inputs read before they exist, heavy work re-run on every
keystroke, outdated idioms (`shinythemes`, `callModule`, `renderCachedPlot`), and archived
packages. This skill avoids those by building from tested patterns and checking the result.

Bundled material (paths relative to this file):

| Path | What it is | When to read |
|---|---|---|
| `references/catalog.md` | Every example: folder, title, tags, files, packages, legacy flag, grouped by category | To find which example shows a feature |
| `references/<category>.md` | Patterns per category, modern snippets, pitfalls, source example | For each feature the app needs |
| `references/full-dashboards.md` | Anatomy of the complete apps + **assembly rules** | Before assembling anything bigger than one plot |
| `assets/templates/single-file/app.R` | Sidebar + value boxes + plot + table + download | Default starting point |
| `assets/templates/multi-file/` | `global.R` / `ui.R` / `server.R` / `R/` module, navbar | Multi-page apps, or more than ~150 lines |
| `assets/examples/<folder>/` | Original example source (MIT, RStudio) | Only when a reference file's snippet is not enough |
| `scripts/check_app.R` | Headless smoke test | After writing the app, every time |
| `scripts/build_catalog.R` | Regenerates `catalog.md` | Only when examples are added |

## Category index

| Need | Reference |
|---|---|
| Page structure: sidebar, navbar, tabs, columns, cards, value boxes, themes, shinydashboard | `layouts.md` |
| Widgets, selectize, dates, `update*Input`, validation | `inputs.md` |
| Plots, tables, DT, text, images, HTML/markdown, **file upload, download, Rmd reports**, htmlwidgets, caching | `outputs.md` |
| `reactive`/`observe`/`bindEvent`, action buttons, timers, debounce, file polling | `reactivity.md` |
| `renderUI`, `conditionalPanel`, `insertUI`, modals, notifications, progress bars | `dynamic-ui.md` |
| Click/hover/brush on plots, selecting/excluding/zooming points | `plot-interaction.md` |
| Modules, sub-apps, `R/` folder | `modules.md` |
| Long computations without freezing (ExtendedTask, promises/future) | `async.md` |
| Bookmarking, URL query strings, client data | `state.md` |
| Custom HTML templates, JS ↔ R messages, custom inputs, htmlwidgets hooks | `javascript.md` |

Read only the files the request needs. A filter-plot-table-download dashboard needs
`layouts.md`, `inputs.md`, `outputs.md`, `reactivity.md` and the assembly rules. Each
reference file opens with a Contents list: read it, then jump to the sections you need
(e.g. `grep -n "^## " references/outputs.md`) instead of reading 500 lines top to bottom.

## Robustness checklist

Users of these apps (often students) will untick every box, upload the wrong file, and
pick the same column twice. Before calling the app done, make each of these produce a
readable message via `validate(need(...))` inside the shared reactive, not a blank area
or a red R error:

- every filter cleared / multi-select emptied;
- uploaded file missing, not a CSV, or without the column types the app needs;
- two pickers set to the same column where that makes no sense (e.g. `y ~ y`);
- server-filled pickers still `NULL` when a button is clicked (`req()`).

`validate()` only shows text when it runs inside a render function or a reactive that a
render function reads; inside `observe()` it is silently swallowed. Keep helper columns
used only for plotting (relabelled factors etc.) out of tables and downloads.

## Workflow

1. **Pin down the app.** Data source (built-in dataset, uploaded CSV, file on disk), what
   the user controls (inputs), what they see (outputs), and how many pages. If the request
   leaves these open, choose sensible defaults and state them rather than asking a long
   list of questions. If the user gives real data, read its columns first so names in code
   are right.
2. **Start from a template.** Copy `assets/templates/single-file/app.R` or the
   `multi-file/` folder into the user's project. Keep its shape: static data loaded once
   at top level → one shared `reactive()` for the filtered/processed data → every output
   reads that reactive.
3. **Add each feature from its reference file.** Use the reference snippet; open the cited
   example under `assets/examples/` only when you need more context. Apply the assembly
   rules in `full-dashboards.md`.
4. **Use current idioms.** The examples date from 2013-2020. Translate as you copy:

   | Old (in examples) | Use instead |
   |---|---|
   | `fluidPage(sidebarLayout(...))`, `navbarPage`, `shinythemes` | `bslib::page_sidebar`, `page_navbar`, `bs_theme()` (classic still works; fine when editing old code) |
   | `wellPanel` boxes, `shinydashboard::box`/`valueBox` | `card()`, `value_box()`, `layout_columns()` |
   | `callModule(mod, "id")` | `mod_server("id")` built on `moduleServer()` |
   | `observeEvent`/`eventReactive` | still fine; `reactive(...) \|> bindEvent(input$go)` is shorter |
   | `renderCachedPlot` | `renderPlot(...) \|> bindCache(...)` |
   | plain promise + `future` for slow work | `ExtendedTask` + `bslib::input_task_button` |
   | `ggvis`, `rCharts`/nvd3, `googleCharts`, `bubbles`, `shinySignals`, `rgdal` | `ggplot2`/`plotly`, `plotly`, `plotly`, `plotly`, `reactive()`, `sf` |

   When editing a user's existing classic-Shiny app, match its style instead of
   converting it wholesale; mixing paradigms inside one file is harder to read than either.
5. **Write the server as `function(input, output, session)`.** Many features
   (`updateSelectInput`, modals, `session$ns`) need `session`, and adding it later is a
   common source of "object 'session' not found".
6. **Check it.** Run from this skill's directory:

   ```bash
   Rscript scripts/check_app.R <path/to/app_dir>
   ```

   It parses all files, loads the app, renders the UI, cross-checks every `input$`/`output$`
   ID used in the server against the UI, then runs the server under `testServer()` with
   inputs at their UI defaults (and again after clicking every action button), evaluating
   every output including downloads. Fix every `ERROR` and re-run until `RESULT: 0 error(s)`.
   `WARN` lines usually come from dynamic UI or modules — read them, fix the real ones.
   Exit status is 1 on any error.

   Limits worth knowing: inputs created by `renderUI` start unset, so outputs that need
   them report `silent` (stopped by `req()`), not `ok`; JavaScript does not run; an
   uploaded file is never simulated. For an upload app, also test the processing function
   directly on a sample CSV. If a package is missing, the load step names it — install it
   or pick an installed alternative, and tell the user.

   **Reports:** `rmarkdown::render()` needs pandoc, which ships with RStudio but is often
   missing for plain `Rscript` (check `rmarkdown::pandoc_available()`). If it is missing
   where the app will run, render HTML with `knitr::knit()` + `markdown::mark_html()`
   (no pandoc; tested snippet in `outputs.md`, "HTML download without pandoc"), or keep rmarkdown and tell the user the app needs
   RStudio/pandoc. Always exercise the report download once (the checker does this when
   the download button is visible at startup; otherwise call it in `testServer()`).
7. **Deliver.** Give the user: the files (written into their project, not only pasted),
   the packages to install as one `install.packages(c(...))` line, how to run
   (`shiny::runApp("dir")`), the checker result, and anything deliberately left out.

## Code style for generated apps

- Comment the *why* at each reactive and each non-obvious pattern, briefly. Apps from this
  skill are often read by students learning Shiny; a one-line comment like
  `# one shared reactive: filtering runs once, not once per output` teaches more than
  restating the code.
- Guard optional inputs with `req()`; give users readable messages with
  `validate(need(cond, "message"))` instead of red R errors.
- Name IDs for what they hold (`species`, `scatter`, `download_csv`), not `select1`/`plot1`.
- Load packages with `library()` at the top; avoid `require()` inside the server.
- No `<<-` for state; use `reactiveVal()` / `reactiveValues()`.
- Keep data loading outside `server` unless it depends on the user (e.g. uploads).
- With an `R/` folder, put helpers the modules call in `R/` (or `global.R`), not in
  `app.R`: files in `R/` are sourced into a separate environment and cannot see
  functions defined in `app.R`.
- Guard every input that the server fills later (`updateSelectInput` after an upload or
  dataset switch) with `req()` before use. The checker leaves such inputs unset, so a
  missing guard shows up there as an error.

## Teaching requests

When the user wants to explain a concept (e.g. "show my students the difference between
`reactive` and `observe`"), prefer the smallest example that isolates the concept. The
numbered example folders were designed exactly for this; cite them by name
(e.g. `088-action-pattern1` … `092-action-pattern5`) and give the modern rewrite from the
reference file alongside.
