#!/usr/bin/env node
/**
 * Drift checks: Next routes vs product-map hub; rule ID resolution summary.
 * Exit 0 with warnings by default; PRODUCT_MAP_CHECK_STRICT=1 fails on issues.
 */
import fs from "node:fs";
import path from "node:path";
import { loadAllRules } from "../ui-rules/lib/parse-rules.mjs";
import { loadHub } from "./lib/load-hub.mjs";
import { REPO_ROOT } from "./lib/paths.mjs";

const strict = process.env.PRODUCT_MAP_CHECK_STRICT === "1";

/**
 * @param {string} dir
 * @returns {string[]}
 */
function listPageRoutes(dir) {
  /** @type {string[]} */
  const routes = [];
  if (!fs.existsSync(dir)) return routes;

  const walk = (d, parts) => {
    for (const ent of fs.readdirSync(d, { withFileTypes: true })) {
      if (ent.name.startsWith(".") || ent.name === "api") continue;
      const p = path.join(d, ent.name);
      if (ent.isDirectory()) {
        walk(p, [...parts, ent.name]);
      } else if (ent.name === "page.tsx" || ent.name === "page.ts" || ent.name === "page.jsx") {
        const route =
          parts.length === 0 ? "/" : "/" + parts.join("/").replace(/\\/g, "/");
        routes.push(route);
      }
    }
  };
  walk(dir, []);
  return routes.sort();
}

function main() {
  const hub = loadHub();
  const { byId: rulesById } = loadAllRules();
  /** @type {string[]} */
  const warnings = [];
  /** @type {string[]} */
  const errors = [];

  // --- Routes ---
  const appDir = path.join(REPO_ROOT, "src", "app");
  const routes = listPageRoutes(appDir);
  const productionRoutes = routes.filter((r) => !r.startsWith("/debug"));

  const hubPaths = new Set();
  for (const s of hub.surfaces) {
    const p = s.platforms?.nextjs?.path;
    if (p && p !== "/*") hubPaths.add(p.replace(/\/$/, "") || "/");
  }

  for (const r of productionRoutes) {
    const norm = r.replace(/\/$/, "") || "/";
    // root page may map to redirect — still expect some surface or ignore /
    if (norm === "/") continue;
    if (!hubPaths.has(norm)) {
      warnings.push(`Route ${norm} has no surface platforms.nextjs.path in hub`);
    }
  }

  // --- Orphan surfaces (never in any flow) ---
  const used = new Set();
  const markFlow = (flow, stack = new Set()) => {
    if (stack.has(flow.id)) return;
    stack.add(flow.id);
    for (const ph of flow.phases || []) {
      if (ph.surface) used.add(ph.surface);
      if (ph.include) {
        const sub = hub.flows.find((f) => f.id === ph.include);
        if (sub) markFlow(sub, stack);
      }
      for (const b of ph.branch || []) {
        if (b.surface) used.add(b.surface);
        if (b.include) {
          const sub = hub.flows.find((f) => f.id === b.include);
          if (sub) markFlow(sub, stack);
        }
      }
    }
  };
  for (const f of hub.flows) markFlow(f);

  let orphanSurfaces = 0;
  for (const s of hub.surfaces) {
    if (s.status === "retired") continue;
    // fields under a used parent are ok
    if (used.has(s.id)) continue;
    if (s.parent && used.has(s.parent)) continue;
    // skip pure fields with no capture (leaf chrome)
    if (s.kind === "field" || s.kind === "surface") continue;
    if (!used.has(s.id) && (s.kind === "screen" || s.kind === "subscreen" || s.kind === "gate")) {
      orphanSurfaces++;
      if (orphanSurfaces <= 15) {
        warnings.push(`Screen-like surface not in any flow: ${s.id}`);
      }
    }
  }
  if (orphanSurfaces > 15) {
    warnings.push(`…and ${orphanSurfaces - 15} more screen-like surfaces not in flows`);
  }

  // --- Rule resolve ---
  let badRules = 0;
  for (const s of hub.surfaces) {
    for (const rid of s.rules || []) {
      if (!rulesById.has(rid)) {
        badRules++;
        if (badRules <= 10) warnings.push(`Unknown rule on ${s.id}: ${rid}`);
      }
    }
  }
  for (const f of hub.flows) {
    for (const rid of f.rules || []) {
      if (!rulesById.has(rid)) {
        badRules++;
        if (badRules <= 10) warnings.push(`Unknown rule on flow ${f.id}: ${rid}`);
      }
    }
  }

  // --- Missing include targets ---
  for (const f of hub.flows) {
    for (const ph of f.phases || []) {
      if (ph.include && !hub.flows.some((x) => x.id === ph.include)) {
        errors.push(`Flow ${f.id} includes missing flow ${ph.include}`);
      }
      if (ph.surface && !hub.byId.has(ph.surface)) {
        errors.push(`Flow ${f.id} phase ${ph.id}: missing surface ${ph.surface}`);
      }
      for (const b of ph.branch || []) {
        if (b.surface && !hub.byId.has(b.surface)) {
          errors.push(`Flow ${f.id} branch: missing surface ${b.surface}`);
        }
        if (b.include && !hub.flows.some((x) => x.id === b.include)) {
          errors.push(`Flow ${f.id} branch includes missing ${b.include}`);
        }
      }
    }
  }

  for (const w of warnings) console.warn(`  warn: ${w}`);
  for (const e of errors) console.error(`  error: ${e}`);

  console.log(
    `product-map:check — routes=${productionRoutes.length} hubPaths=${hubPaths.size} flows=${hub.flows.length} warnings=${warnings.length} errors=${errors.length}`,
  );

  if (errors.length || (strict && warnings.length)) {
    process.exit(1);
  }
}

main();
