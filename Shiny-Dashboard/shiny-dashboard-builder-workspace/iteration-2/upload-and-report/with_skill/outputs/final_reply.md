I built the app in `upload_app/`. I ran it against `chick_weights.csv` and against several bad files (results below).

**Files**
- `upload_app/app.R`: the app.
- `upload_app/report.Rmd`: the template for the downloadable report.

**What it does**
- Students upload a CSV. The numeric-column dropdown then lists only the file's numeric columns, and the grouping dropdown lists all of its columns. For `chick_weights.csv` the defaults are `weight` and `Diet`.
- A table shows each group's **n** (non-missing values), **mean**, **sd** and **missing** count. Missing values are left out of the mean and sd. Rows with a missing group get their own group called "(missing group)", so they don't disappear without notice.
- A ggplot boxplot of the numeric column for each group.
- **Download HTML report** saves one self-contained HTML file. It lists the file name and the columns chosen, then shows the table and the boxplot (the plot is built into the file). Pandoc isn't installed on this machine, so the report is made with `knitr` + `markdown`, which don't need it. The download therefore works from plain R, not only from RStudio.

**What students see when something goes wrong** (a short message instead of an R error)
- No file uploaded yet: "Upload a CSV file to begin."
- A file that isn't a CSV, or a file that can't be read
- A file with no numeric columns
- The same column picked as both the value and the group
- A numeric column that is entirely missing

**Install and run**
```r
install.packages(c("shiny", "bslib", "ggplot2", "knitr", "markdown"))
shiny::runApp("upload_app")
```

**Test results**
- The skill's smoke test (`check_app.R`) reported 0 errors and 0 warnings.
- I also ran the app's server code headlessly with `chick_weights.csv`. Grouped by Diet it gives 4 groups, 572 non-missing values and 6 missing, matching the 6 NAs in `weight`. The downloaded report contained both the table and the embedded plot.
- The bad files (no numeric columns, a `.xlsx` file, the same column chosen twice, NA groups, a group whose values are all missing) each showed the message listed above.
- I didn't open the app in a browser, so the dropdown refresh after an upload is untested in a real session.

**Left out on purpose:** upload size is capped at 20 MB, only comma-separated `.csv` files are accepted (no TSV or Excel), and the report is HTML only (no PDF or Word). If you want any of these, I can add them.
