FROM rocker/shiny:4.4.2

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('BiocManager')" \
 && R -e "install.packages(c('shinydashboard', 'DT', 'shiny', 'ggplot2', 'gplots'))" \
 && R -e "BiocManager::install(c('edgeR', 'DESeq2', 'limma'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
