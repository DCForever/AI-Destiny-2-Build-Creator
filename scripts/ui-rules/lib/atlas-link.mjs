/**
 * Link UI-rules inventory nodes to Atlas screen captures.
 *
 * Resolution order per node:
 * 1. Explicit `atlas` field on the node (string | string[])
 * 2. Alias table (mismatched naming)
 * 3. Auto: node.id with '.' → '-' if it matches an atlas screen id
 * 4. Nearest ancestor with a resolution (inheritance for fields/surfaces)
 */
import fs from "node:fs";
import path from "node:path";
import { REPO_ROOT } from "./paths.mjs";

export const ATLAS_DIR = path.join(REPO_ROOT, "docs", "atlas");
export const ATLAS_MANIFEST_PATH = path.join(ATLAS_DIR, "manifest.json");
export const ATLAS_SHOTS_DIR = path.join(ATLAS_DIR, "screenshots");
export const ATLAS_OBS_PATH = path.join(ATLAS_DIR, "observations.json");

/**
 * Inventory node id → one or more Atlas screen ids when auto-mapping fails.
 * Keep this small; prefer aligning names so auto `.` → `-` works.
 */
export const ATLAS_ALIASES = {
  "build.create": [
    "build-create-draft-general",
    "build-create-draft-locked-tabs",
  ],
  "build.create.tabs": ["build-create-draft-locked-tabs"],
  "build.create.general": ["build-create-draft-general"],
  "build.create.class": ["build-create-draft-general"],
  "build.create.subclass": ["build-create-draft-general"],
  "build.create.name": ["build-create-draft-general"],
  "build.create.synergy-types": ["build-create-draft-general"],
  "build.create.exotic-armor": ["build-create-draft-general"],
  "build.create.exotic-weapon": ["build-create-draft-general"],
  "build.create.pinned-super": ["build-create-draft-general"],
  "build.create.tags": ["build-create-draft-general"],
  "build.create.submit": ["build-create-draft-general"],
  "build.edit.armor": [
    "build-edit-armor-reuse",
    "build-edit-armor-create",
    "build-edit-armor-improve",
  ],
  "build.edit.weapon": [
    "build-edit-weapon-reuse",
    "build-edit-weapon-create",
  ],
  "build.finish": ["build-edit-finish"],
  "build.finish.gaps": ["build-edit-finish"],
  "build.finish.walkthrough": ["build-edit-finish"],
  "build.finish.character": ["build-edit-finish"],
  "build.finish.equip": ["build-edit-finish"],
  "build.finish.dim": ["build-edit-finish"],
  "build.finish.equip-gate": ["build-edit-finish"],
  "catalog.weapons.filters": ["catalog-filters-open"],
  "loadouts.list": ["loadouts-signed-in", "loadouts"],
  "loadouts.signed-out": ["loadouts-signed-out"],
  "loadouts.filter.exotic": ["loadouts-signed-in"],
  "loadouts.slot-expanded": ["loadouts-slot-expanded"],
  "settings.signed-out": ["settings-signed-out", "settings"],
  "settings.signed-in": ["settings-signed-in"],
  "analyze.page": ["analyze"],
  "analyze.form": ["analyze"],
  "analyze.report": ["analyze"],
};

/**
 * @typedef {object} AtlasScreen
 * @property {string} id
 * @property {string} [title]
 * @property {string} [path]
 * @property {string} [auth]
 * @property {string} [area]
 */

/**
 * @returns {{ screens: AtlasScreen[], byId: Map<string, AtlasScreen> }}
 */
export function loadAtlasManifest() {
  if (!fs.existsSync(ATLAS_MANIFEST_PATH)) {
    return { screens: [], byId: new Map() };
  }
  const raw = JSON.parse(fs.readFileSync(ATLAS_MANIFEST_PATH, "utf8"));
  const screens = raw.screens || [];
  const byId = new Map(screens.map((s) => [s.id, s]));
  return { screens, byId, productAreas: raw.productAreas || [], raw };
}

