# =============================================================================
# Assignment 2 – Lab 3: Control Flow & Blood-Pressure Data Cleaning
# Subject  : R Programming (ODD 2026-27)
# Student  : Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C
# Dataset  : UCI Heart Disease – Cleveland Processed
#            https://archive.ics.uci.edu/ml/machine-learning-databases/
#                    heart-disease/processed.cleveland.data
# Variable : trestbps (resting blood pressure, mm Hg)
# =============================================================================
# Run from the lab3-heart-disease/ directory:
#   Rscript lab3_bp_cleaning.R
# All output is written to ./output/. No manual file placement needed.
# =============================================================================

# ---- Packages ---------------------------------------------------------------
# microbenchmark is the only external package needed in this script.
if (!requireNamespace("microbenchmark", quietly = TRUE)) {
  install.packages("microbenchmark", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2", repos = "https://cloud.r-project.org")
}
library(microbenchmark)
library(ggplot2)

# ---- Utility ----------------------------------------------------------------
banner <- function(title) {
  line <- paste(rep("=", 70), collapse = "")
  cat("\n", line, "\n", title, "\n", line, "\n", sep = "")
}

# Ensure output and data directories exist
if (!dir.exists("data")) dir.create("data")
if (!dir.exists("output")) dir.create("output")

# =============================================================================
# TASK 1 – IMPORT & VERIFY
# =============================================================================
banner("TASK 1 – IMPORT & VERIFY")

col_names <- c("age", "sex", "cp", "trestbps", "chol", "fbs",
               "restecg", "thalach", "exang", "oldpeak", "slope",
               "ca", "thal", "num")

data_url  <- paste0(
  "https://archive.ics.uci.edu/ml/machine-learning-databases/",
  "heart-disease/processed.cleveland.data"
)
data_path <- "data/processed.cleveland.data"

# Download only if the file is not already present
if (!file.exists(data_path)) {
  cat("Downloading Cleveland Heart Disease data...\n")
  tryCatch(
    download.file(data_url, destfile = data_path, mode = "wb", quiet = FALSE),
    error = function(e) stop("Download failed: ", conditionMessage(e))
  )
  cat("Download complete.\n")
} else {
  cat("Data file already present – skipping download.\n")
}

# Read the data; "?" encodes missing values
heart <- tryCatch(
  read.csv(data_path, header = FALSE, col.names = col_names,
           na.strings = "?", stringsAsFactors = FALSE),
  error = function(e) stop("Could not read data file: ", conditionMessage(e))
)

# Verify dimensions
expected_rows <- 303L
expected_cols <- 14L
if (nrow(heart) != expected_rows || ncol(heart) != expected_cols) {
  stop(sprintf(
    "Dimension mismatch: expected %d x %d, got %d x %d.",
    expected_rows, expected_cols, nrow(heart), ncol(heart)
  ))
}
cat(sprintf("Dimensions OK: %d rows x %d columns\n", nrow(heart), ncol(heart)))
cat("Column names:", paste(names(heart), collapse = ", "), "\n")
cat("First 6 rows:\n")
print(head(heart))
cat("\nNAs in trestbps (original):", sum(is.na(heart$trestbps)), "\n")

# =============================================================================
# TASK 2 – INJECT SIMULATED DATA-ENTRY ERRORS
# =============================================================================
banner("TASK 2 – INJECT SIMULATED DATA-ENTRY ERRORS")

# Work on a copy so the original data frame stays pristine
set.seed(42)
bp_dirty <- heart$trestbps          # numeric vector, 303 elements

# Choose injection indices (sampling from rows where trestbps is not already NA)
valid_idx <- which(!is.na(bp_dirty))

# Negative values (data-entry sign flip)
neg_idx <- sample(valid_idx, 5)
bp_dirty[neg_idx] <- c(-120, -85, -95, -110, -70)

# Refresh valid pool (exclude already touched indices)
available <- setdiff(valid_idx, neg_idx)

# NA injections (sensor dropout)
na_idx <- sample(available, 4)
bp_dirty[na_idx] <- NA
available <- setdiff(available, na_idx)

# Above-300 injections (fat-finger entry, e.g. 1300 typed as 1300)
high_idx <- sample(available, 4)
bp_dirty[high_idx] <- c(320, 350, 310, 380)

cat("Injection summary:\n")
cat("  Negative values at rows:", neg_idx,
    "-> values:", c(-120, -85, -95, -110, -70), "\n")
cat("  NA injections at rows   :", na_idx, "\n")
cat("  Above-300 at rows       :", high_idx,
    "-> values:", c(320, 350, 310, 380), "\n")
cat("\nDirty trestbps summary:\n")
print(summary(bp_dirty))
cat("Total NAs in dirty vector:", sum(is.na(bp_dirty)), "\n")

# =============================================================================
# TASK 3 – BP-CLEANING FUNCTION (if-else)
# =============================================================================
banner("TASK 3 – CLEAN_BP() FUNCTION USING IF-ELSE")

# clean_bp applies three rules element-wise:
#   Rule 1: negative value  -> NA      (physiologically impossible)
#   Rule 2: value > 250     -> 250     (cap at clinical ceiling; note: injection
#                                       threshold was >300, cap threshold is 250)
#   Rule 3: otherwise       -> unchanged
clean_bp <- function(x) {
  # x: numeric vector of blood-pressure readings (may contain NA)
  result <- numeric(length(x))
  for (i in seq_along(x)) {
    if (is.na(x[i])) {
      result[i] <- NA                  # propagate existing NAs untouched
    } else if (x[i] < 0) {
      result[i] <- NA                  # Rule 1: negative -> NA
    } else if (x[i] > 250) {
      result[i] <- 250                 # Rule 2: cap at 250
    } else {
      result[i] <- x[i]               # Rule 3: valid, keep as-is
    }
  }
  return(result)
}

bp_clean <- clean_bp(bp_dirty)

cat("After clean_bp():\n")
cat("  NAs (including converted negatives):", sum(is.na(bp_clean)), "\n")
cat("  Max value (should be <= 250)       :", max(bp_clean, na.rm = TRUE), "\n")
cat("  Min value (should be >= 0 or NA)   :",
    ifelse(all(is.na(bp_clean)), NA, min(bp_clean, na.rm = TRUE)), "\n")

# =============================================================================
# TASK 4 – tryCatch() ERROR HANDLING
# =============================================================================
banner("TASK 4 – tryCatch() ERROR HANDLING")

# --- 4a. Safe mean with NAs present ------------------------------------------
cat("\n--- 4a. Safe mean of bp_dirty (contains NAs) ---\n")
safe_mean_bp <- tryCatch(
  {
    val <- mean(bp_dirty, na.rm = TRUE)
    cat("Mean BP (na.rm = TRUE):", round(val, 2), "mmHg\n")
    val
  },
  error   = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NA },
  warning = function(w) { cat("WARNING:", conditionMessage(w), "\n"); NA }
)

