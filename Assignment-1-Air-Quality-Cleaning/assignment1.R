# =============================================================================
# Assignment 1 – Air-Quality Data Cleaning
# Subject  : R Programming (ODD 2026-27)
# Student  : Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C
# Dataset  : Beijing Multi-Site Air Quality Dataset (UCI ML Repository)
#            Station: Aotizhongxin  (2013-03-01 to 2017-02-28)
# =============================================================================
# NOTE: All paths are RELATIVE so the script runs for any user who clones the
# repository. Base R only – no external packages required.
# =============================================================================

# Ensure output directory exists before any write operations
if (!dir.exists("output")) dir.create("output")

# Helper banner function – keeps section headers consistent across console output
banner <- function(title) {
  line <- paste(rep("=", 70), collapse = "")
  cat("\n", line, "\n", title, "\n", line, "\n", sep = "")
}

# =============================================================================
# TASK 1 – IMPORT & INSPECT
# =============================================================================
# WHY: We wrap the import in tryCatch() so that any deployment issue (wrong
# working directory, corrupted file, wrong format) gives a clear, actionable
# error message instead of a cryptic R stack trace.  Saving 'raw_data'
# immediately after successful import preserves the original state so Task 8
# can produce an honest before/after comparison.
# =============================================================================

banner("TASK 1 – IMPORT & INSPECT")

data_path <- "data/PRSA_Data_Aotizhongxin_20130301-20170228.csv"

# Three distinct error cases are handled:
#   1. File not found  – most common setup mistake
#   2. File cannot be opened  – permissions or OS lock
#   3. Incorrect file format – not a valid CSV / wrong columns

df <- tryCatch({

  # Case 1: file not found
  if (!file.exists(data_path)) {
    stop("FILE_NOT_FOUND")
  }

  # Case 2: file cannot be opened (try to open a connection)
  con <- tryCatch(
    file(data_path, open = "r"),
    error = function(e) stop("FILE_CANNOT_BE_OPENED")
  )
  close(con)

  # Actual import:
  #   check.names = FALSE  → column "PM2.5" keeps its dot (not renamed to PM2.5)
  #   na.strings           → treat all common representations of missing as NA
  tmp <- read.csv(
    data_path,
    check.names  = FALSE,
    na.strings   = c("NA", "", "\u00a0", " ", "NaN"),
    stringsAsFactors = FALSE
  )

  # Case 3: format check – expect at least these core columns
  required_cols <- c("PM2.5", "PM10", "SO2", "NO2", "TEMP", "WSPM", "wd")
  missing_cols  <- setdiff(required_cols, colnames(tmp))
  if (length(missing_cols) > 0) {
    stop(paste("FILE_FORMAT_INCORRECT – missing columns:", paste(missing_cols, collapse = ", ")))
  }

  tmp   # return the data frame on success

}, error = function(e) {
  msg <- conditionMessage(e)
  if (grepl("FILE_NOT_FOUND", msg)) {
    cat("ERROR: Dataset file not found at path:", data_path, "\n")
    cat("Please ensure the file is present before running this script.\n")
  } else if (grepl("FILE_CANNOT_BE_OPENED", msg)) {
    cat("ERROR: File exists but cannot be opened (check permissions).\n")
  } else if (grepl("FILE_FORMAT_INCORRECT", msg)) {
    cat("ERROR:", msg, "\n")
  } else {
    cat("ERROR during import:", msg, "\n")
  }
  stop("Import failed – cannot continue.")
})

# Save an untouched copy immediately – Task 8 compares this to the cleaned df
raw_data <- df

cat("\n--- head() – first 6 rows ---\n")
print(head(df, 6))

cat("\n--- str() – structure ---\n")
str(df)

cat("\n--- Dimensions ---\n")
cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")

cat("\n--- NA presence ---\n")
has_na <- anyNA(df)
cat("Any NAs present?", has_na, "\n")
cat("Total NA count:", sum(is.na(df)), "\n")

cat("\n--- Column-wise NA counts ---\n")
col_na <- colSums(is.na(df))
print(col_na[col_na > 0])   # only show columns that actually have NAs

# =============================================================================
# TASK 2 – NA vs NULL vs NaN
# =============================================================================
# WHY: Students often conflate these three concepts.  Demonstrating them with
# is.na(), is.null(), is.nan() and showing length differences makes the
# distinctions concrete and testable.
# =============================================================================

