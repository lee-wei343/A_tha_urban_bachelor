# Clean the F6 (next generation) tplant observations.
#
# Inputs:
#   data/raw/tplant_F6_observations.csv
#   data/processed/pop_metadata.csv      pop -> ecotype (from 01_clean_phenology)
#
# Output:
#   data/processed/tplant_F6_clean.csv
#
# Changes vs raw:
#   - All column names snake_case (janitor::clean_names)
#   - Dates parsed: ft, sowing_date_then_stratification, brought_to_greenhouse
#   - not_germinated_til_* logical flags: empty -> FALSE (no flag means
#     germinated)
#   - leaf_shape / leaf_edge values normalised to upper case (matches F5)
#   - ecotype joined from pop_metadata
#   - elongated, serrated binary cols added (matches F5 schema)
#   - Raw `pop` validated against prefix of id_f5_parent; mismatches reported
#
# Notes on what is intentionally NOT done here:
#   - n_shoot_axis and height_stem are left NA where missing. The original
#     notebook imputed 0, but that conflates "not measured" with "zero".
#     Analyses that want zero-imputation should call replace_na(0) explicitly.
#   - Per-analysis derived columns (FT_early, light_till_FT,
#     stratification_days, light_till_FT_maxed) live in the flowering-time
#     analysis doc, not here.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringi)
  library(janitor)
  library(here)
})

tplant_F6_raw <- read_csv(
  here("data/raw/tplant_F6_observations.csv"),
  na = c("", "na", "NA", "Na"),
  col_types = cols(
    ID                              = col_character(),
    ID_F5_parent                    = col_character(),
    Pop                             = col_character(),
    Individuum                      = col_character(),
    total_repl_in_pop               = col_integer(),
    Tray                            = col_character(),
    Column                          = col_character(),
    Row                             = col_character(),
    FT                              = col_date(),
    sowing_date_then_stratification = col_date(),
    brought_to_greenhouse           = col_date(),
    not_germinated_til_2025_06_02   = col_logical(),
    not_germinated_til_2025_06_04   = col_logical(),
    not_germinated_til_2025_07_04   = col_logical(),
    leaf_shape                      = col_character(),
    leaf_edge                       = col_character(),
    n_shoot_axis                    = col_integer(),
    height_stem                     = col_integer(),
    notes                           = col_character()
  )
)

pop_meta <- read_csv(
  here("data/processed/pop_metadata.csv"),
  show_col_types = FALSE,
  col_types = cols(pop = col_character(), ecotype = col_character())
)

# --- cleaning ---------------------------------------------------------------
tplant_F6 <- tplant_F6_raw |>
  clean_names() |>
  mutate(
    pop_from_parent = stri_extract(id_f5_parent, regex = "^.*(?=-)"),
    pop_mismatch    = !is.na(pop) & !is.na(pop_from_parent) &
                      pop != pop_from_parent
  )

mismatches <- sum(tplant_F6$pop_mismatch, na.rm = TRUE)
if (mismatches > 0) {
  warning(mismatches,
          " rows have raw Pop != prefix of ID_F5_parent. ",
          "Using parent-derived Pop.")
}

tplant_F6 <- tplant_F6 |>
  mutate(
    pop = coalesce(pop_from_parent, pop),
    not_germinated_til_2025_06_02 = coalesce(not_germinated_til_2025_06_02, FALSE),
    not_germinated_til_2025_06_04 = coalesce(not_germinated_til_2025_06_04, FALSE),
    not_germinated_til_2025_07_04 = coalesce(not_germinated_til_2025_07_04, FALSE),
    leaf_shape = case_when(
      leaf_shape == "o" ~ "O",
      leaf_shape == "l" ~ "L",
      TRUE              ~ leaf_shape
    ),
    leaf_edge = case_when(
      leaf_edge == "s" ~ "S",
      leaf_edge == "g" ~ "G",
      TRUE             ~ leaf_edge
    ),
    elongated = case_when(leaf_shape == "L" ~ 1L,
                          leaf_shape == "O" ~ 0L,
                          TRUE              ~ NA_integer_),
    serrated  = case_when(leaf_edge  == "S" ~ 1L,
                          leaf_edge  == "G" ~ 0L,
                          TRUE              ~ NA_integer_)
  ) |>
  left_join(pop_meta, by = "pop") |>
  select(id, id_f5_parent, pop, individuum, ecotype,
         tray, row, column,
         ft, sowing_date_then_stratification, brought_to_greenhouse,
         not_germinated_til_2025_06_02,
         not_germinated_til_2025_06_04,
         not_germinated_til_2025_07_04,
         leaf_shape, leaf_edge, n_shoot_axis, height_stem,
         elongated, serrated,
         total_repl_in_pop, notes)

# --- write & summary --------------------------------------------------------
write_csv(tplant_F6, here("data/processed/tplant_F6_clean.csv"))

cat("tplant_F6_clean.csv:", nrow(tplant_F6), "rows,",
    ncol(tplant_F6), "cols\n")
cat("  germinated by 2025-07-04:    ",
    sum(!tplant_F6$not_germinated_til_2025_07_04), "\n")
cat("  rows missing ecotype:        ",
    sum(is.na(tplant_F6$ecotype)), "\n")
cat("  pop != id_f5_parent prefix:  ", mismatches, "\n")
