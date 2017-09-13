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
library(tm)
library(SnowballC)
library(wordcloud)
library(ggplot2)
library(dplyr)

# Including graph-related customizable items
source("graph-titles.R")

create_word_cloud_from_smses <- function(smses, title = "", subtitle="", max_words = 50) {
  # Stop words are modified version of words obtained from http://www.ranks.nl/stopwords/persian
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
  wordcloud(adv_corpus, max.words = max_words, random.order = FALSE, colors = rainbow(50), family="BYagut")  
  title(main = title, sub = subtitle, family="BYagut")
  #Freq of each individual word
  dtm <- DocumentTermMatrix(adv_corpus)
  dtm <-as.matrix(dtm)
  freq <- colSums(dtm)
  freq <- sort(freq, decreasing = TRUE)
  return(freq)
}



sms_data_file_name <- file.choose()
sms_data_xml <- xmlParse(sms_data_file_name, encoding = "utf-8")
root_node <- xmlRoot(sms_data_xml)
total_sms_count <- xmlSize(root_node)

# Total number of SMS messages in the file
cat("Total number of SMS messages in the file: ",total_sms_count, "\n")

# Extracting SMSes and converting them into a data frame. God bless you XPath!
messages <- xpathSApply(doc = root_node, path = "/smses/sms", fun = xmlAttrs) %>% 
  t() %>%
  as.data.frame(stringsAsFactors = FALSE)

messages <- mutate(messages, readable_date=as.POSIXct(readable_date, format = "%d %b %Y %H:%M:%S", tz="Asia/Tehran"),
                   date=format(readable_date, format = "%Y-%m-%d"),
                   hour=format(readable_date, format = "%H"))

# Collection of Spam Numbers. Are there more numbers?
spam_numbers <- xmlParse("./spam-numbers.xml", encoding = "utf-8") %>%
  xmlRoot() %>%
  xpathSApply(path = "//number", fun = xmlAttrs) %>%
  t() %>%
  as.data.frame(stringsAsFactors = FALSE)
                      

# Messages from spam numbers
spam_messages <- messages[messages$address %in% spam_numbers$address, ]

cat("Total number of advertisements: ", nrow(spam_messages), "\n")
cat("Percentage of advertisements to total number of messages: ", round((nrow(spam_messages) / total_sms_count) * 100, digits = 2), "%\n")

# Q1. How many days of data do we have?
msg_per_day <- spam_messages %>%
  count(date) %>%
  rename(sms_count=n)

cat("We have data for", nrow(msg_per_day), "days!\n")

# Q2. How many messages do we get on average from spam-related numbers per day
avg_msg_per_day <- round(mean(msg_per_day$sms_count), digits = 3)
std_msg_per_day <- round(sd(msg_per_day$sms_count), digits = 3)
cat("On average we receive",avg_msg_per_day, "spam messgaes per day with a SD of", std_msg_per_day, "messages\n")


# Q3. What are min, max, etc...
qs <- quantile(msg_per_day$sms_count, probs = c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0))
print(summary(msg_per_day$sms_count))


# Q3. How the chart looks like?
g1_text <- get_graph_text("g1")
y_axis_text <- seq(from = 1, to = max(msg_per_day$sms_count), by = 1)

print(ggplot(data = msg_per_day) + geom_line(mapping = aes(x=as.Date(date), y=sms_count), color="blue") + 
  scale_y_discrete(limits = y_axis_text) +
  labs(title=g1_text["main_title"], x=g1_text["x_label"], y=g1_text["y_label"], caption=g1_text["subtitle"]) + 
  theme(text = element_text(family = "BYagut"),plot.title = element_text(hjust = 0.5), plot.caption  = element_text(hjust = 0.5)))


# Q4. Which addresses sends the most spam? (Show in a Pareto-chart)
# Notice that we only plot first 20 numbers; you can change this by tweaking this variable.
chart_bound <- c(1:20)
g2_text <- get_graph_text("g2")

msg_per_number <- spam_messages %>% 
  count(address) %>% 
  rename(msg_count=n)

print(ggplot(data = msg_per_number[chart_bound,]) + 
  geom_col(mapping = aes(x=reorder(address, -msg_count), y=msg_count), fill = rainbow(20)) +
  labs(title=g2_text["main_title"], x=g2_text["x_label"], y=g2_text["y_label"], caption=g2_text["subtitle"]) + 
  theme(text = element_text(family = "BYagut"), plot.title = element_text(hjust = 0.5), plot.caption  = element_text(hjust = 0.5),
        axis.text.x  = element_text(angle = 90)))


# Q5. Which words are most frequentely used in advertisements in general? (we can also create a per number wordcloud)
# Creating an overall wordcloud. Using the function we can create individual wordclouds for each number
g3_text <- get_graph_text("g3")
create_word_cloud_from_smses(spam_messages$body, title = g3_text["main_title"], subtitle = g3_text["subtitle"])
# Here I also create wordclouds for the highest spam sending numbers
g4_text <- get_graph_text("g4")
for (i in 1:3) {
  create_word_cloud_from_smses(spam_messages[spam_messages$address == msg_per_number$address[i], ]$body,
                               title = paste(g4_text["main_title"], msg_per_number$address[i]), subtitle = g4_text["subtitle"])  
}