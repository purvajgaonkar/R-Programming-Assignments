# =============================================================================
# Assignment 2 – Lab 4: Missing Data Handling (UCI Adult / Census Income)
# Subject  : R Programming (ODD 2026-27)
# Student  : Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C
# Dataset  : UCI Adult (Census Income)
#            https://archive.ics.uci.edu/ml/machine-learning-databases/
#                    adult/adult.data
#            32 561 rows, 15 columns, no header.
#            Missing encoded as " ?" (leading space); strip.white = TRUE handles it.
# =============================================================================
# Run from the lab4-adult-missing-data/ directory:
#   Rscript lab4_missing_data.R
# All output is written to ./output/. No manual file placement needed.
# =============================================================================

# ---- Packages ---------------------------------------------------------------
for (pkg in c("naniar", "skimr", "ggplot2")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}
library(naniar)
library(skimr)
library(ggplot2)

# ---- Utility ----------------------------------------------------------------
banner <- function(title) {
  line <- paste(rep("=", 70), collapse = "")
  cat("\n", line, "\n", title, "\n", line, "\n", sep = "")
}

# Ensure output directory exists
if (!dir.exists("output")) dir.create("output")

# =============================================================================
# TASK 1 – IMPORT & VERIFY
# =============================================================================
banner("TASK 1 – IMPORT & VERIFY")

col_names <- c("age", "workclass", "fnlwgt", "education", "education_num",
               "marital_status", "occupation", "relationship", "race", "sex",
               "capital_gain", "capital_loss", "hours_per_week",
               "native_country", "income")

data_url  <- paste0(
  "https://archive.ics.uci.edu/ml/machine-learning-databases/",
  "adult/adult.data"
)
data_path <- "data/adult.data"

if (!file.exists(data_path)) {
  cat("Downloading UCI Adult data...\n")
  tryCatch(
    download.file(data_url, destfile = data_path, mode = "wb", quiet = FALSE),
    error = function(e) stop("Download failed: ", conditionMessage(e))
  )
  cat("Download complete.\n")
} else {
  cat("Data file already present – skipping download.\n")
}

adult <- tryCatch(
  read.csv(
    data_path,
    header          = FALSE,
    col.names       = col_names,
    na.strings      = "?",
    strip.white     = TRUE,   # handles the leading-space " ?" sentinel
    stringsAsFactors = FALSE
  ),
  error = function(e) stop("Could not read data file: ", conditionMessage(e))
)

# Verify dimensions (last row is blank in the raw file; drop it if needed)
if (nrow(adult) > 32561) adult <- adult[seq_len(32561), ]

expected_rows <- 32561L
expected_cols <- 15L
if (nrow(adult) != expected_rows || ncol(adult) != expected_cols) {
  stop(sprintf(
    "Dimension mismatch: expected %d x %d, got %d x %d.",
    expected_rows, expected_cols, nrow(adult), ncol(adult)
  ))
}
cat(sprintf("Dimensions OK: %d rows x %d columns\n", nrow(adult), ncol(adult)))
cat("Column names:", paste(names(adult), collapse = ", "), "\n")
cat("\nFirst 6 rows:\n")
print(head(adult))
cat("\nBaseline NA count per column:\n")
print(colSums(is.na(adult)))

# =============================================================================
# TASK 2 – INJECT MISSING / ERRONEOUS VALUES
# =============================================================================
banner("TASK 2 – INJECT MISSING / ERRONEOUS VALUES")

# Keep the original for before/after comparison
adult_orig <- adult

set.seed(123)

# 2a. NA injections into hours_per_week
na_rows_hrs <- sample(nrow(adult), 200)
adult$hours_per_week[na_rows_hrs] <- NA
cat("Injected NAs into hours_per_week at", length(na_rows_hrs), "rows.\n")
cat("  First 10 row indices:", head(na_rows_hrs, 10), "\n")

# 2b. Blank string ("") injections into workclass (categorical)
blank_rows_wc <- sample(nrow(adult), 150)
adult$workclass[blank_rows_wc] <- ""
cat("Injected blank strings into workclass at", length(blank_rows_wc), "rows.\n")
cat("  First 10 row indices:", head(blank_rows_wc, 10), "\n")

