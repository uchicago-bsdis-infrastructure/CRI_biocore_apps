packages <- c('shiny', 'shinydashboard', 'DT', 'bslib', 'shinyjs', 'dplyr','stringr','readxl','readr','tidyr','stringr','tidyverse','cowplot','patchwork','ggplot2','sp','tibble','shinyWidgets','shinyjs','bslib','KernSmooth','digest')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

BCpackages <- packages
if (length(setdiff(BCpackages, rownames(installed.packages()))) > 0) {
  # source("http://bioconductor.org/biocLite.R")
  # biocLite(setdiff(BCpackages, rownames(installed.packages())))
  BiocManager::install(setdiff(BCpackages, rownames(installed.packages())), update = FALSE, ask = TRUE)
}

# sapply(c(packages, BCpackages), require, character.only=T)

print(sapply(c(packages, BCpackages), require, character.only=T))
