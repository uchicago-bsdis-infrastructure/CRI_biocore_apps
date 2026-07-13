### Function to slim down RDS files for scVizApp!!

fnToSlimRDS = function(rdsPath){
  cat(sprintf('Reading the RDS:%s', rdsPath))
  
  rds = readRDS(rdsPath)
  DefaultAssay(rds) = 'RNA'
  print('Slimming down RDS with DietSeurat')
  slim_seurat <- DietSeurat(
    object = rds, 
    assays = "RNA", 
    layers = c("data","scale.data"),
    dimreducs = Reductions(rds),
    graphs = Graphs(rds)
  )
  print('Completed slimming down of RDS file')
  name = strsplit(rdsPath, "\\.rds")[[1]][1]
  print('Saving slimmed RDS file')
  saveRDS(slim_seurat, paste0(name, '_slimmed.rds'), compress = F)
  cat(sprintf('Slimmed RDS file is saved in the follwoing path: %s', paste0(name, '_slimmed.rds')))
}

# Example run
# fnToSlimRDS(rdsPath = '/gpfs/data/biocore-analysis/CRI-BIO-842-HMS-Kulkarni-yli-zyren/Res29samp_integration_wHippo_alpha_beta_epsilon_wExpCond8_rmOutlier.rds')
