#!/usr/bin/env node
/**
 * Seed / re-import product-map hub from legacy inventory.yaml + atlas manifest.
 * Overwrites surfaces.yaml, flows.yaml, transitions.yaml.
 */
import fs from "node:fs";
import { stringify as yamlStringify } from "yaml";
import { parse as parseYaml } from "yaml";
import {
  ATLAS_MANIFEST_PATH,
  FLOWS_PATH,
  INVENTORY_PATH,
  PRODUCT_MAP_DIR,
  SURFACES_PATH,
  TRANSITIONS_PATH,
} from "./lib/paths.mjs";

function main() {
  if (!fs.existsSync(INVENTORY_PATH)) {
    console.error("Missing inventory:", INVENTORY_PATH);
    process.exit(1);
  }
  const inv = parseYaml(fs.readFileSync(INVENTORY_PATH, "utf8"));
  const atlas = fs.existsSync(ATLAS_MANIFEST_PATH)
    ? JSON.parse(fs.readFileSync(ATLAS_MANIFEST_PATH, "utf8"))
    : { screens: [], paths: [], transitions: [] };

  /** @type {object[]} */
  const surfaces = [];
  /** @type {object[]} */
  const flowSurfaces = []; // kind:flow nodes become flows later

  const walk = (nodes, parentId, area) => {
    for (const n of nodes || []) {
      if (n.kind === "flow") {
        flowSurfaces.push({ ...n, area, parentId });
        // still register as surface for diagram?
        // Skip as surface; only as flow
        continue;
      }
      const captureFromAtlas =
        n.atlas ||
        (typeof n.atlas === "string" ? [n.atlas] : null);
      let captureId = null;
      if (Array.isArray(captureFromAtlas) && captureFromAtlas[0]) {
        captureId = captureFromAtlas[0];
      } else if (typeof n.atlas === "string") {
        captureId = n.atlas;
      } else {
        // auto from id
        const guess = String(n.id).replace(/\./g, "-");
        if ((atlas.screens || []).some((s) => s.id === guess)) {
          captureId = guess;
        }
      }

      /** @type {any} */
      const surface = {
        id: n.id,
        title: n.title || n.id,
        kind: n.kind || "surface",
        area: area || "other",
        auth: n.auth || undefined,
        parent: parentId || null,
        notes: n.notes || undefined,
        rules: n.rules || undefined,
        status: "active",
      };
      if (n.flowsTo) surface.flowsTo = n.flowsTo;

      const path = n.path;
      if (path || captureId || n.auth) {
        surface.platforms = {
          nextjs: {
            ...(path ? { path } : {}),
            ...(captureId ? { captureId } : {}),
            ...(n.tab ? { tab: n.tab } : {}),
          },
        };
      }

      // strip undefined
      for (const k of Object.keys(surface)) {
        if (surface[k] === undefined) delete surface[k];
      }
      if (surface.platforms?.nextjs) {
        for (const k of Object.keys(surface.platforms.nextjs)) {
          if (surface.platforms.nextjs[k] === undefined) {
            delete surface.platforms.nextjs[k];
          }
        }
      }

      surfaces.push(surface);
      walk(n.children, n.id, area);
    }
  };

  for (const page of inv.pages || []) {
    const area = page.id === "overview" ? "shell" : page.id;
    walk(page.nodes, null, area);
  }

  // Enrich capture from atlas screen list by matching title-ish
  const screenById = new Map((atlas.screens || []).map((s) => [s.id, s]));
  for (const s of surfaces) {
    const cid = s.platforms?.nextjs?.captureId;
    if (cid && screenById.has(cid)) {
      const sc = screenById.get(cid);
      if (!s.platforms.nextjs.path && sc.path) {
        s.platforms.nextjs.path = sc.path;
      }
      if (!s.auth && sc.auth) s.auth = sc.auth;
    }
  }

  /** @type {object[]} */
  const flows = [];

  // From inventory kind:flow nodes
  for (const f of flowSurfaces) {
    flows.push({
      id: f.id.startsWith("flow.") || f.id.startsWith("journey.")
        ? f.id
        : `flow.${f.id}`,
      title: f.title,
      type: f.id.includes("journey") ? "journey" : "flow",
      priority: f.id.includes("p1") ? "P1" : f.id.includes("p2") ? "P2" : undefined,
      rules: f.rules,
      phases: (f.children || []).map((c, i) => ({
        id: c.id.split(".").pop() || `phase-${i}`,
        title: c.title,
        surface: c.id,
        rules: c.rules,
      })),
    });
  }

  // From atlas paths
  for (const p of atlas.paths || []) {
    if (flows.some((f) => f.id === p.id || f.id === `flow.${p.id}`)) continue;
    const phases = (p.steps || []).map((st, i) => {
      // find surface with this captureId
      const surf = surfaces.find(
        (s) => s.platforms?.nextjs?.captureId === st.screenId,
      );
      return {
        id: `step-${i + 1}`,
        title: st.label || st.screenId,
        surface: surf?.id || st.screenId.replace(/-/g, "."),
        // if surface missing, still record screenId for generate
        captureId: st.screenId,
      };
    });
    flows.push({
      id: p.id.startsWith("flow-") ? p.id.replace(/^flow-/, "flow.") : p.id,
      title: p.title,
      type: p.type || "path",
      priority: p.priority,
      description: p.description,
      phases,
    });
  }

  // Ensure phase surfaces exist for orphan capture-only steps
  for (const flow of flows) {
    for (const ph of flow.phases || []) {
      if (ph.surface && !surfaces.some((s) => s.id === ph.surface)) {
        // try captureId-based
        if (ph.captureId) {
          const existing = surfaces.find(
            (s) => s.platforms?.nextjs?.captureId === ph.captureId,
          );
          if (existing) {
            ph.surface = existing.id;
            delete ph.captureId;
            continue;
          }
        }
        // create stub surface from capture
        const sid = ph.surface;
        if (!surfaces.some((s) => s.id === sid)) {
          surfaces.push({
            id: sid,
            title: ph.title || sid,
            kind: "screen",
            area: sid.split(".")[0] || "other",
            parent: null,
            status: "active",
            platforms: ph.captureId
              ? { nextjs: { captureId: ph.captureId } }
              : undefined,
          });
        }
        delete ph.captureId;
      } else {
        delete ph.captureId;
      }
    }
  }

  const transitions = (atlas.transitions || []).map((t) => {
    const fromS = surfaces.find(
      (s) => s.platforms?.nextjs?.captureId === t.from,
    );
    const toS = surfaces.find((s) => s.platforms?.nextjs?.captureId === t.to);
    return {
      from: fromS?.id || t.from,
      to: toS?.id || t.to,
      action: t.action,
      fromCaptureId: t.from,
      toCaptureId: t.to,
    };
  });

  fs.mkdirSync(PRODUCT_MAP_DIR, { recursive: true });
  fs.writeFileSync(
    SURFACES_PATH,
    yamlStringify(
      { surfaces },
      { lineWidth: 0, defaultStringType: "QUOTE_DOUBLE" },
    ),
    "utf8",
  );
  fs.writeFileSync(
    FLOWS_PATH,
    yamlStringify({ flows }, { lineWidth: 0 }),
    "utf8",
  );
  fs.writeFileSync(
    TRANSITIONS_PATH,
    yamlStringify({ transitions }, { lineWidth: 0 }),
    "utf8",
  );

  console.log(
    `Imported ${surfaces.length} surfaces, ${flows.length} flows, ${transitions.length} transitions → ${PRODUCT_MAP_DIR}`,
  );
}

main();
