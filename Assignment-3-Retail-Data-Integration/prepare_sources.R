# prepare_sources.R
# This script downloads the UCI Online Retail dataset and prepares the three raw source files.

# Ensure required packages are installed
required_packages <- c("readxl", "writexl", "jsonlite", "dplyr")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages) > 0) {
  install.packages(new_packages, repos = "https://cloud.r-project.org")
}

library(readxl)
library(writexl)
library(jsonlite)
library(dplyr)

# Create data/ directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

raw_path <- "data/Online Retail.xlsx"
url <- "https://archive.ics.uci.edu/ml/machine-learning-databases/00352/Online%20Retail.xlsx"

# Download the file if it is absent
if (!file.exists(raw_path)) {
  cat("Downloading Online Retail dataset from UCI...\n")
  tryCatch({
    download.file(url, raw_path, mode = "wb")
  }, error = function(e) {
    cat("Primary URL failed. Trying backup URL...\n")
    # Try alternative UCI URL if primary fails
    alt_url <- "https://web.archive.org/web/20231128032742/https://archive.ics.uci.edu/ml/machine-learning-databases/00352/Online%20Retail.xlsx"
    download.file(alt_url, raw_path, mode = "wb")
  })
} else {
  cat("Raw dataset already exists at:", raw_path, "\n")
}

# Verify file exists
if (!file.exists(raw_path)) {
  stop("Failed to download raw Online Retail Excel file.")
}

# Load the dataset
cat("Loading Excel file...\n")
df <- read_excel(raw_path)

# Verify row count
expected_rows <- 541909
actual_rows <- nrow(df)
cat("Raw row count:", actual_rows, "\n")
if (actual_rows != expected_rows) {
  stop(paste("Row count verification failed! Expected:", expected_rows, "but got:", actual_rows))
} else {
  cat("Row count verified successfully.\n")
}

# --- STEP 0: PROCESS AND SPLIT SOURCES ---

# Helper function to find the mode (most frequent value)
get_mode <- function(x) {
  x <- x[!is.na(x) & x != ""]
  if (length(x) == 0) return(NA_character_)
  tbl <- table(x)
  modes <- names(tbl)[tbl == max(tbl)]
  sort(modes)[1] # deterministic tie-breaker (alphabetical)
}

# 1. data/transactions.csv
# Columns: InvoiceNo, StockCode, CustomerID, Quantity, InvoiceDate
cat("Creating transactions.csv...\n")
transactions <- df %>%
  select(InvoiceNo, StockCode, CustomerID, Quantity, InvoiceDate)

write.csv(transactions, "data/transactions.csv", row.names = FALSE)

# 2. data/products.json
# Columns: StockCode, Description, UnitPrice (one row per StockCode)
# Collapsing rules:
#   - For UnitPrice, we use the median value per StockCode.
#   - For Description, we use the modal (most frequent) Description per StockCode.
cat("Collapsing products...\n")

product_diagnostics <- df %>%
  group_by(StockCode) %>%
  summarise(
    distinct_prices = n_distinct(UnitPrice, na.rm = TRUE),
    distinct_descriptions = n_distinct(Description, na.rm = TRUE)
  )

multi_price_count <- sum(product_diagnostics$distinct_prices > 1)
multi_desc_count <- sum(product_diagnostics$distinct_descriptions > 1)

cat("Number of StockCodes with >1 distinct price:", multi_price_count, "\n")
cat("Number of StockCodes with >1 distinct description:", multi_desc_count, "\n")

# State the rule: Collapsing is done by grouping by StockCode, then taking the median UnitPrice
# and the modal Description. If multiple descriptions have the same frequency, we choose the first alphabetically.
products <- df %>%
  group_by(StockCode) %>%
  summarise(
    Description = get_mode(Description),
    UnitPrice = median(UnitPrice, na.rm = TRUE),
    .groups = "drop"
  )

jsonlite::write_json(products, "data/products.json", pretty = TRUE)

# 3. data/customers.xlsx
# Columns: CustomerID, Country (one row per CustomerID)
# Filter out NA CustomerID first since it cannot represent a specific customer.
# Collapsing rule: Use the modal Country per CustomerID.
cat("Collapsing customers...\n")

customer_diagnostics <- df %>%
  filter(!is.na(CustomerID)) %>%
  group_by(CustomerID) %>%
  summarise(
    distinct_countries = n_distinct(Country, na.rm = TRUE)
  )

multi_country_count <- sum(customer_diagnostics$distinct_countries > 1)
cat("Number of CustomerIDs with >1 distinct country:", multi_country_count, "\n")

customers <- df %>%
  filter(!is.na(CustomerID)) %>%
  group_by(CustomerID) %>%
  summarise(
    Country = get_mode(Country),
    .groups = "drop"
  )

writexl::write_xlsx(customers, "data/customers.xlsx")

# Print the dimensions of all three generated files
cat("\n--- GENERATED FILE DIMENSIONS ---\n")
cat("transactions.csv :", nrow(transactions), "rows x", ncol(transactions), "columns\n")
cat("products.json    :", nrow(products), "rows x", ncol(products), "columns\n")
cat("customers.xlsx   :", nrow(customers), "rows x", ncol(customers), "columns\n")
