# ---------------------------------------------------------------
# 01 - Setup, dataset preparation, image loading and exploration
# ---------------------------------------------------------------

library(EBImage)
library(keras3)

dir.create("data/images", recursive = TRUE, showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

# ---- Dataset ---------------------------------------------------
# The reference tutorial uses 12 personal photographs:
#   p1..p6 = planes, c1..c6 = cars
# To keep the project reproducible for anyone cloning this repository,
# the images are taken from CIFAR-10 (class 0 = airplane, class 1 = automobile)
# and written out using the tutorial's naming scheme.
# If you supply your own 12 images with these names, this step is skipped.

pics <- c(paste0("p", 1:6, ".jpg"), paste0("c", 1:6, ".jpg"))

if (all(file.exists(file.path("data/images", pics)))) {
  cat("Found 12 existing images in data/images/ - using those.\n")
} else {
  cat("Generating 12 images from CIFAR-10...\n")
  cifar <- dataset_cifar10()
  x <- cifar$train$x
  y <- as.vector(cifar$train$y)

  plane_idx <- which(y == 0)[1:6]
  car_idx   <- which(y == 1)[1:6]

  write_img <- function(arr, path) {
    img <- Image(aperm(arr / 255, c(2, 1, 3)), colormode = "Color")
    writeImage(img, path, quality = 100)
  }

  for (i in 1:6) write_img(x[plane_idx[i], , , ], file.path("data/images", paste0("p", i, ".jpg")))
  for (i in 1:6) write_img(x[car_idx[i],   , , ], file.path("data/images", paste0("c", i, ".jpg")))
  cat("Wrote 12 images to data/images/\n")
}

# ---- Load ------------------------------------------------------
# Order matters: positions 1-6 are planes (label 0), 7-12 are cars (label 1).

mypic <- list()
for (i in 1:12) {
  mypic[[i]] <- readImage(file.path("data/images", pics[i]))
}
cat("Loaded", length(mypic), "images\n")

# ---- Explore ---------------------------------------------------

print(mypic[[1]])
summary(mypic[[1]])
str(mypic[[1]])

png("output/histogram_p2.png", width = 700, height = 500)
hist(mypic[[2]], main = "Pixel intensity distribution - p2.jpg")
dev.off()

png("output/all_images.png", width = 900, height = 400)
par(mfrow = c(2, 6), mar = c(1, 1, 2, 1))
for (i in 1:12) {
  display(mypic[[i]], method = "raster")
  title(pics[i], cex.main = 1)
}
dev.off()
par(mfrow = c(1, 1))

saveRDS(mypic, "output/raw_images.rds")
cat("Stage 01 complete.\n")
