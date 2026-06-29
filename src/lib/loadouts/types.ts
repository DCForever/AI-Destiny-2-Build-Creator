import type { ResolutionStatus } from "@/lib/build/types";
import type {
  ArmorSlotName,
  DestinyClassName,
  WeaponSlotName,
} from "@/lib/manifest/types/records";

export type ExoticFilterMode = "exact" | "slot";

export interface ExoticArmorSummary {
  hash: number | null;
  name: string;
  slot: ArmorSlotName | null;
  classType: DestinyClassName | null;
  status: ResolutionStatus;
}

export interface ExoticWeaponSummary {
  hash: number | null;
  name: string;
  slot: WeaponSlotName;
  status: ResolutionStatus;
}

export interface LoadoutExoticSummary {
  loadoutId: string;
  className: DestinyClassName;
  exoticArmor: ExoticArmorSummary | null;
  exoticWeapon: ExoticWeaponSummary | null;
}

export interface ArmorExoticFilter {
  mode: ExoticFilterMode;
  hash?: number;
  name?: string;
  slot?: ArmorSlotName;
}

export interface WeaponExoticFilter {
  mode: ExoticFilterMode;
  hash?: number;
  name?: string;
  slot?: WeaponSlotName;
}

export interface ExoticFilterCriteria {
  armor?: ArmorExoticFilter | null;
  weapon?: WeaponExoticFilter | null;
}

export interface LoadoutListRow {
  id: string;
  name: string;
  source: string;
  className?: DestinyClassName;
  createdAt: string;
  updatedAt: string;
  manifestVersion: string;
  exoticSummary: Omit<LoadoutExoticSummary, "loadoutId">;
}

export interface DiscoveryOverlayState {
  open: boolean;
  title: string;
  criteria: ExoticFilterCriteria;
  matches: LoadoutListRow[];
}
