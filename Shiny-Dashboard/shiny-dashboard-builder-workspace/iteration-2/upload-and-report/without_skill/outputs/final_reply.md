The app is in `upload_app/app.R`. It's one file and uses only shiny, ggplot2 and knitr.

**To run it:** `shiny::runApp("upload_app")`

**What students do:**
1. Upload a CSV.
2. Pick a **numeric column**. This dropdown lists only the numeric columns in their file.
3. Pick a **grouping column**. This dropdown lists every column, so a numeric code like `Diet` also works as a group.
4. Look at the table and the boxplot. The table shows each group's `n`, `missing`, `mean` and `sd`. The boxplot has the individual points drawn over it.
5. Click **Download HTML report** to get one self-contained `.html` file with the table and the plot inside it.

**How missing values are handled:**
- `NA` and blank cells are read as missing.
- `n` counts the values that aren't missing. `missing` counts the NAs, and they are left out of the mean and sd. The report includes a note saying this.
- Rows with a missing group value are shown as their own group, labelled "(missing)", so nothing disappears without a trace.

**Report without pandoc:** pandoc isn't installed, so the report is written as plain HTML and the plot is embedded as an image. That means rmarkdown/pandoc isn't needed on the machine running the app, or on the students' machines.

**Tested with chick_weights.csv** (weight by Diet), in an automated server test with the report download included. The 6 NA weights are reported correctly: 2 each in Diets 1, 2 and 4, none in Diet 3. Group means range from 102.4 to 143.0, and the downloaded report contains both the table and the plot.

**Not included:** statistical tests (ANOVA, Kruskal-Wallis) and a choice of plot types. Let me know if you want ANOVA or Kruskal-Wallis results added to the table.
