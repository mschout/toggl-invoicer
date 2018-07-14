FROM perl:5.26

RUN apt-get update && \
    apt-get -y install \
        texlive-latex-base \
        texlive-xetex \
    && apt-get clean all

# copy cpanfile and snapshot to the app first so that other code changes do not
# bust the docker cache
COPY cpanfile /app/cpanfile
COPY cpanfile.snapshot /app/cpanfile.snapshot
COPY vendor /app/vendor
WORKDIR /app
ENV PERL5LIB /app/local/lib/perl5
RUN ./vendor/bin/carton install && rm -rf $HOME/.cpanm && rm -rf vendor

COPY . /app
