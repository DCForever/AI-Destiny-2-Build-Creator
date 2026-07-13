"use client";

import type { ReactNode } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";

import { InfoHotspot } from "./InfoHotspot";
import { Text } from "./Text";

export type EntityHotspotShowLabel = "auto" | "always" | "never";

/**
 * Icon-first entity chip with description popover.
 * When an icon is available, prefers icon (+ optional accent) over the name.
 */
export function EntityHotspot({
  name,
  kind,
  description,
  icon,
  accentColor,
  size = 28,
  showLabel = "auto",
  meta,
  className = "",
  children,
}: {
  name: string;
  kind?: string;
  description?: string | null;
  icon?: string | null;
  accentColor?: string | null;
  size?: number;
  showLabel?: EntityHotspotShowLabel;
  /** Extra popover lines (slot, element, etc.). */
  meta?: string[];
  className?: string;
  /** Override trigger content entirely. */
  children?: ReactNode;
}) {
  const desc = description?.trim() ?? "";
  const lines = [
    ...(meta ?? []).filter(Boolean),
    desc || "No catalog description",
  ];

  const hasIcon = Boolean(icon);
  const labelVisible =
    showLabel === "always" || (showLabel === "auto" && !hasIcon);

  const trigger =
    children ??
    (
      <span className="inline-flex items-center gap-1.5 min-w-0">
        <ItemIcon
          icon={icon ?? null}
          name={name}
          size={size}
          accentColor={accentColor}
        />
        {labelVisible ? (
          <Text size="sm" as="span" className="truncate whitespace-nowrap">
            {name}
          </Text>
        ) : null}
      </span>
    );

  return (
    <InfoHotspot
      title={name}
      kind={kind}
      lines={lines}
      icon={icon ?? null}
      accentColor={accentColor}
      className={className}
    >
      {trigger}
    </InfoHotspot>
  );
}
