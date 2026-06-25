# Shared helpers for the analysis Quarto documents under analysis/.
#
# Each helper returns a tibble; no global state is mutated. here::here()
# is used for paths so docs render correctly whether the working directory
# is the repo root or analysis/.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(here)
})

# Consistent ecotype colour palette used across plots.
ecotype_colors <- c(
  "Wall"     = "#f8cd37",
  "Grass"    = "#6a176e",
  "Pavement" = "#bc3754",
  "Tree bed" = "#f37819"
)

# Plot styling. Uses generic "serif" rather than "Times New Roman" so docs
# render on Linux/macOS without that exact Windows font installed.
theme_thesis <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x  = ggplot2::element_text(size = 25, family = "serif"),
      axis.title   = ggplot2::element_text(size = 25, family = "serif"),
      legend.text  = ggplot2::element_text(size = 15, family = "serif")
    )
}

#' Load the F5 cleaned table (one row per F5 plant).
load_tplant_F5 <- function() {
  read_csv(
    here("data/processed/tplant_F5_clean.csv"),
    show_col_types = FALSE
  )
}

#' Load the F6 cleaned table, filter to plants that germinated by 2025-07-04,
#' and derive the flowering-time / stratification columns used by the F6
#' analyses. Also imputes 0 for n_shoot_axis and height_stem where missing
#' (matches the assumption in the original notebook that a non-flowering or
#' undeveloped plant counts as zero for those measurements).
prepare_f6_germinated <- function() {
  read_csv(
    here("data/processed/tplant_F6_clean.csv"),
    show_col_types = FALSE
  ) |>
    filter(!not_germinated_til_2025_07_04) |>
    mutate(
      light_till_ft       = as.integer(ft - brought_to_greenhouse),
      stratification_days = as.integer(brought_to_greenhouse - sowing_date_then_stratification),
      ft_early            = if_else(light_till_ft >= 1, 1L, 0L),
      light_till_ft_maxed = replace_na(light_till_ft, 100L),
      n_shoot_axis        = replace_na(n_shoot_axis, 0L),
      height_stem         = replace_na(height_stem, 0L)
    )
}

#' Load the dormancy table, attach the F6 plant ID (many-to-many join via
#' id_f5_parent), exclude strong-fungi rows, and compute germ_ratio +
#' weeks_elapsed. Returns one row per (parent x run x F6 child).
prepare_dormancy_for_analysis <- function() {
  dormancy <- read_csv(
    here("data/processed/dormancy_clean.csv"),
    show_col_types = FALSE
  )

  f6 <- read_csv(
    here("data/processed/tplant_F6_clean.csv"),
    show_col_types = FALSE
  )

  dormancy |>
    left_join(
      f6 |> select(id, id_f5_parent),
      by = "id_f5_parent",
      relationship = "many-to-many"
    ) |>
    select(id, id_f5_parent, pop, ecotype, everything()) |>
    filter(has_strong_fungi == FALSE) |>
    mutate(
      germ_ratio = case_when(
        seed_count_germinated == 0                ~ 0,
        seed_count_germinated == seed_count_total ~ 1,
        TRUE ~ seed_count_germinated / seed_count_total
      ),
      weeks_elapsed = factor(case_when(
        run == "1" ~ 0,
        run == "2" ~ 3,
        run == "3" ~ 6
      )),
      run     = as.factor(run),
      group   = as.factor(group),
      pop     = as.factor(pop),
      id      = as.factor(id),
      ecotype = as.factor(ecotype)
    )
}
