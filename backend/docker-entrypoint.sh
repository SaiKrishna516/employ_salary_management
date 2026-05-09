#!/bin/sh
set -e

# Remove stale Puma PID file — without this, Docker restarts fail with
# "A server is already running. Check /app/tmp/pids/server.pid."
rm -f tmp/pids/server.pid

echo "==> Waiting for database..."
until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" 2>/dev/null; do
  echo "    DB not ready yet, retrying in 1s..."
  sleep 1
done

echo "==> Running migrations..."
bundle exec rails db:migrate

echo "==> Starting Puma on port ${PORT:-3001}..."
exec "$@"
