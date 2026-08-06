# Week 2 NPTEL Practice 
# R Prog Lab 2 Purvaj Gaonkar - 23102C0083

# Basic operations
2 + 3
2 * 3
2 - 3
3 / 2

# BODMAS rule in action (Brackets, Orders, Division, Multiplication, Addition, Subtraction)
2 * 3 - 4 + 5 / 6
(2 + 3) * 5 + 5 - 10
(((2 + 3) * 5 + 5) - 10) / 2

# Spacing doesn't matter
2+5
2    +    5

# Assigning values
x <- 20
x
x = 20
x

# Doing math with variables
y = x * 2
y
z = x + y
z

# Case sensitivity check
X <- 30
X
x

# Assigning character strings (quotes are required)
x = "apple"
x = 'apple'
x

# Checking data types
x = 20
is.numeric(x)
is.character(x)

y = "apple"
is.character(y)
is.numeric(y)

# Converting data types
y = as.character(x)
is.numeric(y)
is.character(y)
y

# Coercion warning (converting text to a number creates NA - Not Available)
z = as.numeric("apple")
z

# Checking storage modes
x = 6
mode(x)
storage.mode(x)

x = TRUE
storage.mode(x)

# Creating a data vector
y = c(1, 2, 3, 4, 5)
y

# Math with vectors and scalars
c(2, 3, 5, 7) + 10
c(12, 13, 15, 17) - 10
c(2, 3, 5, 7) * 10
c(12, 13, 15, 17) / 10

# Math between vectors of the same length
c(2, 3, 5, 7) + c(-2, -3, -5, 8)
c(2, 3, 5, 7) - c(-2, -3, -5, 8)
c(2, 3, 5, 7) * c(-2, -3, -5, 8)
c(24, 20, 8, 16) / c(3, 4, 2, 8)

# Vector recycling (dividing 4 items by 2 items works perfectly)
c(24, 20, 8, 16) / c(4, 2)

# Vector mismatch warnings (when lengths aren't perfect multiples)
c(2, 3, 5, 7) + c(8, 9, 10)
c(24, 20, 8, 16) / c(4, 2, 8)

# Division by zero
3 / 0
5 + Inf

# Checking for infinity
x = 5 + Inf
is.finite(x)
is.infinite(x)