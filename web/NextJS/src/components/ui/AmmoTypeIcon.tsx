"use client";

import { ammoTypeIconPath } from "@/lib/destiny/ammoTypeIcons";

/**
 * Monochrome ammo-type glyph from destiny-icons (general/ammo-*.svg).
 * Painted with currentColor via CSS mask so it inherits chip/text color.
 */
export function AmmoTypeIcon({
  ammo,
  size = 16,
  className = "",
}: {
  ammo: string;
  size?: number;
  className?: string;
}) {
  const src = ammoTypeIconPath(ammo);
  if (!src) return null;

  return (
    <span
      role="img"
      aria-label={ammo}
      title={ammo}
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
