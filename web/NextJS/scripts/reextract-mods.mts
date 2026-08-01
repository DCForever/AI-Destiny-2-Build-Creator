import fs from "node:fs";
import path from "node:path";

import { modsExtractor } from "../src/lib/manifest/extractors/mods.ts";

const ver =
  process.argv[2] ??
  fs
    .readdirSync(path.join(".cache", "entities"))
    .filter((d) => !d.startsWith("."))
    .sort()
    .at(-1);

if (!ver) {
  console.error("No entity cache version found");
  process.exit(1);
}

const base = path.join(".cache", "manifest", ver);
async function loadTable(name: string) {
  const p = path.join(base, `${name}.json`);
  if (!fs.existsSync(p)) throw new Error(`Missing ${p}`);
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

const records = await modsExtractor.extract(loadTable as never);
const out = path.join(".cache", "entities", ver, "mods.json");
fs.writeFileSync(out, JSON.stringify(records));
const withDesc = records.filter((r) => r.description?.trim()).length;
console.log(
  JSON.stringify({
    ver,
    total: records.length,
    withDesc,
    sample: records.find((r) => r.name === "Heavy Ammo Finder")?.description?.slice(0, 120),
  }),
);
