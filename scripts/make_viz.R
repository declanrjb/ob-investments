library(tidyverse)
library(tidygeocoder)

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
    filing_url = paste('https://github.com/declanrjb/ob-investments/blob/main/docs-public/filings/', company_id, '.pdf', sep='')
  ) |>
  group_by(company_id) |>
  summarize(
    pages = paste(page, collapse=', '),
    transferee_name = first(transferee_name),
    filing_url = first(filing_url)
  ) |>
  write.csv('data/viz/company_filings.csv', row.names=FALSE)

# perform geocoding for the globe
# df |>
#   select(transferee_name, transferee_country, transferee_address) |>
#   unique() |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# manual address cleanup step

df_geo <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=19455493#gid=19455493', sheet='Company geoid')

# REMEMBER: drop direct funds from this

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

# make the all company sankey
fund_has_branches <- df |>
  group_by(fund_nicename) |>
  summarize(branches = length(unique(fund_name))) |>
  mutate(
    has_branches = branches > 1
  ) |>
  select(fund_nicename, has_branches)

sankey_df <- df |>
  filter(!is_direct) |>
  select(fund_nicename, fund_name, transferee_name, transferee_country, amount) |>
  left_join(fund_has_branches)

funds_to_comps <- sankey_df |>
  filter(!has_branches) |>
  group_by(fund_nicename, transferee_name) |>
  summarize(
    amount = sum(amount),
    transferee_country = first(transferee_country),
    overseeing_fund = first(fund_nicename)
  ) |>
  mutate(
    step_from=1,
    step_to=3
  ) |>
  rename(
    src = fund_nicename,
    dest = transferee_name
  )

funds_to_branches <- sankey_df |>
  filter(has_branches) |>
  group_by(fund_nicename, fund_name) |>
  summarize(
    amount = sum(amount),
    overseeing_fund = first(fund_nicename)
  ) |>
  mutate(
    step_from=1,
    step_to=2,
    transferee_country = 'Not Applicable'
  ) |>
  rename(
    src = fund_nicename,
    dest = fund_name
  )

branches_to_comps <- sankey_df |>
  filter(has_branches) |>
  group_by(fund_name, transferee_name) |>
  summarize(
    amount = sum(amount),
    transferee_country = first(transferee_country),
    overseeing_fund = first(fund_nicename)
  ) |>
  mutate(
    step_from=2,
    step_to=3
  ) |>
  rename(
    src = fund_name,
    dest = transferee_name
  )

sankey_output <- rbind(
  funds_to_comps,
  funds_to_branches,
  branches_to_comps
) |>
  arrange(src, dest, desc(amount))

write.csv(sankey_output, 'data/viz/sankey_all.csv', row.names=FALSE)
