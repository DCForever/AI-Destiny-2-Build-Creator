#!/usr/bin/env node
/**
 * Ban paid InsertSocketPlug + dismantle/DeleteItem under flutter/ (packages+apps).
 * Self-tests: test/ci/check-bungie-writes.self-test.mjs
 */
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

/** Case-insensitive; Free suffix stays allowed. */
export const BANNED_INSERT = /insertsocketplug(?!free)/i;
/** Paid endpoint path (InsertSocketPlug/ without Free). */
export const BANNED_PAID_ENDPOINT =
  /Actions\/Items\/InsertSocketPlug(?!Free)\//i;
export const BANNED_DISMANTLE_DELETE = [
  /dismantleitem\b/i,
  /\/Destiny2\/Actions\/Items\/Dismantle\b/i,
  /deleteitem\b/i,
  /\/Destiny2\/Actions\/Items\/DeleteItem\b/i,
];

export function isScannedDartPath(path) {
  const n = (path || "").replace(/\\/g, "/");
  if (!n.endsWith(".dart") || !n.startsWith("flutter/")) return false;
  return !(n.includes("/test/") || n.endsWith("_test.dart"));
}

export function findViolationsInText(text, filePath = "") {
  const out = [];
  if (BANNED_INSERT.test(text)) {
    out.push({ path: filePath, rule: "InsertSocketPlug-not-Free" });
  }
  if (BANNED_PAID_ENDPOINT.test(text)) {
    out.push({ path: filePath, rule: "paid-InsertSocketPlug-endpoint" });
  }
  if (BANNED_DISMANTLE_DELETE.some((re) => re.test(text))) {
    out.push({ path: filePath, rule: "dismantle-or-DeleteItem" });
  }
  return out;
}

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) {
      if (name !== "test" && name !== ".dart_tool") walk(full, out);
    } else if (name.endsWith(".dart")) out.push(full);
  }
  return out;
}

export function scanBungieWrites(repoRoot) {
  const root = join(repoRoot, "flutter");
  const findings = [];
  let scanned = 0;
  for (const abs of walk(root)) {
    const rel = relative(repoRoot, abs).replace(/\\/g, "/");
    if (!isScannedDartPath(rel)) continue;
    scanned += 1;
    findings.push(...findViolationsInText(readFileSync(abs, "utf8"), rel));
  }
  return { findings, scanned };
}

const isMain = process.argv[1] &&
  fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
  const { findings, scanned } = scanBungieWrites(repoRoot);
  const text = [
    "## Bungie write-surface scan",
    "",
    `Scanned **${scanned}** non-test Dart files under \`flutter/\`.`,
    "",
    findings.length
      ? findings.map((f) => `- **${f.rule}** \`${f.path}\``).join("\n")
      : "No banned InsertSocketPlug / dismantle / DeleteItem matches.",
    "",
  ].join("\n");
  if (process.env.GITHUB_STEP_SUMMARY) {
    writeFileSync(process.env.GITHUB_STEP_SUMMARY, text, { flag: "a" });
  }
  console.log(text);
  if (scanned === 0) {
    console.error("::error::Bungie write-surface scan found 0 files");
    process.exit(1);
  }
  if (findings.length) {
    console.error("::error::Bungie write-surface scan failed");
    process.exit(1);
  }
  console.log("bungie-writes: ok");
}
