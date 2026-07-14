#!/usr/bin/env bash
# Prove Next standalone + better-sqlite3 + D2BC_CACHE_ROOT on this machine.
# See docs/packaging-desktop.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${D2BC_PORT:-3010}"
CACHE_DIR="${D2BC_CACHE_ROOT:-$(mktemp -d -t d2bc-spike-cache-XXXXXX)}"
export D2BC_CACHE_ROOT="$CACHE_DIR"
STANDALONE="$ROOT/.next/standalone"
PID=""

cleanup() {
  if [[ -n "${PID}" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "==> Building (standalone output)"
npm run build

echo "==> Preparing standalone static assets"
bash scripts/prepare-standalone.sh

if [[ ! -f "$STANDALONE/server.js" ]]; then
  echo "FAIL: standalone server.js missing" >&2
  exit 1
fi

SQLITE_NODE="$(find "$STANDALONE" -name 'better_sqlite3.node' 2>/dev/null | head -n 1 || true)"
if [[ -z "$SQLITE_NODE" ]]; then
  SQLITE_NODE="$(find "$ROOT/node_modules/better-sqlite3" -name 'better_sqlite3.node' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$SQLITE_NODE" ]]; then
    echo "WARN: better_sqlite3.node only found under root node_modules (serverExternalPackages)"
  fi
fi
if [[ -z "$SQLITE_NODE" ]]; then
  echo "FAIL: could not locate better_sqlite3.node" >&2
  exit 1
fi
echo "OK: native sqlite at $SQLITE_NODE"

# Session cookie helper is imported by some catalog paths; provide a spike-only secret.
export SESSION_SECRET="${SESSION_SECRET:-d2bc-spike-session-secret-32chars-min}"

echo "==> Starting sidecar on 127.0.0.1:$PORT (cache=$CACHE_DIR)"
(
  cd "$STANDALONE"
  HOSTNAME=127.0.0.1 PORT="$PORT" D2BC_CACHE_ROOT="$CACHE_DIR" \
  SESSION_SECRET="$SESSION_SECRET" NODE_ENV=production \
    node server.js
) &
PID=$!

echo "==> Waiting for HTTP ready"
ready=0
for _ in $(seq 1 120); do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "FAIL: sidecar exited before ready" >&2
    exit 1
  fi
  sleep 0.5
done
if [[ "$ready" -ne 1 ]]; then
  echo "FAIL: timeout waiting for http://127.0.0.1:$PORT/" >&2
  exit 1
fi
echo "OK: HTTP ready"

echo "==> Touching API that opens SQLite (catalog weapons)"
# May return non-200 without manifest; still must initialize app.db via getDb().
set +e
STATUS="$(curl -sS -o /tmp/d2bc-spike-catalog.json -w "%{http_code}" \
  "http://127.0.0.1:$PORT/api/catalog/weapons?limit=1")"
set -e
echo "catalog status=$STATUS body=$(head -c 200 /tmp/d2bc-spike-catalog.json || true)"

DB_PATH="$CACHE_DIR/app.db"
if [[ ! -f "$DB_PATH" ]]; then
  echo "FAIL: expected SQLite at $DB_PATH after catalog request" >&2
  echo "cache tree:" >&2
  find "$CACHE_DIR" -maxdepth 3 -type f 2>/dev/null || true
  exit 1
fi
echo "OK: SQLite created at $DB_PATH"

DB_PATH="$DB_PATH" node --input-type=module <<'EOF'
import Database from "better-sqlite3";
const db = new Database(process.env.DB_PATH, { readonly: true });
const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
if (!tables.length) {
  console.error("FAIL: app.db has no tables");
  process.exit(1);
}
console.log(
  "OK: better-sqlite3 opened app.db; tables=",
  tables.map((t) => t.name).slice(0, 8).join(","),
);
db.close();
EOF

echo "==> Spike standalone PASSED"
PORT="$PORT" DB_PATH="$DB_PATH" D2BC_CACHE_ROOT="$CACHE_DIR" node -e \
  'console.log(JSON.stringify({ok:true,port:Number(process.env.PORT),cacheRoot:process.env.D2BC_CACHE_ROOT,dbPath:process.env.DB_PATH}))'
