import type { RollTag } from "@/lib/db/types";
import type { ArmorStatName } from "@/data/rules/statBenefits";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import type { ArmorStatSortBy } from "./sortInstances";

export type InstanceKind = "weapon" | "armor";

export interface ResolvedPlug {
  hash: number;
  name: string | null;
  displayName: string;
  resolved: boolean;
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
