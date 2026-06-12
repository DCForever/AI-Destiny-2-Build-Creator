import type { ArtifactRecord, ArtifactPerkRecord } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import { asRawArtifact, asRawInventoryItem } from "./rawTypes";
import { normalizeName } from "../normalize";
import { getRaw } from "./common";

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function buildArtifactPerks(
  tiers: { items: { itemHash: number }[] }[],
  itemTable: RawTable,
): ArtifactPerkRecord[] {
  const perks: ArtifactPerkRecord[] = [];

  for (let col = 0; col < tiers.length; col++) {
    const tier = tiers[col];
    for (let row = 0; row < tier.items.length; row++) {
      const perkItem = asRawInventoryItem(getRaw(itemTable, tier.items[row].itemHash));
      if (!perkItem || !perkItem.displayProperties.name.trim()) continue;
      perks.push({
        hash: perkItem.hash,
        name: perkItem.displayProperties.name,
        searchName: normalizeName(perkItem.displayProperties.name),
        icon: perkItem.displayProperties.icon ?? null,
        description: perkItem.displayProperties.description,
        column: col,
        row,
      });
    }
  }

  return perks;
}

async function extractArtifacts(loadTable: LoadTable): Promise<ArtifactRecord[]> {
  const [artifactTable, itemTable] = await Promise.all([
    loadTable("DestinyArtifactDefinition"),
    loadTable("DestinyInventoryItemDefinition"),
  ]);

  const result: ArtifactRecord[] = [];

  for (const v of Object.values(artifactTable)) {
    const artifact = asRawArtifact(v);
    if (!artifact || artifact.redacted) continue;
    if (!artifact.displayProperties.name.trim()) continue;

    result.push({
      hash: artifact.hash,
      name: artifact.displayProperties.name,
      searchName: normalizeName(artifact.displayProperties.name),
      icon: artifact.displayProperties.icon ?? null,
      description: artifact.displayProperties.description,
      perks: buildArtifactPerks(artifact.tiers, itemTable),
    });
  }

  return result;
}

export const artifactsExtractor: Extractor<"artifacts"> = {
  store: "artifacts",
  extract: (loadTable) => extractArtifacts(loadTable),
};
