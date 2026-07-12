##  This is the user-interface application for Single cell data visualization 
## with different methods together with method comparison
## Developed by Geetha Priyanka Yerradoddi, update from Dec, 2024 - Mar 2025
## Developed by Yan Li, yli22@bsd.uchicago.edu, Nov 2024
## --------------------------------------------------------------------------- ##
## library requirements for UI
library(shiny)
library(shinydashboard)
library(DT)
library(bslib)
library(shinyjs)
library(dplyr)
library(readr)
library(readxl) 
library(shinyWidgets)
library(tibble)
library(plotly)
## --------------------------------------------------------------------------- ##
## Inputs in the application

# Introduction Tab
# $rdsPath - Input path of the RDS object supplies
# $rdsUploadSubmit - access the submit button after you enter RDS object path
# $rdsUploadStatusMessage - Status message determining if the RDS object loaded successfully or if there is an issue with the load

# Cohort Cell Summary Tab
# $Category1 - Input Rows of Summary data table in Cohort Cell Summary tab
# $Category2 - Input Columns of Summary data table in Cohort Cell Summary tab
# $compareCellSummaryCategory - Button input to calculate cell summary table after selection of Rows and Columns using Category1 and Category2 
# $compareCellSummaryTable - Cell Summary Table that is visualized

# Violin Plots Tab
# $VlnSelectedGenes - Input Selected genes from list of genes present in dataset SPECIFICALLY for violin plot
# $VlnClusterSelect - Input Clusters for visualizing in the violin Plot
# $VlnSampleSepSelect - Input (If needed) Sample/treatment effect separation
# $VlnPlot - Final Violin Plot visualization output

# Feature Plots Tab
# $FeatureSelectedGenes - Input Selected genes from list of genes present in dataset SPECIFICALLY for Feature Plot
# $FeatureClusterSelect - Input Clusters for labelling in the Feature Plot
# $FeatureSampleSepSelection - Input (If needed) Sample/treatment effect separation
# $FeaturePlot - Final Feature Plot visualization output

# Dot Plot Tab
# $DotSelectedGenes - Input Selected genes from list of genes present in dataset SPECIFICALLY for Dot Plot
# $DotClusterSelect - Input Clusters for visualizing the gene expression (Y-axis of Dot plot)
# $DotPlot - Final Dot Plot visualization output

