# Core TF target heatmap logic (refactored from GSAD_DAPseq_TFs.R)

COLOR_BG <- "grey90"
COLOR_GS <- "orange"
COLOR_HL <- "red2"
COLOR_MID <- "yellow"

COLORSET <- c(
  "darkturquoise", "#E41A1C", "gold", "#BEBADA", "#A6D854", "lightpink",
  "mediumslateblue", "darkseagreen1", "deeppink4", "#FC8D62", "cornflowerblue",
  "#A65628", "darkkhaki", "#A6CEE3", "#33A02C", "navajowhite", "antiquewhite4",
  "darkgreen", "#FF7F00", "midnightblue", "#6A3D9A", "dodgerblue4", "violetred1",
  "darkorchid1", "darkslategrey", "darkolivegreen", "coral4", "red3", "#FFED6F",
  "burlywood4", "thistle", "chartreuse3", "#FB9A99", "darkslateblue", "deeppink",
  "antiquewhite", "chartreuse4", "chocolate3", "violet", "mediumblue", "turquoise4",
  "springgreen3", "cyan2", "thistle2", "#8DD3C7", "mediumpurple1", "khaki1",
  "#FDB462", "hotpink4", "dodgerblue2", "deepskyblue1", "darkslategray4",
  "lemonchiffon1", "#E78AC3", "deeppink3", "#FFFFB3", "burlywood", "firebrick1",
  "#CAB2D6", "darkolivegreen4", "springgreen2", "forestgreen", "skyblue", "#999999",
  "#F781BF", "#80B1D3", "yellow1", "olivedrab1", "magenta1", "blue", "azure2",
  "#B3B3B3", "#BC80BD", "darkorchid4", "#8DA0CB", "#377EB8", "purple",
  "antiquewhite3", "#1F78B4", "firebrick", "#FCCDE5", "gold3", "palegreen",
  "azure4", "azure3", "#B2DF8A", "cadetblue1", "darkviolet", "darksalmon",
  "chartreuse1", "#E5C494", "#4DAF4A", "lightslateblue", "tomato3", "#D9D9D9",
  "#CCEBC5", "slateblue4", "green2", "royalblue1", "#66C2A5", "lightblue1",
  "mediumorchid"
)

read_lines_nonempty <- function(path) {
  x <- readLines(path, warn = FALSE)
  x <- trimws(x)
  x[nzchar(x)]
}

read_optional_table <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  read.table(
    path,
    header = TRUE,
    sep = "\t",
    quote = "",
    stringsAsFactors = FALSE,
    fill = TRUE,
    na.strings = c("", "NA", "null", "NULL", "Null")
  )
}

read_profile_table <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  ext <- tolower(tools::file_ext(path))
  sep <- if (ext == "csv") "," else "\t"
  read.table(
    path,
    header = TRUE,
    sep = sep,
    row.names = 1,
    quote = "",
    stringsAsFactors = FALSE,
    fill = TRUE,
    check.names = FALSE,
    na.strings = c("", "NA", "null", "NULL", "Null")
  )
}

coerce_numeric_profile <- function(profile) {
  for (col in colnames(profile)) {
    profile[[col]] <- suppressWarnings(as.numeric(as.character(profile[[col]])))
  }
  non_numeric <- colnames(profile)[vapply(profile, function(x) all(is.na(x)), logical(1))]
  if (length(non_numeric) > 0) {
    stop(
      sprintf(
        "Profile file has non-numeric column(s): %s",
        paste(non_numeric, collapse = ", ")
      )
    )
  }
  profile
}

profile_value_range <- function(anno_df) {
  mat <- as.matrix(anno_df)
  storage.mode(mat) <- "double"
  c(min(mat, na.rm = TRUE), max(mat, na.rm = TRUE))
}

