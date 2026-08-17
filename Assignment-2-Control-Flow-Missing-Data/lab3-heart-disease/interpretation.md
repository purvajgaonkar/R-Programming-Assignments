# Interpretation — Assignment 2 Lab 3 BP Cleaning

**Student:** Purvaj Gaonkar | Roll No: 23102C0083 | Class: BE CMPN-C  
**Subject:** R Programming (ODD 2026-27)

---

## Performance Comparison: Loops versus Vectorization

Vectorized operations are significantly faster than loop-based cleaning in R. On the baseline Cleveland dataset containing 303 observations, the difference in processing time is extremely small. The loop-based detection of invalid blood pressure values required a median time of 32.05 microseconds, whereas the vectorized approach took 2.80 microseconds.

To demonstrate the difference at scale, we performed the benchmark on a replicated vector of 1,000,000 elements. The results show a substantial performance gap:
* Loop-based detection took a median of 130.64 milliseconds.
* Vectorized detection took a median of 10.99 milliseconds.

This represents a speedup factor of approximately 11.9x when using the vectorized approach.

## Why Vectorization Wins in R

Vectorization is faster in R because R is an interpreted language. Under a standard loop, the R interpreter must evaluate the type, find the correct method, and execute the instructions for every element individually. This loop interpreter overhead is high. 

In contrast, vectorized operations delegate the repetition directly to compiled internal C or Fortran code. This compiled layer executes loop iterations at the machine code level without repeating dynamic type checks or symbol lookups. Consequently, vectorization avoids the interpreter bottleneck and fully leverages contiguous memory layouts.
