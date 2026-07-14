#!/usr/bin/env bash
# Headless Electron shell spike: spawn sidecar, confirm ready, shut down cleanly.
# Requires: npm i -D electron (not installed by default — large download).
# See docs/packaging-desktop.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.next/standalone/server.js" ]]; then
  echo "==> Standalone missing; building first"
  npm run build
  bash scripts/prepare-standalone.sh
else
  bash scripts/prepare-standalone.sh
fi

ELECTRON_BIN=""
if [[ -x "$ROOT/node_modules/.bin/electron" ]]; then
  ELECTRON_BIN="$ROOT/node_modules/.bin/electron"
elif command -v electron >/dev/null 2>&1; then
  ELECTRON_BIN="$(command -v electron)"
fi

if [[ -z "$ELECTRON_BIN" ]]; then
  echo "FAIL: electron not installed. Run: npm i -D electron" >&2
  exit 1
fi

PORT="${D2BC_PORT:-3011}"
CACHE_DIR="${D2BC_CACHE_ROOT:-$(mktemp -d -t d2bc-electron-cache-XXXXXX)}"

echo "==> Running Electron headless spike (port=$PORT cache=$CACHE_DIR)"
# xvfb-run helps on Linux CI without a display; fall back to plain electron.
run_electron() {
  D2BC_SPIKE_HEADLESS=1 \
  D2BC_PORT="$PORT" \
  D2BC_CACHE_ROOT="$CACHE_DIR" \
  D2BC_STANDALONE_DIR="$ROOT/.next/standalone" \
    "$@" "$ROOT/desktop"
}

OUT="$(mktemp)"
if command -v xvfb-run >/dev/null 2>&1; then
  run_electron xvfb-run -a "$ELECTRON_BIN" | tee "$OUT"
else
  # Electron may still boot in headless spike mode without a window.
  run_electron "$ELECTRON_BIN" | tee "$OUT"
fi

if ! grep -q '"ok":true' "$OUT"; then
  echo "FAIL: electron spike did not report ok:true" >&2
  exit 1
fi

# Ensure no orphan listener on the spike port
sleep 1
if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
  echo "FAIL: port $PORT still responding after Electron exit (orphan sidecar)" >&2
  exit 1
fi

echo "==> Spike electron PASSED"
cat "$OUT" | grep '"ok":true' | tail -n 1
