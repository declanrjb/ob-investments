library(tidyverse)

parse_transferee <- function(transferee_text) {
  splits <- transferee_text |> 
    str_split('\n') |>
    unlist()

  non_empty_indices <- splits |>
    lapply(function(str) {str_length(str) > 0}) |> 
    unlist() |> 
    which()

  splits <- splits[non_empty_indices]

  temp <- as.data.frame(matrix(ncol=5, nrow=1))
  colnames(temp) <- c('transferee', 'transferee_name', 'transferee_ein', 'transferee_address', 'transferee_country')

  if (length(splits) == 4) {
    splits <- c(transferee_text, splits)
  } else {
    splits <- c(transferee_text, splits[1], splits[2], paste(splits[3], splits[4]), splits[5])
  }

  temp[1,] <- splits

  return(temp)
}

parse_fund <- function(description) {

  manager_text <- description |> 
      str_extract('owns an interest in((.|\n)*)\\.', group=1) |>
      str_trim()

  fund_name <- manager_text |>
    str_split_i('\n', 1)

  fund_ein <- manager_text |>
    str_extract('EIN:(.*)\\)', group=1) |>
    str_trim()

  return(data.frame(description, fund_name, fund_ein))
}

# cleanup investments
investments <- read_csv("data/raw/investments_2021_raw.csv")

# change amounts to numeric
investments <- investments |> 
  mutate(amount = parse_number(amount))

# extract transferee info
transferee_info <- investments$transferee |> 
  lapply(parse_transferee) %>% 
  do.call(rbind, .) |>
  unique()

transferee_info <- transferee_info |>
  mutate(
    transferee_name = transferee_name |> str_split_i(':', -1) |> str_trim(),
    transferee_ein = transferee_ein |> str_split_i(':', -1) |> str_trim(),
    transferee_address = transferee_address |> str_split_i(':', -1) |> str_trim(),
    transferee_country = transferee_country |> str_split_i('Country of Incorporation', -1) |> str_trim()
  )

fund_info <- investments$description |>
  lapply(parse_fund) %>%
  do.call(rbind, .) |>
  unique()

investments <- investments |> 
  left_join(transferee_info) |> 
  left_join(fund_info)

investments <- investments |>
  select(transferee_name, transferee_country, fund_name, amount, page, transferee_ein, fund_ein, transferee_address)

# clean up the OCR misread of stripes
investments$fund_name <- investments$fund_name |>
  str_replace('Stripes IV Offshore AIlV, LP', 'Stripes IV Offshore AIV, LP')

investments$transferee_country <- investments$transferee_country |>
  str_replace('lreland', 'Ireland')

investments$transferee_name <- investments$transferee_name %>%
  gsub('Webull Corporatoin', 'Webull Corporation', .)

write.csv(investments, 'data/clean/investments_2021_clean.csv', row.names=FALSE)

