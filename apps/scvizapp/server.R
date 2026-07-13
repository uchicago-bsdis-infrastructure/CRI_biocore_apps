library(shiny)
library(Seurat)
library(ggplot2)
library(patchwork)
library(cowplot)
library(tibble)
# library(presto)
library(dittoSeq)
library(Polychrome)
library(viridis)
library(viridisLite)
options(warn = -1)

options(shiny.maxRequestSize = 30 * 1024 ^ 3)
## trim function used for comparison group names' processing
trim <- function (x)
  gsub("^\\s+|\\s+$", "", x)
source('formatRDSFile.R')
# setwd('/Users/geethapriyanka/Projects/cytof/CytoF_Data_Analysis/') #Remove before push
## ---------------------------------------------------------------------------- ##

get_discrete_palette <- function(n, package = "Default", palette_name = NULL) {
  
  if (is.null(n) || n < 1) n <- 1
  
  cols <- switch(package,
                 
                 "Default" = NULL,   # let Seurat pick default (ggplot hue_pal)
                 
                 "dittoSeq" = {
                   all_cols <- dittoSeq::dittoColors()   # 40 colors
                   if (n <= length(all_cols)) {
                     all_cols[seq_len(n)]
                   } else {
                     rep(all_cols, length.out = n)
                   }
                 },
                 
                 "Polychrome" = {
                   pal_func <- switch(palette_name %||% "glasbey",
                                      "glasbey"  = Polychrome::glasbey.colors,
                                      "alphabet" = Polychrome::alphabet.colors,
                                      "kelly"    = Polychrome::kelly.colors,
                                      "dark"     = Polychrome::dark.colors,
                                      "light"    = Polychrome::light.colors,
                                      Polychrome::glasbey.colors
                   )
                   max_n <- switch(palette_name %||% "glasbey",
                                   "glasbey" = 32, "alphabet" = 26, "kelly" = 22,
                                   "dark" = 24, "light" = 24, 32
                   )
                   as.character(pal_func(min(n, max_n)))
                 },
                 
                 NULL   # fallback: default
  )
  
  unname(cols)
}

get_continuous_palette <- function(package = "Default", palette_name = NULL) {
  
  switch(package,
         
         "Default" = c("lightgrey", "blue"),   # Seurat's default
         
         "viridis" = {
           opt <- switch(palette_name %||% "viridis",
                         "viridis" = "D", "magma" = "A", "inferno" = "B",
                         "plasma"  = "C", "cividis" = "E", "turbo" = "H",
                         "mako"    = "G", "rocket" = "F",
                         "D"
           )
           viridis::viridis(100, option = opt)
         },
         
         c("lightgrey", "blue")
  )
}

## ---------------------------------------------------------------------------- ##
# Analysis Description
metadata_literature_summary_auto <- function(rds_path, max_unique = 10) {
  # Load RDS
  obj <- rds_path
  meta <- obj@meta.data
  
  # Exclude unwanted columns
  meta <- meta[, !grepl("nCount|nFeature|percent", colnames(meta)), drop = FALSE]
  
  # Select relevant metadata columns
  # relevant_cols <- grep("expCond|orig.ident|cluster|Cluster|cell|Cell|idents|Idents", colnames(meta), value = TRUE)
  # meta <- meta[, relevant_cols, drop = FALSE]
  
  # Function to auto-generate a clean description per column
  get_description <- function(col) {
    col_lower <- tolower(col)
    
    if (str_detect(col_lower, "orig.ident")) {
      return("Indicates the original identity or sample name in the dataset, corresponding to the initial dataset/experimental replicates.")
      
    } else if (str_detect(col_lower, "expcond")) {
      # detect number if present (e.g., expCond1, expCond2)
      num <- str_extract(col_lower, "\\d+")
      if (!is.na(num)) {
        return(paste0("Specifies experimental condition ", num, 
                      " associated with each cell, such as treatment, genotype, or timepoint."))
      } else {
        return("Specifies the experimental condition assigned to each cell (e.g., Control, KO, Treatment). Used for comparative analyses.")
      }
      
    } else if (str_detect(col_lower, "cluster")) {
      return("Represents the cluster identity or group assignment for each cell, typically derived from unsupervised clustering. Each label corresponds to a distinct transcriptional population.")
      
  # Build summary 
    } else if (str_detect(col_lower, "celltype|cell_type|cell|Cell|cellType|type|Type")) {
      return("Indicates the annotated cell type assigned to each cell or cluster based on gene expression markers or reference mapping.")
      
    } else {
      return(paste("Metadata column", col, "containing experimental or grouping information per cell."))
    }
  }
  table
  summary_tbl <- tibble(
    Column = colnames(meta),
    Description = sapply(colnames(meta), get_description),
    `Values` = sapply(meta, function(x) {
      ux <- unique(x)
      ux <- ux[!is.na(ux)]
      ux <- stringr::str_sort(ux, numeric = TRUE)
      paste(ux, collapse = ", ")
    })
  )
  
  return(summary_tbl)
}
# Cell Summary Table
cluster_summary <- function(data, col, row) {
  # data = rds_plotdata()
  print("2. Summarizing Metadata in Cohort Summary Tab")
  Seurat::DefaultAssay(data)   <- "RNA"
  ident_call = row
  
  data@meta.data[] <- lapply(data@meta.data, function(x) {
    if (is.character(x)) {
      gsub("_", ".", x)
    } else {
      x
    }
  })
  
  ### Function from scRICA table summary
  sprintf("Selected %s as Idents:", ident_call)
  Idents(data) = data@meta.data[[row]]
  clusterCellNo                  <-
    as.data.frame(table(Seurat::Idents(data)))
  
  
  data$clusterExpCond  <-
    paste(Seurat::Idents(data), data@meta.data[[col]], sep = '_')
  
  clusterCellExpNo               <-
    as.data.frame(table(data@meta.data$clusterExpCond))
  
  clusterCellExpNo$cluster       <-
    sapply(strsplit(as.character(clusterCellExpNo$Var1), split = '_'), '[[', 1)
  
  clusterCellExpNo$exp           <-
    sapply(strsplit(as.character(clusterCellExpNo$Var1), split = '_'), tail, 1)
  
  clusterCellExpNoWide           <-
    reshape2::dcast(data = clusterCellExpNo, cluster ~ exp, value.var = 'Freq')
  
  clusterCellExpNoWide[is.na(clusterCellExpNoWide)] <- 0
  clusterCellExpNoWidePer        <- clusterCellExpNoWide
  
  clusterCellExpNoWideColSum     <-
    colSums(clusterCellExpNoWidePer %>% dplyr::select(-cluster))
  for (i in 2:dim(clusterCellExpNoWidePer)[2]) {
    clusterCellExpNoWidePer[, i]      <-
      round(clusterCellExpNoWidePer[, i] * 100 / clusterCellExpNoWideColSum[i -1],
            digits = 2)
  }
  print("2.2 Caluclating cell distribution and Proportions")
  clusterCellNoComb1             <-
    merge(clusterCellNo,
          clusterCellExpNoWide,
          by.x = 'Var1',
          by.y = 'cluster')
  clusterCellNoComb              <-
    merge(clusterCellNoComb1,
          clusterCellExpNoWidePer,
          by.x = 'Var1',
          by.y = 'cluster')
  colnames(clusterCellNoComb)    <-
    c('clusters', 'cellNo', paste('cellNo', colnames(clusterCellNoComb)[-c(1, 2)], sep = '_'))
  colnames(clusterCellNoComb)    <-
    gsub(
      pattern = '\\.x$',
      replacement = '',
      x = colnames(clusterCellNoComb)
    )
  colnames(clusterCellNoComb)    <-
    gsub(
      pattern = '\\.y$',
      replacement = '_Per',
      x = colnames(clusterCellNoComb)
    )
  
  colnames(clusterCellNoComb)    <-
    gsub(
      pattern = '-',
      replacement = '_',
      x = colnames(clusterCellNoComb)
    )
  print(clusterCellNoComb)
  return(clusterCellNoComb)
}

