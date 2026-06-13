import type { AppDatabase } from "@/lib/db/client";
import type { RollTag, UserInventoryItem } from "@/lib/db/types";
import { queryInventoryByBucket } from "@/lib/db/repositories/inventoryRepository";

const WEAPON_SLOTS = ["Kinetic", "Energy", "Power"] as const;
const TOP_N = 5;

function formatItem(item: UserInventoryItem): string {
  const tags = item.rollTags.length > 0 ? ` [${item.rollTags.join(", ")}]` : "";
  const mw = item.isMasterwork ? " MW" : "";
  const crafted = item.isCrafted ? " crafted" : "";
  return `- hash ${item.itemHash} (${item.location}, p${item.power})${mw}${crafted}${tags}`;
}

/**
 * Compact inventory summary for LLM prompts — top tagged candidates per weapon slot.
 */
export function buildInventorySummary(db: AppDatabase, userId: number): string | null {
  const sections: string[] = [];

  for (const slot of WEAPON_SLOTS) {
    const items = queryInventoryByBucket(db, userId, slot);
    if (items.length === 0) continue;

    const prioritized = [...items].sort((a, b) => {
      const aTags = a.rollTags.length;
      const bTags = b.rollTags.length;
      if (aTags !== bTags) return bTags - aTags;
      return b.power - a.power;
    });

    const lines = prioritized.slice(0, TOP_N).map(formatItem);
    sections.push(`${slot} (${items.length} owned):\n${lines.join("\n")}`);
  }

  if (sections.length === 0) return null;
  return sections.join("\n\n");
}

export function itemsWithTag(
  db: AppDatabase,
  userId: number,
  tag: RollTag,
): UserInventoryItem[] {
  const all: UserInventoryItem[] = [];
  for (const slot of WEAPON_SLOTS) {
    all.push(...queryInventoryByBucket(db, userId, slot));
  }
  return all.filter((item) => item.rollTags.includes(tag));
}
