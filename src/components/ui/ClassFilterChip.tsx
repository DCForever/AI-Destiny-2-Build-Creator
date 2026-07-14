"use client";

import { FilterChip, type FilterChipMode } from "@/components/ui/Chip";
import { ClassIcon } from "@/components/ui/DestinyIcons";
import {
  CLASS_CSS_COLOR,
  type GuardianClassName,
} from "@/lib/destiny/identityVisuals";

/** Dense class toggle: official-style class glyph + class color when active. */
export function ClassFilterChip({
  className: guardianClass,
  active,
  onClick,
  size = "xs",
  mode,
}: {
  className: GuardianClassName;
  active: boolean;
  onClick: () => void;
  size?: "xs" | "md";
  /** off | include | exclude — when set, overrides binary `active` styling. */
  mode?: FilterChipMode;
}) {
  const color = CLASS_CSS_COLOR[guardianClass];
  const resolved: FilterChipMode = mode ?? (active ? "include" : "off");
  return (
    <FilterChip
      label={guardianClass}
      active={resolved !== "off"}
      mode={resolved}
      onClick={onClick}
      size={size}
      iconOnly
      icon={
        <ClassIcon
          className={guardianClass}
          color={resolved === "off" ? color : color}
          size={14}
        />
      }
      activeStyle={{
        borderColor: color,
        boxShadow: `0 0 0 1px ${color}`,
        backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
      }}
    />
  );
}
