library(tidyverse)
library(openxlsx)

df <- read_csv('data/clean/investments_w_company-info.csv')

public_df <- df

public_df <- public_df |>
  select(
    transferee_name, 
    amount,
    sector,
    transferee_country, 
    region,
    transferee_address, 
    website, 
    transferee_ein,  
    blurb,
    fund_name,
    fund_ein,
    date
  ) |>
  rename(
    Company_Name = transferee_name,
    Country = transferee_country,
    Region = region,
    Amount_Dollars = amount,
    Sector = sector,
    Description = blurb,
    Company_Address = transferee_address,
    Company_Website = website,
    Company_EIN = transferee_ein,
    Fund_Name = fund_name,
    Fund_EIN = fund_ein,
    Date = date
  )

write.csv(public_df, 'data-public/oberlin-college_investments_2021-22.csv')
write.xlsx(public_df, 'data-public/oberlin-college_investments_2021-22.xlsx')