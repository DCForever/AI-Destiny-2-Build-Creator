import { getSubclassMeta } from "@/data/subclasses";
import type { ElementName } from "@/lib/manifest/types/records";

export type DestinyElement =
  | "Kinetic"
  | "Arc"
  | "Solar"
  | "Void"
  | "Stasis"
  | "Strand"
  | "Prismatic";

export type GuardianClassName = "Titan" | "Hunter" | "Warlock";

/** Tailwind text color classes for guardian classes (canvas palette). */
export const CLASS_TEXT_CLASS: Record<GuardianClassName, string> = {
  Titan: "text-solar",
  Hunter: "text-arc",
  Warlock: "text-void",
};

/**
 * Element tints aligned with DestinyDamageTypeDefinition.color (official).
 * CSS vars in globals.css mirror these for Tailwind utility classes.
 */
export const ELEMENT_CSS_COLOR: Record<DestinyElement, string> = {
  Kinetic: "var(--element-kinetic)",
  Arc: "var(--element-arc)",
  Solar: "var(--element-solar)",
  Void: "var(--element-void)",
  Stasis: "var(--element-stasis)",
  Strand: "var(--element-strand)",
  Prismatic: "var(--element-prismatic)",
};

export const CLASS_CSS_COLOR: Record<GuardianClassName, string> = {
  Titan: "var(--element-solar)",
  Hunter: "var(--element-arc)",
  Warlock: "var(--element-void)",
};

/** Stable loadout accent colors (Bungie loadout color slots, simplified). */
export const LOADOUT_ACCENT_PALETTE = [
  "#e8b86d", // amber
  "#f0793e", // solar
  "#7ad1f5", // arc
  "#b184c5", // void
  "#3fd680", // strand
  "#4d88ff", // stasis
  "#e2654f", // red
  "#d67ee2", // prismatic
] as const;

export function elementFromSubclass(subclassName: string | null | undefined): DestinyElement {
  if (!subclassName?.trim()) return "Kinetic";
  const meta = getSubclassMeta(subclassName.trim());
  if (meta?.element) return meta.element as DestinyElement;
  // Prismatic variants
  if (/prismatic/i.test(subclassName)) return "Prismatic";
  return "Kinetic";
}

export function subclassNameFromBuildSubclass(subclass: unknown): string | null {
  if (!subclass) return null;
  if (typeof subclass === "string") return subclass;
  if (typeof subclass === "object" && subclass !== null && "name" in subclass) {
    const name = (subclass as { name?: unknown }).name;
    return typeof name === "string" ? name : null;
  }
  return null;
}

/** Pick a stable accent color for a loadout (icon/color chrome without Bungie color hashes). */
export function loadoutAccentColor(seed: string): string {
  let h = 0;
  for (let i = 0; i < seed.length; i++) {
    h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  }
  return LOADOUT_ACCENT_PALETTE[h % LOADOUT_ACCENT_PALETTE.length]!;
}

export function isGuardianClass(value: string): value is GuardianClassName {
  return value === "Titan" || value === "Hunter" || value === "Warlock";
}

export function isDestinyElement(value: string): value is DestinyElement {
  return (
    value === "Kinetic" ||
    value === "Arc" ||
    value === "Solar" ||
    value === "Void" ||
    value === "Stasis" ||
    value === "Strand" ||
    value === "Prismatic"
  );
}

/** ElementName from manifest is compatible with DestinyElement for known values. */
export function toDestinyElement(element: ElementName | string | null | undefined): DestinyElement {
  if (!element) return "Kinetic";
  if (isDestinyElement(element)) return element;
  return "Kinetic";
}
