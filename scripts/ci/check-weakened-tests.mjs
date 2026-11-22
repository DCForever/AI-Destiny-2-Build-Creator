#!/usr/bin/env node
/** CI entry: weakened-test heuristic. */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import {
  analyzeWeakenedDiff,
  resolveBase,
} from "./check-weakened-tests-lib.mjs";

const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
const base = resolveBase(preferred);
const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
const diff = sh(`git diff --unified=0 ${base}...HEAD`);
const nameStatus = sh(`git diff --name-status ${base}...HEAD`).split("\n");
const findings = analyzeWeakenedDiff(diff, nameStatus);
const summary = [
  "## Weakened-test heuristic",
  "",
  `Base: \`${base}\``,
  "",
  findings.length
    ? findings.map((f) => `- **${f.kind}** \`${f.path}\`: ${f.detail}`).join("\n")
    : "No weakened-test signals.",
  "",
].join("\n");
if (process.env.GITHUB_STEP_SUMMARY) {
  writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
}
console.log(summary);
if (findings.length) {
  console.error("::error::Weakened-test heuristic failed");
  process.exit(1);
}
console.log("weakened-test: ok");
