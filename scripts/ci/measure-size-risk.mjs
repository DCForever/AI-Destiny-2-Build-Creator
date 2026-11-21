#!/usr/bin/env node
/** CI entry: size/risk labels. Logic + self-tests under test/ci/. */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import {
  isExcludedFromProduction,
  isTestPath,
  measureSizeRisk,
  resolveBase,
  SMALL,
} from "../../test/ci/lib/measure-size-risk-lib.mjs";

const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
const base = resolveBase(preferred);
const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
const numstat = sh(`git diff --numstat ${base}...HEAD`);
const nameStatus = sh(`git diff --name-status ${base}...HEAD`);
const allPaths = [];
for (const line of nameStatus.split("\n")) {
  if (!line.trim()) continue;
  const parts = line.split("\t");
  allPaths.push(parts[parts.length - 1]);
}
const prodPaths = allPaths.filter((p) => !isExcludedFromProduction(p));
const testPaths = allPaths.filter((p) => isTestPath(p));
const prodPatch = prodPaths.length
  ? sh(`git diff ${base}...HEAD -- ${prodPaths.map((p) => JSON.stringify(p)).join(" ")}`)
  : "";
const testPatch = testPaths.length
  ? sh(`git diff ${base}...HEAD -- ${testPaths.map((p) => JSON.stringify(p)).join(" ")}`)
  : "";
const { added, deleted, prod, flags, size } = measureSizeRisk({
  numstat,
  nameStatus,
  prodPatch,
  testPatch,
  allPaths,
});
const labels = [`size/${size.toLowerCase()}`, ...flags.map((f) => `risk/${f}`)];
const summary = [
  "## Size / risk labels",
  "",
  `Base: \`${base}\``,
  "",
  `- Production added lines (exclude tests + docs): **${added}**`,
  `- Production deleted lines: **${deleted}**`,
  `- Size: **${size}** (Small ≤ ${SMALL})`,
  `- Flags: ${flags.length ? flags.map((f) => `\`${f}\``).join(", ") : "_none_"}`,
  `- Label hints: ${labels.map((l) => `\`${l}\``).join(", ")}`,
  "",
  prod.length
    ? `Production files (${prod.length}):\n${prod.map((f) => `- \`${f}\``).join("\n")}`
    : "No production files in diff.",
  "",
].join("\n");
if (process.env.GITHUB_STEP_SUMMARY) {
  writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
}
console.log(summary);
console.log(`SIZE=${size}`);
console.log(`ADDED=${added}`);
console.log(`FLAGS=${flags.join(",")}`);
console.log(`LABELS=${labels.join(",")}`);
