library(shiny)
library(shinydashboard)
library(plotly)
library(shinyjs)
library(shinymaterial)

shinyUI(
  dashboardPage(title = 'RePrice', skin = 'blue',
    dashboardHeader(title = 'RePrice'),
      dashboardSidebar(
        sidebarMenu(
          menuItem('Dashboard', tabName = 'dashboard', icon = icon('dashboard'))
        )
      ),
      dashboardBody(
        useShinyjs(),
        tags$div(id="loading", 
                 style="position:fixed;top:0;left:0;width:100%;height:100%;background-color:#3c3c3c;z-index:100;display:flex;align-items:center;justify-content:center;", 
                 tags$img(src="Rolling-1s-200px.gif")
        ),
        tags$div(id = 'main-content',
          tabItems(
            tabItem(tabName = 'dashboard',
                    h3("Dashboard", class='body-title'),
                    div(id = "input_section",
                      fluidRow(
                        column(4, h4("Your App Monthly Price", style = "color: grey;")),
                        column(4, h4("Your App Category", style = "color: grey;"))
                      ),
                      fluidRow(
                        column(4,
                              numericInput("app_price_input", label = NULL, value = 15, min = 0)
                        ),
                        column(4,
                              textInput("text_input", label = NULL)
                        )
                      ),
                      fluidRow(
                        column(4,
                              actionButton("run_analysis", "Run Analysis")
                        )
                      )
                    ),
                    conditionalPanel(
                      condition = "input.run_analysis > 0",
                      fluidRow(
                        column(4,
                          actionButton("restart_analysis", "Restart Analysis", class = 'button-margin')
                        )  
                      ),
                      fluidRow(
                        valueBoxOutput('avg_price_box'),
                        valueBoxOutput('app_price_box')
                      ),
                      fluidRow(
                        box(title = 'Competitor Analysis - Pricing', solidHeader = TRUE,
                            width = 8, collapsible = TRUE,
                            plotlyOutput('comp_price_plot'))
                      ),
                      fluidRow(
                        box(title = 'Competitor Analysis - Ratings', solidHeader = TRUE,
                            width = 8, collapsible = TRUE,
                            plotlyOutput('comp_rate_plot'))
                      )
                    )
              )
            )
          ),
          tags$head(
            tags$link(rel = "stylesheet", type = "text/css", href = "midnight-skin.css"),
            tags$link(rel = 'stylesheet', type = 'text/css', href = 'header-style.css'),
            tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;700&display=swap"),
            tags$link(rel = 'stylesheet', type = 'text/css', href = 'body-title-style.css'),
            tags$link(rel = 'stylesheet', type = 'text/css', href = 'button-style.css'),
            tags$script(
              "$(document).on('click', '#restart_analysis', function() {
              location.reload();
              });
            "),
            tags$script("
            function hideMainContent() {
              $('#main-content').hide();
            }

            function showMainContent() {
              $('#main-content').show();
            }
          ")
          )
        )
  )
)