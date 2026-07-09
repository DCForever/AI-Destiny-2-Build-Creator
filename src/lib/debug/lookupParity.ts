export type LookupEntityKind = "exotic_armor" | "exotic_weapon" | "set" | "synergy" | "variant";

const EMPTY_LOOKUP_MESSAGES: Record<LookupEntityKind, string> = {
  exotic_armor: "No exotic armor matched the current lookup.",
  exotic_weapon: "No exotic weapon matched the current lookup.",
  set: "No sets matched the current lookup.",
  synergy: "No synergies matched the current lookup.",
  variant: "No variants are available for this build.",
};

export function emptyLookupMessage(kind: LookupEntityKind): string {
  return EMPTY_LOOKUP_MESSAGES[kind];
}

export function mapExoticSelection(item: { hash: number; name: string }): {
  hash: number;
  name: string;
} {
  return { hash: item.hash, name: item.name };
}

export function synergyIdentityFields(s: { id: string; name: string; type: string }): {
  id: string;
  name: string;
  type: string;
} {
  return { id: s.id, name: s.name, type: s.type };
}

export function setIdentityFields(s: { id: string; name: string; type: string }): {
  id: string;
  name: string;
  type: string;
} {
  return { id: s.id, name: s.name, type: s.type };
}

export function variantIdentityFields(v: { id: string; name: string; isDefault?: boolean }): {
  id: string;
  name: string;
  isDefault: boolean;
} {
  return { id: v.id, name: v.name, isDefault: v.isDefault ?? false };
}
