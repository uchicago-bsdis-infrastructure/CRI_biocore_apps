options(repos = c(CRAN = "https://cloud.r-project.org"))

shiny_deps <- c("sass", "bslib", "shiny")
cran_pkgs <- c("dplyr", "tibble", "tidyr")
bioc_pkgs <- c("ComplexHeatmap", "circlize")

install.packages("BiocManager")
install.packages(shiny_deps, dependencies = TRUE)
install.packages(cran_pkgs, dependencies = TRUE)
BiocManager::install(bioc_pkgs, update = FALSE, ask = FALSE)

stopifnot(
  requireNamespace("shiny", quietly = TRUE),
  requireNamespace("ComplexHeatmap", quietly = TRUE),
  requireNamespace("dplyr", quietly = TRUE)
)
