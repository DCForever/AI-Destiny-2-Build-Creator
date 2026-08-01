"use client";

import Image from "next/image";
import { useState } from "react";

interface ItemIconProps {
  icon: string | null;
  name: string;
  size?: number;
  /** Optional element/class accent for border ring. */
  accentColor?: string | null;
}

const NOTCH_CLIP =
  "polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px)";

/**
 * Dark plate behind Bungie art so white/light perk glyphs stay visible on the
 * light theme (and match in-game inventory wells on dark).
 */
const ICON_WELL_BG = "#12151c";

function PlaceholderIcon({
  name,
  size,
  accentColor,
}: {
  name: string;
  size: number;
  accentColor?: string | null;
}) {
  return (
    <div
      className="flex items-center justify-center border text-muted text-xs font-mono flex-shrink-0"
      style={{
        width: size,
        height: size,
        clipPath: NOTCH_CLIP,
        backgroundColor: ICON_WELL_BG,
        color: "#8a93a6",
        borderColor: accentColor ?? "var(--line)",
        boxShadow: accentColor ? `inset 0 0 0 1px ${accentColor}44` : undefined,
      }}
      aria-label={name}
    >
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

export function ItemIcon({
  icon,
  name,
  size = 40,
  accentColor,
}: ItemIconProps) {
  const [failed, setFailed] = useState(false);

  if (!icon || failed) {
    return (
      <PlaceholderIcon name={name} size={size} accentColor={accentColor} />
    );
  }

  const src = icon.startsWith("http") ? icon : `https://www.bungie.net${icon}`;

  return (
    <div
      className="border overflow-hidden flex-shrink-0"
      style={{
        width: size,
        height: size,
        clipPath: NOTCH_CLIP,
        backgroundColor: ICON_WELL_BG,
        borderColor: accentColor ?? "var(--line)",
        boxShadow: accentColor ? `inset 0 0 0 1px ${accentColor}44` : undefined,
      }}
    >
      <Image
        src={src}
        alt={name}
        width={size}
        height={size}
        className="block"
        unoptimized
        onError={() => setFailed(true)}
      />
    </div>
  );
}
