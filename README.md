Investigation identifying $52 million of Oberlin College's foreign investments.

View the data: [CSV](./data-public/oberlin-college_investments_2021-22.csv) | [Excel](./data-public/oberlin-college_investments_2021-22.xlsx) | [Online](https://public.flourish.studio/visualisation/28414505/)

# Methodology

The Review’s investigation draws on previously unreported documents uncovered in a publicly available database maintained by the Internal Revenue Service (IRS). The documents, which appear as an appendix to the College’s 2021 990-T nonprofit income tax return, include 154 pages of disclosures filed under Treasury regulations 1.351-3(a) and 1.6038B-1(c), which require nonprofits to disclose investments in foreign-controlled entities. 

Reporters processed the documents, which are only available as scanned pdfs, using the `pdf2image` and `pytesseract` Python libraries. Each page was first converted to an image, then fed to `pytesseract` optical character recognition (OCR). The resulting text was parsed using regular expressions and manually checked for accuracy. See the [notebook](./notebooks/extract.ipynb)

The resulting data was cleaned and processed in R, and visualized using Flourish.