banner("TASK 2 – NA vs NULL vs NaN")

demo_na  <- NA
demo_null <- NULL
demo_nan  <- NaN

cat("\n--- Basic type demonstrations ---\n")
cat("Value | NA        | NULL     | NaN\n")
cat("------+-----------+----------+----------\n")
cat(sprintf("%-6s| %-10s| %-9s| %s\n", "is.na()",  is.na(demo_na),  is.na(demo_null),  is.na(demo_nan)))
cat(sprintf("%-6s| %-10s| %-9s| %s\n", "is.null()", is.null(demo_na), is.null(demo_null), is.null(demo_nan)))
cat(sprintf("%-6s| %-10s| %-9s| %s\n", "is.nan()", is.nan(demo_na), is.nan(demo_null), is.nan(demo_nan)))

cat("\n--- Length demonstration ---\n")
cat("length(NA)   =", length(demo_na),   "← NA is a scalar placeholder\n")
cat("length(NULL) =", length(demo_null), "← NULL is the absence of an object\n")
cat("length(NaN)  =", length(demo_nan),  "← NaN is a numeric value (IEEE 754)\n")

cat("\n--- NaN dual membership ---\n")
cat("is.nan(NaN)  =", is.nan(demo_nan),
    "← NaN is numerically 'not a number'\n")
cat("is.na(NaN)   =", is.na(demo_nan),
    "← NaN also counts as missing in R\n")

cat("\n--- Comparison table ---\n")
comparison_table <- data.frame(
  Concept  = c("NA",   "NULL",  "NaN"),
  is.na    = c(TRUE,   FALSE,   TRUE),
  is.null  = c(FALSE,  TRUE,    FALSE),
  is.nan   = c(FALSE,  FALSE,   TRUE),
  Length   = c(1L,     0L,      1L),
  stringsAsFactors = FALSE
)
print(comparison_table)

# =============================================================================
# TASK 3 – missing_summary() USER-DEFINED FUNCTION
# =============================================================================
# WHY: A reusable function avoids repeating the same summary logic for every
# variable.  warning() (not stop()) is used for high-missingness columns so
# execution continues – the analyst is alerted but not blocked.
# =============================================================================

banner("TASK 3 – missing_summary() USER-DEFINED FUNCTION")

missing_summary <- function(dataset) {
  # Validate input
  if (!is.data.frame(dataset)) stop("Input must be a data frame.")

  result <- data.frame(
    Variable           = character(),
    Total_Records      = integer(),
    Missing_Values     = integer(),
    Missing_Percentage = numeric(),
    stringsAsFactors   = FALSE
  )

  for (col in colnames(dataset)) {
    n_total   <- nrow(dataset)
    n_missing <- sum(is.na(dataset[[col]]))
    pct       <- round(n_missing / n_total * 100, 2)

    result <- rbind(result, data.frame(
      Variable           = col,
      Total_Records      = n_total,
      Missing_Values     = n_missing,
      Missing_Percentage = pct,
      stringsAsFactors   = FALSE
    ))

    # Alert if any variable exceeds 20 % missing
    if (pct > 20) {
      warning(sprintf("Variable '%s' has %.2f%% missing values (>20%% threshold).", col, pct))
    }
  }

  result
}

# Apply to the seven selected variables
selected_vars   <- c("PM2.5", "PM10", "SO2", "NO2", "TEMP", "WSPM", "wd")
subset_for_task3 <- df[, selected_vars, drop = FALSE]

cat("\n--- Missing value summary for selected variables ---\n")
summary_result <- missing_summary(subset_for_task3)
print(summary_result)

# =============================================================================
# TASK 4 – pollution_ratio = PM2.5 / PM10 (NaN / Inf treatment)
# =============================================================================
# WHY: This task MUST run before Task 5 imputation.  After imputation the
# medians fill in zeroes and near-zeroes in PM10, which would produce very
# large but finite ratios – obscuring the original division-by-zero / 0/0
# cases.  We count each special value separately so the student can explain
# what they represent ecologically.
# =============================================================================

banner("TASK 4 – pollution_ratio (PM2.5 / PM10)")

# Compute ratio on the RAW (unimputed) columns
pollution_ratio <- df[["PM2.5"]] / df[["PM10"]]

