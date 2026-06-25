# _A. thaliana_ urban populations — Bachelor thesis

Code and data for the bachelor thesis on urban _Arabidopsis thaliana_ populations.

## Repository layout

```
data/
  raw/          Original CSVs; never edited by hand. Inputs to the pipeline.
  processed/    Cleaned tables produced by scripts/. Re-buildable from raw.
scripts/        Numbered, idempotent cleaning pipeline (run in order).
analysis/       Quarto documents, one per research question.
R/              Reusable helper functions sourced by analysis docs.
figures/        Generated plots (gitignored).
```

## Reproducing the cleaned datasets

Requires R (≥ 4.2) with the following CRAN packages:

```r
install.packages(c("tidyverse", "janitor", "here", "stringi"))
```

Then from the repo root:

```bash
Rscript scripts/00_run_all.R
```

This runs steps 01 → 04 in order and writes everything under
`data/processed/`. Each script can also be run individually if you only
need to rebuild one output.

| Script                          | Reads                                    | Writes                                                         |
|---------------------------------|------------------------------------------|----------------------------------------------------------------|
| `01_clean_phenology.R`          | `phenology_field.csv`                    | `phenology_clean.csv`, `pop_metadata.csv`                      |
| `02_clean_tplant_F5.R`          | F5 obs + dead/below-18cm + sampling + `pop_metadata` | `tplant_F5_clean.csv`                                  |
| `03_clean_tplant_F6.R`          | F6 obs + `pop_metadata`                  | `tplant_F6_clean.csv`                                          |
| `04_clean_dormancy.R`           | dormancy count + `pop_metadata`          | `dormancy_clean.csv`                                           |

A one-off bootstrap script — `scripts/extract_lists_from_qmd.R` — is kept
in the history to document how `dead_plants_F5.csv` and
`population_sampling.csv` were lifted out of the original analysis
notebook. It is safe to delete once `main.qmd` is removed.

## Processed datasets at a glance

| File                          | Grain                              | What it answers                                                  |
|-------------------------------|------------------------------------|------------------------------------------------------------------|
| `phenology_clean.csv`         | one row per field site             | Full field survey: presence, persistence, flowering time, ecotype |
| `pop_metadata.csv`            | one row per population             | Lookup: `pop → ecotype` (Wall, Grass, Pavement, Tree bed)        |
| `tplant_F5_clean.csv`         | one row per F5 transplant          | Morphology + sampling + alive/above-18cm flags                  |
| `tplant_F6_clean.csv`         | one row per F6 plant               | Sowing/germination/flowering dates + morphology                  |
| `dormancy_clean.csv`          | one row per (F5 parent × run)      | Seed counts, fungi flags, dormancy-test windows                  |

For column-level documentation see `data/README.md` (codebook).

## Status

The repository is mid-migration from a single monolithic `main.qmd` to a
script-based cleaning pipeline plus one Quarto doc per research question
under `analysis/`. The original `main.qmd` still exists at the repo root
during the transition and will be removed once every analysis has been
ported.
