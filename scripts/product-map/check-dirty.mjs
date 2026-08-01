#!/usr/bin/env node
/**
 * Regenerate product-map projections and fail if tracked outputs are dirty.
 * Use in CI after checkout so hub edits must be followed by committed generate.
 *
 * Env:
 *   PRODUCT_MAP_SKIP_GENERATE=1  — only check dirty state (no regenerate)
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  ATLAS_LINKS_PATH,
  ATLAS_MANIFEST_PATH,
  DRAWIO_PATH,
  INVENTORY_PATH,
  REPO_ROOT,
} from "./lib/paths.mjs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const skipGen = process.env.PRODUCT_MAP_SKIP_GENERATE === "1";

const TRACKED = [
  path.relative(REPO_ROOT, INVENTORY_PATH).replace(/\\/g, "/"),
  path.relative(REPO_ROOT, DRAWIO_PATH).replace(/\\/g, "/"),
  path.relative(REPO_ROOT, ATLAS_LINKS_PATH).replace(/\\/g, "/"),
  path.relative(REPO_ROOT, ATLAS_MANIFEST_PATH).replace(/\\/g, "/"),
];

function run(cmd, args) {
  // Prefer argv array without shell (avoids DEP0190 + injection)
  return spawnSync(cmd, args, {
    cwd: REPO_ROOT,
    encoding: "utf8",
    windowsHide: true,
  });
}

function main() {
  if (!skipGen) {
    console.log("product-map:check-dirty — regenerating…");
    const gen = spawnSync(process.execPath, [path.join(dir, "generate.mjs")], {
      cwd: REPO_ROOT,
      stdio: "inherit",
    });
    if ((gen.status ?? 1) !== 0) {
      console.error("Generate failed");
      process.exit(gen.status ?? 1);
    }
  }

  const diff = run("git", ["diff", "--stat", "--", ...TRACKED]);
  const status = run("git", ["status", "--porcelain", "--", ...TRACKED]);
  const porcelain = (status.stdout || "").trim();
  if (porcelain) {
    console.error("product-map:check-dirty FAILED — generated outputs differ from git:\n");
    console.error(porcelain);
    console.error("\nDiff stat:");
    console.error(diff.stdout || "(no stat)");
    console.error(
      "\nFix: npm run product-map:sync && git add docs/ui-rules docs/atlas/manifest.json docs/atlas/ui-rules-links.json",
    );
    process.exit(1);
  }

  console.log(
    `product-map:check-dirty OK (${TRACKED.length} paths clean after generate)`,
  );
}

main();