## --------------------------------------------------------------------------- ##
## A total of 5 UI pages shown in the end, including the first introduction page 
## 1. Introduction pages content - 2 sub pages, Might add FAQ
Introductionex = fluidPage(
  h3("1. Abstract/Motivation"),
  p("Single-cell RNA sequencing (scRNA-seq) has become a powerful tool for uncovering cellular diversity and understanding tissue composition at high resolution. Critical information about biological differences at the cellular level can be obtained by comparing scRNA-seq datasets (treatment vs. control). We used R Shiny to create scVizApp (Single-cell Visualization Application), which enables users to easily explore and interpret scRNA-seq data, in order to make such analysis more accessible.",br(),
  
"Our application focuses on comparative exploration by enabling users to visualize cell populations under various experimental conditions and interactively modify metadata. Regardless of the experiment model, users can create and examine Multi-Dimensional Plots, Feature Plots, Violin Plots, and Dot Plots by merely uploading an RDS/Rdata file.",br(),

"Without requiring coding, scVizApp seeks to facilitate intuitive data exploration and promote deeper biological insights. This tool offers a practical solution for experimental researchers to independently investigate and interpret their single-cell datasets.
",br()),
  h3("2. Application Outline:"),
  div(
    style = "margin-left: 20px;", # indentation for subsection
    h4("2.1 Input Requirements"),
    p("The application requires an integrated Seurat-compatible.RDS or.RData file that includes a metadata table and a normalized gene expression count matrix. The data should be preprocessed (post-integration) and ready for visualization, with components such as graphs and reductions.")
  ),
  
  div(
    style = "margin-left: 20px;", # indentation for subsection
    h4("2.2 Application Structure"),
    p("scVizApp streamlines the exploration and comparison of single-cell datasets, offering five intuitive navigation sections:"),
    p( strong("1.	Load Input Data:"), "Easily upload .RDS or .RData files directly from your computer using encrypted string. All uploaded datasets are preserved, allowing quick access for comparisons or reanalysis. Navigate seamlessly through all app sections using the header navigation bar or the handy navigation buttons next to the ‘Load Data’ option."),
    p( strong("2. Application Overview:"), "Get a clear and succinct walkthrough of the app’s workflow and key functionalities. This is ideal for new users or collaborators who need a quick tour of scVizApp’s capabilities."),
    p( strong("3. Cell Summary Profile:"), "Discover the distribution of cells across experimental conditions. Explore cell counts and proportions to gain insights into sample composition and detect differences between conditions."),
    p( strong("4. Multi-Dimensional Plots:"), "Visualize cell cluster distributions using UMAP and t-SNE projections. These powerful 2D plots are essential for annotating cell types and revealing the complex structure of high-dimensional single-cell data."),
    p( strong("5. Expression-Level Visualizations:"), "Dive deep into gene expression with flexible visualization tools, including Violin Plots, Feature Plots, and Dot Plots. Select your markers of interest and conveniently download publication-quality plots for reports or presentations."),
  ),
h3("3. Application Outline:"),
p(strong("Data Access and Initialization"),br(),
  "To ensure secure and streamlined data access, the Biocore team provisions an encrypted string for each user, granting access only to RDS files pertaining to the client’s specific analyses. Upon inputting this string, users are permitted to access all modules within the scVizApp platform."),
p(strong("Data Loading"),br(),
  "Users initiate data analysis via the 'Load/Input Data' interface. This page enables users to select an RDS file from a dropdown menu populated dynamically according to the encrypted authorization string. Upon selection, the user triggers data upload by activating the ‘LOAD DATA’ button. A progress bar positioned above the button denotes the upload status. Upon successful upload, confirmation is provided via a notification displaying the completed file name (e.g., '✅ File uploaded: '). Subsequently, the application transitions automatically to the Cell Summary Profile module (Section 3.2)."),
p(strong("User Guidance"),br(),
  "scVizApp includes an integrated 'Overview' manual, accessible via the navigation tab, which delineates each module’s functionality. This documentation provides an abstract, detailed outline, and comprehensive descriptions, facilitating intuitive user engagement and workflow navigation."),
h3("4.Analytical Modules"),
h4("4.1 Cell Summary Profile",style = "margin-left: 20px;"),
div(
  style = "margin-left: 20px;", # indentation for subsection
  h4("4.1.1 Cell Summary"),
  p("This module empowers users to interrogate cell distribution across samples, Seurat clusters, cell types, or experimental conditions—metadata prerequisites included within the uploaded RDS file. Users may designate specific metadata variables as rows and columns to compute and visualize cell abundance and proportional distribution accordingly. Results are depicted via a stacked bar plot, illustrating distribution clarity. The module supports versatile summary calculations under varying conditions, and users may export results as CSV files or download the graphical output in PDF format. Plot aesthetics (height and width) are adjustable per user requirements."),
  h4("4.1.2 Multi-Dimensional Plots"),
  p("This module facilitates visualization of dimensionality reductions present within the RDS file, including PCA, UMAP, or tSNE embeddings. Users may select from available reductions and annotations to explore cluster organization. Cluster labels are selectable through a dropdown menu, and the option to facet plots based on additional metadata is provided via the 'Clusters Split' parameter. Multi-dimensional plots are exportable in PDF format with user-defined dimensions.")),
h4("4.2 Violin Plots",style = "margin-left: 20px;"),
p("Violin plots enable visualization of gene expression distributions at single-cell resolution across clusters. The user may select genes of interest (markers) via a dropdown populated by the normalized expression matrix. The x-axis can be configured to display the expression distribution across selected clusters or metadata variables. Faceting by samples or other metadata is supported to facilitate comparative expression analysis. All violin plots are downloadable in PDF format with customizable sizing.",style = "margin-left: 20px;"),
h4("4.3 Feature Plots",style = "margin-left: 20px;",style = "margin-left: 20px;"),
p("Feature plots project marker gene expression onto a multidimensional embedding (default: UMAP), aiding spatial interpretation of expression patterns at single-cell resolution. Marker selection mirrors the interface of the Violin Plot module, and the feature plots allow faceting by experimental variables if desired. Outputs are exportable as PDF files with flexible plot dimensions.",style = "margin-left: 20px;"),
h4("4.4 Dot Plots",style = "margin-left: 20px;"),
p("In the Dot Plot module, users can examine relative average expression of selected markers per cluster, with dot size and color encoding percent expression and average expression levels, respectively. The platform supports comparison of multiple genes/markers, provides cell type and cell cycle phase marker options (Human only), and allows users to upload custom gene lists via Excel/CSV/TXT files for bespoke analyses. Dot plots are downloadable in adjustable PDF formats for integration into downstream reports or publications.",style = "margin-left: 20px;"),
h3("Output Customization and Export"),
p("All plots can be resized prior to export, and downloadable options include high-resolution PDF for figures and CSV for tabular summaries. This ensures compatibility with downstream analysis pipelines and publication standards."),
h4("Usability"),
p("scVizApp is designed for users with varying expertise in single-cell analysis, providing"),
p(strong("•	Straightforward navigation")," via clearly labeled tabs and modules.",style = "margin-left: 20px;"),
p(strong("•	Dropdown- and button-based inputs")," with real-time feedback.",style = "margin-left: 20px;"),
p(strong("•	Automatic feature detection ")," (e.g., reductions, markers) lowers the barrier for non-programmers.",style = "margin-left: 20px;"),
p(strong("•	Seamless export options")," allow users to integrate figures and data into downstream publications or presentations.",style = "margin-left: 20px;"),
p(strong("•	Security:")," Robust data access via encrypted keys ensures client privacy and analysis exclusivity.",style = "margin-left: 20px;"),
p(strong("•	User-friendly:")," Intuitive UI/UX minimizes required training time and improves analysis speed.",style = "margin-left: 20px;"),
p(strong("•	Comprehensiveness:")," Covers all standard visualization needs for single-cell analysis (cell summaries, reductions, expression plots).",style = "margin-left: 20px;"),
p(strong("•	Customizability:")," Adjustable plot dimensions, faceting, and gene selection empower users to tailor analyses to specific needs.",style = "margin-left: 20px;"),
p(strong("•	Interoperability:")," Outputs are ready for publication or further computational analysis.",style = "margin-left: 20px;"),
p(strong("•	Scalability:")," Capable of handling varying dataset sizes and complexities, accommodating heterogeneous client requirements.",style = "margin-left: 20px;"),
p(strong("•	Documentation:")," Built-in guidance streamlines onboarding, troubleshooting, and workflow optimization.",style = "margin-left: 20px;"),
p(strong("•	Efficiency:")," Automatic module progression and preset workflows save time and streamline the analysis process.",style = "margin-left: 20px;"),
p(strong("•	Versatile metadata-driven summaries")," with user-configurable axes and grouping.",style = "margin-left: 20px;"),
 )


Introduction <- fluidPage(
    # h3("Overview & Guidelines"),
  p(),
    p("Welcome to the Single-cell RNA sequencing Visualization Application -", strong("scVizApp"), "! This platform provides an interactive workspace for exploring summaries of cell types and clusters, interactive plots of gene expression, and access to downstream analyses.", style = "font-family: Helvetica Neue;"),
    p("Select an RDS or RData file using the file dialog. After loading, the following contents will be displayed and automatically navigated to Cell Summary Profile Module:", style = "font-family: Helvetica Neue;"),
    div(style = "font-weight: bold;",
        p("\u2705 File uploaded: <file name>")  # ✅ symbol
    ),
    fluidRow(
      div(
        tags$head(
          tags$style(HTML("
          .action-button-custom {
            margin-top: 0.5em;
            background-color: #800000;
            padding: 5px 15px;
            font-family: Andika, Arial, sans-serif;
            font-size: 0.8em;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: #fff;
            text-shadow: 0px 1px 10px #000;
            border-radius: 10px;
            box-shadow: rgba(0, 0, 0, .55) 0 1px 1px;
            Shiny.addCustomMessageHandler('uploadProgress', function(message) {
        // Update progress bar via Shiny.setInputValue
        Shiny.setInputValue('upload_progress', message);
      });
      
      .action-button-custom-centre {
            display: block;
            
            margin-top: 0.5em;
            background-color: #800000;
            padding: 5px 15px;
            font-family: Andika, Arial, sans-serif;
            font-size: 0.8em;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: #fff;
            text-shadow: 0px 1px 10px #000;
            border-radius: 10px;
            box-shadow: rgba(0, 0, 0, .55) 0 1px 1px;
            Shiny.addCustomMessageHandler('uploadProgress', function(message) {
        // Update progress bar via Shiny.setInputValue
        Shiny.setInputValue('upload_progress', message);
      });
      
      
      $(document).on('shiny:fileuploadprogress', function(event) {
        // Send progress to Shiny (0-100)
        var progress = Math.round(event.progress * 100);
        Shiny.setInputValue('upload_progress', progress);
      });
          }"))),
        
        tags$h5("Load RDS file of your choice below", style = "color: #337ab7;"),
        selectInput("RDSFile", "", choices = NULL, width = "100%"),
        
        progressBar(
          id = "load2",
          value = 0,
          total = NULL,
          title = "",
          status = "info"
        ),
        textOutput("uploadStatus"),
        actionButton("rdsUploadSubmit", "Load Data", class = "action-button-custom"),
        actionButton("CSSubmit", "Cell Summary", class = "action-button-custom"),
        actionButton("VPSubmit", "Violin Plots", class = "action-button-custom"),
        actionButton("FPSubmit", "Feature Plots", class = "action-button-custom"),
        actionButton("DPSubmit", "Dot Plots", class = "action-button-custom"),
        actionButton("HMapSubmit", "Heatmaps", class = "action-button-custom"),
        actionButton("ScoringSubmit", "Scoring", class = "action-button-custom"),
        actionButton("DETestingSubmit", "DE Testing", class = "action-button-custom")
      )
    ),
    mainPanel(
      textOutput("rdsUploadStatusMessage")
    ),
  p(),
  p("Click on the link below to access ", strong("scVizApp Test Data"), "to download test data required to work on scVizApp",style = "font-family: Helvetica Neue;"),
  tags$a("scVizApp Test Data", href = " https://drive.google.com/file/d/1z9oIqS5l_X92Pz2w7vr4spLcvXSlu4Hw/view?usp=share_link", target = "_blank", ),
  p(),
  p("Click on the link below to access ", strong("scVizApp Tutorial"), "with detailed step by step protocol to reproduce the analysis",style = "font-family: Helvetica Neue;"),
  tags$a("scVizApp Tutorial", href = "https://docs.google.com/document/d/14wJ0AMBkk05YkLSoJlVIpaceHFqwRysl/edit?usp=sharing&ouid=104169265426479626636&rtpof=true&sd=true", target = "_blank", ),
  p()
  
)

## ---------------------------------------------------------------------------- ##
## 2. Cohort summary tab
sample_description <- shinyUI(
  fluidPage(
    div(
      p("Samples and conditions included in current analysis", style = "font-family: Helvetica Neue;",
        style = "font-weight: bold")
    ),
    mainPanel(
      DTOutput("sampleDescriptionTable")
    ),
    hr(),
    p(strong("Additional Option:")," Press the following button to add new column with cell type annotations/clusters/conditions to above sample description data using one of the columns as reference",style = "font-family: Helvetica Neue;",),
    actionButton("AddMetadata", "Select" , style = 'display:block; margin-top:10px;margin-left: auto;margin-right: auto;', class = "action-button-custom", width = '50%'),
    p(),
    ## Conditional Panel to add new metadata depeding on metadata columns --------- ##
    conditionalPanel(
      condition = "input.AddMetadata == true",
      sidebarLayout(
        sidebarPanel(
          
          selectizeInput("RefColName", "Select metadata column:",  choices = NULL, multiple = F),
          
          actionButton("RefColSelect", "Load Column Values",style = 'display: inline-block; margin-top:10px;', class = "action-button-custom"),
          
          hr(),
          
          textInput("NewColName", "New metadata column name:", value = "new_idents"),
          actionButton("ApplyNames", "Apply",style = 'display: inline-block; margin-top:10px;', class = "action-button-custom"),
        ),
        
        mainPanel(
          uiOutput("RefColContent"),
          verbatimTextOutput("out")
        )
      )
    ),
  )
)

Cell_Summary <- shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(
          div(
            p("Select a Category to calculate cell summary",
              style = "font-weight: bold")
          )
        ),
        fluidRow(
          selectInput(
            inputId = "Category1",
            label = "Row Category",
            choices = NULL,width = '100%'
          )
        ),
        fluidRow(
          selectInput(
            inputId = "Category2",
            label = "Column Category",
            choices = NULL,width = '100%'
          )
        ),
        actionButton(
          "compareCellSummaryCategory",
          "Load Summary Table",
          width = '95%', class = "action-button-custom"
        ),
        downloadButton("download_CellSummary", "Download table as CSV", class = "action-button-custom"),
        fluidRow(
          column(6,
                 textInput("barplot_width", "Plot Width (in):", value = "8")
          ),
          column(6,
                 textInput("barplot_height", "Plot Height (in):", value = "6")
          )
        ),
        fluidRow(
          column(6,
                 textInput("barPlotXtextSize", "X-axis Text Size", value = "14")
          ),
          column(6,
                 textInput("barPlotYtextSize", "Y-axis Text Size", value = "14")
          )
        ),
        fluidRow(
          column(12,
                 textInput("barPlotLtextSize", "Legend Text Size", value = "14")
          )
        ),
        downloadButton("download_CellSummaryPlot", "Download Plot as PDF", class = "action-button-custom"),
      ),
      mainPanel(
        DTOutput("compareCellSummaryTable"),
        # Output for the comparison table
        plotOutput("CellSummaryBarPlot")
      )
    )
  )
)

## Add UMAP and tSNE figures
## 2. Cohort summary tab
umap_plots <- shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(
          div(
            p("Select cluster to visualize UMAP",
              style = "font-weight: bold")
          )
        ),
        fluidRow(
          selectInput(
            inputId = "MdVis",
            label = "Multi_Dimensionality Option",
            choices = NULL,
            # choices = c('UMAP','tSNE'),
            # selected = 'UMAP',
            width = '100%'
          )
        ),
        fluidRow(
          selectInput(
            inputId = "Categoryumap",
            label = "Clusters",
            choices = NULL,width = '100%'
          )
        ),
        fluidRow(
          selectInput(
            inputId = "MdSplitby",
            label = "Clusters Split",
            choices = "None",width = '100%'
          )
        ),
        fluidRow(
          tags$h5(("Select suitable color palette")),
          radioButtons("umap_palette_package", "Palette source:",
                       choices = c("Default (Seurat)" = "Default",
                                   "dittoSeq (up to 40)" = "dittoSeq",
                                   "Polychrome (up to 32)" = "Polychrome"),
                       selected = "Default"),
          
          conditionalPanel(
            condition = "input.umap_palette_package == 'Polychrome'",
            selectInput("umap_palette_name", "Polychrome palette:",
                        choices = c("glasbey", "alphabet", "kelly", "dark", "light"),
                        selected = "glasbey")
          ),
          actionButton(
            "LoadUMAP",
            "Load UMAP",
            width = '75%',
            class = "action-button-custom"
          )),
        fluidRow(
          column(6,
                 textInput("umapplot_width", "Plot Width (in):", value = "8")
          ),
          column(6,
                 textInput("umapplot_height", "Plot Height (in):", value = "6")
          )
        ),
        fluidRow(
          column(6,
                 textInput("mdPlotXtextSize", "X-axis Text Size", value = "14")
          ),
          column(6,
                 textInput("mdPlotYtextSize", "Y-axis Text Size", value = "14")
          )
        ),
        fluidRow(
          column(12,
                 textInput("mdPlotLtextSize", "Legend Text Size", value = "14")
          )
        ),
        downloadButton("download_UMAPs", "Download plot as PDF", class = "action-button-custom"),
      ),
      mainPanel(
        plotOutput("UMAPPlots", height = "900px")  # Output for the comparison table
      )
    )
  )
)

