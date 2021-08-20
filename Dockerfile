FROM ruby:2.6-slim-stretch

LABEL maintainer="weex"
LABEL source="https://github.com/weex/diaspora"

ARG DIASPORA_VER=0.7.9.0

ENV RAILS_ENV=production \
    UID=942 \
    GID=942

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt-dev \
    imagemagick \
    ghostscript \
    curl \
    libmagickwand-dev \
    git \
    libpq-dev \
    nodejs \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --GID ${GID} diaspora \
    && adduser --uid ${UID} --gid ${GID} \
    --home /diaspora --shell /bin/sh \
    --disabled-password --gecos "" diaspora

USER diaspora

WORKDIR /diaspora

RUN wget -qO- https://github.com/weex/diaspora/archive/c4.tar.gz | tar xz --strip 1 \
    && mkdir /diaspora/log \
    && cp config/database.yml.example config/database.yml

RUN gem install bundler \
    && script/configure_bundler \
    && bin/bundle install --full-index -j$(getconf _NPROCESSORS_ONLN)

VOLUME /diaspora/public