# Adding BarPlot with cell Proportions
plot_cluster_barplot <- function(cluster_summary,
                                 selectedCol2 = NULL,
                                 expCondNameOrder = NULL,
                                 perPlotHeight = NULL,
                                 perPlotWidth = NULL,
                                 stack = FALSE,
                                 gap = 0.85,
                                 barPlotXtextSize = 14,
                                 barPlotYtextSize = 14,
                                 barPlotLtextSize = 14) {
  
  # Color function
  ggplotColours <- function(n = 6, h = c(0, 360) + 15) {
    if ((diff(h) %% 360) < 1)
      h[2] <- h[2] - 360 / n
    hcl(h = seq(h[1], h[2], length = n),
        c = 100,
        l = 65)
  }
  # print(cluster_summary)
  colnames(cluster_summary)[1] <- "cluster"
  prop_cols <-
    grep("_Per$", colnames(cluster_summary), value = TRUE)
  cluster_data <- cluster_summary[, c("cluster", prop_cols)]
  # print(cluster_data)
  perData2plotLong <-
    reshape2::melt(cluster_data, id.vars = 'cluster')
  # print(perData2plotLong)
  # Set cluster and condition order
  perClusterOrder <- levels(factor(perData2plotLong$cluster))
  if (!is.null(expCondNameOrder)) {
    perData2plotLong$variable <-
      factor(perData2plotLong$variable, levels = rev(expCondNameOrder))
  }
  
  # If no color palette provided, auto-generate one
  if (is.null(selectedCol2)) {
    n_colors <- length(unique(perClusterOrder))
    selectedCol2 <- ggplotColours(n_colors)
  }
  
  # Auto plot size
  n_rows <- nrow(cluster_summary)
  n_cols <- ncol(cluster_summary)
  
  if (is.null(perPlotHeight)) {
    plotSizeHeight <-
      if (n_cols > 2)
        round(0.5 * n_cols)
    else
      round(0.8 * n_cols)
  } else {
    plotSizeHeight <- perPlotHeight
  }
  
  if (is.null(perPlotWidth)) {
    plotSizeWidth <- if (n_rows < 11) {
      round(n_rows)
    } else if (n_rows < 17) {
      round(0.7 * n_rows)
    } else {
      round(0.5 * n_rows)
    }
  } else {
    plotSizeWidth <- perPlotWidth
  }
  
  # Plotting
  if (stack) {
    g1 <-
      ggplot(perData2plotLong, aes(
        x = value,
        y = factor(variable),
        fill = factor(cluster)
      )) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = selectedCol2) +
      labs(title = '', x = '', y = '') +
      theme_minimal(base_size = 16)
  } else {
    g1 <-
      ggplot(perData2plotLong, aes(
        x = value,
        y = factor(cluster, levels = rev(perClusterOrder)),
        fill = factor(variable)
      )) +
      geom_bar(
        stat = "identity",
        position = "dodge",
        colour = "black",
        width = gap
      ) +
      coord_flip() +
      scale_fill_manual(values = selectedCol2) +
      labs(title = '', y = 'Relative cell %', x = '') +
      theme_minimal(base_size = 16)
  }
  
  # Formatting
  g1 <- g1 +
    theme(
      axis.text.x = element_text(size = barPlotXtextSize),
      axis.text.y = element_text(size = barPlotYtextSize),
      legend.title = element_blank(),
      legend.text = element_text(size = barPlotLtextSize),
      panel.grid.major = element_line(color = "grey85")
    )
  
  if (n_rows > 10) {
    g1 <-
      g1 + guides(fill = guide_legend(ncol = ifelse(stack, 2, 1), reverse = TRUE))
  }
  
  return(g1)
}


normalize_string <- function(x) {
  # Lowercase + remove spaces
  gsub("\\s+", "", tolower(x))
}

## Dotplot
#' Enhanced Dotplot with Genotype Markers
#'
#' Creates a dotplot with genotype markers displayed as a color bar above the plot
#'
#' @param seurat_obj Seurat object
#' @param features Vector of features (genes) to plot
#' @param genotype_var Name of metadata column containing genotype information
#' @param genetype_var Name of metadata column containing gene type information
#' @param group_by Variable to group cells by (default: genotype_var)
#' @param cols Colors for genotype markers (default: Seurat::DiscretePalette)
#' @param dotplot_width Plot width in inches (default: 10)
#' @param dotplot_height Plot height in inches (default: 6)
#' @param fontsize_x Font size for x-axis labels (default: 8)
#' @param fontsize_y Font size for y-axis labels (default: 8)
#' @param fontangle_x Angle for x-axis labels (default: 45)
#' @param fontsize_legend Font size for legend text (default: 8)
#' @param genetypebar_per Proportion of height dedicated to genotype bar (default: 0.03)
#' @param legend_per Proportion of width dedicated to legend (default: 0.15)
#' @param grid_on Whether to show grid lines (default: TRUE)
#' @param output_file Optional file path to save plot
#' @param ... Additional arguments passed to Seurat::DotPlot
#'
#' @return Combined ggplot object
#'
#' @examples
#' # seurat_obj <- your_seurat_object
#' # dotplot_with_genotype(seurat_obj, 
#' #                     features = c("Gene1", "Gene2"), 
#' #                     genotype_var = "genotype",
#' #                     genetype_var = "gene_type")
dotplot_with_genotype <- function(seurat_obj,
                                  features,
                                  group_by,
                                  # split_by = 'None',
                                  marker_genes_df,
                                  cols = NULL,
                                  dotplot_width = 10,
                                  dotplot_height = 6,
                                  fontsize_x = 8,
                                  fontsize_y = 8,
                                  fontangle_x = 45,
                                  fontsize_legend = 8,
                                  genetypebar_per = 0.03,
                                  legend_per = 0.15,
                                  grid_on = TRUE,
                                  output_file = NULL) {
  # --- Deduplicate features to avoid factor level duplication ---
  features <- unique(features)
  
  # One gene per entry - duplicate genes give FactorLevel duplicate errors
  marker_genes_df <- marker_genes_df %>%
    dplyr::distinct(gene, .keep_all = TRUE)
  
  # Basic dotplot
    g1 <- Seurat::DotPlot(
      seurat_obj,
      features = features,
      group.by = group_by,
      # split.by = split_by,
      dot.scale = 6,
      assay = "RNA",
      # scale = F,
      cols = c("lightgrey", "red")
    ) +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(
          color = "black",
          size = fontsize_x,
          angle = fontangle_x,
          vjust = 0.5
        ),
        axis.text.y = ggplot2::element_text(
          color = "black",
          size = fontsize_y
        ),
        axis.title = ggplot2::element_blank(),
        legend.text = ggplot2::element_text(
          color = "black",
          size = fontsize_legend
        )
      )
  
  
  if (grid_on) {
    g1 <- g1 + ggplot2::theme(panel.grid.major = ggplot2::element_line(colour = "grey80"))
  }
  
  # Gene type annotation bar (match dotplot features)
  marker_genes_df <- marker_genes_df %>%
    dplyr::filter(gene %in% levels(droplevels(g1$data$features.plot))) %>%
    dplyr::mutate(gene = factor(gene, levels = levels(droplevels(g1$data$features.plot))))
  
  if (is.null(cols)) {
    cols <- Seurat::DiscretePalette(
      n = length(unique(marker_genes_df$geneType)),
      palette = "alphabet"
    )
  }
  
  g2 <- ggplot2::ggplot(marker_genes_df) +
    ggplot2::geom_bar(
      mapping = ggplot2::aes(x = gene, y = 1, fill = geneType),
      stat = "identity",
      width = 1
    ) +
    ggplot2::scale_fill_manual(values = cols) +
    ggplot2::theme_void() +
    ggplot2::theme(
      panel.spacing.x = grid::unit(1, "mm"),
      legend.text = ggplot2::element_text(color = "black", size = fontsize_legend),
      legend.title = ggplot2::element_blank()
    )
  
  # Combine plots
  legend <- cowplot::plot_grid(
    cowplot::get_legend(g2),
    cowplot::get_legend(g1),
    ncol = 1,
    align = "h",
    axis = "l"
  )
  
  g1_no_legend <- g1 + ggplot2::theme(legend.position = "none")
  g2_no_legend <- g2 + ggplot2::theme(legend.position = "none")
  
  plot <- cowplot::plot_grid(
    g2_no_legend,
    g1_no_legend,
    align = "v",
    ncol = 1,
    axis = "lr",
    rel_heights = c(genetypebar_per * dotplot_height,
                    (1 - genetypebar_per) * dotplot_height)
  )
  
  plot_with_legend <- cowplot::plot_grid(
    plot,
    legend,
    nrow = 1,
    align = "h",
    axis = "none",
    rel_widths = c((1 - legend_per) * dotplot_width,
                   legend_per * dotplot_width)
  )
  
  # Save if requested
  if (!is.null(output_file)) {
    ggplot2::ggsave(
      filename = output_file,
      plot = plot_with_legend,
      width = dotplot_width,
      height = dotplot_height,
      limitsize = FALSE
    )
    message("Plot saved to: ", output_file)
  }
  
  return(plot_with_legend)
}


