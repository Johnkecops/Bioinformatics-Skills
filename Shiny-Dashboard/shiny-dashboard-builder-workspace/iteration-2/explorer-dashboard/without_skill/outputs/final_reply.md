Your dashboard is in `mtcars_app/app.R`.

What it does:
- **Sidebar:** checkboxes to filter by number of cylinders (4/6/8) and transmission (Automatic/Manual), plus the download button.
- **Scatter plot:** weight vs mpg, coloured by cylinders and shaped by transmission. Drag a box over points to select them. The box clears when the filters change.
- **Table underneath:** shows only the cars you brushed, with the car names in a column.
- **Download:** saves exactly what's in the table as a CSV (`mtcars_brushed_<date>.csv`).

To run it:

```r
shiny::runApp("mtcars_app")
```

I tested it with `shiny::testServer`. The filters subset the data correctly, and brushing the light cars (4 cylinders, manual) returned 6 cars. The downloaded CSV contained those same 6 rows. I didn't open it in a browser.

Until you brush something, the table is empty and the CSV contains only the column headers. If you'd rather it show all the filtered cars until you make a selection, that's a one-line change.