# --- Count special values BEFORE treatment ---
n_na_ratio    <- sum(is.na(pollution_ratio) & !is.nan(pollution_ratio))
n_nan_ratio   <- sum(is.nan(pollution_ratio))
n_posinf_ratio <- sum(is.infinite(pollution_ratio) & pollution_ratio > 0)
n_neginf_ratio <- sum(is.infinite(pollution_ratio) & pollution_ratio < 0)

cat("\n--- Counts BEFORE treatment ---\n")
cat("NA  (propagated from source columns):", n_na_ratio, "\n")
cat("NaN (0 / 0 – both sensors zero)     :", n_nan_ratio, "\n")
cat("+Inf (positive / 0)                 :", n_posinf_ratio, "\n")
cat("-Inf (negative / 0 – impossible here):", n_neginf_ratio, "\n")

# Ecological interpretation
cat("\nInterpretation:\n")
cat("  NaN  → both PM2.5 and PM10 recorded as 0 simultaneously\n")
cat("  +Inf → PM2.5 > 0 but PM10 = 0 (sensor error or record anomaly)\n")
cat("  NA   → at least one source column was already missing\n")

# --- Replace NaN and Inf with NA ---
# is.nan() catches only NaN; is.infinite() catches both +Inf and -Inf
pollution_ratio[is.nan(pollution_ratio)]      <- NA
pollution_ratio[is.infinite(pollution_ratio)] <- NA

cat("\n--- Counts AFTER treatment ---\n")
cat("NA (total):", sum(is.na(pollution_ratio)), "\n")
cat("NaN       :", sum(is.nan(pollution_ratio)), "\n")
cat("Inf       :", sum(is.infinite(pollution_ratio)), "\n")

# =============================================================================
# TASK 5 – LOOP-BASED MEDIAN IMPUTATION
# =============================================================================
# WHY: A single for-loop over a character vector of column names is idiomatic
# base-R and makes it trivial to add or remove variables.  Median is preferred
# over mean for pollutant data because concentrations are typically right-
# skewed (many low readings plus occasional extreme pollution events); the
# median is robust to those outliers and does not pull the imputed value
# upward artificially.
# =============================================================================

banner("TASK 5 – LOOP-BASED MEDIAN IMPUTATION")

numeric_variables <- c("PM2.5", "PM10", "SO2", "NO2", "TEMP", "WSPM")

# One loop – graded requirement
for (var in numeric_variables) {

  # Check the column exists (defensive; already validated in import)
  if (!var %in% colnames(df)) {
    cat("SKIP:", var, "– column not found in data frame\n")
    next
  }

  col_vec    <- df[[var]]
  na_before  <- sum(is.na(col_vec))
  med_val    <- median(col_vec, na.rm = TRUE)

  # Replace NAs with the column median
  col_vec[is.na(col_vec)] <- med_val
  df[[var]]               <- col_vec

  na_after   <- sum(is.na(df[[var]]))

  cat(sprintf("Variable: %-6s | NAs before: %4d | Median used: %8.3f | NAs after: %d\n",
              var, na_before, med_val, na_after))
}

# =============================================================================
# TASK 6 – calculate_mode() FOR CATEGORICAL VARIABLE
# =============================================================================
# WHY: The 'wd' (wind direction) column is categorical / ordinal; replacing
# missing values with the median of numeric codes would be meaningless.  Mode
# imputation preserves the most commonly observed wind direction, which is the
# ecologically sensible choice for a weather station.
# =============================================================================

banner("TASK 6 – calculate_mode() FOR 'wd' (WIND DIRECTION)")

calculate_mode <- function(x) {
  # Remove NAs before computing frequency table so they don't affect the tally
  x_clean <- x[!is.na(x)]
  if (length(x_clean) == 0) stop("All values are NA – cannot compute mode.")
  freq_table <- table(x_clean)
  # names() returns the value; which.max() finds the position of the maximum
  as.character(names(freq_table)[which.max(freq_table)])
}

na_before_wd <- sum(is.na(df[["wd"]]))
cat("\nNA count in 'wd' BEFORE mode imputation:", na_before_wd, "\n")

mode_wd <- calculate_mode(df[["wd"]])
cat("Mode of 'wd':", mode_wd, "\n")

df[["wd"]][is.na(df[["wd"]])] <- mode_wd

na_after_wd <- sum(is.na(df[["wd"]]))
cat("NA count in 'wd' AFTER  mode imputation:", na_after_wd, "\n")

