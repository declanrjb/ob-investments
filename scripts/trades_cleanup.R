library(tidyverse)

df <- read_csv('data/raw/stock-transfers_2021_raw.csv')

colnames(df) <- c('transferee_name', 'date', 'amount', 'related_private_letter')

df <- df |>
  mutate(amount = parse_number(amount))

write.csv(df, 'data/clean/trades_2021_clean.csv', row.names=FALSE)