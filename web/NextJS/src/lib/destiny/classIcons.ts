/**
 * Guardian class → destiny-icons SVG (justrealmilk/destiny-icons general/).
 * Files live under public/destiny-icons/general/ (vendored CC0).
 */

import type { GuardianClassName } from "@/lib/destiny/identityVisuals";

/** Public URL path for a guardian class glyph. */
export const CLASS_ICON_PATH: Record<GuardianClassName, string> = {
  Titan: "/destiny-icons/general/class_titan.svg",
  Hunter: "/destiny-icons/general/class_hunter.svg",
  Warlock: "/destiny-icons/general/class_warlock.svg",
};

export function classIconPath(
  className: string | null | undefined,
): string | null {
  if (!className?.trim()) return null;
  const raw = className.trim();
  if (raw in CLASS_ICON_PATH) {
    return CLASS_ICON_PATH[raw as GuardianClassName];
  }
  const lower = raw.toLowerCase();
  if (lower === "titan") return CLASS_ICON_PATH.Titan;
  if (lower === "hunter") return CLASS_ICON_PATH.Hunter;
  if (lower === "warlock") return CLASS_ICON_PATH.Warlock;
  return null;
}
