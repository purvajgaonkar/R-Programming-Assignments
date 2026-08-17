# R Programming Assignment 2 — Control Flow & Missing Data

**Student:** Purvaj Gaonkar | **Roll No:** 23102C0083 | **Class:** BE CMPN-C  
**Subject:** R Programming (ODD 2026-27)

---

## Problem Statement

This assignment covers advanced control flow and missing data mechanisms across two distinct labs. 

**Lab 3 (Heart Disease BP Cleaning)** focuses on conditional execution, custom error handling, and a runtime performance comparison between iterative loops and vectorized operations in R. 

**Lab 4 (Adult Census Income Missingness)** implements detection, systematic classification, custom median imputation, and before-and-after missingness analysis using the `naniar` and `skimr` ecosystems.

---

## Datasets

| Lab | Name | Source | Size (Baseline) | Variable of Interest / Focus |
|---|---|---|---|---|
| **Lab 3** | Cleveland Heart Disease | UCI ML Repository | 303 rows × 14 columns | `trestbps` (Resting Blood Pressure) |
| **Lab 4** | Adult / Census Income | UCI ML Repository | 32,561 rows × 15 columns | Multi-variable missingness and imputation |

---

## Folder Structure

```
Assignment-2-Control-Flow-Missing-Data/
├── lab3-heart-disease/
│   ├── data/                           ← downloaded at runtime (ignored)
│   │   └── processed.cleveland.data
│   ├── output/                         ← benchmark reports, tables, plots
│   │   ├── benchmark_comparison.png    ← Loop vs Vectorized Boxplot
│   │   ├── bp_before_after.png         ← Before/After distribution comparison
│   │   ├── bp_distribution.png         ← Cleaned BP histogram
│   │   ├── cleaned_heart_data.csv      ← Final exported CSV
│   │   └── console_output.txt          ← Executed Rscript output log
│   ├── lab3_bp_cleaning.R              ← Standalone R script
│   ├── lab3.ipynb                      ← R Kernel Jupyter Notebook
│   └── interpretation.md               ← Loop vs vectorization analysis
├── lab4-adult-missing-data/
│   ├── data/                           ← downloaded at runtime (ignored)
│   │   └── adult.data
│   ├── output/                         ← missingness reports and plots
│   │   ├── cleaned_adult_data.csv      ← Final exported CSV
│   │   ├── console_output.txt          ← Executed Rscript output log
│   │   ├── miss_var_before.png         ← naniar variable-wise baseline
│   │   ├── miss_var_after.png          ← naniar variable-wise clean
│   │   ├── vis_miss_before.png         ← naniar missingness grid (sample)
│   │   └── vis_miss_after.png          ← naniar missingness grid (clean)
│   ├── lab4_missing_data.R             ← Standalone R script
│   ├── lab4.ipynb                      ← R Kernel Jupyter Notebook
│   └── interpretation.md               ← Missingness patterns & median imputation limits
├── .gitignore                          ← local git exclusions
└── README.md                           ← this file
```

---

## How to Run

### Prerequisites

An R installation (version 4.x) with the executable on your PATH. Note that on Windows PowerShell, the bare command `R` is often an alias for `Invoke-History`. Always execute using `Rscript`.

The required R packages (`microbenchmark`, `ggplot2`, `naniar`, `skimr`) will be installed automatically by the scripts if they are not already present in your environment.

### Execution

To run the standalone R scripts and save console outputs to their respective folders:

```powershell
# Execute Lab 3
cd lab3-heart-disease
Rscript lab3_bp_cleaning.R | Tee-Object -FilePath output/console_output.txt
cd ..

# Execute Lab 4
cd lab4-adult-missing-data
Rscript lab4_missing_data.R | Tee-Object -FilePath output/console_output.txt
cd ..
```

To run the Jupyter Notebooks:
Open Jupyter Notebook or JupyterLab and run `lab3.ipynb` and `lab4.ipynb` cell-by-cell. Alternatively, execute them from the command line:

```powershell
jupyter nbconvert --to notebook --execute --inplace lab3-heart-disease/lab3.ipynb
jupyter nbconvert --to notebook --execute --inplace lab4-adult-missing-data/lab4.ipynb
```

---

## Task-to-Function Mapping

### Lab 3 (Heart Disease)

| Task | Requirement | Key Implementations |
|------|-------------|---------------------|
| **1** | Import & Verify | `read.csv(na.strings="?")` + size checking |
| **2** | Corruption Injection | Negative, NA, and >300 mmHg injection via `set.seed(42)` |
| **3** | BP-Cleaning Function | Custom element-wise `clean_bp()` using `if-else` |
| **4** | Error Handling | `tryCatch()` to intercept warnings, invalid division, and non-numeric ratio inputs |
| **5** | Loop vs Vectorized Benchmark | Execution time evaluation using `system.time()` and `microbenchmark` |
| **6** | Validation | Range checks, programmatic assertions, and output plot generation |
| **7** | Export & Verify | CSV export without row names and re-import verification |

### Lab 4 (Adult Census)

| Task | Requirement | Key Implementations |
|------|-------------|---------------------|
| **1** | Import & Verify | `read.csv(na.strings="?", strip.white=TRUE)` |
| **2** | Corruption Injection | Hours, workclass blanks, gain NaNs, and ages (999) via `set.seed(123)` |
| **3** | Detection | `is.na()`, `is.nan()`, `x == ""` range check, and `naniar::miss_var_summary()` |
| **4** | Custom Imputation | Vector-level `impute_median()` with grace handler for all-NA inputs |
| **5** | Before/After Analysis | Total percentage summaries and `naniar` visualizations |
| **6** | Treatment | Numeric conversions, categorical imputation, and row filtering |
| **7** | Validation | `skimr::skim()` reports and strict programmatic assertions |
| **8** | Export & Verify | CSV export, round-trip check, and validation |

---

## Results Summary

### Lab 3 (Heart Disease BP Cleaning)
* **Dataset Size:** 303 rows × 14 columns
* **Injected Outliers:** 5 negative blood pressure values, 4 NAs, and 4 entries above 300 mmHg.
* **Cleaning Rule:** Negative BP mapped to `NA`, BP > 250 capped at 250, valid values preserved.
* **Large Benchmark Size:** 1,000,000 observations.
* **Speedup Factor:** **11.9x** (Loop median 130.64 ms vs Vectorized median 10.99 ms).

### Lab 4 (Adult Census Income Missingness)
* **Dataset Size:** 32,561 rows × 15 columns
* **Baseline Missingness:** 0.93% of total cells.
* **Custom Imputation Medians:**
  * `age`: **37.0**
  * `hours_per_week`: **40.0**
  * `capital_gain`: **0.0**
* **Categorical Handling:** Blank cells converted to `"Unknown"`, unrecoverable rows removed (2,399 rows, 7.37% of data).
* **Final Cleansed Count:** 30,162 complete rows, 0% missingness.
