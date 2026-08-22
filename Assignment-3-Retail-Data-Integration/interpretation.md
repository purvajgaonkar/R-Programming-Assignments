# Interpretation: Assignment 3 - Retail Data Integration and Analysis

## Data Cleaning Decisions

### Duplicate Records
Duplicate rows were identified and removed using `dplyr::distinct()`. A total of 5,429 duplicate transaction rows were removed from the raw 541,909-row file, leaving 536,480 rows. No duplicates were found in the products or customers tables, which is expected since both were already collapsed to one row per key during source preparation.

### Cancellations and Negative Quantities
The dataset contains two types of rows with negative Quantity values. Rows whose InvoiceNo begins with "C" are returns or cancellations: they record the reversal of a prior sale. These 9,177 rows are legitimate business events and are deliberately retained. Excluding them would overstate net revenue by $815,184. Total revenue reported throughout this analysis is therefore net of returns.

A separate set of 1,336 rows carries negative Quantity without a "C" prefix. These have no corresponding invoice type and represent data entry errors. They are removed under the step labelled "Remove Invalid Negatives (non-cancellation)".

### Missing CustomerID
CustomerID is absent for approximately 25% of transactions (135,080 of 541,909 raw rows). These are guest or unregistered purchases. We choose to retain them for all transaction-level and product-level analyses, because dropping them would underestimate total sales revenue by approximately $1.18 million. They are excluded only from the customer-level analyses (top customers, segmentation bands) where a CustomerID is required to aggregate spend per customer. The cleaning log records this as a zero-removal step with an explicit label.

### Invalid Unit Prices
Products with a UnitPrice of zero or below (145 of 4,070 StockCodes after collapsing) are removed from the products table because they cannot be used to calculate revenue. Transactions that reference these StockCodes consequently receive NA revenue and are excluded from the analysis dataset (52 rows).

### Country = NA Group
The Country column is sourced from the customers table and is absent for all 133,556 analysis-eligible transactions that have no CustomerID. In the previous run these rows appeared as a phantom "NA country" group ranked second with $1,181,924. This is not a geography. All country-level analysis now filters `!is.na(Country)` before grouping, and the set-aside amount is printed explicitly.

---

## Join Choice: Left Join

We use `left_join` with transactions as the primary table. The reasoning is as follows.

- **Left join with products** keeps every transaction row. Transactions referencing a StockCode absent from the products catalog (e.g., codes whose price was cleaned away) receive NA UnitPrice; these 52 rows are then excluded when filtering for valid Revenue. No transactions are silently discarded without accounting for them.
- **Left join with customers** keeps all transactions, including those with NA CustomerID. An inner join would have silently dropped all 133,595 guest transactions, reducing the dataset to only the identified-customer portion and inflating per-customer revenue figures.
- An **inner join** on both keys simultaneously would have discarded roughly 25% of transactions, 52 unmatched product rows, and produced a dataset that does not represent actual total sales.

Key cardinality was verified after both joins: the row count of the integrated dataset (535,144) matches the cleaned transactions count exactly, confirming no row duplication.

---

## Customer Segmentation Thresholds

Customer-level spend was aggregated for the 4,372 distinct CustomerIDs in the cleaned customers table. Thresholds are derived from the empirical distribution of total spend per customer:

| Boundary          | Percentile | Value    |
|-------------------|-----------|----------|
| Low / Medium      | 50th      | $671.09  |
| Medium / High     | 75th      | $1,663.17 |
| High / Premium    | 95th      | $5,944.09 |

Using percentiles rather than round numbers avoids arbitrary cutoffs and ensures the bands remain meaningful if the data changes. The Low Value band covers the bottom half of customers; Premium covers the top 5%.

---

## Market Performance Analysis

**Note on United Kingdom dominance:** The UK generates $7,407,550 in revenue across 19,856 transactions and 3,950 customers. Raw revenue comparisons against other countries are misleading because the UK customer base is orders of magnitude larger. A fair comparison uses revenue per customer.

**High-performing market: EIRE**
EIRE generates $276,248 from only 3 identified customers and 319 transactions, producing a revenue per customer of $92,083. This is the highest revenue-per-customer figure outside the UK in the dataset. The pattern suggests a small number of large wholesale accounts that concentrate purchasing volume. A targeted account management strategy could extract significant additional value here.

**High-performing market (volume efficiency): Netherlands**
The Netherlands generates $331,094 from 9 customers and 101 transactions, giving revenue per customer of $36,788, the second-highest in the dataset. Like EIRE, this indicates bulk purchasing from a small customer base.

**Underperforming market: Saudi Arabia**
Saudi Arabia generates $134 in total from 2 transactions and 1 customer, with revenue per customer of $134. This is the lowest of any named geography in the dataset. Whether this reflects lack of market penetration, shipping barriers, or a single test purchase, the data provides no basis to treat it as an active market.

---

## Three Business Insights

**Insight 1: The Premium segment (4.8% of customers) generates 50.3% of identifiable customer revenue.**
219 customers spend above the 95th-percentile threshold of $5,944, collectively accounting for $4,605,504 out of $9,059,316 attributable to known customers. The remaining 4,153 customers share the other 49.7%. Protecting and growing this Premium segment through retention programs is the single highest-leverage action available to this business.

**Insight 2: Revenue per customer in EIRE ($92,083) and the Netherlands ($36,788) dwarfs the UK average ($1,875), pointing to high-value wholesale relationships in those markets.**
The UK's $7.4 million headline figure is driven by volume: 3,950 customers averaging $1,875 each. EIRE's 3 customers average 49 times that. The Netherlands' 9 customers average 20 times that. These are almost certainly wholesale or B2B accounts. Formalising these relationships with preferred pricing or dedicated account management would reduce churn risk for revenue that is currently highly concentrated.

**Insight 3: Two of the top five revenue-generating StockCodes are shipping charges, not products.**
DOTCOM POSTAGE (StockCode DOT) at $315,693 and POSTAGE (StockCode POST) at $114,390 rank first and fourth, together representing $430,083 or 4.2% of total revenue. This means the top-products list overstates the commercial importance of physical goods. A clean product-revenue analysis should filter out service-type codes. If shipping charges are priced below cost, the effective product-level margins are also being suppressed by these two codes.
