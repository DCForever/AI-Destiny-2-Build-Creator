#!/usr/bin/env node
/**
 * Scaffold a flow into flows.yaml
 * Usage: node scripts/product-map/add-flow.mjs --id flow.example --title "Example"
 */
import fs from "node:fs";
import { parse as parseYaml, stringify as yamlStringify } from "yaml";
import { FLOWS_PATH } from "./lib/paths.mjs";

function arg(name, def) {
  const i = process.argv.indexOf(`--${name}`);
  if (i >= 0 && process.argv[i + 1]) return process.argv[i + 1];
  return def;
}

const id = arg("id");
const title = arg("title", id);
const type = arg("type", "subflow");
const priority = arg("priority", "P1");

if (!id) {
  console.error(
    "Usage: npm run product-map:add-flow -- --id flow.example --title \"Example\" [--type subflow] [--priority P1]",
  );
  process.exit(1);
}

const doc = fs.existsSync(FLOWS_PATH)
  ? parseYaml(fs.readFileSync(FLOWS_PATH, "utf8"))
  : { flows: [] };
const flows = doc.flows || [];
if (flows.some((f) => f.id === id)) {
  console.error(`Flow already exists: ${id}`);
  process.exit(1);
}

flows.push({
  id,
  title,
  type,
  priority,
  phases: [
    {
      id: "start",
      title: "Start (edit me)",
      surface: null,
    },
  ],
});

fs.writeFileSync(
  FLOWS_PATH,
  yamlStringify({ flows }, { lineWidth: 0 }),
  "utf8",
);
console.log(`Added flow ${id} → ${FLOWS_PATH}`);
console.log("Next: set phase.surface ids, npm run product-map:sync");
