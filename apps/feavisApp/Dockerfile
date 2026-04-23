FROM rocker/shiny:4.4.2

# Pin shiny UID to match server directory ownership (/srv/data/ is chowned to 997)
RUN usermod -u 997 shiny

RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', 'shinyjs', 'shinyFiles', 'dplyr', 'DT', 'ggplot2', 'readxl', 'openxlsx'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
