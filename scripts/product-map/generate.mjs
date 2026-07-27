#!/usr/bin/env node
/**
 * Generate projections from product-map hub:
 * - docs/ui-rules/inventory.yaml (compat)
 * - docs/ui-rules/ui-map.drawio
 * - docs/atlas/ui-rules-links.json
 * - docs/atlas/manifest.json (screens/paths/transitions merged)
 */
import fs from "node:fs";
import { stringify as yamlStringify } from "yaml";
import {
  buildNodeAtlasIndex,
  buildReverseAtlasMap,
  loadAtlasManifest,
} from "../ui-rules/lib/atlas-link.mjs";
import { buildMxFile } from "../ui-rules/lib/drawio.mjs";
import { expandRuleRefs, loadAllRules } from "../ui-rules/lib/parse-rules.mjs";
import { expandFlowSteps, loadHub, surfacesToTree } from "./lib/load-hub.mjs";
import {
  ATLAS_LINKS_PATH,
  ATLAS_MANIFEST_PATH,
  DRAWIO_PATH,
  INVENTORY_PATH,
  UI_RULES_DIR,
} from "./lib/paths.mjs";

function hubToInventory(hub) {
  const byArea = surfacesToTree(hub.surfaces);
  // Prefer stable page order
  const order = [
    "shell",
    "overview",
    "build",
    "catalog",
    "sets",
    "synergy",
    "loadouts",
    "settings",
    "analyze",
    "cross-cutting",
    "other",
  ];
  const areas = [
    ...order.filter((a) => byArea.has(a)),
    ...[...byArea.keys()].filter((a) => !order.includes(a)).sort(),
  ];

  const pages = areas.map((area) => ({
    id: area === "shell" ? "overview" : area,
    label:
      area === "shell"
        ? "Overview"
        : area.charAt(0).toUpperCase() + area.slice(1),
    description:
      hub.meta.description ||
      `Product map area: ${area}`,
    nodes: byArea.get(area) || [],
  }));

  // Flow pages for drawio
  for (const flow of hub.flows) {
    if (!flow.phases?.length) continue;
    const nodes = (flow.phases || []).map((ph) => {
      if (ph.include) {
        return {
          id: `${flow.id}.${ph.id}`,
          kind: "flow",
          title: `${ph.title || ph.id} → ${ph.include}`,
          rules: ph.rules || flow.rules,
        };
      }
      const s = hub.byId.get(ph.surface);
      return {
        id: `${flow.id}.${ph.id}`,
        kind: "flow",
        title: ph.title || s?.title || ph.surface || ph.id,
        rules: [...(ph.rules || []), ...(s?.rules || [])].filter(Boolean),
        path: s?.platforms?.nextjs?.path,
        auth: s?.auth,
        atlas: s?.platforms?.nextjs?.captureId
          ? [s.platforms.nextjs.captureId]
          : undefined,
      };
    });
    pages.push({
      id: `flow-${flow.id}`.replace(/\./g, "-"),
      label: flow.title || flow.id,
      description: flow.description || `Flow ${flow.id}`,
      nodes,
    });
  }

  return {
    version: hub.meta.version || 1,
    title: hub.meta.title || "Product Map",
    description: hub.meta.description,
    generatedFrom: "docs/product-map",
    pages,
  };
}

function hubToAtlasScreens(hub) {
  const screens = [];
  const seen = new Set();
  for (const s of hub.surfaces) {
    const nx = s.platforms?.nextjs;
    if (!nx?.captureId) continue;
    if (seen.has(nx.captureId)) continue;
    seen.add(nx.captureId);
    screens.push({
      id: nx.captureId,
      title: s.title,
      area: s.area || "other",
      path: nx.path || "/",
      auth: s.auth || "any",
      surfaceId: s.id,
      ...(nx.tab ? { tab: nx.tab } : {}),
      ...(s.notes ? { notes: s.notes } : {}),
    });
  }
  return screens;
}

function hubToAtlasPaths(hub) {
  return hub.flows
    .filter((f) => f.phases?.length)
    .map((f) => {
      const steps = expandFlowSteps(f, hub.byId, hub.flows);
      return {
        id: String(f.id).replace(/\./g, "-"),
        title: f.title || f.id,
        priority: f.priority || "",
        type: f.type || "path",
        description: f.description || "",
        steps: steps.map(({ screenId, label }) => ({ screenId, label })),
        surfaceFlowId: f.id,
      };
    })
    .filter((p) => p.steps.length);
}

