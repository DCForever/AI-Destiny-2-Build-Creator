#!/usr/bin/env node
/**
 * Regression fixtures for scripts/ci/measure-size-risk-lib.mjs.
 * Under top-level test/ci/ (gate path → ci-runner; excluded from production size).
 */
import {
  DEST_DRIVE_RE,
  DELETE_API_RE,
  addedOrRemovedBodies,
  isCiGatePath,
  isExcludedFromProduction,
  measureSizeRisk,
  resolveBase,
  stripCiGateHunks,
} from "../../scripts/ci/measure-size-risk-lib.mjs";

function ok(name, fn) {
  fn();
  console.log(`PASS ${name}`);
}

ok("ci-runner on .github without runs-on", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\t.github/workflows/ci.yml",
    nameStatus: "M\t.github/workflows/ci.yml",
    prodPatch: "name: CI\n",
    testPatch: "",
    allPaths: [".github/workflows/ci.yml"],
  });
  if (!r.flags.includes("ci-runner")) throw new Error(JSON.stringify(r));
  if (!r.reviewRequired) throw new Error("expected REVIEW_REQUIRED");
});

ok("ci-runner on scripts/ci libs", () => {
  const r = measureSizeRisk({
    numstat: "10\t0\tscripts/ci/check-weakened-tests-lib.mjs",
    nameStatus: "A\tscripts/ci/check-weakened-tests-lib.mjs",
    prodPatch: "const SKIP = /skip: true/;\n",
    testPatch: "",
    allPaths: ["scripts/ci/check-weakened-tests-lib.mjs"],
  });
  if (!r.flags.includes("ci-runner")) throw new Error(JSON.stringify(r));
});

ok("ci-runner on test/ci self-tests (gate path)", () => {
  if (!isCiGatePath("test/ci/measure-size-risk.self-test.mjs")) {
    throw new Error("test/ci must be a ci gate path");
  }
  const r = measureSizeRisk({
    numstat: "1\t0\tlib/x.dart",
    nameStatus: "M\tlib/x.dart\nM\ttest/ci/measure-size-risk.self-test.mjs",
    prodPatch: "void f() {}",
    testPatch: "",
    allPaths: ["lib/x.dart", "test/ci/measure-size-risk.self-test.mjs"],
  });
  if (!r.flags.includes("ci-runner")) throw new Error(JSON.stringify(r));
});

ok("auth-secrets patterns", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tsrc/auth.ts",
    nameStatus: "M\tsrc/auth.ts",
    prodPatch: "const h = 'Bearer FAKE';\nrefresh_token storage\n",
    testPatch: "",
    allPaths: ["src/auth.ts"],
  });
  if (!r.flags.includes("auth-secrets")) throw new Error(JSON.stringify(r));
});

ok("network-bind includes HttpServer.bind", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tsrc/server.dart",
    nameStatus: "M\tsrc/server.dart",
    prodPatch: "await HttpServer.bind('127.0.0.1', 0);\n",
    testPatch: "",
    allPaths: ["src/server.dart"],
  });
  if (!r.flags.includes("network-bind")) throw new Error(JSON.stringify(r));
});

ok("dest-write covers Bungie write APIs", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tsrc/apply.dart",
    nameStatus: "M\tsrc/apply.dart",
    prodPatch: "client.equipItems(...); TransferItem; InsertSocketPlugFree\n",
    testPatch: "",
    allPaths: ["src/apply.dart"],
  });
  if (!r.flags.includes("dest-write")) throw new Error(JSON.stringify(r));
});

ok("dest-write matches quoted/raw/forward-slash D E Z drives", () => {
  const samples = [
    '"D:\\\\Rips"',
    '"E:\\\\Rips"',
    '"Z:\\\\Media"',
    'r"E:\\Rips"',
    '"E:/Rips"',
    'Directory("D:/RippedDiscs")',
    "'Z:/Media'",
  ];
  for (const s of samples) {
    if (!DEST_DRIVE_RE.test(s)) throw new Error(`DEST_DRIVE_RE missed: ${s}`);
    const r = measureSizeRisk({
      numstat: "1\t0\tsrc/path.dart",
      nameStatus: "M\tsrc/path.dart",
      prodPatch: `final p = ${s};\n`,
      testPatch: "",
      allPaths: ["src/path.dart"],
    });
    if (!r.flags.includes("dest-write")) {
      throw new Error(`dest-write missed for ${s}: ${JSON.stringify(r)}`);
    }
  }
});

