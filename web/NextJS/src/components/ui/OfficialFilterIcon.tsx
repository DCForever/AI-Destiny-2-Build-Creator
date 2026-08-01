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
    <span
      className="inline-flex items-center justify-center shrink-0 rounded-sm"
      style={{
        width: size,
        height: size,
        /* Dark well keeps light Bungie glyphs legible on light theme. */
        backgroundColor: "#12151c",
      }}
    >
      <Image
        src={bungieIconUrl(icon)}
        alt={label}
        width={size}
        height={size}
        className="block"
        unoptimized
      />
    </span>
  );
}
