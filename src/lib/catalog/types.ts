export type CatalogScope = "all" | "owned";

export type CatalogItem = {
  hash: number;
  name: string;
  icon: string | null;
  slot?: string;
  element?: string;
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
