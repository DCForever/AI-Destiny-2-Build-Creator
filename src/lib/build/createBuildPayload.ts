import type { BuildSubclass, GuardianClass } from "@/components/build/types";
import type { SynergyTypeSelection } from "@/components/debug/SynergyTypeMultiSelect";
import {
  defaultSubclassForClass,
  isValidSubclassForClass,
} from "@/lib/build/createBuildLookups";

export type ExoticPick = { hash: number; name: string } | null;

export type CreateBuildFormState = {
  name: string;
  className: GuardianClass;
  subclassName: string;
  pinnedSuper: string | null;
  exotic: ExoticPick;
  synergyTypes: SynergyTypeSelection[];
  subclassDefaults: BuildSubclass;
};

export type CreateBuildApiPayload = {
  name?: string;
  className: GuardianClass;
  subclass: BuildSubclass;
  synergyTypes: SynergyTypeSelection[];
  pinnedSuper: string | null;
  exoticArmorName: string | null;
  exoticArmorHash: number | null;
};

export function createBuildPayload(state: CreateBuildFormState): CreateBuildApiPayload {
  const subclassName = isValidSubclassForClass(state.className, state.subclassName)
    ? state.subclassName
    : defaultSubclassForClass(state.className);

  const pinned = state.pinnedSuper?.trim() || null;
  const exoticHash = state.exotic?.hash ?? null;
  const exoticName = state.exotic?.name?.trim() || null;

  return {
    name: state.name.trim() || undefined,
    className: state.className,
    subclass: {
      ...state.subclassDefaults,
      name: subclassName,
      super: pinned || state.subclassDefaults.super,
    },
    synergyTypes: state.synergyTypes,
    pinnedSuper: pinned,
    exoticArmorHash: exoticHash,
    exoticArmorName: exoticName,
  };
}
