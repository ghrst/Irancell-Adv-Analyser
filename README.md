# SMS-Adv-Analyser
SMS-Adv-Analyser is an open source (GPL V.2) project which provides you with a simple R script and some of the numbers that Irancell (an Iranian telecom company) uses to send spam advertisements. It can be used both as a database of Irancell-related (or any other operator) spam numbers and a way to analyse and assess their advertisements.


Usage
======

In order to use this project you should use **sms-analysis.R** script. This script uses two XML files. The first XML files should contain list of your SMS messages. This file should be obtained using **SMS Backup & Restore** Android app (com.riteshsahu.SMSBackupRestore). This app can be obtained using Google-play. Notice that you should provide the script with a backup of your **Text Messages**. The second XML file contains list of spam numbers of the provider. I tried to gather the list of spam numbers for Irancell (an Iranian telecom company). You can provide your own list, add new numbers to this file or use a completely new list. The format is easy to read and write. For executing the R-script you must install **XML, lubridate, tm, SnowballC, wordcloud and sqldf** libraries. In order to install these libraries use:

install.packages("lib-name")


Authors
======

**Gholamreza Sabery Tabrizy**

**Email**: reza_sabery_89@yahoo.com

**Blog**: http://www.saberynotes.com