# ---------------------------------------------------------------
# Package installation for Assignment 4
# Run this once before executing the project.
# ---------------------------------------------------------------

options(repos = c(CRAN = "https://cloud.r-project.org"))

# EBImage is a Bioconductor package, NOT on CRAN.
# On Linux it compiles against FFTW/TIFF/JPEG/PNG system libraries.
# On Ubuntu or Google Colab, install those first:
#   sudo apt-get install -y libfftw3-dev libtiff-dev libjpeg-dev libpng-dev

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
if (!requireNamespace("EBImage", quietly = TRUE)) {
  BiocManager::install("EBImage", ask = FALSE, update = FALSE)
}

# keras3 supersedes the older `keras` package used in the reference tutorial.
# Recent versions resolve the Python backend via reticulate::py_require(),
# so install_keras() is usually not required.
if (!requireNamespace("keras3", quietly = TRUE)) {
  install.packages("keras3")
}

library(EBImage)
library(keras3)

cat("EBImage version:", as.character(packageVersion("EBImage")), "\n")
cat("keras3  version:", as.character(packageVersion("keras3")),  "\n")

# If the Keras backend fails to initialise, uncomment and run:
# keras3::install_keras()
