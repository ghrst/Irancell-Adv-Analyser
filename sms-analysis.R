#################################################################################################################################
# This script analyzes output of "SMS Backup & Restore" Android app in order to extract and analyse a bunch of numbers in 
# spam-numbers.xml file. General goal of this script is to analyse spam advertisements of Iranian telecom companies. currently
# spam-numbers.xml only contains Irancell-related spam numbers.
# Author: Gholamreza Sabery Tabrizy
# Email: reza_sabery_89@yahoo.com
# Blog: http://www.saberynotes.com
# License: GPL V.2; for more information refer to LICENSE file.
#################################################################################################################################

library(XML)
library(lubridate)
library(sqldf)
library(tm)
library(SnowballC)
library(wordcloud)
library(showtext) # For Fonts

# Adding the font that we use in charts with showtext library
font.add(family = "BYagut", regular = "./fonts/BYAGUT.TTF")

sms_data_file_name <- file.choose()
sms_data_xml <- xmlParse(sms_data_file_name, encoding = "utf-8")
root_node <- xmlRoot(sms_data_xml)
total_sms_count <- xmlSize(root_node)

# Total number of SMS messages in the file
cat("Total number of SMS messages in the file: ",total_sms_count, "\n")

# Extracting SMSes and converting them into a data frame. God bless you XPath!
messages <- xpathSApply(doc = root_node, path = "/smses/sms", fun = xmlAttrs)
messages <- as.data.frame(t(messages), stringsAsFactors = FALSE)

# Converting fields
messages$readable_date <- strptime(x = messages$readable_date, format = "%d %b %Y %H:%M:%S", tz="Asia/Tehran")
messages$readable_date <- as.POSIXct(messages$readable_date)
messages$date <- format(messages$readable_date, format = "%Y-%m-%d")
messages$hour <- format(messages$readable_date, format = "%H")

# Collection of Spam Numbers. Are there more numbers?
spam_numbers <- xmlParse("./spam-numbers.xml", encoding = "utf-8")
spam_numbers <- xpathSApply(doc = xmlRoot(spam_numbers), path = "//number", fun = xmlAttrs)
spam_numbers <- as.data.frame(t(spam_numbers), stringsAsFactors = FALSE)
                      

# Messages from spam numbers
spam_messages <- messages[messages$address %in% spam_numbers$address, ]

cat("Total number of advertisements: ", nrow(spam_messages), "\n")
cat("Percentage of advertisements to total number of messages: ", round((nrow(spam_messages) / total_sms_count) * 100, digits = 2), "%\n")

# Q1. How many days of data do we have?
msg_per_day <- sqldf("select date, count(*) as sms_count from spam_messages group by date")
cat("We have data for", nrow(msg_per_day), "days!\n")

# Q2. How many messages do we get on average from spam-related numbers per day
avg_msg_per_day <- round(mean(msg_per_day$sms_count), digits = 3)
std_msg_per_day <- round(sd(msg_per_day$sms_count), digits = 3)
cat("On average we receive",avg_msg_per_day, "spam messgaes per day with a SD of", std_msg_per_day, "messages\n")


# Q3. What are min, max, etc...
qs <- quantile(msg_per_day$sms_count, probs = c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0))
print(summary(msg_per_day$sms_count))


# Q3. How the chart looks like?
dev.new() # showtext.begin needs this; otherwise it will complain about lack of graphical device!
showtext.begin()
plot(as.Date(msg_per_day$date), msg_per_day$sms_count, type="n",xlab = "", ylab = "", family = "BYagut")
lines(as.Date(msg_per_day$date), msg_per_day$sms_count, type = "l")
title(main = "تعداد پیام های تبلیغاتی ارسال شده", xlab = "ماه", ylab = "تعداد پیام ها", sub = "http://www.saberynotes.com", family = "BYagut")
showtext.end()

# Q4. Which addresses sends the most spam? (Show in a Pareto-chart)
# Notice that we only plot first 20 numbers; you can change this by tweaking this variable.
chart_bound <- c(1:20)
msg_per_number <- sqldf("select address, count(*) as msg_count from spam_messages group by address")
msg_per_number <- msg_per_number[order(msg_per_number$msg_count, decreasing = TRUE), ]
showtext.begin()
bp <- barplot(msg_per_number$msg_count[chart_bound], names.arg = msg_per_number$address[chart_bound], las=2, 
              col = rainbow(20), ylim = c(0, sum(msg_per_number$msg_count)), family="BYagut")
text(bp, y=msg_per_number$msg_count[chart_bound], labels=msg_per_number$msg_count[chart_bound], cex=1, pos=3, srt=90, family="BYagut")
title(main = "تعداد پیام های تبلیغاتی ارسال شده از هر آدرس", xlab = "آدرس", ylab = "تعداد پیام ها", 
      sub = "http://www.saberynotes.com", family = "BYagut")
showtext.end()
# Q5. Which words are most frequentely used in advertisements in general? (we can also create a per number wordcloud)
# Stop words are modified version of words obtained from http://www.ranks.nl/stopwords/persian

create_word_cloud_from_smses <- function(smses, title = "", max_words = 50) {
  persian_stopwords <-read.csv(file = "./persian-stopwords", stringsAsFactors = FALSE, encoding = "utf-8", 
                               sep = ",", header = FALSE)
  # Putting a space instead of : to prevent mixing of words after removing punctuation
  smses <- gsub(":"," ", smses)
  # Putting a space between numbers and words; otherwise sometimes, after removing numbers, symbols for Tooman will mix-up with prev word
  smses <- gsub("(\\d+)", " \\1 ", smses)
  # There are two different codepoints for persian letter /ye/; one is U+064A (0XD98A) and the other is U+06CC (0XDB8C). We should 
  # normalize them. Actually there are more codepoints for this letter but fortunately, in our text we only have these two. ;)
  smses <- gsub("\U064A", "\U06CC", smses)
  # Notice that we can not stem the document in here! R does not provide such a functionality for Persian
  persian_stopwords <- as.character(persian_stopwords)
  adv_corpus <- Corpus(VectorSource(smses))
  adv_corpus <- tm_map(adv_corpus, PlainTextDocument)
  adv_corpus <- tm_map(adv_corpus, removePunctuation, preserve_intra_word_dashes = TRUE)
  adv_corpus <- tm_map(adv_corpus, removeWords, persian_stopwords)
  adv_corpus <- tm_map(adv_corpus, removeNumbers)
  showtext.begin()
  wordcloud(adv_corpus, max.words = max_words, random.order = FALSE, colors = rainbow(50), family="BYagut")  
  title(main = title, sub = "http://www.saberynotes.com", family="BYagut")
  showtext.end()
  #Freq of each individual word
  dtm <- DocumentTermMatrix(adv_corpus)
  dtm <-as.matrix(dtm)
  freq <- colSums(dtm)
  freq <- sort(freq, decreasing = TRUE)
  return(freq)
}

# Creating an overall wordcloud. Using the function we can create individual wordclouds for each number
create_word_cloud_from_smses(spam_messages$body, "ابر کلمات برای تمامی پیام ها")
# Here I also create wordclouds for the highest spam sending numbers
for (i in 1:3) {
  create_word_cloud_from_smses(spam_messages[spam_messages$address == msg_per_number$address[i], ]$body,
                               paste("ابر کلمات برای آدرس: ", msg_per_number$address[i]))  
}

