import fs from "node:fs";
import { parse as parseYaml } from "yaml";
import {
  FLOWS_PATH,
  META_PATH,
  PLATFORMS_PATH,
  SURFACES_PATH,
  TRANSITIONS_PATH,
} from "./paths.mjs";

function readYaml(p, fallback) {
  if (!fs.existsSync(p)) return fallback;
  return parseYaml(fs.readFileSync(p, "utf8")) ?? fallback;
}

/**
 * @returns {{
 *   meta: object,
 *   platforms: Record<string, object>,
 *   surfaces: object[],
 *   flows: object[],
 *   transitions: object[],
 *   byId: Map<string, object>
 * }}
 */
export function loadHub() {
  const meta = readYaml(META_PATH, { version: 1 });
  const platformsDoc = readYaml(PLATFORMS_PATH, { platforms: {} });
  const surfacesDoc = readYaml(SURFACES_PATH, { surfaces: [] });
  const flowsDoc = readYaml(FLOWS_PATH, { flows: [] });
  const transitionsDoc = readYaml(TRANSITIONS_PATH, { transitions: [] });

  const surfaces = surfacesDoc.surfaces || [];
  const byId = new Map(surfaces.map((s) => [s.id, s]));

  return {
    meta,
    platforms: platformsDoc.platforms || {},
    surfaces,
    flows: flowsDoc.flows || [],
    transitions: transitionsDoc.transitions || [],
    byId,
  };
}

/**
 * Build parent→children tree for inventory/drawio projection.
 * @param {object[]} surfaces
 */
export function surfacesToTree(surfaces) {
  /** @type {Map<string|null, object[]>} */
  const childrenOf = new Map();
  for (const s of surfaces) {
    const p = s.parent ?? null;
    if (!childrenOf.has(p)) childrenOf.set(p, []);
    childrenOf.get(p).push(s);
  }
  for (const list of childrenOf.values()) {
    list.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  }

  const toNode = (s) => {
    const kids = childrenOf.get(s.id) || [];
    /** @type {any} */
    const node = {
      id: s.id,
      kind: s.kind || "surface",
      title: s.title || s.id,
      path: s.platforms?.nextjs?.path || s.path,
      auth: s.auth,
      notes: s.notes,
      rules: s.rules || [],
      atlas: s.platforms?.nextjs?.captureId
        ? [s.platforms.nextjs.captureId]
        : s.atlas,
    };
    if (kids.length) node.children = kids.map(toNode);
    if (s.flowsTo) node.flowsTo = s.flowsTo;
    return node;
  };

  const roots = childrenOf.get(null) || [];
  /** @type {Map<string, object[]>} */
  const byArea = new Map();
  for (const r of roots) {
    const area = r.area || "other";
    if (!byArea.has(area)) byArea.set(area, []);
    byArea.get(area).push(toNode(r));
  }
  return byArea;
}

/**
 * Expand flows to atlas-style path steps (surface → captureId).
 * @param {object[]} flows
 * @param {Map<string, object>} surfaceById
 * @param {object[]} [allFlows]
 */
export function expandFlowSteps(flow, surfaceById, allFlows = []) {
  const flowById = new Map(allFlows.map((f) => [f.id, f]));
  /** @type {{ screenId: string, label: string, surfaceId?: string }[]} */
  const steps = [];

  const walkPhases = (phases) => {
    for (const ph of phases || []) {
      if (ph.include) {
        const sub = flowById.get(ph.include);
        if (sub) walkPhases(sub.phases);
        continue;
      }
      if (ph.branch) {
        for (const b of ph.branch) {
          if (b.include) {
            const sub = flowById.get(b.include);
            if (sub) walkPhases(sub.phases);
          } else if (b.surface) {
            pushSurface(b.surface, b.title || ph.title || b.surface);
          }
        }
        continue;
      }
      if (ph.surface) {
        pushSurface(ph.surface, ph.title || ph.id || ph.surface);
      }
    }
  };

  const pushSurface = (surfaceId, label) => {
    const s = surfaceById.get(surfaceId);
    const screenId =
      s?.platforms?.nextjs?.captureId ||
      (s?.id ? String(s.id).replace(/\./g, "-") : surfaceId.replace(/\./g, "-"));
    steps.push({
      screenId,
      label: label || s?.title || surfaceId,
      surfaceId,
    });
  };

  walkPhases(flow.phases);
  return steps;
}
