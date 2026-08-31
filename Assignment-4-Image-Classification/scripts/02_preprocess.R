# ---------------------------------------------------------------
# 02 - Resize, reshape, train/test split, one-hot encoding
# ---------------------------------------------------------------

library(EBImage)
library(keras3)

mypic <- readRDS("output/raw_images.rds")

# ---- Resize every image to 28 x 28 -----------------------------
for (i in 1:12) {
  mypic[[i]] <- resize(mypic[[i]], 28, 28)
}

# ---- Flatten: 28 * 28 * 3 channels = 2352 values per image -----
for (i in 1:12) {
  mypic[[i]] <- array_reshape(mypic[[i]], c(28, 28, 3))
}
cat("Flattened length per image:", length(mypic[[1]]), "\n")

# ---- Train / test split ----------------------------------------
# Images 6 and 12 (one plane, one car) are held out for testing.
#
# NOTE: the published tutorial script loops only over 7:11, which would
# produce 5 training rows against 10 labels. Both ranges are required.

trainx <- NULL
for (i in 1:5)  trainx <- rbind(trainx, mypic[[i]])
for (i in 7:11) trainx <- rbind(trainx, mypic[[i]])

testx <- rbind(mypic[[6]], mypic[[12]])

trainy <- c(0, 0, 0, 0, 0, 1, 1, 1, 1, 1)
testy  <- c(0, 1)

# ---- One-hot encode --------------------------------------------
trainLabels <- to_categorical(trainy)
testLabels  <- to_categorical(testy)

str(trainx)
str(testx)

saveRDS(list(trainx = trainx, testx = testx,
             trainy = trainy, testy = testy,
             trainLabels = trainLabels, testLabels = testLabels),
        "output/preprocessed_data.rds")

cat("Stage 02 complete.\n")
