#!/usr/bin/env node
/**
 * Report DBR/DAC/BR (and optional slice) rule IDs never attached on surfaces or flows.
 * Writes docs/product-map/orphan-rules.md
 *
 * Exit 0 always unless PRODUCT_MAP_ORPHAN_STRICT=1 (then fail if any domain orphans).
 */
import fs from "node:fs";
import path from "node:path";
import { loadAllRules } from "../ui-rules/lib/parse-rules.mjs";
import { loadHub } from "./lib/load-hub.mjs";
import { PRODUCT_MAP_DIR, REPO_ROOT } from "./lib/paths.mjs";

const strict = process.env.PRODUCT_MAP_ORPHAN_STRICT === "1";
const includeSlice = process.argv.includes("--include-slice");

function collectAttached(hub) {
  const used = new Set();
  const add = (ids) => {
    for (const id of ids || []) used.add(id);
  };
  for (const s of hub.surfaces) add(s.rules);
  for (const f of hub.flows) {
    add(f.rules);
    for (const ph of f.phases || []) {
      add(ph.rules);
      for (const b of ph.branch || []) add(b.rules);
    }
  }
  return used;
}

function main() {
  const hub = loadHub();
  const { rules } = loadAllRules();
  const used = collectAttached(hub);

  const domain = rules.filter(
    (r) => r.layer === "dac" || r.layer === "dbr" || r.layer === "br",
  );
  const slice = rules.filter((r) => r.layer === "slice");

  const orphanDomain = domain.filter((r) => !used.has(r.id));
  const orphanSlice = slice.filter((r) => !used.has(r.id));

  const byLayer = { dac: [], dbr: [], br: [] };
  for (const r of orphanDomain) {
    byLayer[r.layer]?.push(r);
  }

  console.log(
    `orphan-rules: attached=${used.size} domain-total=${domain.length} domain-orphan=${orphanDomain.length} slice-orphan=${orphanSlice.length}`,
  );
  for (const [layer, list] of Object.entries(byLayer)) {
    console.log(`  ${layer}: ${list.length} unattached`);
  }

  const reportPath = path.join(PRODUCT_MAP_DIR, "orphan-rules.md");
  const lines = [
    `# Orphan rules (not on product map)`,
    "",
    `Generated: ${new Date().toISOString().slice(0, 10)}`,
    "",
    "Rules listed here exist in domain/feature markdown but are **not** referenced by any surface or flow phase `rules:` list.",
    "That can be intentional (backend-only, not yet mapped, superseded).",
    "",
    `| Layer | Total | Attached | Orphan |`,
    `|-------|-------|----------|--------|`,
    ...["dac", "dbr", "br"].map((layer) => {
      const total = domain.filter((r) => r.layer === layer).length;
      const orphans = byLayer[layer].length;
      return `| ${layer.toUpperCase()} | ${total} | ${total - orphans} | ${orphans} |`;
    }),
    "",
  ];

  for (const layer of ["dac", "dbr", "br"]) {
    const list = byLayer[layer];
    lines.push(`## ${layer.toUpperCase()} (${list.length})`, "");
    if (!list.length) {
      lines.push("_None._", "");
      continue;
    }
    lines.push("| ID | Section |", "|----|---------|");
    for (const r of list.sort((a, b) => a.id.localeCompare(b.id))) {
      lines.push(`| \`${r.id}\` | ${r.section || "—"} |`);
    }
    lines.push("");
  }

  if (includeSlice) {
    lines.push(`## Slice SC/AS (${orphanSlice.length})`, "");
    lines.push(
      "_Many slice criteria are historical; prefer promoting durable ones to DAC/BR._",
      "",
    );
    for (const r of orphanSlice.slice(0, 100).sort((a, b) => a.id.localeCompare(b.id))) {
      lines.push(`- \`${r.id}\``);
    }
    if (orphanSlice.length > 100) {
      lines.push(`- _…+${orphanSlice.length - 100} more_`);
    }
    lines.push("");
  }

  lines.push(
    "## How to fix",
    "",
    "1. Attach to a surface/flow: Screens mode in companion or edit `surfaces.yaml` / `flows.yaml`",
    "2. Or mark intentional: leave orphan if backend-only / not user-visible",
    "3. Re-run `npm run product-map:orphan-rules`",
    "",
  );

  fs.writeFileSync(reportPath, lines.join("\n"), "utf8");
  console.log(`Wrote ${path.relative(REPO_ROOT, reportPath)}`);

  if (strict && orphanDomain.length > 0) {
    console.error(
      `Strict orphan-rules: ${orphanDomain.length} domain rules unattached`,
    );
    process.exit(1);
  }
}

main();
