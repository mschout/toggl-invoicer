FROM perl:5.26-slim AS perl-modules

RUN apt-get update && \
    apt-get -y install build-essential openssl libssl-dev libz-dev texlive-latex-base

COPY cpanfile /app/cpanfile
COPY cpanfile.snapshot /app/cpanfile.snapshot
COPY vendor /app/vendor
WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5
RUN ./vendor/bin/carton install && rm -rf $HOME/.cpanm && rm -rf vendor

FROM perl:5.26-slim

RUN apt-get update \
    && apt-get install -y \
        openssl \
        texlive-latex-base \
        texlive-xetex \
    && rm -rf /var/apt/cache/*

COPY --from=perl-modules /app/local /app/local

WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5

COPY . /app
