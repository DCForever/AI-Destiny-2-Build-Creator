import { NextResponse } from "next/server";
import { z } from "zod";

import { resolveOwnedCatalogContext } from "@/app/api/catalog/_ownedFilter";
import { filterWeaponCatalog } from "@/lib/catalog/filterItems";
import { attachInstancePointers } from "@/lib/inventory/instances/catalogPointer";
import { getDb } from "@/lib/db/client";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  scope: z.enum(["all", "owned"]).default("all"),
  q: z.string().trim().optional(),
  slot: z.enum(["Kinetic", "Energy", "Power"]).optional(),
  itemType: z.string().trim().optional(),
  frame: z.string().trim().optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
  includeInstancePointer: z.enum(["0", "1"]).optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    scope: url.searchParams.get("scope") ?? "all",
    q: url.searchParams.get("q") ?? undefined,
    itemType: url.searchParams.get("itemType") ?? undefined,
    frame: url.searchParams.get("frame") ?? undefined,
    slot: url.searchParams.get("slot") ?? undefined,
    limit: url.searchParams.get("limit") ?? "100",
    includeInstancePointer: url.searchParams.get("includeInstancePointer") ?? undefined,
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
    const owned = await resolveOwnedCatalogContext(request, db, "weapons");
    if (!owned) {
      return NextResponse.json({
        items: [],
        syncPrompt: true,
        message: "Sign in and sync inventory for owned weapons",
      });
    }
    ownedHashes = owned.ownedHashes;
    syncPrompt = owned.syncPrompt;
  }

  try {
    const { entityCache } = await getServices();
    const [weapons, exoticWeapons] = await Promise.all([
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
    ]);

    const filtered = filterWeaponCatalog(
      { weapons, exoticWeapons },
      { ...parsed.data, ownedHashes },
    );

    const includePointer =
      parsed.data.scope === "owned" && parsed.data.includeInstancePointer === "1";
    const items = attachInstancePointers(filtered, includePointer);

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
