"use client";

import { weaponTypeIconPath } from "@/lib/destiny/weaponTypeIcons";

/**
 * Monochrome weapon-type glyph from destiny-icons (same set DIM Organizer uses).
 * Painted with currentColor via CSS mask so it inherits chip/text color.
 */
export function WeaponTypeIcon({
  typeName,
  size = 16,
  className = "",
}: {
  typeName: string;
  /** Glyph height in px; width scales for wide destiny-icons aspect ratios. */
  size?: number;
  className?: string;
}) {
  const src = weaponTypeIconPath(typeName);
  if (!src) return null;

  // destiny-icons weapon silhouettes are wide (~2.5–3:1); keep height fixed.
  const width = Math.round(size * 2.4);

  return (
    <span
      role="img"
      aria-label={typeName}
      title={typeName}
      className={`inline-block shrink-0 bg-current ${className}`.trim()}
      style={{
        width,
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
