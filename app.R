#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(plotly)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Relevanz von positiven Testergebnissen"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            numericInput("sensitivity", label = "Sensivität [%]", value = 94.4, min=0, max=100, step=.1), # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
            numericInput("specificity", label = "Spezifität [%]", value = 99.6, min=0, max=100, step=.1),
            numericInput("prevalence", label = "Prätestwahrscheinlichkeit [%]", value = 0.8, min=0, max=100, step=.1),
            h2("Ergebnis"),
            wellPanel(
                
                h5("Wie Wahrscheinlich positiv wenn Test postiv [%]"),
                tags$head(tags$style('h5 {color:blue;}')),
                verbatimTextOutput("PvPlus", placeholder = TRUE),
                h5("Wie Wahrscheinlich negativ wenn Test negativ [%]"),
                verbatimTextOutput("pvMinus", placeholder = TRUE)
            )
        ),
        

        # Show a plot of the generated distribution
        mainPanel(
            plotlyOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$distPlot <- renderPlotly({
        prevalence <- seq(0, 1, by = 0.0001)
        data <- tibble(prevalence = prevalence,
                       sensitivity = input$sensitivity/100,
                       specificity = input$specificity/100,
                       pvPlus = (prevalence*sensitivity)/((prevalence*sensitivity)+(1-prevalence)*(1-specificity)),
                       pvMinus = ((1-prevalence)*specificity)/(((1-prevalence)*specificity)+(prevalence*(1-sensitivity)))
        ) 
        data_point <- tibble(prevalence = input$prevalence/100,
                       sensitivity = input$sensitivity/100,
                       specificity = input$specificity/100,
                       pvPlus = (prevalence*sensitivity)/((prevalence*sensitivity)+(1-prevalence)*(1-specificity)),
                       pvMinus = ((1-prevalence)*specificity)/(((1-prevalence)*specificity)+(prevalence*(1-sensitivity)))
        ) 
        output$PvPlus <- renderText({ data_point$pvPlus*100 %>% round(digits = 2) })
        output$pvMinus <- renderText({ data_point$pvMinus*100 %>% round(digits = 1) })

        # draw the histogram with the specified number of bins
       p <-  ggplot(data, aes(prevalence, pvPlus, color = "Relevanz")) + geom_line() + geom_line(aes(y = pvMinus, color = "Trennfähigkeit")) +
            geom_point(data = data_point,aes(x = prevalence, y = pvMinus, color = "Trennfähigkeit")) + geom_point(data = data_point,aes(x = prevalence, y = pvPlus, color = "Relevanz")) +
            scale_color_manual(values = c(
            'Relevanz' = "red",
            'Trennfähigkeit' = "blue")) + labs( y = "Wahrscheinlichkeit", x = "Prätestwahrscheinlichkeit", title = "Beurteilung eines binären Klassifikators") + 
            labs(color='Vorhersagewert')
       
       p <- ggplotly(p, tooltip = c("Berechnet","Gemeldet", "Tag"))
       p
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
