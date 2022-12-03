#!/usr/bin/env Rscript
rm(list = ls())
args = commandArgs(trailingOnly=TRUE)

if (length(args)!=1) {
  stop("usage: Rscript project.R <csv file>", call.=FALSE)
} else if (length(args)==1) {
  stock<- args[1]
}
print(paste0("Current stock: ", stock))

library(dplyr)
library(readr)
library(stringr)
library(zoo)
library(tseries)
print("packages loaded")

filename<- str_split(stock, "_")[[1]][1] # Split file name to just the stock name
print(filename)

assign(filename, read.csv(stock))
print("stock read")

stock_df<- get(filename) %>% select(1:6)
stock_df[c('Date', 'Time')] <- str_split_fixed(stock_df$date, ' ', 2) # Make date and time separate vars
stock_df<- stock_df %>% mutate(Date = as.Date(Date), ) %>% 
  arrange(date) %>% select(-date) %>% group_by(Date) %>% 
  mutate(DayVolume = sum(volume), DayHigh = max(high), DayLow=min(low), DayAvg = mean(close))  # Create Day variables
print("added daily variables")  

# Merge all Day variables
day_open<- stock_df %>% arrange(Date, Time) %>% group_by(Date) %>% filter(row_number() == 1) %>% select(c(open, Date, DayVolume, DayHigh, DayLow, DayAvg)) %>% rename(DayOpen=open)
day_close<- stock_df %>% arrange(Date, Time) %>% group_by(Date) %>% filter(row_number() == n()) %>% select(c(close, Date)) %>% rename(DayClose=close)
day<- merge(day_open, day_close, by="Date") %>% mutate(MA = rollmean(DayClose, k=50, fill=NA, align='right'))
print("merging dayopen dayclose complete")

# Make Counter of >2 days above MA
above<- day %>% filter(DayClose > MA) %>% 
  mutate(BETWEEN=as.numeric(c(diff(lag(Date)),0))) %>%
  group_by(grp=with(rle(BETWEEN), rep(seq_along(lengths), lengths)))%>%
  mutate(counter = seq_along(grp), Counter = case_when(
    as.numeric(counter) > 1 ~ as.numeric(counter) + 1,
    TRUE ~ as.numeric(counter))) %>% 
  select(-c(BETWEEN, counter))
print("counter created")

# Find average and median duration
largest_dur<- above %>% group_by(grp) %>% filter(Counter > 2) %>% summarise(across(everything(), last))
mean_dur<- mean(largest_dur$Counter)
med_dur<- median(largest_dur$Counter)

# ADF test for stationarity - grab p-value [null-hypothesis: non-stationary]
pval<- adf.test(day$DayClose)[4]

stocktable <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(stocktable) = c("Stock", "Mean", "Median", "ADF p-value")
stocktable[nrow(stocktable)+1,] <- c(filename, mean_dur, med_dur, pval)
print("table created")

csv_file<- paste(filename, ".csv", sep="")
write.csv(stocktable, csv_file)
print(paste0("csv file created", csv_file))

# Create .png of time series graph
plot<- ggplot(day,aes(x=day$Date)) +
  geom_line(aes(y=day$DayClose, color="Price")) +
  geom_line(aes(y=day$MA, color = "50 Day MA"))+
  labs(x="Date",y="Values")+
  ggtitle(paste(filename))+
  theme(plot.title = element_text(hjust = 0.5))+
  scale_colour_manual("", breaks = c("Price", "50 Day MA"),values = c("blue", "red"))
  
ggsave(paste0(filename, ".png"), plot)
print("graph saved")

