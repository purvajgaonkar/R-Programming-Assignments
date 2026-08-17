# Interpretation — Assignment 2 Lab 4 Missing Data Handling

**Student:** Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C  
**Subject:** R Programming (ODD 2026-27)

---

## Missingness Patterns in the Adult Dataset

Prior to deliberate injections, the original Adult dataset contains missing values in three categorical variables: workclass (1,836 missing, 5.64%), occupation (1,843 missing, 5.66%), and native_country (583 missing, 1.79%). After injecting 200 NAs in hours_per_week, 150 blank strings in workclass, 80 NaNs in capital_gain, and 50 impossible ages, the total missingness reached 0.93% of all cells.

The missingness displays a high correlation between workclass and occupation. When the workclass of an individual is missing, their occupation is also frequently missing. This indicates a missing-not-at-random (MNAR) or missing-at-random (MAR) mechanism, likely representing individuals who are unemployed, self-employed, or chose not to disclose their employment details.

## Imputation Medians and Treatment Summary

The following median values were computed from valid observations and used to impute missing numeric values:
* Age: 37.0 years
* Hours per week: 40.0 hours
* Capital gain: 0.0 dollars

For categorical variables containing missing entries, we replaced blank strings with "Unknown". Rows containing missing occupation or native_country were removed. This process deleted 2,399 observations, which is 7.37% of the total dataset. The remaining 30,162 observations are fully complete.

## Limitations of Median Imputation

Median imputation is a simple method to handle missing numerical values. However, it has major limitations:

First, it reduces the variance of the variable. By replacing all missing values with a single constant median, the imputed observations cluster at the center of the distribution. This artificially reduces the spread of the data and alters the shape of the probability density.

Second, it distorts relationships between variables. Median imputation does not account for covariates. For example, imputing the hours worked per week as 40.0 for all missing entries ignores differences in education, age, or occupation. This attenuates the correlation coefficient and biases downstream regression coefficients toward zero.

Third, it leads to underestimates of standard errors. Statistical software treats the imputed median values as true observations, which inflates the sample size. This reduces the standard error estimates and increases the type one error rate in hypothesis testing.
