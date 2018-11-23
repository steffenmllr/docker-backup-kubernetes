FROM ruby:2.3-alpine

RUN \
  apk --update add \
    build-base \
    libxml2-dev \
    libxslt-dev \
    postgresql \
    readline-dev \
    tar \
    zlib-dev && \
  rm -rf /var/cache/apk/*

RUN gem install backup -v 4.4.1 --no-ri --no-rdoc