# 2c. NaN injections into capital_gain (numeric coercion trick)
nan_rows_cg <- sample(nrow(adult), 80)
adult$capital_gain <- as.numeric(adult$capital_gain)
adult$capital_gain[nan_rows_cg] <- NaN
cat("Injected NaN into capital_gain at", length(nan_rows_cg), "rows.\n")
cat("  First 10 row indices:", head(nan_rows_cg, 10), "\n")

# 2d. Impossible age injections
impossible_age_rows <- sample(nrow(adult), 50)
adult$age[impossible_age_rows] <- 999
cat("Injected age = 999 at", length(impossible_age_rows), "rows.\n")
cat("  First 10 row indices:", head(impossible_age_rows, 10), "\n")

cat("\nPost-injection NA summary:\n")
print(colSums(is.na(adult)))

# =============================================================================
# TASK 3 – DETECTION OF MISSING / PROBLEMATIC VALUES
# =============================================================================
banner("TASK 3 – DETECTION")

cat("\n--- is.na() detection (hours_per_week) ---\n")
na_count_hrs <- sum(is.na(adult$hours_per_week))
cat("NAs in hours_per_week:", na_count_hrs, "\n")

cat("\n--- is.nan() detection (capital_gain) ---\n")
nan_count_cg <- sum(is.nan(adult$capital_gain))
cat("NaNs in capital_gain:", nan_count_cg, "\n")

cat("\n--- Blank-string detection (workclass) ---\n")
blank_count_wc <- sum(adult$workclass == "", na.rm = TRUE)
cat("Blank strings in workclass:", blank_count_wc, "\n")

cat("\n--- Range-check detection: impossible age (age == 999) ---\n")
impossible_age_count <- sum(adult$age == 999, na.rm = TRUE)
cat("Rows with age = 999:", impossible_age_count, "\n")

# --- is.null() demonstration on a standalone R object ------------------------
cat("\n--- is.null() demonstration ---\n")
null_object <- NULL
cat("is.null(null_object):", is.null(null_object), "\n")
cat("is.null(NA)          :", is.null(NA),          "\n")
cat("is.null(\"\")          :", is.null(""),          "\n")

cat("\n")
cat("NOTE: NULL cannot exist inside a data frame cell.\n")
cat("A data frame stores each column as a vector, and R vectors cannot\n")
cat("contain NULL elements. Assigning NULL to a data frame column drops\n")
cat("the column entirely (df$col <- NULL removes the column). Therefore,\n")
cat("a missing categorical value is represented as NA or a blank string,\n")
cat("never as NULL. is.null() is useful for checking whether a variable\n")
cat("or list element is absent, not for checking cell contents.\n")

# --- naniar variable-level missingness summary --------------------------------
cat("\n--- naniar::miss_var_summary() ---\n")
# naniar treats NaN as missing, blank strings are not counted as NA by naniar
# so we snapshot here before treatment
miss_summary_before <- miss_var_summary(adult)
print(miss_summary_before)

# =============================================================================
# TASK 4 – BEFORE missingness stats (used again in Task 6)
# =============================================================================
banner("TASK 4 – BEFORE/AFTER MISSINGNESS COUNTS")

count_missing_pct <- function(df, label = "Dataset") {
  total_cells  <- prod(dim(df))
  total_na     <- sum(is.na(df))
  cat(sprintf("[%s] Total cells: %d | NAs: %d | Missing %%: %.2f%%\n",
              label, total_cells, total_na,
              100 * total_na / total_cells))
  invisible(list(total = total_cells, na = total_na,
                 pct = 100 * total_na / total_cells))
}

before_stats <- count_missing_pct(adult, "Before treatment")

# naniar visualisations – BEFORE treatment
cat("\nSaving naniar plots (before treatment)...\n")

p_miss_var_before <- gg_miss_var(adult) +
  labs(title = "Missing Values per Variable (Before Treatment)") +
  theme_minimal()
ggsave("output/miss_var_before.png", p_miss_var_before,
       width = 10, height = 6, dpi = 120)
cat("Saved output/miss_var_before.png\n")

# vis_miss on 5 000-row sample (32k rows do not render legibly)
set.seed(1)
adult_sample <- adult[sample(nrow(adult), 5000), ]
p_vis_miss_before <- vis_miss(adult_sample) +
  labs(title = "Missingness Pattern – 5 000-row Sample (Before Treatment)")
ggsave("output/vis_miss_before.png", p_vis_miss_before,
       width = 12, height = 6, dpi = 120)
cat("Saved output/vis_miss_before.png\n")

