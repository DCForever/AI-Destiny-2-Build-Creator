"use client";

import type { SynergyLinkInput, SynergyType } from "@/lib/synergies/schemas";

export type SynergyLink = {
  id: string;
  kind: string;
  displayName: string;
  itemHash: number | null;
  perkHash: number | null;
  parentItemHash: number | null;
  originTraitName: string | null;
  originTraitHash: number | null;
  armorSetName: string | null;
  bonusPieces: number | null;
  bonusName: string | null;
  armorSetHash: number | null;
  /** Catalog description of the linked object (detail responses). */
  description?: string | null;
};

export type SynergyDetail = {
  id: string;
  name: string;
  type: SynergyType | string;
  subType: string | null;
  description: string;
  links: SynergyLink[];
  createdAt?: string;
  updatedAt?: string;
};

export type SynergySummary = Pick<
  SynergyDetail,
  "id" | "name" | "type" | "subType"
> & {
  links?: SynergyLink[];
};

export type SynergyDraftLink = SynergyLinkInput;

export const LINK_KINDS = [
  "weapon",
  "weapon_perk",
  "origin_trait",
  "armor_set_bonus",
] as const;

export type LinkKind = (typeof LINK_KINDS)[number];

export const LINK_KIND_LABEL: Record<string, string> = {
  weapon: "Weapon",
  weapon_perk: "Weapon perk",
  origin_trait: "Origin trait",
  armor_set_bonus: "Armor set bonus",
};
