/**
 * Rebuild entity stores + perk→weapon index for the on-disk manifest version.
 * Usage: npx tsx scripts/rebuild-entity-cache.mts
 */
import { createEntityCache } from "../src/lib/manifest/entityCache.ts";
import { createManifestService } from "../src/lib/manifest/manifestService.ts";
import { readFile } from "node:fs/promises";
import path from "node:path";

const versionPath = path.join(process.cwd(), ".cache", "current-version.json");
const { version } = JSON.parse(await readFile(versionPath, "utf8")) as {
  version: string;
};

console.log("Rebuilding entity cache for", version);
const manifest = createManifestService();
const entityCache = createEntityCache({
  version,
  loadRawTable: (table) => manifest.loadRawTable(version, table),
});
const meta = await entityCache.rebuild(version);
console.log("Done:", JSON.stringify(meta, null, 2));
