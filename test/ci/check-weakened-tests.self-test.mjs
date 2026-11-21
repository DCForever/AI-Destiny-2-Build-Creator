#!/usr/bin/env node
/**
 * Regression fixtures for scripts/ci/check-weakened-tests.mjs (fail-closed).
 * Lives under top-level test/ so it does not count toward production size.
 */
import {
  analyzeWeakenedDiff,
  resolveBase,
} from "./lib/check-weakened-tests-lib.mjs";

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
  const f = analyzeWeakenedDiff("", ["R100\ttest/old_test.dart\tlib/old.dart"]);
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

console.log("weakened-test self-test: ok");
