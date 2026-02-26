#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="/workspaces/reactive-view"
GEM_DIR="$REPO_ROOT/reactive_view"
EXAMPLE_DIR="$REPO_ROOT/examples/reactive_view_example"

if [ -d "$GEM_DIR" ]; then
  echo "Installing gem dependencies in reactive_view/..."
  bundle install --gemfile "$GEM_DIR/Gemfile"
fi

if [ -d "$EXAMPLE_DIR" ]; then
  echo "Installing example app dependencies..."
  bundle install --gemfile "$EXAMPLE_DIR/Gemfile"

  if [ ! -d "$EXAMPLE_DIR/.reactive_view" ]; then
    echo "Running ReactiveView setup for example app..."
    (cd "$EXAMPLE_DIR" && bin/rails reactive_view:setup)
  else
    echo "Syncing ReactiveView files for example app..."
    (cd "$EXAMPLE_DIR" && bin/rails reactive_view:sync 2>/dev/null || true)
  fi

  echo "Preparing example database..."
  (cd "$EXAMPLE_DIR" && bin/rails db:prepare)
fi

echo "Dev container setup complete."