## ---------------------------------------------------------------------------- ##
## 3. 'VlnPlot' page to include Violin Plots
VlnPlot = shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(
          div(
            tags$h3("Select the markers (Genes) to visualize using Violin Plots", style = "color: #337ab7;"),  # Title styled like a primary box
            # title = "Upload RDS File", status = "primary", solidHeader = TRUE, collapsible = TRUE,
            selectizeInput(inputId = "VlnSelectedGenes",
                           label = "Select Genes",
                           choices = NULL,  # Choices will be updated based on loaded data
                           multiple = TRUE)
          )),
        # fluidRow(div(
        #   tags$h3("Select the markers (Genes) to understand cell types and phases using Violin Plots", style = "color: #337ab7;"),  # Title styled like a primary box
        #   selectizeInput(inputId = "VlnSelectedGenesTypes",
        #                  label = "Select cell types and Phases",
        #                  choices = NULL,  # Choices will be updated based on loaded data
        #                  multiple = TRUE)
        # )),
        div(
          # style = "border: 1px solid #dcdcdc; padding: 20px; margin-bottom: 20px; border-radius: 5px; box-shadow: 2px 2px 10px #aaa;",
          p("Select clusters and additional separation if needed"
            , style="font-weight: bold"),
          
          
          fluidRow(selectInput(inputId="VlnClusterSelect",
                               label="Clusters to Visualize (x axis)",
                               selected="seurat_clusters", choices = NULL, multiple = F, width = '100%')
          ),
          
          fluidRow(selectInput(inputId="VlnSampleSepSelect",
                               label="Additional separation",
                               selected=NULL, choices = NULL, multiple = F, width = '100%')
          ),
          fluidRow(
            tags$h5(("Select suitable color palette")),
            radioButtons("vln_palette_package", "Palette source:",
                         choices = c("Default (Seurat)" = "Default",
                                     "dittoSeq (up to 40)" = "dittoSeq",
                                     "Polychrome (up to 32)" = "Polychrome"),
                         selected = "Default"),
            
            conditionalPanel(
              condition = "input.vln_palette_package == 'Polychrome'",
              selectInput("vln_palette_name", "Polychrome palette:",
                          choices = c("glasbey", "alphabet", "kelly", "dark", "light"),
                          selected = "glasbey")
            )),
          actionButton("VlnClusterSelection", "Load Violin Plot" , style = 'display: inline-block; margin-top:10px;', class = "action-button-custom"),
          fluidRow(
            column(6,
                   textInput("vlnplot_width", "Plot Width (in):", value = "8")
            ),
            column(6,
                   textInput("vlnplot_height", "Plot Height (in):", value = "6")
            )
          ),
          fluidRow(
            column(6,
                   textInput("vlnPlotXtextSize", "X-axis Text Size", value = "14")
            ),
            column(6,
                   textInput("vlnPlotYtextSize", "Y-axis Text Size", value = "14")
            )
          ),
          fluidRow(
            column(12,
                   textInput("vlnPlotLtextSize", "Legend Text Size", value = "14")
            )
          ),
          # actionButton("VlnSampleSepSelection", "Select", style = 'display: inline-block; margin-top:-50px;'),
          downloadButton("download_VlnPlot", "Download Plot as PDF", class = "action-button-custom"),
        )
      ),
      mainPanel(
        plotOutput("VlnPlot", height = "900px")
      )
    )
  )
)

