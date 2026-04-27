library(tidyverse)

df <- read_csv('data/clean/investments_w_company-info.csv')

df |>
  select(transferee_name, fund_name, transferee_country, date) |>
  rename(
    `Company Name` = transferee_name,
    `Company Country` = transferee_country,
    `Fund Name` = fund_name,
    Date = date
  ) |>
  unique() |>
  write_sheet('https://docs.google.com/spreadsheets/d/1fgfqctCFASQozVKZqu9OZ3rzJbRChPwbYn3mjQPhkEg/edit?gid=210907688#gid=210907688', sheet='Companies by Fund')

df |>
  select(transferee_name, transferee_country) |>
  unique() |>
  rename(
    `Company Name` = transferee_name,
    `Company Country` = transferee_country
  ) |>
  write_sheet('https://docs.google.com/spreadsheets/d/1fgfqctCFASQozVKZqu9OZ3rzJbRChPwbYn3mjQPhkEg/edit?gid=1122495939#gid=1122495939', sheet='Unique Companies')

df |>
  select(fund_name) |>
  unique() |>
  rename(
    `Fund Name` = fund_name
  ) |>
  write_sheet('https://docs.google.com/spreadsheets/d/1fgfqctCFASQozVKZqu9OZ3rzJbRChPwbYn3mjQPhkEg/edit?gid=1122495939#gid=1122495939', sheet='Unique Funds')