The app is in `modules_app/app.R`. Run it with `shiny::runApp("modules_app")`.

**Layout:** a `bslib::page_navbar` with three tabs. Each tab is its own module, written as a `xxxUI(id)` / `xxxServer(id)` pair:

- **Data** (`dataUI` / `dataServer`): you pick iris, mtcars or ToothGrowth and the dataset is shown in a DT table. The server returns the dataset as a reactive, and the other two modules receive that reactive as an argument. This is the standard way to pass data between modules.
- **Plot** (`plotUI` / `plotServer`): a histogram of a numeric column you choose, with a bins slider. The column list updates when you change the dataset.
- **Model** (`modelUI` / `modelServer`): you choose y and x, then click **Fit model**. The app fits `lm(y ~ x)` inside `withProgress()`, with a `Sys.sleep()` loop standing in for a slow fit, and prints `summary()`. The printed call shows the real formula, for example `lm(formula = mpg ~ wt, ...)`.

**Bookmarking:** the app uses `enableBookmarking = "url"`, `ui` is written as `function(request)`, and there is a **Bookmark** button in the navbar. Clicking it gives a URL that restores the dataset, the plot column, the bins, x and y, and the active tab (the navbar has `id = "tabs"`). Inputs inside modules are bookmarked under their namespaced IDs automatically.

**Teaching points in the code:**
- The column selectors are built with `renderUI`. `selectInput()` restores bookmarked values by itself. Without `outputOptions(..., suspendWhenHidden = FALSE)`, a selector on a hidden tab would not restore.
- The **Fit model** button is left out of the bookmark. Otherwise opening a bookmark would refit the model on load. After a restore, students click Fit again.
- DT's housekeeping inputs (rows_all, search and so on) are also left out of the bookmark, so the URL stays short.

**Verified:** all three module servers pass `shiny::testServer` checks. The Data module returns the chosen dataset, the histogram renders, and the coefficients match `lm(mpg ~ wt, mtcars)`. I did not open the app in a browser, so the bookmark round-trip itself has not been tested. Click Bookmark once to confirm it.