## ---------------------------------------------------------------------------- ##
shinyServer(function(input, output, session) {
  
  # check input string page
  currentPage <- reactiveVal("start")
  
  output$page <- reactive(currentPage())
  outputOptions(output, "page", suspendWhenHidden = FALSE)
  
  # Define reactive data directory based on user input
  data_dir <- reactive({
    req(input$projectName)
    file.path(getwd(), "data", input$projectName)
    # file.path("/Users/geethapriyanka/Projects/cytof/CytoF_Data_Analysis/data", input$projectName)
  })
  
  # Handle submit button and validate folder
  observeEvent(input$submitProject, {
    if (dir.exists(data_dir())) {
      currentPage("main")
    } else {
      showModal(modalDialog(
        title = "Error",
        paste("Input string does not match our record, please contact BIOCORE staff for aassitance."),
        easyClose = TRUE
      ))
    }
  })
  
  # Populate selectInput based on dynamic folder
  observe({
    req(currentPage() == "main")  # Only update after page is validated
    req(data_dir())               # Ensure it's available
    file_list <- list.files(data_dir(), pattern = "\\.(rds|RData)$", full.names = FALSE)
    updateSelectInput(session, "RDSFile", choices = file_list)
  })
  
  
  
  
  ## -------------------------------------------------------------------------- ##
  ## define interactive value for input datapath to take from input$rdsPath
  ## rds$datapath interactive value for input, by default, it takes default 'test.rds'
  # rds <- reactiveValues(datapath = as.character(paste(getwd(), 'test.rds', sep = '/')))
  # rds <- reactiveValues(datapath = NULL)
  ## Adding marker genes - cell division and growth phases
  cellPhase_markers <-
    reactiveValues(datapath = as.character(paste(getwd(), 'cc_marker_genes.xlsx', sep = '/')))
  cellType_markers <-
    reactiveValues(datapath = as.character(paste(getwd(), 'marker_genes.xlsx', sep = '/')))
  progress <- reactiveValues(time=shiny::Progress$new(style = "old"))
  

  
  ## 1. observe 'input$rdsUploadSubmit' to upload the input data file path.
  rds <- reactiveVal(NULL) 
  uploadedRDSList <- reactiveVal(list())  # Stores all uploaded Seurat objects
  
  # get the list - cell phase
  cellPhase_genes <- reactive({
    req(cellPhase_markers)
    req(cellType_markers)
    
    gene_list <-
      readxl::read_excel(cellPhase_markers$datapath, col_names = TRUE)
    gene_list2 <-
      readxl::read_excel(cellType_markers$datapath, col_names = TRUE)
   
    rbind(gene_list, gene_list2)
  })
  
  gene_phases <- reactive({
    req(cellPhase_genes())
    unique(c(cellPhase_genes()$geneType))
  })
  

  observeEvent(input$rdsUploadSubmit, {
    req(input$RDSFile)
    
    invalidateLater(500) 
    start_time <- Sys.time()
    
    
    for (i in 1:100) {
    current_status <- if (i < 30) {
      "info"   # Red for 0-30%
    } else if (i < 70) {
      "warning"  # Yellow for 30-70%
    } else {
      "success"  # Green for 70-100%
    }}
    
    
    updateProgressBar(
      session = session,
      id = "load2",
      value = 0,
      total = 100,
      title = paste("Processing...0%"),
      status = current_status  # Dynamic color update
    )
    Sys.sleep(0.05)
    
      tryCatch({
        
        # progress$stage <- "loading"
        # progress$percent <- 0
        # progress$message <- "Initializing..."
        # 
        updateProgressBar(
          session = session,
          id = "load2",
          value = 10,
          total = 100,
          title = paste("Processing...10%"),
          status = current_status  
        )
        Sys.sleep(0.05)
        
        file_name <- input$RDSFile
        file_path <- file.path(data_dir(), file_name)
        file_ext <- tolower(tools::file_ext(file_name))
        
         
        rds_file <- switch(file_ext,
                           "rds"   = readRDS(file_path),
                           "rdata" = {
                             env <- new.env()
                             load(file_path, envir = env)
                             get(ls(env)[1], envir = env)
                           },
                           stop("Unsupported file format"))
        
        
        updateProgressBar(
          session = session,
          id = "load2",
          value = 40,
          total = 100,
          title = paste("Processing...40%"),
          status = current_status 
        )
        Sys.sleep(0.1)
        
        if (!inherits(rds_file, "Seurat")) stop("Not a Seurat object")
        
        if (is.null(Assays(rds_file)) || length(Assays(rds_file)) == 0 ||
            is.null(Reductions(rds_file)) || length(Reductions(rds_file)) == 0 ||
            is.null(rds_file@meta.data) || ncol(rds_file@meta.data) == 0) {
          stop("Missing required Seurat components (assay/reduction/meta.data)")
        }
        
        
        updateProgressBar(
          session = session,
          id = "load2",
          value = 70,
          total = 100,
          title = paste("Processing...70%"),
          status = current_status  
        )
        Sys.sleep(0.1)
        
        rds_file <- formatRDSFile(rds_file)
        
        
        # Save to reactive values
        current_list <- uploadedRDSList()
        current_list[[file_name]] <- rds_file
        uploadedRDSList(current_list)
        rds(rds_file)
        
        # updateSelectInput(session, "selectedRDS", choices = names(current_list), selected = file_name)
        
        # Update all relevant UI inputs
        rds_obj <- rds_file
        metadata_cols <- colnames(rds_obj@meta.data)
        gene_names <- rownames(rds_obj)
        reduction_names <- names(rds_obj@reductions)
        gene_type_choices <- gene_phases()
        cluster_cols <- metadata_cols[!grepl("nCount|nFeature|percent", metadata_cols)]
        # cluster_cols <- metadata_cols[stringr::str_detect(metadata_cols,"expCond|orig.ident|cluster|cell|Cell|Cluster|ident|Ident")]
        
        req(rds_data())
        # updateSelectizeInput(session, "Category1", choices = cluster_cols)
        # updateSelectizeInput(session, "Category2", choices = cluster_cols)
        # updateSelectizeInput(session, "MdSplitby", choices = c('None', cluster_cols))
        # updateSelectizeInput(session, "Categoryumap", choices = cluster_cols)
        # updateSelectizeInput(session, "FeatureClusterSelect", choices = cluster_cols)
        # updateSelectizeInput(session, "VlnClusterSelect", choices = cluster_cols)
        # updateSelectizeInput(session, "DotClusterSelect", choices = cluster_cols)
        # updateSelectizeInput(session, "FeatureSampleSepSelect", choices = c('None', cluster_cols))
        # updateSelectizeInput(session, "VlnSampleSepSelect", choices = c('None', cluster_cols))
        # updateSelectizeInput(session, "DotSampleSepSelect", choices = c('None', cluster_cols))
        # updateSelectizeInput(session, "MdVis", choices = reduction_names)
        # updateSelectizeInput(session, "FeatureSelectedGenes", choices = gene_names)
        # updateSelectizeInput(session, "VlnSelectedGenes", choices = gene_names)
        # updateSelectizeInput(session, "DotSelectedGenes", choices = gene_names)
        # updateSelectizeInput(session, "FeatureSelectedGenesTypes", choices = gene_type_choices)
        # updateSelectizeInput(session, "DotSelectedGenesTypes", choices = gene_type_choices)
        # updateSelectizeInput(session, "HeatmapGenes", choices = gene_names)
        # updateSelectizeInput(session, "HeatmapClusterSelect", choices = cluster_cols)
        # updateSelectizeInput(session, "HeatmapSampleSepSelect", choices = c('None', cluster_cols))
        # updateSelectizeInput(session, "RefColName", choices = cluster_cols)
        # 
        updateProgressBar(
          session = session,
          id = "load2",
          value = 80,
          total = 100,
          title = paste("Finalizing...0%"),
          status = current_status  
        )
        Sys.sleep(0.1)
        validation_delay <- min(5, max(0.05, 0.05 * ncol(rds_file)))
        # Sys.sleep(validation_delay)
        # Reset visual outputs
        output$uploadStatus <- renderText(paste("✅ File uploaded:", file_name))
        output$CellSummaryBarPlot <- renderPlot(NULL)
        output$compareCellSummaryTable <- DT::renderDataTable(NULL)
        output$UMAPPlots <- renderPlot(NULL)
        output$VlnPlot <- renderPlot(NULL)
        output$FeaturePlot <- renderPlot(NULL)
        output$DotPlot <- renderPlot(NULL)
        output$Heatmap <- renderPlot(NULL)
        
        updateNavbarPage(session, inputId = "tabs", selected = "Cell Summary Profile")
        
        duration <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 2)
        message(paste("Upload and processing took", duration, "seconds"))
        

        updateProgressBar(
          session = session,
          id = "load2",
          value = 90,
          total = 100,
          title = paste("Finalizing...50%"),
          status = current_status  
        )
        Sys.sleep(0.1)
        # Sys.sleep(validation_delay)
        
        updateProgressBar(
          session = session,
          id = "load2",
          value = 100,
          total = 100,
          title = paste(""),
          status = current_status 
        )
        
        # Sys.sleep(0.05)
       
      }, error = function(e) {
        updateProgressBar(
          session = session,
          id = "load2",
          value = 100,
          # title = paste("❌ Error:", e$message),
          status = "danger"  # Red
        )
        output$uploadStatus <- renderText(paste("❌ Error:", e$message))
      })
    })

  # Reactively fetch selected object from dropdown
  selectedRDS <- reactive({
    req(input$selectedRDS)
    rds_object <- uploadedRDSList()[[input$selectedRDS]]
    rds(rds_object)  # update current reactiveVal
    rds_object
   })
  
  
  
  ## -------------------------------------------------------------------------- ##
  ## reactive values
  ## 1. rds_data(): based on 'input$rdsPath' interactive value into 'rds$datapath'
  ## 2. rds_meta(): reactive on meta.data of reactive 'rds_data()'
  ## 3. rds_plot(): reactive rds_data() with selective columns for Plots (sample/batch/treatment columns)
  
  rds_data <- reactive({
    rds()
  })
  rds_plotdata <- reactiveVal(NULL)
  observeEvent(rds_data(),{
    rds <- rds_data()  
    req(rds)
    
    rds_meta_data <- rds@meta.data
    # print("Metadata is loaded")
    
    # Identify relevant columns
    columns_in_rds <- colnames(rds_meta_data)
    columns_to_keep <-
      columns_in_rds[stringr::str_detect(columns_in_rds,
                                         "expCond|orig.ident|cluster|cell|Cell|Cluster")]
    
    # Check if columns_to_keep has anything (avoid accidental empty dataframe)
    if (length(columns_to_keep) == 0) {
      stop("No matching columns (expCond, orig.ident, cluster) found in metadata.")
    }
    
    # Subset metadata to only those columns
    rds_meta_data <- rds_meta_data[, columns_to_keep, drop = FALSE]
    
    # Create a copy of the Seurat object to safely modify (not recommended to modify directly in reactive)
    rds_copy <- rds
    rds_copy@meta.data <- rds_meta_data
    
    # Return modified Seurat object
    # rds_copy

    if ("scale.data" %in% Layers(rds_copy[["RNA"]])) {
      print("Scaled data exists and is not empty")
    } else {
      print("Running ScaleData()")
      # rds_copy = Seurat::ScaleData(object = rds_copy, features = rownames(rds_copy))
    }
    
    # Apply custom idents if they exist
    if (!is.null(custom_idents())) {
      tryCatch({
        custom_data <- custom_idents()
        # If custom_idents contains a column name
        if (is.character(custom_data) && length(custom_data) == 1) {
          if (custom_data %in% colnames(rds_copy@meta.data)) {
            Idents(rds_copy) <- rds_copy@meta.data[[custom_data]]
            print(paste("Applied Idents from column:", custom_data))
          }
        }
        # If custom_idents contains actual ident values
        else if (length(custom_data) == ncol(rds_copy)) {
          Idents(rds_copy) <- custom_data
          print("Applied custom Idents vector")
        }
      }, error = function(e) {
        print(paste("Error applying custom idents:", e$message))
      })
    }
    
    rds_plotdata(rds_copy)
  })
  
  # rds_plotdata <- reactiveVal(rds_plotdata_finalize())
  custom_idents <- reactiveVal(NULL)
  observeEvent(input$CSSubmit,{
     updateNavbarPage(session, inputId = "tabs", selected = "Cell Summary Profile")
   })
  observeEvent(input$VPSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "Violin Plots")
  })
  observeEvent(input$FPSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "Feature Plots")
  })
  observeEvent(input$DPSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "Dot Plots")
  })
  observeEvent(input$HMapSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "Heatmaps")
  })
  observeEvent(input$ScoringSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "Scoring")
  })
  observeEvent(input$DETestingSubmit,{
    updateNavbarPage(session, inputId = "tabs", selected = "DE Testing")
  })
  # Add this to your server - Forces all UI elements to refresh when data updates
  observe({
    req(rds_plotdata())

    # This creates a dependency on rds_plotdata for UI updates
    data <- rds_plotdata()
    cluster_cols <- colnames(data@meta.data)

    print(paste("Observer triggered - Available columns:",
                paste(cluster_cols, collapse = ", ")))
    reduction_names <- names(data@reductions)
    gene_names <- rownames(data)
    metadata_cols <- colnames(data@meta.data)
    reduction_names <- names(data@reductions)
    gene_type_choices <- gene_phases()
    cluster_cols <- metadata_cols[!grepl("nCount|nFeature|percent", metadata_cols)]
    # Update ALL selectInputs that use metadata columns
    updateSelectizeInput(session, "Category1", choices = cluster_cols)
    updateSelectizeInput(session, "Category2", choices = cluster_cols)
    updateSelectizeInput(session, "MdSplitby", choices = c('None', cluster_cols))
    updateSelectizeInput(session, "Categoryumap", choices = cluster_cols)
    updateSelectizeInput(session, "FeatureClusterSelect", choices = cluster_cols)
    updateSelectizeInput(session, "VlnClusterSelect", choices = cluster_cols)
    updateSelectizeInput(session, "DotClusterSelect", choices = cluster_cols)
    updateSelectizeInput(session, "FeatureSampleSepSelect", choices = c('None', cluster_cols))
    updateSelectizeInput(session, "VlnSampleSepSelect", choices = c('None', cluster_cols))
    updateSelectizeInput(session, "DotSampleSepSelect", choices = c('None', cluster_cols))
    updateSelectizeInput(session, "ScoringSelectedGenes", choices = gene_names)
    updateSelectizeInput(session, "MdVis", choices = reduction_names)
    updateSelectizeInput(session, "FeatureSelectedGenes", choices = gene_names)
    updateSelectizeInput(session, "VlnSelectedGenes", choices = gene_names)
    updateSelectizeInput(session, "DotSelectedGenes", choices = gene_names)
    updateSelectizeInput(session, "FeatureSelectedGenesTypes", choices = gene_type_choices)
    updateSelectizeInput(session, "DotSelectedGenesTypes", choices = gene_type_choices)
    updateSelectizeInput(session, "HmapSelectedGenes", choices = gene_names)
    valid_cluster_cols <- cluster_cols[sapply(cluster_cols, function(col) {
      length(unique(data@meta.data[[col]])) > 1
    })]
    updateSelectizeInput(session, "HeatmapClusterSelect", choices = valid_cluster_cols)
    updateSelectizeInput(session, "HeatmapSampleSepSelect", choices = c('None', valid_cluster_cols))
    updateSelectizeInput(session, "DEtestingCluster", choices = valid_cluster_cols)
    updateSelectizeInput(session, "RefColName", choices = cluster_cols)


  }) %>% bindEvent(rds_plotdata(), custom_idents())

  # Add visual confirmation that update happened
  observeEvent(list(rds_plotdata(), custom_idents()), {
    req(rds_plotdata())
    
    # showNotification(
      # "✓ Data updated throughout the app",
    #   type = "message",
    #   duration = 2
    # )
  })
  
  # Debug observer - remove after confirming it works
  observe({
    print("=== DEBUG: Reactive values status ===")
    print(paste("rds_data is NULL?", is.null(rds_data())))
    print(paste("rds_plotdata is NULL?", is.null(try(rds_plotdata(), silent = TRUE))))
    print(paste("custom_idents:", custom_idents()))
    
    if (!is.null(try(rds_plotdata(), silent = TRUE))) {
      print(paste("rds_plotdata columns:", 
                  paste(colnames(rds_plotdata()@meta.data), collapse = ", ")))
    }
    print("=====================================")
  }) %>% bindEvent(rds_plotdata(), custom_idents())
  ## -------------------------------------------------------------------------- ##
  
  #
  ## ------------------------------------------------------------------------- ##
  ## render output results
  ## 1. Render the summary table in the UI
  
  output$sampleDescriptionTable <- DT::renderDataTable({
    req(rds_plotdata())
    print(paste("Table rendering with columns:", 
                paste(colnames(rds_plotdata()@meta.data), collapse = ", ")))
    metadata_literature_summary_auto(rds_plotdata())
  }) %>% bindEvent(rds_plotdata(), ignoreNULL = TRUE, ignoreInit = FALSE)
  
  observeEvent(input$compareCellSummaryCategory, {
    req(rds_plotdata())
    output$compareCellSummaryTable <- DT::renderDataTable({
      cluster_summary(
        data = rds_plotdata(),
        row = input$Category1,
        col = input$Category2
      )
    })
    
    output$CellSummaryBarPlot <- renderPlot({
      req(rds_plotdata())
      cs = cluster_summary(
        data = rds_plotdata(),
        row = input$Category1,
        col = input$Category2
      )
      
      plot_cluster_barplot(
        cluster_summary = cs,
        selectedCol2 = NULL,
        expCondNameOrder = NULL,
        perPlotHeight = NULL,
        perPlotWidth = NULL,
        stack = TRUE,
        gap = 0.85,
        barPlotXtextSize = as.numeric(input$barPlotXtextSize),
        barPlotYtextSize = as.numeric(input$barPlotYtextSize),
        barPlotLtextSize = as.numeric(input$barPlotLtextSize)
      )
    })
  })
  
  ## Download Cell Summaries and Cell Summary bar Plot
  
  output$download_CellSummary <- downloadHandler(
    filename = function() {
      paste0("cell_summary_", Sys.Date(), "_", Sys.time(), ".txt")
    },
    content = function(file) {
      data_to_save <- cluster_summary(
        data = rds_plotdata(),
        row = input$Category1,
        col = input$Category2
      )
      write.table(
        data_to_save,
        file,
        row.names = FALSE,
        quote = F,
        sep = '\t',
        col.names = T
      )
    }
  )
  
  
  
  output$download_CellSummaryPlot <- downloadHandler(
    filename = function() {
      paste0("cluster_barplot_", Sys.Date(), "_", Sys.time(), ".pdf")
    },
    content = function(file) {
      plot_obj <- plot_cluster_barplot(
        cluster_summary = cluster_summary(
          data = rds_plotdata(),
          row = input$Category1,
          col = input$Category2
        ),
        selectedCol2 = NULL,
        expCondNameOrder = NULL,
        perPlotHeight = NULL,
        perPlotWidth = NULL,
        stack = TRUE,
        gap = 0.85
      )
      
      ggsave(
        filename = file,
        plot = plot_obj,
        device = "pdf",
        height = as.numeric(input$barplot_height),
        width = as.numeric(input$barplot_width),
        units = "in"
      )
    }
  )
  
  
  
  ## PCA, UMAPs, tSNEs
  umapPlot <- reactive({
    data = rds_plotdata()
    # Set the clustering and sample separation options
    cluster <- input$Categoryumap
    Seurat::DefaultAssay(data) <- 'RNA'  # Set the assay
    print("2.2. Generationg UMAP Plots")
    sprintf("2.2: Selected %s UMAP Plots as Idents: ", cluster)
    # Set the cluster identities based on the selected cluster column in meta data
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    # par(mar=c(1,1,1,1))Category1
    # Generate the FeaturePlot based on whether sample separation is needed
    req(input$MdVis)
    selected_clusters <- input$Categoryumap
    # plot_obj <- subset(seurat_obj, idents = selected_clusters)
    # -------- Get palette --------
    n_groups <- length(unique(as.character(data@meta.data[[cluster]])))
    
    palette_pkg <- input$umap_palette_package  # "Default", "dittoSeq", "Polychrome"
    palette_name <- input$umap_palette_name    # e.g., "glasbey" for Polychrome
    
    cols <- get_discrete_palette(n_groups, palette_pkg, palette_name)
    
    if (input$MdSplitby != 'None') {
      DimPlot(
        data,
        reduction = input$MdVis,
        split.by = input$MdSplitby,
        cols = cols,
        label = TRUE
      )+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$mdPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$mdPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$mdPlotLtextSize))
        )
    } else {
      DimPlot(data, reduction = input$MdVis, label = TRUE, cols = cols) +
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$mdPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$mdPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$mdPlotLtextSize))
        )
    }
  })
  
  observeEvent(input$LoadUMAP, {
    output$UMAPPlots <- renderPlot({
      suppressWarnings({
        # Ensure all necessary inputs and data are available
        umapPlot()
      })
    })
  })
  
  output$download_UMAPs <- downloadHandler(
    filename = function() {
      paste0("cluster_MultiDimPlot_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".pdf")
    },
    content = function(file) {
      plotObject = umapPlot()
      
      
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$umapplot_height),
        width = as.numeric(input$umapplot_width),
        units = "in"
      )
    }
    
  )
  
  ## ------------------------------------------------------------------------- ##
  # 2. Render Violin Plot
  
  Vlnplot = reactive({
    data = rds_plotdata()
    # Set the clustering and sample separation options
    cluster <- input$VlnClusterSelect
    Seurat::DefaultAssay(data) <- 'RNA'  # Set the assay
    print("3. Generationg Violin Plots")
    sprintf("3.1: Sdelected %s Violin Plots as Idents: ", cluster)
    # Set the cluster identities based on the selected cluster column in meta data
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    n_groups <- length(unique(as.character(data@meta.data[[cluster]])))
    
    palette_pkg <- input$vln_palette_package
    palette_name <- input$vln_palette_name
    
    cols <- get_discrete_palette(n_groups, palette_pkg, palette_name)
    
    # Generate the FeaturePlot based on whether sample separation is needed
    if (input$VlnSampleSepSelect == 'None') {
      p =  Seurat::VlnPlot(data,
                           features = as.vector(input$VlnSelectedGenes),
                           slot = 'data',combine = FALSE, cols = cols
      )
      # p <- wrap_plots(p, ncol = 4) + plot_annotation(theme = theme_minimal())
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal()) +
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$vlnPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$vlnPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$vlnPlotLtextSize))
        )
      p
    } else {
      sprintf(
        "3.2: Selected %s Violin Plots for Split Visualization: ",
        input$VlnSampleSepSelect
      )
      p = Seurat::VlnPlot(
        data,
        features = as.vector(input$VlnSelectedGenes),
        slot = 'data',
        split.by = input$VlnSampleSepSelect,
        combine = FALSE, cols = cols
      )
      # p <- wrap_plots(p, ncol = 2) + plot_annotation(theme = theme_minimal())
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal())+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$vlnPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$vlnPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$vlnPlotLtextSize))
        )
      p
    }
  })
  observeEvent(input$VlnClusterSelection, {
    output$VlnPlot <- renderPlot({
      suppressWarnings({
        # Ensure all necessary inputs and data are available
        Vlnplot()
      })
    })
  })
  
  output$download_VlnPlot <- downloadHandler(
    filename = function() {
      paste0("cluster_ViolinPlot_", Sys.Date(), "_", Sys.time(), ".pdf")
    },
    content = function(file) {
      plotObject = Vlnplot()
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$vlnplot_height),
        width = as.numeric(input$vlnplot_width),
        units = "in"
      )
    }
  )
  
  
  ## ------------------------------------------------------------------------- ##
  # 3. Render Feature Plot
  FPlot = reactive({
    data = rds_plotdata()
    # Set the clustering and sample separation options
    print("4. Generating required Feature Plots")
    cluster <- input$FeatureClusterSelect
    Seurat::DefaultAssay(data) <- 'RNA'  # Set the assay
    sprintf("4.1: Selected %s as Idents for Feature Plots: ", cluster)
    # Set the cluster identities based on the selected cluster column in meta data
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    palette_pkg <- input$fp_palette_package
    palette_name <- input$fp_palette_name
    
    cols <- get_continuous_palette(palette_pkg, palette_name)
    
    # Generate the FeaturePlot based on whether sample separation is needed
    # if (input$FeatureSampleSepSelect %in% rownames(data)) {
    if (input$FeatureSampleSepSelect == 'None') {
      p = Seurat::FeaturePlot(
        data,
        features = input$FeatureSelectedGenes,
        keep.scale = 'all',
        label = T,
        pt.size = 0.1,
        combine = TRUE
      ) & scale_color_gradientn(colors = cols)
      # p <- wrap_plots(p, ncol = 4) + plot_annotation(theme = theme_minimal())
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal())+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$FPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$FPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$FPlotLtextSize))
        )
      p
    }
    else {
      sprintf("4.2: Selected %s to Split for Feature Plots: ",
              input$FeatureSampleSepSelect)
      p = Seurat::FeaturePlot(
        data,
        features = input$FeatureSelectedGenes,
        split.by = input$FeatureSampleSepSelect,
        keep.scale = 'all',
        label = T,
        pt.size = 0.1,
        combine = T
      ) & scale_color_gradientn(colors = cols)
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal())+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$FPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$FPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$FPlotLtextSize))
        )
      p
    }
  })
  observeEvent(input$FeatureClusterSelection, {
    output$FeaturePlot <- renderPlot({
      suppressWarnings({
        FPlot()
      })
    })
  })
  
  output$download_FeaturePlot <- downloadHandler(
    filename = function() {
      paste0("cluster_FeaturePlot_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".pdf")
    },
    content = function(file) {
      plotObject = FPlot()
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$featureplot_height),
        width = as.numeric(input$featureplot_width),
        units = "in"
      )
    }
  )
  
  ## ------------------------------------------------------------------------- ##
  # 4. Render Dot Plot
  
  Dplot <- reactive({
    req(rds_plotdata())
    
    data <- rds_plotdata()
    Seurat::DefaultAssay(data) <- "RNA"
    if(input$DotSampleSepSelect == 'None'){
      data@meta.data$dot_cluster = data@meta.data[[input$DotClusterSelect]]
      cluster = 'dot_cluster'
    } else {
      data@meta.data$dot_cluster <- paste0(data@meta.data[[input$DotClusterSelect]],"_",data@meta.data[[input$DotSampleSepSelect]])
      cluster = 'dot_cluster'
      # cluster
    }
    
    Seurat::Idents(data) <- data@meta.data$dot_cluster
    
    features_list <- NULL
    gene_types_df <- NULL
    
    # Option 1: Gene Type from preloaded gene types
    if (input$DotInputType == "PreGeneTypes") {
      gene_types_df <- cellPhase_genes() %>%
        dplyr::filter(geneType %in% input$DotSelectedGenesTypes)
      features_list <- gene_types_df %>% pull(gene)
    }
    
    # Option 2: Specific genes from uploaded RDS
    else if (input$DotInputType == "uploadedMarkers") {
      features_list <- as.vector(input$DotSelectedGenes)
    }
    
    # Option 3: Uploaded file
    else if (input$DotInputType == "excelSource") {
      req(input$dotPlotFile)
      file_path <- input$dotPlotFile$datapath
      file_ext <- tools::file_ext(input$dotPlotFile$name)
      file_ext <- tolower(file_ext)
      df <- switch(
        file_ext,
        "csv"  = readr::read_csv(file_path, col_types = cols()),
        "txt"  = readr::read_delim(file_path, delim = "\t", col_types = cols()),
        "xlsx" = readxl::read_excel(file_path),
        "xls" = readxl::read_excel(system.file(file_path)),
        "tsv" = readr::read_delim(system.file(file_path), delim = "\t", col_types = cols()),
        stop("Unsupported file format")
      )
      
      validate(
        need(
          all(c("gene", "geneType") %in% colnames(df)),
          "File must contain 'gene' and 'geneType' columns."
        )
      )
      
      features_list <- unique(df$gene)
      gene_types_df <- df
    }
    
    req(features_list)  # Must have something to plot
    
    # Case A: we have gene types
    if (input$DotInputType %in% c("PreGeneTypes", "excelSource")) {
      plot_out <- dotplot_with_genotype(
        seurat_obj     = data,
        features       = features_list,
        group_by       = cluster,
        marker_genes_df = gene_types_df,   # <- explicitly passing gene/geneType df
        # split.by = input$DotSampleSepSelect,
        dotPlotXtextSize     = as.numeric(input$dotPlotXtextSize),
        dotPlotYtextSize     = as.numeric(input$dotPlotYtextSize),
        dotPlotLtextSize     = as.numeric(input$dotPlotLtextSize),
        fontangle_x    = as.numeric(input$dotPlotXangle),
        genetypebar_per = 0.05,
        legend_per     = 0.2
      )
    }
    
    # Case B: just genes, no gene types
    else {
      plot_out <- Seurat::DotPlot(
        data,
        features = features_list,
        dot.scale = 6,
        assay = "RNA",
        group.by = cluster,
        # scale = F,
        # split.by = input$DotSampleSepSelect,
        cols = c("lightgrey", "red")
      ) + RotatedAxis()+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$dotPlotXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$dotPlotYtextSize)),
          legend.text = element_text(size = as.numeric(input$dotPlotLtextSize))
        )
    }
    
    return(plot_out)
  })
  
  
  observeEvent(input$DotClusterSelection, {
    output$DotPlot <- renderPlot({
      suppressWarnings({
        # Ensure all necessary inputs and data are available
        Dplot()
      })
    })
  })
  
  output$download_DotPlot <- downloadHandler(
    filename = function() {
      paste0("cluster_FeaturePlot_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".pdf")
    },
    content = function(file) {
      plotObject = Dplot()
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$dotplot_height),
        width = as.numeric(input$dotplot_width),
        units = "in"
      )
    }
  )
  
  
  ## ------------------------------------------------------------------------- ##
  ## ------------------------------------------------------------------------- ##
  # 6. Render Heatmaps
  HMap = reactive({
    data = rds_plotdata()
    # Set the clustering and sample separation options
    print("6. Generating required heatmaps")
    cluster <- input$HeatmapClusterSelect
    Seurat::DefaultAssay(data) <- 'RNA'  # Set the assay
    sprintf("6.1: Selected %s as Idents for Heatmap Plots: ", cluster)
    # Set the cluster identities based on the selected cluster column in meta data
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    data[["RNA"]] <- as(object = data[["RNA"]], Class = "Assay")
    dataAgg <- AverageExpression(object = data,
                                 return.seurat = TRUE,
                                 slot = "data")
    dataAgg = ScaleData(dataAgg, features = rownames(dataAgg))
    
    
    p = Seurat::DoHeatmap(
      dataAgg,
      features = input$HmapSelectedGenes,
      draw.lines = FALSE
    )
    
    p <- wrap_plots(p) + plot_annotation(theme = theme_minimal()) &
      ggplot2::theme(
        axis.text.x = element_text(size = as.numeric(input$HmaptXtextSize),angle = 45, hjust = 1),
        axis.text.y = element_text(size = as.numeric(input$HmapYtextSize)),
        legend.text = element_text(size = as.numeric(input$HmapLtextSize))
      )
    p
  })
  
  observeEvent(input$HeatmapSelection, {
    output$Heatmap <- renderPlot({
      suppressWarnings({
        HMap()
      })
    })
  })
  
  output$download_Heatmap <- downloadHandler(
    filename = function() {
      paste0("cluster_Heatmap_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".pdf")
    },
    content = function(file) {
      plotObject = HMap()
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$Heatmap_height),
        width = as.numeric(input$Heatmap_width),
        units = "in"
      )
    }
  )
  
  ## ------------------------------------------------------------------------- ##
  # 7. Render Scoring Plot
  Scoring = reactive({
    data = rds_plotdata()
    # Set the clustering and sample separation options
    print("7. Generating required Scoring Plots")
    cluster <- input$ScoringClusterSelect
    Seurat::DefaultAssay(data) <- 'RNA'  # Set the assay
    sprintf("7.1: Selected %s as Idents for Feature Plots: ", cluster)
    # Set the cluster identities based on the selected cluster column in meta data
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    
    features_list <- NULL
    if (input$ScoringInputType == "uploadedMarkers") {
      features_list <- as.vector(input$ScoringSelectedGenes)
    }
    
    # Option 3: Uploaded file
    else if (input$ScoringInputType == "excelSource") {
      req(input$ScoringPlotFile)
      file_path <- input$ScoringPlotFile$datapath
      file_ext <- tolower(tools::file_ext(input$ScoringPlotFile$name))
      
      df <- switch(
        file_ext,
        "csv"  = readr::read_csv(file_path, col_types = cols()),
        "txt"  = readr::read_delim(file_path, delim = "\t", col_types = cols()),
        "xlsx" = readxl::read_excel(file_path),
        "xls" = readxl::read_excel(file_path),
        "gmt" = clusterProfiler::read.gmt(file_path),
        "tsv" = readr::read_delim(file_path, delim = "\t", col_types = cols()),
        stop("Unsupported file format")
      )
      
      validate(
        need(
          all(c("gene") %in% colnames(df)),
          "File must contain 'gene' column."
        )
      )
      
      features_list <- unique(df$gene)
      gene_types_df <- df
    }
    
    req(features_list)
    data = Seurat::AddModuleScore(data, features = list(features_list), name = "Score")
    # Generate the FeaturePlot based on whether sample separation is needed
    # if (input$FeatureSampleSepSelect %in% rownames(data)) {
    if (input$ScoringSampleSepSelect == 'None') {
      p = scCustomize::FeaturePlot_scCustom(
        data,
        features = "Score1",
        keep.scale = 'all',
        label = T,
        pt.size = 0.1,
        combine = TRUE,na_cutoff = NA
      )
      
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal())+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$ScoringXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$ScoringYtextSize)),
          legend.text = element_text(size = as.numeric(input$ScoringLtextSize))
        )
      p
    }
    else {
      sprintf("7.2: Selected %s to Split for Scoring Plots: ",
              input$ScoringSampleSepSelect)
      p = scCustomize::FeaturePlot_scCustom(
        data,
        features = "Score1",
        split.by = input$ScoringSampleSepSelect,
        label = T,
        pt.size = 0.1,
        combine = T,na_cutoff = NA
      )
      p <- wrap_plots(p) + plot_annotation(theme = theme_minimal())+
        ggplot2::theme(
          axis.text.x = element_text(size = as.numeric(input$ScoringXtextSize)),
          axis.text.y = element_text(size = as.numeric(input$ScoringYtextSize)),
          legend.text = element_text(size = as.numeric(input$ScoringLtextSize))
        )
      p
    }
  })
  observeEvent(input$ScoringClusterSelection, {
    output$Scoring <- renderPlot({
      suppressWarnings({
        Scoring()
      })
    })
  })
  
  output$download_Scoring <- downloadHandler(
    filename = function() {
      paste0("cluster_ScoringPlot_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".pdf")
    },
    content = function(file) {
      plotObject = Scoring()
      ggsave(
        filename = file,
        plot = plotObject,
        device = "pdf",
        height = as.numeric(input$scoring_height),
        width = as.numeric(input$scoring_width),
        units = "in"
      )
    }
  )
  
  ## ------------------------------------------------------------------------- ##
  # 8. DE Testing
  # 8. DE Testing
  de_data = reactive({
    req(rds_plotdata(), input$DEtestingCluster)
    
    data <- rds_plotdata()
    cluster <- input$DEtestingCluster
    
    Seurat::DefaultAssay(data) <- 'RNA'
    Seurat::Idents(data) <- data@meta.data[[cluster]]
    
    data
  })
  
  # 2. Reactive list of cluster choices
  all_clusters <- reactive({
    req(de_data())
    sort(unique(as.character(Seurat::Idents(de_data()))))
  })
  
  # 3. Populate DECluster1 when DEtestingCategory is clicked
  observeEvent(input$DEtestingCluster, {
    req(all_clusters())
    
    cat("Populating cluster dropdowns\n")
    
    updateSelectInput(session, "DECluster1", choices = all_clusters())
    
    updateSelectizeInput(session, "DECluster2",
                         choices = c("vsAll", all_clusters()))
  })
  
  # 4. Update DECluster2 based on DECluster1 (mutual exclusion)
  observeEvent(input$DECluster1, {
    req(input$DECluster1, all_clusters())
    
    available <- c("vsAll", setdiff(all_clusters(), input$DECluster1))
    
    current <- isolate(input$DECluster2)
    selected <- if (!is.null(current) && current %in% available) current else "vsAll"
    
    updateSelectizeInput(session, "DECluster2",
                         choices = available)
  }, ignoreInit = TRUE)
  
  # 5. Run DE testing only when both clusters are selected
  DEtestingTable <- reactive({
    req(de_data(), input$DECluster1, input$DECluster2, input$DEtestingCategory)
    data <- de_data()
    
    ident2 <- if ("vsAll" %in% input$DECluster2) NULL else input$DECluster2
    
    showNotification(
    "Calculating Differentially expressed Markers",
      type = "message",
      duration = 2
    )
    
    de.markers <- tryCatch({
      Seurat::FindMarkers(
        data,
        ident.1 = input$DECluster1,
        ident.2 = ident2
      )
    }, error = function(e) {
      message("FindMarkers failed: ", e$message)
      NULL
    })
    
    req(de.markers)  # stop cleanly with a clear error if it's NULL
    
    de.markers$Gene <- rownames(de.markers)
    de.markers <- de.markers %>% dplyr::select(Gene, dplyr::everything())
    rownames(de.markers) <- NULL
    showNotification(
      "Calculation Complete",
      type = "message",
      duration = 2
    )
    de.markers
  })
  
  VolcanoPlot <- reactive({
    req(DEtestingTable(),input$DECluster1, input$DECluster2, input$DEtestingCategory)
    # Identifying Up, Down and Non significant
    df <- DEtestingTable() %>%
      dplyr::mutate(
        significance = dplyr::case_when(
          p_val_adj < 0.05 & avg_log2FC > 0.5  ~ "Up",
          p_val_adj < 0.05 & avg_log2FC < -0.5 ~ "Down",
          TRUE                                ~ "NS"
        ),
        neg_log10_p = -log10(p_val_adj + 1e-300)  # avoid log(0)
      )
    print(head(df))
    # Get top 10 from Up and Down significant markers
    top_labels <- df %>%
      dplyr::filter(significance != "NS") %>%
      dplyr::group_by(significance) %>%
      dplyr::slice_min(p_val_adj, n = 10) %>%
      dplyr::ungroup()
    print(head(top_labels))
    # Plotly function
    plotly::plot_ly(
      data = df,
      x = ~avg_log2FC,
      y = ~neg_log10_p,
      color = ~significance,
      colors = c("Up" = "#D0526E", "Down" = "#5A9BD4", "NS" = "grey80"),
      type = "scatter",
      mode = "markers",
      marker = list(size = 5, opacity = 0.6),
      text = ~paste0("Gene: ", Gene,
                     "<br>log2FC: ", round(avg_log2FC, 2),
                     "<br>p_adj: ", signif(p_val_adj, 3)),
      hoverinfo = "text"
    ) %>%
      plotly::add_annotations(
        data = top_labels,
        x = ~avg_log2FC, y = ~neg_log10_p, text = ~Gene,
        showarrow = FALSE,
        # arrowhead = 2, arrowsize = 0.5,
        # ax = ~ax, ay = ~ay,
        font = list(size = 10, color = "rgba(0, 0, 0, 0.8)")
      ) %>%
      plotly::layout(
        title = "Volcano Plot",
        xaxis = list(title = "log2 Fold Change", zeroline = TRUE),
        yaxis = list(title = "-log10(adjusted p-value)"),
        shapes = list(
          # Vertical threshold lines
          list(type = "line", x0 = 1, x1 = 1,
               y0 = 0, y1 = max(df$neg_log10_p),
               line = list(color = "grey50", dash = "dash", width = 1)),
          list(type = "line", x0 = -1, x1 = -1,
               y0 = 0, y1 = max(df$neg_log10_p),
               line = list(color = "grey50", dash = "dash", width = 1)),
          # Horizontal p-value line
          list(type = "line",
               x0 = min(df$avg_log2FC), x1 = max(df$avg_log2FC),
               y0 = -log10(0.05), y1 = -log10(0.05),
               line = list(color = "grey50", dash = "dash", width = 1))
        ),
        showlegend = TRUE
      )
  })
  
  
# 6. Render the table - this stays "registered" all the time
output$DEtestingTable <- DT::renderDataTable({
  DEtestingTable()
})

output$VolcanoPlot <- renderPlotly({
  suppressWarnings({
    VolcanoPlot()
  })
})

output$download_DEtesting <- downloadHandler(
  filename = function() {
    paste0("DEtesting_",
           Sys.Date(),
           "_",
           Sys.time(),
           ".csv")
  },
  content = function(file) {
    DEObject = DEtestingTable()
    write.table(
      DEObject,
      file,
      row.names = FALSE,
      quote = F,
      sep = '\t',
      col.names = T
    )
  }
)
  ## ------------------------------------------------------------------------- ##
  # 9.Metadata addition and export New RDS file with added metadata column - conditional Panel in Cell Summary Profile's SAMPLE DESCRIPTION
  ## ------------------------------------------------------------------------- ##
MetaExport = reactive({
  data = rds_plotdata()
  data
})

  observeEvent(input$RefColSelect, {
    data = rds_plotdata()
    req(input$RefColName)
    # meta <- data@meta.data
    
    validate(
      need(input$RefColName %in% colnames(data@meta.data),
           "Column not found in meta.data")
    )
    
    # Set Idents
    Idents(data) <- data@meta.data[[input$RefColName]]
    # Get unique levels
    lvls <- levels(factor(Idents(data)))
    n <- length(lvls)
    
    output$RefColContent <- renderUI({
      req(lvls)
      
      tagList(
        h4(paste("Found", length(lvls), "levels:")),
        lapply(seq_along(lvls), function(i) {
          textInput(
            inputId = paste0("col_", i),
            label = paste0("Level ", i, ": ", lvls[i]),
            value = lvls[i],
            placeholder = "Enter new name"
          )
        })
      )
    })
    showNotification(paste("Loaded", n, "levels"), type = "message")
  })
  
  observeEvent(input$ApplyNames, {
    req(rds_plotdata(),input$NewColName)
    data = rds_plotdata()
    Idents(data) <- data@meta.data[[input$RefColName]]
    lvls <- levels(Idents(data))
    n <- length(lvls)
    
    new_names <- sapply(seq_len(n), function(i) {
      val <- input[[paste0("col_", i)]]
      if (is.null(val) || val == "") {
        lvls[i]  # Keep original if empty
      } else {
        val
      }
    }, USE.NAMES = FALSE)
    
    # Validate that we have all inputs
    if (any(is.null(new_names))) {
      showNotification("Error: Some inputs are missing", type = "error")
      return(NULL)
    }
    
    names(new_names) <- lvls
    
    tryCatch({
      # Rename idents
      data <- RenameIdents(data, new_names)
      
      # Add renamed idents as new metadata column
      data@meta.data[[input$NewColName]] <- Idents(data)
      old_values <- data@meta.data[[input$RefColName]]
      new_col_values <- new_names[as.character(old_values)]
      data@meta.data[[input$NewColName]] <- new_col_values
      rds_plotdata(data)
      
      # Also update rds_data to keep in sync
      # original <- rds_data()
      # original_values <- new_names[as.character(original@meta.data[[input$RefColName]])]
      # original@meta.data[[input$NewColName]] <- original_values
      # rds_data(original)
      custom_idents(input$NewColName)
      
      showNotification(
        paste("Successfully created column:", input$NewColName),
        type = "message",
        duration = 5
      )
      
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
    
  output$out <- renderPrint({
    req(rds_plotdata(), input$RefColName, input$NewColName)
    
    data <- rds_plotdata()
    Idents(data) <- data@meta.data[[input$RefColName]]
    # Check if new column exists
    if (input$NewColName %in% colnames(data@meta.data)) {
      cat("Cross-tabulation of old vs new names:\n\n")
      print(table(
        Original = data@meta.data[[input$RefColName]],
        Renamed = data@meta.data[[input$NewColName]]
      ))
    } 
    # else {
    #   # cat("New column not yet created. Click 'Apply New Names'.\n")
    # }
  })
  
  
  output$download_updatedMeta <- downloadHandler(
    filename = function() {
      paste0("UpdatedMetaData_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".tsv")
    },
    content = function(file) {
      mtdata = rds_plotdata()@meta.data
      # mtdata$cellBarcodes = rownames(mtdata)
      mtdata <- data.frame(cellBarcodes = rownames(mtdata), mtdata)
      write.table(mtdata, file = file, sep = '\t',col.names = T, row.names = F)
    }
  )
    

  output$download_updatedRDS <- downloadHandler(
    filename = function() {
      paste0("UpdatedRDS_",
             Sys.Date(),
             "_",
             Sys.time(),
             ".rds")
    },
    content = function(file) {
      saveRDS(rds_plotdata(), file)
    }
  )
    
})

