FROM ruby:3.4.3-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  libcairo2 \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libatspi2.0-0 \
  libdbus-1-3 \
  libgbm1 \
  libglib2.0-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libx11-6 \
  libxcomposite1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxkbcommon0 \
  libxrandr2 \
  libxcb1 \
  libcups2 \
  git \
  libsqlite3-dev \
  libyaml-dev \
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
RUN npm install -g playwright@1.58.2
RUN playwright install chromium

EXPOSE 3000

CMD ["bin/start"]