/**
 * Discover screenshot files for a screen id.
 * Capture names: `{screenId}__{variant}.png` or legacy patterns.
 * @param {string} screenId
 * @returns {{ file: string, variant: string, url: string }[]}
 */
export function listShotsForScreen(screenId) {
  if (!fs.existsSync(ATLAS_SHOTS_DIR)) return [];
  const files = fs.readdirSync(ATLAS_SHOTS_DIR).filter((f) => f.endsWith(".png"));
  /** @type {{ file: string, variant: string, url: string }[]} */
  const out = [];
  for (const file of files) {
    // build-library__signed-in.png
    if (file.startsWith(screenId + "__")) {
      const variant = file.slice(screenId.length + 2, -4);
      out.push({
        file,
        variant,
        url: `/atlas/screenshots/${file}`,
      });
      continue;
    }
    // analyze__anon.png where screen is analyze
    if (file === `${screenId}.png`) {
      out.push({
        file,
        variant: "default",
        url: `/atlas/screenshots/${file}`,
      });
    }
  }
  // Prefer signed-in first
  out.sort((a, b) => {
    const rank = (v) =>
      v === "signed-in" ? 0 : v === "signed-out" ? 1 : v === "anon" ? 2 : 3;
    return rank(a.variant) - rank(b.variant);
  });
  return out;
}

/**
 * Direct resolution for one node (no parent walk).
 * @param {object} node
 * @param {Map<string, AtlasScreen>} atlasById
 * @returns {string[]}
 */
export function resolveAtlasIdsDirect(node, atlasById) {
  if (!node) return [];
  const ids = [];

  if (node.atlas != null) {
    const list = Array.isArray(node.atlas) ? node.atlas : [node.atlas];
    for (const id of list) {
      if (id && atlasById.has(String(id))) ids.push(String(id));
    }
    if (ids.length) return unique(ids);
  }

  if (ATLAS_ALIASES[node.id]) {
    for (const id of ATLAS_ALIASES[node.id]) {
      if (atlasById.has(id)) ids.push(id);
    }
    if (ids.length) return unique(ids);
  }

  const auto = String(node.id || "").replace(/\./g, "-");
  if (auto && atlasById.has(auto)) ids.push(auto);

  return unique(ids);
}

/**
 * Build parent map and resolve with inheritance.
 * @param {object} inventory - parsed inventory.yaml
 * @param {Map<string, AtlasScreen>} atlasById
 * @returns {Map<string, { ids: string[], inheritedFrom: string|null }>}
 */
export function buildNodeAtlasIndex(inventory, atlasById) {
  /** @type {Map<string, { node: object, parentId: string|null }>} */
  const meta = new Map();

  const walk = (nodes, parentId) => {
    for (const n of nodes || []) {
      meta.set(n.id, { node: n, parentId });
      walk(n.children, n.id);
    }
  };
  for (const p of inventory.pages || []) walk(p.nodes, null);

  /** @type {Map<string, { ids: string[], inheritedFrom: string|null }>} */
  const index = new Map();

  const resolve = (id) => {
    if (index.has(id)) return index.get(id);
    const m = meta.get(id);
    if (!m) {
      const empty = { ids: [], inheritedFrom: null };
      index.set(id, empty);
      return empty;
    }
    const direct = resolveAtlasIdsDirect(m.node, atlasById);
    if (direct.length) {
      const rec = { ids: direct, inheritedFrom: null };
      index.set(id, rec);
      return rec;
    }
    if (m.parentId) {
      const parent = resolve(m.parentId);
      if (parent.ids.length) {
        const rec = {
          ids: parent.ids,
          inheritedFrom: parent.inheritedFrom || m.parentId,
        };
        index.set(id, rec);
        return rec;
      }
    }
    const rec = { ids: [], inheritedFrom: null };
    index.set(id, rec);
    return rec;
  };

  for (const id of meta.keys()) resolve(id);
  return index;
}

