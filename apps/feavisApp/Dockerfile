FROM rocker/shiny:latest

RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', 'shinyjs', 'shinyFiles', 'dplyr', 'DT', 'ggplot2', 'readxl', 'openxlsx'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
