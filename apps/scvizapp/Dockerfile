FROM rocker/shiny:latest

# Install system dependencies (add as needed)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('dplyr', 'Seurat', 'SeuratObject', 'stringr', 'tidyr',
  'renv', 'cowplot', 'ggplot2', 'grid', 'patchwork', 'readr',
  'readxl', 'reshape2', 'stringi', 'tibble',
  'shiny', 'tools', 'bslib', 'DT',
  'shinydashboard', 'shinyWidgets', 'shinyjs', 'scCustomize', 'Polychrome', 'viridis', 'viridisLite'))"

# For Bioconductor packages
RUN R -e "install.packages('BiocManager')"
# && R -e "BiocManager::install(c('DESeq2', 'edgeR', 'dittoSeq'))"

# Copy app files — the RUN rm line is required to clear default sample apps
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/i

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
