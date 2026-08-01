#!/usr/bin/env node
/**
 * Scaffold a surface into surfaces.yaml
 * Usage: node scripts/product-map/add-surface.mjs --id build.foo --title "Foo" --area build
 */
import fs from "node:fs";
import { parse as parseYaml, stringify as yamlStringify } from "yaml";
import { SURFACES_PATH } from "./lib/paths.mjs";

function arg(name, def) {
  const i = process.argv.indexOf(`--${name}`);
  if (i >= 0 && process.argv[i + 1]) return process.argv[i + 1];
  return def;
}

const id = arg("id");
const title = arg("title", id);
const area = arg("area", id?.split(".")[0] || "other");
const kind = arg("kind", "screen");
const pathVal = arg("path");
const captureId = arg("captureId", id?.replace(/\./g, "-"));
const parent = arg("parent", null);

if (!id) {
  console.error(
    "Usage: npm run product-map:add-surface -- --id area.name --title \"Title\" [--area build] [--path /x] [--captureId x] [--parent id]",
  );
  process.exit(1);
}

const doc = fs.existsSync(SURFACES_PATH)
  ? parseYaml(fs.readFileSync(SURFACES_PATH, "utf8"))
  : { surfaces: [] };
const surfaces = doc.surfaces || [];
if (surfaces.some((s) => s.id === id)) {
  console.error(`Surface already exists: ${id}`);
  process.exit(1);
}

/** @type {any} */
const surface = {
  id,
  title,
  kind,
  area,
  parent: parent || null,
  status: "active",
  rules: [],
};
if (pathVal || captureId) {
  surface.platforms = {
    nextjs: {
      ...(pathVal ? { path: pathVal } : {}),
      ...(captureId ? { captureId } : {}),
    },
  };
}

surfaces.push(surface);
fs.writeFileSync(
  SURFACES_PATH,
  yamlStringify({ surfaces }, { lineWidth: 0 }),
  "utf8",
);
console.log(`Added surface ${id} → ${SURFACES_PATH}`);
console.log("Next: attach rules, wire flow phase, npm run product-map:sync");
