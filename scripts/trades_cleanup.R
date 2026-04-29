library(tidyverse)

df <- read_csv('data/raw/stock-transfers_2021_raw.csv')

colnames(df) <- c('transferee_name', 'date', 'amount', 'related_private_letter', 'page')

df <- df |>
  mutate(amount = parse_number(amount))

df$transferee_name <- df$transferee_name %>%
  gsub('Plotlogic Pty Ltd', 'Plotlogic Pty, Ltd', .)

write.csv(df, 'data/clean/trades_2021_clean.csv', row.names=FALSE)