The app is in `upload_app/` and works on `chick_weights.csv`, including the HTML report download.

**Files**
- `upload_app/app.R` is the whole app.
- `upload_app/report_template.Rmd` is the report layout. You can edit it to change the downloaded report.
- `test_upload_app.R` is a check that runs without a browser. Run it with `Rscript test_upload_app.R`.
- `sample_report.html` is a report the app produced from `chick_weights.csv`.

**How it works for students**
1. Upload a CSV.
2. The two dropdowns fill in from the file. "Numeric column" lists only numeric columns. "Grouping column" lists every column and starts on the one with the fewest distinct values, so for the chick data it starts on `Diet` rather than `weight`.
3. The table shows **n, missing, mean and sd** for each group, and the boxplot appears below it. The boxplot draws the individual points over the boxes.
4. "Download HTML report" saves one HTML file containing the file name, the chosen columns, the row and missing counts, the table and the plot. The plot is built into the file, so the report opens offline.

**How missing values are handled**
- Empty cells and `NA` both count as missing.
- `n` counts only non-missing values. `missing` is the number of NAs in each group. Mean and sd ignore NAs.
- Rows with no group label form their own `(missing)` group, so they still show up in the table.
- A group with only one value gets sd `-`, and a group with no values gets mean `-` instead of an error.
- If a file has no numeric column, isn't a CSV, or a student picks the same column twice, the app shows a plain message instead of a red R error.

**Install and run**
```r
install.packages(c("shiny", "bslib", "ggplot2", "knitr", "markdown"))
shiny::runApp("upload_app")
```
The report is built with `knitr` and `markdown`, so it does **not** need pandoc or RStudio. It works from plain R on any machine.

**Testing**
- With `chick_weights.csv` the app gives 4 diets, 572 non-missing weights and 6 missing (2, 2, 0 and 2 per diet). The downloaded report contains both the table and the plot.
- I also checked group labels that are missing, a group where every value is missing, and picking the same column in both dropdowns.
- The skill's own checker (`check_app.R`) reports one error: `value_col` and `group_col` not found in the UI. This is a false alarm. The checker skips dropdowns that start with no choices, and these two start empty on purpose until a file is uploaded.

**Left out**
- Statistical tests such as ANOVA or Kruskal-Wallis.
- Choice of plot type.
- PDF or Word reports, which would need pandoc.

I can add any of these if you want them.
