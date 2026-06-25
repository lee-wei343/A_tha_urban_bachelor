# _A. thaliana_ urban populations — Bachelor thesis

Code and data for the bachelor thesis on urban _Arabidopsis thaliana_ populations.

## Repository layout

```
data/
  raw/          Original CSVs; never edited by hand. Inputs to the pipeline.
  processed/    Cleaned tables produced by scripts/. Re-buildable from raw.
  README.md     Codebook (per-column documentation for every table).
scripts/        Numbered, idempotent cleaning pipeline (run in order).
R/              Shared helper functions sourced by analysis docs.
analysis/       One Quarto document per research question.
figures/        Generated plots (gitignored).
```

## Setup

All R packages used by the pipeline and the analysis docs can be
installed via mamba (conda-forge), plus two that are not on conda-forge:

```bash
mamba install -c conda-forge \
    r-base quarto \
    r-tidyverse r-janitor r-here r-stringi \
    r-dharma r-mvnormtest r-vegan \
    r-lme4 r-emmeans r-multcomp r-multcompview r-car r-mmrm r-corrplot \
    r-remotes
```

Then install the two CRAN/GitHub-only packages via R:

```bash
Rscript -e 'install.packages("biotools", repos="https://cloud.r-project.org")'
Rscript -e 'remotes::install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")'
```

## Reproducing the cleaned datasets

From the repo root:

```bash
Rscript scripts/00_run_all.R
```

This runs steps 01 → 04 in order and writes everything under
`data/processed/`. Each script can also be run individually if you only
need to rebuild one output.

| Script                          | Reads                                                 | Writes                                                         |
|---------------------------------|-------------------------------------------------------|----------------------------------------------------------------|
| `01_clean_phenology.R`          | `phenology_field.csv`                                 | `phenology_clean.csv`, `pop_metadata.csv`                      |
| `02_clean_tplant_F5.R`          | F5 obs + dead/below-18cm + sampling + `pop_metadata`  | `tplant_F5_clean.csv`                                          |
| `03_clean_tplant_F6.R`          | F6 obs + `pop_metadata`                               | `tplant_F6_clean.csv`                                          |
| `04_clean_dormancy.R`           | dormancy count + `pop_metadata`                       | `dormancy_clean.csv`                                           |

## Running the analyses

The analysis Quarto documents read from `data/processed/`, so the
cleaning pipeline must have run at least once. Render a doc with:

```bash
quarto render analysis/01_F5_leaf_morphology.qmd
```

| Document                              | Question                                                                |
|---------------------------------------|-------------------------------------------------------------------------|
| `01_F5_leaf_morphology.qmd`           | Does F5 leaf morphology differ by ecotype? (EDA, MANOVA/PERMANOVA, GLMM)|
| `02_F6_flowering_time.qmd`            | Does F6 flowering time differ by ecotype?                               |
| `03_F6_leaf_morphology.qmd`           | Does F6 leaf morphology differ by ecotype?                              |
| `04_dormancy.qmd`                     | Does F5 seed dormancy differ by ecotype across runs?                    |
| `05_F5_F6_correlation.qmd`            | How well do F5 and F6 population-level traits correlate?                |

## Processed datasets at a glance

| File                          | Grain                              | What it answers                                                   |
|-------------------------------|------------------------------------|-------------------------------------------------------------------|
| `phenology_clean.csv`         | one row per field site             | Field survey: presence, persistence, flowering time, ecotype       |
| `pop_metadata.csv`            | one row per population             | Lookup: `pop → ecotype` (Wall, Grass, Pavement, Tree bed)         |
| `tplant_F5_clean.csv`         | one row per F5 transplant          | Morphology + sampling + alive/above-18cm flags                    |
| `tplant_F6_clean.csv`         | one row per F6 plant               | Sowing/germination/flowering dates + morphology                    |
| `dormancy_clean.csv`          | one row per (F5 parent × run)      | Seed counts, fungi flags, dormancy-test windows                    |

For column-level documentation see `data/README.md`.
