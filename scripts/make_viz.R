library(tidyverse)
library(tidygeocoder)

df <- read_csv('data/clean/investments_w_company-info.csv')

df |>
  select(transferee_name, page) |>
  mutate(
    company_id = transferee_name %>%
      gsub(',', '', .) %>%
      gsub('\\.', '', .) %>%
      gsub('/', '_', .) %>%
      gsub(' ', '_', .) %>%
      str_to_lower() |>
      str_squish()
  ) |>
  group_by(company_id) |>
  summarize(pages = paste(page, collapse=', ')) |>
  write.csv('data/viz/company_filings.csv', row.names=FALSE)

df <- df |>
  mutate(
    street_address = str_split_i(transferee_address, ',', 1)
  ) |>
  geocode(
    street=street_address,
    country=transferee_country,
    method='osm'
  )
