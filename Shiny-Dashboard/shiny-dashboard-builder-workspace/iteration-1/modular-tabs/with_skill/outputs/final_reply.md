The app is in `modules_app/`. It passes the headless smoke test (`RESULT: 0 error(s), 0 warning(s)`), and I also tested the modules and bookmark restore directly.

## Files

```
modules_app/
  app.R            # navbar page, wires the 3 modules, turns on URL bookmarking
  R/utils.R        # numeric_cols() helper, used by app.R and the modules
  R/mod_data.R     # data_ui() / data_server()   -> 'Data' tab
  R/mod_plot.R     # plot_ui() / plot_server()   -> 'Plot' tab
  R/mod_model.R    # model_ui() / model_server() -> 'Model' tab
```

Shiny loads everything in `R/` automatically, so `app.R` has no `source()` calls.

## How it works

- **Data:** you pick iris, mtcars or ToothGrowth and it is shown in a DT table. `data_server()` returns the chosen data frame as a **reactive**. The other two modules receive that reactive without calling it (`dataset`, not `dataset()`), so all three tabs always use the same dataset.
- **Plot:** a ggplot2 histogram of one numeric column, with a bins slider (5-50). When the dataset changes, the column list switches to that dataset's numeric columns. Your current choice is kept if the new dataset has that column too.
- **Model:** you choose y and x from the numeric columns. Clicking **Fit model** runs `lm(y ~ x)`. The fit is wrapped in `withProgress()` with ten 0.2 s steps to fake a slow model. `bindEvent(input$fit)` means changing a dropdown does not start a fit. If x and y are the same column you get a readable message, not an R error.
- **Bookmarking:** the app uses `enableBookmarking = "url"`, and the UI is a function of `request`.
  - The address bar updates whenever an input changes, so copying the URL saves the current state. The "Share link" button in the navbar does the same thing.
  - The selected tab is saved too (`page_navbar(id = "tab")`).
  - DT's internal table inputs are left out of the URL so it stays short.
  - Restoring had one catch. A bookmarked column such as `mtcars`/`hp` would be lost if the pickers were first built with iris columns. To prevent this, the UI reads the bookmarked dataset with `restoreInput()` and builds the pickers with that dataset's columns. If someone edits the dataset name in the URL to something invalid, the app falls back to iris.

## Install and run

```r
install.packages(c("shiny", "bslib", "ggplot2", "DT"))
shiny::runApp("modules_app")
```

## Checks run

- `scripts/check_app.R`: 0 errors, 0 warnings.
- `testServer()` on the Model module (mtcars, `mpg ~ wt`): the summary renders. With x = y it shows "Choose two different columns for x and y".
- `testServer()` on the Plot module: the histogram renders.
- UI restore from a bookmark URL (`mtcars`, `hp`, `wt`) selects the right options. An invalid dataset name in the URL falls back to iris.

## Notes

- The model's x and y are numeric columns only, so for ToothGrowth that means `len` and `dose`. `supp` is a factor and is not offered.
- The Fit button's click count is part of the bookmark. A shared link opened after a fit therefore re-runs the fit, with its progress bar, and shows the summary. To make people click Fit again instead, add `setBookmarkExclude("fit")` inside `model_server()`.
- `plotly` and `dplyr` were not needed.
