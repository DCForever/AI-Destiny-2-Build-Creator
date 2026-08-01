import type { EntityCache, FragmentCountCheck, PerkLegality, PerkValidator } from "./types/services";
import type { Hash, WeaponRecord } from "./types/records";

function weaponNotFoundReason(weaponHash: Hash): string {
  return `weapon hash ${weaponHash} not found in legendary weapon store`;
}

function weaponPerkNotFoundReason(
  weapon: WeaponRecord,
  perkHash: Hash,
): string {
  return `perk hash ${perkHash} is not available on ${weapon.name} (hash ${weapon.hash})`;
}

function artifactNotFoundReason(artifactHash: Hash): string {
  return `artifact hash ${artifactHash} not found in artifact store`;
}

function artifactPerkNotFoundReason(
  artifactName: string,
  artifactHash: Hash,
  perkHash: Hash,
): string {
  return `perk hash ${perkHash} is not available on ${artifactName} (hash ${artifactHash})`;
}

function findWeaponPerkColumn(
  weapon: WeaponRecord,
  perkHash: Hash,
): { column: number; curated: boolean } | null {
  for (const column of weapon.perkColumns) {
    if (column.curated.includes(perkHash)) {
      return { column: column.column, curated: true };
    }
    if (column.randomized.includes(perkHash)) {
      return { column: column.column, curated: false };
    }
  }
  return null;
}

export class StorePerkValidator implements PerkValidator {
  constructor(private readonly cache: EntityCache) {}

  async checkWeaponPerk(
    weaponHash: Hash,
    perkHash: Hash,
  ): Promise<PerkLegality> {
    const weapons = await this.cache.getStore("weapons");
    const weapon = weapons.find((entry) => entry.hash === weaponHash);
    if (!weapon) {
      return { legal: false, reason: weaponNotFoundReason(weaponHash) };
    }

    const match = findWeaponPerkColumn(weapon, perkHash);
    if (!match) {
      return { legal: false, reason: weaponPerkNotFoundReason(weapon, perkHash) };
    }

    return {
      legal: true,
      column: match.column,
      curated: match.curated,
    };
  }

  async checkArtifactPerk(
    artifactHash: Hash,
    perkHash: Hash,
  ): Promise<PerkLegality> {
    const artifacts = await this.cache.getStore("artifacts");
    const artifact = artifacts.find((entry) => entry.hash === artifactHash);
    if (!artifact) {
      return { legal: false, reason: artifactNotFoundReason(artifactHash) };
    }

    const perk = artifact.perks.find((entry) => entry.hash === perkHash);
    if (!perk) {
      return {
        legal: false,
        reason: artifactPerkNotFoundReason(
          artifact.name,
          artifactHash,
          perkHash,
        ),
      };
    }

    return { legal: true, column: perk.column, curated: true };
  }

  async checkFragmentCount(
    aspectHashes: Hash[],
    fragmentCount: number,
  ): Promise<FragmentCountCheck> {
    const aspects = await this.cache.getStore("aspects");
    const byHash = new Map(aspects.map((aspect) => [aspect.hash, aspect]));

    let capacity = 0;
    for (const hash of aspectHashes) {
      const aspect = byHash.get(hash);
      if (aspect) {
        capacity += aspect.fragmentCapacity;
      }
    }

    return {
      legal: fragmentCount <= capacity,
      capacity,
      requested: fragmentCount,
    };
  }
}

export function createPerkValidator(cache: EntityCache): PerkValidator {
  return new StorePerkValidator(cache);
}
