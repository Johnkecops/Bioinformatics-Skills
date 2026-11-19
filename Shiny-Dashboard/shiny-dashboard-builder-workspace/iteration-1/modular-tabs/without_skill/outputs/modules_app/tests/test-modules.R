# Run from the app folder with: shiny::runTests()
library(shiny); library(ggplot2); library(DT)
for (f in list.files("../R", full.names = TRUE)) source(f)

testServer(dataServer, {
  session$setInputs(dataset = "mtcars")
  stopifnot(identical(session$returned(), mtcars))
})

data <- reactiveVal(iris)

testServer(plotServer, args = list(data = data), {
  session$setInputs(col = "Sepal.Width", bins = 10)
  stopifnot(inherits(output$hist, "list"))   # plot rendered
})

testServer(modelServer, args = list(data = data), {
  session$setInputs(x = "Petal.Width", y = "Petal.Length", fit = 1)
  stopifnot(grepl("Petal.Width", output$summary), grepl("R-squared", output$summary))
})

cat("All module tests passed\n")
