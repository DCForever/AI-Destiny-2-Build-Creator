export type NamedCatalogFilter = {
  perk?: string;
  originTrait?: string;
  setBonus?: string;
};

export function emptyFilterMessage(filter: NamedCatalogFilter): string | null {
  if (filter.perk?.trim()) return `No matching perk: ${filter.perk.trim()}`;
  if (filter.originTrait?.trim()) return `No matching origin trait: ${filter.originTrait.trim()}`;
  if (filter.setBonus?.trim()) return `No matching set bonus: ${filter.setBonus.trim()}`;
  return null;
}
