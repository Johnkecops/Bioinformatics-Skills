function(input, output, session) {
  filtered <- reactive({
    req(input$supp)
    dat[dat$supp %in% input$supp, , drop = FALSE]
  })

  # Modules receive reactives (not their values) so they stay live.
  explore_server("explore", data = filtered)

  output$summary <- renderTable(
    aggregate(len ~ supp + dose, data = filtered(), FUN = mean)
  )
}
