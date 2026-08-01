#!/usr/bin/env node
/**
 * Validate product-map hub structure and rule ID resolution.
 */
import { loadHub } from "./lib/load-hub.mjs";
import { loadAllRules } from "../ui-rules/lib/parse-rules.mjs";

function main() {
  const hub = loadHub();
  const { byId: rulesById } = loadAllRules();
  /** @type {string[]} */
  const errors = [];
  /** @type {string[]} */
  const warnings = [];

  if (!hub.surfaces.length) {
    errors.push("No surfaces in surfaces.yaml — run npm run product-map:import");
  }

  const ids = new Set();
  for (const s of hub.surfaces) {
    if (!s.id) errors.push("Surface missing id");
    else if (ids.has(s.id)) errors.push(`Duplicate surface id: ${s.id}`);
    else ids.add(s.id);

    if (s.parent && !hub.byId.has(s.parent) && s.parent !== null) {
      // parent might be missing if import bug
      if (s.parent) warnings.push(`Surface ${s.id} parent missing: ${s.parent}`);
    }

    for (const rid of s.rules || []) {
      if (!rulesById.has(rid)) {
        warnings.push(`Surface ${s.id}: unknown rule ${rid}`);
      }
    }
    for (const ref of s.refs || []) {
      if (ref.type === "error" && !ref.id) {
        errors.push(`Surface ${s.id}: error ref missing id`);
      }
    }
  }

  const flowIds = new Set();
  for (const f of hub.flows) {
    if (!f.id) errors.push("Flow missing id");
    else if (flowIds.has(f.id)) errors.push(`Duplicate flow id: ${f.id}`);
    else flowIds.add(f.id);

    for (const rid of f.rules || []) {
      if (!rulesById.has(rid)) warnings.push(`Flow ${f.id}: unknown rule ${rid}`);
    }
    for (const ph of f.phases || []) {
      if (ph.include && !flowIds.has(ph.include) && !hub.flows.some((x) => x.id === ph.include)) {
        // may be forward ref — check after
      }
      if (ph.surface && !hub.byId.has(ph.surface)) {
        warnings.push(`Flow ${f.id} phase ${ph.id}: unknown surface ${ph.surface}`);
      }
      for (const rid of ph.rules || []) {
        if (!rulesById.has(rid)) {
          warnings.push(`Flow ${f.id}/${ph.id}: unknown rule ${rid}`);
        }
      }
    }
  }

  // include resolution
  for (const f of hub.flows) {
    for (const ph of f.phases || []) {
      if (ph.include && !hub.flows.some((x) => x.id === ph.include)) {
        errors.push(`Flow ${f.id}: include unknown flow ${ph.include}`);
      }
    }
  }

  // platform keys
  for (const s of hub.surfaces) {
    for (const pk of Object.keys(s.platforms || {})) {
      if (!hub.platforms[pk]) {
        warnings.push(`Surface ${s.id}: unknown platform key ${pk}`);
      }
    }
  }

  for (const w of warnings) console.warn(`  warn: ${w}`);
  for (const e of errors) console.error(`  error: ${e}`);

  console.log(
    `product-map validate: ${hub.surfaces.length} surfaces, ${hub.flows.length} flows, ${errors.length} errors, ${warnings.length} warnings`,
  );
  if (errors.length) process.exit(1);
}

main();