## ---------------------------------------------------------------------------- ##
## 4. 'FeaturePlot' to include Feature Plots
FeaturePlot = shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(
          div(
            # style = "border: 1px solid #dcdcdc; padding: 20px; margin-bottom: 20px; border-radius: 5px; box-shadow: 2px 2px 10px #aaa;",
            tags$h3("Select the markers (Genes) to visualize using Feature Plots", style = "color: #337ab7;"),  # Title styled like a primary box
            # title = "Upload RDS File", status = "primary", solidHeader = TRUE, collapsible = TRUE,
            p("Please select multiple categories from the available group levels", style = "font-weight: bold"),
            selectizeInput(inputId = "FeatureSelectedGenes",
                           label = "Select Genes",
                           choices = NULL,  # Choices will be updated based on loaded data
                           multiple = TRUE)
          )
          # verbatimTextOutput("FeatureSelectedGenes")
        ),
        # fluidRow(div(
        #     tags$h3("Select the markers (Genes) to understand cell types and phases using Feature Plots", style = "color: #337ab7;"),  # Title styled like a primary box
        #     selectizeInput(inputId = "FeatureSelectedGenesTypes",
        #                    label = "Select Cell Types and Phases",
        #                    choices = NULL,  # Choices will be updated based on loaded data
        #                    multiple = TRUE)
        #   )),
        div(
          # style = "border: 1px solid #dcdcdc; padding: 20px; margin-bottom: 20px; border-radius: 5px; box-shadow: 2px 2px 10px #aaa;",
          p("Select clusters and sample separated (Whole) options if needed - default set to seurat clusters and no separation"
            , style="font-weight: bold"),
          
          
          fluidRow(selectizeInput(inputId="FeatureClusterSelect",
                                  label="Clusters to Visualize",
                                  selected="seurat_clusters", choices = NULL, multiple = F, width = '100%')
          ),
          
          fluidRow(selectizeInput(inputId="FeatureSampleSepSelect",
                                  label="Additional separation",
                                  selected="orig.ident", choices = NULL, multiple = F, width = '100%')
          ),
          # actionButton("FeatureSampleSepSelection", "Select", style = 'display: inline-block; margin-top:-50px;'),
          fluidRow(
            tags$h5(("Select suitable color palette")),
            radioButtons("fp_palette_package", "Palette source:",
                         choices = c("Default (grey → blue)" = "Default",
                                     "viridis" = "viridis"),
                         selected = "Default"),
            
            conditionalPanel(
              condition = "input.fp_palette_package == 'viridis'",
              selectInput("fp_palette_name", "Viridis option:",
                          choices = c("viridis", "magma", "inferno", "plasma",
                                      "cividis", "turbo", "mako", "rocket"),
                          selected = "viridis")
            ),
          ),
          actionButton("FeatureClusterSelection", "Load Feature Plot" , style = 'display: inline-block; margin-top:10px;', class = "action-button-custom"),fluidRow(
            column(6,
                   textInput("featureplot_width", "Plot Width (in):", value = "8")
            ),
            column(6,
                   textInput("featureplot_height", "Plot Height (in):", value = "6")
            )
          ),
          fluidRow(
            column(6,
                   textInput("FPlotXtextSize", "X-axis Text Size", value = "14")
            ),
            column(6,
                   textInput("FPlotYtextSize", "Y-axis Text Size", value = "14")
            )
          ),
          fluidRow(
            column(12,
                   textInput("FPlotLtextSize", "Legend Text Size", value = "14")
            )
          ),
          downloadButton("download_FeaturePlot", "Download Plot as PDF", class = "action-button-custom"),
        )
      ),
      mainPanel(
        plotOutput("FeaturePlot", height = "900px")
      )
    )
  )
)

