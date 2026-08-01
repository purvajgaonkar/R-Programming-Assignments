# Interpretation — Assignment 1 Air-Quality Data Cleaning

**Student:** Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C  
**Subject:** R Programming (ODD 2026-27)

---

## Why Median Instead of Mean for Pollutant Imputation

Pollutant concentrations such as PM2.5 (median: 58 µg/m³), PM10
(median: 87 µg/m³), SO2 (median: 9 µg/m³), and NO2 (median: 53 µg/m³) are
strongly right-skewed: the bulk of hourly readings are low, but episodic
pollution events push a small number of values to extreme highs. The
arithmetic mean is sensitive to these outliers and would inflate the imputed
value beyond what a typical hour actually looks like. The **median**, by
contrast, is the middle observation after sorting and is therefore unaffected
by extreme values — it gives a more representative "normal hour" reading and
avoids artificially worsening the dataset's pollution statistics.

## Why Mode for Wind Direction

`wd` (wind direction) is a categorical variable storing compass labels such as
"NNW" or "N". Calculating a numeric median or mean over such labels is
meaningless. Mode imputation — replacing the 81 missing entries with the most
frequently observed direction — preserves the distributional character of the
column and is the standard practice for nominal data.

## What NaN and Inf Values in `pollution_ratio` Represent

`pollution_ratio = PM2.5 / PM10`. When PM10 equals zero (sensor recording a
zero reading), the division yields **+Inf** (if PM2.5 > 0) or **NaN** (if
both are zero simultaneously). In this dataset both counts were **0** — the
934 special values in the ratio were pure **NA** propagated from source columns
that were already missing. This indicates that every sensor outage affected
both channels together rather than producing spurious zero readings, which is
consistent with station-level recording gaps.

## Did Cleaning Succeed?

Yes. Across the seven selected variables — PM2.5, PM10, SO2, NO2, TEMP, WSPM,
and wd — a total of **3 716 missing values** were present before cleaning. After
median imputation (numeric columns) and mode imputation (`wd`), **0 NAs
remained**. The exported CSV was read back and verified programmatically: all
35 064 rows were retained and no NAs were found in any of the seven variables,
confirming that the cleaning pipeline was fully successful.
