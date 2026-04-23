FROM rocker/shiny:4.4.2

# Install system dependencies (add as needed)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'ggplot2', 'dplyr'))"

# For Bioconductor packages
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install(c('edgeR'))"

# Copy app files
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
