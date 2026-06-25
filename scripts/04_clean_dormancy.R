# Clean the dormancy / germination test data.
#
# Inputs:
#   data/raw/dormancy_count.csv      seed-count measurements per F5 parent x run
#   data/processed/pop_metadata.csv  pop -> ecotype (from 01_clean_phenology)
#
# Output:
#   data/processed/dormancy_clean.csv
#
# Changes vs raw:
#   - All column names snake_case
#   - id_f5_parent typo fix: 165-{4,8,17} -> 156-{4,8,17}
#   - Derived: pop (prefix of id_f5_parent), ecotype (joined from pop_metadata)
#   - has_fungi / has_strong_fungi coerced to logical (raw stores 0/1)
#
# Notes on what is intentionally NOT done here:
#   - germ_ratio not computed: it is an analysis metric and depends on
#     which fungi-exclusion filter the analysis applies.
#   - The F6-link join (dormancy x tplant_F6.id via id_f5_parent) is a
#     many-to-many join that inflates dormancy past its natural grain
#     (one row per parent x run). It belongs in the analysis doc that
#     uses the F6 ID, not in this cleaner.
#   - run -> weeks_elapsed mapping is an analysis-time encoding.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringi)
  library(janitor)
  library(here)
})

dormancy_raw <- read_csv(
  here("data/raw/dormancy_count.csv"),
  na = c("", "na", "NA", "Na"),
  col_types = cols(
    ID_F5_parent                      = col_character(),
    seed_count_germinated             = col_integer(),
    seed_count_total                  = col_integer(),
    has_fungi                         = col_logical(),
    has_strong_fungi                  = col_logical(),
    dormtest_start                    = col_date(),
    dormtest_end                      = col_date(),
    group                             = col_character(),
    run                               = col_character(),
    Notes                             = col_character(),
    seed_count_total_with_black_seeds = col_integer()
  )
)

pop_meta <- read_csv(
  here("data/processed/pop_metadata.csv"),
  show_col_types = FALSE,
  col_types = cols(pop = col_character(), ecotype = col_character())
)

dormancy <- dormancy_raw |>
  clean_names() |>
  mutate(
    id_f5_parent = case_when(
      id_f5_parent == "165-4"  ~ "156-4",
      id_f5_parent == "165-8"  ~ "156-8",
      id_f5_parent == "165-17" ~ "156-17",
      TRUE                     ~ id_f5_parent
    ),
    pop = stri_extract(id_f5_parent, regex = "^.*(?=-)")
  ) |>
  left_join(pop_meta, by = "pop") |>
  select(id_f5_parent, pop, ecotype, run, group,
         dormtest_start, dormtest_end,
         seed_count_germinated, seed_count_total,
         seed_count_total_with_black_seeds,
         has_fungi, has_strong_fungi, notes)

write_csv(dormancy, here("data/processed/dormancy_clean.csv"))

cat("dormancy_clean.csv:", nrow(dormancy), "rows,",
    ncol(dormancy), "cols\n")
cat("  unique parents:        ", dplyr::n_distinct(dormancy$id_f5_parent), "\n")
cat("  unique runs:           ", dplyr::n_distinct(dormancy$run), "\n")
cat("  rows missing ecotype:  ", sum(is.na(dormancy$ecotype)), "\n")
cat("  rows missing total:    ", sum(is.na(dormancy$seed_count_total)), "\n")
cat("  strong fungi excluded: ", sum(dormancy$has_strong_fungi, na.rm = TRUE), "\n")
