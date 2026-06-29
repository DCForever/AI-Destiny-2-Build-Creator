import { NextResponse } from "next/server";
import { z } from "zod";

import { resolveOwnedCatalogContext } from "@/app/api/catalog/_ownedFilter";
import { filterArmorCatalog } from "@/lib/catalog/filterItems";
import { getDb } from "@/lib/db/client";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  scope: z.enum(["all", "owned"]).default("all"),
  q: z.string().trim().optional(),
  slot: z.enum(["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"]).optional(),
  className: z.enum(["Titan", "Hunter", "Warlock"]).optional(),
  frame: z.string().trim().optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    scope: url.searchParams.get("scope") ?? "all",
    q: url.searchParams.get("q") ?? undefined,
    slot: url.searchParams.get("slot") ?? undefined,
    className: url.searchParams.get("className") ?? undefined,
    frame: url.searchParams.get("frame") ?? undefined,
    limit: url.searchParams.get("limit") ?? "100",
  });

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  const db = getDb();
  let ownedHashes = new Map<number, number>();
  let syncPrompt = false;

  if (parsed.data.scope === "owned") {
    const owned = await resolveOwnedCatalogContext(request, db, "armor");
    if (!owned) {
      return NextResponse.json({
        items: [],
        syncPrompt: true,
        message: "Sign in and sync inventory for owned armor",
      });
    }
    ownedHashes = owned.ownedHashes;
    syncPrompt = owned.syncPrompt;
  }

  try {
    const { entityCache } = await getServices();
    const exoticArmor = await entityCache.getStore("exotic-armor");

    const items = filterArmorCatalog({ exoticArmor }, { ...parsed.data, ownedHashes });

    return NextResponse.json({
      items,
      count: items.length,
      scope: parsed.data.scope,
      syncPrompt: parsed.data.scope === "owned" ? syncPrompt : false,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Catalog filter failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
