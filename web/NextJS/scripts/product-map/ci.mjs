#!/usr/bin/env node
/**
 * Product-map CI gate:
 *   validate → generate → check (errors fail) → check-dirty → orphan-rules (report only)
 *
 * Env:
 *   PRODUCT_MAP_CHECK_STRICT=1  — also fail check.mjs on warnings
 *   PRODUCT_MAP_ORPHAN_STRICT=1 — fail if domain rules unattached
 *   PRODUCT_MAP_CI_SOFT=1       — log failures but exit 0 (transition mode)
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { REPO_ROOT } from "./lib/paths.mjs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const soft = process.env.PRODUCT_MAP_CI_SOFT === "1";

function run(script, env = {}) {
  console.log(`\n==> product-map ${script}`);
  const r = spawnSync(process.execPath, [path.join(dir, script)], {
    cwd: REPO_ROOT,
    stdio: "inherit",
    env: { ...process.env, ...env },
  });
  return r.status ?? 1;
}

function main() {
  let failed = 0;

  // validate hub structure
  if (run("validate.mjs") !== 0) failed = 1;

  // regenerate projections
  if (run("generate.mjs") !== 0) failed = 1;

  // drift / missing surfaces — errors fail; warnings OK unless STRICT
  if (run("check.mjs") !== 0) failed = 1;

  // committed outputs must match generate
  if (run("check-dirty.mjs", { PRODUCT_MAP_SKIP_GENERATE: "1" }) !== 0) {
    failed = 1;
  }

  // orphan report always; never fail unless ORPHAN_STRICT
  run("orphan-rules.mjs");

  // flutter parity report (non-fatal)
  run("parity.mjs");

  if (failed) {
    console.error("\nproduct-map:ci FAILED");
    if (soft) {
      console.error("(PRODUCT_MAP_CI_SOFT=1 — not failing parent gate)");
      process.exit(0);
    }
    process.exit(1);
  }
  console.log("\nproduct-map:ci OK");
}

main();
