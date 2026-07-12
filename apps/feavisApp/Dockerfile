FROM rocker/shiny:4.4.2

# Pin shiny UID to match host shiny user (UID 992) for volume mount permissions
RUN usermod -u 992 shiny

RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', 'shinyjs', 'shinyFiles', 'dplyr', 'DT', 'ggplot2', 'readxl', 'openxlsx'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
