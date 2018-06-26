FROM perl:5.26

RUN apt-get update && \
    apt-get -y install \
        texlive-latex-base \
        texlive-xetex \
    && apt-get clean all

COPY . /app
WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5
RUN ./vendor/bin/carton install && rm -rf $HOME/.cpanm

