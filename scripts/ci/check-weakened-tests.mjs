#!/usr/bin/env node
/**
 * Thin Skeptic shared CI: fail (or label via summary) when a PR diff weakens
 * safety tests — dropped asserts, loosened matchers, or a changed safety test
 * with no negative case.
 *
 * Usage: node scripts/ci/check-weakened-tests.mjs [base_ref]
 * Default base: origin/main (falls back to main / HEAD~1).
 *
 * Exit 0 = ok; exit 1 = weakened tests detected.
 * No secrets. Read-only git. Does not mention Skeptic by name in output labels.
 */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const baseArg = process.argv[2] || process.env.BASE_REF || "origin/main";

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
  throw new Error("Could not resolve a git base ref for the test diff");
}

const base = resolveBase(baseArg);
const diff = sh(`git diff --unified=0 ${base}...HEAD`);

const findings = [];
const safetyPath =
  /(skeptic_|fail_closed|ownership|guard|undo|apply_socket|cache_write|path_guard|no_dismantle)/i;

/** @type {Map<string, {removedExpect: number, addedExpect: number, loosened: string[], addedNegative: boolean, touched: boolean}>} */
const perFile = new Map();

function fileState(path) {
  if (!perFile.has(path)) {
    perFile.set(path, {
      removedExpect: 0,
      addedExpect: 0,
      loosened: [],
      addedNegative: false,
      touched: false,
    });
  }
  return perFile.get(path);
}

let currentFile = null;
for (const line of diff.split("\n")) {
  const fileMatch = line.match(/^diff --git a\/(.+) b\/(.+)$/);
  if (fileMatch) {
    currentFile = fileMatch[2];
    continue;
  }
  if (!currentFile) continue;
  if (!/(^|\/)test(s)?\//.test(currentFile) && !/_test\.(dart|ts|tsx|js|mjs)$/.test(currentFile)) {
    continue;
  }
  const st = fileState(currentFile);
  st.touched = true;

  if (line.startsWith("-") && !line.startsWith("---")) {
    const body = line.slice(1);
    if (/\bexpect\s*\(/.test(body) || /\bassert\w*\s*\(/.test(body)) {
      st.removedExpect += 1;
    }
  }
  if (line.startsWith("+") && !line.startsWith("+++")) {
    const body = line.slice(1);
    if (/\bexpect\s*\(/.test(body) || /\bassert\w*\s*\(/.test(body)) {
      st.addedExpect += 1;
    }
    if (
      /\bfindsWidgets\b/.test(body) ||
      />=\s*\d+/.test(body) ||
      /\bisNot\s*\(\s*isEmpty\s*\)/.test(body)
    ) {
      // Loosened matcher heuristics (paired with a removed stricter form below).
    }
    if (
      /(refuse|fail|skip|throw|isFalse|isEmpty|notUnlocked|ReadFailed|instanceNotOwned|doesNotFit|EnergyCostUnknown)/i.test(
        body,
      )
    ) {
      st.addedNegative = true;
    }
  }
}

// Second pass: loosened matcher line pairs on the unified hunk.
const hunkLines = diff.split("\n");
currentFile = null;
for (let i = 0; i < hunkLines.length; i++) {
  const line = hunkLines[i];
  const fileMatch = line.match(/^diff --git a\/(.+) b\/(.+)$/);
  if (fileMatch) {
    currentFile = fileMatch[2];
    continue;
  }
  if (!currentFile) continue;
  if (!/(^|\/)test(s)?\//.test(currentFile) && !/_test\.(dart|ts|tsx|js|mjs)$/.test(currentFile)) {
    continue;
  }
  if (!line.startsWith("-") || line.startsWith("---")) continue;
  const removed = line.slice(1);
  const next = hunkLines[i + 1] || "";
  if (!next.startsWith("+") || next.startsWith("+++")) continue;
  const added = next.slice(1);
  const st = fileState(currentFile);
  if (/\b==\b/.test(removed) && />=/.test(added) && !/>=/.test(removed)) {
    st.loosened.push("== to >=");
  }
  if (/\bfindsOneWidget\b/.test(removed) && /\bfindsWidgets\b/.test(added)) {
    st.loosened.push("findsOneWidget to findsWidgets");
  }
  if (/\bfindsNothing\b/.test(removed) && /\bfindsWidgets\b/.test(added)) {
    st.loosened.push("findsNothing to findsWidgets");
  }
}

for (const [path, st] of perFile) {
  if (!st.touched) continue;
  const netExpect = st.addedExpect - st.removedExpect;
  if (st.removedExpect > 0 && netExpect < 0) {
    findings.push({
      path,
      kind: "dropped-asserts",
      detail: `removed ${st.removedExpect} expect/assert, added ${st.addedExpect}`,
    });
  }
  for (const tip of st.loosened) {
    findings.push({ path, kind: "loosened-matcher", detail: tip });
  }
  if (safetyPath.test(path) && st.touched && !st.addedNegative && st.removedExpect > 0) {
    findings.push({
      path,
      kind: "safety-test-no-negative",
      detail: "changed safety test without an added negative-case assert",
    });
  }
}

const summary = [
  "## Weakened-test heuristic",
  "",
  `Base: \`${base}\``,
  "",
  findings.length === 0
    ? "No weakened-test signals."
    : findings.map((f) => `- **${f.kind}** \`${f.path}\`: ${f.detail}`).join("\n"),
  "",
].join("\n");

if (process.env.GITHUB_STEP_SUMMARY) {
  writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
}
console.log(summary);

if (findings.length > 0) {
  console.error("::error::Weakened-test heuristic failed — see job summary");
  process.exit(1);
}
console.log("weakened-test: ok");
