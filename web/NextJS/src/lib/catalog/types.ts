export type CatalogScope = "all" | "owned";

export type CatalogItem = {
  hash: number;
  name: string;
  icon: string | null;
  slot?: string;
  element?: string;
  /** Primary / Special / Heavy — weapons only. */
  ammo?: string;
  itemTypeName?: string;
  frame?: string;
  classType?: string;
  setBonusName?: string;
  setBonusHash?: number;
  /** Bungie relative icon for the equipable item set, when known. */
  setBonusIcon?: string | null;
  /** 2pc / 4pc effects — item-level, not per owned copy. */
  setBonusPerks?: Array<{
    requiredCount: number;
    name: string;
    description: string;
  }>;
  isExotic: boolean;
  owned: boolean;
  ownedCount: number;
  instancesHref?: string;
  /** Exotic intrinsic or picker description for display/search projection */
  description?: string;
};

/** Client-side result grouping dimensions (multi-select combines with ·). */
export type CatalogGroupDimension =
  | "element"
  | "ammo"
  | "archetype"
  | "frame"
  | "slot"
  | "class";

export type CatalogFilterParams = {
  scope: CatalogScope;
  q?: string;
  slot?: string;
  /** Single item type (legacy); prefer itemTypes for multi-select. */
  itemType?: string;
  /** Multi-select weapon types (OR within set). */
  itemTypes?: string[];
  /** Single frame (legacy); prefer frames for multi-select. */
  frame?: string;
  frames?: string[];
  /** Multi-select damage types (OR). */
  elements?: string[];
  /** Multi-select ammo types Primary/Special/Heavy (OR). */
  ammos?: string[];
  className?: string;
  perk?: string;
  originTrait?: string;
  setBonus?: string;
  limit?: number;
  weaponHashAllowlist?: Set<number>;
  armorHashAllowlist?: Set<number>;
};
