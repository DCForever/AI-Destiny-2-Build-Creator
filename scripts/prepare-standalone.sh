#!/usr/bin/env bash
# Copy static assets into the Next.js standalone output tree.
# Required before running the sidecar or Electron shell.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STANDALONE="$ROOT/.next/standalone"

if [[ ! -f "$STANDALONE/server.js" ]]; then
  echo "error: missing $STANDALONE/server.js — run npm run build first" >&2
  exit 1
fi

mkdir -p "$STANDALONE/.next"
rm -rf "$STANDALONE/public"
cp -R "$ROOT/public" "$STANDALONE/public"
rm -rf "$STANDALONE/.next/static"
cp -R "$ROOT/.next/static" "$STANDALONE/.next/static"

echo "Prepared standalone at $STANDALONE"
