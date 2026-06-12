import type {
  ResolvedBuildSheet,
  ResolvedPerkPick,
  ResolvedWeapon,
} from "@/lib/build/types";

export interface WishlistExport {
  text: string;
  lineCount: number;
  skipped: string[];
}

function stripNewlines(text: string): string {
  return text.replace(/\r?\n/g, " ").trim();
}

function weaponNote(rationale: string): string {
  return stripNewlines(rationale).slice(0, 100);
}

function weaponDisplayName(weapon: ResolvedWeapon): string {
  return weapon.reference.resolved?.name ?? weapon.reference.requestedName;
}

function isIllegalPerk(perk: ResolvedPerkPick): boolean {
  return perk.legality?.legal === false;
}

function collectPerkHashes(weapon: ResolvedWeapon): {
  hashes: number[];
  skipped: string[];
} {
  const skipped: string[] = [];
  const hashes: number[] = [];
  const weaponName = weaponDisplayName(weapon);

  for (const perk of weapon.perks) {
    if (!perk.resolved) {
      skipped.push(
        `Perk "${perk.requestedName}" unresolved on ${weaponName}`,
      );
      continue;
    }
    if (isIllegalPerk(perk)) {
      const reason = perk.legality?.reason ?? "illegal";
      skipped.push(`${perk.requestedName} on ${weaponName}: ${reason}`);
      continue;
    }
    hashes.push(perk.resolved.hash);
  }

  return { hashes, skipped };
}

function formatWishlistLine(
  weaponHash: number,
  perkHashes: number[],
  note: string,
): string {
  if (perkHashes.length === 0) {
    return `dimwishlist:item=${weaponHash}#notes:${note}`;
  }
  return `dimwishlist:item=${weaponHash}&perks=${perkHashes.join(",")}#notes:${note}`;
}

function emitWeaponLine(weapon: ResolvedWeapon): {
  line: string | null;
  skipped: string[];
} {
  if (!weapon.reference.resolved) {
    return {
      line: null,
      skipped: [`Weapon "${weapon.reference.requestedName}" unresolved`],
    };
  }

  const note = weaponNote(weapon.rationale);
  const { hashes, skipped } = collectPerkHashes(weapon);
  const line = formatWishlistLine(weapon.reference.resolved.hash, hashes, note);
  return { line, skipped };
}

function buildHeader(sheet: ResolvedBuildSheet): string {
  const title = stripNewlines(sheet.build.name);
  const description = stripNewlines(sheet.build.summary);
  return `title:${title} (Destiny 2 Build Creator)\ndescription:${description}\n\n`;
}

export function buildWishlist(sheet: ResolvedBuildSheet): WishlistExport {
  const skipped: string[] = [];
  const wishlistLines: string[] = [];

  for (const weapon of sheet.weapons) {
    const result = emitWeaponLine(weapon);
    skipped.push(...result.skipped);
    if (result.line) {
      wishlistLines.push(result.line);
    }
  }

  const text = buildHeader(sheet) + wishlistLines.join("\n");
  return { text, lineCount: wishlistLines.length, skipped };
}
