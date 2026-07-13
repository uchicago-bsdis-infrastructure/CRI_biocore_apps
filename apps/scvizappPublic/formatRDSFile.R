##  This is the Script to update RDS file to scVisApp Input format for user-interface application for Single cell data visualization
## Developed by Geetha Priyanka Yerradoddi Mar 2025
##------------------------------------------------------------------------------------------##
## Libraries (CHANGE NOTHING) ---
library(Seurat)
library(stringr)
library(dplyr)
library(tidyr)
# Requirements - change columns to clusters, expCond and orig.ident formats
# Change special characters -,/,|,space to _
# Inputs ------
# 1. rdspath - Full path of RDS file you want to use as input for scVisApp
# 2. column_words - Meta Data column names that are present in RDS file to be used for VISUALIZATIONS (that are NOT names under Cluster or expCond or orig.ident)

##------------------------------------------------------------------------------------------##
formatRDSFile = function(rdspath, column_words = character(0)){
  # dirpath <- dirname(rdspath)
  # Step 1: Changing all columns into scVisApp readables
  # splitRDSpath <- strsplit(rdspath, ".rds")[[1]]
  # rds = readRDS(as.character(rdspath))
  metadata = rdspath@meta.data
  check = startsWith(colnames(rdspath@meta.data),'expCond')
  i = length(check[check == TRUE])
  
  # Keywords to match (case-insensitive)
  # keywords <- c("sample", "treatment", "class", "type", "subtype","condition")
  keywords <- c("sample", "treatment", "class","condition")
  keywords = unique(c(keywords, column_words))
  # Finding the columns with mentioned keywords
  cols_to_rename <- which(sapply(names(metadata), function(col) {
  any(grepl(paste(keywords, collapse = "|"), col, ignore.case = TRUE))
  }))
  
  # Rename matching columns to expCond etc.
  if (length(cols_to_rename) > 0) {
  new_names <- paste0("expCond", i + (1:length(cols_to_rename)))
  names(metadata)[cols_to_rename] <- new_names
  }
  
  # Most special characters are included
  special_chars_pattern <- "[-/|\\ +]"
  
  # Step 2: Replace special characters in all values of the dataframe
  metadata[] <- lapply(metadata, function(x) {
    if (is.character(x)) {
      gsub(special_chars_pattern, "_", x)  # Replace special characters in character columns
    } else {
      x  # Leave other types unchanged (e.g., numeric)
    }
  })
  
  rdspath@meta.data <- metadata
  SeuratObject::DefaultAssay(rdspath) = 'RNA'
  # rdspath = Seurat::Seurat::ScaleData(object = rdspath, do.scale = T, do.center = T, features = rownames(rdspath))
  # If the object has sample separated counts or data or scaled.data
  # rds = SeuratObject::JoinLayers(rds, assay = 'RNA')
  # saveRDS(rds, paste0(splitRDSpath,'_updated.rds'))
  return(rdspath)
}

### How to run the script ----
# formatRDSFile(rdspath = '<RDS file Path>', column_words = '<Columns to use for Visualizations>')

# Example formatRDSFile(rdspath = 'Projects/cytof/GSE267714_MC38_WT.rds', column_words = c(''))
