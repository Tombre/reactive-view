FROM ruby:3.4.3-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  git \
  libsqlite3-dev \
  nodejs \
  npm \
  pkg-config \
  && rm -rf /var/lib/apt/lists/*

RUN gem install bundler foreman

WORKDIR /app

# Copy the gem and example app so the local Gemfile path dependency resolves.
COPY reactive_view /app/reactive_view
COPY examples/reactive_view_example /app/examples/reactive_view_example

WORKDIR /app/examples/reactive_view_example

RUN bundle install

EXPOSE 3000

CMD ["bin/start"]
