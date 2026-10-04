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
# Import libraries
import pytesseract as pt
from pdf2image import convert_from_path
from autocorrect import Speller
import re
import pandas as pd
from datetime import datetime as dt
```

```python
# Set the local path of the primary disclosures document
file = '../docs/irs_filings/990T_2021-22.pdf'
```

Having opened the document, we define nesting doll functions for extracting larger and larger units of data. At the lowest level, we extract the text from a single page. Wrapped around that we extract structured data from a single page, parsing structure out of the extracted text. Above that, we extract data across multiple pages, using the functionality of the single page approach.

```python
# use regex to extract the investments from raw text
def process_investments(page_img, page_num):
    # Extract a string containing all text on the page using pytesseract
    text = pt.image_to_string(page_img)

    # Extract the lines on the page that begin with exactly one number (these delineate the financial disclosures lines we're interested in)
    details = pd.Series([item for item in text.split('\n') if re.search(r'^\([0-9]{1}\)', item)])

    # Convert each data line to a dictionary entry, with the key being the part of the line before the colon and the value being the part of the line after
    return {k:v for k, v in zip(details.apply(lambda x: re.sub(r'^\([0-9]{1}\)', '', x.split(':')[0]).strip()), details.apply(lambda x: x.split(':', 1)[1].strip()))} | {'page': page_num}

# retrieve all investments from a single page
def get_investments_singular(file, page_num):

    # Convert this particular pdf page to an image
    page = convert_from_path(file, 600, first_page=page_num, last_page=page_num)[0]

    # Pass that image to process_investments to extract the data
    return pd.DataFrame(process_investments(page), index=[0])

# retrieve all investments from a range of pages
def get_investments_multiple(file, first, last):

    # Convert all the relevant pages in the document to a set of images
    pages = convert_from_path(file, 600, first_page=first, last_page=last)

    # Run process_investments on all of those pages and concat the resulting dataframes using a list comprehension
    return pd.concat([pd.DataFrame(process_investments(pages[i], first+i), index=[0]) for i in range(0, len(pages))])

# extract the raw text from a single pdf page
def get_page_text(file, page_num):

    # Convert this particular pdf page to an image
    page = convert_from_path(file, 600, first_page=page_num, last_page=page_num)[0]

    # Return the raw text from that page
    return pt.image_to_string(page)
```

When we analyze this data we'll want the dates to be in a machine-readable format, but not all dates in the documents will be parseable (although most will be). Here, we define a soft-failure date parser that will convert the dates that match the format we expect, and replace the rest explicitly with None so we can count the number of failure instances.

```python
def format_date(x):
    try:
        # Attempt to parse the date in MM/DD/YYYY format
        date = dt.strptime(x, '%m/%d/%Y')
    except:

        # If parsing failed, soft return None
        date = None
    return date
```

Here we use regex to extract the second form of investment disclosures, which are listed as stock trades in the latter half of the document.

```python
def regex_extract_stocks(file, page_num):
    # Get all the raw text from the page
    text = get_page_text(file, page_num)

    # Parse the text as a dataframe using regular expressions
    return pd.DataFrame({
        # The text that occurs between the phrases "44074" and "Oberlin College (EIN"
        'transferee': text[re.search(r'44074', text).end(0):re.search(r'Oberlin College \(EIN', text).start(0)],
        # The text that occurs between the phrases "Oberlin College (EIN" and "Ownership"
        'description': re.search(r'(Oberlin College \(EIN.*)Ownership', text, re.DOTALL).group(1),
        # The text that occurs between the terms "Ownership" and "corporation"
        'consideration_received': re.search(r'Ownership.*corporation', text, re.DOTALL).group(0),
        # The text that matches a dollar sign followed by one or more numbers and commas in any order
        'amount':re.search(r'\$[0-9,]+', text).group(0),
        # The current page number
        'page': page_num
    }, index=[page_num])
```

In this section we define known row delimiters on the page. Farther down, we'll use these to iteratively crop the page into strips to extract values.
We follow this approach to evade all the problems that come with line terminators when values overflow onto multiple lines (which they do sometimes, but not consistently or predictably).

```python
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

Having already extracted the investments form of reporting from the first half of the document, we now extract the stock trades that appear in the second half. (These are largely duplicative of the first half, but they provide some new information.)