# Force the error branch: pass a non-numeric object
cat("\nForcing error branch – passing a character string to mean():\n")
tryCatch(
  {
    val <- mean("not_a_number")
    cat("Mean:", val, "\n")
  },
  warning = function(w) {
    cat("Caught warning (NAs introduced by coercion):", conditionMessage(w), "\n")
  },
  error = function(e) {
    cat("Caught error:", conditionMessage(e), "\n")
  }
)

# --- 4b. Safe chol / trestbps ratio ------------------------------------------
cat("\n--- 4b. Safe ratio: chol / trestbps ---\n")

safe_ratio <- function(numerator, denominator) {
  tryCatch(
    {
      # Guard 1: non-numeric denominator
      if (!is.numeric(denominator)) {
        warning("Denominator is not numeric. Returning NA.")
        return(NA_real_)
      }
      # Guard 2: NA denominator
      if (is.na(denominator)) {
        message("Denominator is NA. Returning NA.")
        return(NA_real_)
      }
      # Guard 3: zero denominator
      if (denominator == 0) {
        warning("Denominator is zero – division undefined. Returning NA.")
        return(NA_real_)
      }
      numerator / denominator
    },
    warning = function(w) {
      cat("  [safe_ratio WARNING]", conditionMessage(w), "\n")
      NA_real_
    },
    error = function(e) {
      cat("  [safe_ratio ERROR]", conditionMessage(e), "\n")
      NA_real_
    }
  )
}

