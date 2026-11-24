#!/usr/bin/env node
/** Regression fixtures for scripts/ci/check-bungie-writes.mjs */
import {
  BANNED_INSERT,
  findViolationsInText,
  isScannedDartPath,
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
  if (!f.some((x) => x.rule === "InsertSocketPlug-not-Free")) throw new Error(JSON.stringify(f));
});

ok("insertSocketPlug method banned", () => {
  const f = findViolationsInText("await insertSocketPlug(ctx, args);");
  if (!f.some((x) => x.rule === "insertSocketPlug-not-Free")) throw new Error(JSON.stringify(f));
});

ok("dismantleItem banned", () => {
  const f = findViolationsInText("client.dismantleItem();");
  if (!f.some((x) => x.rule === "dismantle-or-DeleteItem")) throw new Error(JSON.stringify(f));
});

ok("DeleteItem endpoint banned", () => {
  const f = findViolationsInText("'/Destiny2/Actions/Items/DeleteItem/'");
  if (!f.some((x) => x.rule === "dismantle-or-DeleteItem")) throw new Error(JSON.stringify(f));
});

ok("prose Never dismantles not banned", () => {
  if (findViolationsInText("/// Never dismantles. EquipItems only.").length) {
    throw new Error("prose must not fail");
  }
});

ok("isScannedDartPath skips tests", () => {
  if (isScannedDartPath("flutter/packages/app/test/foo_test.dart")) {
    throw new Error("test skipped");
  }
  if (!isScannedDartPath("flutter/packages/app/lib/src/equip/apply_sockets.dart")) {
    throw new Error("lib scanned");
  }
});

ok("negative lookahead keeps Free", () => {
  if (BANNED_INSERT.test("InsertSocketPlugFree")) throw new Error("Free matched");
  if (!BANNED_INSERT.test("InsertSocketPlug")) throw new Error("bare missed");
});

console.log("check-bungie-writes self-test: ok");
