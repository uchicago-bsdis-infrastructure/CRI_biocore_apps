FROM rocker/shiny:4.4.2

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shinydashboard', 'dplyr', 'shinyWidgets', 'shinyjs', 'shinyFiles', 'DT', 'shiny', 'ggplot2'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
