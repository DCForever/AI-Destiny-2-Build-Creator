#!/usr/bin/env node
/** Fail when a PR weakens safety tests (dropped asserts, loosened matchers,
 *  safety-test change with no negative case). Read-only git. No secrets. */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const preferred = process.argv[2] || process.env.BASE_REF || "origin/main";
const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
const base = [preferred, "origin/main", "main", "HEAD~1"].find((r) => {
  try { sh(`git rev-parse --verify ${r}`); return true; } catch { return false; }
});
if (!base) throw new Error("no base ref");

const diff = sh(`git diff --unified=0 ${base}...HEAD`);
const safety = /(skeptic_|fail_closed|ownership|guard|undo|apply_socket|cache_write|path_guard|no_dismantle)/i;
const files = new Map();
const state = (p) => {
  if (!files.has(p)) files.set(p, { rm: 0, add: 0, loose: [], neg: false, hit: false });
  return files.get(p);
};

let cur = null;
const lines = diff.split("\n");
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  const m = line.match(/^diff --git a\/.+ b\/(.+)$/);
  if (m) { cur = m[1]; continue; }
  if (!cur) continue;
  if (!/(^|\/)test(s)?\//.test(cur) && !/_test\.(dart|ts|tsx|js|mjs)$/.test(cur)) continue;
  const st = state(cur); st.hit = true;
  if (line.startsWith("-") && !line.startsWith("---")) {
    const b = line.slice(1);
    if (/\bexpect\s*\(/.test(b) || /\bassert\w*\s*\(/.test(b)) st.rm += 1;
  }
  if (line.startsWith("+") && !line.startsWith("+++")) {
    const b = line.slice(1);
    if (/\bexpect\s*\(/.test(b) || /\bassert\w*\s*\(/.test(b)) st.add += 1;
    if (/(refuse|fail|skip|throw|isFalse|isEmpty|notUnlocked|ReadFailed|instanceNotOwned|doesNotFit|EnergyCostUnknown)/i.test(b)) {
      st.neg = true;
    }
  }
  if (line.startsWith("-") && !line.startsWith("---")) {
    const next = lines[i + 1] || "";
    if (!next.startsWith("+") || next.startsWith("+++")) continue;
    const rm = line.slice(1); const ad = next.slice(1);
    if (/\b==\b/.test(rm) && />=/.test(ad) && !/>=/.test(rm)) st.loose.push("eq-to-gte");
    if (/\bfindsOneWidget\b/.test(rm) && /\bfindsWidgets\b/.test(ad)) st.loose.push("one-to-widgets");
  }
}

const findings = [];
for (const [path, st] of files) {
  if (!st.hit) continue;
  if (st.rm > 0 && st.add - st.rm < 0) {
    findings.push({ path, kind: "dropped-asserts", detail: `rm ${st.rm} add ${st.add}` });
  }
  for (const tip of st.loose) findings.push({ path, kind: "loosened-matcher", detail: tip });
  if (safety.test(path) && st.rm > 0 && !st.neg) {
    findings.push({ path, kind: "safety-test-no-negative", detail: "no negative case added" });
  }
}

const summary = [
  "## Weakened-test heuristic",
  "",
  `Base: \`${base}\``,
  "",
  findings.length ? findings.map((f) => `- **${f.kind}** \`${f.path}\`: ${f.detail}`).join("\n") : "No weakened-test signals.",
  "",
].join("\n");
if (process.env.GITHUB_STEP_SUMMARY) writeFileSync(process.env.GITHUB_STEP_SUMMARY, summary, { flag: "a" });
console.log(summary);
if (findings.length) { console.error("::error::Weakened-test heuristic failed"); process.exit(1); }
console.log("weakened-test: ok");
