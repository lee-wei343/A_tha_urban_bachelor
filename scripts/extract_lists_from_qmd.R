# One-off bootstrap: extract hardcoded ID lists from main.qmd into raw CSVs.
#
# Run once from the repo root:
#     Rscript scripts/extract_lists_from_qmd.R
#
# Produces:
#   data/raw/dead_plants_F5.csv      (was ID_is_not_alive_A_tha vector)
#   data/raw/population_sampling.csv (was Pop_pool_sampled + Pop_indv_sampled)
#
# Safe to delete once main.qmd has been replaced by the new pipeline.
# Kept in git history so the provenance of those raw CSVs is reproducible.

qmd <- readLines("main.qmd")

# --- dead plants list -------------------------------------------------------
start <- grep("^ID_is_not_alive_A_tha <- c\\(", qmd)
stopifnot(length(start) == 1)
end   <- start - 1 + which(qmd[start:length(qmd)] == ")")[1]
ids   <- gsub('[", ]', "", qmd[(start + 1):(end - 1)])
ids   <- ids[nzchar(ids)]
writeLines(c("ID", ids), "data/raw/dead_plants_F5.csv")
cat("dead_plants_F5.csv:", length(ids), "rows\n")

# --- population sampling lists ---------------------------------------------
extract_vec <- function(line) {
  raw <- sub("^[^(]*\\(", "", line)
  raw <- sub("\\)$", "", raw)
  unlist(strsplit(gsub('["[:space:]]', "", raw), ","))
}
pool <- extract_vec(grep('^Pop_pool_sampled <- c\\(', qmd, value = TRUE))
indv <- extract_vec(grep('^Pop_indv_sampled <- c\\(', qmd, value = TRUE))

all_pops <- sort(unique(c(pool, indv)))
df <- data.frame(
  Pop              = all_pops,
  was_pool_sampled = all_pops %in% pool,
  was_indv_sampled = all_pops %in% indv
)
write.csv(df, "data/raw/population_sampling.csv",
          row.names = FALSE, quote = FALSE)
cat("population_sampling.csv:", nrow(df), "rows (",
    sum(df$was_pool_sampled), "pool /",
    sum(df$was_indv_sampled), "indv )\n")