```python
def extract_stocks(file, page_num):
    # Extract the raw text from the file
    text = get_page_text(file, page_num)
    
    # Track where we are in the list of known headers we set above
    curr_term = 0
    result = {}

    # split the page into strips based on the delimiters above, and extract values from each strip
    while len(text) > 0 and curr_term < len(splits):

        # Find the index in the page text where the current start header appears
        start = re.search(splits[curr_term], text).start(0)

        # Trim the text to only the text that occurs after that header
        text = text[start:]

        # Set the key to keep track of this information in the data dictionary as the current header being parsed
        out_key = splits[curr_term]

        # Index to the next known header in the list
        curr_term += 1

        # If we have not yet exceeded the list of known headers
        if curr_term < len(splits):

            # Set the end index in the text to be the beginning of the next header in the pre-mapped list
            end = re.search(splits[curr_term], text).start(0)

            # Take the substring between these two headers, and store it in our data dictionary
            result[f'{curr_term}_{out_key}'] = text[len(out_key.replace("\\",'')):end].strip()

            # Crop the text to only the text that occurs after the end header
            text = text[end:]
        else:

            # If we've reached the last header, set the whole remainder of the text, whatever it is, in the last place in the data dictionary
            result[f'{curr_term}_{out_key}'] = text[len(out_key.replace("\\",'')):].strip()

    # Make a pandas dataframe from the parsed results
    df = pd.DataFrame(result, index=[0])

    # Apply data cleaning checks to the dataframe (not in this pared-down example)
    df = clean_stock_frame(df)

    # Keep track of the relevant page number for each record to support manual fact-checking later
    df['Page'] = page_num

    return df
```

After extracting all of the data, we export it to a clean CSV file for analysis in R and visualization in Flourish.

```python
# Investments of disclosure type A appear between pages 17 and 93, manually identified
df = get_investments_multiple(file, 17, 93)

# Write the first type of disclosures to a CSV file
df.to_csv('../data/raw/stock-transfers_2021_raw.csv', index=False)
```

```python
# Investments of disclosure type B appear between pages 94 and the end, manually identified
df = pd.concat([regex_extract_stocks(file, page) for page in range(94, 171)])

# Write the second type of disclosures to a CSV file
df.to_csv('../data/raw/investments_2021_raw.csv', index=False)
```

## Building a transparency database

One of my goals with this investigation was to make these documents as accessible as possible to the general public. I didn't want to just tell people the story, I wanted them to be able to read the records for themselves and see insights I might have missed. To that end, I wrote this simple script to break up the original 171 page disclosure and write out one document for each entity referenced, including all relevant records for that entity. Most investees had two separate forms of disclosure at different places within the document, and conjoining those twinned pages made it easier to build a [searchable database of disclosures](../docs/filings) in the GitHub repo.

```python
# Import the relevant libraries
import pandas as pd
import pdfplumber
from PyPDF2 import PdfWriter, PdfReader
```

We read in the existing dataframe built above to keep track of which entities we want to track:

```python
df = pd.read_csv('../data/viz/company_filings.csv')
```

Then the original filing document, this time as a binary input so we can conditionally output parts of it to the local disk using pdfwriter:

```python
pdf = PdfReader(open('../docs/irs_filings/990T_2021-22.pdf', "rb"))
```

For each row in the database of entities, we select a slice of pages from the document that are relevant to that entity. We merge those pages into one temporary document, and write it out to the disk.

```python
# For each row in the dataframe
for i in range(0, len(df)):

    # Make a filepath in the public filings folder, with the file name matching the cleaned company id
    outpath = f"../docs-public/filings/{df['company_id'][i]}.pdf"

    # Make a list of relevant pages for this company based on the pages tracked in the dataframe, adjusting for zero-indexing in Python
    pages = [int(page)-1 for page in df['pages'][i].split(',')]

    # Make an output object via PdfWriter
    output = PdfWriter()

    # Make an output document containing only the pages relevant to this company
    for page in pages:
        output.add_page(pdf.pages[page])

    # Write the new company document to the specified outpath in the filings directory
    with open(outpath, "wb") as outputStream:
        output.write(outputStream)
```
