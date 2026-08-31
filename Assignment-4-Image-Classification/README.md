# Image Recognition and Classification with R

**Assignment 4 | R Programming (ODD 2026-27)**

| | |
|---|---|
| **Name** | Purvaj Gaonkar |
| **Roll Number** | 23102C0083 |
| **Class** | BE CMPN - C |
| **Reference** | Bharatendra Rai, *Image Recognition and Classification with R* (Deep Learning with R, lecture 4) |

---

## Objective

Implement an end-to-end image classification project in R: load raw image files,
inspect and preprocess them, build and train a neural network with Keras, evaluate
the result, and maintain the whole thing under Git version control.

## Problem Description

Given a small set of photographs belonging to two categories, planes and cars, train
a classifier that assigns an unseen image to the correct category. Each image is
resized to a common resolution, flattened into a numeric vector, and passed to a
fully connected neural network which outputs a probability for each class.

## Dataset

Twelve images, six per class, following the reference tutorial's naming scheme:

| Files | Class | Label |
|---|---|---|
| `p1.jpg` – `p6.jpg` | Plane | 0 |
| `c1.jpg` – `c6.jpg` | Car | 1 |

Images 1–5 and 7–11 form the training set (10 images). Images 6 and 12, one of each
class, are held out for testing.

The images are generated from **CIFAR-10** (class 0 = airplane, class 1 = automobile)
so that anyone cloning this repository reproduces the exact same inputs. The reference
video uses personal photographs; substituting a public dataset makes the project
reproducible without changing any of the method. To use your own images instead, place
twelve files with the names above into `data/images/` before running, and the
generation step is skipped automatically.

## Packages Used

| Package | Purpose | Source |
|---|---|---|
| `EBImage` | Reading, displaying, resizing images | **Bioconductor**, not CRAN |
| `keras3` | Model definition, training, evaluation | CRAN |
| `tensorflow` | Backend for Keras | resolved via reticulate |

`EBImage` is not installable with `install.packages()`. It requires BiocManager, and
on Linux it compiles against FFTW, TIFF, JPEG and PNG system libraries:

```bash
sudo apt-get install -y libfftw3-dev libtiff-dev libjpeg-dev libpng-dev
```

```r
install.packages("BiocManager")
BiocManager::install("EBImage")
```

## Major Operations Performed

1. Load twelve images with `readImage()`.
2. Explore with `print()`, `display()`, `summary()`, `hist()` and `str()`.
3. Resize every image to 28 × 28.
4. Flatten each to a vector of 28 × 28 × 3 = **2352** values with `array_reshape()`.
5. Split into a 10-image training set and a 2-image test set.
6. One-hot encode the labels with `to_categorical()`.
7. Build a sequential network: dense 256 (ReLU) → dense 128 (ReLU) → dense 2 (softmax).
8. Compile with binary cross-entropy loss and the RMSprop optimizer.
9. Train for 30 epochs, batch size 32, with a 0.2 validation split.
10. Evaluate on both sets and produce confusion matrices.

## How to Run

### Google Colab (recommended)

1. Open `assignment4_image_classification.ipynb` in Colab.
2. **Runtime → Change runtime type → R**.
3. **Runtime → Run all**. The first cell installs system libraries and EBImage, which
   takes several minutes on a fresh runtime.

### Locally with RStudio or Rscript

```r
source("requirements.R")     # once
```

```bash
Rscript image_classification.R
```

Or run the stages individually:

```bash
Rscript scripts/01_setup_and_data.R
Rscript scripts/02_preprocess.R
Rscript scripts/03_train_evaluate.R
```

## Results

> **TO BE FILLED AFTER RUNNING.** Copy these four numbers from `output/metrics.csv`.

| Metric | Value |
|---|---|
| Training loss | `FILL IN` |
| Training accuracy | `FILL IN` |
| Test loss | `FILL IN` |
| Test accuracy | `FILL IN` |

### Confusion Matrix — Training Data

> Paste the table printed by the notebook, then keep the image reference below.

![Training confusion matrix](output/confusion_matrix_train.png)

### Confusion Matrix — Test Data

![Test confusion matrix](output/confusion_matrix_test.png)

### Training History

![Training history](output/training_history.png)

### Source Images

![All twelve images](output/all_images.png)

## Screenshots

> Add screenshots of successful execution here, as required by the assignment.

| Screenshot | File |
|---|---|
| Console showing successful training run | `screenshots/execution.png` |
| Confusion matrix output | `screenshots/confusion_matrix.png` |
| `git log` showing staged commit history | `screenshots/git_log.png` |

## Notes on the Reference Implementation

Two corrections were needed to make the published tutorial script run on current
software.

**`predict_classes()` and `predict_proba()` no longer exist.** Both were removed in
TensorFlow 2.6. They are replaced here with:

```r
prob <- model |> predict(trainx)
pred <- max.col(prob) - 1
```

`predict()` returns the class probabilities, `max.col()` gives the index of the largest
value in each row, and subtracting 1 converts that index back to a 0/1 label.

**The training loop in the published script covers only `7:11`.** That produces five
training rows against ten labels. Both `1:5` and `7:11` are required.

Additionally, the tutorial uses the older `keras` package and passes `input_shape`
inside the first `layer_dense()`. This implementation uses `keras3` and declares the
input shape on `keras_model_sequential()`, which is the current form.

## Limitations

**Training accuracy here is not evidence of learning.** The network has over 600,000
parameters and sees ten training images. There is more than enough capacity to
memorise each image outright, so high training accuracy is the expected outcome
regardless of whether anything transferable was learned.

**The test set cannot support a conclusion.** With exactly two test images, accuracy
can only be 0%, 50% or 100%. No statement about generalisation can be made from that.

**The architecture discards spatial structure.** Flattening to a 2352-long vector
destroys the information that two pixels were adjacent, so the network cannot learn
edges or shapes. What remains learnable is the overall colour and brightness
distribution, which is likely how the two classes separate at all: sky backgrounds
are bright and blue, road backgrounds are not. A convolutional network using
`layer_conv_2d()` and `layer_max_pooling_2d()` preserves that structure and is the
appropriate architecture for image data.

**What a production version would require.** Thousands of images per class, a proper
train/validation/test split, data augmentation, and a convolutional architecture. The
value of this exercise lies in the end-to-end workflow rather than in the accuracy of
the resulting classifier.

## Repository Structure

```
Assignment-4-Image-Classification/
├── assignment4_image_classification.ipynb   Colab notebook (R kernel)
├── image_classification.R                   full pipeline in one script
├── requirements.R                           package installation
├── scripts/
│   ├── 01_setup_and_data.R                  dataset prep, loading, exploration
│   ├── 02_preprocess.R                      resize, reshape, split, encode
│   └── 03_train_evaluate.R                  model, training, evaluation
├── data/images/                             12 source images
├── output/                                  generated results
├── COMMIT_PLAN.md                           staged commit sequence
├── .gitignore
└── README.md
```
