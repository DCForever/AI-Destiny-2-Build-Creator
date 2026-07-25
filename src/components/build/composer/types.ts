export type ComposerTab = "general" | "subclass" | "armor" | "weapon" | "finish";

export type ComposerMode = "draft" | "live";

export type ArmorSubPath = "reuse" | "create";
export type WeaponSubPath = "reuse" | "create";

/** Same tab strip for default and non-default variants (FR-018). */
export const COMPOSER_TABS: { id: ComposerTab; label: string }[] = [
  { id: "general", label: "General" },
  { id: "subclass", label: "Subclass" },
  { id: "armor", label: "Armor & Mod Set" },
  { id: "weapon", label: "Weapon Set" },
  { id: "finish", label: "Finish" },
];
