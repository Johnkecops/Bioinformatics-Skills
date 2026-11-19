The app is in `modules_app/`. Run it with `shiny::runApp("modules_app")`.

```
modules_app/
├── app.R              navbarPage, wires the three modules together, URL bookmarking
├── R/mod_data.R       Data tab: pick iris / mtcars / ToothGrowth, shown in a DT table
├── R/mod_plot.R       Plot tab: ggplot histogram of a numeric column, with a bins slider
├── R/mod_model.R      Model tab: lm(y ~ x), progress bar, starts on the "Fit model" button
└── tests/test-modules.R   testServer checks for all three modules (shiny::runTests())
```

How it works:
- **Modules.** Each tab has its own `xxxUI(id)` / `xxxServer(id)` pair. Shiny sources files in `R/` automatically. `dataServer()` returns the chosen dataset as a reactive, and `plotServer()` and `modelServer()` take it as an argument. Their column dropdowns then update to show only the numeric columns of that dataset.
- **Progress bar.** `withProgress()` and `incProgress()` wrap the fit. `Sys.sleep(0.2)` runs 10 times to fake a slow fit, so it takes about 2 seconds. The fit runs only when the button is clicked. Changing x or y afterwards does not refit.
- **Bookmarking.** `enableBookmarking = "url"` is on and `ui` is a `function(request)`. The browser URL updates on every input change, so you can copy it at any time to save or share the current state: the active tab, the dataset, the plot column, the bins, x and y, and the last fitted model. Two cases need extra code, which may be useful to show students:
  - The column dropdowns are filled from the server, so Shiny can't restore their values on its own. `onRestore()` saves the bookmarked value and puts it back once the choices exist.
  - The button's click count isn't useful in a URL, so it is left out with `setBookmarkExclude("fit")`. The fitted formula is saved instead with `onBookmark()` / `state$values`, and a bookmarked URL fits the model again when it is opened. The DT table's helper inputs are also left out so the URL stays short.

What I checked: the module tests pass (the dataset is returned, the histogram renders, and the lm summary contains `R-squared`), and the full UI builds. I did not test opening a bookmarked URL in a browser, so please try that once. Pick a dataset, change some inputs, fit the model, reload the URL, and check that everything comes back.
