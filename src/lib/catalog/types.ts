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
  isExotic: boolean;
  owned: boolean;
  ownedCount: number;
};

export type CatalogFilterParams = {
  scope: CatalogScope;
  q?: string;
  slot?: string;
  itemType?: string;
  frame?: string;
  className?: string;
  limit?: number;
};
