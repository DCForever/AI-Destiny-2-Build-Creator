#!/usr/bin/env node
/**
 * Flutter (or other nested) capture pipeline stub.
 * Lists surfaces ready to capture; optionally writes placeholder sidecar JSON.
 *
 * Usage:
 *   node scripts/product-map/capture-stub.mjs --platform=flutter-windows
 *   node scripts/product-map/capture-stub.mjs --platform=flutter-windows --write-plan
 *
 * Real capture (future): Flutter integration_test / desktop driver writing
 *   docs/atlas/screenshots/flutter-windows/{captureId}__signed-in.png
 */
import fs from "node:fs";
import path from "node:path";
import { loadHub } from "./lib/load-hub.mjs";
import { REPO_ROOT } from "./lib/paths.mjs";

const platform =
  process.argv.find((a) => a.startsWith("--platform="))?.split("=")[1] ||
  "flutter-windows";
const writePlan = process.argv.includes("--write-plan");

function main() {
  const hub = loadHub();
  const meta = hub.platforms[platform];
  if (!meta) {
    console.error(`Unknown platform: ${platform}`);
    process.exit(1);
  }

  const dir = path.join(
    REPO_ROOT,
    meta.screenshotsDir || `docs/atlas/screenshots/${platform}`,
  );

  /** @type {object[]} */
  const plan = [];
  for (const s of hub.surfaces) {
    const p = s.platforms?.[platform];
    if (!p || p.status === "deferred") continue;
    if (!p.captureId && !p.route) continue;
    plan.push({
      surfaceId: s.id,
      title: s.title,
      route: p.route,
      captureId: p.captureId,
      status: p.status || "stub",
      output: p.captureId
        ? path.join(dir, `${p.captureId}__signed-in.png`).replace(/\\/g, "/")
        : null,
      rules: s.rules || [],
    });
  }

  console.log(`capture-stub platform=${platform} targets=${plan.length}`);
  console.log(`screenshotsDir=${dir}`);
  console.log("");
  console.log("When the Flutter shell exists:");
  console.log("  1. Boot app with test auth / fixtures");
  console.log("  2. Navigate each route");
  console.log("  3. Write PNG to output path (same captureId as Next when set)");
  console.log("  4. npm run product-map:parity -- --platform=" + platform);
  console.log("");

  for (const row of plan.slice(0, 25)) {
    console.log(
      `  [${row.status}] ${row.surfaceId} → ${row.route || "—"} → ${row.captureId || "no-capture"}`,
    );
  }
  if (plan.length > 25) console.log(`  …+${plan.length - 25} more`);

  if (writePlan) {
    fs.mkdirSync(dir, { recursive: true });
    const planFile = path.join(dir, "capture-plan.json");
    fs.writeFileSync(
      planFile,
      JSON.stringify(
        {
          platform,
          generatedAt: new Date().toISOString(),
          note: "Stub plan — not a real capture run",
          targets: plan,
        },
        null,
        2,
      ) + "\n",
      "utf8",
    );
    // keep dir with .gitkeep
    const keep = path.join(dir, ".gitkeep");
    if (!fs.existsSync(keep)) fs.writeFileSync(keep, "", "utf8");
    console.log(`Wrote ${planFile}`);
  }
}

main();
