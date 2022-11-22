library(dplyr)
library(readr)
library(stringr)
library(tidyverse)
library(zoo)
library(tseries)

## Sample process for one specific file ADANIGREEN_minute_data_with_indicators.csv
path<- getwd()
myFiles <- list.files(path=path, pattern="*.csv",)
filename<- str_split(myFiles[1], "_")[[1]][1] # Split file name to just the stock name
assign(filename, read.csv(myFiles[1]))
ADANIGREEN<- ADANIGREEN %>% select(1:6)
ADANIGREEN[c('Date', 'Time')] <- str_split_fixed(ADANIGREEN$date, ' ', 2) # Make date and time separate vars
ADANIGREEN<- ADANIGREEN %>% mutate(Date = as.Date(Date), ) %>% 
  arrange(date) %>% select(-date) %>% group_by(Date) %>% 
  mutate(DayVolume = sum(volume), DayHigh = max(high), DayLow=min(low), DayAvg = mean(close))  # Create Day variables
  
# Merge all Day variables
day_open<- ADANIGREEN %>% arrange(Date, Time) %>% group_by(Date) %>% filter(row_number() == 1) %>% select(c(open, Date, DayVolume, DayHigh, DayLow, DayAvg)) %>% rename(DayOpen=open)
day_close<- ADANIGREEN %>% arrange(Date, Time) %>% group_by(Date) %>% filter(row_number() == n()) %>% select(c(close, Date)) %>% rename(DayClose=close)
day<- merge(day_open, day_close, by="Date") %>% mutate(MA = rollmean(DayClose, k=50, fill=NA, align='right'))
  
# Make Counter of >2 days above MA
above<- day %>% filter(DayClose > MA) %>% 
  mutate(BETWEEN=as.numeric(c(diff(lag(Date)),0))) %>%
  group_by(grp=with(rle(BETWEEN), rep(seq_along(lengths), lengths)))%>%
  mutate(counter = seq_along(grp), Counter = case_when(
    as.numeric(counter) > 1 ~ as.numeric(counter) + 1,
    TRUE ~ as.numeric(counter))) %>% 
  select(-c(BETWEEN, counter))

# Find average and median duration
largest_dur<- above %>% group_by(grp) %>% filter(Counter > 2) %>% summarise(across(everything(), last))
mean(largest_dur$Counter)
median(largest_dur$Counter)

# Time series plot with red MA line
plot(day$Date,day$DayClose, type = "l",
     xlab = "Year", ylab = "Values", col="blue")
lines(day$Date,day$MA,type = "l",col="red")
legend("topleft", c("Price", "50 Day MA"),lty = 1, col = c("blue", "red"))

# ADF test for stationarity - grab p-value [null-hypothesis: non-stationary]
adf.test(day$DayClose)[4]