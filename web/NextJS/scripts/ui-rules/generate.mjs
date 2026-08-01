#!/usr/bin/env node
/**
 * Generate docs/ui-rules/ui-map.drawio from inventory.yaml + rule docs.
 *
 * Usage: node scripts/ui-rules/generate.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { parse as parseYaml } from "yaml";
import {
  buildNodeAtlasIndex,
  buildReverseAtlasMap,
  loadAtlasManifest,
} from "./lib/atlas-link.mjs";
import { buildMxFile } from "./lib/drawio.mjs";
import { expandRuleRefs, loadAllRules } from "./lib/parse-rules.mjs";
import {
  ATLAS_UI_RULES_LINKS_PATH,
  DRAWIO_PATH,
  INVENTORY_PATH,
  UI_RULES_DIR,
} from "./lib/paths.mjs";

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
  const { byId: atlasById, screens } = loadAtlasManifest();
  const atlasIndex = buildNodeAtlasIndex(inv, atlasById);

  // Validate refs
  let missing = 0;
  let atlasDirect = 0;
  const walk = (nodes) => {
    for (const n of nodes ?? []) {
      for (const id of expand(n.rules ?? [])) {
        if (!byId.has(id)) {
          console.warn(`  warn: ${n.id} → unknown rule ${id}`);
          missing++;
        }
      }
      const link = atlasIndex.get(n.id);
      if (link?.ids?.length && !link.inheritedFrom) atlasDirect++;
      walk(n.children);
    }
  };
  for (const p of pages) walk(p.nodes);

  const xml = buildMxFile(pages, byId, expand, { atlasIndex });
  fs.mkdirSync(UI_RULES_DIR, { recursive: true });
  fs.writeFileSync(DRAWIO_PATH, xml, "utf8");

  const reverse = buildReverseAtlasMap(inv, atlasIndex);
  fs.mkdirSync(path.dirname(ATLAS_UI_RULES_LINKS_PATH), { recursive: true });
  fs.writeFileSync(
    ATLAS_UI_RULES_LINKS_PATH,
    JSON.stringify(reverse, null, 2) + "\n",
    "utf8",
  );

  console.log(
    `Wrote ${DRAWIO_PATH} (${pages.length} pages, ${rules.length} rules, ${missing} missing rule refs, ${atlasDirect} nodes with direct Atlas links / ${screens.length} atlas screens)`,
  );
  console.log(
    `Wrote ${ATLAS_UI_RULES_LINKS_PATH} (${Object.keys(reverse.byScreen).length} atlas→node links)`,
  );
}

main();
