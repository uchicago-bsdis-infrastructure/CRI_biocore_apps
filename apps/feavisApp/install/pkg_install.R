packages <- c("shinydashboard", "dplyr", "shinyWidgets", "shinyjs", "DT", "shiny", "ggplot2")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
sapply(packages, require, character.only=T)
print(sapply(packages, require, character.only=T))

# BCpackages <- c("clusterProfiler")
# if (length(setdiff(BCpackages, rownames(installed.packages()))) > 0) {
#   source("http://bioconductor.org/biocLite.R")
#   biocLite(setdiff(BCpackages, rownames(installed.packages())))
# }
# sapply(c(packages, BCpackages), require, character.only=T)
# print(sapply(c(packages, BCpackages), require, character.only=T))

trim <- function (x) gsub("^\\s+|\\s+$", "", x)