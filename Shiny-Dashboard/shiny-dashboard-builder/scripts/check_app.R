#!/usr/bin/env Rscript
# Smoke-test a Shiny app directory without a browser.
#
# Usage: Rscript check_app.R <app_dir>
#
# Steps
#   1. parse every .R file                      -> syntax errors
#   2. load the app (shinyAppDir)               -> missing packages, top-level errors
#   3. render the UI to HTML                    -> bad UI arguments; collect input/output IDs
#   4. compare IDs used in server code vs UI    -> typos like output$plot1 vs plotOutput("plot")
#   5. run the server under testServer() with every input set to its UI default,
#      evaluate each output, then "click" every action button once and evaluate again
#                                               -> runtime errors in render functions
# Exit status 0 = no errors (warnings may still be printed), 1 = at least one error.
#
# Limits: inputs created by renderUI/insertUI are not in the static HTML, so they
# start unset; outputs that need them show as "silent" (req() stopped them), not as
# errors. htmlwidget outputs are evaluated but not drawn. JavaScript is not run.

suppressPackageStartupMessages({ library(shiny); library(xml2) })

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1 || !dir.exists(args[1])) stop("Usage: Rscript check_app.R <app_dir>")
dir <- normalizePath(args[1])
errors <- character(); warns <- character()
err  <- function(...) { m <- paste0(...); errors <<- c(errors, m); cat("ERROR:", m, "\n") }
warn <- function(...) { m <- paste0(...); warns <<- c(warns, m); cat("WARN: ", m, "\n") }
finish <- function() {
  cat(sprintf("\nRESULT: %d error(s), %d warning(s)\n", length(errors), length(warns)))
  quit(status = if (length(errors)) 1 else 0, save = "no")
}

