library(tidyverse)
library(plotly)

sensitivity <- 1
specificity <- .990
prevalence <- 0.008


pvPlus <- (prevalence*sensitivity)/((prevalence*sensitivity)+(1-prevalence)*(1-specificity))

pvMinus <-((1-prevalence)*specificity)/(((1-prevalence)*specificity)+(prevalence*(1-sensitivity)))

# can be tested with Free statistical calculators https://www.medcalc.org/calc/diagnostic_test.php
# theory is given at https://de.wikipedia.org/wiki/Beurteilung_eines_binären_Klassifikators#Positiver_und_negativer_Vorhersagewert
prevalence <- seq(0, 1, by = 0.02)


data <- tibble(prevalence = prevalence,
               sensitivity = .95,
               specificity = 0.9901,
               pvPlus = (prevalence*sensitivity)/((prevalence*sensitivity)+(1-prevalence)*(1-specificity)),
               pvMinus = ((1-prevalence)*specificity)/(((1-prevalence)*specificity)+(prevalence*(1-sensitivity)))
               ) 


p <-ggplot(data, aes(prevalence, pvPlus, color = "Relevanz")) + geom_line() + geom_line(aes(y = pvMinus, color = "Trennfähigkeit")) +   scale_color_manual(values = c(
  'Relevanz' = "red",
  'Trennfähigkeit' = "blue")) + labs( y = "Wahrscheinlichkeit", x = "Prätestwahrscheinlichkeit", title = "Beurteilung eines binären Klassifikators") + 
    labs(color='Vorhersagewert')

p <- ggplotly(p)
p <- p %>% layout(legend = list(x = 0.45, y = 0.21, font = list(size = 8)))
p

