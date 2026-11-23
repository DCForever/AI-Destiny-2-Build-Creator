#!/usr/bin/env node
/** CI entry: weakened-test heuristic. */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import {
  analyzeWeakenedDiff,
  deletedProductionPaths,
  failingWeakenedFindings,
  resolveBase,
} from "./check-weakened-tests-lib.mjs";

const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
const base = resolveBase(preferred);
const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
const diff = sh(`git diff --unified=0 ${base}...HEAD`);
const nameStatus = sh(`git diff --name-status ${base}...HEAD`).split("\n");
const deletedProd = deletedProductionPaths(nameStatus);
const readBaseFile = (path) => {
  try {
    return sh(`git show ${base}:${path}`);
  } catch {
    return null;
  }
};
const findings = analyzeWeakenedDiff(diff, nameStatus, {
  deletedProductionPaths: deletedProd,
  readBaseFile,
});
const blocking = failingWeakenedFindings(findings);
const summary = [
  "## Weakened-test heuristic",
  "",
  `Base: \`${base}\``,
  "",
  findings.length
    ? findings.map((f) => `- **${f.kind}** \`${f.path}\`: ${f.detail}`).join("\n")
    : "No weakened-test signals.",
  "",
];
if (findings.some((f) => f.kind === "retired-test")) {
  summary.push(
    "_retired-test findings are non-blocking (require review via size/risk deletes / test-weakening)._",
    "",
  );
}
const summaryText = summary.join("\n");
if (process.env.GITHUB_STEP_SUMMARY) {
  writeFileSync(process.env.GITHUB_STEP_SUMMARY, summaryText, { flag: "a" });
}
console.log(summaryText);
if (blocking.length) {
  console.error("::error::Weakened-test heuristic failed");
  process.exit(1);
}
console.log("weakened-test: ok");
