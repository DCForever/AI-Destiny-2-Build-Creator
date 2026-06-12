/**
 * Meta pack record shapes. Content is curated by hand from the cached 9.7.0
 * sources in `src/data/meta/sources/` and marked for user review. The pack is
 * grounding for the LLM and the fallback when web search is unavailable.
 */

export type MetaClassName = "Titan" | "Hunter" | "Warlock";

export interface ArtifactGuidance {
  name: string;
  /** What the artifact's perk grid is built around. */
  identity: string;
  /** 9.7.0 rebalance notes that change how it plays. */
  rebalanceNotes: readonly string[];
  /** Activities or build styles it suits best. */
  bestFor: string;
}

export interface SetBonusGuidance {
  setName: string;
  source: string;
  twoPiece: string;
  fourPiece: string;
  assessment: string;
}

export interface SetBonusCombo {
  pieces: string;
  useCase: string;
}

export interface ExoticArmorNote {
  name: string;
  className: MetaClassName;
  note: string;
}

export interface ExoticWeaponNote {
  name: string;
  note: string;
}

export interface HighlightedBuild {
  className: MetaClassName;
  subclass: string;
  title: string;
  summary: string;
}

export interface StatGuidanceEntry {
  context: string;
  guidance: string;
}
