import fs from "node:fs";
import { stringify as yamlStringify } from "yaml";
import { loadHub } from "./load-hub.mjs";
import { FLOWS_PATH, SURFACES_PATH } from "./paths.mjs";

function writeSurfaces(surfaces) {
  fs.writeFileSync(
    SURFACES_PATH,
    yamlStringify({ surfaces }, { lineWidth: 0 }),
    "utf8",
  );
}

function writeFlows(flows) {
  fs.writeFileSync(
    FLOWS_PATH,
    yamlStringify({ flows }, { lineWidth: 0 }),
    "utf8",
  );
}

/**
 * Replace rules array on a surface.
 * @param {string} surfaceId
 * @param {string[]} rules
 */
export function attachRulesToSurface(surfaceId, rules) {
  const hub = loadHub();
  const s = hub.surfaces.find((x) => x.id === surfaceId);
  if (!s) return { ok: false, message: `Unknown surface: ${surfaceId}` };
  const cleaned = [...new Set((rules || []).map((r) => String(r).trim()).filter(Boolean))];
  s.rules = cleaned;
  writeSurfaces(hub.surfaces);
  return { ok: true, surfaceId, rules: cleaned, sourcePath: "docs/product-map/surfaces.yaml" };
}

/**
 * Append a phase stub to a flow.
 * @param {string} flowId
 * @param {{ id: string, title?: string, surface?: string|null, include?: string|null }} phase
 */
export function addPhaseToFlow(flowId, phase) {
  const hub = loadHub();
  const f = hub.flows.find((x) => x.id === flowId);
  if (!f) return { ok: false, message: `Unknown flow: ${flowId}` };
  if (!phase?.id) return { ok: false, message: "phase.id required" };
  f.phases = f.phases || [];
  if (f.phases.some((p) => p.id === phase.id)) {
    return { ok: false, message: `Phase already exists: ${phase.id}` };
  }
  /** @type {any} */
  const row = {
    id: String(phase.id).trim(),
    title: phase.title || phase.id,
  };
  if (phase.include) row.include = phase.include;
  else if (phase.surface) row.surface = phase.surface;
  f.phases.push(row);
  writeFlows(hub.flows);
  return {
    ok: true,
    flowId,
    phase: row,
    sourcePath: "docs/product-map/flows.yaml",
  };
}

/**
 * Create a minimal surface if missing.
 */
export function ensureSurface(surface) {
  const hub = loadHub();
  if (hub.surfaces.some((s) => s.id === surface.id)) {
    return { ok: false, message: `Surface exists: ${surface.id}` };
  }
  /** @type {any} */
  const row = {
    id: surface.id,
    title: surface.title || surface.id,
    kind: surface.kind || "screen",
    area: surface.area || surface.id.split(".")[0] || "other",
    parent: surface.parent ?? null,
    status: "active",
    rules: surface.rules || [],
  };
  if (surface.path || surface.captureId) {
    row.platforms = {
      nextjs: {
        ...(surface.path ? { path: surface.path } : {}),
        ...(surface.captureId ? { captureId: surface.captureId } : {}),
      },
    };
  }
  hub.surfaces.push(row);
  writeSurfaces(hub.surfaces);
  return { ok: true, surface: row, sourcePath: "docs/product-map/surfaces.yaml" };
}
