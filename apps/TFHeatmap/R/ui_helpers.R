# UI helpers for file inputs with bundled example files

example_files <- list(
  db_file = "TF_targets_At_cscore.txt",
  geneset_file = "GSAD_results_all.txt",
  goi_file = "selected_DEGs.txt",
  gs_anno_file = "ath-258-tf-info_simple_pp.txt",
  gs_profile_file = "logFC.txt",
  genes_anno_file = "gene_id_name_mapping.txt",
  genes_profile_file = "genes_tpm.txt"
)

app_test_dir <- function() {
  candidates <- c(
    file.path(getwd(), "test"),
    file.path(dirname(getwd()), "test"),
    "/app/test"
  )
  for (dir in candidates) {
    if (dir.exists(dir)) {
      return(normalizePath(dir, winslash = "/"))
    }
  }
  file.path(getwd(), "test")
}

example_file_path <- function(input_id) {
  fname <- example_files[[input_id]]
  if (is.null(fname)) {
    return(NULL)
  }
  path <- file.path(app_test_dir(), fname)
  if (!file.exists(path)) {
    return(NULL)
  }
  normalizePath(path, winslash = "/")
}

example_file_labels_js <- function() {
  tags$script(HTML("
    Shiny.addCustomMessageHandler('setFileInputLabels', function(labels) {
      Object.keys(labels).forEach(function(id) {
        var input = document.getElementById(id);
        if (!input) return;
        var group = input.closest('.input-group');
        if (!group) return;
        var textBox = group.querySelector('input.form-control[type=\"text\"]');
        if (textBox) textBox.value = labels[id];
      });
    });
  "))
}
