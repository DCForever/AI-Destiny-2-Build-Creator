import type { RollTag } from "@/lib/db/types";
import type { ArmorTier } from "@/data/rules/armorTiers";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import type { ArmorStatSortBy } from "./sortInstances";

export type InstanceKind = "weapon" | "armor";

export type SocketColumnKind =
  | "barrel"
  | "magazine"
  | "trait"
  | "intrinsic"
  | "origin"
  | "masterwork"
  | "catalyst";

/** Per-socket capture persisted on inventory_items.socket_plugs. */
export interface StoredSocketPlug {
  socketIndex: number;
  equippedPlugHash: number;
  reusablePlugHashes: number[];
  columnKind: SocketColumnKind;
  columnLabel: string;
}

export type PerkCaptureStatus = "complete" | "pending" | "unavailable";

export interface InstancePerkOption {
  hash: number;
  name: string | null;
  displayName: string;
  isEnhanced: boolean;
  isEquipped: boolean;
  /** Bungie relative icon when known from entity stores. */
  icon?: string | null;
  /** Catalog description when known. */
  description?: string;
}

export interface InstancePerkColumn {
  columnKind: SocketColumnKind;
  label: string;
  socketIndex: number;
  equippedPlugHash: number;
  options: InstancePerkOption[];
}

export interface InstancePerkGrid {
  instanceId: string;
  itemHash: number;
  captureStatus: PerkCaptureStatus;
  columns: InstancePerkColumn[];
}

/** Raw socket rows from Bungie parse before manifest classification. */
export interface RawSocketCapture {
  socketIndex: number;
  equippedPlugHash: number;
  reusablePlugHashes: number[];
}

export interface ResolvedPlug {
  hash: number;
  name: string | null;
  displayName: string;
  resolved: boolean;
  /** Bungie relative icon when known from entity stores. */
  icon?: string | null;
  /** Catalog description when known. */
  description?: string;
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
  /** Armor 3.0 stats and/or weapon combat stats (string keys). */
  statValues?: Partial<Record<string, number>>;
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
