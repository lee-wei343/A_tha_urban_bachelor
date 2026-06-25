# Clean the phenology field-survey data.
#
# Input:  data/raw/phenology_field.csv
# Output: data/processed/phenology_clean.csv   (full table, cleaned column names)
#         data/processed/pop_metadata.csv      (Pop + ecotype lookup table,
#                                               consumed by 02_clean_tplant_F5.R
#                                               and 03_clean_tplant_F6.R)
#
# Changes vs raw:
#   - snake_case column names via janitor::clean_names()
#   - Site_ID -> pop (matches the "Pop" naming used in the tplant tables)
#   - type -> ecotype, values title-cased (wall -> Wall, grass -> Grass, ...)
#   - pop coerced to character (it is a categorical identifier, not a number)
#
# Other columns are left untouched on purpose: downstream analysis decides
# the appropriate type (date, factor, numeric) for the question being asked.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(janitor)
  library(here)
})

raw <- read_csv(
  here("data/raw/phenology_field.csv"),
  show_col_types = FALSE
)

phenology <- raw |>
  clean_names() |>
  rename(pop = site_id, ecotype = type) |>
  mutate(
    pop     = as.character(pop),
    ecotype = str_to_title(ecotype)
  )

dir.create(here("data/processed"), showWarnings = FALSE, recursive = TRUE)

write_csv(phenology, here("data/processed/phenology_clean.csv"))
cat("phenology_clean.csv:", nrow(phenology), "rows,",
    ncol(phenology), "cols\n")

pop_metadata <- phenology |>
  distinct(pop, ecotype)

write_csv(pop_metadata, here("data/processed/pop_metadata.csv"))
cat("pop_metadata.csv:", nrow(pop_metadata), "rows (",
    sum(is.na(pop_metadata$ecotype)), "missing ecotype )\n")
