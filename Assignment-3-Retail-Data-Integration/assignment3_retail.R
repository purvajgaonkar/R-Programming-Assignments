# assignment3_retail.R
# Main analysis script for Assignment 3: Retail Data Integration and Analysis.

# 1. SETUP & LIBRARIES
cat("=== SETUP & LIBRARIES ===\n")
required_packages <- c("readr", "readxl", "writexl", "jsonlite", "dplyr", "ggplot2", "DBI", "RSQLite")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages) > 0) {
  install.packages(new_packages, repos = "https://cloud.r-project.org")
}

library(readr)
library(readxl)
library(writexl)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(DBI)
library(RSQLite)

# Create output/ directory if it doesn't exist
if (!dir.exists("output")) {
  dir.create("output")
}

# 2. TASK 1: IMPORT AND CLEAN
cat("\n=== TASK 1: IMPORT AND CLEAN ===\n")

# Import all three formats
cat("Importing datasets...\n")
transactions_raw <- read_csv("data/transactions.csv", show_col_types = FALSE)
products_raw <- jsonlite::fromJSON("data/products.json")
customers_raw <- read_excel("data/customers.xlsx")

cat("Raw dimensions:\n")
cat("- Transactions:", nrow(transactions_raw), "rows,", ncol(transactions_raw), "columns\n")
cat("- Products:", nrow(products_raw), "rows,", ncol(products_raw), "columns\n")
cat("- Customers:", nrow(customers_raw), "rows,", ncol(customers_raw), "columns\n")

# Data Cleaning
cleaning_log <- data.frame(
  Table = character(),
  Step = character(),
  Before_Rows = integer(),
  After_Rows = integer(),
  Removed = integer(),
  stringsAsFactors = FALSE
)

log_step <- function(table_name, step_desc, before_df, after_df) {
  bef <- nrow(before_df)
  aft <- nrow(after_df)
  rem <- bef - aft
  cleaning_log <<- rbind(cleaning_log, data.frame(
    Table = table_name,
    Step = step_desc,
    Before_Rows = bef,
    After_Rows = aft,
    Removed = rem,
    stringsAsFactors = FALSE
  ))
}

# Clean Transactions
cat("\nCleaning transactions...\n")
# Step 1: Duplicate records
transactions_step1 <- distinct(transactions_raw)
log_step("Transactions", "Remove Duplicates", transactions_raw, transactions_step1)

# Step 2: Quantity filtering.
# Cancellations carry a negative Quantity and an InvoiceNo starting with "C". They are
# legitimate business events (returns) and are RETAINED so that total revenue is net of returns.
# The 1,336 rows with negative Quantity but no leading "C" are data errors with no matching
# invoice type; those are removed.
transactions_step2 <- transactions_step1 %>%
  filter(Quantity > 0 | (Quantity < 0 & grepl("^C", InvoiceNo)))
log_step("Transactions", "Remove Invalid Negatives (non-cancellation)", transactions_step1, transactions_step2)

# Report cancellations retained
cancellation_rows <- transactions_step2 %>% filter(grepl("^C", InvoiceNo) & Quantity < 0)
cat("Cancellation rows retained:", nrow(cancellation_rows), "\n")
cat("  (Cancellation revenue will be reported after join, once UnitPrice is available.)\n")

# Step 3: Handle missing CustomerID
# Roughly 25% of CustomerIDs are missing (NA).
# We decide to RETAIN these rows because they represent valid transactions and sales volume.
# Dropping them would severely underestimate total sales revenue.
# We keep CustomerID as NA and log it.
transactions_cleaned <- transactions_step2
log_step("Transactions", "Retain NA CustomerID", transactions_step2, transactions_cleaned)

# Clean Products
cat("\nCleaning products...\n")
# Step 1: Duplicate records (should be 0 since collapsed in step 0)
products_step1 <- distinct(products_raw)
log_step("Products", "Remove Duplicates", products_raw, products_step1)