/**
 * Full payload for companion / drawio for one node.
 * @param {string} nodeId
 * @param {Map<string, { ids: string[], inheritedFrom: string|null }>} index
 * @param {Map<string, AtlasScreen>} atlasById
 */
export function shotsPayloadForNode(nodeId, index, atlasById) {
  const link = index.get(nodeId) || { ids: [], inheritedFrom: null };
  const screens = link.ids.map((id) => {
    const screen = atlasById.get(id) || { id };
    const shots = listShotsForScreen(id);
    return {
      id,
      title: screen.title || id,
      path: screen.path,
      auth: screen.auth,
      area: screen.area,
      shots,
      hasShots: shots.length > 0,
    };
  });
  return {
    nodeId,
    atlasIds: link.ids,
    inheritedFrom: link.inheritedFrom,
    screens,
    hasAnyShots: screens.some((s) => s.hasShots),
  };
}

/**
 * @param {string[]} arr
 */
function unique(arr) {
  return [...new Set(arr)];
}

/**
 * Invert inventory→atlas index into atlas screen id → primary inventory node.
 * Prefers direct (non-inherited) links; among directs, shortest id / screen-like kinds win.
 *
 * @param {object} inventory
 * @param {Map<string, { ids: string[], inheritedFrom: string|null }>} atlasIndex
 * @returns {{
 *   generatedAt: string,
 *   companionHint: string,
 *   byScreen: Record<string, { primary: string, page: string|null, title: string, nodes: string[] }>,
 *   byNode: Record<string, string[]>
 * }}
 */
export function buildReverseAtlasMap(inventory, atlasIndex) {
  /** @type {Map<string, { id: string, title: string, kind: string, page: string|null }>} */
  const nodeMeta = new Map();
  for (const page of inventory.pages || []) {
    const walk = (nodes) => {
      for (const n of nodes || []) {
        nodeMeta.set(n.id, {
          id: n.id,
          title: n.title || n.id,
          kind: n.kind || "surface",
          page: page.id,
        });
        walk(n.children);
      }
    };
    walk(page.nodes);
  }

  /** @type {Map<string, string[]>} */
  const screenToNodes = new Map();
  /** @type {Record<string, string[]>} */
  const byNode = {};

  for (const [nodeId, link] of atlasIndex.entries()) {
    if (!link.ids?.length) continue;
    // only direct links for reverse primary (avoid flooding every field)
    if (link.inheritedFrom) continue;
    byNode[nodeId] = link.ids;
    for (const sid of link.ids) {
      if (!screenToNodes.has(sid)) screenToNodes.set(sid, []);
      screenToNodes.get(sid).push(nodeId);
    }
  }

  const kindRank = (k) => {
    if (k === "screen") return 0;
    if (k === "subscreen") return 1;
    if (k === "gate") return 2;
    if (k === "flow") return 3;
    if (k === "surface") return 4;
    return 5;
  };

  /** @type {Record<string, { primary: string, page: string|null, title: string, nodes: string[] }>} */
  const byScreen = {};
  for (const [sid, nodes] of screenToNodes.entries()) {
    const sorted = [...nodes].sort((a, b) => {
      const ma = nodeMeta.get(a);
      const mb = nodeMeta.get(b);
      const kr = kindRank(ma?.kind) - kindRank(mb?.kind);
      if (kr !== 0) return kr;
      return a.length - b.length || a.localeCompare(b);
    });
    const primary = sorted[0];
    const meta = nodeMeta.get(primary);
    byScreen[sid] = {
      primary,
      page: meta?.page ?? null,
      title: meta?.title || primary,
      nodes: sorted,
    };
  }

  return {
    generatedAt: new Date().toISOString().slice(0, 10),
    companionHint: "http://127.0.0.1:4174/?node=<inventory-node-id>",
    byScreen,
    byNode,
  };
}
