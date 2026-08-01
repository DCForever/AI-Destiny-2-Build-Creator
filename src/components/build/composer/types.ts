export type ComposerTab = "general" | "subclass" | "armor" | "weapon" | "finish";

export type ComposerMode = "draft" | "live";

export type ArmorSubPath = "reuse" | "create";
export type WeaponSubPath = "reuse" | "create";

/**
 * Product areas (DBR-CMPL-005): exactly four — General, Subclass,
 * Armor + Mods Sets, Weapons Set. Finish is equip/export chrome, not a fifth area.
 */
export const COMPOSER_TABS: {
  id: ComposerTab;
  label: string;
  /** True for the four product areas; false for Finish chrome. */
  isArea: boolean;
}[] = [
  { id: "general", label: "General", isArea: true },
  { id: "subclass", label: "Subclass", isArea: true },
  { id: "armor", label: "Armor + Mods Sets", isArea: true },
  { id: "weapon", label: "Weapons Set", isArea: true },
  { id: "finish", label: "Finish", isArea: false },
];

export const COMPOSER_AREA_TAB_IDS = COMPOSER_TABS.filter((t) => t.isArea).map(
  (t) => t.id,
) as ComposerTab[];
