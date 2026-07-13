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
  itemType?: string;
  frame?: string;
  className?: string;
  perk?: string;
  originTrait?: string;
  setBonus?: string;
  limit?: number;
  weaponHashAllowlist?: Set<number>;
  armorHashAllowlist?: Set<number>;
};
