/** Damage elements selectable as Element synergy sub-types (006). */
export const SYNERGY_ELEMENTS = [
  "Kinetic",
  "Solar",
  "Arc",
  "Void",
  "Stasis",
  "Strand",
  "Prismatic",
] as const;

export type SynergyElement = (typeof SYNERGY_ELEMENTS)[number];
