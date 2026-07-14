"use client";

import { slotIconPath } from "@/lib/destiny/slotIcons";

/**
 * Monochrome armor slot glyph (Helmet, Gauntlets, …) from destiny-icons.
 */
export function SlotIcon({
  slot,
  size = 14,
  className = "",
}: {
  slot: string;
  size?: number;
  className?: string;
}) {
  const src = slotIconPath(slot);
  if (!src) return null;

  return (
    <span
      role="img"
      aria-label={slot}
      title={slot}
      className={`inline-block shrink-0 bg-current ${className}`.trim()}
      style={{
        width: size,
        height: size,
        WebkitMaskImage: `url(${src})`,
        maskImage: `url(${src})`,
        WebkitMaskSize: "contain",
        maskSize: "contain",
        WebkitMaskRepeat: "no-repeat",
        maskRepeat: "no-repeat",
        WebkitMaskPosition: "center",
        maskPosition: "center",
      }}
    />
  );
}
