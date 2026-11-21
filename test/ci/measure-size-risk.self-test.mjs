#!/usr/bin/env node
/**
 * Regression fixtures for scripts/ci/measure-size-risk.mjs (fail-closed).
 * Lives under top-level test/ so it does not count toward production size.
 */
import {
  isExcludedFromProduction,
  measureSizeRisk,
  resolveBase,
} from "../../scripts/ci/measure-size-risk.mjs";

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
});

ok("ci-runner on scripts/ci", () => {
  const r = measureSizeRisk({
    numstat: "1\t0\tscripts/ci/x.mjs",
    nameStatus: "A\tscripts/ci/x.mjs",
    prodPatch: "",
    testPatch: "",
    allPaths: ["scripts/ci/x.mjs"],
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

ok("test-weakening scans test paths", () => {
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
