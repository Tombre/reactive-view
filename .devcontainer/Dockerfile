FROM ruby:3.4.3-bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  libsqlite3-dev \
  nodejs \
  npm \
  pkg-config \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*

RUN gem install foreman

WORKDIR /workspaces/reactive-view
