import type { GeneratedBuild, BuildRequest } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import type { ArmorStatName } from "@/data/rules/statBenefits";

export type RollTag =
  | "MeleeBuildCandidate"
  | "ChampionBarrier"
  | "ChampionOverload"
  | "ChampionUnstoppable"
  | "OrbitBuild"
  | "Crafted";

export interface UserInventoryItem {
  instanceId: string;
  itemHash: number;
  bucket: string;
  location: "vault" | "character" | "equipped";
  characterId?: string;
  power: number;
  isMasterwork: boolean;
  isCrafted: boolean;
  plugHashes: number[];
  rollTags: RollTag[];
  statValues?: Partial<Record<ArmorStatName, number>>;
  syncedAt: string;
}

export type LoadoutSource = "generator" | "analyzer" | "manual-edit";

export interface SavedLoadout {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
  manifestVersion: string;
  buildRequest?: BuildRequest;
  generatedBuild: GeneratedBuild;
  resolvedSheet: ResolvedBuildSheet;
  source: LoadoutSource;
}

export interface DbUser {
  id: number;
  bungieMembershipId: string;
  membershipType: number;
  displayName: string;
  lastSyncAt: string | null;
}
