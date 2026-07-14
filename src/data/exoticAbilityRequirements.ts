/**
 * Curated exotic armor → required ability pins (DBR-SUB-005 / DAC-DST-004).
 *
 * When an exotic hard-requires a Super / melee / grenade / class ability,
 * list it here by Bungie hash and/or display name. Lookup is case-insensitive
 * on name; hash wins when both present.
 *
 * Expand this table as product identifies hard-gated exotics. Soft synergies
 * (exotics that merely *prefer* an ability) must not appear here.
 */

export type ExoticAbilityRequirement = {
  /** Optional Bungie inventory item hash. */
  hash?: number;
  /** Display name as shown in-game / entity cache. */
  name: string;
  super?: string;
  melee?: string;
  grenade?: string;
  classAbility?: string;
};

/**
 * Seeded curated requirements. Empty requirements on a row are ignored.
 * Add rows when an exotic truly cannot function without a specific ability.
 */
export const EXOTIC_ABILITY_REQUIREMENTS: readonly ExoticAbilityRequirement[] = [
  // Example hard gates are uncommon; keep list product-curated.
  // {
  //   name: "Example Exotic",
  //   hash: 1234567890,
  //   super: "Thundercrash",
  // },
];

export type AbilityRequirementFields = {
  super?: string;
  melee?: string;
  grenade?: string;
  classAbility?: string;
};

function normalizeName(value: string): string {
  return value.trim().toLowerCase();
}

/** Lookup by hash first, then exact name (case-insensitive). */
export function lookupExoticAbilityRequirements(input: {
  hash?: number | null;
  name?: string | null;
}): AbilityRequirementFields | null {
  const byHash =
    input.hash != null && input.hash > 0
      ? EXOTIC_ABILITY_REQUIREMENTS.find((r) => r.hash === input.hash)
      : undefined;
  const byName =
    input.name?.trim()
      ? EXOTIC_ABILITY_REQUIREMENTS.find(
          (r) => normalizeName(r.name) === normalizeName(input.name!),
        )
      : undefined;
  const row = byHash ?? byName;
  if (!row) return null;

  const out: AbilityRequirementFields = {};
  if (row.super?.trim()) out.super = row.super.trim();
  if (row.melee?.trim()) out.melee = row.melee.trim();
  if (row.grenade?.trim()) out.grenade = row.grenade.trim();
  if (row.classAbility?.trim()) out.classAbility = row.classAbility.trim();
  return Object.keys(out).length > 0 ? out : null;
}

export function hasAbilityRequirements(
  req: AbilityRequirementFields | null | undefined,
): boolean {
  if (!req) return false;
  return Boolean(req.super || req.melee || req.grenade || req.classAbility);
}
