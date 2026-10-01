This [investigation](https://github.com/declanrjb/ob-investments), published in <i>The Oberlin Review</i>, identifies more than $52 million of Oberlin College's foreign investments in 69 companies around the world. Its publication represents the public’s first access to the details of those investments, which have previously been kept a closely guarded secret of the College’s fund managers.

View the data: [CSV](./data/public/oberlin-college_investments_2021-22.csv) | [Excel](./data/public/oberlin-college_investments_2021-22.xlsx) | [Online](https://public.flourish.studio/visualisation/28414505/)

# Methodology

The <i>Review’s</i> investigation draws on [previously unreported documents](https://github.com/declanrjb/ob-investments/blob/main/docs/990T_2021-22.pdf) uncovered in a publicly available database maintained by the Internal Revenue Service (IRS). The documents, which appear as an appendix to the College’s 2021 990-T nonprofit income tax return, include 154 pages of disclosures filed under Treasury regulation 1.6038B-1(c), which requires businesses to disclose investments in foreign-controlled entities. 

Reporters processed the documents, which are only available as scanned pdfs, using the `pdf2image` and `pytesseract` Python libraries. Each page was first converted to an image, then fed to `pytesseract` optical character recognition (OCR). The resulting text was parsed using regular expressions and manually checked for accuracy. See the [notebook](./notebooks/extract.ipynb).

Reporters reviewed the entire dataset for accuracy. Two parsing errors were found and corrected manually.

Reporters matched company details given in the documents to company websites and mission statements using a combination of Google Search, national business registries, and SEC EDGAR filings. To make a positive match, reporters required two points of identification, typically a company's name and physical address. In 11 cases, reporters were not able to verify a company or fund's real-world profile to this standard of accuracy. Those entities are listed under "[No verifiable details]." 

Reporters categorized the companies into sectors based on their websites and mission statements. The resulting data was cleaned and processed in R and visualized with Flourish. 

Every data analysis finding was independently reproduced by a factchecker who had not seen the original source code. Reporters verified details found in the original documents using [AUM 13F](https://aum13f.com/), [EDGAR](https://www.sec.gov/search-filings), [IAPD](https://adviserinfo.sec.gov/), and lists of shareholders purchased from the [Israeli Business Registry](https://www.gov.il/en/service/company_extract), which are available in [this directory](https://github.com/declanrjb/ob-investments/tree/main/docs/shareholder_docs).

Read [the story](https://oberlinreview.org/37874/news/oberlin-college-invested-1-2-million-in-israeli-companies-in-2021-investigation-finds/).

# Worked Code

Below you can find the Python code used to extract the relevant financial records for this investigation.

This story began with the watershed discovery of 171 pages of [investment disclosures](https://projects.propublica.org/nonprofits/display_990/340714363/download990pdf_06_2023_prefixes_31-36%2F340714363_202206_990T_2023060821403663) sitting unnoticed in ProPublica's nonprofit explorer database. In order to analyze that data, I first had to extract it from the original pdf.

## Parsing the data

Extracting the relevant information from the documents posed a challenge, since the appendices containing the most revelatory information appeared to have been scanned and didn't respond to traditional text extraction. Instead, I used pdf2image to first convert each page to an image, then pytesseract OCR to extract the text.

```python
import pytesseract as pt
from pdf2image import convert_from_path
from autocorrect import Speller
import re
import pandas as pd
from datetime import datetime as dt
```

```python
file = '../docs/irs_filings/990T_2021-22.pdf'
```

```python
# use regex to extract the investments from raw text
def process_investments(page_img, page_num):
    text = pt.image_to_string(page_img)
    details = pd.Series([item for item in text.split('\n') if re.search(r'^\([0-9]{1}\)', item)])
    return {k:v for k, v in zip(details.apply(lambda x: re.sub(r'^\([0-9]{1}\)', '', x.split(':')[0]).strip()), details.apply(lambda x: x.split(':', 1)[1].strip()))} | {'page': page_num}

# retrieve all investments from a single page
def get_investments_singular(file, page_num):
    page = convert_from_path(file, 600, first_page=page_num, last_page=page_num)[0]
    return pd.DataFrame(process_investments(page), index=[0])

# retrieve all investments from a range of pages
def get_investments_multiple(file, first, last):
    pages = convert_from_path(file, 600, first_page=first, last_page=last)
    return pd.concat([pd.DataFrame(process_investments(pages[i], first+i), index=[0]) for i in range(0, len(pages))])

# extract the raw text from a single pdf page
def get_page_text(file, page_num):
    page = convert_from_path(file, 600, first_page=page_num, last_page=page_num)[0]
    return pt.image_to_string(page)
```

```python
# attempt to format a date string in standard unambigous format, otherwise soft parse it to None
def format_date(x):
    try:
        date = dt.strptime(x, '%m/%d/%Y')
    except:
        date = None
    return date
```

```python
# use regex to extract the second form of investment disclosures, which are listed as stock trades in the latter half of the document
def regex_extract_stocks(file, page_num):
    text = get_page_text(file, page_num)
    return pd.DataFrame({
        'transferee': text[re.search(r'44074', text).end(0):re.search(r'Oberlin College \(EIN', text).start(0)],
        'description': re.search(r'(Oberlin College \(EIN.*)Ownership', text, re.DOTALL).group(1),
        'consideration_received': re.search(r'Ownership.*corporation', text, re.DOTALL).group(0),
        'amount':re.search(r'\$[0-9,]+', text).group(0),
        'page': page_num
    }, index=[page_num])
```

```python
# define known row delimiters on the page, used to iteratively crop the page into strips to extract values
# this is used to evade all the problems that come with line terminators when values overflow onto multiple lines (which they do sometimes, but not consistently or predictably)
splits = [
    '\(1\) Name of Transferor\:',
    'EIN\:',
    'Address\:',
    '\(2\) Name of Transferee\:',
    'EIN:',
    'Address:',
    'Country of Incorporation',
    '\(3\) Consideration received:',
    '\(4\) Cash'
]
```

```python
# perform data cleaning checks on the extracted stocks
def clean_stock_frame(df):
    df.columns = [
        'Transferor',
        'Transferor_EIN',
        'Transferor_Address',
        'Transferee',
        'Transferee_EIN',
        'Transferee_Address',
        'Transferee_Country_Incorporation',
        'Consideration_Received',
        'Cash'
    ]

    df['Description'] = df['Transferee_Country_Incorporation'].apply(lambda x: x.split('\n\n')[1] if len(x.split('\n\n')) > 1 else None)
    df['Transferee_Country_Incorporation'] = df['Transferee_Country_Incorporation'].apply(lambda x: x.split('\n\n')[0])

    df['Footer'] = df['Cash'].apply(lambda x: x.split('\n\n')[1] if len(x.split('\n\n')) > 1 else None)
    df['Cash'] = df['Cash'].apply(lambda x: x.split('\n\n')[0])

    return df
```

```python
# extract stock dataframes that appear in the latter half of the document
def extract_stocks(file, page_num):
    text = get_page_text(file, page_num)
    
    curr_term = 0
    result = {}

    # split the page into strips based on the delimiters above, and extract values from each strip
    while len(text) > 0 and curr_term < len(splits):
        start = re.search(splits[curr_term], text).start(0)
        text = text[start:]
        out_key = splits[curr_term]
        curr_term += 1
        if curr_term < len(splits):
            end = re.search(splits[curr_term], text).start(0)
            result[f'{curr_term}_{out_key}'] = text[len(out_key.replace("\\",'')):end].strip()
            text = text[end:]
        else:
            result[f'{curr_term}_{out_key}'] = text[len(out_key.replace("\\",'')):].strip()

    df = pd.DataFrame(result, index=[0])
    df = clean_stock_frame(df)
    df['Page'] = page_num

    return df
```

After extracting all of the data, I exported it to a clean CSV file for analysis in R and visualization in Flourish.

```python
# investments of disclosure type A appear between pages 17 and 93, manually identified
df = get_investments_multiple(file, 17, 93)
df.to_csv('../data/raw/stock-transfers_2021_raw.csv', index=False)
```

```python
# investments of disclosure type B appear between pages 94 and the end, manually identified
df = pd.concat([regex_extract_stocks(file, page) for page in range(94, 171)])
df.to_csv('../data/raw/investments_2021_raw.csv', index=False)
```

## Building a transparency database

One of my goals with this investigation was to make these documents as accessible as possible to the general public. I didn't want to just tell people the story, I wanted them to be able to read the records for themselves and see insights I might have missed. To that end, I wrote this simple script to break up the original 171 page disclosure and write out one document for each entity referenced, including all relevant records for that entity. Most investees had two separate forms of disclosure at different places within the document, and conjoining those twinned pages made it easier to build a [searchable database of disclosures](../docs/filings) in the GitHub repo.

```python
import pandas as pd
import pdfplumber
from PyPDF2 import PdfWriter, PdfReader
```

```python
df = pd.read_csv('../data/viz/company_filings.csv')
pdf = PdfReader(open('../docs/irs_filings/990T_2021-22.pdf', "rb"))
```

```python
for i in range(0, len(df)):
    outpath = f"../docs-public/filings/{df['company_id'][i]}.pdf"
    pages = [int(page)-1 for page in df['pages'][i].split(',')]

    output = PdfWriter()
    for page in pages:
        output.add_page(pdf.pages[page])
    with open(outpath, "wb") as outputStream:
        output.write(outputStream)
```
