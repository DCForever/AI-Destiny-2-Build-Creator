import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import type { EquipmentSlot } from "@/lib/sets/schemas";

export type GuardianClass = "Titan" | "Hunter" | "Warlock";

export type BuildSubclass = {
  name: string;
  super: string;
  classAbility: string;
  movement: string;
  melee: string;
  grenade: string;
  aspects: string[];
  fragments: string[];
  rationale?: string;
};

export type SynergySummary = {
  id: string;
  name: string;
  type: string;
  subType?: string | null;
};

export type SynergyTypeSummary = {
  type: string;
  subType: string | null;
  label: string;
  key: string;
};

export type SlotClaimSummary = {
  slot: EquipmentSlot;
  itemHash: number;
  itemName: string;
  source: string;
  setId?: string;
  selectedPerks?: number[];
  instanceId?: string | null;
};

export type VariantAttachment = {
  setId: string;
  mode: "live" | "snapshot";
  set?: { id: string; name: string; type: string };
};

export type BuildVariantDetail = {
  id: string;
  name: string;
  isDefault?: boolean;
  exoticWeaponHash: number | null;
  exoticWeaponName: string | null;
  artifactHash?: number | null;
  artifactName?: string | null;
  artifactConfig?: number[];
  notes: string | null;
  attachments: VariantAttachment[];
  resolved?: {
    equipment: Partial<Record<EquipmentSlot, SlotClaimSummary>>;
    conflicts: Array<{ slot: EquipmentSlot; claimants: SlotClaimSummary[] }>;
  };
};

export type BuildSummary = {
  id: string;
  name: string;
  className: GuardianClass;
  exoticArmorHash?: number | null;
  exoticArmorName?: string | null;
  exoticWeaponHash?: number | null;
  exoticWeaponName?: string | null;
  pinnedSuper?: string | null;
};

export type BuildDetail = BuildSummary & {
  subclass: BuildSubclass;
  softStatTargets?: SoftStatTargets;
  tagIds?: string[];
  synergyTypes?: SynergyTypeSummary[];
  synergies: SynergySummary[];
  variants: BuildVariantDetail[];
};

export type BungieCharacter = {
  characterId: string;
  classType: GuardianClass | string;
  light?: number;
  emblemPath?: string;
};

export const WEAPON_SLOTS: EquipmentSlot[] = ["primary", "special", "heavy"];
export const ARMOR_SLOTS: EquipmentSlot[] = [
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
];

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
};

export const CLASS_COLOR: Record<GuardianClass, string> = {
  Titan: "text-solar",
  Hunter: "text-arc",
  Warlock: "text-void",
};
