#!/usr/bin/env node
/**
 * Regression fixtures for scripts/ci/check-weakened-tests-lib.mjs.
 * Under top-level test/ (not production size).
 */
import {
  analyzeWeakenedDiff,
  isCiGatePath,
  resolveBase,
} from "../../scripts/ci/check-weakened-tests-lib.mjs";

function ok(name, fn) {
  fn();
  console.log(`PASS ${name}`);
}

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

ok("toEqual → toBeGreaterThanOrEqual detected", () => {
  const diff = [
    "diff --git a/web/foo.test.ts b/web/foo.test.ts",
    "--- a/web/foo.test.ts",
    "+++ b/web/foo.test.ts",
    "@@ -1 +1 @@",
    "-expect(x).toEqual(1);",
    "+expect(x).toBeGreaterThanOrEqual(1);",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  if (!f.some((x) => x.detail === "eq-to-gte")) throw new Error(JSON.stringify(f));
});

ok("loosening across non-adjacent hunk lines", () => {
  const diff = [
    "diff --git a/test/a_test.dart b/test/a_test.dart",
    "--- a/test/a_test.dart",
    "+++ b/test/a_test.dart",
    "@@ -1,3 +1,3 @@",
    "-expect(a == b, isTrue);",
    "-final pad = 1;",
    "+final pad = 1;",
    "+expect(a >= b, isTrue);",
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

ok("skip:true and skip:'reason' and @Skip and *.skip flag weakening", () => {
  const cases = [
    "test('x', () {}, skip: true);",
    "test('x', () {}, skip: 'temporarily broken');",
    "@Skip('reason')\ntest('x', () {});",
    "it.skip('x', () => {});",
    "test.skip('x', () => {});",
    "describe.skip('x', () => {});",
  ];
  for (const added of cases) {
    const diff = [
      "diff --git a/test/skeptic_guard_test.dart b/test/skeptic_guard_test.dart",
      "--- a/test/skeptic_guard_test.dart",
      "+++ b/test/skeptic_guard_test.dart",
      "@@ -1 +1 @@",
      "-expect(x, isFalse);",
      `+${added}`,
    ].join("\n");
    const f = analyzeWeakenedDiff(diff);
    if (!f.some((x) => x.kind === "test-weakening")) {
      throw new Error(`expected test-weakening for ${added}: ${JSON.stringify(f)}`);
    }
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
  const f = analyzeWeakenedDiff("", ["R100\ttest/old_test.dart\tlib/old.dart"]);
  if (!f.some((x) => x.detail === "test-path-renamed-away")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("scripts/ci pattern source is ci-gate (allowlisted from test scan)", () => {
  if (!isCiGatePath("scripts/ci/check-weakened-tests-lib.mjs")) {
    throw new Error("expected ci gate path");
  }
  const diff = [
    "diff --git a/scripts/ci/check-weakened-tests-lib.mjs b/scripts/ci/check-weakened-tests-lib.mjs",
    "--- a/scripts/ci/check-weakened-tests-lib.mjs",
    "+++ b/scripts/ci/check-weakened-tests-lib.mjs",
    "@@ -1 +1 @@",
    "-const x = 1;",
    "+const SKIP = /skip: true/;",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  if (f.length) throw new Error(`ci gate must not yield findings: ${JSON.stringify(f)}`);
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

console.log("weakened-test self-test: ok");
