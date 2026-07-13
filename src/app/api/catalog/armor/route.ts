import { NextResponse } from "next/server";
import { z } from "zod";

import { resolveOwnedCatalogContext } from "@/app/api/catalog/_ownedFilter";
import { emptyFilterMessage } from "@/lib/catalog/emptyFilterResult";
import { filterArmorCatalog } from "@/lib/catalog/filterItems";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import { loadLegendaryArmorRows } from "@/lib/catalog/legendaryArmor";
import { resolveSetBonusFilter } from "@/lib/catalog/setBonusFilter";
import { attachInstancePointers } from "@/lib/inventory/instances/catalogPointer";
import { getDb } from "@/lib/db/client";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

/** Collect multi-value query params: repeated keys and/or comma-separated. */
function multiQuery(url: URL, keys: string[]): string[] | undefined {
  const values: string[] = [];
  for (const key of keys) {
    for (const raw of url.searchParams.getAll(key)) {
      for (const part of raw.split(",")) {
        const t = part.trim();
        if (t) values.push(t);
      }
    }
  }
  return values.length > 0 ? [...new Set(values)] : undefined;
}

const querySchema = z.object({
  scope: z.enum(["all", "owned"]).default("all"),
  q: z.string().trim().optional(),
  slot: z.enum(["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"]).optional(),
  className: z.enum(["Titan", "Hunter", "Warlock"]).optional(),
  frame: z.string().trim().optional(),
  frames: z.array(z.string().trim().min(1)).optional(),
  setBonus: z.string().trim().optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
  includeInstancePointer: z.enum(["0", "1"]).optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    scope: url.searchParams.get("scope") ?? "all",
    q: url.searchParams.get("q") ?? undefined,
    slot: url.searchParams.get("slot") ?? undefined,
    className: url.searchParams.get("className") ?? undefined,
    frame: url.searchParams.get("frame") ?? undefined,
    frames: multiQuery(url, ["frame", "frames"]),
    setBonus: url.searchParams.get("setBonus") ?? undefined,
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

  const ownedContext = await resolveOwnedCatalogContext(request, db, "armor");

  if (parsed.data.scope === "owned") {
    if (!ownedContext) {
      return NextResponse.json({
        items: [],
        syncPrompt: true,
        message: "Sign in and sync inventory for owned armor",
      });
    }
    ownedHashes = ownedContext.ownedHashes;
    syncPrompt = ownedContext.syncPrompt;
  } else if (ownedContext) {
    ownedHashes = ownedContext.ownedHashes;
  }

  try {
    const { entityCache, manifest } = await getServices();
    const manifestStatus = await manifest.getStatus();
    const exoticArmor = await entityCache.getStore("exotic-armor");

    let armorHashAllowlist: Set<number> | undefined;
    let legendaryArmor:
      | Awaited<ReturnType<typeof loadLegendaryArmorRows>>
      | undefined;

    if (parsed.data.setBonus?.trim()) {
      const setBonuses = await entityCache.getStore("set-bonuses");
      const resolution = resolveSetBonusFilter(parsed.data.setBonus, setBonuses);
      if (!resolution.ok) {
        return NextResponse.json({
          items: [],
          count: 0,
          scope: parsed.data.scope,
          syncPrompt: parsed.data.scope === "owned" ? syncPrompt : false,
          message: emptyFilterMessage({ setBonus: parsed.data.setBonus }),
        });
      }
      armorHashAllowlist = resolution.armorHashes;
      if (manifestStatus.cachedVersion) {
        legendaryArmor = await loadLegendaryArmorRows(
          resolution.sets,
          manifest,
          manifestStatus.cachedVersion,
        );
      }
    }

    const storeHashes = new Set([
      ...exoticArmor.map((armor) => armor.hash),
      ...(legendaryArmor?.map((row) => row.hash) ?? []),
    ]);
    const unknownOwnedHashes = [...ownedHashes.keys()].filter((hash) => !storeHashes.has(hash));
    const inventoryProjections =
      unknownOwnedHashes.length > 0 && manifestStatus.cachedVersion
        ? await resolveInventoryHashProjections(
            manifest,
            manifestStatus.cachedVersion,
            unknownOwnedHashes,
          )
        : new Map();

    const filtered = filterArmorCatalog(
      { exoticArmor, legendaryArmor },
      {
        ...parsed.data,
        ownedHashes,
        inventoryProjections,
        armorHashAllowlist,
      },
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