# =============================================================================
# TASK 7 – clean_variable() WITH ROBUST ERROR HANDLING
# =============================================================================
# WHY: A reusable cleaning function with tryCatch() is more maintainable than
# inline if-else guards sprinkled throughout the script.  Four explicit failure
# modes are demonstrated so the caller always knows WHY cleaning failed, not
# just that it did.
# =============================================================================

banner("TASK 7 – clean_variable() WITH ERROR HANDLING")

clean_variable <- function(dataset, variable_name) {
  # Returns the cleaned numeric vector, or NULL on failure (execution continues)

  tryCatch({

    # Failure mode 1: variable does not exist in the dataset
    if (!variable_name %in% colnames(dataset)) {
      stop(paste("VARIABLE_NOT_FOUND:", variable_name))
    }

    col_vec <- dataset[[variable_name]]

    # Failure mode 2: categorical variable passed (non-numeric)
    if (!is.numeric(col_vec)) {
      stop(paste("CATEGORICAL_VARIABLE:", variable_name, "is not numeric"))
    }

    # Failure mode 3: column is entirely NA
    if (all(is.na(col_vec))) {
      stop(paste("ALL_NA: column", variable_name, "contains only NA values"))
    }

    # Failure mode 4: median cannot be computed (edge case – covered by mode 3,
    # but we guard explicitly in case of all-NaN numeric input)
    med_val <- median(col_vec, na.rm = TRUE)
    if (is.na(med_val) || is.nan(med_val)) {
      stop(paste("MEDIAN_FAILED: could not compute median for", variable_name))
    }

    # Success: impute and return
    col_vec[is.na(col_vec)] <- med_val
    cat(sprintf("  [OK] '%s' cleaned – median %.4f applied.\n", variable_name, med_val))
    return(col_vec)

  }, error = function(e) {
    msg <- conditionMessage(e)
    if (grepl("VARIABLE_NOT_FOUND", msg)) {
      cat(sprintf("  [ERROR] Variable not found: '%s' does not exist in the dataset.\n", variable_name))
    } else if (grepl("CATEGORICAL_VARIABLE", msg)) {
      cat(sprintf("  [ERROR] Categorical variable: '%s' is not numeric – use mode imputation.\n", variable_name))
    } else if (grepl("ALL_NA", msg)) {
      cat(sprintf("  [ERROR] All-NA column: '%s' has no observed values – imputation impossible.\n", variable_name))
    } else if (grepl("MEDIAN_FAILED", msg)) {
      cat(sprintf("  [ERROR] Median computation failed for '%s'.\n", variable_name))
    } else {
      cat(sprintf("  [ERROR] Unexpected error for '%s': %s\n", variable_name, msg))
    }
    return(NULL)  # return NULL so execution always continues past this call
  })
}

# Build a temporary demo dataset with artificial failure cases
demo_df <- df
# Failure case 3: an all-NA numeric column
demo_df[["ALL_NA_COL"]] <- NA_real_
# Failure case 4: a column whose median would be NA (all-NaN numeric)
demo_df[["ALL_NAN_COL"]] <- NaN

cat("\nDemonstrating all four failure cases + one success:\n")

# Case 1 – variable does not exist
clean_variable(demo_df, "NON_EXISTENT_VAR")

# Case 2 – categorical variable
clean_variable(demo_df, "wd")

# Case 3 – column entirely NA
clean_variable(demo_df, "ALL_NA_COL")

# Case 4 – median cannot be computed (NaN column → treated as all-NA after na.rm)
clean_variable(demo_df, "ALL_NAN_COL")

# Success case – a real numeric variable (already imputed; re-run shows 0 NAs)
clean_variable(demo_df, "SO2")

cat("\nAll five cases executed without crashing the script.\n")

# =============================================================================
# TASK 8 – BEFORE / AFTER COMPARISON TABLE
# =============================================================================
# WHY: Comparing raw_data (saved at import) against the cleaned df proves that
# every missing value was actually handled and that no inadvertent data loss
# occurred (row count should be the same).
# =============================================================================

banner("TASK 8 – BEFORE / AFTER COMPARISON TABLE")

all_selected <- c("PM2.5", "PM10", "SO2", "NO2", "TEMP", "WSPM", "wd")

comparison_df <- data.frame(
  Variable        = character(),
  Missing_Before  = integer(),
  Missing_After   = integer(),
  Values_Replaced = integer(),
  stringsAsFactors = FALSE
)