## ---------------------------------------------------------------------------- ##
## 5. 'DotPlot' to include Dot Plots
library(shiny)

DotPlot <- shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        # ---- Gene Selection Header ----
        div(
          tags$h3("Select the markers (Genes) to visualize using Dot Plot",
                  style = "color: #337ab7; font-weight: bold;"),
          selectInput("DotInputType",
                      label = "Choose gene selection source:",
                      choices = c(
                        "From loaded file" = "uploadedMarkers",
                        "From Pre-loaded gene types" = "PreGeneTypes",
                        "From file (with gene & geneType columns)" = "excelSource"
                      )
          )
        ),
        
        # ---- Conditional: From uploaded RDS markers ----
        conditionalPanel(
          condition = "input.DotInputType == 'uploadedMarkers'",
          selectizeInput(
            inputId = "DotSelectedGenes",
            label = "Select Genes",
            choices = NULL,  # updated in server
            multiple = TRUE
          )
        ),
        
        # ---- Conditional: From preloaded gene types ----
        conditionalPanel(
          condition = "input.DotInputType == 'PreGeneTypes'",
          tags$h3("Select markers to understand cell types and phases using Dot Plots",
                  style = "color: #337ab7;"),
          selectizeInput(
            inputId = "DotSelectedGenesTypes",
            label = "Select Cell Types and Phases",
            choices = NULL,  # updated in server
            multiple = TRUE
          )
        ),
        
        # ---- Conditional: From Excel/CSV/TXT ----
        conditionalPanel(
          condition = "input.DotInputType == 'excelSource'",
          tags$h3("Upload interested genes and their classification",
                  style = "color: #337ab7;"),
          fileInput("dotPlotFile",
                    "Upload Gene Data (Excel/CSV/TXT)",
                    accept = c(".csv", ".txt", ".xlsx",".xls",".tsv",".CSV", ".TXT", ".XLSX",".XLS",".TSV")),
          # actionButton("loadDotPlotData", "Load Data", class = "action-button-custom"),
          # textOutput("fileUploadStatus")
        ),
        
        # ---- Cluster selection ----
        div(
          p("Select clusters and separation options if needed - default set to Seurat clusters and no separation",
            style = "font-weight: bold"),
          selectInput(
            inputId = "DotClusterSelect",
            label = "Clusters to Visualize (Y axis)",
            selected = "seurat_clusters",
            choices = NULL,
            multiple = FALSE,
            width = '100%'
          ),
          fluidRow(selectInput(inputId="DotSampleSepSelect",
                               label="Additional separation",
                               selected=NULL, choices = NULL, multiple = F, width = '100%')
          ),
          actionButton("DotClusterSelection", "Load Plot", class = "action-button-custom")
        ),
        
        # ---- Plot size inputs ----
        fluidRow(
          column(6, textInput("dotplot_width", "Plot Width (in):", value = "8")),
          column(6, textInput("dotplot_height", "Plot Height (in):", value = "6"))
        ),
        fluidRow(
          column(6,
                 textInput("dotPlotXtextSize", "X-axis Text Size", value = "14")
          ),
          column(6,
                 textInput("dotPlotYtextSize", "Y-axis Text Size", value = "14")
          )
        ),
        fluidRow(
          column(6,
                 textInput("dotPlotLtextSize", "Legend Text Size", value = "14")
          ),
          column(6,
                 textInput("dotPlotXangle", "X-axis Text Angle (0 - 90)", value = "45")
          )
        ),
        
        # ---- Download ----
        downloadButton("download_DotPlot", "Download Plot as PDF", class = "action-button-custom")
      ),
      
      mainPanel(
        plotOutput("DotPlot", height = "750px")
      )
    )
  )
)

