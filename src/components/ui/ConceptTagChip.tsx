"use client";

import type { ButtonHTMLAttributes } from "react";

import { Chip } from "@/components/ui/Chip";
import {
  DesignationIcon,
  iconFromMap,
} from "@/components/ui/DesignationIcon";
import { useCuratedDesignationIcons } from "@/components/ui/useDesignationIcons";
import {
  conceptTagVisual,
  type ConceptTagVisual,
} from "@/lib/sets/conceptTagVisuals";

function useTagIcon(visual: ConceptTagVisual): string | null {
  const { icons } = useCuratedDesignationIcons();
  if (!visual.designation) return null;
  return iconFromMap(
    icons,
    visual.designation.type,
    visual.designation.subType,
  );
}

/** Prefer glyph/icon over text when art or element SVG is available. */
function preferIcon(visual: ConceptTagVisual, icon: string | null): boolean {
  if (icon) return true;
  if (visual.hasGlyphFallback) return true;
  return false;
}

/**
 * Icon-first concept tag chip (Arc color glyph, Grenade ability art, etc.).
 * Falls back to a text Chip when no icon/glyph is available.
 */
export function ConceptTagChip({
  tagId,
  size = 20,
  className = "",
}: {
  tagId: string;
  size?: number;
  className?: string;
}) {
  const visual = conceptTagVisual(tagId);
  const icon = useTagIcon(visual);

  if (preferIcon(visual, icon) && visual.designation) {
    return (
      <span
        className={`inline-flex items-center ${className}`.trim()}
        title={visual.label}
        aria-label={visual.label}
      >
        <DesignationIcon
          type={visual.designation.type}
          subType={visual.designation.subType}
          icon={icon}
          size={size}
          label={visual.label}
          accentColor={visual.accentColor}
        />
      </span>
    );
  }

  return <Chip className={className}>{visual.label}</Chip>;
}

/**
 * Toggle filter for concept tags — icon when available, label otherwise.
 */
export function ConceptTagFilterChip({
  tagId,
  active,
  onClick,
  size = 18,
  className = "",
  ...rest
}: {
  tagId: string;
  active: boolean;
  onClick: () => void;
  size?: number;
  className?: string;
} & Omit<ButtonHTMLAttributes<HTMLButtonElement>, "children" | "onClick">) {
  const visual = conceptTagVisual(tagId);
  const icon = useTagIcon(visual);
  const showIcon = preferIcon(visual, icon) && visual.designation;

  const accentStyle =
    active && visual.accentColor
      ? {
          borderColor: visual.accentColor,
          color: visual.accentColor,
          backgroundColor: `color-mix(in srgb, ${visual.accentColor} 12%, transparent)`,
        }
      : undefined;

  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      title={visual.label}
      aria-label={visual.label}
      className={`inline-flex items-center justify-center min-h-[28px] min-w-[28px] text-[10px] tracking-widest uppercase px-1.5 py-1 border transition-colors ${
        active
          ? "border-accent text-accent bg-accent/10"
          : "border-line text-muted hover:text-foreground"
      } ${className}`.trim()}
      style={accentStyle}
      {...rest}
    >
      {showIcon && visual.designation ? (
        <DesignationIcon
          type={visual.designation.type}
          subType={visual.designation.subType}
          icon={icon}
          size={size}
          label={visual.label}
          accentColor={visual.accentColor}
        />
      ) : (
        visual.label
      )}
    </button>
  );
}