# Normal case
cat("Normal case  chol=200, trestbps=130 ->",
    safe_ratio(200, 130), "\n")

# Branch 1: zero denominator
cat("Zero denom   chol=200, trestbps=0   ->",
    safe_ratio(200, 0), "\n")

# Branch 2: NA denominator
cat("NA denom     chol=200, trestbps=NA  ->",
    safe_ratio(200, NA), "\n")

# Branch 3: non-numeric denominator
cat("Non-numeric  chol=200, trestbps='x' ->",
    safe_ratio(200, "x"), "\n")

# Apply across the full dataset (using cleaned BP to keep ratios sensible)
heart_ratios <- mapply(safe_ratio,
                       as.numeric(heart$chol),
                       bp_clean)
cat("\nRatio summary across 303 rows:\n")
print(summary(heart_ratios))

# =============================================================================
# TASK 5 – LOOP vs VECTORIZED BENCHMARK
# =============================================================================
banner("TASK 5 – LOOP vs VECTORIZED BENCHMARK")

# Detection function: flag indices where a reading is invalid
#   (negative OR above 250, ignoring NAs)

# --- Loop implementation ---
detect_invalid_loop <- function(x) {
  invalid <- logical(length(x))
  for (i in seq_along(x)) {
    if (!is.na(x[i]) && (x[i] < 0 || x[i] > 250)) {
      invalid[i] <- TRUE
    }
  }
  invalid
}

# --- Vectorized implementation ---
detect_invalid_vec <- function(x) {
  !is.na(x) & (x < 0 | x > 250)
}

# Verify both give identical results on dirty vector
stopifnot(identical(detect_invalid_loop(bp_dirty), detect_invalid_vec(bp_dirty)))
cat("Both implementations produce identical output: TRUE\n")

# ----- Benchmark 1: 303-element vector ----------------------------------------
cat("\n--- Benchmark on 303-element vector (bp_dirty) ---\n")
t_loop_small <- system.time(for (r in 1:1000) detect_invalid_loop(bp_dirty))
t_vec_small  <- system.time(for (r in 1:1000) detect_invalid_vec(bp_dirty))
cat("system.time (1000 reps, loop)      :", t_loop_small["elapsed"], "sec\n")
cat("system.time (1000 reps, vectorized):", t_vec_small["elapsed"],  "sec\n")

mb_small <- microbenchmark(
  loop       = detect_invalid_loop(bp_dirty),
  vectorized = detect_invalid_vec(bp_dirty),
  times = 500L
)
cat("\nmicrobenchmark on 303-element vector:\n")
print(mb_small)

# ----- Benchmark 2: ~1 000 000-element vector ---------------------------------
cat("\n--- Benchmark on ~1e6-element vector ---\n")
set.seed(99)
bp_large <- rep(bp_dirty, length.out = 1e6)
# Sprinkle some out-of-range values so detection is non-trivial
bp_large[sample(1e6, 5000)] <- -50
bp_large[sample(1e6, 5000)] <- 320

t_loop_large <- system.time(detect_invalid_loop(bp_large))
t_vec_large  <- system.time(detect_invalid_vec(bp_large))
cat("system.time loop (1e6)      :", t_loop_large["elapsed"], "sec\n")
cat("system.time vec  (1e6)      :", t_vec_large["elapsed"],  "sec\n")

mb_large <- microbenchmark(
  loop       = detect_invalid_loop(bp_large),
  vectorized = detect_invalid_vec(bp_large),
  times = 20L
)
cat("\nmicrobenchmark on 1e6-element vector:\n")
print(mb_large)

# Speedup factor (median times)
loop_med <- summary(mb_large)$median[summary(mb_large)$expr == "loop"]
vec_med  <- summary(mb_large)$median[summary(mb_large)$expr == "vectorized"]
speedup  <- loop_med / vec_med
cat(sprintf("\nSpeedup factor (1e6 vector, loop median / vec median): %.1fx\n",
            speedup))

# Save benchmark boxplot
png("output/benchmark_comparison.png", width = 800, height = 500)
boxplot(mb_large,
        main = "Loop vs Vectorized – Invalid BP Detection (1e6 elements)",
        ylab = "Time (microseconds)",
        col  = c("#E57373", "#64B5F6"),
        names = c("for-loop", "vectorized"))
