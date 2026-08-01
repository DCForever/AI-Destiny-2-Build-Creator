import type { SynergyLinkInput } from "./schemas";
import { getServices } from "@/lib/services";
import type { SetBonusRecord } from "@/lib/manifest/types/records";

export type ValidatedSynergyLink = SynergyLinkInput & {
  armorSetHash?: number;
  originTraitHash?: number;
};

export async function validateSynergyLink(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  switch (link.kind) {
    case "weapon":
      if (!link.itemHash) return { valid: false, reason: "itemHash required" };
      return validateWeaponHash(link);
    case "weapon_perk":
      if (!link.perkHash) return { valid: false, reason: "perkHash required" };
      return validatePerkHash(link);
    case "origin_trait":
      if (!link.originTraitName && !link.originTraitHash) {
        return { valid: false, reason: "originTraitName or originTraitHash required" };
      }
      return validateOriginTrait(link);
    case "armor_set_bonus":
      if (!link.armorSetName || !link.bonusPieces || !link.bonusName) {
        return { valid: false, reason: "armorSetName, bonusPieces, bonusName required" };
      }
      return validateArmorSetBonus(link);
    case "exotic_armor":
      if (!link.itemHash) return { valid: false, reason: "itemHash required" };
      return validateExoticArmor(link);
    case "artifact_perk":
      if (!link.perkHash) return { valid: false, reason: "perkHash required" };
      return validateArtifactPerk(link);
    default:
      return { valid: false, reason: "unknown kind" };
  }
}

async function validateWeaponHash(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const [weapons, exoticWeapons] = await Promise.all([
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
    ]);
    const hash = link.itemHash!;
    const match = weapons.find((w) => w.hash === hash) ?? exoticWeapons.find((w) => w.hash === hash);
    if (!match) {
      return { valid: false, reason: `weapon hash ${hash} not found in manifest` };
    }
    return {
      valid: true,
      link: { ...link, displayName: link.displayName || match.name },
    };
  } catch {
    return { valid: true, link };
  }
}

async function validatePerkHash(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const perks = await entityCache.getStore("weapon-perks");
    const match = perks.find((p) => p.hash === link.perkHash);
    if (!match) {
      return { valid: false, reason: `perk hash ${link.perkHash} not found in manifest` };
    }
    return {
      valid: true,
      link: { ...link, displayName: link.displayName || match.name },
    };
  } catch {
    return { valid: true, link };
  }
}

async function validateOriginTrait(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const traits = await entityCache.getStore("origin-traits");
    const match = link.originTraitHash
      ? traits.find((t) => t.hash === link.originTraitHash)
      : traits.find((t) => t.name.toLowerCase() === (link.originTraitName ?? "").toLowerCase());
    if (!match) {
      return { valid: false, reason: "origin trait not found in manifest" };
    }
    return {
      valid: true,
      link: {
        ...link,
        displayName: link.displayName || match.name,
        originTraitName: match.name,
        originTraitHash: match.hash,
      },
    };
  } catch {
    return { valid: true, link };
  }
}

async function validateArmorSetBonus(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const sets = await entityCache.getStore("set-bonuses");
    const set = findSetBonus(sets, link.armorSetName!, link.bonusPieces!, link.bonusName!);
    if (!set) {
      return { valid: false, reason: "armor set bonus not found in manifest" };
    }
    return {
      valid: true,
      link: {
        ...link,
        displayName: link.displayName || `${set.set.name} ${link.bonusPieces}pc: ${set.bonus.name}`,
        armorSetHash: set.set.hash,
      },
    };
  } catch {
    return { valid: true, link };
  }
}

async function validateExoticArmor(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const armor = await entityCache.getStore("exotic-armor");
    const match = armor.find((a) => a.hash === link.itemHash);
    if (!match) {
      return { valid: false, reason: `exotic armor hash ${link.itemHash} not found in manifest` };
    }
    return {
      valid: true,
      link: { ...link, displayName: link.displayName || match.name },
    };
  } catch {
    return { valid: true, link };
  }
}

async function validateArtifactPerk(
  link: SynergyLinkInput,
): Promise<{ valid: true; link: ValidatedSynergyLink } | { valid: false; reason: string }> {
  try {
    const { entityCache } = await getServices();
    const artifacts = await entityCache.getStore("artifacts");
    for (const art of artifacts) {
      const perk = art.perks?.find((p) => p.hash === link.perkHash);
      if (perk) {
        return {
          valid: true,
          link: {
            ...link,
            displayName: link.displayName || perk.name,
            parentItemHash: link.parentItemHash ?? art.hash,
          },
        };
      }
    }
    return { valid: false, reason: `artifact perk hash ${link.perkHash} not found in manifest` };
  } catch {
    return { valid: true, link };
  }
}

function findSetBonus(
  sets: SetBonusRecord[],
  armorSetName: string,
  bonusPieces: number,
  bonusName: string,
): { set: SetBonusRecord; bonus: SetBonusRecord["perks"][number] } | null {
  const set = sets.find((s) => s.name.toLowerCase() === armorSetName.toLowerCase());
  if (!set) return null;
  const bonus = set.perks.find(
    (p) => p.requiredCount === bonusPieces && p.name.toLowerCase() === bonusName.toLowerCase(),
  );
  if (!bonus) return null;
  return { set, bonus };
}

export async function validateSynergyLinks(
  links: SynergyLinkInput[],
): Promise<ValidatedSynergyLink[]> {
  const validated: ValidatedSynergyLink[] = [];
  for (const link of links) {
    const result = await validateSynergyLink(link);
    if (!result.valid) {
      throw new Error(result.reason);
    }
    validated.push(result.link);
  }
  return validated;
}
