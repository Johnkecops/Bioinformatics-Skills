I built the dashboard and checked it. It's a single file: `mtcars_app/app.R`.

**What's in it**
- **Sidebar:** checkboxes for the number of cylinders (4/6/8) and transmission type (Automatic/Manual). Everything is selected when the app starts. If you untick every box in a group, the app shows a short message instead of an R error.
- **Scatter plot:** weight (`wt`) against mpg. Point colour shows cylinders and point shape shows transmission. Drag a box on the plot to select cars. If you change a filter, the box is cleared so it can't end up over a different set of points.
- **Table:** sits under the plot and shows only the cars inside the box, with the car name as the first column. Its header shows the count, for example "Brushed cars (6 of 13 shown)".
- **Download button** in the sidebar: saves the table's current contents as `mtcars-brushed-<date>.csv`. The table and the download read the same data, so the CSV always matches what's on screen.

**Install and run**
```r
install.packages(c("shiny", "bslib", "ggplot2", "DT"))
shiny::runApp("mtcars_app")
```

**Testing**
- The skill's checker passed parsing, loading, rendering the UI and running all four outputs (plot, table title, table and CSV download).
- It reported one error, "input `scatter_brush` not present in UI". That error is wrong: the brush ID sits on the plot as `data-brush-id`, and the checker doesn't look for plot brush/click/hover IDs.
- I tested the brush separately with `testServer()`:
  - A box over wt 2 to 3 and mpg 20 to 35 selected 7 cars, the same count you get by filtering `mtcars` directly.
  - With only Manual ticked, it selected 6.
  - The downloaded CSV had those 6 rows, with the car name in the first column.

**Left out:** nothing you asked for. There's no zoom, click-to-select or plotly lasso. If you'd like any of those, I can add them.
