import type { CoverageLinkKind } from "@/lib/synergies/coverageKeys";
import type { CreatableSynergyType } from "@/lib/synergies/schemas";

export type GapScanScope = "owned" | "manifest" | "both";

export type GapCandidateSource = "owned" | "manifest";

export type GapCandidate = {
  coverageKey: string;
  kind: CoverageLinkKind;
  displayName: string;
  itemHash?: number;
  perkHash?: number;
  originTraitHash?: number;
  originTraitName?: string;
  armorSetName?: string;
  bonusPieces?: 2 | 4;
  bonusName?: string;
  armorSetHash?: number;
  /** Weapon ammo when known — used for default synergy type. */
  ammo?: "Primary" | "Special" | "Heavy";
  sources: GapCandidateSource[];
};

export type MissingLinkGap = GapCandidate & {
  gapKind: "link";
  suggestedType: CreatableSynergyType;
  suggestedSubType: string | null;
  rationale: string;
};

/** Missing type / subtype designation (e.g. Verb: Sliding) with no library row. */
export type MissingTypeDesignationGap = {
  gapKind: "type";
  coverageKey: string;
  displayName: string;
  sources: Array<"vocab" | "manifest" | "owned" | "object_text">;
  suggestedType: CreatableSynergyType;
  suggestedSubType: string | null;
  rationale: string;
  mentionCount?: number;
  sampleObjectNames?: string[];
  references?: Array<{
    store: string;
    hash?: number;
    name: string;
    snippet: string;
  }>;
};

export type MissingSynergyGap = MissingLinkGap | MissingTypeDesignationGap;

export type GapScanKindFilter = CoverageLinkKind | "type";

/** Default scan is type designations only (e.g. Verb: Sliding). */
export const DEFAULT_GAP_KINDS: GapScanKindFilter[] = ["type"];

/** Full scan: types + unlinked gear objects. */
export const ALL_GAP_KINDS: GapScanKindFilter[] = [
  "type",
  "weapon",
  "origin_trait",
  "armor_set_bonus",
];