# Step 2: Invalid or zero unit prices
products_cleaned <- products_step1 %>%
  filter(UnitPrice > 0)
log_step("Products", "Filter Zero/Negative Prices", products_step1, products_cleaned)

# Clean Customers
cat("\nCleaning customers...\n")
# Step 1: Duplicate records
customers_step1 <- distinct(customers_raw)
log_step("Customers", "Remove Duplicates", customers_raw, customers_step1)

customers_cleaned <- customers_step1
log_step("Customers", "No-op (Already clean)", customers_step1, customers_cleaned)

# Print cleaning table
cat("\n--- CLEANING LOG TABLE ---\n")
print(cleaning_log)

# 3. TASK 2: INTEGRATE
cat("\n=== TASK 2: INTEGRATE ===\n")

# Join choice and justification:
# We use left_join starting with transactions as the primary table.
# - left_join with products keeps all transactions. If any transaction references a StockCode
#   that was removed from the products catalog (e.g. price <= 0), it will result in NA UnitPrice.
# - left_join with customers keeps all transactions, including those with NA CustomerIDs.
# - Using inner_join would automatically drop transactions with missing CustomerID (~25% of rows)
#   and unmatched products, severely distorting the sales metrics.

cat("Performing left_join...\n")
joined_step1 <- transactions_cleaned %>%
  left_join(products_cleaned, by = "StockCode")

log_step("Joined Dataset", "Join Transactions + Products", transactions_cleaned, joined_step1)

joined_final <- joined_step1 %>%
  left_join(customers_cleaned, by = "CustomerID")

log_step("Joined Dataset", "Join Customers", joined_step1, joined_final)

cat("Final integrated dataset dimensions:", nrow(joined_final), "rows x", ncol(joined_final), "columns\n")

# Count and characterise unmatched records on each side
# 1. Transactions referencing StockCodes with no product record
unmatched_products <- joined_final %>%
  filter(is.na(UnitPrice))

cat("\nUnmatched products in joined dataset (StockCodes missing from products catalog):\n")
cat("- Number of unmatched transactions:", nrow(unmatched_products), "\n")
cat("- Unique StockCodes unmatched:", length(unique(unmatched_products$StockCode)), "\n")

# 2. Transactions referencing CustomerIDs with no customer record
unmatched_customers <- joined_final %>%
  filter(is.na(Country) & !is.na(CustomerID))

cat("Unmatched customers in joined dataset (CustomerIDs missing from customers directory):\n")
cat("- Number of unmatched transactions with non-NA CustomerID:", nrow(unmatched_customers), "\n")
cat("- Unique CustomerIDs unmatched:", length(unique(unmatched_customers$CustomerID)), "\n")

# 3. Transactions where CustomerID itself is NA
na_customer_transactions <- joined_final %>%
  filter(is.na(CustomerID))
cat("Transactions with missing CustomerID (expected to not match customers):", nrow(na_customer_transactions), "\n")

# Key cardinality check
# The number of rows in joined_final must match transactions_cleaned exactly
# because products has a unique key StockCode and customers has a unique key CustomerID.
cat("\nKey Cardinality Verification:\n")
cat("- Row count of cleaned transactions:", nrow(transactions_cleaned), "\n")
cat("- Row count of integrated dataset:", nrow(joined_final), "\n")
if (nrow(transactions_cleaned) == nrow(joined_final)) {
  cat("Verification SUCCESS: No row duplication occurred during the join.\n")
} else {
  warning("Verification FAILURE: Row count mismatch before/after join!")
}

# Create Revenue = Quantity * UnitPrice
# NOTE: UnitPrice lives in products.json, so this column was only added after joining.
# We compute it here. Any transaction with unmatched products will have NA revenue.
# We will filter out rows with NA UnitPrice/Revenue for sales analysis, as we cannot
# calculate revenue without a price.
cat("\nComputing Revenue (Quantity * UnitPrice)...\n")
joined_final <- joined_final %>%
  mutate(Revenue = Quantity * UnitPrice)

