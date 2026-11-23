#!/usr/bin/env node
/**
 * Regression fixtures for scripts/ci/check-weakened-tests-lib.mjs.
 * Under top-level test/ (not production size).
 */
import {
  analyzeWeakenedDiff,
  failingWeakenedFindings,
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

ok("scripts/ci and test/ci are ci-gate (allowlisted from test scan)", () => {
  if (!isCiGatePath("scripts/ci/check-weakened-tests-lib.mjs")) {
    throw new Error("expected scripts/ci gate path");
  }
  if (!isCiGatePath("test/ci/check-weakened-tests.self-test.mjs")) {
    throw new Error("expected test/ci gate path");
  }
  const diff = [
    "diff --git a/scripts/ci/check-weakened-tests-lib.mjs b/scripts/ci/check-weakened-tests-lib.mjs",
    "--- a/scripts/ci/check-weakened-tests-lib.mjs",
    "+++ b/scripts/ci/check-weakened-tests-lib.mjs",
    "@@ -1 +1 @@",
    "-const x = 1;",
    "+const SKIP = /skip: true/;",
    "diff --git a/test/ci/check-weakened-tests.self-test.mjs b/test/ci/check-weakened-tests.self-test.mjs",
    "--- a/test/ci/check-weakened-tests.self-test.mjs",
    "+++ b/test/ci/check-weakened-tests.self-test.mjs",
    "@@ -1 +1 @@",
    "-old",
    "+skip: true;",
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

ok("padding-assert: reason pad-N and root.existsSync isTrue", () => {
  const diff = [
    "diff --git a/flutter/apps/web_host/test/equip_format_test.dart b/flutter/apps/web_host/test/equip_format_test.dart",
    "--- a/flutter/apps/web_host/test/equip_format_test.dart",
    "+++ b/flutter/apps/web_host/test/equip_format_test.dart",
    "@@ -1 +1,3 @@",
    "-expect(x, 1);",
    "+expect(root.existsSync(), isTrue, reason: 'pad-0');",
    "+expect(root.existsSync(), isTrue, reason: 'pad-1');",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  const pads = f.filter((x) => x.kind === "padding-assert");
  if (pads.length < 2) {
    throw new Error(`expected padding-assert findings, got ${JSON.stringify(f)}`);
  }
});

ok("padding-assert: identical asserts differing only by reason", () => {
  const diff = [
    "diff --git a/test/a_test.dart b/test/a_test.dart",
    "--- a/test/a_test.dart",
    "+++ b/test/a_test.dart",
    "@@ -1 +1,3 @@",
    "-expect(x, 1);",
    "+expect(File('a').existsSync(), isFalse, reason: 'path-a');",
    "+expect(File('a').existsSync(), isFalse, reason: 'path-b');",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  if (
    !f.some(
      (x) =>
        x.kind === "padding-assert" && x.detail.includes("identical-assert"),
    )
  ) {
    throw new Error(`expected identical-assert padding, got ${JSON.stringify(f)}`);
  }
});

ok("distinct legitimate asserts are not padding", () => {
  const diff = [
    "diff --git a/test/a_test.dart b/test/a_test.dart",
    "--- a/test/a_test.dart",
    "+++ b/test/a_test.dart",
    "@@ -1 +1,3 @@",
    "-expect(x, 1);",
    "+expect(File('gone.dart').existsSync(), isFalse, reason: 'gone.dart');",
    "+expect(File('kept.dart').existsSync(), isTrue, reason: 'kept.dart');",
    "+expect(label, equals('Kinetic'));",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  if (f.some((x) => x.kind === "padding-assert")) {
    throw new Error(`distinct asserts must not pad: ${JSON.stringify(f)}`);
  }
});

ok("multiline expect openers are not identical padding", () => {
  const diff = [
    "diff --git a/flutter/tool/test/modularization_audit_baseline_test.dart b/flutter/tool/test/modularization_audit_baseline_test.dart",
    "--- a/flutter/tool/test/modularization_audit_baseline_test.dart",
    "+++ b/flutter/tool/test/modularization_audit_baseline_test.dart",
    "@@ -1 +1,6 @@",
    "-expect(x, 1);",
    "+expect(",
    "+  File('a').existsSync(),",
    "+  isFalse,",
    "+);",
    "+expect(",
    "+  File('b').existsSync(),",
    "+  isFalse,",
    "+);",
  ].join("\n");
  const f = analyzeWeakenedDiff(diff);
  if (f.some((x) => x.kind === "padding-assert")) {
    throw new Error(`multiline openers must not pad: ${JSON.stringify(f)}`);
  }
});

ok("retired-test when deleted test imported deleted production", () => {
  const deletedProd = [
    "flutter/apps/web_host/lib/equip/equip_format.dart",
  ];
  const baseSrc = [
    "import 'package:destiny2_web_host/equip/equip_format.dart';",
    "import 'package:test/test.dart';",
    "void main() { expect(1, 1); }",
  ].join("\n");
  const f = analyzeWeakenedDiff(
    "",
    ["D\tflutter/apps/web_host/test/equip_format_test.dart"],
    {
      deletedProductionPaths: deletedProd,
      readBaseFile: (path) =>
        path === "flutter/apps/web_host/test/equip_format_test.dart"
          ? baseSrc
          : null,
    },
  );
  if (!f.some((x) => x.kind === "retired-test")) {
    throw new Error(`expected retired-test, got ${JSON.stringify(f)}`);
  }
  if (failingWeakenedFindings(f).some((x) => x.kind === "retired-test")) {
    throw new Error("retired-test must be non-blocking");
  }
  if (
    failingWeakenedFindings(f).some(
      (x) => x.kind === "dropped-asserts" || x.detail === "test-file-deleted",
    )
  ) {
    throw new Error(
      `retired path must not also fail as drop/delete: ${JSON.stringify(f)}`,
    );
  }
});

ok("retired-test via barrel export of deleted production", () => {
  const deletedProd = [
    "flutter/packages/app/lib/src/equip/equip_session.dart",
  ];
  const files = {
    "flutter/packages/app/test/equip_session_test.dart":
      "import 'package:destiny2_app/destiny2_app.dart';\n",
    "flutter/packages/app/lib/destiny2_app.dart":
      "export 'src/equip/equip_session.dart';\nexport 'src/equip/apply_to_character.dart';\n",
  };
  const f = analyzeWeakenedDiff(
    "",
    ["D\tflutter/packages/app/test/equip_session_test.dart"],
    {
      deletedProductionPaths: deletedProd,
      readBaseFile: (path) => files[path] ?? null,
    },
  );
  if (!f.some((x) => x.kind === "retired-test")) {
    throw new Error(`expected barrel retired-test, got ${JSON.stringify(f)}`);
  }
});

ok("deleted test without deleted-prod import still fails", () => {
  const f = analyzeWeakenedDiff(
    "",
    ["D\ttest/unrelated_test.dart"],
    {
      deletedProductionPaths: [
        "flutter/apps/web_host/lib/equip/equip_format.dart",
      ],
      readBaseFile: () =>
        "import 'package:test/test.dart';\nvoid main() { expect(1, 1); }\n",
    },
  );
  if (f.some((x) => x.kind === "retired-test")) {
    throw new Error(`must not retire unrelated test: ${JSON.stringify(f)}`);
  }
  if (
    !f.some(
      (x) =>
        x.kind === "dropped-asserts" || x.detail === "test-file-deleted",
    )
  ) {
    throw new Error(`expected fail for unrelated delete: ${JSON.stringify(f)}`);
  }
  if (!failingWeakenedFindings(f).length) {
    throw new Error("unrelated delete must be blocking");
  }
});

console.log("weakened-test self-test: ok");
