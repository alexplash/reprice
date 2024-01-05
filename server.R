library(shiny)
library(shinydashboard)
library(stringr)
library(purrr)
library(plotly)
library(reticulate)
library(shinyjs)
library(shinymaterial)
library(DBI)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(),
                 dbname = 'practicedatabase',
                 host = 'localhost',
                 port = 5432,
                 user = 'alexplash')

shinyServer(function(input, output, session) {
  
  shinyjs::hide('loading')
  shinyjs::show('main-content')
  
  observeEvent(input$run_analysis, {
    shinyjs::runjs('hideMainContent()')
    shinyjs::show('loading')
    shinyjs::hide("input_section")
    
    py_run_string(paste("import sys; sys.argv = ['webscrapeNOAI.py', '", input$text_input, "']; exec(open('/Users/alexplash/reprice/webscrapeNOAI.py').read())"))
    avg_price_from_py <- py$avg_price
    app_prices_from_py <- py$app_prices
    prices <- as.numeric(unlist(app_prices_from_py))
    app_titles_from_py <- py$app_titles
    app_ratings_from_py <- py$app_ratings
    
    data_to_save <- data.frame(
      Title = app_titles_from_py,
      Price = prices,
      Rating = app_ratings_from_py
    )

    dbWriteTable(con, 'app_data', data_to_save, append = TRUE, row.names = FALSE)
    
    output$avg_price_box <- renderValueBox({
      valueBox("Average P/M",
               sprintf('$%.2f monthly', avg_price_from_py),
               icon = icon('magnifying-glass-dollar'),
               color = 'aqua')
    })
    
    output$app_price_box <- renderValueBox({
      app_monthly_price <- input$app_price_input
      valueBox("App P/M",
               sprintf('$%.2f monthly', app_monthly_price),
               icon = icon('dollar-sign'),
               color = 'light-blue')
    })
    
    output$comp_price_plot <- renderPlotly({
      app_monthly_price <- input$app_price_input
      py_data <- data.frame(AppNames = app_titles_from_py, Prices = unlist(app_prices_from_py), yearly = FALSE)
      py_data$OriginallyZero <- py_data$Prices == 0
      py_data$Prices[py_data$OriginallyZero] <- avg_price_from_py
      data_combined <- rbind(py_data, data.frame(AppNames = "Your App", Prices = app_monthly_price, yearly = FALSE, OriginallyZero = FALSE))
      bar_colors <- ifelse(data_combined$AppNames == "Your App", "blue",
                           ifelse(data_combined$OriginallyZero, "orange", "lightblue"))
      plot_ly(data_combined, x = ~AppNames, y = ~Prices, type = 'bar', marker = list(color = bar_colors)) %>%
        layout(title = 'App Prices',
               xaxis = list(title = 'App Names'),
               yaxis = list(title = 'Dollars per Month'),
               plot_bgcolor = '#333333', 
               paper_bgcolor = '#333333', 
               font = list(color = "white"),
               margin = list(t = 60, b = 60))
    })
    
    output$comp_rate_plot <- renderPlotly ({
      py_rate_data <- data.frame(AppNames = app_titles_from_py, Ratings = unlist(app_ratings_from_py))
      bar_colors <- ifelse(py_rate_data$Ratings >= 4.0, "lightblue", "red")
      plot_ly(py_rate_data, x = ~AppNames, y = ~Ratings, type = 'bar', marker = list(color = bar_colors)) %>%
        layout(title = 'App Ratings',
               xaxis = list(title = 'App Names'),
               yaxis = list(title = 'Rating - of 5 Stars'),
               plot_bgcolor = '#333333', 
               paper_bgcolor = '#333333', 
               font = list(color = "white"),
               margin = list(t = 60, b = 60))
    })
    
    shinyjs::hide('loading')
    shinyjs::runjs('showMainContent()')
    
  })
  
  observeEvent(input$restart_analysis, {
    shinyjs::runjs('hideMainContent()')
    shinyjs::show('loading')
    updateNumericInput(session, "app_price_input", value = 15)
    updateTextInput(session, "text_input", value = "")
    shinyjs::show("input_section")
    shinyjs::hide('loading')
    shinyjs::runjs('showMainContent()')
  })
  
})
