#################################################################################################################################
# This script analyzes output of "SMS Backup & Restore" Android app in order to extract and analyse a bunch of numbers in 
# spam-numbers.xml file. General goal of this script is to analyse spam advertisements of Iranian telecom companies. currently
# spam-numbers.xml only contains Irancell-related spam numbers.
# Author: Gholamreza Sabery Tabrizy
# Email: reza_sabery_89@yahoo.com
# Blog: http://www.saberynotes.com
# License: GPL V.2; for more information refer to LICENSE file.
#################################################################################################################################


g1 <- c(main_title="تعداد پیامهای تبلیغاتی ارسال شده",
        x_label="ماه",
        y_label="تعداد پیامهای ارسالی",
        subtitle="http://www.saberynotes.com")


g2 <- c(main_title="تعداد پیامهای تبلیغاتی ارسال شده از هر آدرس" ,
        x_label="آدرس" ,
        y_label="تعداد پیامها" ,
        subtitle="http://www.saberynotes.com")


g3 <- c(main_title="ابر کلمات برای همه پیامها" ,
        subtitle="http://www.saberynotes.com")


g4 <- c(main_title="ابر کلمات برای آدرس" ,
        subtitle="http://www.saberynotes.com")

get_graph_text <- function(graph_name) {
  if(graph_name=="g1")
    g1
  else if(graph_name=="g2")
    g2
  else if(graph_name=="g3")
    g3
  else if(graph_name=="g4")
    g4
  else
    stop("Invalid graph name!")
}