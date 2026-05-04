FROM rocker/r-ver:4.3.3

# Dependências de sistema
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libsodium-dev \
    libv8-dev \
    libsqlite3-dev \
    libspatialite-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Pacotes R — pipeline
RUN R -e "install.packages(c( \
    'downloader', 'RCurl', 'data.table', 'openxlsx', 'lubridate', \
    'dplyr', 'tidyverse', 'foreign', 'stringr', 'readxl', \
    'remotes', 'curl' \
), repos='https://cloud.r-project.org')"

# sf separado (depende das libs de sistema acima)
RUN R -e "install.packages('sf', repos='https://cloud.r-project.org')"

# Pacotes R — dashboard e gráficos
RUN R -e "install.packages(c( \
    'shiny', 'bslib', 'rlang', 'reshape2', 'thematic', 'bsicons', \
    'ggridges', 'leaflet', 'ggplot2', 'shinycssloaders', \
    'patchwork', 'gridExtra', 'DT' \
), repos='https://cloud.r-project.org')"

# read.dbc do GitHub
RUN R -e "remotes::install_github('danicat/read.dbc')"

# ribge do GitHub
RUN R -e "remotes::install_github('tbrugz/ribge')"

# geobr do GitHub (versão dev)
RUN R -e "remotes::install_github('ipeaGIT/geobr', subdir = 'r-package')"

COPY pipeline.R /scripts/pipeline.R
COPY graphs.R   /scripts/graphs.R

CMD ["bash", "-c", "Rscript /scripts/pipeline.R && Rscript /scripts/graphs.R"]
