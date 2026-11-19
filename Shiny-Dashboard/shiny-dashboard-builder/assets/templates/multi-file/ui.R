page_navbar(
  title = "Dashboard title",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    checkboxGroupInput("supp", "Supplement", choices = levels(dat$supp),
                       selected = levels(dat$supp))
  ),
  nav_panel("Explore", explore_ui("explore")),
  nav_panel("Summary", card(card_header("Group means"), tableOutput("summary")))
)