prepare_gene_annotations <- function(genes_anno, genes2plot) {
  gene_labels <- setNames(genes2plot, genes2plot)
  gene_grp <- NULL

  if (is.null(genes_anno)) {
    return(list(gene_labels = gene_labels, gene_grp = gene_grp))
  }

  if (ncol(genes_anno) < 2) {
    stop("Gene annotation file needs at least two columns: gene ID and display name.")
  }

  genes_anno[[2]] <- trimws(as.character(genes_anno[[2]]))
  bad <- is.na(genes_anno[[2]]) | genes_anno[[2]] == "" |
    tolower(genes_anno[[2]]) == "null"
  genes_anno[[2]][bad] <- genes_anno[[1]][bad]

  if (ncol(genes_anno) >= 3) {
    genes_anno[[3]] <- trimws(as.character(genes_anno[[3]]))
    bad3 <- is.na(genes_anno[[3]]) | genes_anno[[3]] == "" |
      tolower(genes_anno[[3]]) == "null"
    genes_anno[[3]][bad3] <- "grp_unavail"
  }

  genes_anno <- genes_anno[genes_anno[[1]] %in% genes2plot, , drop = FALSE]
  genes_anno <- genes_anno[match(genes2plot, genes_anno[[1]]), , drop = FALSE]

  gene_labels <- setNames(genes_anno[[2]], genes2plot)

  if (ncol(genes_anno) >= 3) {
    gene_grp <- factor(genes_anno[[3]], levels = unique(genes_anno[[3]]))
    names(gene_grp) <- genes_anno[[1]]
  }

  list(gene_labels = gene_labels, gene_grp = gene_grp)
}

prepare_geneset_annotations <- function(gs_anno, geneset2plot) {
  gs_labels <- setNames(geneset2plot, geneset2plot)
  gs_grp <- NULL

  if (is.null(gs_anno)) {
    return(list(gs_labels = gs_labels, gs_grp = gs_grp))
  }

  if (ncol(gs_anno) < 2) {
    stop("Gene-set annotation file needs at least two columns: gene-set ID and display name.")
  }

  gs_anno[[2]] <- trimws(as.character(gs_anno[[2]]))
  bad <- is.na(gs_anno[[2]]) | gs_anno[[2]] == "" | tolower(gs_anno[[2]]) == "null"
  gs_anno[[2]][bad] <- "anno_unavail"

  if (ncol(gs_anno) < 3) {
    gs_anno[[3]] <- "grp_unavail"
  } else {
    gs_anno[[3]] <- trimws(as.character(gs_anno[[3]]))
    bad3 <- is.na(gs_anno[[3]]) | gs_anno[[3]] == "" | tolower(gs_anno[[3]]) == "null"
    gs_anno[[3]][bad3] <- "grp_unavail"
  }

  gs_anno <- gs_anno[gs_anno[[1]] %in% geneset2plot, , drop = FALSE]
  gs_anno <- gs_anno[match(geneset2plot, gs_anno[[1]]), , drop = FALSE]

  gs_labels <- setNames(gs_anno[[2]], geneset2plot)
  gs_grp <- factor(gs_anno[[3]], levels = unique(gs_anno[[3]]))
  names(gs_grp) <- gs_anno[[1]]

  list(gs_labels = gs_labels, gs_grp = gs_grp)
}

align_profile_table <- function(profile, ids) {
  if (is.null(profile)) {
    return(NULL)
  }

  if ("gene_id" %in% colnames(profile)) {
    profile$gene_id <- NULL
  }

  if (ncol(profile) < 1) {
    stop("Profile tables need at least one value column.")
  }

  profile <- coerce_numeric_profile(profile)
  profile <- profile[rownames(profile) %in% ids, , drop = FALSE]
  profile <- profile[match(ids, rownames(profile)), , drop = FALSE]
  rownames(profile) <- ids
  profile
}

build_occurrence_matrix <- function(db, geneset2plot, genes2plot, goi_in_gsg, occur_cutoff) {
  mat <- matrix(
    0,
    nrow = length(genes2plot),
    ncol = length(geneset2plot),
    dimnames = list(genes2plot, geneset2plot)
  )

  for (gs in geneset2plot) {
    gsg_sel <- db$gene[db$tf == gs]
    if (occur_cutoff == 0) {
      mat[gsg_sel, gs] <- 1
      gsg_sel <- gsg_sel[gsg_sel %in% goi_in_gsg]
      mat[gsg_sel, gs] <- 2
    } else {
      gsg_sel <- gsg_sel[gsg_sel %in% genes2plot]
      mat[gsg_sel, gs] <- 2
    }
  }

  mat
}

