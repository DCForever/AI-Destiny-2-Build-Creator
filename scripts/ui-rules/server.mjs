#!/usr/bin/env node
/**
 * Companion server: browse UI↔rules, edit rule bodies, write back markdown, regenerate draw.io.
 *
 * Usage: node scripts/ui-rules/server.mjs
 * Open:  http://127.0.0.1:4174
 *
 * Never auto-commits.
 */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { parse as parseYaml } from "yaml";
import { buildMxFile } from "./lib/drawio.mjs";
import {
  expandRuleRefs,
  loadAllRules,
} from "./lib/parse-rules.mjs";
import {
  COMPANION_DIR,
  DRAWIO_PATH,
  INVENTORY_PATH,
  UI_RULES_DIR,
} from "./lib/paths.mjs";
import { writeRuleBack } from "./lib/writeback.mjs";

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
};

function loadInventory() {
  return parseYaml(fs.readFileSync(INVENTORY_PATH, "utf8"));
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

function serveStatic(req, res, urlPath) {
  let rel = urlPath === "/" ? "/index.html" : urlPath;
  rel = rel.replace(/\?.*$/, "");
  // prevent path escape
  const abs = path.normalize(path.join(COMPANION_DIR, rel));
  if (!abs.startsWith(COMPANION_DIR)) {
    res.writeHead(403).end("Forbidden");
    return;
  }
  // also allow reading inventory / drawio from parent ui-rules
  let file = abs;
  if (rel === "/inventory.yaml") {
    file = INVENTORY_PATH;
  } else if (rel === "/ui-map.drawio") {
    file = DRAWIO_PATH;
  }

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

function regenerate() {
  const inv = loadInventory();
  const { byId } = loadAllRules();
  const expand = (ids) => expandRuleRefs(ids, byId);
  const xml = buildMxFile(inv.pages ?? [], byId, expand);
  fs.writeFileSync(DRAWIO_PATH, xml, "utf8");
  return { path: "docs/ui-rules/ui-map.drawio", pages: (inv.pages ?? []).length };
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
      // optional regenerate
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

    if (pathname === "/api/node-rules" && req.method === "GET") {
      // Resolve expanded rules for a node id
      const nodeId = url.searchParams.get("id");
      const inv = loadInventory();
      const { byId } = loadAllRules();
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
      return json(res, 200, { node: found, ruleIds: ids, rules });
    }

    // static companion
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
  console.log(`UI Rules companion: http://${HOST}:${PORT}`);
  console.log(`Inventory: ${INVENTORY_PATH}`);
  console.log(`Write-back enabled (no auto-commit).`);
});
