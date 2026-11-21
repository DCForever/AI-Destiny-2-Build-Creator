#!/usr/bin/env node
/**
 * Fail when a PR weakens safety tests. Fail closed on a missing base ref.
 * Detection only — no secrets. Use --self-test for regression fixtures.
 */
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

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

const ASSERT_RE =
  /\b(expectLater|expect|verify|assert\w*)\s*\(/;
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

function hasSkipWeakening(line) {
  return SKIP_FLAG_RE.test(stripComments(line));
}

function hasNegativeAssert(line) {
  return NEGATIVE_ASSERT_RE.test(stripComments(line));
}

function detectLoosening(removed, added) {
  const tips = [];
  const rm = stripComments(removed);
  const ad = stripComments(added);
  // Spaced and compact == / equals → >= / greaterThanOrEqualTo
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
        st.rm += 1; // treat rename-out of test as assert loss / deletion
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
      if (hasSkipWeakening(body)) st.skipWeak = true;
      if (hasNegativeAssert(body)) st.neg = true;
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

function runSelfTest() {
  const cases = [];
  const ok = (name, fn) => {
    try {
      fn();
      cases.push(`PASS ${name}`);
    } catch (e) {
      cases.push(`FAIL ${name}: ${e.message}`);
      throw e;
    }
  };

  ok("spaced == to >= detected", () => {
    const diff = [
      "diff --git a/test/a_test.dart b/test/a_test.dart",
      "--- a/test/a_test.dart",
      "+++ b/test/a_test.dart",
      "@@ -1 +1 @@",
      "-expect(a == b, isTrue);",
      "+expect(a >= b, isTrue);",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.kind === "loosened-matcher" && x.detail === "eq-to-gte")) {
      throw new Error(JSON.stringify(f));
    }
  });

  ok("equals → greaterThanOrEqualTo detected", () => {
    const diff = [
      "diff --git a/test/a_test.dart b/test/a_test.dart",
      "--- a/test/a_test.dart",
      "+++ b/test/a_test.dart",
      "@@ -1 +1 @@",
      "-expect(x, equals(1));",
      "+expect(x, greaterThanOrEqualTo(1));",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.detail === "eq-to-gte")) throw new Error(JSON.stringify(f));
  });

  ok("commented expect does not count as added assert", () => {
    const diff = [
      "diff --git a/test/a_test.dart b/test/a_test.dart",
      "--- a/test/a_test.dart",
      "+++ b/test/a_test.dart",
      "@@ -1 +1,2 @@",
      "-expect(x, 1);",
      "+// expect(x, 1);",
      "+final y = 1;",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.kind === "dropped-asserts")) {
      throw new Error(`expected dropped-asserts, got ${JSON.stringify(f)}`);
    }
  });

  ok("skip:true flags weakening; bare skip word is not a negative", () => {
    const diff = [
      "diff --git a/test/skeptic_guard_test.dart b/test/skeptic_guard_test.dart",
      "--- a/test/skeptic_guard_test.dart",
      "+++ b/test/skeptic_guard_test.dart",
      "@@ -1 +1,2 @@",
      "-expect(x, isFalse);",
      "+test('x', () {}, skip: true);",
      "+// skip this refuse path",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.kind === "test-weakening")) throw new Error(JSON.stringify(f));
    if (!f.some((x) => x.kind === "safety-test-no-negative")) {
      throw new Error(`expected safety-test-no-negative: ${JSON.stringify(f)}`);
    }
  });

  ok("expectLater and verify count as asserts", () => {
    const diff = [
      "diff --git a/test/a_test.dart b/test/a_test.dart",
      "--- a/test/a_test.dart",
      "+++ b/test/a_test.dart",
      "@@ -1 +1 @@",
      "-expectLater(f(), throwsA(anything));",
      "-verify(() => c.x()).called(1);",
      "+final x = 1;",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.kind === "dropped-asserts" && x.detail.includes("rm 2"))) {
      throw new Error(JSON.stringify(f));
    }
  });

  ok("web .test.ts and __tests__ scanned", () => {
    const diff = [
      "diff --git a/web/NextJS/src/foo.test.ts b/web/NextJS/src/foo.test.ts",
      "--- a/web/NextJS/src/foo.test.ts",
      "+++ b/web/NextJS/src/foo.test.ts",
      "@@ -1 +1 @@",
      "-expect(1).toBe(1);",
      "+const x = 1;",
      "diff --git a/web/NextJS/__tests__/bar.ts b/web/NextJS/__tests__/bar.ts",
      "--- a/web/NextJS/__tests__/bar.ts",
      "+++ b/web/NextJS/__tests__/bar.ts",
      "@@ -1 +1 @@",
      "-expect(2).toBe(2);",
      "+const y = 2;",
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (f.filter((x) => x.kind === "dropped-asserts").length < 2) {
      throw new Error(JSON.stringify(f));
    }
  });

  ok("rename test→non-test treated as deletion", () => {
    const f = analyzeWeakenedDiff("", [
      "R100\ttest/old_test.dart\tlib/old.dart",
    ]);
    if (!f.some((x) => x.detail === "test-path-renamed-away")) {
      throw new Error(JSON.stringify(f));
    }
  });

  ok("missing base fails closed", () => {
    let threw = false;
    try {
      resolveBase("refs/does-not-exist-skeptic-base");
    } catch {
      threw = true;
    }
    if (!threw) throw new Error("expected throw");
  });

  console.log(cases.join("\n"));
  console.log("weakened-test self-test: ok");
}

function main() {
  if (process.argv.includes("--self-test")) {
    runSelfTest();
    return;
  }
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

main();
