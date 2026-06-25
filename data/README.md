# Dataset codebook

This document describes the data files used and produced by the pipeline.

- `raw/`       — original CSVs as collected. Never edited by hand.
- `processed/` — cleaned tables built deterministically from `raw/` by the
  scripts under `../scripts/`. Run `Rscript scripts/00_run_all.R` from the
  repo root to rebuild them.

Conventions used in the processed tables:

- All column names are `snake_case`.
- Identifiers (`pop`, `id`, `id_f5_parent`, etc.) are stored as
  **character**, never numeric — they are labels, not measurements.
- `pop` is the join key across every processed table.
- Dates are stored as ISO `YYYY-MM-DD`.
- Logical columns are `TRUE`/`FALSE`. `NA` always means "missing /
  unmeasured", never zero.

Some descriptions in the phenology section below are best inferences from
column names; please verify and refine the ones marked `<verify>` against
the original field protocol.

---

## raw/

### `tplant_F5_observations.csv`

Plant-level morphology measurements on the F5 transplanted population.
One row per plant; identifier format `pop-replicate`.

### `tplant_F6_observations.csv`

Plant-level morphology + phenology measurements on the F6 generation.
One row per plant; identifier is a project-issued sequential code
(`2025-NNNN`); `ID_F5_parent` links back to an F5 plant.

### `phenology_field.csv`

Field-survey table covering the source populations. One row per field
site (`Site_ID`).

### `dormancy_count.csv`

Seed-germination test results, one row per (`ID_F5_parent`, `run`)
combination across the dormancy-loss test runs.

### `F5_below_18cm.csv`

Single-column list of F5 plant IDs whose stem stayed below 18 cm.
Used as a flag in the F5 cleaning step.

### `dead_plants_F5.csv`

Single-column list of F5 plant IDs that did not survive (lifted out of
`main.qmd` so the analysis notebook no longer carries data).

### `population_sampling.csv`

Per-population record of which sampling method(s) were applied:
`was_pool_sampled`, `was_indv_sampled`. A population may have either,
both, or neither.

---

## processed/

### `pop_metadata.csv`

Lookup table: one row per source population.

| column   | type      | description                                           |
|----------|-----------|-------------------------------------------------------|
| pop      | character | Population identifier                                 |
| ecotype  | character | Microhabitat type: `Wall`, `Grass`, `Pavement`, `Tree bed` |

This is the canonical `pop → ecotype` lookup; every other processed
table joins against it via `pop`.

---

### `phenology_clean.csv`

Cleaned field-survey table. One row per field site.

| column                      | type       | description                                                              |
|-----------------------------|------------|--------------------------------------------------------------------------|
| pop                         | character  | Population identifier (renamed from `Site_ID`)                           |
| area                        | character  | Geographic area name                                                     |
| localization_id             | character  | Within-area locator                                                      |
| ecotype                     | character  | Microhabitat type (`Wall`, `Grass`, `Pavement`, `Tree bed`)              |
| destroyed                   | character  | Site status (e.g. `Exist`, `Destroyed`) `<verify>`                       |
| outliers_soil               | character  | Soil-sampling status (e.g. `Not sampled`) `<verify>`                     |
| sowing_1st                  | character  | First sowing date (raw format `MM/YYYY`) `<verify>`                      |
| sowing_2nd                  | character  | Second sowing date or `no` `<verify>`                                    |
| germ_2ndyear                | character  | Second-year germination observed (`Yes`/`No`) `<verify>`                 |
| presence_april_22/23/24     | character  | Presence flag at April census `<verify>`                                 |
| persistence_1/2             | integer    | Persistence scores `<verify scale>`                                      |
| feb_22, april_22, october_22, november_22, april_23 | integer | Plant counts at the given census `<verify>`           |
| ft_04_23                    | integer    | Flowering-time observation Apr 2023 (raw `FT-04-23`) `<verify>`          |
| cohort                      | character  | Cohort label (e.g. `spring`) `<verify>`                                  |
| first_ft_julianday          | integer    | Julian day of first observed flowering                                   |
| x100_ft_julianday           | integer    | Julian day of 100% flowering (raw `100_FT_julianday`)                    |
| ft_variation                | integer    | Spread of flowering-time observations `<verify>`                         |
| harvested_leaves            | character  | Leaf-harvest date (raw `DD/MM/YY`) `<verify>`                            |
| harvested_seeds             | character  | Seed-harvest date (raw `DD/MM/YY`) `<verify>`                            |
| ft_10_2023                  | integer    | Flowering-time observation Oct 2023 (raw `FT_10-2023`) `<verify>`        |
| end_march_24                | integer    | End-of-March 2024 plant count `<verify>`                                 |

Dates above are left as raw strings on purpose — the cleaner does not
guess between `MM/YYYY`, `DD/MM/YY`, and `YYYY-MM-DD`. Convert them in
the analysis script that needs them.

---

### `tplant_F5_clean.csv`

One row per F5 (transplanted) plant.

