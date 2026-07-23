#!/usr/bin/env node
/**
 * Cross-platform quality gate: typecheck → lint → test → build.
 * Fails fast on first non-zero exit (Windows/macOS/Linux; no bash required).
 */
import { spawnSync } from "node:child_process";

const steps = ["typecheck", "lint", "test", "build"];

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