## ---------------------------------------------------------------------------- ##
## 6. 'Heatmaps' to include Feature Plots
Heatmaps = shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(div(
          tags$h3("Select required markers for better interpretability ", style = "color: #337ab7;"),  # Title styled like a primary box
          selectizeInput(
            inputId = "HmapSelectedGenes",
            label = "Select Genes",
            choices = NULL,  # updated in server
            multiple = TRUE
          )
        )),
        div(
          # style = "border: 1px solid #dcdcdc; padding: 20px; margin-bottom: 20px; border-radius: 5px; box-shadow: 2px 2px 10px #aaa;",
          p("Select clusters and sample separated (Whole) options if needed - default set to seurat clusters and no separation"
            , style="font-weight: bold"),
          
          
          fluidRow(selectizeInput(inputId="HeatmapClusterSelect",
                                  label="Clusters to Visualize",
                                  selected="seurat_clusters", choices = NULL, multiple = F, width = '100%')
          ),
          actionButton("HeatmapSelection", "Select" , style = 'display: inline-block; margin-top:10px;', class = "action-button-custom"),fluidRow(
            column(6,
                   textInput("Heatmap_width", "Plot Width (in):", value = "8")
            ),
            column(6,
                   textInput("Heatmap_height", "Plot Height (in):", value = "6")
            )
          ),
          fluidRow(
            column(6,
                   textInput("HmaptXtextSize", "X-axis Text Size", value = "14")
            ),
            column(6,
                   textInput("HmapYtextSize", "Y-axis Text Size", value = "14")
            )
          ),
          fluidRow(
            column(12,
                   textInput("HmapLtextSize", "Legend Text Size", value = "14")
            )
          ),
          
          
          downloadButton("download_Heatmap", "Download Plot as PDF", class = "action-button-custom"),
        )
      ),
      mainPanel(
        plotOutput("Heatmap", height = "900px")
      )
    )
  )
)

