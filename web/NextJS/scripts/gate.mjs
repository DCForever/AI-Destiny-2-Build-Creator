#!/usr/bin/env node
/**
 * Cross-platform quality gate:
 *   product-map:ci → typecheck → lint → test → build
 * Fails fast on first non-zero exit (Windows/macOS/Linux; no bash required).
 *
 * Skip product-map: GATE_SKIP_PRODUCT_MAP=1
 * Soft product-map (warn only): PRODUCT_MAP_CI_SOFT=1
 */
import { spawnSync } from "node:child_process";

const skipMap = process.env.GATE_SKIP_PRODUCT_MAP === "1";
const steps = skipMap
  ? ["typecheck", "lint", "test", "build"]
  : ["product-map:ci", "typecheck", "lint", "test", "build"];

for (const step of steps) {
  console.log(`\n==> npm run ${step}`);
  const result = spawnSync("npm", ["run", step], {
    stdio: "inherit",
    shell: true,
    env: process.env,
  });
  const code = result.status ?? 1;
  if (code !== 0) {
    console.error(`\nGate failed at: npm run ${step} (exit ${code})`);
    process.exit(code);
  }
}

console.log("\nGate passed.");
