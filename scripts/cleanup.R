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

# cleanup investments
investments <- read_csv("data/investments_2021_raw.csv")

# change amounts to numeric
investments <- investments |> 
  mutate(amount = parse_number(amount))

# extract transferee info
transferee_info <- 
  investments$transferee |> 
  lapply(parse_transferee) %>% 
  do.call(rbind, .)



# cleanup stock
stock <- read_csv("data/stock-transfers_2021_raw.csv" )