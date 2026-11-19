---
tags: [skill-creator]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

I teach a biostatistics class. I need a Shiny app where students upload a CSV (chick_weights.csv is an example of the kind of file they'll use), pick a numeric column and a grouping column from dropdowns that fill in from the uploaded file, see summary stats per group (n, mean, sd, missing values) and a boxplot, and then download a short HTML report with the table and the plot. Some files will have missing values. Make it in a folder upload_app.

Input files: chick_weights.csv
