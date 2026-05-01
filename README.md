This investigation, published in <i>The Oberlin Review</i>, identifies more than $52 million of Oberlin College's foreign investments in 69 companies around the world. Its publication represents the public’s first access to the details of those investments, which have previously been kept a closely guarded secret of the College’s fund managers.

View the data: [CSV](./data-public/oberlin-college_investments_2021-22.csv) | [Excel](./data-public/oberlin-college_investments_2021-22.xlsx) | [Online](https://public.flourish.studio/visualisation/28414505/)

# Methodology

The <i>Review’s</i> investigation draws on [previously unreported documents](https://github.com/declanrjb/ob-investments/blob/main/docs/irs_filings/990T_2021-22.pdf) uncovered in a publicly available database maintained by the Internal Revenue Service (IRS). The documents, which appear as an appendix to the College’s 2021 990-T nonprofit income tax return, include 154 pages of disclosures filed under Treasury regulation 1.6038B-1(c), which requires businesses to disclose investments in foreign-controlled entities. 

Reporters processed the documents, which are only available as scanned pdfs, using the `pdf2image` and `pytesseract` Python libraries. Each page was first converted to an image, then fed to `pytesseract` optical character recognition (OCR). The resulting text was parsed using regular expressions and manually checked for accuracy. See the [notebook](./notebooks/extract.ipynb).

Reporters reviewed the entire dataset for accuracy. Two parsing errors were found and corrected manually.

Reporters matched company details given in the documents to company websites and mission statements using a combination of Google Search, national business registries, and SEC EDGAR filings. To make a positive match, reporters required two points of identification, typically a company's name and physical address. In 11 cases, reporters were not able to verify a company or fund's real-world profile to this standard of accuracy. Those entities are listed under "[No verifiable details]." 

Reporters categorized the companies into sectors based on their websites and mission statements. The resulting data was cleaned and processed in R and visualized with Flourish. 

Every data analysis finding was independently reproduced by a factchecker who had not seen the original source code. Reporters verified details found in the original documents using [AUM 13F](https://aum13f.com/), [EDGAR](https://www.sec.gov/search-filings), [IAPD](https://adviserinfo.sec.gov/), and lists of shareholders purchased from the [Israeli Business Registry](https://www.gov.il/en/service/company_extract), which are available in [this repository](https://github.com/declanrjb/ob-investments/tree/main/docs/shareholder_docs).

Read the story.