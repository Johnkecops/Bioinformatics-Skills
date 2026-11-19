# Static data and small pure helpers shared by the modules.
# Defined in R/ (not in app.R) so every module file can see them.

# Loaded once per R process, shared by all visitors.
datasets <- list(iris = iris, mtcars = mtcars, ToothGrowth = ToothGrowth)

# Names of the numeric columns: the only ones a histogram or lm(y ~ x) can use.
numeric_cols <- function(df) names(df)[vapply(df, is.numeric, logical(1))]

# Choose what a column picker should show after the dataset changes:
# the first wanted value the new dataset still has, otherwise the default.
# `wanted` is e.g. c(bookmarked value, current value).
pick_col <- function(wanted, cols, default = cols[1]) {
  ok <- wanted[wanted %in% cols]
  if (length(ok)) ok[1] else default
}
