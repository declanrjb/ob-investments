Investigation identifying $52 million of Oberlin College's foreign investments.

View the data: [CSV](./data-public/oberlin-college_investments_2021-22.csv) | [Excel](./data-public/oberlin-college_investments_2021-22.xlsx) | [Online](https://public.flourish.studio/visualisation/28414505/)

# Methodology

The Review’s investigation draws on previously unreported documents uncovered in a publicly available database maintained by the Internal Revenue Service (IRS). The documents, which appear as an appendix to the College’s 2021 990-T nonprofit income tax return, include 154 pages of disclosures filed under Treasury regulations 1.351-3(a) and 1.6038B-1(c), which require nonprofits to disclose investments in foreign-controlled entities. 

Reporters processed the documents, which are only available as scanned pdfs, using the `pdf2image` and `pytesseract` Python libraries. Each page was first converted to an image, then fed to `pytesseract` optical character recognition (OCR). The resulting text was parsed using regular expressions and manually checked for accuracy. See the [notebook](./notebooks/extract.ipynb).

Reporters reviewed the entire dataset for accuracy. Two errors were found, both confusions of the character "1" with the character "l." Both were corrected manually.

Reporters matched company details given in the documents to company websites and mission statements using a combination of Google Search, national business registries, and SEC EDGAR filings. To make a positive match, reporters required two points of identification, typically a company's name and physical address. In 11 cases, reporters were not able to verify a company or fund's real-world profile to this standard of accuracy. Those entities are listed under "[No verifiable details]." 

Reporters categorized the companies into sectors based on their websites and mission statements. The resulting data was cleaned and processed in R, and visualized using Flourish.

Read the story.