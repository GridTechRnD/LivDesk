#!/bin/sh
set -x

git config --global --add safe.directory /app

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force --reporter=append-only --loglevel=debug

echo "Ready to run Vite development server."

exec "$@"
