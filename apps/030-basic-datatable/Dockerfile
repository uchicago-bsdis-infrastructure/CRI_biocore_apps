FROM rocker/shiny:4.4.2

RUN R -e "install.packages(c('ggplot2', 'DT'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
