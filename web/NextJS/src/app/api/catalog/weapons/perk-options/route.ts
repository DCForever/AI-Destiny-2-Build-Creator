import { NextResponse } from "next/server";
import { z } from "zod";

import { resolveWeaponPerkOptions } from "@/lib/catalog/weaponPerkOptions";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  itemHash: z.coerce.number().int().positive(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({ itemHash: url.searchParams.get("itemHash") });
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((issue) => issue.message).join("; ") },
      { status: 400 },
    );
  }

  const { itemHash } = parsed.data;

  try {
    const { entityCache } = await getServices();
    const [weapons, weaponPerks] = await Promise.all([
      entityCache.getStore("weapons"),
      entityCache.getStore("weapon-perks"),
    ]);

    // Only random-roll weapons (the `weapons` store) expose `perkColumns`;
    // exotics/unknowns resolve to empty columns so the UI records equipped only.
    const weapon = weapons.find((record) => record.hash === itemHash) ?? null;
    const perkNames = new Map(weaponPerks.map((perk) => [perk.hash, perk.name]));

    return NextResponse.json(resolveWeaponPerkOptions(itemHash, weapon, perkNames));
  } catch (error) {
    const message = error instanceof Error ? error.message : "Perk options lookup failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
