# Commit Plan

Task 7 of the assignment requires *meaningful commits at different stages of
project development instead of uploading the complete project in a single
commit*, and the commit history is itself a listed deliverable.

Run these in order from inside the project folder after `git init`.

```bash
git init
git add .gitignore README.md COMMIT_PLAN.md
git commit -m "chore: initialise project structure and gitignore"

git add requirements.R
git commit -m "chore: add package requirements including Bioconductor EBImage"

git add scripts/01_setup_and_data.R data/images/README.txt
git commit -m "feat: add dataset preparation and image loading"

git add data/images/*.jpg
git commit -m "data: add 12 source images (6 planes, 6 cars)"

git add scripts/02_preprocess.R
git commit -m "feat: add resize, reshape and train/test split"

git add scripts/03_train_evaluate.R image_classification.R
git commit -m "feat: add model definition, training and evaluation"

git add assignment4_image_classification.ipynb
git commit -m "feat: add Colab notebook version of the pipeline"

git add output/
git commit -m "results: add generated outputs, metrics and confusion matrices"

git add README.md
git commit -m "docs: complete README with results and screenshots"
```

Verify before pushing:

```bash
git log --oneline
```

Then:

```bash
git remote add origin https://github.com/<username>/<repo>.git
git branch -M main
git push -u origin main
```

Do not squash these commits.
