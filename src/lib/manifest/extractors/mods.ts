import type { ModRecord, ModSlotCategory } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import { dedupeModVariantsByNameAndSlot } from "../modSearchGroups";
import type { RawInventoryItem } from "./rawTypes";
import { asRawSandboxPerk } from "./rawTypes";
import { getRaw, iterItems, projectBase } from "./common";

const ITEM_TYPE_MOD = 19;
const MOD_CAT_PREFIX = "enhancements.";

/** Tooltip that only explains multi-copy stacking (not the mod's effect). */
const STACKING_TOOLTIP_RE =
  /multiple copies of this mod|stacked to increase the potency|diminishing returns for each additional copy/i;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isModItem(item: RawInventoryItem): boolean {
  return (
    item.itemType === ITEM_TYPE_MOD &&
    (item.plug?.plugCategoryIdentifier ?? "").startsWith(MOD_CAT_PREFIX)
  );
}

function toModSlotCategory(cat: string): ModSlotCategory | null {
  if (/enhancements\.(v2_)?head/.test(cat)) return "helmet";
  if (/enhancements\.(v2_)?arms/.test(cat)) return "arms";
  if (/enhancements\.(v2_)?chest/.test(cat)) return "chest";
  if (/enhancements\.(v2_)?legs/.test(cat)) return "legs";
  if (/enhancements\.(v2_)?class/.test(cat)) return "classItem";
  if (/tuning/.test(cat)) return "tuning";
  if (/enhancements\.general/.test(cat) || /enhancements\.universal/.test(cat)) return "general";
  return null;
}

function resolveEnergyCost(item: RawInventoryItem): number | null {
  const cost = item.plug?.energyCost?.energyCost;
  return typeof cost === "number" ? cost : null;
}

function isStackingOnlyTooltip(text: string): boolean {
  return STACKING_TOOLTIP_RE.test(text);
}

/** Collect sandbox perk effect lines for all perk hashes on the plug. */
function sandboxPerkDescriptions(
  item: RawInventoryItem,
  sandboxPerks: RawTable,
): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const entry of item.perks ?? []) {
    const hash = entry.perkHash;
    if (hash == null) continue;
    const sp = asRawSandboxPerk(getRaw(sandboxPerks, hash));
    const d = sp?.displayProperties.description?.trim() ?? "";
    if (!d || seen.has(d)) continue;
    seen.add(d);
    out.push(d);
  }
  return out;
}

function tooltipStrings(item: RawInventoryItem): {
  effect: string[];
  stacking: string[];
} {
  const effect: string[] = [];
  const stacking: string[] = [];
  for (const tip of item.tooltipNotifications ?? []) {
    const t = tip.displayString?.trim() ?? "";
    if (!t) continue;
    if (isStackingOnlyTooltip(t)) stacking.push(t);
    else effect.push(t);
  }
  return { effect, stacking };
}

/**
 * Build the player-facing mod description.
 *
 * Bungie often leaves `displayProperties.description` empty. The **effect**
 * lives on DestinySandboxPerk; `tooltipNotifications` frequently only carry
 * multi-copy stacking notes (e.g. Focusing Strike). Prefer sandbox effect text
 * first so we don't show stacking boilerplate as the whole description.
 *
 * Order: displayProperties → sandbox perks → non-stacking tooltips → stacking tooltips.
 */
export function resolveModDescription(
  item: RawInventoryItem,
  sandboxPerks: RawTable,
): string {
  const display = item.displayProperties.description?.trim() ?? "";
  if (display) return display;

  const sandbox = sandboxPerkDescriptions(item, sandboxPerks);
  if (sandbox.length > 0) return sandbox.join(" ");

  const tips = tooltipStrings(item);
  if (tips.effect.length > 0) return tips.effect.join(" ");
  if (tips.stacking.length > 0) return tips.stacking.join(" ");

  return "";
}

async function extractMods(loadTable: LoadTable): Promise<ModRecord[]> {
  const [itemTable, sandboxPerks] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
  ]);
  const result: ModRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isModItem(item)) continue;

    const cat = item.plug?.plugCategoryIdentifier ?? "";
    const slotCategory = toModSlotCategory(cat);
    if (!slotCategory) continue;

    result.push({
      ...projectBase(item),
      description: resolveModDescription(item, sandboxPerks),
      slotCategory,
      energyCost: resolveEnergyCost(item),
    });
  }

  // Drop cheap artifact discount plugs when a higher-cost "normal" copy exists
  // (same name + armor slot category) — matches DIM catalog behavior.
  return dedupeModVariantsByNameAndSlot(result);
}

export const modsExtractor: Extractor<"mods"> = {
  store: "mods",
  extract: (loadTable) => extractMods(loadTable),
};
