#!/usr/bin/env node
/**
 * Seed platforms.flutter-windows on product surfaces that already have nextjs bindings.
 * Does not fork domain rules — same surface id, same captureId when possible.
 *
 * Usage: node scripts/product-map/seed-flutter-windows.mjs [--force]
 *   --force  overwrite existing flutter-windows blocks
 */
import fs from "node:fs";
import { stringify as yamlStringify } from "yaml";
import { loadHub } from "./lib/load-hub.mjs";
import { SURFACES_PATH } from "./lib/paths.mjs";

const force = process.argv.includes("--force");

/** Areas in first Flutter Windows shell (exclude debug, journey stubs, analyze-heavy). */
const PRIORITY_AREAS = new Set([
  "shell",
  "build",
  "catalog",
  "sets",
  "synergy",
  "loadouts",
  "settings",
]);

const PRIORITY_KINDS = new Set(["screen", "subscreen", "gate"]);

/** Surfaces deferred on Flutter Windows (non-goals / later). */
const DEFER_IDS = new Set([
  "analyze.page",
  "shared.llm-propose",
  "shared.llm-propose.run",
  "shared.llm-propose.review",
  "shared.llm-propose.confirm",
]);

function main() {
  const hub = loadHub();
  let added = 0;
  let skipped = 0;
  let deferred = 0;

  for (const s of hub.surfaces) {
    if (DEFER_IDS.has(s.id) || s.id.startsWith("shared.llm") || s.id.startsWith("journey.")) {
      if (!s.platforms) s.platforms = {};
      if (!s.platforms["flutter-windows"] || force) {
        s.platforms["flutter-windows"] = {
          status: "deferred",
          notes: "Not first-shell Flutter Windows scope",
        };
        deferred++;
      }
      continue;
    }

    const nx = s.platforms?.nextjs;
    const isPriority =
      PRIORITY_AREAS.has(s.area) &&
      (PRIORITY_KINDS.has(s.kind) || nx?.captureId || nx?.path);

    if (!isPriority) {
      skipped++;
      continue;
    }

    if (s.platforms?.["flutter-windows"] && !force) {
      skipped++;
      continue;
    }

    if (!s.platforms) s.platforms = {};
    const route = nx?.path && nx.path !== "/*" ? nx.path : guessRoute(s);
    s.platforms["flutter-windows"] = {
      status: "stub",
      route: route || undefined,
      captureId: nx?.captureId || undefined,
      // same logical capture id as Next when present
    };
    // strip undefined
    for (const k of Object.keys(s.platforms["flutter-windows"])) {
      if (s.platforms["flutter-windows"][k] === undefined) {
        delete s.platforms["flutter-windows"][k];
      }
    }
    added++;
  }

  fs.writeFileSync(
    SURFACES_PATH,
    yamlStringify({ surfaces: hub.surfaces }, { lineWidth: 0 }),
    "utf8",
  );
  console.log(
    `seed-flutter-windows: added/updated=${added} deferred=${deferred} skipped=${skipped}`,
  );
  console.log(`Wrote ${SURFACES_PATH}`);
  console.log("Next: npm run product-map:sync && npm run product-map:parity");
}

function guessRoute(s) {
  const area = s.area;
  const map = {
    build: "/build",
    catalog: "/catalog",
    sets: "/sets",
    synergy: "/synergy",
    loadouts: "/loadouts",
    settings: "/settings",
    shell: "/",
  };
  return map[area];
}

main();