# =============================================================================
# TASK 5 – CUSTOM IMPUTATION FUNCTION
# =============================================================================
banner("TASK 5 – CUSTOM MEDIAN IMPUTATION FUNCTION")

# impute_median: takes a numeric vector, replaces NA and NaN with the median
# of the valid (non-NA, non-NaN) observations.
# Handles an all-NA/NaN input gracefully by returning the vector unchanged
# with a warning instead of erroring.
impute_median <- function(x) {
  if (!is.numeric(x)) {
    warning("impute_median: input is not numeric. Returning unchanged.")
    return(x)
  }
  valid_vals <- x[!is.na(x) & !is.nan(x)]
  if (length(valid_vals) == 0) {
    warning("impute_median: all values are NA/NaN; cannot compute median. Returning as-is.")
    return(x)
  }
  med <- median(valid_vals)
  x[is.na(x) | is.nan(x)] <- med
  return(x)
}

# Demonstration: all-NA input
cat("All-NA input test:\n")
all_na_vec <- c(NA, NA, NA)
result_all_na <- impute_median(all_na_vec)
cat("  Result:", result_all_na, "\n")

# Normal use
cat("\nNormal use: c(1, NA, 3, NaN, 5):\n")
test_vec <- c(1, NA, 3, NaN, 5)
cat("  Before:", test_vec, "\n")
cat("  After :", impute_median(test_vec), "\n")

# =============================================================================
# TASK 6 – TREATMENT
# =============================================================================
banner("TASK 6 – TREATMENT")

# Work on a copy
adult_clean <- adult

# 6a. Impossible numeric values -> NA
cat("6a. Setting age = 999 to NA...\n")
adult_clean$age[adult_clean$age == 999] <- NA
cat("  Remaining age = 999:", sum(adult_clean$age == 999, na.rm = TRUE), "\n")

# 6b. NaN in capital_gain: NaN is technically NA in R's data frame but
#     we treat it explicitly before median imputation
cat("\n6b. NaN in capital_gain: treat as NA then impute...\n")
adult_clean$capital_gain[is.nan(adult_clean$capital_gain)] <- NA
cat("  NaN remaining in capital_gain:", sum(is.nan(adult_clean$capital_gain)), "\n")

# 6c. Blank strings in workclass -> "Unknown"
cat("\n6c. Replacing blank strings in workclass with 'Unknown'...\n")
adult_clean$workclass[adult_clean$workclass == ""] <- "Unknown"
cat("  Blank strings remaining:", sum(adult_clean$workclass == "", na.rm = TRUE), "\n")
cat("  'Unknown' count:", sum(adult_clean$workclass == "Unknown"), "\n")

# 6d. Median imputation for numeric NAs
numeric_cols <- c("age", "hours_per_week", "capital_gain",
                  "capital_loss", "fnlwgt", "education_num")
cat("\n6d. Median imputation for numeric columns...\n")
for (col in numeric_cols) {
  na_before <- sum(is.na(adult_clean[[col]]))
  if (na_before > 0) {
    adult_clean[[col]] <- impute_median(adult_clean[[col]])
    cat(sprintf("  %-20s: %d NAs imputed with median = %.1f\n",
                col, na_before, median(adult_orig[[col]], na.rm = TRUE)))
  }
}

# 6e. Remove rows where occupation or native_country is still NA
# (categorical NAs from original dataset; median imputation not applicable)
cat("\n6e. Removing rows with unrecoverable NA in categorical cols...\n")
rows_before <- nrow(adult_clean)
adult_clean <- adult_clean[!is.na(adult_clean$occupation) &
                           !is.na(adult_clean$native_country), ]
cat(sprintf("  Removed %d rows (%.2f%% of data).\n",
            rows_before - nrow(adult_clean),
            100 * (rows_before - nrow(adult_clean)) / rows_before))

# 6f. complete.cases() report
n_complete   <- sum(complete.cases(adult_clean))
n_incomplete <- sum(!complete.cases(adult_clean))
cat(sprintf("\n6f. Complete cases  : %d (%.2f%%)\n",
            n_complete, 100 * n_complete / nrow(adult_clean)))
cat(sprintf("    Incomplete cases: %d (%.2f%%)\n",
            n_incomplete, 100 * n_incomplete / nrow(adult_clean)))

