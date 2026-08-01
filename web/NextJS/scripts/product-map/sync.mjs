#!/usr/bin/env node
/**
 * validate → generate
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const dir = path.dirname(fileURLToPath(import.meta.url));

function run(script) {
  const r = spawnSync(process.execPath, [path.join(dir, script)], {
    stdio: "inherit",
  });
  if (r.status !== 0) process.exit(r.status || 1);
}

run("validate.mjs");
run("generate.mjs");
run("check.mjs");
console.log("product-map:sync OK");
