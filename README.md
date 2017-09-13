# SMS-Adv-Analyser
SMS-Adv-Analyser is an open source (GPL V.2) project which provides you with a simple R script and some of the numbers that Irancell (an Iranian telecom company) uses to send spam advertisements. It can be used both as a database of Irancell-related (or any other operator) spam numbers and a way to analyse and assess their advertisements.

## Dependencies

A recent version of R. You should also install the following packages:

```
1. install.packages("lubridate")
2. install.packages("XML")
3. install.packages("dplyr")
4. install.packages("tm")
5. install.packages("SnowballC")
6. install.packages("wordcloud")
7. install.packages("ggplot2")
```
Graphs use a font called *BYagut* If you do not have it you can install it from fonts directory.

## Quick start

1. Open RStudio and run the **sms-analysis.R** script
2. A dialog will be shown, choose the XML result of *SMS Bacckup and Restore* app.
3. Results will be shown in *Plots* window of RStudio and it's *Console*.


## Files and folders


* **spam-numbers.xml**: This XML file currently contains a collection of Irancell-related spam addresses that I gathered. If you know more numbers you can add them here. Also you can include spam numbers of other providers and specify them using the provider attribute.

* **persian-stopwords**: Contains a comma-separated list of stopwords that will be automatically removed before creating wordclouds. If you want any word to be removed add it in this file. The list is a modified version of http://www.ranks.nl/stopwords/persian list.

* **fonts folder**: TTF files of fonts used in charts are here. Currently only BYagut.ttf.

* **graph-titles.R**: Here you can customize graph labels of each of the graphs separately.


## Authors


**Gholamreza Sabery Tabrizy**

**Email**: reza_sabery_89@yahoo.com

**Blog**: http://www.saberynotes.com