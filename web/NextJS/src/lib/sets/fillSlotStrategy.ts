import type { SetType } from "@/lib/sets/schemas";

export type FillStrategy =
  | { kind: "catalog"; catalogKind: "weapons" | "armor" }
  | {
      kind: "manifest";
      category: "exotic-weapons" | "exotic-armor" | "mods";
      label: string;
    }
  | {
      kind: "manual_hash_name";
      label: string;
      hint: string;
    };

/**
 * How production Sets slot-fill should pick an item for a set type + slot.
 * Fashion has no catalog store — use explicit hash + display name (same as debug).
 */
export function fillStrategyForSet(type: SetType, slot: string): FillStrategy {
  if (type === "weapon") {
    return { kind: "catalog", catalogKind: "weapons" };
  }
  if (type === "armor") {
    return { kind: "catalog", catalogKind: "armor" };
  }
  if (type === "mod") {
    const piece =
      slot === "helmet"
        ? "Helmet"
        : slot === "arms"
          ? "Arms"
          : slot === "chest"
            ? "Chest"
            : slot === "legs"
              ? "Legs"
              : slot === "class_item"
                ? "Class item"
                : slot.includes(":")
                  ? slot.split(":")[0]
                  : "armor";
    return {
      kind: "manifest",
      category: "mods",
      label: `Mods for ${piece} (slot-scoped or general)`,
    };
  }
  if (type === "pair") {
    if (slot === "exotic_weapon" || slot.includes("weapon")) {
      return {
        kind: "manifest",
        category: "exotic-weapons",
        label: "Exotic weapon",
      };
    }
    return {
      kind: "manifest",
      category: "exotic-armor",
      label: "Exotic armor",
    };
  }
  // fashion and any other non-catalog cosmetic slot
  return {
    kind: "manual_hash_name",
    label: "Fashion / cosmetic item",
    hint:
      "Enter the Bungie item hash and display name (cosmetics are not in the weapon/armor catalog).",
  };
}
