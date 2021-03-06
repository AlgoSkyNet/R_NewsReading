## =============================================================================
##
## Code to esplore the idea of correlate sentiment pattern to asset price change
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## Use on your own risk: experimentation only!!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
##
## Part 1 - Collect Sentiment Data for a Topic
##
# register for developer account via https://apps.twitter.com
# obtain keys by creating an App in from https://developer.twitter.com/en/apps
# encrypt your keys using script 'encrypt_api_key.R'

## define path of the repository
path_repository <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_NewsReading/TWITTER_FINSEN"

# or use repository path if just using sample data
#path_repository <- "TWITTER_FINSEN"

library(twitteR)
library(tidyverse)
source(file.path(path_repository, "Functions/decrypt_mykeys.R"))
source(file.path(path_repository, "Functions/establish_twitter_connection.R"))
source(file.path(path_repository, "Functions/get_twitter_sentiment.R"))
library(syuzhet)
library(lubridate)
library(scales)
library(reshape2)

# establish twitter connection: function will insure the connection
establish_twitter_connection(path_encrypted_keys = file.path(path_repository, "Keys"),
                             path_private_key = file.path("C:/Users/fxtrams/.ssh", "id_api"))


## =================================================================

# Get sentiment summary of the topic
topic_sentiment <- get_twitter_sentiment(search_term = "#tesla",
                                         n_tweets = 3000,
                                         output_df = T)

# calculate vector of latest scores
latest_scores <- colSums(topic_sentiment)

# convert to dataframe
topic_scores <- latest_scores %>% as.list() %>% as.data.frame() %>% 
  # collect the date
  mutate(DateTime = Sys.time() %>% as.character())

## write file to the log object
# create directory for Logs
if(!dir.exists(file.path(path_repository, "Logs"))){
    dir.create(file.path(path_repository, "Logs"))
  }

# append new record to the data base
if(!file.exists(file.path(path_repository, "Logs/Sent.rds"))){
  write_rds(topic_scores, file.path(path_repository, "Logs/Sent.rds"))
} else {
  read_rds(file.path(path_repository, "Logs/Sent.rds")) %>% 
    bind_rows(topic_scores) %>% 
    write_rds(file.path(path_repository, "Logs/Sent.rds"))
}

## ==================================================================
## Join asset price data to the topic

# read the file
sentiment_logs <- read_rds(file.path(path_repository, "Logs/Sent.rds"))

## Price data of the asset
path_price <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/AI_CP60-333.csv"
topic_price <- read_csv(path_price,col_names = F)
# convert to time format 
topic_price$X1 <- ymd_hms(topic_price$X1)
# same for sentiment data
sentiment_logs$DateTime <- ymd_hms(sentiment_logs$DateTime)

# round the hours in sentiment data to match hourly values
s_round <- sentiment_logs %>% 
  mutate(DateTimeR = round_date(sentiment_logs$DateTime, unit = "30 minutes")) #%>% 
  # if needed add 1 hour to the column DateTimeR
  # mutate(DateTimePlus1h = DateTimeR + 3600) 
  
# joined data: sentiment values with price values. NB: time is 'aligned' by Broker Server Time!
sent_price_joined <- s_round %>% inner_join(topic_price, by = c("DateTimeR" = "X1"))

## ====================================================================
# write obtained dataset to the Logs folder
write_rds(sent_price_joined, file.path(path_repository, "Logs/Sent_price.rds"))

# Shift data -> train regression model -> etc see script sent_learn_ai_R.R

# Data for prediction
topic_scores_last <- latest_scores %>% as.list() %>% as.data.frame()

# Write data for prediction to the file
write_rds(topic_scores_last, file.path(path_repository, "Logs/topic_scores_last.rds"))