# =============================================================================
# TASK 7 – BEFORE/AFTER COMPARISON & NANIAR PLOTS
# =============================================================================
banner("TASK 7 – BEFORE / AFTER COMPARISON")

after_stats <- count_missing_pct(adult_clean, "After treatment")
cat(sprintf("Missingness reduced from %.2f%% to %.2f%%\n",
            before_stats$pct, after_stats$pct))

# Compute per-column before/after
ba_df <- data.frame(
  column      = names(adult),
  na_before   = colSums(is.na(adult)),
  pct_before  = round(100 * colSums(is.na(adult)) / nrow(adult), 2)
)
common_cols <- intersect(names(adult), names(adult_clean))
na_after_vec <- sapply(common_cols, function(c) sum(is.na(adult_clean[[c]])))
ba_df$na_after  <- na_after_vec[match(ba_df$column, names(na_after_vec))]
ba_df$pct_after <- round(100 * ba_df$na_after / nrow(adult_clean), 2)
cat("\nPer-column before/after:\n")
print(ba_df)

# Naniar plots AFTER treatment
p_miss_var_after <- gg_miss_var(adult_clean) +
  labs(title = "Missing Values per Variable (After Treatment)") +
  theme_minimal()
ggsave("output/miss_var_after.png", p_miss_var_after,
       width = 10, height = 6, dpi = 120)
cat("\nSaved output/miss_var_after.png\n")

set.seed(2)
adult_clean_sample <- adult_clean[sample(nrow(adult_clean), 5000), ]
p_vis_miss_after <- vis_miss(adult_clean_sample) +
  labs(title = "Missingness Pattern – 5 000-row Sample (After Treatment)")
ggsave("output/vis_miss_after.png", p_vis_miss_after,
       width = 12, height = 6, dpi = 120)
cat("Saved output/vis_miss_after.png\n")

# =============================================================================
# TASK 8 – VALIDATE WITH skimr + PROGRAMMATIC ASSERTIONS
# =============================================================================
banner("TASK 8 – VALIDATE WITH skimr")

cat("skimr::skim() on cleaned dataset:\n")
print(skim(adult_clean))

# Programmatic assertions
cat("\n--- Programmatic assertions ---\n")

# No age = 999
if (any(adult_clean$age == 999, na.rm = TRUE)) {
  stop("ASSERTION FAILED: age = 999 still present.")
} else {
  cat("PASSED: no age = 999 values.\n")
}

# No untreated NAs in numeric cols
for (col in numeric_cols) {
  if (col %in% names(adult_clean)) {
    n <- sum(is.na(adult_clean[[col]]))
    if (n > 0) {
      stop(sprintf("ASSERTION FAILED: %d NAs remain in numeric col '%s'.", n, col))
    } else {
      cat(sprintf("PASSED: no NAs in '%s'.\n", col))
    }
  }
}

# No blank strings in categorical cols
cat_cols <- c("workclass", "occupation", "marital_status",
              "relationship", "race", "sex", "income")
for (col in cat_cols) {
  if (col %in% names(adult_clean)) {
    n <- sum(adult_clean[[col]] == "", na.rm = TRUE)
    if (n > 0) {
      stop(sprintf("ASSERTION FAILED: %d blank strings in '%s'.", n, col))
    } else {
      cat(sprintf("PASSED: no blank strings in '%s'.\n", col))
    }
  }
}

# =============================================================================
# TASK 9 – EXPORT & VERIFY
# =============================================================================
banner("TASK 9 – EXPORT & VERIFY")

output_path <- "output/cleaned_adult_data.csv"
write.csv(adult_clean, output_path, row.names = FALSE)
cat("Exported:", output_path, "\n")

adult_reread <- read.csv(output_path, stringsAsFactors = FALSE)
cat("Re-read dimensions:", nrow(adult_reread), "rows x",
    ncol(adult_reread), "cols\n")
stopifnot(nrow(adult_reread) == nrow(adult_clean))
stopifnot(ncol(adult_reread) == ncol(adult_clean))
cat("Column names match:", identical(names(adult_reread), names(adult_clean)), "\n")
if (any(adult_reread$age == 999, na.rm = TRUE)) {
  stop("EXPORT VERIFY FAILED: age = 999 found after re-read.")
}
cat("Export verification PASSED.\n")

banner("ALL TASKS COMPLETE")
cat("Output files in ./output/:\n")
cat(paste(" -", list.files("output"), collapse = "\n"), "\n")
