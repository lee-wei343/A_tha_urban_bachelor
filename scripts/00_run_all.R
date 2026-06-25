# Run the full data-cleaning pipeline (raw -> processed) in order.
#
# Usage from the repo root:
#     Rscript scripts/00_run_all.R
#
# Step 01 (phenology) must run before 02/03/04 because they join on
# data/processed/pop_metadata.csv. Steps 02, 03 and 04 are independent of
# each other and could be parallelised, but their inputs are small so a
# serial run takes only a few seconds.

suppressPackageStartupMessages(library(here))

steps <- c(
  "scripts/01_clean_phenology.R",
  "scripts/02_clean_tplant_F5.R",
  "scripts/03_clean_tplant_F6.R",
  "scripts/04_clean_dormancy.R"
)

for (s in steps) {
  cat("\n--- ", s, " ---\n", sep = "")
  source(here(s), local = TRUE, echo = FALSE)
}

cat("\nPipeline complete. Outputs in data/processed/.\n")
