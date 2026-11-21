#!/usr/bin/env node
/** Label production-diff size (exclude tests+docs) and risk flags.
 *  Flags: deletes, migrations, dest-write, ci-runner, auth-secrets,
 *  network-bind, test-weakening. Read-only; prints step summary. */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
const SMALL = 300;
const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
const base = [preferred, "origin/main", "main", "HEAD~1"].find((r) => {
  try { sh(`git rev-parse --verify ${r}`); return true; } catch { return false; }
});
if (!base) throw new Error("no base ref");

const excluded = (p) =>
  !p ||
  /(^|\/)docs(-site)?(\/|$)/.test(p) ||
  /\.md$/i.test(p) ||
  /(^|\/)test(s)?\//.test(p) ||
  /_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(p) ||
  /\.test\.(ts|tsx|js|mjs)$/i.test(p) ||
  /(^|\/)fixtures?\//.test(p) ||
  /(^|\/)__tests__\//.test(p);

let added = 0; let deleted = 0;
const prod = []; const gone = [];
for (const line of sh(`git diff --numstat ${base}...HEAD`).split("\n")) {
  if (!line.trim()) continue;
  const [a, d, path] = line.split("\t");
  if (excluded(path)) continue;
  prod.push(path);
  if (a !== "-") added += Number.parseInt(a, 10) || 0;
  if (d !== "-") deleted += Number.parseInt(d, 10) || 0;
}
for (const line of sh(`git diff --name-status ${base}...HEAD`).split("\n")) {
  if (!line.trim()) continue;
  const [status, ...rest] = line.split("\t");
  const path = rest[rest.length - 1];
  if (!excluded(path) && status.startsWith("D")) gone.push(path);
}

// Content flags scan product files only (not scripts/ci detectors).
const paths = prod.filter((p) => !p.startsWith("scripts/ci/"));
const patch = paths.length
  ? sh(`git diff ${base}...HEAD -- ${paths.map((p) => JSON.stringify(p)).join(" ")}`)
  : "";
const flags = new Set();
if (gone.length || /\b(dismantle|DeleteItem)\b/.test(patch)) flags.add("deletes");
if (/(migration|schemaVersion|ALTER TABLE)/i.test(patch)) flags.add("migrations");
if (/[Dd]:\\| [Ee]:\\| [Zz]:\\|\/Volumes\//.test(patch)) flags.add("dest-write");
if (paths.some((p) => p.startsWith(".github/workflows/")) && /runs-on:/.test(patch)) {
  flags.add("ci-runner");
}
if (/(CLIENT_SECRET|SESSION_SECRET)\b/.test(patch)) flags.add("auth-secrets");
if (/(0\.0\.0\.0|listen\(|HOST\s*=)/i.test(patch)) flags.add("network-bind");
if (/findsOneWidget[\s\S]{0,80}findsWidgets/.test(patch)) flags.add("test-weakening");

const size = added <= SMALL ? "Small" : "Large";
const flagList = [...flags].sort();
const labels = [`size/${size.toLowerCase()}`, ...flagList.map((f) => `risk/${f}`)];
const summary = [
  "## Size / risk labels",
  "",
  `Base: \`${base}\``,
  "",
  `- Production added lines (exclude tests + docs): **${added}**`,
  `- Production deleted lines: **${deleted}**`,
  `- Size: **${size}** (Small ≤ ${SMALL})`,
  `- Flags: ${flagList.length ? flagList.map((f) => `\`${f}\``).join(", ") : "_none_"}`,
  `- Label hints: ${labels.map((l) => `\`${l}\``).join(", ")}`,
  "",
  prod.length ? `Production files (${prod.length}):\n${prod.map((f) => `- \`${f}\``).join("\n")}` : "No production files in diff.",
  "",
].join("\n");
if (process.env.GITHUB_STEP_SUMMARY) writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
console.log(summary);
console.log(`SIZE=${size}`);
console.log(`ADDED=${added}`);
console.log(`FLAGS=${flagList.join(",")}`);
console.log(`LABELS=${labels.join(",")}`);
