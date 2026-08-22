# Assignment 3: Retail Data Integration and Analysis

**Course**: R Programming, Semester 7 - BE Computer Engineering  
**Lab type**: Single integrated lab  
**Submission**: Executed `.ipynb` exported to PDF + this GitHub repository

---

## Overview

This lab demonstrates multi-source data integration using a real-world retail transaction dataset from the UCI Machine Learning Repository. Three data formats (CSV, JSON, Excel) are imported, cleaned, joined with `dplyr`, analysed for sales and customer behaviour, stored in a SQLite database, and queried via SQL. Results are verified by cross-checking dplyr and SQL outputs.

---

## Dataset

**Source**: UCI Online Retail Dataset  
**URL**: `https://archive.ics.uci.edu/ml/machine-learning-databases/00352/Online%20Retail.xlsx`  
**Raw file**: 541,909 rows, 8 columns (InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country)

The raw file is downloaded at runtime into `data/` and is not committed to the repository (see `.gitignore`).

The raw file is split into three normalised source files by `prepare_sources.R`:

| File | Format | Rows | Columns |
|---|---|---|---|
| `data/transactions.csv` | CSV | 541,909 | 5 |
| `data/products.json` | JSON | 4,070 | 3 |
| `data/customers.xlsx` | Excel | 4,372 | 2 |

---

## Repository Structure

```
Assignment-3-Retail-Data-Integration/
├── data/                     # Raw + generated files (not committed)
├── output/                   # SQLite DB, CSVs, plots, console log (committed)
│   ├── retail_sales.db
│   ├── plot1_top_products.png
│   ├── plot2_customer_segments.png
│   └── console_output.txt
├── prepare_sources.R         # Downloads raw file, splits into three sources
├── assignment3_retail.R      # Main analysis script (all four tasks)
├── assignment3.ipynb         # Executed R-kernel Jupyter notebook
├── interpretation.md         # Cleaning decisions, join rationale, insights
├── README.md                 # This file
└── .gitignore
```

---

## How to Run

### Option 1: Jupyter Notebook (Colab or local)

Open `assignment3.ipynb` using a Jupyter environment with the R kernel (`ir`). The notebook is self-contained: it downloads the dataset if absent, installs missing packages, and runs all tasks sequentially. On Google Colab, the R kernel is available via `IRkernel`.

### Option 2: Standalone R scripts (local only)

Ensure R 4.x is installed and run from inside `Assignment-3-Retail-Data-Integration/`:

```powershell
# Step 0: download + split sources
Rscript prepare_sources.R

# Main analysis (Tasks 1-4)
Rscript assignment3_retail.R
```

---

## Required Packages

| Package | Purpose |
|---|---|
| `readr` | Import CSV |
| `readxl` | Import Excel |
| `writexl` | Write Excel |
| `jsonlite` | Import/export JSON |
| `dplyr` | Data manipulation and joins |
| `ggplot2` | Plotting |
| `DBI` | Database interface |
| `RSQLite` | SQLite backend |

All packages are auto-installed by both scripts and the notebook if not already present.

---

## Deliverables

| File | Description |
|---|---|
| `assignment3.ipynb` | Executed notebook with inline outputs and plots |
| `assignment3_retail.R` | Standalone analysis script |
| `prepare_sources.R` | Source preparation script |
| `output/retail_sales.db` | SQLite database (41.36 MB) |
| `output/plot1_top_products.png` | Top 5 products by revenue |
| `output/plot2_customer_segments.png` | Customer segment distribution |
| `output/console_output.txt` | Full console output from the R script |
| `interpretation.md` | Written interpretation and insights |

---

## Key Results

| Metric | Value |
|---|---|
| Raw rows | 541,909 |
| Rows after cleaning | 535,092 (valid revenue) |
| Cancellations retained | 9,177 rows (-$815,184 net) |
| Total net revenue | $10,241,241 |
| Top product | DOTCOM POSTAGE ($315,693) |
| Top country (by revenue) | United Kingdom ($7,407,550) |
| Top country (by revenue/customer) | EIRE ($92,083 per customer) |
| Premium segment customers | 219 (4.8% of base, $4,605,504 spend) |
| SQLite DB size | 41.36 MB |
