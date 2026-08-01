#!/usr/bin/env node
/**
 * Companion server: UI↔rules + Atlas screenshots, edit rule bodies, write-back, regenerate draw.io.
 *
 * Usage: node scripts/ui-rules/server.mjs
 * Open:  http://127.0.0.1:4174
 *
 * Serves Atlas captures from docs/atlas/screenshots (gitignored; run atlas:capture first).
 * Never auto-commits.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { parse as parseYaml } from "yaml";
import { REPO_ROOT } from "./lib/paths.mjs";
import {
  ATLAS_DIR,
  ATLAS_SHOTS_DIR,
  buildNodeAtlasIndex,
  buildReverseAtlasMap,
  loadAtlasManifest,
  shotsPayloadForNode,
} from "./lib/atlas-link.mjs";
import { buildMxFile } from "./lib/drawio.mjs";
import {
  expandRuleRefs,
  loadAllRules,
} from "./lib/parse-rules.mjs";
import {
  ATLAS_UI_RULES_LINKS_PATH,
  COMPANION_DIR,
  DRAWIO_PATH,
  INVENTORY_PATH,
} from "./lib/paths.mjs";
import { writeRuleBack } from "./lib/writeback.mjs";
import {
  expandFlowTree,
  loadHub,
} from "../product-map/lib/load-hub.mjs";
import {
  addPhaseToFlow,
  attachRulesToSurface,
  ensureSurface,
} from "../product-map/lib/write-hub.mjs";

const PORT = Number(process.env.UI_RULES_PORT || 4174);
const HOST = process.env.UI_RULES_HOST || "127.0.0.1";

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".yaml": "text/yaml; charset=utf-8",
  ".yml": "text/yaml; charset=utf-8",
  ".drawio": "application/xml; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
};

function loadInventory() {
  return parseYaml(fs.readFileSync(INVENTORY_PATH, "utf8"));
}

function atlasContext() {
  const inv = loadInventory();
  const { byId, screens, productAreas, raw } = loadAtlasManifest();
  const index = buildNodeAtlasIndex(inv, byId);
  return { inv, byId, screens, productAreas, raw, index };
}

function json(res, status, body) {
  const data = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(data);
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks).toString("utf8");
  if (!raw) return null;
  return JSON.parse(raw);
}

/**
 * @param {string} file
 * @param {import('http').ServerResponse} res
 */
function streamFile(file, res) {
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404).end("Not found");
    return;
  }
  const ext = path.extname(file);
  res.writeHead(200, {
    "Content-Type": MIME[ext] || "application/octet-stream",
    "Cache-Control": "no-store",
  });
  fs.createReadStream(file).pipe(res);
}

function serveStatic(req, res, urlPath) {
  let rel = urlPath === "/" ? "/index.html" : urlPath;
  rel = rel.replace(/\?.*$/, "");

  // Atlas assets: /atlas/...
  if (rel === "/atlas" || rel.startsWith("/atlas/")) {
    const sub = rel === "/atlas" ? "" : rel.slice("/atlas/".length);
    const file = path.normalize(path.join(ATLAS_DIR, sub));
    if (!file.startsWith(ATLAS_DIR)) {
      res.writeHead(403).end("Forbidden");
      return;
    }
    return streamFile(file, res);
  }

  const abs = path.normalize(path.join(COMPANION_DIR, rel));
  if (!abs.startsWith(COMPANION_DIR)) {
    res.writeHead(403).end("Forbidden");
    return;
  }
  let file = abs;
  if (rel === "/inventory.yaml") {
    file = INVENTORY_PATH;
  } else if (rel === "/ui-map.drawio") {
    file = DRAWIO_PATH;
  }
  return streamFile(file, res);
}

