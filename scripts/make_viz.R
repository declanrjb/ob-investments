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
      str_squish(),
    filing_url = paste('https://github.com/declanrjb/ob-investments/blob/main/docs-public/filings/', company_id, '.pdf', sep='')
  ) |>
  group_by(company_id) |>
  summarize(
    pages = paste(page, collapse=', '),
    transferee_name = first(transferee_name),
    filing_url = first(filing_url)
  ) |>
  write.csv('data/viz/company_filings.csv', row.names=FALSE)

# df |>
#   select(transferee_name, transferee_country, transferee_address) |>
#   unique() |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# manual address cleanup step

df_geo <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# computational geocoding
df_geo <- df_geo |>
  geocode(
    street=street,
    city=city,
    country=country,
    method='osm'
  )

df_geo |>
  write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='company coords')

df <- df |>
  mutate(
    street_address = str_split_i(transferee_address, ',', 1)
  ) |>
  geocode(
    street=street_address,
    country=transferee_country,
    method='osm'
  )
