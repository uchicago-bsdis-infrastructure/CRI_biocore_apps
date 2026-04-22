# This is the server script to disply interactive results.
library("dplyr")
library("DT")
library("ggplot2")

## ------------------------------------------------------------------------------------------- ##
## ------------------------------------------------------------------------------------------- ##
# prepare function used in the server
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
## --------- 
resLists2DfCluster <- function(listRes, topNo, adjpVal, padjon) {
  if (missing(padjon)) padjon <- as.logical(T) 
  print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  if (missing(topNo) & !missing(adjpVal)) {
    listResCluster <- lapply(seq_along(listRes), function(x) {
      resDf    <- dplyr::mutate(listRes[[x]], 'Cluster' = names(listRes)[x])
      if (padjon) {
        listResSel <- resDf %>% dplyr::filter(p.adjust<=adjpVal[x])
      } else {
        listResSel <- resDf %>% dplyr::filter(pvalue<=adjpVal[x])
      }
      return(listResSel)
    })
    print(sprintf("Filtering criteria: adjpVal=c('%s'), padjon=%s", paste(adjpVal, collapse = ", "), padjon))
  } else if (!missing(topNo) & missing(adjpVal)) {
    listResCluster <- lapply(seq_along(listRes), function(x) {
      resDf    <- dplyr::mutate(listRes[[x]], 'Cluster' = names(listRes)[x])
      if (padjon) {
        listResTop <- resDf %>% dplyr::arrange(p.adjust) %>% dplyr::slice_head(n = topNo)
      } else {
        listResTop <- resDf %>% dplyr::arrange(pvalue) %>% dplyr::slice_head(n = topNo)
      }
      return(listResTop)
    })
    print(sprintf("Filtering criteria: topNo=%s, padjon=%s", topNo, padjon))
  } else if (missing(topNo) & missing(adjpVal)) {
    listResCluster <- lapply(seq_along(listRes), function(x) {
      resDf    <- dplyr::mutate(listRes[[x]], 'Cluster' = names(listRes)[x])
      return(resDf)
    })
    print(sprintf("Filtering criteria is NA"))
  } else if (!missing(topNo) & !missing(adjpVal)) {
    listResCluster <- lapply(seq_along(listRes), function(x) {
      resDf    <- dplyr::mutate(listRes[[x]], 'Cluster' = names(listRes)[x])
      if (padjon) {
        listResSel <- resDf %>% dplyr::filter(p.adjust<=adjpVal[x])
      } else {
        listResSel <- resDf %>% dplyr::filter(pvalue<=adjpVal[x])
      }
      listResTop <- listResSel %>% dplyr::arrange(pvalue) %>% dplyr::slice_head(n = topNo)
      return(listResTop)
    })
    print(sprintf("Filtering criteria: topNo=%s, adjpVal=c('%s'), padjon=%s", topNo, paste(adjpVal, collapse = ", "), padjon))
  }
  resListComb <- dplyr::bind_rows(listResCluster)
  print(table(resListComb$Cluster))
  print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  return(resListComb)
}
# ---------
# 0.2
# makeDotPlot <- function(res2plot, padjon) {
#   # heightval = length((res2plot$res)$Description) * 10
#   res2plot$GeneRatio2 <- as.numeric(as.character(res2plot$Count))/as.numeric(as.character(sapply(res2plot$GeneRatio, function(x) strsplit(as.character(x), split = '/')[[1]][2]))) 
#   xLevels <- levels(factor(res2plot$Cluster))
#   yLevels <- unique(factor(res2plot$ID))
#   
#   dotPlot <- ggplot(res2plot, aes(x=factor(Cluster, levels = as.character(xLevels)), y=factor(ID, levels = rev(yLevels) )))
#   if (padjon) {
#     dotPlot <- dotPlot + geom_point(aes(size = as.numeric(res2plot$GeneRatio2), colour = as.numeric(as.character(p.adjust))), show.legend = T ) + theme_bw()
#   }else {
#     dotPlot <- dotPlot + geom_point(aes(size = as.numeric(res2plot$GeneRatio2), colour = as.numeric(as.character(pvalue))), show.legend = T ) + theme_bw()
#   }
#   dotPlot <- dotPlot + labs(x = "", y = "")
#   dotPlot <- dotPlot + theme(axis.text.y = element_text(colour = "black", size = 10))
#   dotPlot <- dotPlot + theme(axis.text.x = element_text(colour = "black", size = 10, angle = 90, hjust = 1))
#   dotPlot <- dotPlot + labs(title = "Selected over represented GOs") 
#   dotPlot <- dotPlot + theme(plot.title = element_text(size = 10, hjust = 0.5))
#   if (padjon) {
#     dotPlot <- dotPlot + scale_colour_gradient(name = "adjusted \n p-value\n")
#     # dotPlot <- dotPlot + scale_colour_gradient(name = "adjusted \n p-value\n",
#     #                                      limits=c(0, round2(max(cpEnrichGoRes$p.adjust), pround.digits)), low="red", high="blue")
#   }else {
#     dotPlot <- dotPlot + scale_colour_gradient(name = "original \n p-value\n")
#     # dotPlot <- dotPlot + scale_colour_gradient(name = "original \n p-value\n",
#     #                                      limits=c(0, round2(max(cpEnrichGoRes$pvalue), pround.digits)), low="red", high="blue")
#   }
#   dotPlot <- dotPlot + scale_size(name = "Gene Ratio")
#   # dotPlot <- dotPlot + scale_size(name = "Gene Ratio", range = c(1,10), breaks = c(0.25, 0.50, 0.75, 1))
#   # dotPlot <- dotPlot + scale_size(name = "count", range = c(min(res.pcut$Count), max(res.pcut$Count)),
#   #                     breaks=c(min(res.pcut$Count), 5, 10, max(res.pcut$Count)))
#   dotPlot <- dotPlot + theme(plot.margin = unit(c(0.5,0.5,0.1,0.1), "cm") ) ##top, right, bottom, left margins
#   dotPlot <- dotPlot + theme(legend.text=element_text(size=14), legend.title = element_text(size=10) )
#   dotPlot <- dotPlot + theme(legend.direction = "horizontal", legend.position = "bottom", legend.box = "vertical", legend.spacing.y = unit(-0.2, "cm"))
#   dotPlot <- dotPlot + guides(colour = guide_colorbar(order = 1, label.hjust = 0.5, label.theme = element_text(angle=90, size = 10) ), 
#                             size   = guide_legend(order = 2, label.theme = element_text(size = 10, angle = 0) ))
#   dotPlot
# }
## --------- 
## updated with swtiching on yAxis column selection
makeDotPlot <- function(res2plot, padjon, yAxisCol = "ID") {
  res2plot$GeneRatio2 <- as.numeric(as.character(res2plot$Count)) /
    as.numeric(sapply(res2plot$GeneRatio, function(x) strsplit(as.character(x), '/')[[1]][2]))
  
  xLevels <- levels(factor(res2plot$Cluster))
  yLevels <- unique(factor(res2plot[[yAxisCol]]))
  
  dotPlot <- ggplot(res2plot, aes(
    x = factor(Cluster, levels = as.character(xLevels)),
    y = factor(.data[[yAxisCol]], levels = rev(yLevels))
  ))
  
  if (padjon) {
    dotPlot <- dotPlot + geom_point(
      aes(size = GeneRatio2, colour = as.numeric(as.character(p.adjust))),
      show.legend = TRUE
    ) + theme_bw()
  } else {
    dotPlot <- dotPlot + geom_point(
      aes(size = GeneRatio2, colour = as.numeric(as.character(pvalue))),
      show.legend = TRUE
    ) + theme_bw()
  }
  
  dotPlot <- dotPlot +
    labs(x = "", y = "") +
    theme(axis.text.y = element_text(colour = "black", size = 10),
          axis.text.x = element_text(colour = "black", size = 10, angle = 90, hjust = 1),
          plot.title = element_text(size = 10, hjust = 0.5)) +
    labs(title = "Selected over represented GOs")
  
  if (padjon) {
    dotPlot <- dotPlot + scale_colour_gradient(name = "adjusted \n p-value\n")
  } else {
    dotPlot <- dotPlot + scale_colour_gradient(name = "original \n p-value\n")
  }
  
  dotPlot <- dotPlot + scale_size(name = "Gene Ratio") +
    theme(plot.margin = unit(c(0.5, 0.5, 0.1, 0.1), "cm"),
          legend.text = element_text(size = 14),
          legend.title = element_text(size = 10),
          legend.direction = "horizontal",
          legend.position = "bottom",
          legend.box = "vertical",
          legend.spacing.y = unit(-0.2, "cm")) +
    guides(colour = guide_colorbar(order = 1, label.hjust = 0.5,
                                   label.theme = element_text(angle = 90, size = 10)),
           size = guide_legend(order = 2, label.theme = element_text(size = 10, angle = 0)))
  
  dotPlot
}
## ------------------------------------------------------------------------------------------- ##
## ------------------------------------------------------------------------------------------- ##
## server start
server <- function(input, output, session) {
  ## ------------------------------------------------------------------------------------------- ##
  ## 0. download demo data with 'demoDataDownload' button
  output$demoDataDownload <- downloadHandler(
    filename = function() {paste("demo_data_", Sys.Date(), ".zip", sep="")},
    content = function(fname) {
      workDir <- getwd()
      setwd(tempdir())
      data1 <- read.delim(file = paste(workDir, 'input_data/input1/clusterProfiler_gcsample_res1.txt', sep = '/'), header = T, sep = '\t')
      data2 <- read.delim(file = paste(workDir, 'input_data/input1/clusterProfiler_gcsample_res3.txt', sep = '/'), header = T, sep = '\t')
      data3 <- read.delim(file = paste(workDir, 'input_data/input1/clusterProfiler_gcsample_res4.txt', sep = '/'), header = T, sep = '\t')
      data4 <- read.delim(file = paste(workDir, 'input_data/input1/clusterProfiler_gcsample_res7.txt', sep = '/'), header = T, sep = '\t')
      fs <- c("demo_data1.txt", "demo_data2.txt", "demo_data3.txt", "demo_data4.txt")
      write.table(data1, file = "demo_data1.txt", sep ="\t", quote = F, row.names = F, col.names = T)
      write.table(data2, file = "demo_data2.txt", sep ="\t", quote = F, row.names = F, col.names = T)
      write.table(data3, file = "demo_data3.txt", sep ="\t", quote = F, row.names = F, col.names = T)
      write.table(data4, file = "demo_data4.txt", sep ="\t", quote = F, row.names = F, col.names = T)
      zip(zipfile=fname, files=fs)
      # print(getwd())
      # print(workDir)
      setwd(as.character(workDir))
    },
    contentType = "application/zip"
  )
  ## ------------------------------------------------------------------------------------------- ##
  ## 1.0: define and update reactive input data expression 
  inputData <- reactiveValues(Fnames = list(data_1 = paste(getwd(), 'input_data/input1/clusterProfiler_gcsample_res1.txt', sep = '/'), 
                                            data_2 = paste(getwd(), 'input_data/input1/clusterProfiler_gcsample_res3.txt', sep = '/'), 
                                            data_3 = paste(getwd(), 'input_data/input1/clusterProfiler_gcsample_res4.txt', sep = '/'), 
                                            data_4 = paste(getwd(), 'input_data/input1/clusterProfiler_gcsample_res7.txt', sep = '/')))

  
  ## 1.1: update reactive input data file names based on dropdown selection
  ## Reactive value to store files list
  filesList <- reactiveVal(NULL)
  selectedFolder <- reactiveVal(NULL)
  
  observeEvent(input$inputType, {
    output$folderInputUI <- renderUI({
      if (input$inputType == "project") {
        textInput("inputFolder", "Enter provided CRI-BIO project result token:", value = "")
      } else if (input$inputType == "gseaApp") {
        textInput("inputFolder2", label = HTML('Enter GSEA app <a href="https://biocoreapps.bsd.uchicago.edu/gsea_shiny/" target="_blank"> https://biocoreapps.bsd.<wbr>uchicago.edu/<wbr>gsea_shiny/</a> result token:' ), value = "")
      } else if (input$inputType == "upload") {
        fileInput(
          "uploadFolder",
          "Upload your own analysis reuslts folder (zipped):",
          multiple = FALSE,
          accept = c(".zip")
        )
      }
    })
  })
  
  ## Load Files
  observeEvent(input$loadFiles, {
    type <- input$inputType
    if (type == "project") {
      permName <- trimws(input$inputFolder)
      folderPath <- normalizePath(file.path("/srv/data/feavis_data/project_data", permName), mustWork = FALSE)
      if (dir.exists(folderPath)) {
        selectedFolder(folderPath)
        filesList(list.files(folderPath, full.names = FALSE))
        showNotification(sprintf("✅ Loaded pCRI-BIO roject folder: %s", folderPath), type = "message")
      } else {
        filesList(NULL)
        showNotification("Permanent folder does not exist!", type = "error")
      }
      
    } else if (type == "gseaApp") {
      tempName <- trimws(input$inputFolder2)
      folderPath <- normalizePath(file.path("/srv/data/feavis_data/input_data_2delete", tempName), mustWork = FALSE)
      if (dir.exists(folderPath)) {
        selectedFolder(folderPath)
        filesList(list.files(folderPath, full.names = FALSE))
        showNotification(sprintf("⚠️ Loaded temporary GSEA app results folder: %s", folderPath), type = "message")
        
        # Register session cleanup
        sessionFolder <- folderPath
        session$onSessionEnded(function() {
          if (dir.exists(sessionFolder)) {
            tryCatch({
              unlink(sessionFolder, recursive = TRUE, force = TRUE)
              message(sprintf("[Session %s] Deleted temporary folder: %s", session$token, sessionFolder))
            }, error = function(e) {
              warning(sprintf("[Session %s] Failed to delete temp folder %s: %s", 
                              session$token, sessionFolder, e$message))
            })
          }
        })
      } else {
        filesList(NULL)
        showNotification("Temporary folder does not exist!", type = "error")
      }
    }
  })
  
  ## Automatically handle upload case
  observeEvent(input$uploadFolder, {
    req(input$uploadFolder)
    uploadPath <- input$uploadFolder$datapath
    tempToken <- paste0("upload_", as.integer(Sys.time()))
    targetFolder <- file.path("/srv/data/feavis_data/input_data_2delete", tempToken)
    
    dir.create(targetFolder, recursive = TRUE, showWarnings = FALSE)
    
    ## Unzip uploaded file into temporary folder
    unzip(uploadPath, exdir = targetFolder)
    allFiles <- list.files(targetFolder, full.names = FALSE, recursive = TRUE)
    
    if (length(allFiles) == 0) {
      showNotification("⚠️ No files found in uploaded ZIP.", type = "warning")
    }
    
    selectedFolder(targetFolder)
    filesList(allFiles)
    
    showNotification(sprintf("✅ Uploaded and loaded folder: %s (%d files)", tempToken, length(allFiles)), type = "message")
    
    # Auto cleanup after session end
    sessionFolder <- targetFolder
    session$onSessionEnded(function() {
      if (dir.exists(sessionFolder)) {
        unlink(sessionFolder, recursive = TRUE, force = TRUE)
        message(sprintf("[Session %s] Deleted uploaded temp folder: %s", session$token, sessionFolder))
      }
    })
  })
  
  ##Render file selection UI 
  output$fileSelectorUI <- renderUI({
    req(filesList())
    selectizeInput(
      "selectedFiles",
      label = "Choose one or more files:",
      choices = filesList(),
      multiple = TRUE
    )
  })
  
  ## Clear file selection after submit click
  observeEvent(input$dataSubmit, {
    filesList(NULL)
    updateSelectizeInput(session, "selectedFiles", choices = NULL)
    showNotification("✅ Data submitted and selection cleared.", type = "message")
  })
  
  ## ------------------------------------------------------------------------------------------- ##
  ## Reactive values for input data: update file names when dataSubmit is clicked 
  ## with returned inputDataFnamesUpdate()$Fnames (vector of full paths.) and inputDataFnamesUpdate()$OrgFnames (vector of original filenames.)
  inputDataFnamesUpdate <- eventReactive(input$dataSubmit, {
    req(selectedFolder())
    # print('99999999')
    # print(paste("Other function can use folder:", selectedFolder()))
    # print('99999999')
    if (is.null(input$selectedFiles) || length(input$selectedFiles) == 0) {
      # If nothing is selected, keep existing
      inputData$Fnames <- inputData$Fnames  
      inputData$OrgFnames <- lapply(inputData$Fnames, basename)
    } else {
      # Prepend directory path since dropdown returns relative file names
      inputData$Fnames <- file.path(selectedFolder(), input$selectedFiles)
      # Original names are just the file basenames
      inputData$OrgFnames <- basename(input$selectedFiles)
      # Optional: assign default keys
      names(inputData$Fnames) <- paste0("data_", seq_along(inputData$Fnames))
    }
    # print('99999999')
    # print(inputData$OrgFnames)
    # print('99999999')
    # Return updated inputData as a list
    list(
      Fnames = inputData$Fnames,
      OrgFnames = inputData$OrgFnames
    )
  })
  

  ## 1.2: load inputData$Fnames into R as a list object with corresponding input$data*Name
  getInputDataList <- eventReactive(input$dataSubmit, {
    res <- inputDataFnamesUpdate()
    fnames <- res$Fnames
    # print('12121212121')
    # print(str(fnames))
    # print("========================================")
    # print(str(res))
    # print('-=-=-=-=-=-=-')
    Res <- lapply(fnames, function(x) {
      ext <- tolower(tools::file_ext(x))
      print(sprintf("ext is %s", ext))
      if (ext == "txt") {
        inputRes <- read.delim(file = as.character(x), header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)
      } else if (ext == "csv") {
        inputRes <- read.csv(file = as.character(x), header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)
      } else if (ext %in% c("xls", "xlsx")) {
        inputRes <- readxl::read_excel(path = as.character(x))
        inputRes <- as.data.frame(inputRes, check.names = FALSE, stringsAsFactors = FALSE)
      } else {
        stop(sprintf("Unsupported file type: %s", ext))
      }
      
      # Round numeric columns to 3 decimals
      inputRes <- inputRes %>% dplyr::mutate(across(where(is.numeric), ~ round(., 3)))
      return(inputRes)
    })
    names(Res) <- names(fnames)
    # print(str(Res))
    # print('121212121121212')
    Res
  })
  ## ------------------------------------------------------------------------------------------- ##
  ## reactive values for render UI on pvalues criteria
  # 2.1 create reactiveValues() to update dataInput for dotplot and table based on the click input$dataSubmit or input$adjpUpdate
  #     if input$dataSubmit, all data are presented in the table, and plot the top 10 GOs in the dot-plot
  #     if input$adjpUpdate, present data in the table based on the query from querty term and query p/FDR
  # get adjusted p-value from rendered UI based on the reactive values - inputData
  getAdjP <- reactive({
    res <- inputDataFnamesUpdate()   # capture returned list
    inputDataNo <- length(unlist(res$Fnames))   # use it

    if (inputDataNo > 0) {
      adjpVal <- sapply(seq_len(inputDataNo), function(i) {
        input[[paste0("data", i, "Adjp")]]
      })
    } else {
      adjpVal <- NULL
    }
    # print("adjp-=--=-=-=adjp-=--=-=-=")
    # print(adjpVal)
    # print("adjp-=--=-=-=adjp-=--=-=-=")
    adjpVal
  })
  ## ------------------------------------------------------------------------------------------- ##
  ## Create a reactiveVal to track button clicks
  resUpdateTrigger <- reactiveVal(0)
  dtUpdateTrigger <- reactiveVal(0)
  ## Observe each button separately
  observeEvent(input$dataSubmit, { 
    print("dataSubmit clicked")
    handleButtonClick() 
    resUpdateTrigger(resUpdateTrigger() + 1)
    dtUpdateTrigger(dtUpdateTrigger() + 1)
  }, ignoreInit = TRUE)
  
  observeEvent(input$adjpUpdate, { 
    print("adjpUpdate clicked")
    handleButtonClick() 
    resUpdateTrigger(resUpdateTrigger() + 1)
    dtUpdateTrigger(dtUpdateTrigger() + 1)
  }, ignoreInit = TRUE)
  
  observeEvent(input$queryUpdate, { 
    print("queryUpdate clicked")
    handleButtonClick() 
    resUpdateTrigger(resUpdateTrigger() + 1)
    dtUpdateTrigger(dtUpdateTrigger() + 1)
  }, ignoreInit = TRUE)
  ## ---------------------------------------------------------------------------------------------- ##
  ## ------------------------------------------------------------------------------------------- ##
  ## ReactiveValues for final results $res, results used in plot $res2plot, ploting height $plotHeight, serch options in 'Description'
  dataCombList <- reactiveValues(
    res = NULL,
    res2plot = NULL,
    plotHeight = NULL,
    textSearchOptions = NULL,
    textSelected = NULL
  )
  ## Define the handler function so that the reactive values can be updated once those button handler are clicked
  handleButtonClick <- function() {
    ## Load input data
    inputDataList <- getInputDataList()
    print("===== Input Data List =====")
    print(str(inputDataList))
    print("===========================")
    ## Determine if adjusted p-values should be applied
    adjpVals <- NULL
    if (!is.null(input$adjpUpdate) && input$adjpUpdate > 0) {
      adjpVals <- getAdjP()
    }
    padjon <- !is.null(input$adjPon) && input$adjPon == "fdrp"
    print("===== Input input$adjPon  List =====")
    print(sprintf("input$adjPon is %s", input$adjPon))
    print(sprintf("padjon is %s", padjon))
    print("===========================")
    ## Create full result table
    combListDfFull <- if (!is.null(adjpVals)) {
      resLists2DfCluster(listRes = inputDataList, adjpVal = adjpVals, padjon = padjon)
    } else {
      resLists2DfCluster(listRes = inputDataList)
    }
    print("===== After resLists2DfCluster =====")
    print(table(combListDfFull$Cluster))
    print("===================================")
    ## Determine search terms
    termInt <- if (nzchar(input$goInts2)) {
      trim(unlist(strsplit(input$goInts2, split = ',')))
    } else if (!is.null(input$goInts)) {
      as.character(input$goInts)
    } else {
      "all"
    }
    ## Filter by keywords unless 'all'
    if (!("all" %in% termInt)) {
      combListDfFull <- combListDfFull %>% dplyr::filter(grepl(paste(termInt, collapse = '|'), Description))
    }
    ## Update reactiveValues
    dataCombList$res <- dplyr::distinct(combListDfFull, Cluster, ID, .keep_all = TRUE)
    # print("===== Input input$functionChoice  List =====")
    # print(sprintf("input$functionChoice is %s", input$functionChoice))
    # print(sprintf("input$adjPon is %s", input$adjPon))
    # print("===========================")
    
    if (input$functionChoice == "top10") {
      if (padjon) {
        dataCombList$res2plot <- dataCombList$res %>% group_by(Cluster) %>% arrange(.data[["p.adjust"]], .by_group = TRUE) %>% slice_head(n = 10) %>% ungroup()
      } else {
        dataCombList$res2plot <- dataCombList$res %>% group_by(Cluster) %>% arrange(.data[["pvalue"]], .by_group = TRUE) %>% slice_head(n = 10) %>% ungroup()
      }
    } else {
      dataCombList$res2plot <- dataCombList$res
    }
    print("===== After resLists2DfCluster for top10 chosen =====")
    print("reactive values in $res")
    print(table(dataCombList$res$Cluster))
    print("reactive values in $res2plot")
    print(table(dataCombList$res2plot$Cluster))
    print("===================================")
    ## Dynamic plot height
    nRows <- nrow(dataCombList$res2plot)
    dataCombList$plotHeight <- if (nRows < 40) nRows * 20 else
      if (nRows < 70) nRows * 15 else
        if (nRows < 100) nRows * 12 else
          if (nRows < 500) nRows * 10 else 9000
    ## ------------------------------ ##
    ## Update search text options
    connectionString <- c("of", "in", "from")
    SearchTextsAll <- unlist(strsplit(paste(dataCombList$res$Description, collapse = " "), " "))
    SearchTexts <- SearchTextsAll[!SearchTextsAll %in% connectionString]
    SearchTextsList <- as.list(unique(SearchTexts))
    names(SearchTextsList) <- unique(SearchTexts)
    
    dataCombList$textSearchOptions <- c('search all' = 'all', SearchTextsList)
    dataCombList$textSelected <- termInt
  }
  ## ---------------------------------------------------------------------------------------------- ##
  ## ------------------------------------------------------------------------------------------- ##
  ## update reactive values (dataCombList$res2plot) for dotplot top10 only with input$functionChoice
  observeEvent(input$functionChoice, {
    req(dataCombList$res) ## above obtained results
    padjon <- !is.null(input$adjPon) && input$adjPon == "fdrp"
    
    if (input$functionChoice == "top10") {
      if (padjon) {
        dataCombList$res2plot <- dataCombList$res %>%
          group_by(Cluster) %>%
          arrange(.data[["p.adjust"]], .by_group = TRUE) %>%
          slice_head(n = 10) %>%
          ungroup()
      } else {
        dataCombList$res2plot <- dataCombList$res %>%
          group_by(Cluster) %>%
          arrange(.data[["pvalue"]], .by_group = TRUE) %>%
          slice_head(n = 10) %>%
          ungroup()
      }
    } else {
      dataCombList$res2plot <- dataCombList$res
    }
    
    nRows <- nrow(dataCombList$res2plot)
    dataCombList$plotHeight <- if (nRows < 40) nRows * 20 else
      if (nRows < 70) nRows * 15 else
        if (nRows < 100) nRows * 12 else
          if (nRows < 500) nRows * 10 else 9000
  })
  ## ---------------------------------------------------------------------------------------------- ##
  ## Render UIs for search boxes
  ## box "Search in the description for keywords"  
  ## box "Filter by nominal p-value or FDR adjusted p-value"
  output$textSearch <- renderUI({ 
    tagList(fluidRow(
      box(tableOutput("inputDataSummary")),
      box(column(width = 12, selectizeInput(inputId = "goInts", 
                                            label = "Select one or more keywords to search in the Description",
                                            selected = dataCombList$textSelected, 
                                            choices = dataCombList$textSearchOptions, 
                                            multiple = TRUE)),
          column(width = 12, p("OR", 
                               style="color:black; margin-top: 0cm; margin-left: 0.2cm; align: center; font-family:Andika, Arial, sans-serif; font-size:1.5em; text-transform:uppercase ;")), 
          column(width = 12, textInput(inputId = "goInts2",
                                       label = "Enter one or more keywords (separated by comma) to search in the Description",
                                       value = ""))), 
      # column(width = 6, tableOutput("inputDataSummary")), 
      # query button
          actionButton(
            inputId = "queryUpdate",
            label = "Query Search",
            style = "margin-top:0.5em; float:right; margin-right:1em;
                     background-color: #c9302c !important; 
                     # border-color: #c9302c !important;
                     font-family:Andika, Arial, sans-serif; 
                     font-size:1em;
                     text-transform:uppercase; 
                     color: #fff !important;
                     border-radius:10px;
                     box-shadow: rgba(0,0,0,.55) 0 1px 1px;"
            
          )
    ))
  })
  ## ---------------------------------------------------------------------------------------------- ##
  ## render UI for query box for adjusted pvals
  output$padjControls <- renderUI({
    res <- inputDataFnamesUpdate()   # capture returned list
    inputDataNo     <- length(unlist(res$Fnames))

    if (inputDataNo == 0) return(NULL)  # nothing to show
    
    # --- common button style
    buttonStyle <- tags$style("button#adjpUpdate {
                               margin-top:0.5em; 
                               float:right; 
                               margin-right:1em; 
                               # background-color:#009900; 
                               background-color: #c9302c !important; 
                               padding: 5px 15px; 
                               font-family:Andika, Arial, sans-serif; 
                               font-size:1em;  
                               letter-spacing:0.05em; 
                               text-transform:uppercase ;color:#fff; 
                               text-shadow: 0px 1px 10px #000;
                               border-radius: 10px;
                               box-shadow: rgba(0, 0, 0, .55) 0 1px 1px;
                             }")
    
    # --- generate input fields dynamically
    controls <- lapply(seq_len(inputDataNo), function(i) {
      
      # compute maximum p-value / adjp from input dataset i
      maxVal <- tryCatch({
        datList <- getInputDataList()   # <- use the reactive that actually loads the data
        dat <- datList[[i]]
        # max(dat$p.adjust, na.rm = TRUE)  # or max(dat$adjp, na.rm = TRUE)
        maxVal <- max(dat$p.adjust, na.rm = TRUE) 
        if(maxVal > 0.9) { maxVal = round(maxVal, digits = 0)} else {maxVal = round(maxVal, digits = 2)}
      }, error = function(e) 1)  # fallback if something is missing
      
      column(
        width = max(12 %/% min(inputDataNo, 4), 2),  # responsive width (max 4 per row)
        style = 'padding-right:1em; padding-top:1em',
        textInput(
          paste0("data", i, "Adjp"),
          paste("p-value or FDR adjusted p-value for input data", i),
          value = as.character(maxVal)   # <-- dynamic max value
        )
      )
    })
    
    # --- assemble full UI
    tagList(
      column(
        width = 3, style='padding-right:1em; padding-top:1em',
        radioButtons("adjPon", "Results query is based on",
                     choices = c("Nominal p-value" = "normp",
                                 "FDR adjusted p-value" = "fdrp"),
                     selected = "fdrp")
      ),
      controls,
      actionButton("adjpUpdate", "Query Search"),
      buttonStyle
    )
  })
  ## ---------------------------------------------------------------------------------------------- ##
  ## render ui for resSummary table
  ## resSummary (renderUI) as dataTable to display all input data 
  ## for box "Over represented gene sets table" (right box)
  ## Render dynamic DT outputs for combined results
  output$resSummary <- renderUI({
    # Depend on the button click trigger
    req(resUpdateTrigger() || dtUpdateTrigger())
    
    # Only render if dataCombList$res exists and is non-empty
    req(dataCombList$res)
    resData <- isolate(dataCombList$res)
    inputDataNo <- length(unique(resData$Cluster))  # number of clusters / tables to show
    
    if (inputDataNo == 0) return(NULL)
    
    # Generate DT outputs dynamically
    outputs <- lapply(seq_len(inputDataNo), function(i) {
      clusterName <- unique(resData$Cluster)[i]
      tagList(
        column(
          width = 12,
          DT::dataTableOutput(paste0("data", i, "output"))
        ),
        br(), br()
      )
    })
    
    # Combine all UI elements
    # do.call(tagList, outputs)
    # Combine all UI elements and place download button at the bottom
    tagList(
      outputs,
      br(), br(),
      downloadButton(
        outputId = "downloadResData",
        label = "Download Enrichment Results",
        style = "margin-top:0.5em; float:right; margin-right:1em; 
               background-color:#009900; color:#fff; 
               font-family:Andika, Arial, sans-serif; font-size:1em; 
               text-transform:uppercase; border-radius:10px; 
               box-shadow: rgba(0,0,0,.55) 0 1px 1px;"
      )
    )
    
  })
  ## ------------------------------------------------------------------------------------------------------ ##
  ## render table of inputDataSummary in queary box
  output$inputDataSummary <- renderTable({
    res <- inputDataFnamesUpdate()
    inputDataNo     <- length(unlist(res$Fnames))
    # print('33333')
    # print(inputDataNo)
    # print('33333')
    inputDataFnames <- unlist(inputData$OrgFnames)
    inputDataSummary <- matrix(data = inputDataFnames)
    rownames(inputDataSummary) <- paste('data', 1:inputDataNo, sep = ' ')
    # print(inputDataSummary)
    outputData1Res  <- inputDataSummary
  },digits=0, rownames = T, colnames = F, align="ll")
  
  ## ------------------------------------------------------------------------------------------------------ ##
  ## render results for dotplot column 2 sections
  # 2.1 render table of dotplot summary
  output$resSummary1   <- renderTable({
    if (!is.null(dataCombList$res2plot)) {
      # print('---')
      # print(head(dataCombList$res))
      # print(str(table(dataCombList$res2plot$Cluster)))
      # print('---')
      resClusterSummary <- table(dataCombList$res$Cluster)
      rownames(resClusterSummary) <- sapply(rownames(resClusterSummary), function(x) paste(unlist(unlist(strsplit(x, split = '_'))), collapse = ' ') )
      # print('---')
      # print(rownames(resClusterSummary))
      # print('---')
      resClusterSummary
    }
  }, digits=0, rownames = T, colnames = F, align = 'ccc')

  
  # 2.1 render dotplot
  output$dotPlot1   <- renderPlot({
    req(dataCombList$res2plot)
    if (input$adjPon == "fdrp") padjon = as.logical(T) else padjon = as.logical(F)
    dotPlot1Res <- makeDotPlot(res2plot = dataCombList$res2plot, padjon = padjon)
    dotPlot1Res
  })
  
  output$ui_dotplot <- renderUI({
    req(dataCombList$plotHeight)
    plotOutput(outputId = "dotPlot1", height = dataCombList$plotHeight )
  })
  ## ------------------------------------------------------------------------------------------------------ ##
  ## ---------------------------------------------------------- ##
  ## reactive values rendering and updates
  observe({
    req(resUpdateTrigger() || dtUpdateTrigger())
    
    # Ensure data exists
    resData <- isolate(dataCombList$res)
    req(resData)
    
    clusterLevels <- unique(resData$Cluster)
    
    # Determine filtering terms
    termInt <- isolate({
      if (!is.null(input$goInts2) && nzchar(input$goInts2)) {
        trim(unlist(strsplit(input$goInts2, ",")))
      } else if (!is.null(input$goInts)) {
        as.character(input$goInts)
      } else {
        "all"
      }
    })
    
    # Loop over each cluster and create DT outputs
    lapply(seq_along(clusterLevels), function(i) {
      clusterName <- clusterLevels[i]
      
      output[[paste0("data", i, "output")]] <- DT::renderDataTable({
        clusterData <- resData %>% filter(Cluster == clusterName)
        
        # Filter by keywords
        if (!("all" %in% termInt)) {
          clusterData <- clusterData %>% filter(grepl(paste(termInt, collapse = "|"), Description))
        }
        
        # Filter by adjusted p-value if applicable
        if (!is.null(input$adjpUpdate) && input$adjpUpdate > 0) {
          adjpVals <- isolate(getAdjP())
          padjon <- !is.null(input$adjPon) && input$adjPon == "fdrp"
          ## ---------- ##
          if (length(adjpVals) >= i) {
            if (padjon) {
              clusterData <- clusterData %>% filter(p.adjust <= adjpVals[i])
            } else {
              clusterData <- clusterData %>% filter(pvalue <= adjpVals[i])
            }
          }
        }
        
        DT::datatable(
          clusterData,
          rownames = FALSE,
          extensions = c('FixedColumns','ColReorder','Buttons','KeyTable','Scroller'),
          options = list(
            scrollX = TRUE,
            deferRender = TRUE,
            scrollY = 200,
            scroller = TRUE,
            keys = TRUE,
            colReorder = TRUE,
            pageLength = 5,
            lengthMenu = c(5,10,15,20),
            dom = 'Bfrtip',
            buttons = c('copy','csv','excel','pdf','print', I('colvis')),
            fixedColumns = list(leftColumns = 1)
          )
        )
      })
    })
  })
  ## ------------------------------------------------------------------------------------------------------ ##
  ## ---------------------------------------------------------- ##
  ## downloading sections
  ## download excel file
  output$downloadResData <- downloadHandler(
    filename = function() paste0("resData_", Sys.Date(), ".xlsx"),
    content = function(file) {
      resData <- isolate(dataCombList$res)
      req(resData)
      openxlsx::write.xlsx(resData, file, asTable = TRUE)
    }
  )
  
  ## ---------
  ## plots downloading options and downloding output
  # Open modal for download settings
  observeEvent(input$openDotDownload, {
    showModal(modalDialog(
      title = "Download Dotplot",
      fluidRow(
        column(3,
               selectInput("dotFileType", "File type:",
                           choices = c("PNG" = "png", "PDF" = "pdf"),
                           selected = "pdf")
        ),
        column(3,
               numericInput("dotWidth", "Width (inches):", value = 12, min = 4, max = 30, step = 1)
        ),
        column(3,
               numericInput("dotHeight", "Height (inches):", value = 8, min = 4, max = 30, step = 1)
        ),
        column(3,
               selectInput("yAxisChoice", "Y-axis labels:",
                           choices = c("Terms" = "ID", "Descriptions" = "Description"),
                           selected = "ID")
        )
      ),
      checkboxInput("lockAspect", "Lock aspect ratio", value = TRUE),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("downloadDotPlot", "Confirm & Download")
      ),
      easyClose = TRUE
    ))
  })
  
  # Aspect ratio locking
  observeEvent(input$dotWidth, {
    if (isTRUE(input$lockAspect)) {
      ratio <- isolate(input$dotHeight / input$dotWidth)
      newHeight <- round(input$dotWidth * ratio, 1)
      updateNumericInput(session, "dotHeight", value = newHeight)
    }
  })
  observeEvent(input$dotHeight, {
    if (isTRUE(input$lockAspect)) {
      ratio <- isolate(input$dotWidth / input$dotHeight)
      newWidth <- round(input$dotHeight * ratio, 1)
      updateNumericInput(session, "dotWidth", value = newWidth)
    }
  })
  
  # Download handler
  output$downloadDotPlot <- downloadHandler(
    filename = function() {
      paste0("dotplot_", Sys.Date(), ".", input$dotFileType)
    },
    content = function(file) {
      req(dataCombList$res2plot)
      yAxisCol <- ifelse(is.null(input$yAxisChoice), "ID", input$yAxisChoice)
      
      if (input$dotFileType == "pdf") {
        pdf(file, width = input$dotWidth, height = input$dotHeight)
        print(makeDotPlot(res2plot = dataCombList$res2plot,
                          padjon = (input$adjPon == "fdrp"),
                          yAxisCol = yAxisCol))
        dev.off()
      } else {
        png(file, width = input$dotWidth, height = input$dotHeight, units = "in", res = 300)
        print(makeDotPlot(res2plot = dataCombList$res2plot,
                          padjon = (input$adjPon == "fdrp"),
                          yAxisCol = yAxisCol))
        dev.off()
      }
    }
  )
  # Close modal immediately after clicking Confirm & Download
  observeEvent(input$downloadDotPlot, {
    removeModal()
  })
  ## ------------------------------------------------------------------------------------------------------ ##
  ## ------------------------------------------------------------------------------------------------------ ##
}
# complete server
## ------------------------------------------------------------------------------------------- ##
## ------------------------------------------------------------------------------------------- ##