dev.off()
cat("Benchmark plot saved to output/benchmark_comparison.png\n")

# =============================================================================
# TASK 6 – VALIDATE CLEANED VECTOR
# =============================================================================
banner("TASK 6 – VALIDATE CLEANED VECTOR")

cat("Remaining NAs       :", sum(is.na(bp_clean)), "\n")
cat("Min (excl. NA)      :", min(bp_clean,    na.rm = TRUE), "\n")
cat("Max (excl. NA)      :", max(bp_clean,    na.rm = TRUE), "\n")
cat("Mean (excl. NA)     :", round(mean(bp_clean,   na.rm = TRUE), 2), "\n")
cat("Median (excl. NA)   :", median(bp_clean, na.rm = TRUE), "\n")

# Programmatic assertions
if (any(bp_clean < 0, na.rm = TRUE)) {
  stop("ASSERTION FAILED: negative BP values still present.")
} else {
  cat("Assertion PASSED: no negative BP values.\n")
}
if (any(bp_clean > 250, na.rm = TRUE)) {
  stop("ASSERTION FAILED: BP values above 250 still present.")
} else {
  cat("Assertion PASSED: no BP values above 250.\n")
}

# Distribution plot of cleaned BP
png("output/bp_distribution.png", width = 800, height = 500)
hist(bp_clean,
     breaks = 20,
     main   = "Distribution of Cleaned Resting Blood Pressure",
     xlab   = "trestbps (mmHg)",
     col    = "#64B5F6",
     border = "white")
abline(v = mean(bp_clean, na.rm = TRUE),   col = "#E53935", lwd = 2, lty = 2)
abline(v = median(bp_clean, na.rm = TRUE), col = "#43A047", lwd = 2, lty = 3)
legend("topright",
       legend = c("Mean", "Median"),
       col    = c("#E53935", "#43A047"),
       lwd    = 2, lty = c(2, 3))
dev.off()
cat("BP distribution plot saved to output/bp_distribution.png\n")

# Before vs after comparison plot
png("output/bp_before_after.png", width = 900, height = 500)
par(mfrow = c(1, 2))
hist(bp_dirty,
     breaks = 20, main = "Dirty BP",
     xlab = "trestbps (mmHg)", col = "#EF9A9A", border = "white")
hist(bp_clean,
     breaks = 20, main = "Cleaned BP",
     xlab = "trestbps (mmHg)", col = "#80CBC4", border = "white")
par(mfrow = c(1, 1))
dev.off()
cat("Before/after plot saved to output/bp_before_after.png\n")

# =============================================================================
# TASK 7 – EXPORT & VERIFY
# =============================================================================
banner("TASK 7 – EXPORT & VERIFY")

# Attach cleaned BP back into the heart data frame
heart_clean <- heart
heart_clean$trestbps <- bp_clean

output_path <- "output/cleaned_heart_data.csv"
write.csv(heart_clean, output_path, row.names = FALSE)
cat("Exported:", output_path, "\n")

# Read back and verify
heart_reread <- read.csv(output_path, stringsAsFactors = FALSE)
cat("Re-read dimensions:", nrow(heart_reread), "rows x",
    ncol(heart_reread), "cols\n")
stopifnot(nrow(heart_reread) == nrow(heart_clean))
stopifnot(ncol(heart_reread) == ncol(heart_clean))
cat("Column names match:", identical(names(heart_reread), names(heart_clean)), "\n")
cat("NAs in trestbps (reread):", sum(is.na(heart_reread$trestbps)), "\n")
if (any(heart_reread$trestbps < 0, na.rm = TRUE)) {
  stop("EXPORT VERIFY FAILED: negative values found after re-read.")
}
if (any(heart_reread$trestbps > 250, na.rm = TRUE)) {
  stop("EXPORT VERIFY FAILED: values > 250 found after re-read.")
}
cat("Export verification PASSED.\n")

banner("ALL TASKS COMPLETE")
cat("Output files in ./output/:\n")
cat(paste(" -", list.files("output"), collapse = "\n"), "\n")