for (v in all_selected) {
  mb <- sum(is.na(raw_data[[v]]))
  ma <- sum(is.na(df[[v]]))
  vr <- mb - ma
  comparison_df <- rbind(comparison_df, data.frame(
    Variable        = v,
    Missing_Before  = mb,
    Missing_After   = ma,
    Values_Replaced = vr,
    stringsAsFactors = FALSE
  ))
}

print(comparison_df)

# Interpretation line
total_before <- sum(comparison_df[["Missing_Before"]])
total_after  <- sum(comparison_df[["Missing_After"]])
cat(sprintf(
  "\nInterpretation: %d missing values existed across the 7 selected variables ",
  total_before
))
if (total_after == 0) {
  cat("and ALL were successfully handled – no NAs remain.\n")
} else {
  cat(sprintf("but %d still remain – review imputation logic.\n", total_after))
}

# =============================================================================
# TASK 9 – GROUPED BAR CHART (before vs after)
# =============================================================================
# WHY: A grouped bar chart (beside=TRUE) allows the viewer to instantly see,
# for each variable, how many values were replaced.  We save to PNG for
# reproducibility and also draw to the screen device so the chart is
# immediately visible during an interactive session.
# =============================================================================

banner("TASK 9 – GROUPED BAR CHART (Missing Values Before vs After)")

before_vals <- comparison_df[["Missing_Before"]]
after_vals  <- comparison_df[["Missing_After"]]
var_labels  <- comparison_df[["Variable"]]

# Matrix: rows = before/after, cols = variables (barplot expects this layout)
bar_matrix <- rbind(Before = before_vals, After = after_vals)
colnames(bar_matrix) <- var_labels

# --- Save to PNG ---
png(
  filename = "output/missing_values_plot.png",
  width    = 900,
  height   = 600,
  res      = 100
)

barplot(
  bar_matrix,
  beside  = TRUE,
  col     = c("#E74C3C", "#2ECC71"),  # red = before, green = after
  main    = "Missing Values Before vs After Imputation\n(Aotizhongxin Station)",
  xlab    = "Variables",
  ylab    = "Number of Missing Values",
  legend.text = rownames(bar_matrix),
  args.legend = list(x = "topright", bty = "n"),
  las     = 1
)

dev.off()
cat("Plot saved to: output/missing_values_plot.png\n")

# --- Draw to screen device as well ---
barplot(
  bar_matrix,
  beside  = TRUE,
  col     = c("#E74C3C", "#2ECC71"),
  main    = "Missing Values Before vs After Imputation\n(Aotizhongxin Station)",
  xlab    = "Variables",
  ylab    = "Number of Missing Values",
  legend.text = rownames(bar_matrix),
  args.legend = list(x = "topright", bty = "n"),
  las     = 1
)

# =============================================================================
# TASK 10 – EXPORT CLEANED DATA & VERIFY
# =============================================================================
# WHY: Writing to CSV (row.names=FALSE) produces a clean file without an extra
# index column.  Reading back and verifying row count + zero NA count gives a
# programmatic assertion that the pipeline completed correctly.
# =============================================================================

banner("TASK 10 – EXPORT CLEANED DATA & VERIFY")

# 'df' now contains the fully imputed data frame – rename for clarity
cleaned <- df

write.csv(cleaned, "output/cleaned_air_quality_data.csv", row.names = FALSE)
cat("Cleaned data written to: output/cleaned_air_quality_data.csv\n")

# --- Read back and verify ---
verified <- read.csv(
  "output/cleaned_air_quality_data.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

cat("\n--- Verification ---\n")
cat("Original rows:", nrow(cleaned), "| Exported rows:", nrow(verified), "\n")

if (nrow(verified) == nrow(cleaned)) {
  cat("Row count matches – no data loss during export.\n")
} else {
  cat("WARNING: row count mismatch!\n")
}

# Check that no NAs remain in the 7 selected variables
na_in_selected <- sapply(all_selected, function(v) sum(is.na(verified[[v]])))
cat("\nNA counts in selected variables after re-import:\n")
print(na_in_selected)

if (all(na_in_selected == 0)) {
  cat("\nVERIFICATION PASSED: No NAs remain in any selected variable.\n")
} else {
  cat("\nVERIFICATION FAILED: Some NAs remain – check imputation.\n")
}

banner("ALL TASKS COMPLETE")
cat("Output files:\n")
cat("  output/cleaned_air_quality_data.csv\n")
cat("  output/missing_values_plot.png\n")