function regenerate() {
  // Prefer product-map hub generator (structure SSoT)
  const r = spawnSync(
    process.execPath,
    [path.join(REPO_ROOT, "scripts/product-map/generate.mjs")],
    { cwd: REPO_ROOT, stdio: "pipe", encoding: "utf8" },
  );
  if (r.status === 0) {
    const inv = loadInventory();
    return {
      path: "docs/ui-rules/ui-map.drawio",
      pages: (inv.pages ?? []).length,
      via: "product-map",
    };
  }
  if (r.stderr) console.error(r.stderr);
  // Fallback: inventory-only drawio
  const inv = loadInventory();
  const { byId } = loadAllRules();
  const { byId: atlasById } = loadAtlasManifest();
  const atlasIndex = buildNodeAtlasIndex(inv, atlasById);
  const expand = (ids) => expandRuleRefs(ids, byId);
  const xml = buildMxFile(inv.pages ?? [], byId, expand, { atlasIndex });
  fs.writeFileSync(DRAWIO_PATH, xml, "utf8");
  const reverse = buildReverseAtlasMap(inv, atlasIndex);
  fs.writeFileSync(
    ATLAS_UI_RULES_LINKS_PATH,
    JSON.stringify(reverse, null, 2) + "\n",
    "utf8",
  );
  return {
    path: "docs/ui-rules/ui-map.drawio",
    pages: (inv.pages ?? []).length,
    atlasLinks: Object.keys(reverse.byScreen).length,
  };
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://${HOST}:${PORT}`);
  const { pathname } = url;

  try {
    if (pathname === "/api/health") {
      return json(res, 200, { ok: true });
    }

    if (pathname === "/api/inventory" && req.method === "GET") {
      return json(res, 200, loadInventory());
    }

    if (pathname === "/api/atlas" && req.method === "GET") {
      const { screens, productAreas, raw, index } = atlasContext();
      const shotCount = fs.existsSync(ATLAS_SHOTS_DIR)
        ? fs.readdirSync(ATLAS_SHOTS_DIR).filter((f) => f.endsWith(".png")).length
        : 0;
      let linked = 0;
      for (const v of index.values()) {
        if (v.ids.length && !v.inheritedFrom) linked++;
      }
      return json(res, 200, {
        screenCount: screens.length,
        shotCount,
        nodesWithDirectAtlas: linked,
        productAreas,
        screens,
        manifestVersion: raw?.version,
        captureHint:
          shotCount === 0
            ? "No PNGs under docs/atlas/screenshots — run npm run atlas:capture"
            : null,
      });
    }

    if (pathname === "/api/atlas/node" && req.method === "GET") {
      const nodeId = url.searchParams.get("id");
      if (!nodeId) {
        return json(res, 400, { ok: false, message: "id required" });
      }
      const { index, byId } = atlasContext();
      return json(res, 200, shotsPayloadForNode(nodeId, index, byId));
    }

    if (pathname === "/api/rules" && req.method === "GET") {
      const { rules } = loadAllRules();
      return json(res, 200, { rules });
    }

    if (pathname.startsWith("/api/rules/") && req.method === "GET") {
      const id = decodeURIComponent(pathname.slice("/api/rules/".length));
      const { byId } = loadAllRules();
      const rule = byId.get(id);
      if (!rule) return json(res, 404, { ok: false, message: "Not found" });
      return json(res, 200, rule);
    }

    if (pathname.startsWith("/api/rules/") && req.method === "PUT") {
      const id = decodeURIComponent(pathname.slice("/api/rules/".length));
      const payload = await readBody(req);
      const body = payload?.body;
      const title = payload?.title;
      if (typeof body !== "string") {
        return json(res, 400, { ok: false, message: "body string required" });
      }
      const result = writeRuleBack(id, body, { title });
      if (!result.ok) return json(res, 400, result);
      if (payload?.regenerate) {
        try {
          result.drawio = regenerate();
        } catch (e) {
          result.regenerateError = String(e);
        }
      }
      return json(res, 200, result);
    }

    if (pathname === "/api/generate" && req.method === "POST") {
      const out = regenerate();
      return json(res, 200, { ok: true, ...out });
    }

    if (pathname === "/api/sync" && req.method === "POST") {
      const r = spawnSync(
        process.execPath,
        [path.join(REPO_ROOT, "scripts/product-map/sync.mjs")],
        { cwd: REPO_ROOT, stdio: "pipe", encoding: "utf8" },
      );
      return json(res, r.status === 0 ? 200 : 500, {
        ok: r.status === 0,
        stdout: r.stdout,
        stderr: r.stderr,
      });
    }

    if (pathname === "/api/hub" && req.method === "GET") {
      const hub = loadHub();
      return json(res, 200, {
        meta: hub.meta,
        platforms: hub.platforms,
        surfaceCount: hub.surfaces.length,
        flowCount: hub.flows.length,
        transitionCount: hub.transitions.length,
        surfaces: hub.surfaces,
        flows: hub.flows,
        transitions: hub.transitions,
      });
    }

    if (pathname === "/api/hub/flows" && req.method === "GET") {
      const hub = loadHub();
      const flows = hub.flows.map((f) => ({
        ...f,
        tree: expandFlowTree(f, hub.byId, hub.flows),
      }));
      return json(res, 200, { flows });
    }

    if (pathname === "/api/hub/surfaces" && req.method === "GET") {
      const hub = loadHub();
      return json(res, 200, { surfaces: hub.surfaces });
    }

    if (pathname === "/api/hub/attach-rules" && req.method === "PUT") {
      const payload = await readBody(req);
      const surfaceId = payload?.surfaceId;
      const rules = payload?.rules;
      if (!surfaceId || !Array.isArray(rules)) {
        return json(res, 400, {
          ok: false,
          message: "surfaceId and rules[] required",
        });
      }
      const result = attachRulesToSurface(surfaceId, rules);
      if (!result.ok) return json(res, 400, result);
      if (payload?.regenerate) {
        try {
          result.drawio = regenerate();
        } catch (e) {
          result.regenerateError = String(e);
        }
      }
      return json(res, 200, result);
    }

    if (pathname === "/api/hub/add-phase" && req.method === "POST") {
      const payload = await readBody(req);
      const result = addPhaseToFlow(payload?.flowId, payload?.phase || {});
      if (!result.ok) return json(res, 400, result);
      if (payload?.regenerate) {
        try {
          result.drawio = regenerate();
        } catch (e) {
          result.regenerateError = String(e);
        }
      }
      return json(res, 200, result);
    }

    if (pathname === "/api/hub/add-surface" && req.method === "POST") {
      const payload = await readBody(req);
      const result = ensureSurface(payload?.surface || payload || {});
      if (!result.ok) return json(res, 400, result);
      if (payload?.regenerate) {
        try {
          result.drawio = regenerate();
        } catch (e) {
          result.regenerateError = String(e);
        }
      }
      return json(res, 200, result);
    }

    if (pathname === "/api/atlas/manifest" && req.method === "GET") {
      if (!fs.existsSync(path.join(ATLAS_DIR, "manifest.json"))) {
        return json(res, 404, { ok: false, message: "manifest missing" });
      }
      return json(
        res,
        200,
        JSON.parse(fs.readFileSync(path.join(ATLAS_DIR, "manifest.json"), "utf8")),
      );
    }

    if (pathname === "/api/node-rules" && req.method === "GET") {
      const nodeId = url.searchParams.get("id");
      const inv = loadInventory();
      const { byId } = loadAllRules();
      const { index, byId: atlasById } = atlasContext();
      /** @type {any} */
      let found = null;
      const walk = (nodes) => {
        for (const n of nodes ?? []) {
          if (n.id === nodeId) found = n;
          walk(n.children);
        }
      };
      for (const p of inv.pages ?? []) walk(p.nodes);
      if (!found) return json(res, 404, { ok: false, message: "Node not found" });
      const ids = expandRuleRefs(found.rules ?? [], byId);
      const rules = ids.map((id) => byId.get(id) || { id, missing: true });
      const atlas = shotsPayloadForNode(nodeId, index, atlasById);
      return json(res, 200, { node: found, ruleIds: ids, rules, atlas });
    }

    if (req.method === "GET" || req.method === "HEAD") {
      return serveStatic(req, res, pathname);
    }

    json(res, 405, { ok: false, message: "Method not allowed" });
  } catch (e) {
    console.error(e);
    json(res, 500, { ok: false, message: String(e) });
  }
});

if (!fs.existsSync(COMPANION_DIR)) {
  console.error(`Companion missing at ${COMPANION_DIR}`);
  process.exit(1);
}

server.listen(PORT, HOST, () => {
  console.log(`UI Rules + Atlas companion: http://${HOST}:${PORT}`);
  console.log(`Inventory: ${INVENTORY_PATH}`);
  console.log(`Atlas shots: ${ATLAS_SHOTS_DIR}`);
  console.log(`Write-back enabled (no auto-commit).`);
});
