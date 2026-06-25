# Clean the F5 (transplanted) tplant observations.
#
# Inputs:
#   data/raw/tplant_F5_observations.csv  raw plant-level measurements
#   data/raw/dead_plants_F5.csv          IDs flagged not-alive
#   data/raw/F5_below_18cm.csv           IDs whose stem was below 18 cm
#   data/raw/population_sampling.csv     pool / individual sampling per pop
#   data/processed/pop_metadata.csv      pop -> ecotype (from 01_clean_phenology)
#
# Output:
#   data/processed/tplant_F5_clean.csv
#
# Changes vs raw:
#   - All column names snake_case (via janitor::clean_names)
#   - Rows missing id are dropped
#   - id typo fix: 165-{1,2,3} -> 156-{1,2,3}
#   - Derived: pop, replicate (split out of id)
#   - Leaf shape / edge values normalised to upper case
#   - Joined flags + derived columns: is_alive_a_tha, is_above_18cm,
#     was_pool_sampled, was_indv_sampled, sampletype, ecotype,
#     total_repl_in_pop, pop_above_3, pop_below_15, elongated, serrated
#
# All plants are emitted; downstream filters on is_alive_a_tha when needed.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringi)
  library(janitor)
  library(here)
})

# --- raw inputs -------------------------------------------------------------
tplant_raw <- read_csv(
  here("data/raw/tplant_F5_observations.csv"),
  na = c("", "Na", "n", "na", "NA"),
  col_types = cols(
    ID           = col_character(),
    Tray         = col_character(),
    Row          = col_integer(),
    Column       = col_integer(),
    n_shoot_axis = col_integer(),
    Leaf_shape   = col_character(),
    Leaf_edge    = col_character(),
    Comments     = col_character()
  )
)

dead_ids <- read_csv(
  here("data/raw/dead_plants_F5.csv"),
  show_col_types = FALSE
)$ID

below_18 <- read_csv(
  here("data/raw/F5_below_18cm.csv"),
  show_col_types = FALSE
) |>
  clean_names()  # single column: f5_is_below_18cm

sampling <- read_csv(
  here("data/raw/population_sampling.csv"),
  show_col_types = FALSE,
  col_types = cols(
    Pop              = col_character(),
    was_pool_sampled = col_logical(),
    was_indv_sampled = col_logical()
  )
) |>
  clean_names()

pop_meta <- read_csv(
  here("data/processed/pop_metadata.csv"),
  show_col_types = FALSE,
  col_types = cols(pop = col_character(), ecotype = col_character())
)

# --- cleaning ---------------------------------------------------------------
tplant <- tplant_raw |>
  clean_names() |>
  filter(!is.na(id)) |>
  mutate(
    # 3-entry typo fix; documented inline rather than in a 3-row CSV
    id = case_when(
      id == "165-1" ~ "156-1",
      id == "165-2" ~ "156-2",
      id == "165-3" ~ "156-3",
      TRUE          ~ id
    ),
    pop       = stri_extract(id, regex = "^.*(?=-)"),
    replicate = stri_extract(id, regex = "(?<=-).*$"),
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
    is_alive_a_tha = !(id %in% dead_ids),
    is_above_18cm  = !(id %in% below_18$f5_is_below_18cm)
  ) |>
  left_join(sampling, by = "pop") |>
  mutate(
    was_pool_sampled = coalesce(was_pool_sampled, FALSE),
    was_indv_sampled = coalesce(was_indv_sampled, FALSE),
    sampletype = case_when(
       was_pool_sampled &  was_indv_sampled ~ "Pool_and_Indv",
       was_pool_sampled & !was_indv_sampled ~ "Pool",
      !was_pool_sampled &  was_indv_sampled ~ "Indv",
      TRUE                                  ~ "Not_sampled"
    )
  ) |>
  left_join(pop_meta, by = "pop")

# --- per-population aggregates over alive plants ---------------------------
alive_counts <- tplant |>
  filter(is_alive_a_tha) |>
  count(pop, name = "total_repl_in_pop")

tplant <- tplant |>
  left_join(alive_counts, by = "pop") |>
  mutate(
    total_repl_in_pop = coalesce(total_repl_in_pop, 0L),
    pop_above_3       = total_repl_in_pop > 3,
    pop_below_15      = total_repl_in_pop < 15,
    elongated = case_when(leaf_shape == "L" ~ 1L,
                          leaf_shape == "O" ~ 0L,
                          TRUE              ~ NA_integer_),
    serrated  = case_when(leaf_edge  == "S" ~ 1L,
                          leaf_edge  == "G" ~ 0L,
                          TRUE              ~ NA_integer_)
  ) |>
  select(id, pop, replicate, ecotype,
         tray, row, column,
         leaf_shape, leaf_edge, n_shoot_axis,
         elongated, serrated,
         is_alive_a_tha, is_above_18cm,
         was_pool_sampled, was_indv_sampled, sampletype,
         total_repl_in_pop, pop_above_3, pop_below_15,
         comments)

# --- write & summary --------------------------------------------------------
write_csv(tplant, here("data/processed/tplant_F5_clean.csv"))

cat("tplant_F5_clean.csv:", nrow(tplant), "rows,",
    ncol(tplant), "cols\n")
cat("  alive:                 ", sum(tplant$is_alive_a_tha), "\n")
cat("  unique pops:           ", dplyr::n_distinct(tplant$pop), "\n")
cat("  rows missing ecotype:  ", sum(is.na(tplant$ecotype)), "\n")
