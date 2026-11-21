#!/usr/bin/env node
/**
 * Thin Skeptic shared CI: measure production-diff size (exclude tests + docs)
 * and emit size/risk labels as a check summary (no write permissions required).
 *
 * Flags: deletes, migrations, dest-write, ci-runner, auth-secrets,
 * network-bind, test-weakening.
 *
 * Usage: node scripts/ci/measure-size-risk.mjs [base_ref]
 * Exit 0 always for labeling; prints SIZE=Small|Large and FLAGS=...
 */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const baseArg = process.argv[2] || process.env.BASE_REF || "origin/main";
const SMALL_MAX = 300;

function sh(cmd) {
  return execSync(cmd, { encoding: "utf8" }).trim();
}

function resolveBase(preferred) {
  for (const candidate of [preferred, "origin/main", "main", "HEAD~1"]) {
    try {
      sh(`git rev-parse --verify ${candidate}`);
      return candidate;
    } catch {
      // try next
    }
  }
  throw new Error("Could not resolve a git base ref");
}

function isExcluded(path) {
  if (!path) return true;
  if (/(^|\/)docs(\/|$)/.test(path)) return true;
  if (/(^|\/)docs-site(\/|$)/.test(path)) return true;
  if (/\.md$/i.test(path)) return true;
  if (/(^|\/)test(s)?\//.test(path)) return true;
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(path)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(path)) return true;
  if (/(^|\/)fixtures?\//.test(path)) return true;
  if (/(^|\/)__tests__\//.test(path)) return true;
  return false;
}

const base = resolveBase(baseArg);
const numstat = sh(`git diff --numstat ${base}...HEAD`);
let added = 0;
let deleted = 0;
const productionFiles = [];
const deletedFiles = [];

for (const line of numstat.split("\n")) {
  if (!line.trim()) continue;
  const parts = line.split("\t");
  if (parts.length < 3) continue;
  const [a, d, path] = parts;
  if (isExcluded(path)) continue;
  productionFiles.push(path);
  if (a !== "-") added += Number.parseInt(a, 10) || 0;
  if (d !== "-") deleted += Number.parseInt(d, 10) || 0;
  if (a === "0" && d !== "0" && d !== "-") {
    // pure deletions still count as touched
  }
}

const nameStatus = sh(`git diff --name-status ${base}...HEAD`);
for (const line of nameStatus.split("\n")) {
  if (!line.trim()) continue;
  const [status, ...rest] = line.split("\t");
  const path = rest[rest.length - 1];
  if (isExcluded(path)) continue;
  if (status.startsWith("D")) deletedFiles.push(path);
}

const patch = sh(`git diff ${base}...HEAD`);
const flags = new Set();

if (deletedFiles.length > 0 || /\b(dismantle|deleteItem|DeleteItem|unlinkSync|rmSync)\b/.test(patch)) {
  // Only set deletes when production paths show file deletes or destructive APIs.
  const prodPatch = productionFiles.length > 0;
  if (deletedFiles.length > 0 || (prodPatch && /\b(dismantle|DeleteItem)\b/.test(patch))) {
    flags.add("deletes");
  }
}
if (/(migration|schemaVersion|ALTER TABLE|answers\.jsonl|cache-key)/i.test(patch)) {
  flags.add("migrations");
}
if (/[Dd]:\\| [Ee]:\\| [Zz]:\\|\/Volumes\/|Bungie.*[Ww]rite|vault.*write/i.test(patch)) {
  flags.add("dest-write");
}
if (/\.github\/workflows\//.test(patch) && /runs-on:/.test(patch)) {
  flags.add("ci-runner");
}
if (/(CLIENT_SECRET|SESSION_SECRET|api[_-]?key|refresh_token|access_token\s*[:=])/i.test(patch)) {
  flags.add("auth-secrets");
}
if (/(0\.0\.0\.0|listen\(|bind\(|HOST\s*=\s*['\"]?\*)/i.test(patch)) {
  flags.add("network-bind");
}

// test-weakening: reuse the same cheap signals as the weakened-test job.
if (
  /findsOneWidget.*\n\+.*findsWidgets/s.test(patch) ||
  (/^-.*\b==\b/m.test(patch) && /^\+.*>=/m.test(patch))
) {
  flags.add("test-weakening");
}

const size = added <= SMALL_MAX ? "Small" : "Large";
const flagList = [...flags].sort();
const labelHints = [
  `size/${size.toLowerCase()}`,
  ...flagList.map((f) => `risk/${f}`),
];

const summary = [
  "## Size / risk labels",
  "",
  `Base: \`${base}\``,
  "",
  `- Production added lines (exclude tests + docs): **${added}**`,
  `- Production deleted lines: **${deleted}**`,
  `- Size: **${size}** (Small ≤ ${SMALL_MAX})`,
  `- Flags: ${flagList.length ? flagList.map((f) => `\`${f}\``).join(", ") : "_none_"}`,
  `- Label hints: ${labelHints.map((l) => `\`${l}\``).join(", ")}`,
  "",
  productionFiles.length
    ? `Production files (${productionFiles.length}):\n${productionFiles.map((f) => `- \`${f}\``).join("\n")}`
    : "No production files in diff.",
  "",
].join("\n");

if (process.env.GITHUB_STEP_SUMMARY) {
  writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
}
console.log(summary);
console.log(`SIZE=${size}`);
console.log(`ADDED=${added}`);
console.log(`FLAGS=${flagList.join(",")}`);
console.log(`LABELS=${labelHints.join(",")}`);