# Filter out transactions with NA revenue (which are those that had no product match)
# since we cannot conduct revenue analysis without prices.
analysis_data <- joined_final %>%
  filter(!is.na(Revenue))

cat("Rows with valid Revenue for analysis:", nrow(analysis_data), "\n")
cat("Rows dropped due to missing price/unmatched product:", nrow(joined_final) - nrow(analysis_data), "\n")

# Deferred cancellation revenue report (UnitPrice now available from join)
canc_revenue <- joined_final %>%
  filter(grepl("^C", InvoiceNo) & Quantity < 0 & !is.na(Revenue)) %>%
  summarise(n = n(), total_neg_revenue = sum(Revenue))
cat("Cancellation (return) total negative revenue: $",
    format(round(canc_revenue$total_neg_revenue, 2), big.mark = ","),
    "across", canc_revenue$n, "rows.\n")
cat("Total revenue above is net of these returns.\n")

# 4. TASK 3: SALES AND CUSTOMER ANALYSIS
cat("\n=== TASK 3: SALES AND CUSTOMER ANALYSIS ===\n")

# 1. Total sales revenue
total_revenue <- sum(analysis_data$Revenue)
cat("1. Total Sales Revenue: $", format(total_revenue, big.mark = ","), "\n")

# 2. Top 5 products by revenue
top_products <- analysis_data %>%
  group_by(StockCode, Description) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop") %>%
  arrange(desc(Revenue)) %>%
  slice(1:5)

cat("\n2. Top 5 Products by Revenue:\n")
print(top_products)

# 3. Top 5 countries by revenue
# Transactions with no CustomerID carry Country = NA after the left join.
# This NA group is not a real geography; it represents 133,595 guest transactions.
# We exclude NA Country from all country-level analysis.
na_country_revenue <- sum(analysis_data$Revenue[is.na(analysis_data$Country)])
na_country_rows    <- sum(is.na(analysis_data$Country))
cat("Revenue set aside from NA-Country rows: $", format(round(na_country_revenue, 2), big.mark = ","),
    "across", na_country_rows, "transactions (these are guest transactions with no CustomerID).\n")

country_data <- analysis_data %>% filter(!is.na(Country))

top_countries <- country_data %>%
  group_by(Country) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop") %>%
  arrange(desc(Revenue)) %>%
  slice(1:5)

cat("\n3. Top 5 Countries by Revenue (excluding NA-Country guest transactions):\n")
print(top_countries)

# 4. Top 5 customers by total purchase value (exclude NA CustomerID)
top_customers <- analysis_data %>%
  filter(!is.na(CustomerID)) %>%
  group_by(CustomerID) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop") %>%
  arrange(desc(Revenue)) %>%
  slice(1:5)

cat("\n4. Top 5 Customers by Revenue:\n")
print(top_customers)

# Customer Value Segmentation
cat("\nClassifying customers into value bands...\n")
customer_spend <- analysis_data %>%
  filter(!is.na(CustomerID)) %>%
  group_by(CustomerID) %>%
  summarise(TotalSpend = sum(Revenue), .groups = "drop")

# Calculate percentiles for spend thresholds
thresholds <- quantile(customer_spend$TotalSpend, probs = c(0.50, 0.75, 0.95))
low_thresh <- thresholds[1]
med_thresh <- thresholds[2]
high_thresh <- thresholds[3]

cat("Spend Thresholds (derived from distribution):\n")
cat("- Low to Medium (50th percentile): $", round(low_thresh, 2), "\n")
cat("- Medium to High (75th percentile): $", round(med_thresh, 2), "\n")
cat("- High to Premium (95th percentile): $", round(high_thresh, 2), "\n")

customer_spend <- customer_spend %>%
  mutate(Segment = case_when(
    TotalSpend <= low_thresh ~ "Low Value",
    TotalSpend > low_thresh & TotalSpend <= med_thresh ~ "Medium Value",
    TotalSpend > med_thresh & TotalSpend <= high_thresh ~ "High Value",
    TotalSpend > high_thresh ~ "Premium"
  ))

