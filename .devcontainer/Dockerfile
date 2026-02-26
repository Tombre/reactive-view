FROM ruby:3.4.3-bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libatspi2.0-0 \
  build-essential \
  ca-certificates \
  curl \
  git \
  libdbus-1-3 \
  libgbm1 \
  libcups2 \
  libnspr4 \
  libnss3 \
  libsqlite3-dev \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxkbcommon0 \
  libxrandr2 \
  nodejs \
  npm \
  pkg-config \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g agent-browser \
  && agent-browser install

RUN gem install foreman

WORKDIR /workspaces/reactive-view
