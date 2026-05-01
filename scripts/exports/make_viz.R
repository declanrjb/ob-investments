library(tidyverse)
library(tidygeocoder)
library(googlesheets4)

company_info <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699480597#gid=1699480597', sheet='Companies research')

company_info <- company_info |>
  select(transferee_name, blurb, sector, website, flag, region) |>
  mutate(
    URL = website,
    website = gsub('www.', '', gsub('/', '', gsub('https:', '', website)))
  )

df <- read_csv('data/clean/investments_w_company-info.csv')

# remove the direct investments in funds
df <- df |>
  filter(!is_direct)

# breakout for the filings for doc reference in the github repo
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
    filing_url = paste('https://github.com/declanrjb/ob-investments/blob/main/docs/filings/', company_id, '.pdf', sep='')
  ) |>
  group_by(company_id) |>
  summarize(
    pages = paste(page, collapse=', '),
    transferee_name = first(transferee_name),
    filing_url = first(filing_url)
  ) |>
  write.csv('data/viz/company_filings.csv', row.names=FALSE)

# full table
filing_urls <- read_csv('data/viz/company_filings.csv')

table_df <- df |>
  filter(!is_direct) |>
  left_join(filing_urls) |>
  group_by(transferee_name, transferee_country) |>
  summarize(
    amount = sum(amount),
    date = first(date),
    filing_url = first(filing_url)
  ) |>
  mutate(filing_url = paste('<a href="', filing_url, '">View</a>', sep='')) |>
  left_join(company_info) |>
  select(transferee_name, transferee_country, amount, sector, blurb, URL, date, filing_url) |>
  rename(
    Company = transferee_name,
    Country = transferee_country,
    Investment = amount,
    Description = blurb,
    Sector = sector,
    Date = date,
    `Original Filing` = filing_url
  ) |>
  mutate(
    Company = case_when(
      !is.na(URL) ~ paste('<a href="', URL, '">', Company, '</a>', sep=''),
      is.na(URL) ~ Company
    )
  ) |>
  select(!URL) |>
  arrange(desc(Investment))

write.csv(table_df, 'data/viz/table_full.csv', row.names=FALSE)

# israeli table
table_df |>
  mutate(is_israeli = Country == 'Israel') |>
  arrange(desc(Investment)) |>
  write.csv('data/viz/table_israel.csv', row.names=FALSE)

# stripes sankey
stripes_df <- df |>
  filter(fund_nicename == 'Stripes Offshore')

# 60% of all stripes funds went to Israel
stripes_df |> 
  group_by(transferee_country) |> 
  summarize(
    amount = sum(amount),
    num_comps = length(unique(transferee_name))
  ) |> 
  mutate(percent = amount / sum(amount))

stripes_starter <- stripes_df |>
  group_by(fund_name) |>
  summarize(value = sum(amount)) |>
  mutate(
    source = 'Stripes Offshore',
    step_from = 0,
    step_to = 1,
    fund_name = str_replace_all(fund_name, 'AIV, LP', '')
  ) |>
  rename(
    dest = fund_name
  )

stripes_sankey <- stripes_df |>
  rename(
    source = fund_name,
    dest = transferee_name,
    value = amount
  ) |>
  mutate(
    step_from = 1,
    step_to = 2,
    is_israeli = transferee_country == 'Israel'
  ) |>
  arrange(desc(is_israeli), transferee_country, desc(value))

stripes_sankey$source <- stripes_sankey$source |>
  str_replace('AIV, LP', '') |>
  str_trim()

stripes_sankey$dest <- stripes_sankey$dest |>
  str_replace('Ltd.', '') |>
  str_replace('Inc.', '') |>
  str_replace('GmbH', '') |>
  str_replace(', Ltd', '') |>
  str_trim()

# color palette for this sankey
# Israel: e3b505
# Canada: 91a6ff
# Germany: ff6663
# United Kingdom: 1f487e 


stripes_sankey <- stripes_sankey |>
  select(source, dest, value, step_from, step_to) |>
  rbind(stripes_starter)

write.csv(stripes_sankey, 'data/viz/stripes-sankey.csv', row.names=FALSE)

# perform geocoding for the globe
# df |>
#   select(transferee_name, transferee_country, transferee_address) |>
#   unique() |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# manual address cleanup step

df_geo <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# REMEMBER: drop direct funds from this

# computational geocoding
# df_geo <- df_geo |>
#   geocode(
#     street=street,
#     city=city,
#     country=country,
#     method='osm'
#   )

# df_geo |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='company coords')

df_geo <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=809803929#gid=809803929', sheet='company coords manual check')

geo_auto <- df_geo |>
  filter(!is.na(lat))

geo_auto <- geo_auto |>
  select(transferee_name, lat, long)

geo_manual <- df_geo |>
  filter(manual_address != 'NA')

geo_manual <- geo_manual |>
  select(transferee_name, manual_address) |>
  mutate(
    lat = str_split_i(manual_address, ', ', 1),
    long = str_split_i(manual_address, ', ', 2)
  ) |>
  select(!manual_address)

geo_df <- geo_auto |>
  select(transferee_name, lat, long) |>
  rbind(geo_manual)

geo_df <- df |>
  filter(!is_direct) |>
  group_by(transferee_name) |>
  summarize(
    amount = sum(amount),
    country = first(transferee_country)
  ) |>
  mutate(log_amt = log(amount, base=10)) |>
  left_join(company_info) |>
  left_join(geo_df) |>
  filter(!is.na(lat))

write.csv(geo_df, 'data/viz/globe.csv', row.names=FALSE)

# sector blocks
sector_labels <- df |>
  group_by(sector) |>
  summarize(amount = sum(amount)) |>
  mutate(
    amount_m = round(amount / 1000000, 1),
    sector_nicename = paste(sector, ' ($', amount_m, 'M)', sep='')
  ) |>
  select(sector, sector_nicename)

sector_blocks <- df |>
  filter(!is_direct) |>
  filter(transferee_name != 'Cross Ocean Aviation Fund | (Intl) DAC') |>
  left_join(sector_labels) |>
  group_by(sector_nicename, transferee_name) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info)

write.csv(sector_blocks, 'data/viz/sector_blocks.csv', row.names=FALSE)

# country blocks
region_totals <- df |>
  group_by(region) |>
  summarize(amount = sum(amount)) |>
  mutate(
    round_amt = case_when(
      amount >= 1000000 ~ paste(round(amount / 1000000, 1), 'M', sep=''),
      amount >= 1000 ~ paste(round(amount / 1000, 1), 'K', sep='')
    ),
    region_nicename = paste(region, ' (', round_amt, ')', sep='')
  )

country_blocks <- df |>
  filter(transferee_name != 'Cross Ocean Aviation Fund | (Intl) DAC') |>
  group_by(region, transferee_country, transferee_name) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info) |>
  left_join(
    region_totals |>
      select(region, region_nicename),
    by='region'
  ) |>
  mutate(region = region_nicename) |>
  select(!region_nicename) |>
  arrange(region, transferee_country, desc(amount)) 

write.csv(country_blocks, 'data/viz/country_blocks.csv', row.names=FALSE)
