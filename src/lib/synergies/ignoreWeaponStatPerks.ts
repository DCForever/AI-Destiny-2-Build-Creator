import type { PerkRecord, WeaponRecord } from "@/lib/manifest/types/records";

/**
 * Collect perk hashes that appear in barrel (col 0) or magazine (col 1)
 * sockets on legendary weapons — those are stat columns, not trait keywords.
 */
export function barrelMagazineHashesFromWeapons(
  weapons: Array<Pick<WeaponRecord, "perkColumns">>,
): Set<number> {
  const out = new Set<number>();
  for (const w of weapons) {
    for (const col of w.perkColumns ?? []) {
      if (col.column > 1) continue;
      for (const h of col.curated) out.add(h);
      for (const h of col.randomized) out.add(h);
    }
  }
  return out;
}

/** Name/description heuristics for barrel & magazine plugs not caught by column index. */
export function isBarrelOrMagazinePerkText(perk: {
  name: string;
  description?: string;
}): boolean {
  const name = perk.name.toLowerCase();
  const desc = (perk.description ?? "").toLowerCase();

  // Explicit type words in name
  if (/\bbarrel\b/.test(name)) return true;
  if (/\brifling\b/.test(name)) return true;
  if (/\bbore\b/.test(name)) return true;
  if (/\bmagazine\b/.test(name) || /\bmagwell\b/.test(name)) return true;
  if (/\b(?:appended|tactical|extended|alloy|assault|drop|light)\s+mag\b/.test(name)) {
    return true;
  }

  // Description lead-ins used by Bungie for these columns
  if (
    /\bbarrel\b/.test(desc) &&
    /\b(recoil|range|stability|handling|velocity)\b/.test(desc)
  ) {
    return true;
  }
  if (
    (/\bmagazine\b/.test(desc) || /\bmagwell\b/.test(desc) || /\brounds\b/.test(desc)) &&
    /\b(reload|magazine|range|stability|handling|inventory)\b/.test(desc)
  ) {
    // "rounds" alone is broad (e.g. trait text) — require mag-like context
    if (/\brounds\b/.test(desc) && !/\b(magazine|magwell|ammo|reload)\b/.test(desc)) {
      // High-Caliber Rounds etc. still are magazine column; name often ends with Rounds
      if (/\brounds\b/.test(name) || /\bmag\b/.test(name)) return true;
      return false;
    }
    return true;
  }

  // Common barrel names without "barrel" in the title
  if (
    /^(arrowhead brake|chambered compensator|corkscrew|fluted|full bore|hammer-forged|polygonal|smallbore|rifled barrel|extended barrel|full choke|smoothbore|corkscrew rifling|hammer-forged rifling|polygonal rifling)$/i.test(
      name,
    )
  ) {
    return true;
  }

  // Common magazine names
  if (
    /^(accurized rounds|appended mag|tactical mag|extended mag|steady rounds|alloy magazine|flared magwell|ricochet rounds|light mag|armor-piercing rounds|drop mag|assault mag|high-caliber rounds|light battery|enhanced battery|projection fuse|particle repeater|liquid coils|accelerated coils|ion battery)$/i.test(
      name,
    )
  ) {
    return true;
  }

  return false;
}

export function shouldIgnoreWeaponPerkForKeywords(
  perk: Pick<PerkRecord, "hash" | "name" | "description">,
  barrelMagHashes: ReadonlySet<number>,
): boolean {
  if (barrelMagHashes.has(perk.hash)) return true;
  return isBarrelOrMagazinePerkText(perk);
}
