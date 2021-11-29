ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION

RUN gem install bitcoin-ruby:0.0.20 ecdsa:1.2.0 rest-client:2.1.0 virtus:2.0.0

COPY . /app

WORKDIR /app
