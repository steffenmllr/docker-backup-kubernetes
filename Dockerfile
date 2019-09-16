FROM ruby:2-alpine

RUN \
  apk add --no-cache \
    build-base \
    libxml2-dev \
    libxslt-dev \
    postgresql \
    readline-dev \
    openssl \
    gnupg \
    gzip \
    tar \
    zlib-dev && \
  rm -rf /var/cache/apk/*

RUN gem install backup -v 5.0.0.beta.2
