#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-flashcards}"
DB="${2:-postgresql}"  # postgresql or sqlite3 or mysql

echo "Creating Rails app: $APP_NAME (db: $DB)"
rails new "$APP_NAME" --database="$DB"

OVERLAY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_NAME"

echo "Overlaying files..."
rsync -av "$OVERLAY_DIR/" ./ --exclude '.git' --exclude 'scripts' --exclude 'README.md' --exclude '*.zip'

echo "Installing gems..."
bundle install

echo "Setting up database..."
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

echo "Done. Run with: bin/rails s"
