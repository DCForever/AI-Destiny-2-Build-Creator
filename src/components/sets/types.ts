import type { SetType } from "@/lib/sets/schemas";

export type SetSummary = {
  id: string;
  name: string;
  type: SetType | string;
  tagIds: string[];
  createdAt?: string;
  updatedAt?: string;
};

export type SetItem = {
  id: string;
  setId: string;
  slot: string;
  itemHash: number;
  itemName: string;
  icon?: string | null;
  description?: string | null;
  element?: string | null;
  instanceId: string | null;
  selectedPerks: number[];
  masterworkHash: number | null;
  modHashes: number[] | null;
  sortOrder: number;
  removedAt: string | null;
  stale: boolean;
};

export type SetUsedByBuild = {
  buildId: string;
  buildName: string;
  variantNames: string[];
};

export type SetDetail = SetSummary & {
  items: SetItem[];
  modEncourage?: boolean;
  /** Builds that attach this set on one or more variants. */
  usedByBuilds?: SetUsedByBuild[];
};

export const SLOT_LABEL: Record<string, string> = {
  primary: "Primary",
  special: "Special",
  heavy: "Heavy",
  helmet: "Helmet",
  arms: "Arms",
  chest: "Chest",
  legs: "Legs",
  class_item: "Class item",
  exotic_weapon: "Exotic weapon",
  exotic_armor: "Exotic armor",
  shader_ornament: "Shader / ornament",
  ghost: "Ghost",
  sparrow: "Sparrow",
  ship: "Ship",
  emblem: "Emblem",
  finisher: "Finisher",
};