| column              | type      | description                                                            | NA means                          |
|---------------------|-----------|------------------------------------------------------------------------|-----------------------------------|
| id                  | character | Plant identifier `pop-replicate`                                       | never NA (rows without id dropped)|
| pop                 | character | Population identifier                                                  | never                             |
| replicate           | character | Replicate number within the population                                 | never                             |
| ecotype             | character | Joined from `pop_metadata`                                             | population not in field survey    |
| tray, row, column   | character / integer | Greenhouse position                                          | not recorded                      |
| leaf_shape          | character | `L` (linear/elongated) or `O` (ovate)                                  | not scored                        |
| leaf_edge           | character | `S` (serrated) or `G` (smooth)                                         | not scored                        |
| n_shoot_axis        | integer   | Number of shoot axes                                                   | not measured                      |
| elongated           | integer   | Binary `1`/`0` derived from `leaf_shape == "L"` / `"O"`                | leaf_shape NA                     |
| serrated            | integer   | Binary `1`/`0` derived from `leaf_edge == "S"` / `"G"`                 | leaf_edge NA                      |
| is_alive_a_tha      | logical   | `FALSE` for IDs in `dead_plants_F5.csv`, `TRUE` otherwise              | never                             |
| is_above_18cm       | logical   | `FALSE` for IDs in `F5_below_18cm.csv`, `TRUE` otherwise               | never                             |
| was_pool_sampled    | logical   | Population was pool-sampled                                            | never                             |
| was_indv_sampled    | logical   | Population was individually sampled                                    | never                             |
| sampletype          | character | One of `Pool`, `Indv`, `Pool_and_Indv`, `Not_sampled`                  | never                             |
| total_repl_in_pop   | integer   | Count of **alive** replicates in the same population                   | never (0 if no alive replicates)  |
| pop_above_3         | logical   | `total_repl_in_pop > 3`                                                | never                             |
| pop_below_15        | logical   | `total_repl_in_pop < 15`                                               | never                             |
| comments            | character | Free-text observation notes                                            | no note                           |

All plants are emitted, including non-alive and below-18 cm — analyses
filter on `is_alive_a_tha` / `is_above_18cm` explicitly.

---

### `tplant_F6_clean.csv`

One row per F6 plant.

| column                                  | type      | description                                                           | NA means                       |
|-----------------------------------------|-----------|-----------------------------------------------------------------------|--------------------------------|
| id                                      | character | F6 plant identifier (`YYYY-NNNN`)                                     | never                          |
| id_f5_parent                            | character | Link to the F5 parent plant (matches `tplant_F5_clean.id`)            | never                          |
| pop                                     | character | Population identifier (prefix of `id_f5_parent`)                      | never                          |
| individuum                              | character | Replicate index within population                                     | never                          |
| ecotype                                 | character | Joined from `pop_metadata`                                            | population not in field survey |
| tray, row, column                       | character | Greenhouse position                                                   | not recorded                   |
| ft                                      | date      | Flowering-time observation date                                       | not flowered (or not observed) |
| sowing_date_then_stratification         | date      | Sowing date (start of stratification)                                 | not sown                       |
| brought_to_greenhouse                   | date      | Date plant was moved to greenhouse                                    | not moved                      |
| not_germinated_til_2025_06_02 / _06_04 / _07_04 | logical | `TRUE` if plant had not germinated by the named date          | never (`NA` coerced to `FALSE`)|
| leaf_shape                              | character | `L` / `O`                                                             | not scored                     |
| leaf_edge                               | character | `S` / `G`                                                             | not scored                     |
| n_shoot_axis                            | integer   | Number of shoot axes                                                  | not measured                   |
| height_stem                             | integer   | Stem height (cm)                                                      | not measured                   |
| elongated, serrated                     | integer   | Binary leaf morphology, derived (matches F5 schema)                   | underlying value NA            |
| total_repl_in_pop                       | integer   | Population replicate count carried over from raw                      | never                          |
| notes                                   | character | Free-text observation notes                                           | no note                        |

`n_shoot_axis` and `height_stem` are **kept NA** when missing — the
original notebook imputed 0, but that conflated "not measured" with
"zero". Analyses that need zero-imputation should do
`replace_na(0)` explicitly.

---

### `dormancy_clean.csv`

One row per (F5 parent, dormancy-test run). 3 runs per parent at most.

| column                            | type      | description                                                       | NA means              |
|-----------------------------------|-----------|-------------------------------------------------------------------|-----------------------|
| id_f5_parent                      | character | F5 parent plant (matches `tplant_F5_clean.id`)                    | never                 |
| pop                               | character | Population identifier (prefix of `id_f5_parent`)                  | never                 |
| ecotype                           | character | Joined from `pop_metadata`                                        | parent pop not in survey |
| run                               | character | Run number (`1`, `2`, `3`) — see Notes                            | never                 |
| group                             | character | Block / batch identifier within a run                             | never                 |
| dormtest_start                    | date      | Start date of the dormancy test                                   | not recorded          |
| dormtest_end                      | date      | End date of the dormancy test                                     | not recorded          |
| seed_count_germinated             | integer   | Seeds that germinated during the run                              | not counted           |
| seed_count_total                  | integer   | Total seeds in the test                                           | not counted           |
| seed_count_total_with_black_seeds | integer   | Total including black (non-viable) seeds                          | not counted           |
| has_fungi                         | logical   | Any fungal contamination observed                                 | not assessed          |
| has_strong_fungi                  | logical   | Strong fungal contamination (analyses typically filter on this)   | not assessed          |
| notes                             | character | Free-text observation notes                                       | no note               |

Notes on this table:

- The germination ratio (`seed_count_germinated / seed_count_total`) is
  intentionally **not** precomputed — it depends on which fungi filter
  the analysis applies (`has_strong_fungi == FALSE`, or stricter).
- The F6-plant link (`tplant_F6_clean.id` via `id_f5_parent`) is a
  many-to-many join (one parent → multiple F6 children) and would
  inflate dormancy past its measurement grain. The analysis doc that
  uses it does the join itself.
- `run` is currently encoded `1`/`2`/`3`. The mapping to elapsed weeks
  (`1`→0, `2`→3, `3`→6) is an analysis convention applied where needed.
