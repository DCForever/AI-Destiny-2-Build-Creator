import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { synergyLinkKindSchema } from "@/lib/synergies/schemas";
import {
  reverseLookupSynergies,
  reverseLookupSynergiesByItemHashes,
} from "@/lib/synergies/synergyService";

export const runtime = "nodejs";

const ITEM_HASH_BATCH_KINDS = new Set(["weapon", "exotic_armor"]);

function collectItemHashes(url: URL): number[] {
  const fromRepeat = url.searchParams.getAll("itemHash");
  const fromCsv = (url.searchParams.get("itemHashes") ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const raw = [...fromRepeat, ...fromCsv];
  const out: number[] = [];
  for (const value of raw) {
    const n = Number(value);
    if (Number.isFinite(n) && Number.isInteger(n)) out.push(n);
  }
  return [...new Set(out)].slice(0, 100);
}

const querySchema = z.object({
  kind: synergyLinkKindSchema,
  name: z.string().trim().optional(),
  itemHash: z.coerce.number().int().optional(),
  perkHash: z.coerce.number().int().optional(),
  originTraitHash: z.coerce.number().int().optional(),
  armorSetName: z.string().trim().optional(),
  bonusPieces: z.coerce.number().int().optional(),
  bonusName: z.string().trim().optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const url = new URL(request.url);
  const itemHashes = collectItemHashes(url);
  const kindParam = url.searchParams.get("kind") ?? "";

  // Batch path: multiple item hashes for weapon / exotic_armor
  if (itemHashes.length > 1 && ITEM_HASH_BATCH_KINDS.has(kindParam)) {
    const kindParsed = synergyLinkKindSchema.safeParse(kindParam);
    if (!kindParsed.success) {
      return NextResponse.json({ error: "Invalid kind" }, { status: 400 });
    }
    const db = getDb();
    const byItemHash = reverseLookupSynergiesByItemHashes(
      db,
      auth.user.id,
      kindParsed.data,
      itemHashes,
    );
    return NextResponse.json({ byItemHash });
  }

  const parsed = querySchema.safeParse({
    kind: url.searchParams.get("kind"),
    name: url.searchParams.get("name") ?? undefined,
    itemHash:
      itemHashes.length === 1
        ? itemHashes[0]
        : (url.searchParams.get("itemHash") ?? undefined),
    perkHash: url.searchParams.get("perkHash") ?? undefined,
    originTraitHash: url.searchParams.get("originTraitHash") ?? undefined,
    armorSetName: url.searchParams.get("armorSetName") ?? undefined,
    bonusPieces: url.searchParams.get("bonusPieces") ?? undefined,
    bonusName: url.searchParams.get("bonusName") ?? undefined,
  });

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  const db = getDb();
  const synergies = reverseLookupSynergies(db, auth.user.id, parsed.data);
  return NextResponse.json({ synergies, count: synergies.length });
}
