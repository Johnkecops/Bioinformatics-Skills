#!/usr/bin/env Rscript
# Build references/catalog.md from the bundled example folders.
#
# Usage: Rscript scripts/build_catalog.R <examples_dir> <output_md>
# Default: assets/examples -> references/catalog.md (run from the skill root).
#
# Category assignment is a hand-reviewed map below. Any folder not in the map
# makes the script stop, so a new example cannot slip in uncategorised.

args <- commandArgs(trailingOnly = TRUE)
ex_dir <- if (length(args) >= 1) args[1] else "assets/examples"
out    <- if (length(args) >= 2) args[2] else "references/catalog.md"

categories <- list(
  layouts = c("001-hello", "006-tabsets", "015-layout-navbar", "015-layout-sidebar",
    "027-absolutely-positioned-panels", "052-navbar-example", "053-navlistpanel-example",
    "057-plot-plus-three-columns", "067-vertical-layout", "083-front-page",
    "084-single-file", "117-shinythemes", "138-icon-fontawesome", "144-colors",
    "026-shiny-inline", "503-server-function", "502-random-number"),
  inputs = c("005-sliders", "007-widgets", "013-selectize", "017-select-vs-selectize",
    "021-selectize-plot", "023-optgroup-server", "024-optgroup-selectize",
    "037-date-and-date-range", "062-submitbutton-demo", "065-update-input-demo",
    "068-widget-action-button", "069-widget-check-group", "070-widget-checkbox",
    "071-widget-date", "072-widget-date-range", "073-widget-file", "074-widget-numeric",
    "075-widget-radio", "076-widget-select", "077-widget-slider", "078-widget-slider-range",
    "079-widget-submit", "080-widget-text", "081-widgets-gallery", "140-selectize-inputs",
    "157-date-format", "158-input-labels", "160-select-input", "163-select-factor",
    "170-date-range-max", "183-sv-simple", "184-sv-deferred", "185-sv-custom-inputs"),
  outputs = c("002-text", "004-mpg", "009-upload", "010-download", "012-datatables",
    "016-knitr-pdf", "018-datatable-options", "019-mathjax", "020-knit-html",
    "022-unicode-chinese", "030-basic-datatable", "039-download-file", "047-image-output",
    "048-including-html-text-and-markdown-files", "054-nvd3-line-chart-output",
    "066-upload-file", "082-word-cloud", "109-render-table", "110-error-sanitization",
    "112-generate-report", "118-highcharter-births", "130-output-null",
    "131-renderplot-args", "136-plot-cache", "137-plot-cache-key", "145-dt-replacedata",
    "150-networkD3-sankey", "161-discrete-limits", "178-delayed-widget",
    "179-nondelayed-widget", "180-delayed-staticwidget", "182-google-charts"),
  reactivity = c("003-reactivity", "011-timer", "014-onflushed", "028-actionbutton-demo",
    "034-current-time", "049-isolate-demo", "055-observer-demo",
    "059-reactive-poll-and-file-reader", "088-action-pattern1", "089-action-pattern2",
    "090-action-pattern3", "091-action-pattern4", "092-action-pattern5",
    "142-reactive-timer", "152-set-reactivevalue", "159-rate-policy",
    "174-throttle-debounce"),
  `dynamic-ui` = c("025-loop-ui", "033-conditionalpanel-demo", "041-dynamic-ui",
    "085-progress", "111-insert-ui", "114-modal-dialog", "116-notifications",
    "119-namespaced-conditionalpanel-demo", "166-dynamic-hosted-tab"),
  `plot-interaction` = c("093-plot-interaction-basic", "094-image-interaction-basic",
    "095-plot-interaction-advanced", "096-plot-interaction-article-1",
    "097-plot-interaction-article-2", "098-plot-interaction-article-3",
    "099-plot-interaction-article-4", "100-plot-interaction-article-5",
    "101-plot-interaction-article-6", "102-plot-interaction-article-7",
    "103-plot-interaction-article-8", "104-plot-interaction-select",
    "105-plot-interaction-zoom", "106-plot-interaction-exclude",
    "139-plot-brush-scaling", "162-plot-dragging"),
  modules = c("108-module-output", "156-subapps", "168-supporting-r-dir",
    "186-sv-module-1", "187-sv-module-2", "188-sv-module-3"),
  async = c("121-async-timer", "122-async-outputs", "123-async-renderprint",
    "124-async-download", "125-async-req", "126-async-ticks", "127-async-flush",
    "129-async-perf", "132-async-events", "133-async-hold-inputs",
    "134-async-hold-timers", "143-async-plot-caching", "153-connection-header"),
  state = c("032-client-data-and-query-string", "113-bookmarking-url",
    "115-bookmarking-updatequerystring", "135-bookmark-uioutput"),
  javascript = c("008-html", "035-custom-input-bindings", "036-custom-input-control",
    "061-server-to-client-custom-messages", "107-events", "147-websocket", "149-onRender",
    "151-reactr-input", "154-index-html-server-r", "155-index-html-app-r",
    "169-prerender-a", "169-prerender-b", "175-setInputValue", "181-google-analytics"),
  `full-dashboards` = c("040-dynamic-clustering", "050-kmeans-example",
    "051-movie-explorer", "060-retirement-simulation", "063-superzip-example",
    "064-telephones-by-region", "086-bus-dashboard", "087-crandash", "120-goog-index",
    "141-radiant", "146-ames-explorer", "500-movie-browser", "501-movie-browser-nav")
)
# Regression tests for shiny itself; not reusable patterns. Kept out of assets.
excluded <- c("128-plot-dim-error", "148-addresourcepath-deleted", "164-no-whitespace",
  "165-trailing-comma", "167-resource-warnings", "171-path-traversal",
  "173-invalidatelater-leak", "176-jquery-3", "177-jquery-1")