# 1. parse -------------------------------------------------------------------
rfiles <- list.files(dir, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
rfiles <- rfiles[!grepl("/(www|tests|rsconnect)/", rfiles)]
if (!length(rfiles)) { err("no .R files in ", dir); finish() }
for (f in rfiles) tryCatch(parse(f), error = function(e) err("parse ", basename(f), ": ", conditionMessage(e)))
if (length(errors)) finish()
cat("OK    parse:", length(rfiles), "file(s)\n")

# 2. load --------------------------------------------------------------------
old <- setwd(dir)
app <- tryCatch(shinyAppDir(dir), error = function(e) { err("load: ", conditionMessage(e)); NULL })
if (is.null(app)) finish()
cat("OK    load\n")

# 3. UI HTML -----------------------------------------------------------------
req <- new.env()
req$PATH_INFO <- "/"; req$REQUEST_METHOD <- "GET"; req$QUERY_STRING <- ""; req$HTTP_HOST <- "localhost"
res <- tryCatch(app$httpHandler(req), error = function(e) { err("UI render: ", conditionMessage(e)); NULL })
if (is.null(res)) finish()
html <- read_html(paste(res$content, collapse = "\n"))
cat("OK    UI renders\n")

attr_or <- function(n, a) { v <- xml_attr(n, a); ifelse(is.na(v), "", v) }
out_nodes <- xml_find_all(html, "//*[contains(@class,'shiny-') and contains(@class,'-output') and @id]
                                   | //*[contains(@class,'html-widget-output') and @id]")
ui_outputs <- unique(xml_attr(out_nodes, "id"))
dl_ids <- unique(xml_attr(xml_find_all(html, "//*[contains(@class,'shiny-download-link') and @id]"), "id"))
ui_outputs <- unique(c(ui_outputs, dl_ids))

# Collect inputs and their default values as Shiny would send them.
defaults <- list(); buttons <- character()
num <- function(x) suppressWarnings(as.numeric(x))
for (n in xml_find_all(html, "//input[@id] | //select[@id] | //textarea[@id]")) {
  id <- xml_attr(n, "id"); type <- attr_or(n, "type"); cls <- attr_or(n, "class")
  if (type == "file") next
  if (grepl("js-range-slider", cls)) {
    from <- attr_or(n, "data-from"); to <- attr_or(n, "data-to")
    defaults[[id]] <- if (nzchar(to)) num(c(from, to)) else num(from)
  } else if (xml_name(n) == "select") {
    sel <- xml_text(xml_find_all(n, ".//option[@selected]"))
    vals <- xml_attr(xml_find_all(n, ".//option[@selected]"), "value")
    v <- ifelse(is.na(vals), sel, vals)
    if (!length(v) && is.na(xml_attr(n, "multiple"))) {   # single select: first option
      first <- xml_find_first(n, ".//option"); if (!is.na(first)) v <- xml_attr(first, "value")
    }
    # selectize keeps choices in a JSON script sibling when server-side; leave unset then
    if (length(v)) defaults[[id]] <- v
  } else if (type == "checkbox" && !nzchar(attr_or(n, "name"))) {
    defaults[[id]] <- !is.na(xml_attr(n, "checked"))
  } else if (type == "number") {
    defaults[[id]] <- num(attr_or(n, "value"))
  } else if (type %in% c("text", "password", "") || xml_name(n) == "textarea") {
    defaults[[id]] <- if (xml_name(n) == "textarea") xml_text(n) else attr_or(n, "value")
  }
}
for (g in xml_find_all(html, "//*[contains(@class,'shiny-input-radiogroup') or contains(@class,'shiny-input-checkboxgroup')][@id]")) {
  id <- xml_attr(g, "id")
  v <- xml_attr(xml_find_all(g, ".//input[@checked]"), "value")
  defaults[[id]] <- if (grepl("radiogroup", xml_attr(g, "class"))) (if (length(v)) v[1] else NULL) else v
}
for (d in xml_find_all(html, "//*[contains(@class,'shiny-date-input') or contains(@class,'shiny-date-range-input')][@id]")) {
  dates <- xml_attr(xml_find_all(d, ".//input"), "data-initial-date")
  dates <- ifelse(is.na(dates) | dates == "", as.character(Sys.Date()), dates)
  defaults[[xml_attr(d, "id")]] <- as.Date(dates)
}
for (b in xml_find_all(html, "//*[contains(@class,'action-button') and @id]")) buttons <- c(buttons, xml_attr(b, "id"))
buttons <- unique(buttons)
# Plot interactions (brush/click/dblclick/hover) create inputs named in data-*-id attributes.
plot_ev <- unlist(lapply(c("brush", "click", "dblclick", "hover"), function(k)
  xml_attr(xml_find_all(html, sprintf("//*[@data-%s-id]", k)), sprintf("data-%s-id", k))))
# Every input element counts as present, even one with no default yet (e.g. an empty
# selectInput that the server fills after an upload).
ui_inputs <- unique(c(names(defaults), buttons, plot_ev,
  xml_attr(xml_find_all(html, "//input[@id] | //select[@id] | //textarea[@id]"), "id")))
cat(sprintf("OK    UI ids: %d input(s), %d button(s), %d output(s)\n",
            length(ui_inputs), length(buttons), length(ui_outputs)))

# 4. ID cross-check ----------------------------------------------------------
code <- paste(unlist(lapply(rfiles, readLines, warn = FALSE)), collapse = "\n")
code <- gsub("#[^\n]*", "", code)  # drop comments
grab <- function(prefix) {
  a <- regmatches(code, gregexpr(paste0("\\b", prefix, "\\$([A-Za-z_][A-Za-z0-9_.]*)"), code))[[1]]
  b <- regmatches(code, gregexpr(paste0("\\b", prefix, "\\[\\[\\s*[\"']([^\"']+)[\"']\\s*\\]\\]"), code))[[1]]
  unique(c(sub(".*\\$", "", a), sub(".*[\"']([^\"']+)[\"'].*", "\\1", b)))
}
has_modules <- grepl("moduleServer|callModule|NS\\(", code)
dynamic_ui  <- grepl("renderUI|insertUI|insertTab|appendTab", code)
srv_out <- grab("output"); srv_in <- grab("input")
# In modules, IDs in the UI are prefixed ("mod-plot"); compare on the last segment.
tail_id <- function(x) sub(".*-", "", x)
miss_ui <- setdiff(srv_out, tail_id(ui_outputs))
if (length(miss_ui)) (if (dynamic_ui) warn else err)(
  "server assigns output(s) with no matching UI element: ", paste(miss_ui, collapse = ", "))
unused <- setdiff(tail_id(ui_outputs), srv_out)
if (length(unused) && !has_modules) warn("UI output(s) never assigned in server: ", paste(unused, collapse = ", "))
miss_in <- setdiff(srv_in, c(tail_id(ui_inputs), tail_id(ui_outputs)))
miss_in <- miss_in[!grepl("^(\\.clientdata|_)", miss_in)]
if (length(miss_in)) (if (dynamic_ui || has_modules) warn else err)(
  "server reads input(s) not present in UI: ", paste(miss_in, collapse = ", "))

# 5. server run --------------------------------------------------------------
srv <- tryCatch(app$serverFuncSource(), error = function(e) NULL)
if (!is.null(srv) && !("session" %in% names(formals(srv)))) {
  # testServer() insists on a session argument; wrap two-argument servers.
  warn("server is function(input, output); prefer function(input, output, session)")
  inner <- srv
  app$serverFuncSource <- function() function(input, output, session) inner(input, output)
}
eval_outputs <- function(output, label) {
  for (id in setdiff(ui_outputs, if (!has_modules) unused)) {  # unused already reported
    r <- tryCatch({
        v <- output[[id]]
        # A download output returns the path of the file its content() wrote.
        if (id %in% dl_ids && !(is.character(v) && file.exists(v) && file.size(v) > 0))
          stop("download produced no file or an empty file")
        "ok"
      },
      shiny.silent.error = function(e) "silent",
      error = function(e) paste("error:", conditionMessage(e)))
    if (startsWith(r, "error")) {
      if (grepl("not found|Couldn't find output", r) && has_modules) next  # module-internal id
      err(sprintf("output '%s' (%s) %s", id, label, r))
    } else cat(sprintf("      output %-24s %s (%s)\n", id, r, label))
  }
}
run <- tryCatch(testServer(app, {
  if (length(defaults)) do.call(session$setInputs, defaults)
  session$flushReact()
  eval_outputs(output, "defaults")
  if (length(buttons)) {
    do.call(session$setInputs, setNames(as.list(rep(1L, length(buttons))), buttons))
    session$flushReact()
    eval_outputs(output, "after clicks")
  }
}), error = function(e) err("server: ", conditionMessage(e)))
setwd(old)
finish()