build_annotations <- function(mat, gs_grp, gs_profile, gene_grp, genes_profile) {
  gs_count <- rowSums(mat > 0)

  row_anno <- ComplexHeatmap::rowAnnotation(
    GeneSetCount = gs_count[rownames(mat)],
    col = list(
      GeneSetCount = circlize::colorRamp2(
        c(min(gs_count), max(gs_count)),
        c("white", "blue")
      )
    ),
    show_legend = TRUE,
    annotation_legend_param = list(title = "Gene Set Count")
  )

  if (!is.null(gs_grp)) {
    top_anno <- ComplexHeatmap::HeatmapAnnotation(
      `Family/Group` = gs_grp[colnames(mat)],
      col = list(
        `Family/Group` = structure(
          COLORSET[seq_along(levels(gs_grp))],
          names = levels(gs_grp)
        )
      ),
      show_legend = TRUE,
      annotation_legend_param = list(title = "Family/Group")
    )
  } else {
    top_anno <- NULL
  }

  profile_ncol <- 0L
  if (!is.null(gs_profile)) {
    anno_df <- gs_profile[colnames(mat), , drop = FALSE]
    gs_range <- profile_value_range(anno_df)
    col_fun <- circlize::colorRamp2(
      c(gs_range[1], 0, gs_range[2]),
      c("darkgreen", "white", "red3")
    )
    col_list <- stats::setNames(
      rep(list(col_fun), ncol(anno_df)),
      colnames(anno_df)
    )
    show_legend <- c(TRUE, rep(FALSE, ncol(anno_df) - 1))
    names(show_legend) <- colnames(anno_df)
    bottom_anno <- ComplexHeatmap::HeatmapAnnotation(
      df = anno_df,
      col = col_list,
      show_legend = show_legend,
      annotation_legend_param = list(title = "Gene Set Profile")
    )
    profile_ncol <- ncol(gs_profile)
  } else {
    bottom_anno <- NULL
  }

  profile_ncol_g <- 0L
  if (!is.null(genes_profile)) {
    anno_df <- genes_profile[rownames(mat), , drop = FALSE]
    gene_range <- profile_value_range(anno_df)
    col_fun <- circlize::colorRamp2(
      c(gene_range[1], (gene_range[1] + gene_range[2]) / 2, gene_range[2]),
      c("darkgreen", "white", "red3")
    )
    col_list <- stats::setNames(
      rep(list(col_fun), ncol(anno_df)),
      colnames(anno_df)
    )
    show_legend <- c(TRUE, rep(FALSE, ncol(anno_df) - 1))
    names(show_legend) <- colnames(anno_df)

    if (!is.null(gene_grp)) {
      right_anno <- ComplexHeatmap::rowAnnotation(
        `Gene Group` = gene_grp[rownames(mat)],
        df = anno_df,
        col = c(
          list(
            `Gene Group` = structure(
              COLORSET[seq_along(levels(gene_grp))],
              names = levels(gene_grp)
            )
          ),
          col_list
        ),
        show_legend = c(`Gene Group` = TRUE, show_legend),
        annotation_legend_param = list(title = "Gene Group")
      )
      profile_ncol_g <- ncol(genes_profile) + 1L
    } else {
      right_anno <- ComplexHeatmap::rowAnnotation(
        df = anno_df,
        col = col_list,
        show_legend = show_legend,
        annotation_legend_param = list(title = "Gene Profile")
      )
      profile_ncol_g <- ncol(genes_profile)
    }
  } else if (!is.null(gene_grp)) {
    right_anno <- ComplexHeatmap::rowAnnotation(
      `Gene Group` = gene_grp[rownames(mat)],
      col = list(
        `Gene Group` = structure(
          COLORSET[seq_along(levels(gene_grp))],
          names = levels(gene_grp)
        )
      ),
      show_legend = TRUE,
      annotation_legend_param = list(title = "Gene Group")
    )
    profile_ncol_g <- 1L
  } else {
    right_anno <- NULL
  }

  list(
    row_anno = row_anno,
    top_anno = top_anno,
    bottom_anno = bottom_anno,
    right_anno = right_anno,
    profile_ncol = profile_ncol,
    profile_ncol_g = profile_ncol_g
  )
}

