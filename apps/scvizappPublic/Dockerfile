FROM rocker/shiny:4.4.2

# Pin shiny UID to match host shiny user (UID 992) for volume mount permissions
RUN usermod -u 992 shiny

# Install system dependencies (add as needed)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libglpk-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('dplyr', 'Seurat', 'SeuratObject', 'stringr', 'tidyr', \
  'renv', 'cowplot', 'ggplot2', 'grid', 'patchwork', 'readr', \
  'readxl', 'reshape2', 'stringi', 'tibble', \
  'shiny', 'tools', 'bslib', 'DT', 'plotly', 'remotes', \
  'shinydashboard', 'shinyWidgets', 'shinyjs', 'scCustomize', 'Polychrome', 'viridis', 'viridisLite'))"

# For Bioconductor packages
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install('dittoSeq')"

# presto is GitHub-only (immunogenomics/presto), not on CRAN/Bioconductor
RUN R -e "remotes::install_github('immunogenomics/presto')"

# Copy app files — the RUN rm line is required to clear default sample apps
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

RUN echo 'RENV_CONFIG_AUTOLOADER_ENABLED=FALSE' >> /usr/local/lib/R/etc/Renviron

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