segment_summary <- customer_spend %>%
  group_by(Segment) %>%
  summarise(
    Customer_Count = n(),
    Total_Spend = sum(TotalSpend),
    Average_Spend = mean(TotalSpend),
    .groups = "drop"
  ) %>%
  mutate(Segment = factor(Segment, levels = c("Low Value", "Medium Value", "High Value", "Premium"))) %>%
  arrange(Segment)

cat("\nCustomer Segments Count and Summary:\n")
print(segment_summary)

# Market Analysis: UK vs Others
# NA Country rows are excluded here too, for the same reason stated above.
cat("\nMarket Analysis (UK vs Others):\n")
country_metrics <- country_data %>%
  group_by(Country) %>%
  summarise(
    TotalRevenue = sum(Revenue),
    TotalTransactions = n_distinct(InvoiceNo),
    TotalCustomers = n_distinct(CustomerID, na.rm = TRUE),
    RevenuePerCustomer = if_else(TotalCustomers > 0, TotalRevenue / TotalCustomers, NA_real_),
    RevenuePerTransaction = TotalRevenue / TotalTransactions,
    .groups = "drop"
  ) %>%
  arrange(desc(TotalRevenue))

cat("\nDetailed Country Metrics (Top 10):\n")
print(head(country_metrics, 10))

# United Kingdom dominates by raw volume. A fair comparison needs per-customer efficiency.
# High-performing market: EIRE (revenue per customer $92,083 from only 3 customers, indicating
# highly concentrated bulk purchasing). Netherlands also strong at $36,788 per customer.
# Underperforming market: Saudi Arabia ($134 total, $134 per customer, 2 transactions).
netherlands_stats <- country_metrics %>% filter(Country == "Netherlands")
eire_stats        <- country_metrics %>% filter(Country == "EIRE")
saudi_stats       <- country_metrics %>% filter(Country == "Saudi Arabia")

cat("\nSelected Market Comparisons:\n")
cat("- EIRE (High-performing per customer):\n")
print(eire_stats)
cat("- Netherlands (High-performing per customer):\n")
print(netherlands_stats)
cat("- Saudi Arabia (Underperforming):\n")
print(saudi_stats)

# PLOTS GENERATION
cat("\nGenerating plots...\n")

# Use a theme helper to avoid Rplots.pdf
pdf(NULL)

