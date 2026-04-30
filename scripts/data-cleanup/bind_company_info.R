df <- read_csv('data/clean/investments_2021_clean.csv')
trades <- read_csv('data/clean/trades_2021_clean.csv')

# trades |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1903505919#gid=1903505919', sheet='fact check - trades')

# df |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1903505919#gid=1903505919', sheet='fact check - investments')

trades <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1903505919#gid=1903505919', sheet='fact check - trades')
df <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1903505919#gid=1903505919', sheet='fact check - investments')

df <- df |>
  select(!hand_check) |>
  mutate(is_direct = !is.na(is_direct))

data(countryRegions)

df <- df |>
  left_join(
    trades |>
      select(transferee_name, amount, date),
    by=c('transferee_name', 'amount')
  )

# trim all that legal junk off the fund names
# check this with the accountant
funds_legal <- df |>
  group_by(fund_name) |>
  summarize(amount = sum(amount)) |>
  arrange(desc(amount)) |>
  unique()

# funds_legal |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699394519#gid=1699394519', sheet='fund name cleanup')

funds_nice <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699394519#gid=1699394519', sheet='fund name cleanup') |>
  select(!amount)

df <- df |>
  left_join(funds_nice)

# add regions to research sheet
# read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699480597#gid=1699480597', sheet='Companies research') |>
#   left_join(countries_by_region, by=c('transferee_country' = 'COUNTRY')) |>
#   rename(region = REGION) |>
#   write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699480597#gid=1699480597', sheet='Companies research')

company_info <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699480597#gid=1699480597', sheet='Companies research')

company_info <- company_info |>
  select(transferee_name, blurb, sector, website, flag, region) |>
  mutate(
    URL = website,
    website = gsub('www.', '', gsub('/', '', gsub('https:', '', website)))
  )

df <- df |>
  left_join(company_info)

write.csv(df, 'data/clean/investments_w_company-info.csv', row.names=FALSE)