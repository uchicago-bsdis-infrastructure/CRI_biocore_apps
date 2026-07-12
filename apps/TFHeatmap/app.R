library(shiny)
library(ComplexHeatmap)
library(circlize)
library(dplyr)
library(tibble)
library(tidyr)

source("R/heatmap_core.R", local = TRUE)
source("R/ui_helpers.R", local = TRUE)

# TF database is ~29 MB; default Shiny limit is 5 MB
options(shiny.maxRequestSize = 100 * 1024^2)

`%||%` <- function(x, y) if (is.null(x)) y else x

ui <- fluidPage(
  tags$head(
    example_file_labels_js(),
    tags$style(
      HTML("
        .heatmap-scroll {
          overflow: auto;
          max-width: 100%;
          max-height: 85vh;
          border: 1px solid #ddd;
          border-radius: 4px;
          padding: 8px;
          margin-bottom: 12px;
          background: #fafafa;
        }
      ")
    )
  ),
  titlePanel("TF Target Heatmap (DAP-seq)"),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      actionButton("load_all_examples", "Load all example files", class = "btn-sm btn-default"),
      br(), br(),
      h4("Required inputs"),
      fileInput(
        "db_file",
        "TF target database (tab-separated)",
        accept = c(".txt", ".tsv", ".tab")
      ),
      fileInput(
        "geneset_file",
        "Gene sets to plot (one ID per line)",
        accept = c(".txt", ".tsv")
      ),
      fileInput(
        "goi_file",
        "Genes of interest (one ID per line)",
        accept = c(".txt", ".tsv")
      ),
      hr(),
      h4("TF / gene-set options"),
      textInput(
        "subset_cat",
        "Subset by Category (comma-separated, optional)",
        value = "",
        placeholder = "e.g. BP,TFT"
      ),
      numericInput("occur_cutoff", "Occurrence cutoff", value = 1, min = 0, step = 1),
      checkboxInput("diet", "Diet mode (randomly keep at most 100 genes)", value = FALSE),
      selectInput("score_column", "Conservation score column (optional)", choices = c("None" = "")),
      hr(),
      h4("Optional annotation files"),
      fileInput(
        "gs_anno_file",
        "TF annotation (gene_set, label, [group])",
        accept = c(".txt", ".tsv")
      ),
      fileInput(
        "gs_profile_file",
        "TF profiles (e.g. logFC)",
        accept = c(".txt", ".tsv", ".csv")
      ),
      fileInput(
        "genes_anno_file",
        "Gene annotation (gene_id, label, [group])",
        accept = c(".txt", ".tsv")
      ),
      fileInput(
        "genes_profile_file",
        "Gene profiles (e.g. TPM)",
        accept = c(".txt", ".tsv")
      ),
      hr(),
      actionButton("run_btn", "Generate heatmaps", class = "btn-primary"),
      br(), br(),
      verbatimTextOutput("status_text")
    ),
    mainPanel(
      width = 8,
      tabsetPanel(
        tabPanel(
          "Occurrence",
          div(
            class = "heatmap-scroll",
            uiOutput("plot_occurrence_ui")
          ),
          downloadButton("dl_occurrence", "Download PDF")
        ),
        tabPanel(
          "Occurrence (split by family)",
          div(
            class = "heatmap-scroll",
            uiOutput("plot_occurrence_split_ui")
          ),
          downloadButton("dl_occurrence_split", "Download PDF")
        ),
        tabPanel(
          "Conservation score",
          div(
            class = "heatmap-scroll",
            uiOutput("plot_score_ui")
          ),
          downloadButton("dl_score", "Download PDF")
        ),
        tabPanel(
          "Score (split by family)",
          div(
            class = "heatmap-scroll",
            uiOutput("plot_score_split_ui")
          ),
          downloadButton("dl_score_split", "Download PDF")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  result <- reactiveVal(NULL)
  example_paths <- reactiveValues()
  examples_nonce <- reactiveVal(0)

  resolve_path <- function(input_id, upload) {
    examples_nonce()
    if (!is.null(upload)) {
      return(upload$datapath)
    }
    example_paths[[input_id]]
  }

  observe_upload_clears_example <- function(input_id) {
    observeEvent(input[[input_id]], {
      if (!is.null(input[[input_id]])) {
        example_paths[[input_id]] <- NULL
        examples_nonce(examples_nonce() + 1)
      }
    }, ignoreInit = TRUE)
  }

  for (input_id in names(example_files)) {
    observe_upload_clears_example(input_id)
  }

  observeEvent(input$load_all_examples, {
    loaded_labels <- list()
    missing <- character(0)

    for (input_id in names(example_files)) {
      path <- example_file_path(input_id)
      if (is.null(path)) {
        missing <- c(missing, example_files[[input_id]])
      } else {
        example_paths[[input_id]] <- path
        loaded_labels[[input_id]] <- example_files[[input_id]]
      }
    }

    examples_nonce(examples_nonce() + 1)

    if (length(loaded_labels) > 0) {
      session$sendCustomMessage("setFileInputLabels", loaded_labels)
      shiny::showNotification(
        sprintf("Loaded %d example file(s).", length(loaded_labels)),
        type = "message",
        duration = 4
      )
    }
    if (length(missing) > 0) {
      shiny::showNotification(
        paste("Missing examples:", paste(missing, collapse = ", ")),
        type = "warning",
        duration = 8
      )
    }
  })

  parse_subset_cat <- function(x) {
    if (is.null(x) || !nzchar(trimws(x))) {
      return(NULL)
    }
    parts <- trimws(strsplit(x, ",", fixed = TRUE)[[1]])
    parts[nzchar(parts)]
  }

  db_path <- reactive({
    resolve_path("db_file", input$db_file)
  })

  observeEvent(db_path(), {
    path <- db_path()
    if (is.null(path) || !nzchar(path)) {
      return()
    }
    db_head <- read.table(
      path,
      header = TRUE,
      sep = "\t",
      quote = "",
      stringsAsFactors = FALSE,
      nrows = 5
    )
    score_cols <- setdiff(colnames(db_head), c("gene", "tf", "Category"))
    choices <- c("None" = "", stats::setNames(score_cols, score_cols))
    selected <- input$score_column
    if (!is.null(selected) && nzchar(selected) && selected %in% score_cols) {
      updateSelectInput(session, "score_column", choices = choices, selected = selected)
    } else {
      default_score <- "n_cons_species_minfrac0"
      pick <- if (default_score %in% score_cols) default_score else ""
      updateSelectInput(session, "score_column", choices = choices, selected = pick)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$run_btn, {
    db <- db_path()
    geneset <- resolve_path("geneset_file", input$geneset_file)
    goi <- resolve_path("goi_file", input$goi_file)

    if (is.null(db) || is.null(geneset) || is.null(goi)) {
      shiny::showNotification(
        "Upload or load example files for the database, gene sets, and genes of interest.",
        type = "error",
        duration = 8
      )
      return()
    }

    output$status_text <- renderText("Running analysis...")
    shiny::showNotification("Building heatmaps...", type = "message", duration = NULL, id = "run_progress")

    res <- tryCatch(
      {
        config <- list(
          db_path = db,
          geneset_path = geneset,
          goi_path = goi,
          subset_cat = parse_subset_cat(input$subset_cat),
          occur_cutoff = input$occur_cutoff,
          diet = isTRUE(input$diet),
          score_column = {
            if (nzchar(input$score_column)) input$score_column else NULL
          },
          gs_anno_path = resolve_path("gs_anno_file", input$gs_anno_file),
          gs_profile_path = resolve_path("gs_profile_file", input$gs_profile_file),
          genes_anno_path = resolve_path("genes_anno_file", input$genes_anno_file),
          genes_profile_path = resolve_path("genes_profile_file", input$genes_profile_file)
        )
        run_tf_heatmap_analysis(config)
      },
      error = function(e) {
        list(error = conditionMessage(e))
      }
    )

    shiny::removeNotification("run_progress")

    if (!is.null(res$error)) {
      result(NULL)
      output$status_text <- renderText(paste("Error:", res$error))
      shiny::showNotification(res$error, type = "error", duration = 10)
      return()
    }

    result(res)
    msg <- c(
      sprintf(
        "Done: %d gene sets, %d genes plotted, %d/%d GOI in selected sets.",
        res$stats$n_genesets,
        res$stats$n_genes,
        res$stats$n_goi_in_sets,
        res$stats$n_goi
      ),
      res$warnings
    )
    output$status_text <- renderText(paste(msg, collapse = "\n"))
    shiny::showNotification("Heatmaps ready.", type = "message", duration = 4)
  })

  plot_placeholder <- tags$p(
    class = "text-muted",
    style = "padding: 24px;",
    "Load inputs and click Generate heatmaps to view plots."
  )

  register_heatmap_plot <- function(ui_id, plot_id, ht_key) {
    output[[ui_id]] <- renderUI({
      res <- result()
      ht <- if (is.null(res)) NULL else res$heatmaps[[ht_key]]
      if (is.null(ht)) {
        return(plot_placeholder)
      }
      px <- res$dims_px
      plotOutput(plot_id, width = px$width, height = px$height)
    })

    output[[plot_id]] <- renderPlot(
      {
        res <- result()
        req(res)
        ht <- res$heatmaps[[ht_key]]
        req(ht)
        ComplexHeatmap::draw(ht)
      },
      width = function() {
        res <- result()
        if (is.null(res)) 1000 else res$dims_px$width
      },
      height = function() {
        res <- result()
        if (is.null(res)) 700 else res$dims_px$height
      },
      res = 96
    )
  }

  register_heatmap_plot("plot_occurrence_ui", "plot_occurrence", "occurrence")
  register_heatmap_plot("plot_occurrence_split_ui", "plot_occurrence_split", "occurrence_split")
  register_heatmap_plot("plot_score_ui", "plot_score", "score")
  register_heatmap_plot("plot_score_split_ui", "plot_score_split", "score_split")

  make_download <- function(ht_key, prefix) {
    downloadHandler(
      filename = function() paste0(prefix, "_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf"),
      content = function(file) {
        res <- result()
        req(res)
        ht <- res$heatmaps[[ht_key]]
        req(ht)
        save_heatmap_pdf(ht, file, res$dims$width, res$dims$height)
      }
    )
  }

  output$dl_occurrence <- make_download("occurrence", "heatmap")
  output$dl_occurrence_split <- make_download("occurrence_split", "heatmap_split")
  output$dl_score <- make_download("score", "heatmap_score")
  output$dl_score_split <- make_download("score_split", "heatmap_score_split")
}

shinyApp(ui, server)
