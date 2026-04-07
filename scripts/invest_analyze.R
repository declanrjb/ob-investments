library(tidyverse)
library(googlesheets4)

df <- read_csv('data/clean/investments_2021_clean.csv')

df$is_direct <- NA
for (i in 1:length(df$transferee_name)) {
  df[i,]$is_direct <- grepl(df[i,]$transferee_name, df[i,]$fund_name) | grepl(df[i,]$fund_name, df[i,]$transferee_name)
}

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


company_info <- read_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?gid=1699480597#gid=1699480597', sheet='Companies research')

company_info <- company_info |>
  select(transferee_name, blurb, sector, website, flag) |>
  mutate(
    URL = website,
    website = gsub('www.', '', gsub('/', '', gsub('https:', '', website)))
  )

df <- df |>
  left_join(company_info)

# check top funds now that we've cleaned up their names
# soleus handles almost 30% of traffic
df |>
  group_by(fund_nicename) |>
  summarize(amount = sum(amount)) |>
  arrange(desc(amount)) |>
  mutate(percent = amount / sum(amount))

# more than 36 million in the caymans
# israel #7 at 1.2 mil
df |> 
  group_by(transferee_country) |> 
  summarize(amount = sum(amount)) |> 
  arrange(desc(amount)) |>
  mutate(percent = amount / sum(amount))

# 36 different funds, some managing many companies
df |> 
  count(fund_name) |> 
  arrange(desc(n))

# funds by country
df |> 
  group_by(fund_name, transferee_country) |> 
  summarize(amount = sum(amount)) |> 
  arrange(desc(amount))

# all israeli investments run through one fund manager, stripes offshore
df |> 
  group_by(fund_nicename, transferee_country) |> 
  summarize(amount = sum(amount)) |>
  arrange(desc(amount)) |>
  filter(transferee_country == 'Israel')

# analysis of sectors
# software and tech leads by a large margin: more than 20% of all investments
sectors_df <- df |> 
  filter(!is_direct) |> 
  group_by(sector) |> 
  summarize(
    amount = sum(amount),
    num_comps = length(unique(transferee_name))
  ) |> 
  arrange(desc(amount)) |>
  mutate(percent_value = amount / sum(amount))

# visualize sectors
sectors_df |>
  filter(sector != 'NA') |>
  write.csv('data/viz/sectors_bar.csv', row.names=FALSE)

# visualization

# make sankey
viz_df <- df |>
  filter(!is_direct)

# visualize sectors as blocks
# exclude the ones for which we don't have sectors

sector_labels <- viz_df |>
  group_by(sector) |>
  summarize(amount = sum(amount)) |>
  mutate(
    amount_m = round(amount / 1000000, 1),
    sector_nicename = paste(sector, ' ($', amount_m, 'M)', sep='')
  ) |>
  select(sector, sector_nicename)

sector_blocks <- viz_df |>
  filter(sector != 'NA') |>
  left_join(sector_labels) |>
  group_by(sector_nicename, transferee_name) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info)

write.csv(sector_blocks, 'data/viz/sector_blocks.csv', row.names=FALSE)

# restrict viz to those 10

oberlin_to_funds <- viz_df |>
  group_by(fund_name) |>
  summarize(value = sum(amount)) |>
  arrange(desc(value)) |>
  head(10) |>
  mutate(source = 'Oberlin College') |>
  rename(dest = fund_name) |>
  select(source, dest, value) |>
  mutate(
    step_from = 0,
    step_to = 1
  )

# the top ten funds make up 86% of total spend
oberlin_to_funds |> arrange(desc(value)) |> head(10) |> pull(value) |> sum()
oberlin_to_funds |> arrange(desc(value)) |> pull(value) |> sum()


funds_to_companies <- viz_df |>
  arrange(transferee_name) |>
  select(fund_name, transferee_name, amount) |>
  filter(fund_name %in% oberlin_to_funds$dest) |>
  rename(
    source = fund_name,
    dest = transferee_name,
    value = amount
  ) |>
  mutate(
    step_from = 1,
    step_to = 2
  )

sankey_df <- rbind(oberlin_to_funds, funds_to_companies)
write.csv(sankey_df, 'data/viz/fund_sankey.csv', row.names=FALSE)

# identify top countries
top_countries <- viz_df |>
  group_by(transferee_country) |>
  summarize(amount = sum(amount)) |>
  arrange(desc(amount)) |>
  head(5)

funds_to_countries <- viz_df |>
  select(fund_nicename, transferee_country, amount) |>
  filter(transferee_country %in% top_countries$transferee_country) |>
  group_by(fund_nicename, transferee_country) |>
  summarize(amount = sum(amount)) |>
  rename(
    source = fund_nicename,
    dest = transferee_country,
    value = amount
  ) |>
  mutate(
    step_from = 0,
    step_to = 1
  ) |>
  arrange(desc(value))

# country_sankey <- rbind(oberlin_to_funds, funds_to_countries)
write.csv(funds_to_countries, 'data/viz/country-sankey.csv', row.names=FALSE)

# make it a blocks chart instead
block_df <- viz_df |>
  group_by(fund_name, transferee_name) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info)

write.csv(block_df, 'data/viz/fund_blocks.csv', row.names=FALSE)

country_blocks <- viz_df |>
  group_by(transferee_country, transferee_name) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info)

write.csv(country_blocks, 'data/viz/country_blocks.csv', row.names=FALSE)

# ok, that's some viz done, let's do the hands on research
df |>
  group_by(transferee_name) |>
  summarize(
    amount = sum(amount, na.rm=TRUE),
    pages = paste(page, collapse=', '),
    transferee_country = paste(unique(transferee_country), collapse=', '),
    transferee_ein = paste(unique(transferee_ein), collapse=', '),
    transferee_address = paste(unique(transferee_address), collapse=', ')
  ) |>
  arrange(transferee_country, transferee_name) |>
  write_sheet('https://docs.google.com/spreadsheets/d/1JB1tH2xEKbiLALWdEs7gDrBk3-ix9kdvroRfhOnic4s/edit?usp=sharing', sheet='end_companies')

# make a searchable table
table_df <- viz_df |>
  filter(!is_direct) |>
  group_by(transferee_name, transferee_country) |>
  summarize(amount = sum(amount)) |>
  left_join(company_info) |>
  select(transferee_name, transferee_country, amount, blurb, URL) |>
  rename(
    Company = transferee_name,
    Country = transferee_country,
    Investment = amount,
    Description = blurb
  ) |>
  mutate(
    Company = paste('<a href="', URL, '">', Company, '</a>', sep='')
  ) |>
  select(!URL) |>
  arrange(desc(Investment))

write.csv(table_df, 'data/viz/table_full.csv', row.names=FALSE)