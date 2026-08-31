# ---------------------------------------------------------------
# Assignment 4 - Image Recognition and Classification with R
# Full pipeline. Runs all three stages in order.
#
# Usage:  Rscript image_classification.R
# ---------------------------------------------------------------

source("scripts/01_setup_and_data.R")
source("scripts/02_preprocess.R")
source("scripts/03_train_evaluate.R")

cat("\nPipeline complete. See output/ for all generated results.\n")
