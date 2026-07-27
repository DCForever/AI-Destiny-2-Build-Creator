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
 * @param {string} surfaceId
 * @param {Map<string, object>} surfaceById
 */
function screenIdFor(surfaceId, surfaceById) {
  const s = surfaceById.get(surfaceId);
  return (
    s?.platforms?.nextjs?.captureId ||
    (s?.id ? String(s.id).replace(/\./g, "-") : String(surfaceId).replace(/\./g, "-"))
  );
}

/**
 * Hierarchical phase tree for Atlas nested UI + Draw.io.
 * @param {object} flow
 * @param {Map<string, object>} surfaceById
 * @param {object[]} allFlows
 * @param {Set<string>} [stack] cycle guard
 * @returns {object[]}
 */
export function expandFlowTree(flow, surfaceById, allFlows = [], stack = new Set()) {
  const flowById = new Map(allFlows.map((f) => [f.id, f]));
  if (stack.has(flow.id)) {
    return [
      {
        id: `${flow.id}-cycle`,
        title: `(cycle: ${flow.id})`,
        kind: "cycle",
      },
    ];
  }
  stack.add(flow.id);

  /** @type {object[]} */
  const out = [];

  for (const ph of flow.phases || []) {
    if (ph.include) {
      const sub = flowById.get(ph.include);
      /** @type {any} */
      const node = {
        id: ph.id || ph.include,
        title: ph.title || sub?.title || ph.include,
        kind: "include",
        include: ph.include,
        rules: ph.rules || sub?.rules,
        children: sub
          ? expandFlowTree(sub, surfaceById, allFlows, new Set(stack))
          : [],
      };
      out.push(node);
      continue;
    }

    if (ph.branch) {
      /** @type {any} */
      const node = {
        id: ph.id || "branch",
        title: ph.title || "Branch",
        kind: "branch",
        rules: ph.rules,
        children: (ph.branch || []).map((b) => {
          if (b.include) {
            const sub = flowById.get(b.include);
            return {
              id: b.id || b.include,
              title: b.title || sub?.title || b.include,
              kind: "include",
              include: b.include,
              children: sub
                ? expandFlowTree(sub, surfaceById, allFlows, new Set(stack))
                : [],
            };
          }
          const sid = b.surface;
          return {
            id: b.id || sid,
            title: b.title || surfaceById.get(sid)?.title || sid,
            kind: "step",
            surfaceId: sid,
            screenId: sid ? screenIdFor(sid, surfaceById) : undefined,
            rules: b.rules,
            gate: b.gate || ph.gate,
            loop: b.loop || ph.loop,
          };
        }),
      };
      out.push(node);
      continue;
    }

    if (ph.surface) {
      out.push({
        id: ph.id || ph.surface,
        title: ph.title || surfaceById.get(ph.surface)?.title || ph.surface,
        kind: ph.loop ? "loop" : ph.gate ? "gate" : "step",
        surfaceId: ph.surface,
        screenId: screenIdFor(ph.surface, surfaceById),
        rules: ph.rules,
        gate: ph.gate,
        loop: ph.loop,
      });
    }
  }

  stack.delete(flow.id);
  return out;
}

/**
 * Flatten phase tree to atlas linear steps (for capture chains).
 * Branch alternatives are all included (labeled).
 * @param {object[]} tree
 * @returns {{ screenId: string, label: string, surfaceId?: string, kind?: string }[]}
 */
export function flattenPhaseTree(tree) {
  /** @type {{ screenId: string, label: string, surfaceId?: string, kind?: string }[]} */
  const steps = [];
  const walk = (nodes, prefix) => {
    for (const n of nodes || []) {
      const label = prefix ? `${prefix} › ${n.title}` : n.title;
      if (n.kind === "step" || n.kind === "loop" || n.kind === "gate") {
        if (n.screenId) {
          steps.push({
            screenId: n.screenId,
            label: n.loop ? `${label} (loop)` : n.gate ? `${label} (gate)` : label,
            surfaceId: n.surfaceId,
            kind: n.kind,
          });
        }
      }
      if (n.children?.length) {
        const p =
          n.kind === "branch"
            ? `${label} [alt]`
            : n.kind === "include"
              ? label
              : prefix;
        walk(n.children, n.kind === "branch" ? `${label}` : p);
      }
    }
  };
  walk(tree, "");
  return steps;
}

/**
 * Expand flows to atlas-style path steps (surface → captureId).
 * @param {object} flow
 * @param {Map<string, object>} surfaceById
 * @param {object[]} [allFlows]
 */
export function expandFlowSteps(flow, surfaceById, allFlows = []) {
  const tree = expandFlowTree(flow, surfaceById, allFlows);
  return flattenPhaseTree(tree);
}