# Plot 1: Top 5 Products by Revenue
p1 <- ggplot(top_products, aes(x = reorder(Description, Revenue), y = Revenue, fill = Revenue)) +
  geom_bar(stat = "identity", width = 0.6) +
  coord_flip() +
  scale_y_continuous(labels = scales::dollar_format()) +
  scale_fill_gradient(low = "#5c7cfa", high = "#1a365d") +
  theme_minimal(base_family = "sans") +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1a202c"),
    plot.subtitle = element_text(size = 10, color = "#4a5568", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#2d3748"),
    axis.text = element_text(size = 9, color = "#4a5568"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  ) +
  labs(
    title = "Top 5 Products by Sales Revenue",
    subtitle = "Online Retail Data Analysis",
    x = "Product Description",
    y = "Total Revenue"
  )

ggsave("output/plot1_top_products.png", plot = p1, width = 8, height = 4.5, dpi = 300)

# Plot 2: Customer Value Segments Count
p2 <- ggplot(segment_summary, aes(x = Segment, y = Customer_Count, fill = Segment)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = format(Customer_Count, big.mark = ",")), vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Low Value" = "#cbd5e0", "Medium Value" = "#a3b18a", "High Value" = "#457b9d", "Premium" = "#1d3557")) +
  theme_minimal(base_family = "sans") +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1a202c"),
    plot.subtitle = element_text(size = 10, color = "#4a5568", margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold", color = "#2d3748"),
    axis.text = element_text(size = 10, color = "#4a5568"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  ) +
  labs(
    title = "Distribution of Customers Across Value Segments",
    subtitle = "Segmentation thresholds derived from total spend distribution percentiles",
    x = "Customer Segment",
    y = "Number of Customers"
  )

ggsave("output/plot2_customer_segments.png", plot = p2, width = 8, height = 4.5, dpi = 300)
cat("Plots successfully saved to output/ directory.\n")

# 5. TASK 4: SQLITE
cat("\n=== TASK 4: SQLITE ===\n")

db_path <- "output/retail_sales.db"

# Remove existing database file if it exists
if (file.exists(db_path)) {
  file.remove(db_path)
}

con <- dbConnect(SQLite(), db_path)

# Write a slimmed dataset: only the columns needed by the two SQL queries plus
# those useful for future analysis (StockCode, Description, Country, Revenue).
# Omitting InvoiceDate (stored as long string) and raw text fields cuts file size significantly.
cat("Writing retail_sales table to SQLite (slimmed columns)...\n")
sqlite_data <- joined_final %>%
  select(InvoiceNo, StockCode, Description, CustomerID, Country,
         Quantity, UnitPrice, Revenue) %>%
  filter(!is.na(UnitPrice))   # rows with no price have no Revenue; not useful in SQL

dbWriteTable(con, "retail_sales", sqlite_data, overwrite = TRUE)

# Execute SQL Queries
cat("\nExecuting SQL Query 1: Top 5 Customers by Revenue...\n")
sql_customers <- dbGetQuery(con, "
  SELECT CustomerID, SUM(Revenue) as Revenue
  FROM retail_sales
  WHERE CustomerID IS NOT NULL
  GROUP BY CustomerID
  ORDER BY Revenue DESC
  LIMIT 5
")
print(sql_customers)

cat("\nExecuting SQL Query 2: Total Revenue by Country, excluding NA (Top 5)...\n")
sql_countries <- dbGetQuery(con, "
  SELECT Country, SUM(Revenue) as Revenue
  FROM retail_sales
  WHERE Country IS NOT NULL
  GROUP BY Country
  ORDER BY Revenue DESC
  LIMIT 5
")
print(sql_countries)

# VACUUM to reclaim freed pages and compact the file
dbExecute(con, "VACUUM")
dbDisconnect(con)

# Cross-check Verification
cat("\n--- CROSS-CHECK VERIFICATION ---\n")
dplyr_top_cust <- top_customers %>% mutate(CustomerID = as.numeric(CustomerID))
sql_top_cust   <- sql_customers  %>% mutate(CustomerID = as.numeric(CustomerID))
cust_match <- isTRUE(all.equal(dplyr_top_cust$CustomerID, sql_top_cust$CustomerID)) &&
              isTRUE(all.equal(round(dplyr_top_cust$Revenue, 2), round(sql_top_cust$Revenue, 2)))

dplyr_top_country <- top_countries
sql_top_country   <- sql_countries
country_match <- isTRUE(all.equal(dplyr_top_country$Country, sql_top_country$Country)) &&
                 isTRUE(all.equal(round(dplyr_top_country$Revenue, 2), round(sql_top_country$Revenue, 2)))

cat("Top 5 Customers match dplyr:", cust_match, "\n")
cat("Top 5 Countries match dplyr:", country_match, "\n")

if (cust_match && country_match) {
  cat("Verification SUCCESS: SQLite results match dplyr results exactly!\n")
} else {
  warning("Verification FAILURE: Results mismatch between SQLite and dplyr!")
}

# DB File size
db_size <- file.info(db_path)$size
cat("\nDatabase file size:", round(db_size / (1024 * 1024), 2), "MB\n")
if (db_size > 50 * 1024 * 1024) {
  cat("WARNING: The SQLite database exceeds 50 MB. Consider excluding it from git.\n")
} else {
  cat("Database file size is under 50 MB. Safe for commit.\n")
}
