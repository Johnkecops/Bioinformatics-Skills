---
tags: [skill-creator]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Build a Shiny app for my R course with a navbar and three tabs: 'Data' (pick a built-in dataset: iris, mtcars or ToothGrowth, and show it), 'Plot' (histogram of a chosen numeric column of that dataset, with a bins slider) and 'Model' (fit a linear model y ~ x on two chosen columns, show the summary; pretend the fit is slow and show a progress bar while it runs, triggered by a button). Each tab should be its own Shiny module. Users should be able to bookmark the app state via the URL. Folder: modules_app.
