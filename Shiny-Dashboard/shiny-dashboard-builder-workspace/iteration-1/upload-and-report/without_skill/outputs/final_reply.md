The app is in `upload_app/app.R`. To run it:

```r
shiny::runApp("upload_app")
```

**How students use it**
1. Upload a CSV.
2. The **Numeric column** dropdown fills with the file's numeric columns. The **Grouping column** dropdown fills with all of its columns.
3. The app shows a table with one row per group (n, n_missing, mean, sd) and a boxplot with the individual points jittered over it.
4. **Download HTML report** saves a single HTML file that holds the table and the plot.

**Missing values**
- Blank cells and `NA` are both read as missing.
- `n` counts every row in a group. `n_missing` counts the rows in that group with no value.
- Missing values are left out of the mean, the sd and the plot.
- Rows with no group value are kept and shown as a `(missing)` group, so no row disappears without being counted.

**Tested with chick_weights.csv** (weight by Diet): 578 rows in total, 6 of them missing. The results are below. `sample_report.html` is an example of the downloaded report.

| Diet | n | n_missing | mean | sd |
|---|---|---|---|---|
| 1 | 220 | 2 | 102.36 | 56.63 |
| 2 | 120 | 2 | 123.31 | 71.89 |
| 3 | 120 | 0 | 142.95 | 86.54 |
| 4 | 118 | 2 | 135.35 | 68.82 |

**Note:** the report doesn't use R Markdown, so pandoc is not needed. This means it works on lab machines that don't have pandoc. The plot is embedded in the file, so the report opens offline and can be submitted on its own.

**Not included:** statistical tests such as ANOVA or Kruskal-Wallis. I can add them if you'd like.
