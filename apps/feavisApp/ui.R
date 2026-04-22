## This application (FeaVis) is developed by Yan Li (yli22@bsd.uchicago.edu), 
## Center for Research Informatics, Univeristiy of Chicago initally at Feb 20, 2018 with substantial modifications at Sep, 25
## ------------------------------------------------------------------------------------------- ##
library(shinydashboard)
library(shiny)
library(shinyWidgets)
library(shinyjs)
library(shinyFiles)
library(dplyr)
## ------------------------------------------------------------------------------------------- ##
## This app includes 1) header; 2) side bar for introduction, data_download, and upload input data; and 3) main dashboard body for main analysis display
## 1. dashboard header, the font style is defined in the www/custom.css file
header <- dashboardHeader(title = "FeaVis", titleWidth = 300)
## ------------------------------------------------------------------------------------------- ##
## 2. dashboad sidebar: upload input data for visualization in the sidebar by providing the full path of the folder, 
## then selecting corresponding files to upload for visualizations
sidebar <- dashboardSidebar(
  br(),
  # 2.0 adjust sidebar fileInput() and textInput() margin space
  tags$style(".shiny-input-container {margin-bottom: 0; margin-top: -10px } .shiny-file-input-progress { margin-bottom: 0px ; margin-top: -5px }"),   
  # 2.1 Introduction link
  a(h4("Introduction", class = "btn btn-default action-button" , 
       style = "fontweight:600; background-color:#337ab7; font-family:Andika, Arial, sans-serif; font-size:0.8em;letter-spacing:0.05em; 
       text-transform:uppercase; color:#fff; 
       text-shadow: 0px 1px 10px #000; 
       border-radius: 10px;box-shadow: rgba(0, 0, 0, .55) 0 1px 1px;"), target = "_blank",
    href = 'https://bitbucket.org/yli22/feavis/src/master/README.md', ## update this document ASAP
    style = "padding-left: 3em"),
  br(),
  br(),
  br(),
  # ---
  downloadButton("demoDataDownload", 
                 label = "Demo Data Download",
                 class = NULL),
  tags$style("#demoDataDownload {margin-left: 3.2em; float:left; fontweight:600; background-color:#337ab7; font-family:Andika, Arial, sans-serif; font-size:0.8em;letter-spacing:0.05em;text-transform:uppercase; color:#fff; text-shadow: 0px 1px 10px #000; border-radius: 10px;box-shadow: rgba(0, 0, 0, .55) 0 1px 1px;}"),
  br(),
  br(),
  br(),
  ## ------------------------------------------------------------------------------------------- ##
  ## 2.2 data input include 1) input$inputFolder for the folder path and 2) select folders inside input$inputFolder after click input$loadFiles (action button)
  box(
    title = "Step 1: Select Input Type and Folder",
    status = 'primary',
    width = 12,
    solidHeader = TRUE,
    background = 'black',
    
    # Step 1: choose input type
    selectInput(
      inputId = "inputType",
      label = "Select type of results:",
      choices = c(
        "CRI-BIO project results" = "project",
        "GSEA App results" = "gseaApp",
        "Upload your own" = "upload"
      ),
      selected = "gseaApp"
    ),
    
    # Step 2: show folder/token input dynamically
    uiOutput("folderInputUI"),
    
    # Step 3: load files (for project or gseaApp only)
    actionButton(
      inputId = "loadFiles",
      label = "Load Files",
      icon = icon("folder-open"),
      style = "color: #fff; background-color: #337ab7;"
    )
  ),
  
  box(
    title = "Step 2: Choose Files for Analysis",
    status = 'primary',
    width = 12,
    solidHeader = TRUE,
    background = 'black',
    
    uiOutput("fileSelectorUI"),
    
    actionButton(
      inputId = "dataSubmit",
      label = "Submit Data",
      icon = icon("cloud-upload"),
      style = "color: #fff; background-color: #337ab7;"
    )
  )
)
## ------------------------------------------------------------------------------------------- ##
## 3. dashboard Body: define 2 query search box output$textSearch and output$padjControls
## and 3 results display boxes in green color, 1) output$resSummary1 in renderTable(), 
## 2) output$ui_dotplot in renderUI(), and 3) output$resSummary in renderUI()
body <- dashboardBody(
  # 3.0 defind the header font custom.css from www/custom.css
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "custom.css") ),  
  tags$style("#inputDataSummary table {border: 1px solid black; align: center; margin-left: 3em}","#inputDataSummary th {border: 1px solid black;}","#inputDataSummary td {border: 1px solid black;}"),
  
  # 3.1
  box(title = "Search in the description for keywords", solidHeader = T, status = "danger", collapsible = T, collapsed = F, width = 12,  
      fluidRow(column(width = 12, offset = 0, style='padding-right:1em; padding-top:1em',
                      # textInput(inputId = "goInts",
                      #           label = "Enter one or more key word to query",
                      #           value = "immune")
                      uiOutput('textSearch')
                      )
               )
      ),
  
  # ---
  box(title = "Filter by nominal p-value or FDR adjusted p-value", 
      solidHeader = T, status = "danger", collapsible = T, collapsed = F, width = 12,
      fluidRow( uiOutput("padjControls") ) 
      ),
  # ---
  column( width = 4, 
          box(title = "Gene sets over representation summary", 
              solidHeader = T, status = "success", collapsible = T, collapsed = F, width = NULL,
              tableOutput(outputId = "resSummary1"),
              tags$style("#resSummary1 table {border: 1px solid black; align: left; margin-left: 1em}", 
                         "#resSummary1 th {border: 1px solid black;}", 
                         "#resSummary1 td {border: 1px solid black;}")
              
          ),
          # ---
          box(title = "Gene sets over representation plot", 
              solidHeader = T, status = "success", collapsible = T, collapsed = F, width = NULL,
              
              # Dropdown input inside the box
              selectInput(
                inputId = "functionChoice",
                label = "Select Functions to Display:",
                choices = c("Top 10 Functions" = "top10", "All Enriched Functions" = "all"),
                selected = "top10"
              ),
              
              uiOutput('ui_dotplot'),
              # Trigger button to open modal (not the actual download button)
              actionButton(
                inputId = "openDotDownload",
                label = "Download Dotplot",
                style = "margin-top:0.5em; float:right; margin-right:1em; 
                        background-color:#009900; color:#fff; 
                        font-family:Andika, Arial, sans-serif; font-size:0.8em; 
                        text-transform:uppercase; border-radius:10px; 
                        box-shadow: rgba(0,0,0,.55) 0 1px 1px;"
              )
          )
          ),
  column( width = 8,
          box (title = "Over represented gene sets table", 
               solidHeader = T, status = "success", collapsible = T, collapsed = F, width = NULL, 
               fluidRow( uiOutput(outputId = 'resSummary') ) 
          )
          )
  ,
  
  width = 300,
  helpText("Developed by bioinformatics core, Center for Research Informatics (CRI), University of Chicago",
           style="padding-left:1em; padding-right:1em;position:absolute; bottom:1em;")
  
  
  
)
## ------
## main combined header, sidebar, and body defined above, with skin as 'green' colour
ui <- dashboardPage(header = header, sidebar = sidebar, body = body)

## ------------------------------------------------------------------------------------------- ##