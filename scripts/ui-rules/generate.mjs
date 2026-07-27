#!/usr/bin/env node
/**
 * Generate docs/ui-rules/ui-map.drawio from inventory.yaml + rule docs.
 *
 * Usage: node scripts/ui-rules/generate.mjs
 */
import fs from "node:fs";
import { parse as parseYaml } from "yaml";
import { buildMxFile } from "./lib/drawio.mjs";
import { expandRuleRefs, loadAllRules } from "./lib/parse-rules.mjs";
import { DRAWIO_PATH, INVENTORY_PATH, UI_RULES_DIR } from "./lib/paths.mjs";

function main() {
  if (!fs.existsSync(INVENTORY_PATH)) {
    console.error(`Missing inventory: ${INVENTORY_PATH}`);
    process.exit(1);
  }

  const inv = parseYaml(fs.readFileSync(INVENTORY_PATH, "utf8"));
  const pages = inv.pages ?? [];
  if (!pages.length) {
    console.error("inventory.yaml has no pages");
    process.exit(1);
  }

  const { byId, rules } = loadAllRules();
  const expand = (ids) => expandRuleRefs(ids, byId);

  // Validate refs
  let missing = 0;
  const walk = (nodes) => {
    for (const n of nodes ?? []) {
      for (const id of expand(n.rules ?? [])) {
        if (!byId.has(id)) {
          console.warn(`  warn: ${n.id} → unknown rule ${id}`);
          missing++;
        }
      }
      walk(n.children);
    }
  };
  for (const p of pages) walk(p.nodes);

  const xml = buildMxFile(pages, byId, expand);
  fs.mkdirSync(UI_RULES_DIR, { recursive: true });
  fs.writeFileSync(DRAWIO_PATH, xml, "utf8");

  console.log(
    `Wrote ${DRAWIO_PATH} (${pages.length} pages, ${rules.length} rules loaded, ${missing} missing refs)`,
  );
}

main();