# Packages that are archived, unmaintained, or GitHub-only. Examples using them
# still teach a valid pattern but the package call must be replaced.
legacy <- c(rgdal = "sf", ggvis = "ggplot2 or plotly", shinySignals = "reactive()/bindEvent()",
  bubbles = "plotly or echarts4r", googleCharts = "plotly", rCharts = "plotly",
  pryr = "lobstr", packrat = "renv", rgeos = "sf", maptools = "sf")

cat_of <- setNames(rep(names(categories), lengths(categories)), unlist(categories))
stopifnot(!anyDuplicated(unlist(categories)))

folders <- sort(list.dirs(ex_dir, full.names = FALSE, recursive = FALSE))
unknown <- setdiff(folders, names(cat_of))
if (length(unknown)) stop("Uncategorised example folders: ", paste(unknown, collapse = ", "))
missing <- setdiff(names(cat_of), folders)
if (length(missing)) warning("Mapped but absent: ", paste(missing, collapse = ", "))

dcf_field <- function(d, f) {
  p <- file.path(ex_dir, d, "DESCRIPTION")
  if (!file.exists(p)) return(NA_character_)
  x <- tryCatch(read.dcf(p, fields = f)[1, 1], error = function(e) NA_character_)
  if (is.na(x)) NA_character_ else trimws(gsub("\\s+", " ", x))
}

pkgs_of <- function(d) {
  files <- list.files(file.path(ex_dir, d), pattern = "\\.(R|r|Rmd)$", recursive = TRUE,
                      full.names = TRUE)
  txt <- unlist(lapply(files, readLines, warn = FALSE))
  m <- regmatches(txt, gregexpr("(library|require|requireNamespace)\\(['\"]?[A-Za-z0-9.]+", txt))
  p <- sub(".*\\(['\"]?", "", unlist(m))
  ns <- regmatches(txt, gregexpr("\\b[A-Za-z][A-Za-z0-9.]+(?=::)", txt, perl = TRUE))
  sort(setdiff(unique(c(p, unlist(ns))), c("shiny", "base", "utils", "stats", "methods")))
}

structure_of <- function(d) {
  f <- list.files(file.path(ex_dir, d))
  parts <- c(
    if (any(f == "app.R")) "app.R",
    if (any(tolower(f) == "ui.r")) "ui.R+server.R",
    if (any(tolower(f) == "global.r")) "global.R",
    if (any(f == "index.Rmd")) "index.Rmd",
    if (any(f == "R")) "R/",
    if (any(f == "www")) "www/",
    if (any(grepl("\\.(csv|tsv|rds|Rds|RData|xls|db|gz|geojson)$", f)) || any(f == "data")) "data")
  paste(parts, collapse = ", ")
}

rows <- lapply(folders, function(d) {
  p <- pkgs_of(d)
  lg <- intersect(p, names(legacy))
  data.frame(folder = d, category = cat_of[[d]],
    title = { t <- dcf_field(d, "Title"); if (is.na(t)) gsub("-", " ", sub("^\\d+-", "", d)) else t },
    tags = { t <- dcf_field(d, "Tags"); if (is.na(t)) "" else t },
    files = structure_of(d),
    packages = paste(p, collapse = " "),
    legacy = if (length(lg)) paste0(lg, " -> ", legacy[lg], collapse = "; ") else "",
    stringsAsFactors = FALSE)
})
tab <- do.call(rbind, rows)

esc <- function(x) gsub("|", "\\|", x, fixed = TRUE)
lines <- c("# Example catalog",
  "",
  "Generated by `scripts/build_catalog.R`. Do not edit by hand; edit the category map in the script.",
  "",
  sprintf("%d examples in %d categories. Source code: `assets/examples/<folder>/`.",
          nrow(tab), length(categories)),
  "Legacy column: package is archived/unmaintained; keep the pattern, swap the package as shown.",
  "",
  "## Contents",
  paste0("- [", names(categories), "](#", names(categories), ")"),
  "")
for (cg in names(categories)) {
  s <- tab[tab$category == cg, ]
  lines <- c(lines, paste0("## ", cg), "",
    "| folder | title | tags | files | packages | legacy |",
    "|---|---|---|---|---|---|",
    sprintf("| `%s` | %s | %s | %s | %s | %s |", s$folder, esc(s$title), esc(s$tags),
            s$files, s$packages, s$legacy),
    "")
}
writeLines(lines, out)
message("Wrote ", out, " (", nrow(tab), " examples)")