## ---------------------------------------------------------------------------- ##
## 7. 'Scoring' to include AddModuleScore
Scoring <- shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        # ---- Gene Selection Header ----
        div(
          tags$h3("Select the markers (Genes) to calculate normalized cell-specific score",
                  style = "color: #337ab7; font-weight: bold;"),
          selectInput("ScoringInputType",
                      label = "Choose gene selection source:",
                      choices = c(
                        "From loaded file" = "uploadedMarkers",
                        "From file (with gene column)" = "excelSource"
                      )
          )
        ),
        
        # ---- Conditional: From uploaded RDS markers ----
        conditionalPanel(
          condition = "input.ScoringInputType == 'uploadedMarkers'",
          selectizeInput(
            inputId = "ScoringSelectedGenes",
            label = "Select Genes",
            choices = NULL,  # updated in server
            multiple = TRUE
          )
        ),
        
        # ---- Conditional: From Excel/CSV/TXT ----
        conditionalPanel(
          condition = "input.ScoringInputType == 'excelSource'",
          tags$h3("Upload interested genes and their classification",
                  style = "color: #337ab7;"),
          fileInput("ScoringPlotFile",
                    "Upload Gene Data (Excel/CSV/TXT/GMT)",
                    accept = c(".csv", ".txt", ".xlsx",".xls",".gmt",".tsv",".CSV", ".TXT", ".XLSX",".XLS",".GMT",".TSV")),
        ),
        
        # ---- Cluster selection ----
        div(
          p("Select clusters and separation options if needed - default set to Seurat clusters and no separation",
            style = "font-weight: bold"),
          selectInput(
            inputId = "ScoringClusterSelect",
            label = "Clusters to Visualize (Y axis)",
            selected = "seurat_clusters",
            choices = NULL,
            multiple = FALSE,
            width = '100%'
          ),
          fluidRow(selectInput(inputId="ScoringSampleSepSelect",
                               label="Additional separation",
                               selected=NULL, choices = NULL, multiple = F, width = '100%')
          ),
          actionButton("ScoringClusterSelection", "Load Plot", class = "action-button-custom")
        ),
        
        # ---- Plot size inputs ----
        fluidRow(
          column(6, textInput("scoring_width", "Plot Width (in):", value = "8")),
          column(6, textInput("scoring_height", "Plot Height (in):", value = "6"))
        ),
        fluidRow(
          column(6,
                 textInput("ScoringXtextSize", "X-axis Text Size", value = "14")
          ),
          column(6,
                 textInput("ScoringYtextSize", "Y-axis Text Size", value = "14")
          )
        ),
        fluidRow(
          column(12,
                 textInput("ScoringLtextSize", "Legend Text Size", value = "14")
          )
        ),
        
        # ---- Download ----
        downloadButton("download_Scoring", "Download Plot as PDF", class = "action-button-custom")
      ),
      
      mainPanel(
        plotOutput("Scoring", height = "750px")
      )
    )
  )
)
## ---------------------------------------------------------------------------- ##
## 8. Differential Expression testing ----
DEtesting <- shinyUI(
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        fluidRow(
          selectInput(
            inputId = "DEtestingCluster",
            label = tags$h3("Select Cluster for Differential Expression Testing",
                            style = "color: #337ab7; font-weight: bold;"),
            choices = NULL,width = '100%'
          ),
        ),
        fluidRow(
          selectizeInput(
            inputId = "DECluster1",
            label = "Comparison Category 1",
            choices = NULL,width = '100%',multiple = T
          )
        ),
        fluidRow(
          selectizeInput(
            inputId = "DECluster2",
            label = "Comparison Category 2",
            choices = NULL,width = '100%',multiple = T
          )
        ),
        actionButton(
          "DEtestingCategory",
          "Load DE Table",
          width = '95%', class = "action-button-custom"
        ),
        downloadButton("download_DEtesting", "Download table as CSV", class = "action-button-custom")),
      mainPanel(
        DTOutput("DEtestingTable"),
        plotlyOutput("VolcanoPlot", height = "700px", width = "1000px")
      )
      
    )
  )
)
## ---------------------------------------------------------------------------- ##
## 9. Add metadata and export RDS file after new annotations ----
Metadata_inclusion = shinyUI(
  fluidPage(
    titlePanel("Downloaded Updated Metadata and RDS here"),
    
    fluidRow(
      column(6, downloadButton("download_updatedMeta", "Download Metadata", class = "action-button-custom")),
      column(6, downloadButton("download_updatedRDS", "Download RDS File", class = "action-button-custom"))
    )
  )
)
# ))
## ---------------------------------------------------------------------------- ##
## full-page navigation container, where each nav_panel() is treated as a full page of content
## and the navigation controls appear in a top-level navigation bar.
tab_bars = page_navbar(
  title = "scVizApp",
  id = "tabs",
  bg = "#800000",
  # underline = TRUE,
  footer = tags$footer(HTML("
                    <!-- Footer -->
                           <footer class='page-footer font-large indigo'>
                           <!-- Copyright -->
                           <div class='footer-copyright text-center py-3'>© Copyright:
                           <a href='https://cri.uchicago.edu/bioinformatics/'> University of Chicago, Center for Research Informatics, Bioinformatics Core</a>
                           </div>
                           <!-- Copyright -->

                           </footer>
                           <!-- Footer -->")),
  theme = bs_theme(bootswatch = "litera"),
  # collapsible = F,
  nav_panel(title = "Introduction",
            navset_tab(
              nav_panel("Load/Input Data", Introduction),
              nav_panel("Overview", Introductionex)
            )),
  nav_panel("Cell Summary Profile",
            navset_tab(
              nav_panel("Samples Description", sample_description),
              nav_panel("Cell Summary", Cell_Summary),
              nav_panel("MultiDimensional Plots", umap_plots)
            )),
  nav_panel("Violin Plots", VlnPlot),
  nav_panel("Feature Plots", FeaturePlot),
  nav_panel("Dot Plots", DotPlot),
  nav_panel("Heatmaps", Heatmaps),
  nav_panel("Scoring", Scoring),
  nav_panel("DE Testing", DEtesting),
  nav_panel("Export/Download files", Metadata_inclusion),
  nav_spacer()
  # nav_menu()
)
## ---------------------------------------------------------------------------- ##
# app_ui <- shinyUI(fluidPage(tab_bars))
## --------------------------------------------------------------------------- ##

## ---Add project check------------------------------------------------------------------------- ##

ui <- shinyUI(fluidPage(
  
  conditionalPanel(
    condition = "output.page === 'start'",
    div(
      style = "
      height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      text-align: center;
    ",
      div(
        style = "max-width: 600px; width: 100%;",
        h3("Welcome to Single Cell RNA-seq Visualization App!"),
        div(
          style = "display: flex; justify-content: center; margin-top: 15px;",
          textInput("projectName", 
                    label = "Please enter the string we provided to access your data", 
                    value = "", 
                    width = "400px")
        ),
        actionButton("submitProject", "Submit", style = "margin-top: 15px;")
      )
    )
  )
  ,
  
  # Main app after project validation
  conditionalPanel(
    condition = "output.page === 'main'",
    tab_bars  # your full navbar layout defined above
  )
)
)
#
# Colors
## UMAP, Violin - default, dittoSeq, Polychrome
## Feature - Viridis
