/**
 * The resolved build sheet: the LLM's name-based build joined against the
 * manifest entity stores, with validation flags, champion coverage, and
 * computed stat benefits. This is what the UI renders and exports derive from.
 */

import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ChampionType } from "@/data/rules/championCounters";
import type { ArmorStatName } from "@/data/rules/statBenefits";
import type { Hash } from "@/lib/manifest/types/records";

export type ResolutionStatus = "verified" | "fuzzy" | "unresolved";

export interface ResolvedReference {
  /** The name the model asked for. */
  requestedName: string;
  /** Manifest record it resolved to, if any. */
  resolved: { hash: Hash; name: string; icon: string | null } | null;
  /** 1 = exact; lower = fuzzy match quality. */
  confidence: number;
  status: ResolutionStatus;
}

export interface ResolvedPerkPick extends ResolvedReference {
  /** Legality against the weapon's perk pools / artifact grid, when checkable. */
  legality: { legal: boolean; reason?: string; curated?: boolean } | null;
  rationale?: string;
}

export interface ResolvedWeapon {
  slot: "Kinetic" | "Energy" | "Power";
  reference: ResolvedReference;
  isExotic: boolean;
  frame: string | null;
  /** Intrinsic champion counter computed from frame + weapon type. */
  championCounter: ChampionType | null;
  perks: ResolvedPerkPick[];
  rationale: string;
}

export interface ChampionCoverageSource {
  counter: ChampionType;
  /** e.g. 'Fatebringer (Adaptive Frame)' or 'subclass verb: jolt'. */
  source: string;
}

export interface ChampionCoverage {
  sources: ChampionCoverageSource[];
  covered: Record<ChampionType, boolean>;
}

export interface ResolvedStatTarget {
  stat: ArmorStatName;
  target: number;
  /** Computed benefit lines at the target value (from the rule tables). */
  benefits: string[];
  rationale: string;
}

export interface FragmentCheckView {
  legal: boolean;
  capacity: number;
  requested: number;
}

export interface ResolvedSubclass {
  aspects: ResolvedReference[];
  fragments: ResolvedReference[];
  abilities: { kind: string; reference: ResolvedReference }[];
  fragmentCheck: FragmentCheckView | null;
  rationale: string;
}

export interface ResolvedArtifact {
  reference: ResolvedReference;
  perks: ResolvedPerkPick[];
  rationale: string;
  /** False when the activity disables artifacts (Trials/Competitive). */
  allowedInActivity: boolean;
}

export interface ValidationSummary {
  verified: number;
  fuzzy: number;
  unresolved: number;
  illegalPerks: number;
}

export interface ResolvedBuildSheet {
  /** The raw LLM output the sheet was built from. */
  build: GeneratedBuild;
  activity: string;
  subclass: ResolvedSubclass;
  exoticArmor: ResolvedReference & { alternatives: ResolvedReference[] };
  weapons: ResolvedWeapon[];
  statTargets: ResolvedStatTarget[];
  mods: { slot: string; picks: ResolvedPerkPick[] }[];
  artifact: ResolvedArtifact | null;
  championCoverage: ChampionCoverage;
  validation: ValidationSummary;
}