function hubToAtlasTransitions(hub) {
  return (hub.transitions || []).map((t) => {
    const fromS = hub.byId.get(t.from);
    const toS = hub.byId.get(t.to);
    return {
      from:
        t.fromCaptureId ||
        fromS?.platforms?.nextjs?.captureId ||
        String(t.from).replace(/\./g, "-"),
      to:
        t.toCaptureId ||
        toS?.platforms?.nextjs?.captureId ||
        String(t.to).replace(/\./g, "-"),
      action: t.action || "",
    };
  });
}

function main() {
  const hub = loadHub();
  if (!hub.surfaces.length) {
    console.error("No surfaces — run: npm run product-map:import");
    process.exit(1);
  }

  const inv = hubToInventory(hub);
  fs.mkdirSync(UI_RULES_DIR, { recursive: true });
  fs.writeFileSync(
    INVENTORY_PATH,
    `# GENERATED from docs/product-map — do not hand-edit\n` +
      `# Source: npm run product-map:sync\n` +
      yamlStringify(inv, { lineWidth: 0 }),
    "utf8",
  );

  const { byId: rulesById, rules } = loadAllRules();
  const expand = (ids) => expandRuleRefs(ids, rulesById);
  const { byId: atlasById, screens: existingScreens } = loadAtlasManifest();

  // Prefer hub screens; keep debug screens from existing manifest if present
  const hubScreens = hubToAtlasScreens(hub);
  const hubCaptureIds = new Set(hubScreens.map((s) => s.id));
  const preserved = (existingScreens || []).filter(
    (s) => s.area === "debug" && !hubCaptureIds.has(s.id),
  );
  const allScreens = [...hubScreens, ...preserved];

  // Temporary atlas byId for reverse map (include hub screens)
  const atlasByIdFull = new Map(allScreens.map((s) => [s.id, s]));
  // Build fake inventory for reverse map
  const atlasIndex = buildNodeAtlasIndex(inv, atlasByIdFull);
  const reverse = buildReverseAtlasMap(inv, atlasIndex);
  fs.writeFileSync(
    ATLAS_LINKS_PATH,
    JSON.stringify(reverse, null, 2) + "\n",
    "utf8",
  );

  const xml = buildMxFile(inv.pages, rulesById, expand, { atlasIndex });
  fs.writeFileSync(DRAWIO_PATH, xml, "utf8");

  // Merge atlas manifest
  let base = {
    app: "Destiny 2 Build Creator",
    version: 4,
    generatedAt: new Date().toISOString().slice(0, 10),
    generatedFrom: "docs/product-map",
    baseUrlDefault: "https://127.0.0.1:3000",
    description:
      hub.meta.description ||
      "Product map generated atlas: screens, paths, transitions.",
    uses: [
      "UX teardown of compose, catalog detail, and library surfaces",
      "QA coverage for signed-out gates and signed-in detail paths",
      "Agent context for navigation across Build / Sets / Synergy / Catalog",
      "Rules traceability via product-map hub",
    ],
    productAreas: [],
  };
  if (fs.existsSync(ATLAS_MANIFEST_PATH)) {
    try {
      const prev = JSON.parse(fs.readFileSync(ATLAS_MANIFEST_PATH, "utf8"));
      base = {
        ...base,
        productAreas: prev.productAreas || base.productAreas,
        uses: prev.uses || base.uses,
        baseUrlDefault: prev.baseUrlDefault || base.baseUrlDefault,
      };
    } catch {
      /* ignore */
    }
  }

  // product areas from platforms/surfaces
  const areaSet = new Set(hub.surfaces.map((s) => s.area).filter(Boolean));
  if (!base.productAreas?.length) {
    base.productAreas = [...areaSet].sort().map((id) => ({
      id,
      label: id.charAt(0).toUpperCase() + id.slice(1),
      nav: hub.surfaces.find((s) => s.area === id && s.platforms?.nextjs?.path)
        ?.platforms?.nextjs?.path,
    }));
  }

  const manifest = {
    ...base,
    screens: allScreens,
    paths: hubToAtlasPaths(hub),
    transitions: hubToAtlasTransitions(hub),
  };
  fs.writeFileSync(
    ATLAS_MANIFEST_PATH,
    JSON.stringify(manifest, null, 2) + "\n",
    "utf8",
  );

  console.log(
    `product-map generate: ${hub.surfaces.length} surfaces, ${hub.flows.length} flows`,
  );
  console.log(`  → ${INVENTORY_PATH}`);
  console.log(`  → ${DRAWIO_PATH} (${inv.pages.length} pages, ${rules.length} rules)`);
  console.log(
    `  → ${ATLAS_MANIFEST_PATH} (${allScreens.length} screens, ${manifest.paths.length} paths)`,
  );
  console.log(
    `  → ${ATLAS_LINKS_PATH} (${Object.keys(reverse.byScreen).length} links)`,
  );
}

main();
