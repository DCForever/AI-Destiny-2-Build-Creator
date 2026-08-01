#!/usr/bin/env node
/**
 * Platform parity report: flutter-windows vs nextjs production surfaces.
 * Exit 0 by default; PRODUCT_MAP_PARITY_STRICT=1 fails if stubs missing for priority screens.
 */
import fs from "node:fs";
import path from "node:path";
import { loadHub } from "./lib/load-hub.mjs";
import { REPO_ROOT } from "./lib/paths.mjs";

const strict = process.env.PRODUCT_MAP_PARITY_STRICT === "1";
const platform = process.argv.find((a) => a.startsWith("--platform="))?.split("=")[1] ||
  "flutter-windows";

function shotExists(plat, captureId, layout, shotsDir) {
  if (!captureId) return false;
  const abs = path.isAbsolute(shotsDir)
    ? shotsDir
    : path.join(REPO_ROOT, shotsDir);
  if (!fs.existsSync(abs)) return false;
  if (layout === "nested") {
    // {captureId}__signed-in.png or {captureId}.png under nested dir
    const files = fs.readdirSync(abs);
    return files.some(
      (f) =>
        f === `${captureId}.png` ||
        f.startsWith(`${captureId}__`) && f.endsWith(".png"),
    );
  }
  // flat nextjs layout
  const flat = path.join(REPO_ROOT, "docs/atlas/screenshots");
  if (!fs.existsSync(flat)) return false;
  return fs
    .readdirSync(flat)
    .some(
      (f) =>
        f === `${captureId}.png` ||
        (f.startsWith(`${captureId}__`) && f.endsWith(".png")),
    );
}

function main() {
  const hub = loadHub();
  const platMeta = hub.platforms[platform];
  if (!platMeta) {
    console.error(`Unknown platform: ${platform}`);
    process.exit(1);
  }

  /** @type {object[]} */
  const rows = [];
  let stub = 0;
  let deferred = 0;
  let missing = 0;
  let withShot = 0;
  let withRules = 0;

  for (const s of hub.surfaces) {
    const nx = s.platforms?.nextjs;
    const fw = s.platforms?.[platform];
    if (!nx && !fw) continue;
    if (!nx?.path && !nx?.captureId && !["screen", "subscreen", "gate"].includes(s.kind)) {
      continue;
    }

    const status = fw?.status || (fw ? "present" : "missing");
    if (status === "deferred") deferred++;
    else if (status === "stub" || status === "planned") stub++;
    else if (!fw) missing++;

    const captureId = fw?.captureId || nx?.captureId;
    const hasShot = shotExists(
      platform,
      captureId,
      platMeta.screenshotsLayout,
      platMeta.screenshotsDir || "docs/atlas/screenshots",
    );
    if (hasShot) withShot++;
    if ((s.rules || []).length) withRules++;

    if (!fw || status === "missing" || status === "stub") {
      rows.push({
        id: s.id,
        kind: s.kind,
        area: s.area,
        status: status === "present" ? "ok" : status,
        nextjsPath: nx?.path || "",
        flutterRoute: fw?.route || "",
        captureId: captureId || "",
        hasShot,
        rules: (s.rules || []).length,
      });
    }
  }

  console.log(`product-map:parity — platform=${platform} status=${platMeta.status}`);
  console.log(
    `  stubs=${stub} deferred=${deferred} missing-slot=${missing} captures-present=${withShot}`,
  );
  console.log(`  surfaces with rules attached (in report set): ${withRules}`);

  const needAttention = rows.filter((r) => r.status === "missing" || r.status === "stub");
  console.log(`  needing attention (missing/stub): ${needAttention.length}`);
  for (const r of needAttention.slice(0, 40)) {
    console.log(
      `  - [${r.status}] ${r.id} route=${r.flutterRoute || "—"} capture=${r.captureId || "—"} shot=${r.hasShot} rules=${r.rules}`,
    );
  }
  if (needAttention.length > 40) {
    console.log(`  …and ${needAttention.length - 40} more`);
  }

  // Write markdown report
  const reportPath = path.join(
    REPO_ROOT,
    "docs/product-map",
    `parity-${platform}.md`,
  );
  const md = [
    `# Parity: ${platform}`,
    "",
    `Generated: ${new Date().toISOString().slice(0, 10)}`,
    "",
    `| Metric | Value |`,
    `|--------|-------|`,
    `| Platform status | ${platMeta.status} |`,
    `| Stubs | ${stub} |`,
    `| Deferred | ${deferred} |`,
    `| Missing platform block | ${missing} |`,
    `| Captures on disk | ${withShot} |`,
    "",
    "## Same rules, different shell",
    "",
    "DBR/DAC/BR IDs are shared. Do not create Flutter-only domain rules.",
    "",
    "## Surfaces (stub or missing)",
    "",
    "| Surface | Status | Flutter route | Capture id | Shot | Rules |",
    "|---------|--------|---------------|------------|------|-------|",
    ...needAttention.map(
      (r) =>
        `| \`${r.id}\` | ${r.status} | ${r.flutterRoute || "—"} | ${r.captureId || "—"} | ${r.hasShot ? "yes" : "no"} | ${r.rules} |`,
    ),
    "",
    "## Checklist",
    "",
    "- [ ] Flutter Windows shell routes match `platforms.flutter-windows.route`",
    "- [ ] Hard/soft guidance parity tests (domain package)",
    "- [ ] Capture stubs filled as screens land (`npm run atlas:capture:flutter-windows` when available)",
    "- [ ] No DBR/DAC forks for Flutter",
    "",
  ].join("\n");
  fs.writeFileSync(reportPath, md, "utf8");
  console.log(`Wrote ${reportPath}`);

  if (strict && missing > 0) {
    console.error("Strict parity: missing platform blocks");
    process.exit(1);
  }
}

main();
