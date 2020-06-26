# Anleitung

##  Begriffsdefinitionen
Eine gute Übersicht über die Begriffe findet sich bei [Wikipedia](https://de.wikipedia.org/wiki/Beurteilung_eines_binären_Klassifikators#Sensitivität_und_Falsch-negativ-Rate)

### Sensivität 

Sensitivität entspricht bei einer medizinischen Diagnose dem Anteil an tatsächlich Kranken, bei denen die Krankheit auch erkannt wurde.

### Spezifität

Spezifität entspricht bei einer medizinischen Diagnose den Anteil der Gesunden an, bei denen auch festgestellt wurde, dass keine Krankheit vorliegt.

### Basisrate

Die Basisrate ist der Anteil der Menschen aus der Stichprobe welche die Krankheit bzw. das Merkmal aufweisen.  
Der positive Vorhersagewert profitiert von einer hohen Prätestwahrscheinlichkeit, der negative Vorhersagewert von einer niedrigen Basisrate. Ein positives medizinisches Testergebnis hat also eine viel höhere Aussagekraft, wenn der Test auf Verdacht durchgeführt wurde, als wenn er allein dem Screening diente.

### Relevanz
 Wahrscheinlichkeit das Getestete positiv ist bei positiven Testergebnis  
$$Relevanz = \frac{Prätestwahrscheinlichkeit * Sensitivität}
{Prätestwahrscheinlichkeit * Sensitivität + (1- Prätestwahrscheinlichkeit) * (1- Spezifität)} $$

### Trennfähigkeit
 Wahrscheinlichkeit das der Getestete negativ ist bei negativem Testergebnis

$$ Trennfähigkeit = \frac{(1-Prätestwahrscheinlichkeit) * Spezifität}
{(1-Prätestwahrscheinlichkeit) * Spezifität + (Prätestwahrscheinlichkeit) * (1- Sensitivität)} $$