make_occurrence_heatmap <- function(
    mat,
    gene_labels,
    gs_labels,
    annos,
    column_split = NULL,
    show_heatmap_legend = FALSE
) {
  cell_size <- grid::unit(3, "mm")
  args <- list(
    matrix = mat,
    name = "occurance",
    col = c("0" = COLOR_BG, "1" = COLOR_GS, "2" = COLOR_HL),
    width = ncol(mat) * cell_size,
    height = nrow(mat) * cell_size,
    show_row_names = TRUE,
    show_column_names = TRUE,
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    row_labels = gene_labels[rownames(mat)],
    column_labels = gs_labels[colnames(mat)],
    column_title_rot = 45,
    column_title_gp = grid::gpar(fontsize = 9, fontface = "bold"),
    rect_gp = grid::gpar(col = "white", lwd = 1),
    row_names_gp = grid::gpar(fontsize = 8),
    column_names_gp = grid::gpar(fontsize = 8),
    show_heatmap_legend = show_heatmap_legend,
    left_annotation = annos$row_anno,
    top_annotation = annos$top_anno,
    bottom_annotation = annos$bottom_anno,
    right_annotation = annos$right_anno
  )

  if (!is.null(column_split)) {
    args$column_split <- column_split
    args$cluster_column_slices <- FALSE
  }

  do.call(ComplexHeatmap::Heatmap, args)
}

make_score_heatmap <- function(
    mat,
    score_name,
    gene_labels,
    gs_labels,
    annos,
    column_split = NULL
) {
  cell_size <- grid::unit(3, "mm")
  args <- list(
    matrix = mat,
    name = score_name,
    col = circlize::colorRamp2(
      c(0, max(mat) / 2, max(mat)),
      c(COLOR_BG, COLOR_MID, COLOR_HL)
    ),
    width = ncol(mat) * cell_size,
    height = nrow(mat) * cell_size,
    show_row_names = TRUE,
    show_column_names = TRUE,
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    row_labels = gene_labels[rownames(mat)],
    column_labels = gs_labels[colnames(mat)],
    column_title_rot = 45,
    column_title_gp = grid::gpar(fontsize = 9, fontface = "bold"),
    rect_gp = grid::gpar(col = "white", lwd = 1),
    row_names_gp = grid::gpar(fontsize = 8),
    column_names_gp = grid::gpar(fontsize = 8),
    show_heatmap_legend = TRUE,
    left_annotation = annos$row_anno,
    top_annotation = annos$top_anno,
    bottom_annotation = annos$bottom_anno,
    right_annotation = annos$right_anno
  )

  if (!is.null(column_split)) {
    args$column_split <- column_split
    args$cluster_column_slices <- FALSE
  }

  do.call(ComplexHeatmap::Heatmap, args)
}

pdf_dims <- function(mat, profile_ncol_g, profile_ncol) {
  list(
    width = 8 + ncol(mat) * 0.08 + profile_ncol_g * 0.2,
    height = 10 + nrow(mat) * 0.08 + profile_ncol * 0.2
  )
}

plot_dims_pixels <- function(
    dims,
    dpi = 110,
    padding = 100,
    min_width = 900,
    min_height = 700,
    max_width = 6000,
    max_height = 10000
) {
  list(
    width = min(max_width, max(min_width, round(dims$width * dpi + padding))),
    height = min(max_height, max(min_height, round(dims$height * dpi + padding)))
  )
}

save_heatmap_pdf <- function(ht, path, width, height) {
  grDevices::pdf(path, width = width, height = height)
  on.exit(grDevices::dev.off(), add = TRUE)
  ComplexHeatmap::draw(ht)
  invisible(path)
}

