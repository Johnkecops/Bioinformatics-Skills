# Headless check of the upload -> summary -> report path.
# Run from this folder:  Rscript test_upload_app.R
library(shiny)
csv <- normalizePath("chick_weights.csv")
setwd("upload_app")
app <- source("app.R")$value  # also defines the helpers here

testServer(app, {
  session$setInputs(file = data.frame(name = "chick_weights.csv", size = file.size(csv),
                                      type = "text/csv", datapath = csv))
  session$setInputs(value_col = "weight", group_col = "Diet")
  print(summary_tbl())
  stopifnot(nrow(summary_tbl()) == 4, sum(summary_tbl()$missing) == 6,
            sum(summary_tbl()$n) == 572, inherits(box_plot(), "ggplot"))
  h <- paste(readLines(output$download_report, warn = FALSE), collapse = "\n")
  stopifnot(grepl("<table", h), grepl("data:image/png;base64", h))
  session$setInputs(group_col = "weight")  # same column twice -> message, not crash
  stopifnot(grepl("different columns", tryCatch(summary_tbl(), error = conditionMessage)))
})

# Missing group labels form their own group; a group with only NAs gives n = 0.
s <- summarise_groups(data.frame(y = c(1, NA, 3, NA), g = c("a", "a", NA, "b")), "y", "g")
print(s)
stopifnot(identical(s$g, c("(missing)", "a", "b")), identical(s$n, c(1L, 1L, 0L)),
          identical(s$missing, c(0L, 1L, 1L)), is.na(s$mean[3]))
cat("ALL CHECKS PASSED\n")
