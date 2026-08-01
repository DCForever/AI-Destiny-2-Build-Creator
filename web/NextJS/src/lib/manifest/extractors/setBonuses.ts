import type { SetBonusRecord } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import { asRawItemSet, asRawSandboxPerk } from "./rawTypes";
import { normalizeName } from "../normalize";
import { getRaw } from "./common";

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function buildSetPerk(
  requiredSetCount: number,
  sandboxPerkHash: number,
  sandboxPerks: RawTable,
): { requiredCount: number; name: string; description: string } {
  const sp = asRawSandboxPerk(getRaw(sandboxPerks, sandboxPerkHash));
  return {
    requiredCount: requiredSetCount,
    name: sp?.displayProperties.name ?? "",
    description: sp?.displayProperties.description ?? "",
  };
}

async function extractSetBonuses(loadTable: LoadTable): Promise<SetBonusRecord[]> {
  const [setTable, sandboxPerks] = await Promise.all([
    loadTable("DestinyEquipableItemSetDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
  ]);

  const result: SetBonusRecord[] = [];

  for (const v of Object.values(setTable)) {
    const set = asRawItemSet(v);
    if (!set || set.redacted) continue;
    if (!set.displayProperties.name.trim()) continue;

    result.push({
      hash: set.hash,
      name: set.displayProperties.name,
      searchName: normalizeName(set.displayProperties.name),
      icon: set.displayProperties.icon ?? null,
      perks: set.setPerks.map((p) =>
        buildSetPerk(p.requiredSetCount, p.sandboxPerkHash, sandboxPerks),
      ),
      itemHashes: set.setItems,
    });
  }

  return result;
}

export const setBonusesExtractor: Extractor<"set-bonuses"> = {
  store: "set-bonuses",
  extract: (loadTable) => extractSetBonuses(loadTable),
};
