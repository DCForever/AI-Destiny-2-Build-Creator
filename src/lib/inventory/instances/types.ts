import type { RollTag } from "@/lib/db/types";
import type { ArmorStatName } from "@/data/rules/statBenefits";
import type { ArmorTier } from "@/data/rules/armorTiers";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import type { ArmorStatSortBy } from "./sortInstances";

export type InstanceKind = "weapon" | "armor";

export interface ResolvedPlug {
  hash: number;
  name: string | null;
  displayName: string;
  resolved: boolean;
}

/** A single set-bonus tier effect (2-piece or 4-piece). */
export interface SetBonusTierSummary {
  requiredCount: number;
  name: string;
  description: string;
}

/** Armor set-bonus surfaced on an armor instance card (2pc & 4pc). */
export interface ArmorSetBonusSummary {
  hash: number;
  name: string;
  tiers: SetBonusTierSummary[];
}

/**
 * Per-`itemHash` armor metadata resolved once per request (loadInstanceContext)
 * and threaded into projection so `projectInstance` performs no manifest reads.
 */
export interface ArmorInstanceMeta {
  isExotic: boolean;
  setBonus: ArmorSetBonusSummary | null;
}

export interface OwnedInstanceDetail {
  instanceId: string;
  itemHash: number;
  kind: InstanceKind;
  bucket: string;
  location: "vault" | "character" | "equipped";
  characterId?: string | null;
  className?: DestinyClassName | null;
  characterDisplayName?: string | null;
  power: number;
  isMasterwork: boolean;
  isCrafted: boolean;
  rollTags: RollTag[];
  plugs: ResolvedPlug[];
  statValues?: Partial<Record<ArmorStatName, number>>;
  totalStats?: number;
  statsIncomplete?: boolean;
  /** Armor only: resolved Armor 3.0 tier (see resolveArmorTier). */
  tier?: ArmorTier;
  /** Armor only: 2pc/4pc set bonus, or null when the item is in no set. */
  setBonus?: ArmorSetBonusSummary | null;
  syncedAt: string;
}

export interface InstanceFilterCriteria {
  itemHash?: number;
  bucket?: string;
  kind?: InstanceKind;
  q?: string;
  sortBy?: ArmorStatSortBy;
}

export interface CharacterLabel {
  className: DestinyClassName;
  characterDisplayName: string;
}

export interface ListInstancesResult {
  instances: OwnedInstanceDetail[];
  count: number;
  syncPrompt: boolean;
  message?: string;
  filter?: InstanceFilterCriteria;
}
