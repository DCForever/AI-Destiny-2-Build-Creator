#!/usr/bin/env bash
set -euo pipefail

if [[ "${GATE_SKIP_PRODUCT_MAP:-}" != "1" ]]; then
  npm run product-map:ci
fi
npm run typecheck
npm run lint
npm run test
npm run build

echo "Gate passed."