#' Run TF target heatmap analysis
#'
#' @param config list with paths and options (see app.R)
#' @return list with heatmaps, stats, warnings, and optional PDF paths
run_tf_heatmap_analysis <- function(config) {
  warnings_out <- character(0)
  warn <- function(...) {
    warnings_out <<- c(warnings_out, paste(...))
  }

  db <- read.table(
    config$db_path,
    header = TRUE,
    sep = "\t",
    quote = "",
    stringsAsFactors = FALSE
  )

  if (!is.null(config$subset_cat) && length(config$subset_cat) > 0) {
    if (!"Category" %in% colnames(db)) {
      stop("Database has no 'Category' column but subset categories were provided.")
    }
    db <- db[db$Category %in% config$subset_cat, , drop = FALSE]
  }

  geneset2plot <- unique(read_lines_nonempty(config$geneset_path))
  goi <- read_lines_nonempty(config$goi_path)

  if (!all(geneset2plot %in% db$tf)) {
    missing <- setdiff(geneset2plot, unique(db$tf))
    stop(
      sprintf(
        "%d selected gene set(s) not found in the database: %s",
        length(missing),
        paste(head(missing, 5), collapse = ", ")
      )
    )
  }

  gsg <- unique(db$gene[db$tf %in% geneset2plot])
  goi_in_gsg <- goi[goi %in% gsg]
  warn(
    paste0(
      length(goi_in_gsg), " out of ", length(goi),
      " genes of interest are in the selected gene sets."
    )
  )

  occur_cutoff <- config$occur_cutoff
  if (occur_cutoff == 0) {
    genes2plot <- gsg
  } else {
    genes2plot <- goi_in_gsg
  }

  genes_anno_tbl <- read_optional_table(config$genes_anno_path)
  gs_anno_tbl <- read_optional_table(config$gs_anno_path)

  gene_ann <- prepare_gene_annotations(genes_anno_tbl, genes2plot)
  gs_ann <- prepare_geneset_annotations(gs_anno_tbl, geneset2plot)

  gs_profile <- read_profile_table(config$gs_profile_path)
  if (!is.null(gs_profile)) {
    gs_profile <- align_profile_table(gs_profile, geneset2plot)
  }

  genes_profile <- read_profile_table(config$genes_profile_path)
  if (!is.null(genes_profile)) {
    genes_profile <- align_profile_table(genes_profile, genes2plot)
  }

  mat <- build_occurrence_matrix(
    db, geneset2plot, genes2plot, goi_in_gsg, occur_cutoff
  )

  gs_count <- rowSums(mat > 0)
  if (occur_cutoff > 1) {
    keep <- gs_count >= occur_cutoff
    genes2plot <- genes2plot[keep]
    mat <- mat[genes2plot, , drop = FALSE]
    gs_count <- gs_count[genes2plot]
  }

  if (isTRUE(config$diet) && nrow(mat) > 100) {
    genes2plot <- sample(genes2plot, 100)
    mat <- mat[genes2plot, , drop = FALSE]
    gs_count <- gs_count[genes2plot]
    warn("Diet mode: randomly subsampled to 100 genes.")
  }

  if (prod(dim(mat)) > 100000) {
    warn(
      "Heatmap has more than 100,000 cells; rendering may be slow. Reduce gene sets or genes."
    )
  }

  annos <- build_annotations(
    mat,
    gs_ann$gs_grp,
    gs_profile,
    gene_ann$gene_grp,
    genes_profile
  )

  dims <- pdf_dims(mat, annos$profile_ncol_g, annos$profile_ncol)

  ht_occurrence <- make_occurrence_heatmap(
    mat,
    gene_ann$gene_labels,
    gs_ann$gs_labels,
    annos
  )

  ht_occurrence_split <- NULL
  if (!is.null(gs_ann$gs_grp)) {
    ht_occurrence_split <- make_occurrence_heatmap(
      mat,
      gene_ann$gene_labels,
      gs_ann$gs_labels,
      annos,
      column_split = gs_ann$gs_grp[colnames(mat)]
    )
  }

  score_col <- config$score_column
  ht_score <- NULL
  ht_score_split <- NULL

  if (!is.null(score_col) && nzchar(score_col)) {
    if (!score_col %in% colnames(db)) {
      stop(sprintf("Score column '%s' not found in database.", score_col))
    }

    score_mat <- db %>%
      dplyr::select(gene, tf, dplyr::all_of(score_col)) %>%
      tidyr::pivot_wider(
        names_from = tf,
        values_from = dplyr::all_of(score_col),
        values_fill = 0
      ) %>%
      tibble::column_to_rownames("gene") %>%
      as.matrix()

    score_mat <- score_mat[rownames(mat), colnames(mat), drop = FALSE]

    ht_score <- make_score_heatmap(
      score_mat,
      score_col,
      gene_ann$gene_labels,
      gs_ann$gs_labels,
      annos
    )

    if (!is.null(gs_ann$gs_grp)) {
      ht_score_split <- make_score_heatmap(
        score_mat,
        score_col,
        gene_ann$gene_labels,
        gs_ann$gs_labels,
        annos,
        column_split = gs_ann$gs_grp[colnames(mat)]
      )
    }
  }

  score_columns <- setdiff(
    colnames(db),
    c("gene", "tf", "Category")
  )

  list(
    heatmaps = list(
      occurrence = ht_occurrence,
      occurrence_split = ht_occurrence_split,
      score = ht_score,
      score_split = ht_score_split
    ),
    dims = dims,
    dims_px = plot_dims_pixels(dims),
    stats = list(
      n_genesets = length(geneset2plot),
      n_genes = nrow(mat),
      n_goi = length(goi),
      n_goi_in_sets = length(goi_in_gsg),
      n_matrix_cells = prod(dim(mat))
    ),
    warnings = warnings_out,
    score_columns = score_columns
  )
}
