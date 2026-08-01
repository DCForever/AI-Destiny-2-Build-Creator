import type { EntityStores } from "../types/stores";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import { asRawStatDef } from "./rawTypes";

type StatRecord = EntityStores["stats"][number];
type LoadTable = (table: RawTableName) => Promise<RawTable>;

async function extractStats(loadTable: LoadTable): Promise<StatRecord[]> {
  const statTable = await loadTable("DestinyStatDefinition");
  const result: StatRecord[] = [];

  for (const v of Object.values(statTable)) {
    const stat = asRawStatDef(v);
    if (!stat || stat.redacted) continue;
    if (!stat.displayProperties.name.trim()) continue;

    result.push({
      hash: stat.hash,
      name: stat.displayProperties.name,
      description: stat.displayProperties.description,
    });
  }

  return result;
}

export const statsExtractor: Extractor<"stats"> = {
  store: "stats",
  extract: (loadTable) => extractStats(loadTable),
};
