FROM rocker/shiny:4.4.2

# System dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# CRAN packages
RUN R -e "install.packages(c('circlize', 'dplyr', 'tibble', 'tidyr', 'sass', 'bslib'))"

# Bioconductor packages
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install('ComplexHeatmap', update = FALSE, ask = FALSE)"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
