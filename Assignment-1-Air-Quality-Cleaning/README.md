# R Programming Assignment 1 — Air-Quality Data Cleaning

**Student:** Purvaj Gaonkar | **Roll No:** 23102C0083 | **Class:** BE CMPN-C  
**Subject:** R Programming (ODD 2026-27)

---

## Problem Statement

Demonstrate foundational data-cleaning skills in base R using a real-world
multi-pollutant air quality dataset. The assignment covers missing-value
identification, imputation strategies, error handling, visualisation, and clean
export — all within a single reproducible script.

---

## Dataset

| Field | Detail |
|---|---|
| Name | Beijing Multi-Site Air Quality Dataset |
| Source | UCI Machine Learning Repository |
| Station used | **Aotizhongxin** |
| Period | 2013-03-01 → 2017-02-28 |
| Rows | 35 064 |
| Columns | 18 |
| File | `data/PRSA_Data_Aotizhongxin_20130301-20170228.csv` |

---

## Folder Structure

```
.
├── assignment1.R                              ← main script (all 10 tasks)
├── README.md                                  ← this file
├── interpretation.md                          ← analytical write-up
├── data/
│   └── PRSA_Data_Aotizhongxin_20130301-20170228.csv
└── output/
    ├── cleaned_air_quality_data.csv           ← cleaned dataset (35 064 rows)
    ├── missing_values_plot.png                ← grouped bar chart
    └── console_output.txt                     ← full script console log
```

---

## How to Run

> **Prerequisite:** R 4.x installed. If R is not on PATH, prepend its bin
> folder first.

```powershell
# PowerShell — one-liner
$env:Path += ";C:\Program Files\R\R-4.6.1\bin"
Rscript assignment1.R
```

All output is written to the `output/` directory automatically.  
No internet connection or package installation is required — **base R only**.

---

## Task-to-Function Mapping

| Task | Description | Key Function / Construct |
|------|-------------|--------------------------|
| 1 | Import & Inspect | `read.csv()` inside `tryCatch()` |
| 2 | NA vs NULL vs NaN | `is.na()`, `is.null()`, `is.nan()` |
| 3 | Missing value summary | `missing_summary(dataset)` ← user-defined |
| 4 | Pollution ratio & Inf/NaN treatment | `is.nan()`, `is.infinite()` |
| 5 | Loop-based median imputation | `for` loop + `median(x, na.rm=TRUE)` |
| 6 | Mode imputation for categorical | `calculate_mode(x)` ← user-defined |
| 7 | Robust column cleaner | `clean_variable(dataset, variable_name)` ← user-defined |
| 8 | Before/after comparison table | `raw_data` vs imputed `df` |
| 9 | Grouped bar chart | `barplot(beside=TRUE)` → PNG + screen |
| 10 | Export & verify | `write.csv()` + `read.csv()` round-trip |

---

## User-Defined Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `missing_summary` | `missing_summary(dataset)` | Returns a 4-column data frame with missing counts & percentages; calls `warning()` for >20% missing |
| `calculate_mode` | `calculate_mode(x)` | Returns the most frequent value of a character vector; used for `wd` (wind direction) |
| `clean_variable` | `clean_variable(dataset, variable_name)` | Validates and median-imputes a numeric column; handles 4 error cases via `tryCatch()` |

---

## Results Summary

| Metric | Value |
|--------|-------|
| Total rows | 35 064 |
| Total NAs (whole dataset) | 7 271 |
| NAs in 7 selected variables | 3 716 |
| NAs after cleaning | **0** |
| NaN in pollution_ratio | 0 |
| +Inf in pollution_ratio | 0 |
| Output CSV size | 35 064 rows × 18 columns |
