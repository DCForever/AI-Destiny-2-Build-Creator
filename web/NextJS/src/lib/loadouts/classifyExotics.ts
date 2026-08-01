import type { SavedLoadout } from "@/lib/db/types";
import type { ExoticArmorRecord, ExoticWeaponRecord } from "@/lib/manifest/types/records";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import type { LoadoutExoticSummary } from "./types";

export interface ManifestExoticStores {
  exoticArmor: ExoticArmorRecord[];
  exoticWeapons: ExoticWeaponRecord[];
}

function loadoutClassName(loadout: SavedLoadout): DestinyClassName {
  return loadout.buildRequest?.className ?? "Titan";
}

export function classifyLoadoutExotics(
  loadout: SavedLoadout,
  manifest?: ManifestExoticStores,
): LoadoutExoticSummary {
  const sheet = loadout.resolvedSheet;
  const className = loadoutClassName(loadout);

  let exoticArmor: LoadoutExoticSummary["exoticArmor"] = null;
  const armorRef = sheet.exoticArmor;
  const armorHash = armorRef.resolved?.hash ?? null;
  const armorName = armorRef.resolved?.name ?? armorRef.requestedName;

  if (armorName) {
    const manifestArmor = armorHash
      ? manifest?.exoticArmor.find((a) => a.hash === armorHash)
      : undefined;
    exoticArmor = {
      hash: armorHash,
      name: armorName,
      slot: manifestArmor?.slot ?? null,
      classType: manifestArmor?.classType ?? null,
      status: armorRef.status,
    };
  }

  let exoticWeapon: LoadoutExoticSummary["exoticWeapon"] = null;
  const weapon = sheet.weapons.find((w) => w.isExotic);
  if (weapon) {
    const weaponHash = weapon.reference.resolved?.hash ?? null;
    const weaponName = weapon.reference.resolved?.name ?? weapon.reference.requestedName;
    exoticWeapon = {
      hash: weaponHash,
      name: weaponName,
      slot: weapon.slot,
      status: weapon.reference.status,
    };
  }

  return {
    loadoutId: loadout.id,
    className,
    exoticArmor,
    exoticWeapon,
  };
}
