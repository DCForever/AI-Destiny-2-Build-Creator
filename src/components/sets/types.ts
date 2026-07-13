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
  instanceId: string | null;
  selectedPerks: number[];
  masterworkHash: number | null;
  modHashes: number[] | null;
  sortOrder: number;
  removedAt: string | null;
  stale: boolean;
};

export type SetDetail = SetSummary & {
  items: SetItem[];
  modEncourage?: boolean;
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