ok("deletes flag matches .delete / .deleteSync / .rename / .renameSync", () => {
  const samples = [
    "await file.delete();",
    "file.deleteSync();",
    "await file.rename(other);",
    "file.renameSync(other);",
  ];
  for (const s of samples) {
    if (!DELETE_API_RE.test(s)) throw new Error(`DELETE_API_RE missed: ${s}`);
    const r = measureSizeRisk({
      numstat: "1\t0\tsrc/io.dart",
      nameStatus: "M\tsrc/io.dart",
      prodPatch: `${s}\n`,
      testPatch: "",
      allPaths: ["src/io.dart"],
    });
    if (!r.flags.includes("deletes")) {
      throw new Error(`deletes missed for ${s}: ${JSON.stringify(r)}`);
    }
  }
});

ok("Large or any flag sets reviewRequired", () => {
  const large = measureSizeRisk({
    numstat: "400\t0\tlib/big.dart",
    nameStatus: "A\tlib/big.dart",
    prodPatch: "x\n",
    testPatch: "",
    allPaths: ["lib/big.dart"],
  });
  if (large.size !== "Large" || !large.reviewRequired) {
    throw new Error(JSON.stringify(large));
  }
});

ok("test-weakening scans +/- lines only (not context)", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tlib/x.dart",
    nameStatus: "M\tlib/x.dart\nM\ttest/a_test.dart",
    prodPatch: "void f() {}",
    testPatch: [
      "diff --git a/test/a_test.dart b/test/a_test.dart",
      "--- a/test/a_test.dart",
      "+++ b/test/a_test.dart",
      "@@ -1,3 +1,3 @@",
      " expect(find.byType(X), findsOneWidget);",
      "-const a = 1;",
      "+const a = 2;",
      " // context still has findsWidgets nearby in real files sometimes",
    ].join("\n"),
    allPaths: ["lib/x.dart", "test/a_test.dart"],
  });
  if (r.flags.includes("test-weakening")) {
    throw new Error(`context-only must not flag: ${JSON.stringify(r)}`);
  }
});

ok("test-weakening detects findsOneWidget→findsWidgets on +/- lines", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tlib/x.dart",
    nameStatus: "M\tlib/x.dart\nM\ttest/a_test.dart",
    prodPatch: "void f() {}",
    testPatch:
      "-expect(find.byType(X), findsOneWidget);\n+expect(find.byType(X), findsWidgets);\n",
    allPaths: ["lib/x.dart", "test/a_test.dart"],
  });
  if (!r.flags.includes("test-weakening")) throw new Error(JSON.stringify(r));
});

ok("ci-gate hunks stripped from weakening scan", () => {
  const patch = [
    "diff --git a/scripts/ci/measure-size-risk-lib.mjs b/scripts/ci/measure-size-risk-lib.mjs",
    "--- a/scripts/ci/measure-size-risk-lib.mjs",
    "+++ b/scripts/ci/measure-size-risk-lib.mjs",
    "@@ -1 +1 @@",
    "-old",
    "+skip: true findsOneWidget findsWidgets == >=",
  ].join("\n");
  const stripped = stripCiGateHunks(patch);
  if (stripped.includes("skip: true")) throw new Error("gate hunk not stripped");
  const bodies = addedOrRemovedBodies(stripped);
  if (bodies.includes("skip: true")) throw new Error("bodies still have skip");
});

ok("nested paths must not hide production", () => {
  if (isExcludedFromProduction("flutter/packages/app/README.md")) {
    throw new Error("nested README should count as production for size");
  }
  if (!isExcludedFromProduction("docs/README.md")) {
    throw new Error("docs/README.md should be excluded");
  }
  if (isExcludedFromProduction("packages/foo/fixtures/loader.dart")) {
    throw new Error("nested fixtures must not hide production");
  }
  if (isExcludedFromProduction("flutter/packages/app/docs/note.md")) {
    throw new Error("nested docs/ must not hide production");
  }
  if (isExcludedFromProduction("flutter/packages/app/test/helpers/util.dart")) {
    throw new Error("nested test/ helper without _test suffix must not hide production");
  }
  if (!isExcludedFromProduction("flutter/packages/app/test/foo_test.dart")) {
    throw new Error("named *_test.dart should still be excluded");
  }
});

ok("missing base fails closed", () => {
  let threw = false;
  try {
    resolveBase("refs/does-not-exist-size-risk");
  } catch {
    threw = true;
  }
  if (!threw) throw new Error("expected throw");
});

console.log("size-risk self-test: ok");
