
shinyApp(

  ui = shinyUI(pageWithSidebar(
    headerPanel("Testing Conflicting Widget IDs"),
    sidebarPanel(
      # Duplicate input IDs; App still loads
      selectInput("select", "Just a selector", c("p", "h2")),
      selectInput("select", "Another selector", c("h2", "p", "a"))
    ),
    mainPanel(
      wellPanel(htmlOutput("html"))
    )
  )),

  server = function(input, output, session) {

    output$html <- renderText(
     if (input$select == "p") {
        HTML("<div><p>This is a paragraph.</p></div>")
      } else {
        HTML("<div><h2>This is a heading</h2></div>")
      }
    )
  }
)
