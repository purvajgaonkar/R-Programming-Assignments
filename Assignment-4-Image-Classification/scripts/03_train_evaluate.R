# ---------------------------------------------------------------
# 03 - Model definition, training, evaluation and prediction
# ---------------------------------------------------------------

library(keras3)

d <- readRDS("output/preprocessed_data.rds")
trainx <- d$trainx; testx <- d$testx
trainy <- d$trainy; testy <- d$testy
trainLabels <- d$trainLabels; testLabels <- d$testLabels

# ---- Model -----------------------------------------------------
# The tutorial passes input_shape inside the first layer_dense().
# keras3 declares it on keras_model_sequential() instead.

model <- keras_model_sequential(input_shape = c(2352)) |>
  layer_dense(units = 256, activation = "relu") |>
  layer_dense(units = 128, activation = "relu") |>
  layer_dense(units = 2,   activation = "softmax")

summary(model)

model |> compile(
  loss      = "binary_crossentropy",
  optimizer = optimizer_rmsprop(),
  metrics   = c("accuracy")
)

# ---- Train -----------------------------------------------------
history <- model |> fit(
  trainx, trainLabels,
  epochs = 30,
  batch_size = 32,
  validation_split = 0.2
)

png("output/training_history.png", width = 800, height = 500)
plot(history)
dev.off()

# ---- Evaluate --------------------------------------------------
train_eval <- model |> evaluate(trainx, trainLabels)
test_eval  <- model |> evaluate(testx,  testLabels)

# ---- Prediction ------------------------------------------------
# The tutorial uses predict_classes() and predict_proba().
# Both were REMOVED in TensorFlow 2.6 and no longer exist.
# predict() returns class probabilities; max.col() gives the index of the
# largest, and subtracting 1 converts that index back to the 0/1 label.

train_prob <- model |> predict(trainx)
train_pred <- max.col(train_prob) - 1

test_prob <- model |> predict(testx)
test_pred <- max.col(test_prob) - 1

cm_train <- table(Predicted = train_pred, Actual = trainy)
cm_test  <- table(Predicted = test_pred,  Actual = testy)

print(cm_train)
print(cm_test)

# ---- Confusion matrix plot -------------------------------------
plot_cm <- function(cm, title) {
  m <- as.matrix(cm)
  image(1:ncol(m), 1:nrow(m), t(m[nrow(m):1, , drop = FALSE]),
        col = colorRampPalette(c("#f5f7fa", "#2E74B5"))(20),
        axes = FALSE, xlab = "Actual", ylab = "Predicted", main = title)
  axis(1, at = 1:ncol(m), labels = colnames(m))
  axis(2, at = 1:nrow(m), labels = rev(rownames(m)))
  for (i in 1:nrow(m)) for (j in 1:ncol(m))
    text(j, nrow(m) - i + 1, m[i, j], cex = 1.6, font = 2)
  box()
}

png("output/confusion_matrix_train.png", width = 500, height = 450)
plot_cm(cm_train, "Confusion Matrix - Training Data")
dev.off()

png("output/confusion_matrix_test.png", width = 500, height = 450)
plot_cm(cm_test, "Confusion Matrix - Test Data")
dev.off()

# ---- Save results ----------------------------------------------
train_results <- cbind(round(train_prob, 4), Predicted = train_pred, Actual = trainy)
colnames(train_results)[1:2] <- c("Prob_Plane", "Prob_Car")

test_results <- cbind(round(test_prob, 4), Predicted = test_pred, Actual = testy)
colnames(test_results)[1:2] <- c("Prob_Plane", "Prob_Car")
rownames(test_results) <- c("p6.jpg", "c6.jpg")

write.csv(train_results, "output/train_predictions.csv", row.names = FALSE)
write.csv(test_results,  "output/test_predictions.csv",  row.names = TRUE)
write.csv(as.data.frame(cm_train), "output/confusion_matrix_train.csv", row.names = FALSE)
write.csv(as.data.frame(cm_test),  "output/confusion_matrix_test.csv",  row.names = FALSE)

metrics <- data.frame(
  Metric = c("Train Loss", "Train Accuracy", "Test Loss", "Test Accuracy",
             "Epochs", "Training Images", "Test Images", "Input Features"),
  Value  = c(round(train_eval$loss, 4), round(train_eval$accuracy, 4),
             round(test_eval$loss, 4),  round(test_eval$accuracy, 4),
             30, nrow(trainx), nrow(testx), ncol(trainx))
)
write.csv(metrics, "output/metrics.csv", row.names = FALSE)
print(metrics)

save_model(model, "output/plane_car_model.keras")
cat("Stage 03 complete.\n")
