The dashboard is ready in `mtcars_app/app.R`. It's a single file that uses bslib, ggplot2 and DT.

**What it does**
- **Sidebar:** checkboxes for the number of cylinders (4/6/8) and for transmission (Automatic/Manual). Everything is ticked at the start.
- **Scatter plot:** weight vs mpg, coloured by cylinders. You can drag a box over points to select them. When you change a filter, the box is cleared so the table doesn't keep showing cars from the previous view.
- **Table underneath:** shows only the cars inside the box. It's sortable and searchable, and the car names are a proper `car` column. When nothing is selected it shows "Drag a box over points in the plot to list cars here."
- **Download button:** saves the same rows as the table to `mtcars-brushed-<date>.csv`. If nothing is selected you get a CSV with only the column headers. No extra plotting columns are added to the file.
- If you untick every cylinder or every transmission box, the app shows a message asking you to select at least one, not an R error.

**Install packages and run**
```r
install.packages(c("shiny", "bslib", "ggplot2", "DT"))
shiny::runApp("mtcars_app")
```
Open it in a browser to download, because the RStudio Viewer pane sometimes blocks downloads.

**Testing**
- The skill's headless checker passed with `RESULT: 0 error(s), 0 warning(s)`.
- I also ran a test with a simulated box over wt 2–3 and mpg 20–35. It returned 7 cars, starting with Mazda RX4 and Datsun 710. The downloaded CSV had the same cars in the same order. Changing the filters updated the selection correctly.
- I haven't tried dragging a box by hand in a real browser.

**Not included:** clicking a single point to select it, and zooming. Either can be added from the same brush setup if you want it.
