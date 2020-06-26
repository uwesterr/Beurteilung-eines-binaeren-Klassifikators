# can be tested with Free statistical calculators https://www.medcalc.org/calc/diagnostic_test.php
# theory is given at https://de.wikipedia.org/wiki/Beurteilung_eines_binären_Klassifikators#Positiver_und_negativer_Vorhersagewert
library(shiny)
library(tidyverse)
library(plotly)

# Define UI for application that draws a histogram
ui <- fluidPage(
    
    # Application title
    tags$head(tags$style('h3 {color:blue;}')),
    tags$head(tags$style('h2 {color:blue;}')),
    
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        
        sidebarPanel(
            h3("Test Parameter"),
            numericInput("sensitivity", label = "Sensivität [%]", value = 90, min=0, max=100, step=.1), # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
            numericInput("specificity", label = "Spezifität [%]", value = 90, min=0, max=100, step=.1),
            numericInput("prevalence", label = "Basisrate [%]", value = 10, min=0, max=100, step=.1),
            wellPanel(
                h3("Ausgewählte Szenarien"),
                helpText("Wählen Sie ein Szenario das Sie interessiert"),
                
                actionButton("Antikoerper", label = "Antikörper"),
                actionButton("Mammographie", label = "Mammographie"),
                actionButton("Schwangerschaft", label = "Schwangerschaft"),
                actionButton("Anleitung", label = "Anleitung")),
        ),
        
        
        # Show a plot of the generated distribution
        mainPanel(
            wellPanel(
                
                wellPanel(
                    h2("Was bedeutet  Testergebnis für den Getesteten?"),
                    helpText("Was bedeutet ein positives bzw. \n negatives Testergebnis für den Getesteten?"),
                    HTML("<strong>Relevanz:</strong> Wahrscheinlichkeit das Getestete positiv ist bei positiven Testergebnis \n"),
                    p(),
                    HTML("<strong>Trennfähigkeit:</strong> Wahrscheinlichkeit das Getestete negativ ist bei negativem Testergebnis"),
                    
                    
                    fluidRow(
                        column(6,
                               h5("Relevanz [%]"),
                               tags$head(tags$style('h5 {color:blue;}')),
                               verbatimTextOutput("PvPlus", placeholder = TRUE)),
                        column(6,
                               
                               h5("Trennfähigkeit [%]"),
                               verbatimTextOutput("pvMinus", placeholder = TRUE)
                        ))),
                plotlyOutput("distPlot")),
            wellPanel(
                uiOutput("md_file"))
            
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    output$md_file <- renderUI({
        file <-  "Anleitung.md"
        withMathJax(
            includeMarkdown(file))
    })
    
    
    observeEvent(input$Anleitung, {
        
        output$md_file <- renderUI({
            file <-  "Anleitung.md"
            withMathJax(
                includeMarkdown(file))
        })
    })
    
    observeEvent(input$Antikoerper, {
        updateNumericInput(session, inputId = "sensitivity", value = 94.4)  # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
        updateNumericInput(session, inputId = "specificity", value = 99.6)
        updateNumericInput(session, inputId = "prevalence", value = 0.85) # https://www.ndr.de/nachrichten/info/coronaskript210.pdf seite 6
        output$md_file <- renderUI({
            file <-  "Antikoerper.md"
            withMathJax(
                includeMarkdown(file))
        })
    })
    
    
    
    observeEvent(input$Mammographie, {
        #https://www.laekh.de/images/Hessisches_Aerzteblatt/2016/12_2016/CME_12_2016_Was_Aerzte_wissen_muessen.pdf
        updateNumericInput(session, inputId = "sensitivity", value = 90)  # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
        updateNumericInput(session, inputId = "specificity", value = 91)
        updateNumericInput(session, inputId = "prevalence", value = 1) # https://www.ndr.de/nachrichten/info/coronaskript210.pdf seite 6
        output$md_file <- renderUI({
            file <-  "Mammographie.md"
            withMathJax(
                includeMarkdown(file))
        })
    })
    
    observeEvent(input$Schwangerschaft, {
        #https://www.laekh.de/images/Hessisches_Aerzteblatt/2016/12_2016/CME_12_2016_Was_Aerzte_wissen_muessen.pdf
        updateNumericInput(session, inputId = "sensitivity", value = 99.2)  # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
        updateNumericInput(session, inputId = "specificity", value = 99.91)
        updateNumericInput(session, inputId = "prevalence", value = 1/86) # https://www.ndr.de/nachrichten/info/coronaskript210.pdf seite 6
        output$md_file <- renderUI({
            file <-  "Mammographie.md"
            withMathJax(
                includeMarkdown(file))
        })
    })
    
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
        output$PvPlus <- renderText({ data_point$pvPlus %>% round(digits = 6) *100})
        output$pvMinus <- renderText({ data_point$pvMinus %>% round(digits = 6) *100})
        
        # draw the histogram with the specified number of bins
        p <-  ggplot(data, aes(prevalence, pvPlus, color = "Relevanz")) + geom_line() + geom_line(aes(y = pvMinus, color = "Trennfähigkeit")) +
            geom_point(data = data_point,aes(x = prevalence, y = pvMinus, color = "Trennfähigkeit")) + geom_point(data = data_point,aes(x = prevalence, y = pvPlus, color = "Relevanz")) +
            scale_color_manual(values = c('Relevanz' = "red",'Trennfähigkeit' = "blue")) + 
            labs( y = "Wahrscheinlichkeit", x = "Basisrate", title = "Grüne Linie ist bei der gewählten Basisrate") + 
            labs(color='Vorhersagewert') + xlim(0,1) +geom_vline(xintercept = data_point$prevalence, color = "green") #+
        #  annotate("text", x = data_point$prevalence , y = .5 , color = "red", label = "Gewählte Basisrate", angle = 90)
        #    geom_text(x=as.numeric(data_point$prevalence %>% max()), label="the weak cars", y=.5, colour="blue", angle=90)
        
        p <- ggplotly(p, tooltip = c("Relevanz","Trennfähigkeit"))
        p <- p %>% layout(legend = list(x = 0.45, y = 0.21, font = list(size = 12)))
        p
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
