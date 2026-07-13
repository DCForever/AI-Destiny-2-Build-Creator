import { NextResponse } from "next/server";
import { z } from "zod";

import {
  DEFAULT_HASH_STORES,
  resolveEntityPresentations,
  type PresentationStore,
} from "@/lib/catalog/entityPresentation";

export const runtime = "nodejs";

const storeSchema = z.enum([
  "weapons",
  "exotic-weapons",
  "exotic-armor",
  "weapon-perks",
  "origin-traits",
  "mods",
  "aspects",
  "fragments",
  "abilities",
  "artifacts",
  "set-bonuses",
]);

const refSchema = z.union([
  z.object({
    by: z.literal("hash"),
    hash: z.number().int(),
    stores: z.array(storeSchema).max(12).optional(),
  }),
  z.object({
    by: z.literal("name"),
    name: z.string().trim().min(1).max(120),
    stores: z.array(storeSchema).min(1).max(12),
  }),
]);

const bodySchema = z.object({
  refs: z.array(refSchema).min(1).max(50),
});

/**
 * Batch-resolve entity name/icon/description for UI hotspots.
 * POST { refs: EntityRef[] } → { results: EntityPresentation[] }
 */
export async function POST(request: Request) {
  try {
    const json: unknown = await request.json();
    const parsed = bodySchema.safeParse(json);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid body", details: parsed.error.flatten() },
        { status: 400 },
      );
    }

    const refs = parsed.data.refs.map((ref) => {
      if (ref.by === "hash") {
        return {
          by: "hash" as const,
          hash: ref.hash,
          stores: (ref.stores ?? [...DEFAULT_HASH_STORES]) as PresentationStore[],
        };
      }
      return {
        by: "name" as const,
        name: ref.name,
        stores: ref.stores as PresentationStore[],
      };
    });

    const results = await resolveEntityPresentations(refs);
    return NextResponse.json({ results });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to resolve entity presentation";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
