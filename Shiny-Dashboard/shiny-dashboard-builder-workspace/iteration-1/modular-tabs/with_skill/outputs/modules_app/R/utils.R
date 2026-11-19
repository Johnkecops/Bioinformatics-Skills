# Names of the numeric columns of a data frame (used by the Plot and Model pickers).
# Lives in R/ so app.R and every module can see it.
numeric_cols <- function(df) names(df)[vapply(df, is.numeric, logical(1))]
