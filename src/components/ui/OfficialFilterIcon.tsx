"use client";

import Image from "next/image";

import { bungieIconUrl } from "@/lib/destiny/catalogFilterVisuals";

/** Official Bungie CDN icon for filter chips (no custom SVG). */
export function OfficialFilterIcon({
  icon,
  label,
  size = 18,
}: {
  icon: string;
  label: string;
  size?: number;
}) {
  return (
    <Image
      src={bungieIconUrl(icon)}
      alt={label}
      width={size}
      height={size}
      className="block"
      unoptimized
    />
  );
}
