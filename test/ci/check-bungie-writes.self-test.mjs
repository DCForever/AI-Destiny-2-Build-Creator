#!/usr/bin/env node
/** Regression fixtures for scripts/ci/check-bungie-writes.mjs */
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  BANNED_INSERT,
  findViolationsInText,
  isScannedDartPath,
  scanBungieWrites,
} from "../../scripts/ci/check-bungie-writes.mjs";

function ok(name, fn) {
  fn();
  console.log(`PASS ${name}`);
}

ok("InsertSocketPlugFree allowed", () => {
  if (findViolationsInText("insertSocketPlugFree(InsertSocketPlugFreeArgs());").length) {
    throw new Error("Free must be allowed");
  }
});

ok("paid InsertSocketPlug banned", () => {
  const f = findViolationsInText("'/Destiny2/Actions/Items/InsertSocketPlug/'");
  if (!f.some((x) => x.rule === "InsertSocketPlug-not-Free")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("paid endpoint without Free banned", () => {
  const f = findViolationsInText("postJson('Actions/Items/InsertSocketPlug/', body);");
  if (!f.some((x) => x.rule === "paid-InsertSocketPlug-endpoint")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("lowercase insertsocketplug banned", () => {
  const f = findViolationsInText("await insertsocketplug(ctx, args);");
  if (!f.some((x) => x.rule === "InsertSocketPlug-not-Free")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("dismantleItem banned", () => {
  const f = findViolationsInText("client.dismantleItem();");
  if (!f.some((x) => x.rule === "dismantle-or-DeleteItem")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("DeleteItem endpoint banned", () => {
  const f = findViolationsInText("'/Destiny2/Actions/Items/DeleteItem/'");
  if (!f.some((x) => x.rule === "dismantle-or-DeleteItem")) {
    throw new Error(JSON.stringify(f));
  }
});

ok("prose Never dismantles not banned", () => {
  if (findViolationsInText("/// Never dismantles. EquipItems only.").length) {
    throw new Error("prose must not fail");
  }
});

ok("isScannedDartPath skips tests, includes apps lib", () => {
  if (isScannedDartPath("flutter/packages/app/test/foo_test.dart")) {
    throw new Error("test skipped");
  }
  if (!isScannedDartPath("flutter/packages/app/lib/src/equip/apply_sockets.dart")) {
    throw new Error("packages lib scanned");
  }
  if (!isScannedDartPath(
    "flutter/apps/windows_host/lib/builds_mock/builds_mock_apply.dart",
  )) {
    throw new Error("apps lib scanned");
  }
});

ok("negative lookahead keeps Free", () => {
  if (BANNED_INSERT.test("InsertSocketPlugFree")) throw new Error("Free matched");
  if (!BANNED_INSERT.test("InsertSocketPlug")) throw new Error("bare missed");
});

ok("apps/ file under flutter is scanned", () => {
  const root = mkdtempSync(join(tmpdir(), "bungie-writes-apps-"));
  const lib = join(root, "flutter", "apps", "windows_host", "lib");
  mkdirSync(lib, { recursive: true });
  writeFileSync(join(lib, "ok.dart"), "// InsertSocketPlugFree only\n");
  writeFileSync(join(lib, "bad.dart"), "await insertSocketPlug(ctx, a);\n");
  const { findings, scanned } = scanBungieWrites(root);
  if (scanned < 2) throw new Error(`expected apps scanned, got ${scanned}`);
  if (!findings.some((f) => f.path.endsWith("bad.dart"))) {
    throw new Error(JSON.stringify(findings));
  }
});

ok("empty flutter root fails closed (scanned=0)", () => {
  const root = mkdtempSync(join(tmpdir(), "bungie-writes-empty-"));
  mkdirSync(join(root, "flutter"), { recursive: true });
  const { scanned, findings } = scanBungieWrites(root);
  if (scanned !== 0) throw new Error(`expected 0 scanned, got ${scanned}`);
  if (findings.length) throw new Error("empty root must have no findings");
  // Entry script exits 1 when scanned === 0 (fail closed).
  if (!(scanned === 0)) throw new Error("empty-scan contract broken");
});

console.log("check-bungie-writes self-test: ok");
