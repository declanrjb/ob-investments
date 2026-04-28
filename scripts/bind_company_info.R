df <- read_csv('data/clean/investments_2021_clean.csv')
trades <- read_csv('data/clean/trades_2021_clean.csv')

data(countryRegions)

df <- df |>
  left_join(
    trades |>
      select(transferee_name, amount, date),
    by=c('transferee_name', 'amount')
  )

df$is_direct <- NA
for (i in 1:length(df$transferee_name)) {
  df[i,]$is_direct <- grepl(df[i,]$transferee_name, df[i,]$fund_name) | grepl(df[i,]$fund_name, df[i,]$transferee_name)
}

# make data for sean
df |>
  select(transferee_name, transferee_country, transferee_ein, transferee_address) |>
  unique() |>
  write_sheet('https://docs.google.com/spreadsheets/d/1-FNB0hThjD1Q-31Lq_E6YbZqfkr6-QjQCY6AqGjt_gM/edit?gid=0#gid=0', sheet='companies')

df |>
  select(fund_name, fund_ein) |>
  unique() |>
  write_sheet('https://docs.google.com/spreadsheets/d/1-FNB0hThjD1Q-31Lq_E6YbZqfkr6-QjQCY6AqGjt_gM/edit?gid=0#gid=0', sheet='funds')

# hand check that that's an accurate approach
df |> 
  filter(is_direct) |> 
  select(transferee_name, fund_name)

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