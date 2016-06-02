# This script analyzes "SMS Backup & Restore" Android app in order to extract Irancell-related text messages
library(XML)
library(lubridate)
library(sqldf)

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

# Collection of Irancell Numbers. Are there more numbers?
irancell_numbers <- xmlParse("./spam-numbers.xml", encoding = "utf-8")
irancell_numbers <- xpathSApply(doc = xmlRoot(irancell_numbers), path = "//number", fun = xmlAttrs)
irancell_numbers <- as.data.frame(t(irancell_numbers), stringsAsFactors = FALSE)
                      

# Messages from Irancell
irancell_messages <- messages[messages$address %in% irancell_numbers$address, ]

cat("Total number of advertisements: ", nrow(irancell_messages), "\n")
cat("Percentage of advertisements to total number of messages: ", round((nrow(irancell_messages) / total_sms_count) * 100, digits = 2), " %\n")

# Q1. How many messages are received per day from Irancell-related phone numbers
msg_per_day <- sqldf("select date, count(*) as sms_count from irancell_messages group by date")


# Q2. How many messages do we get on average from Irancell-related numbers per day
avg_msg_per_day <- round(mean(msg_per_day$sms_count), digits = 3)
std_msg_per_day <- round(sd(msg_per_day$sms_count), digits = 3)
cat("On average we receive",avg_msg_per_day, "spam messgaes per day with a SD of", std_msg_per_day, "messages\n")

# FIXME:: Output to the console
# Q3. What are quntiles?
qs <- quantile(msg_per_day$sms_count, probs = c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0))

# FIXME:: Make the chart pretty...
# Q3. How the chart looks like?
plot(as.Date(msg_per_day$date), msg_per_day$sms_count, type="n")
lines(as.Date(msg_per_day$date), msg_per_day$sms_count, type = "l")

# Q4. Which addresses sends the most spam? (Show in a Pareto-chart)
msg_per_number <- sqldf("select address, count(*) as msg_count from irancell_messages group by address")
msg_per_number <- msg_per_number[order(msg_per_number$msg_count, decreasing = TRUE), ]
bp <- barplot(msg_per_number$msg_count[1:20], names.arg = msg_per_number$address[1:20], las=2, 
              col = rainbow(20), ylim = c(0, sum(msg_per_number$msg_count)))
text(bp, y=msg_per_number$msg_count[1:20], labels=msg_per_number$msg_count[1:20], cex=1, pos=3, srt=90)
title(main = "Number of spam messages sent by each spam number", xlab = "Address", ylab = "# of messages")