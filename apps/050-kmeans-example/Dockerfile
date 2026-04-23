FROM rocker/shiny:4.4.2

# Install OS deps (add more as needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R package dependencies detected from the app
RUN Rscript -e "install.packages(c('shiny'), repos='https://cran.rstudio.com/')"

# Copy app source
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
