Your dashboard is in `mtcars_app/app.R`, a single file.

**Run it** from the folder that contains `mtcars_app`:

```r
shiny::runApp("mtcars_app")
```

**What it has:**
- **Sidebar:** checkboxes for cylinders (4/6/8) and transmission (Automatic/Manual). Everything starts selected. The **Download table as CSV** button is here too.
- **Scatter plot:** weight vs mpg, coloured by cylinders, with a different point shape for each transmission. Drag a box over points to select them.
- **Table underneath:** shows only the brushed cars, after the sidebar filters are applied. It stays empty until you brush, and the brush clears when you change a filter.
- **Download:** saves exactly what's in the table to `brushed_cars_<date>.csv`, with the car name as its own column.

It needs the shiny, bslib, ggplot2 and DT packages.

I tested it headlessly with `shiny::testServer`. With the filters set to 4 and 6 cylinders and Manual, brushing wt 1.5 to 3 and mpg 20 to 35 returned the 10 matching cars, and the CSV download contained the same rows. I haven't opened it in a browser.

If you'd rather see all filtered cars in the table when nothing is brushed (instead of an empty table), that's a one-line change.
