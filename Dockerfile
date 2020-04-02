FROM perl:5.26-slim AS base-image

# Install extra packages needed in final image
RUN apt-get update \
    && apt-get install -y \
        openssl \
        texlive-latex-base \
        texlive-xetex \
    && rm -rf /var/apt/lists/* /var/apt/cache/*

## Carton install layer
FROM base-image AS carton

# Install dev packages needed for carton install
RUN apt update \
  && apt -y install \
    build-essential \
    libssl-dev \
    libz-dev \
  && rm -rf /var/apt/lists/* /var/apt/cache/*

COPY cpanfile /app/cpanfile
COPY cpanfile.snapshot /app/cpanfile.snapshot
COPY vendor /app/vendor
WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5
RUN ./vendor/bin/carton install && rm -rf $HOME/.cpanm && rm -rf vendor

## Final image layer
FROM base-image

COPY --from=carton /app/local /app/local

WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5

COPY . /app
