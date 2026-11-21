#!/usr/bin/env node
/**
 * Fail when a PR weakens safety tests. Fail closed on a missing base ref.
 * Detection only — no secrets. Self-tests live in test/ci/ (excluded from size).
 */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

/** Strip line and block comments so commented expects do not count. */
export function stripComments(src) {
  let out = "";
  let i = 0;
  while (i < src.length) {
    if (src[i] === "/" && src[i + 1] === "/") {
      i += 2;
      while (i < src.length && src[i] !== "\n") i += 1;
      continue;
    }
    if (src[i] === "/" && src[i + 1] === "*") {
      i += 2;
      while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i += 1;
      i += 2;
      continue;
    }
    out += src[i++];
  }
  return out;
}

const ASSERT_RE = /\b(expectLater|expect|verify|assert\w*)\s*\(/;
const SKIP_FLAG_RE = /\bskip\s*:\s*true\b/;
const NEGATIVE_ASSERT_RE =
  /\b(expectLater|expect|verify|assert\w*)\s*\([\s\S]{0,200}?\b(isFalse|isEmpty|throwsA|throws|refuse|ReadFailed|instanceNotOwned|doesNotFit|EnergyCostUnknown|notUnlocked|failClosed|isNull)\b/i;

export function isTestPath(path) {
  if (!path) return false;
  if (/(^|\/)__tests__\//.test(path)) return true;
  if (/(^|\/)test(s)?\//.test(path)) return true;
  if (/_test\.(dart|ts|tsx|js|mjs|py|go)$/i.test(path)) return true;
  if (/\.test\.(ts|tsx|js|mjs)$/i.test(path)) return true;
  return false;
}

export function resolveBase(preferred) {
  const sh = (c) => execSync(c, { encoding: "utf8" }).trim();
  try {
    sh(`git rev-parse --verify ${preferred}`);
    return preferred;
  } catch {
    throw new Error(
      `Base ref missing or unresolvable: ${preferred} (fail closed; no HEAD~1 fallback)`,
    );
  }
}

function countAsserts(line) {
  const clean = stripComments(line);
  const re = new RegExp(ASSERT_RE.source, "g");
  let n = 0;
  while (re.exec(clean)) n += 1;
  return n;
}

function detectLoosening(removed, added) {
  const tips = [];
  const rm = stripComments(removed);
  const ad = stripComments(added);
  if (
    /(?:==|equals\s*\()/.test(rm) &&
    !/(?:>=|greaterThanOrEqualTo)/.test(rm) &&
    /(?:>=|greaterThanOrEqualTo)/.test(ad)
  ) {
    tips.push("eq-to-gte");
  }
  if (/\bfindsOneWidget\b/.test(rm) && /\bfindsWidgets\b/.test(ad)) {
    tips.push("one-to-widgets");
  }
  if (/\bfindsNothing\b/.test(rm) && /\bfindsWidgets\b/.test(ad)) {
    tips.push("nothing-to-widgets");
  }
  return tips;
}

/**
 * @param {string} diff unified diff text
 * @param {string[]} [nameStatusLines] optional `git diff --name-status` lines
 */
export function analyzeWeakenedDiff(diff, nameStatusLines = []) {
  const safety =
    /(skeptic_|fail_closed|ownership|guard|undo|apply_socket|cache_write|path_guard|no_dismantle)/i;
  const files = new Map();
  const state = (p) => {
    if (!files.has(p)) {
      files.set(p, {
        rm: 0,
        add: 0,
        loose: [],
        neg: false,
        skipWeak: false,
        hit: false,
      });
    }
    return files.get(p);
  };

  for (const line of nameStatusLines) {
    if (!line.trim()) continue;
    const [status, ...rest] = line.split("\t");
    if (status.startsWith("R") && rest.length >= 2) {
      const [from, to] = rest;
      if (isTestPath(from) && !isTestPath(to)) {
        const st = state(from);
        st.hit = true;
        st.rm += 1;
        st.loose.push("test-path-renamed-away");
      }
    }
    if (status.startsWith("D")) {
      const path = rest[rest.length - 1];
      if (isTestPath(path)) {
        const st = state(path);
        st.hit = true;
        st.rm += 1;
        st.loose.push("test-file-deleted");
      }
    }
  }

  let cur = null;
  const lines = diff.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const m = line.match(/^diff --git a\/(.+) b\/(.+)$/);
    if (m) {
      cur = m[2];
      continue;
    }
    if (!cur || !isTestPath(cur)) continue;
    const st = state(cur);
    st.hit = true;
    if (line.startsWith("-") && !line.startsWith("---")) {
      st.rm += countAsserts(line.slice(1));
    }
    if (line.startsWith("+") && !line.startsWith("+++")) {
      const body = line.slice(1);
      st.add += countAsserts(body);
      if (SKIP_FLAG_RE.test(stripComments(body))) st.skipWeak = true;
      if (NEGATIVE_ASSERT_RE.test(stripComments(body))) st.neg = true;
    }
    if (line.startsWith("-") && !line.startsWith("---")) {
      const next = lines[i + 1] || "";
      if (!next.startsWith("+") || next.startsWith("+++")) continue;
      for (const tip of detectLoosening(line.slice(1), next.slice(1))) {
        st.loose.push(tip);
      }
    }
  }

  const findings = [];
  for (const [path, st] of files) {
    if (!st.hit) continue;
    if (st.rm > 0 && st.add - st.rm < 0) {
      findings.push({
        path,
        kind: "dropped-asserts",
        detail: `rm ${st.rm} add ${st.add}`,
      });
    }
    for (const tip of st.loose) {
      findings.push({ path, kind: "loosened-matcher", detail: tip });
    }
    if (st.skipWeak) {
      findings.push({
        path,
        kind: "test-weakening",
        detail: "added skip: true",
      });
    }
    if (safety.test(path) && st.hit && st.rm > 0 && !st.neg) {
      findings.push({
        path,
        kind: "safety-test-no-negative",
        detail: "changed safety test without a negative-case assert",
      });
    }
  }
  return findings;
}

function main() {
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
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
