The app is in `modules_app/`. It has a bslib navbar with three tabs, and each tab is its own module built on `moduleServer()`:

```
modules_app/
  app.R            # page_navbar + wiring, enableBookmarking = "url"
  R/helpers.R      # datasets list, numeric_cols(), pick_col()
  R/mod_data.R     # data_ui()  / data_server()  -> returns list(data, name) reactives
  R/mod_plot.R     # plot_ui()  / plot_server(id, data, name)
  R/mod_model.R    # model_ui() / model_server(id, data, name)
```

Shiny loads everything in `R/` automatically, so `app.R` has no `source()` calls.

**What each tab does**
- **Data:** pick iris, mtcars or ToothGrowth and see it in a DT table. This module owns the dataset choice. It returns the dataset as a reactive, and the other two modules receive that reactive (passed uncalled), so they update when the dataset changes.
- **Plot:** a ggplot2 histogram of a numeric column, with a bins slider (5 to 50). The column list changes with the dataset. If the column you picked also exists in the new dataset, it stays selected.
- **Model:** pick y and x from the numeric columns, then click **Fit model** to fit `lm(y ~ x)` and see `summary()`. The fit only runs when you click the button (`bindEvent`). A `withProgress()` bar runs 10 steps of 0.2 s each to pretend the fit is slow. The printed call reads like `lm(formula = mpg ~ wt, data = mtcars)`.

**Bookmarking:** there is a **Bookmark** button in the navbar. The link it gives you stores the open tab, the dataset, the histogram column and bins, and the model's x and y.

One thing needed extra handling. A bookmarked column such as `mpg` isn't in the column list when the app first loads, because that list starts with iris's columns. Each module saves the bookmarked value with `onRestore()` and selects it again once the list has been updated. The Fit button is left out of bookmarks with `setBookmarkExclude("fit")`, so opening a bookmark doesn't fit the model straight away. Click Fit after opening the link.

**What students see instead of R errors**
- Picking the same column for x and y shows "Choose two different columns: y ~ y is not a model."
- Before the first click, the Model tab says "Choose y and x, then click 'Fit model'."
- A dataset name hand-edited into the URL shows "Choose one of the listed datasets."
- While the column list is changing after a dataset switch, the plot shows a short "Updating the column list..." message.
- Fitting doesn't start until both pickers have a value (`req()`).

**Install and run**
```r
install.packages(c("shiny", "bslib", "ggplot2", "DT"))
shiny::runApp("modules_app")
```

**Checks**
- The skill's `check_app.R` passed with `RESULT: 0 error(s), 0 warning(s)`. All 4 outputs render. The model summary stays empty until the button is clicked, which is intended.
- I also ran `testServer()` on each module. Switching to mtcars updates the column list, `y ~ y` gives the message above, and `len ~ dose` on ToothGrowth fits and prints. A bad dataset name in the URL gives a readable message.
- I rendered the UI from a bookmark URL. It came back on the Model tab with mtcars selected.
- I didn't open the app in a browser, so the progress bar and the Bookmark button's dialog haven't been seen working.

**Not included**
- The fit runs in the main session. That is fine for a 2-second demo, but a really slow model would freeze the app for that user while it runs. For that case, look at `ExtendedTask` with `bslib::input_task_button`.
- The address bar doesn't change as you click around; users get a link by pressing Bookmark. If you want the URL to update on every change, add an observer that calls `session$doBookmark()` and `onBookmarked(updateQueryString)`.
