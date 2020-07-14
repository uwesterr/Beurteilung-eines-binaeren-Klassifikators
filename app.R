# can be tested with Free statistical calculators https://www.medcalc.org/calc/diagnostic_test.php
# theory is given at https://de.wikipedia.org/wiki/Beurteilung_eines_binären_Klassifikators#positivr_und_negativr_Vorhersagewert
if (!("caret" %in% rownames(installed.packages()))) install.packages("caret")

library(shiny)
library(tidyverse)
library(plotly)
library(shinyWidgets)
library(caret)

# Define UI for application that draws a histogram
ui <- function(request) {
  
  
  # widgets website https://shiny.rstudio.com/gallery/widget-gallery.html
  navbarPage(title = h3("Aussagekraft von medizinischen Tests v. 0.2"),  position = c("static-top"), theme = "bootstrap.css", 
             
             tabPanel("Einstellung und Ausgabe",
                      # Application title
                      tags$head(tags$style('h1 {color:blue;   text-align: center;}')),
                      
                      
                      tags$head(tags$style('h3 {color:blue;}')),
                      tags$head(tags$style('h2 {color:blue;}')),
                      
                      
                      # Sidebar with a slider input for number of bins 
                      sidebarLayout(
                        
                        
                        sidebarPanel( width = 2,
                                      setBackgroundColor("#ECF0F5"
                                                         # color = c("#F7FBFF", "#2171B5"),
                                                         # gradient = "radial",
                                                         # direction = c("top", "left")
                                      ),
                                      h3("Testparameter"),
                                      numericInput("sensitivity", label = h4("Sensivität [%]"), value = 94.4, min=0, max=100, step=.1), # numbers are from https://www.cegat.de/diagnostik/corona-diagnostik/
                                      numericInput("specificity", label = h4("Spezifität [%]"), value = 99.6, min=0, max=100, step=.1),
                                      numericInput("prevalence", label = h4("Basisrate [%]"), value = 0.85, min=0, max=100, step=.1),
                                      wellPanel(
                                        h3("Vordefinierte Szenarien"),
                                        helpText("Wählen Sie ein Szenario das Sie interessiert"),
                                        
                                        actionButton("Antikoerper", label = "Antikörper"),
                                        actionButton("Mammographie", label = "Mammographie"),
                                        actionButton("PSA", label = "PSA")),
                                      # actionButton("Anleitung", label = "Anleitung")),
                                      
                                      
                                      tags$hr(),
                                      
                                      wellPanel(
                                        tags$div(
                                          HTML(paste("Source code available on",
                                                     tags$a(href="https://github.com/uwesterr/Beurteilung-eines-binaeren-Klassifikators", "GitHub"))))),
                        ),
                        
                        
                        # Show a plot of the generated distribution
                        mainPanel( width = 10,
                                   wellPanel(
                                     h1(textOutput("title_panel")),
                                     wellPanel(
                                       h2("Was bedeutet ein Testergebnis für den Getesteten?"),
                                       tags$div(id = 'placeholder'),
                                   
                                       
                                       fluidRow(
                                         column(6,
                                                h3("Positiver Vorhersagewert [%]"),
                                                
                                                HTML("<strong>Positiver Vorhersagewert:</strong> Wahrscheinlichkeit, dass der Getestete bei positivem Testergebnis positiv ist"),
                                                
                                                tags$head(tags$style('h5 {color:blue;}')),
                                                verbatimTextOutput("PvPlus", placeholder = TRUE)),
                                         column(6,
                                                h3("Negativer Vorhersagewert [%]"),
                                                HTML("<strong>Negativer Vorhersagewert:</strong> Wahrscheinlichkeit, dass der Getestete bei negativem Testergebnis negativ ist "),
                                                
                                                
                                                verbatimTextOutput("pvMinus", placeholder = TRUE)
                                         ))),
                                     
                                     
                                     tags$hr(), 
                                   
                                 
                                     fluidRow(
                                       column(6,
                                              h3("Wahrheitsmatrix für 100.000 Getestete "),
                                              plotOutput("confusionMat"),
                                              tags$hr(), 
                                              helpText("In der Wahrheitsmatrix geben die Zahlen in den grün hinterlegten Felder korrekte Testergebnisse, 
                     in den rot hinterlegten Feldern inkorrekte Anzahl von Testfällen wieder."),
                                              helpText("Je mehr Fälle inkorrekt postiv getestet werden, desto geringer ist der Positive Vorhersagewert, da die Testperson nicht unterscheiden kann, ob sie korrekt oder inkorrekt positiv getestet wurde."),
                                       ),
                                       column(6,
                                              h3("Einfluss der Basisrate auf Vorhersagewerte"),
                                              plotlyOutput("distPlot"),
                                              tags$hr(), 
                                              helpText("Den Einfluss der Basisrate auf den

Positiven und
Negativen Vorhersagewert
wird im nachfolgenden Graph verdeutlicht. Die grüne Linie zeigt den Wert der eingestellten Basisrate an."),
                                              helpText("Die Werte für Positiven und Negativen Vorhersagewert können aus dem Graph für andere Basisratenwerte abgelesen werden."),
                                              
                                       ),
                                       
                                     )),
                                   
                                   wellPanel(
                                     uiOutput("md_file"))
                                   
                        )
                      )
             ),
             
             
             tabPanel("Anleitung",
                      
                      # Show a plot of the generated distribution
                      mainPanel(
                        withMathJax(includeMarkdown("README.md"))
                      )
             ))        
  
  
}

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  output$title_panel = renderText({"Aussagekraft eines Antikörpertests"})
  output$confusionMat <-  renderPlot({
    # browser()
    total <- 1e5
    
    positiv <- (total * input$prevalence/100) %>% round(digits = 0)
    negativ <-( total -positiv) %>% round(digits = 0)
    TP <- (positiv * input$sensitivity/100) %>% round(digits = 0)
    TN  <- (negativ * input$specificity/100) %>% round(digits = 0)
    FN <-  positiv - TP
    FP <- negativ - TN
    
    
    predictions <- c(
      rep("positiv",TP),
      rep("negativ", FN),
      rep("negativ", TN),
      rep("positiv", FP)) %>% factor(levels = c("positiv", "negativ"))
    
    
    groundtruth <- c(
      rep("positiv", positiv),
      rep("negativ", negativ)) %>% factor(levels = c("positiv", "negativ"))
    xtab <- table(predictions, groundtruth)
    
    cmtrx <- confusionMatrix(xtab, positiv = "positiv")
    total <- sum(cmtrx$table)
    res <- as.numeric(cmtrx$table)
    # Generate color gradients. Palettes come from RColorBrewer.
    greenPalette <- c("#F7FCF5","#E5F5E0","#C7E9C0","#A1D99B","#74C476","#41AB5D","#238B45","#006D2C","#00441B")
    redPalette <- c("#FFF5F0","#FEE0D2","#FCBBA1","#FC9272","#FB6A4A","#EF3B2C","#CB181D","#A50F15","#67000D")
    getColor <- function (greenOrRed = "green", amount = 0) {
      if (amount == 0)
        return("#A1D99B")
      palette <- greenPalette
      if (greenOrRed == "red")
        palette <- redPalette
      colorRampPalette(palette)(100)[10 + ceiling(90 * amount / total)]
    }
    # set the basic layout
    layout(matrix(c(1,1,1)))
    par(mar=c(3,3,3,3))
    plot(c(100, 345), c(300, 450), type = "n", xlab="", ylab="", xaxt='n', yaxt='n')
    # title('Wahrheitsmatrix für 100.000 Getestete \n', cex.main=3.5)
    # create the matrix
    classes = colnames(cmtrx$table)
    
    
    rect(135, 370, 345, 430, col= "#b3b3ff", density = 80) # positiv test
    rect(150, 441, 240, 300, col= "#b3b3ff", density = 80)  # positiv wahrheit
    rect(250, 441, 340, 300, col= "#e6b3ff", density = 80)  # negativ wahrheit
    text(195, 435, classes[1], cex=2.7)
    
    rect(150, 430, 240, 370, col= "#A1D99B")
    rect(250, 430, 340, 370, col= "#FC9272")
    text(295, 435, classes[2], cex=2.7)
    text(125, 370, 'Testergebnis', cex=2.7, srt=90, font=2)
    text(245, 450, 'Wahrheit', cex=2.7, font=2)
    rect(135, 305, 345, 365, col= "#e6b3ff", density = 80) # negativ test
    rect(150, 305, 240, 365, col= "#FC9272")
    rect(250, 305, 340, 365, col= "#A1D99B")
    text(140, 400, classes[1], cex=2.7, srt=90)
    text(140, 335, classes[2], cex=2.7, srt=90)
    # add in the cmtrx results
    text(195, 400, res[1], cex=2.6, font=2, col='blue')
    text(195, 385, "Richtig positiv", cex=2.0, font=2, col='darkgreen')
    text(195, 335, res[2], cex=2.6, font=2, col='blue')
    text(195, 320, "Falsch negativ", cex=2.0, font=2, col='darkred')
    
    text(295, 400, res[3], cex=2.6, font=2, col='blue')
    text(295, 385, "Falsch positv", cex=2.0, font=2, col='darkred')
    
    text(295, 335, res[4], cex=2.6, font=2, col='blue')
    text(295, 320, "Richtig negativ", cex=2.0, font=2, col='darkgreen')
    

  })
  
  
  output$md_file <- renderUI({
    file <-  "Antikoerper.md"
    withMathJax(
      includeMarkdown(file))
  })
  
  

  
  observeEvent(input$Antikoerper, {
    output$title_panel = renderText({"Aussagekraft eines Antikörpertests"})
    
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
    output$title_panel = renderText({"Aussagekraft einer Mammographie"})
    
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
  
  
  
  observeEvent(input$PSA, {
    output$title_panel = renderText({"Aussagekraft eines PSA-Tests"})
    isolate({
    updateNumericInput(session, inputId = "sensitivity", value = 91)  
    updateNumericInput(session, inputId = "specificity", value = 91)
    updateNumericInput(session, inputId = "prevalence", value = 0.1) # https://www.prostata.de/prostatakrebs/was-ist-pca/haeufigkeit-des-prostatakarzinoms
    })
     output$md_file <- renderUI({
      file <-  "PSA.md"
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
    output$PvPlus <- renderText({ data_point$Positiver_Vorhersagewert %>% round(digits = 6) *100})
    output$pvMinus <- renderText({ data_point$Negativer_Vorhersagewert %>% round(digits = 6) *100})
    # browser()
    colnames(data)[colnames(data) == "prevalence"] <- "Basisrate"
    colnames(data)[colnames(data) == "pvPlus"] <- "Positiver_Vorhersagewert"
    colnames(data)[colnames(data) == "pvMinus"] <- "Negativer_Vorhersagewert"
    
    colnames(data_point)[colnames(data_point) == "prevalence"] <- "Basisrate"
    colnames(data_point)[colnames(data_point) == "pvPlus"] <- "Positiver_Vorhersagewert"
    colnames(data_point)[colnames(data_point) == "pvMinus"] <- "Negativer_Vorhersagewert"
    # browser()
    # draw the histogram with the specified number of bins
    p <-  ggplot(data, aes(x= Basisrate, Positiver_Vorhersagewert*100)) + geom_line(aes(color = "Positiver Vorhersagewert")) + 
      geom_line(aes(y = Negativer_Vorhersagewert *100, color = "Negativer Vorhersagewert")) +
      geom_point(data = data_point,aes(x = Basisrate, y = Negativer_Vorhersagewert*100, color = "Negativer Vorhersagewert")) +
      geom_point(data = data_point,aes(x = Basisrate, y = Positiver_Vorhersagewert*100, color = "Positiver Vorhersagewert")) +
      labs( y = "Wahrscheinlichkeit [%]", x = "Basisrate") + 
      labs(color='Vorhersagewert') + xlim(0,1) +geom_vline(aes(xintercept = data_point$Basisrate , color = "Eingestellte Basisrate"))  +
      scale_color_manual(values = c('Positiver Vorhersagewert' = "red",'Negativer Vorhersagewert' = "blue", 'Eingestellte Basisrate' = "green"))
    
    
    p <- ggplotly(p)
    #       p <- ggplotly(p, tooltip = c("Erfasste_Infizierte", "Berechnete_Infizierte", "Tag", "Erfasste_Todesfaelle", "Berechnete_Todesfaelle"))
    
    p <- p %>% layout(legend = list(x = 0.45, y = 0.21, font = list(size = 12)))
    p
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
