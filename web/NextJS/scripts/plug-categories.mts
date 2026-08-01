import { getServices } from "../src/lib/services.ts";
import { getRaw } from "../src/lib/manifest/extractors/common.ts";
import { asRawInventoryItem } from "../src/lib/manifest/extractors/rawTypes.ts";

const hashes = [
  3048246338, // Arrowhead
  3966296580, // Poly
  3198323828, // Keep Away
  838873202, // Encore
  2889515627, // Adagio
  2799030358, // Desperate Measures
  3920852688, // Rapid-Fire Frame
  1673863459, // Roar of Battle
];
const { manifest } = await getServices();
const v = (await manifest.getStatus()).cachedVersion!;
const table = await manifest.loadRawTable(v, "DestinyInventoryItemDefinition");
for (const h of hashes) {
  const item = asRawInventoryItem(getRaw(table, h));
  console.log({
    h,
    name: item?.displayProperties?.name,
    cat: item?.plug?.plugCategoryIdentifier,
    type: item?.itemTypeDisplayName,
  });
}
