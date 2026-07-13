"use client";

import {
  DesignationIcon,
  iconFromMap,
} from "@/components/ui/DesignationIcon";
import { OfficialFilterIcon } from "@/components/ui/OfficialFilterIcon";
import { useDesignationIcons } from "@/components/ui/useDesignationIcons";
import {
  visualForArmorArchetype,
  visualForElement,
  visualForWeaponFrame,
} from "@/lib/destiny/catalogFilterVisuals";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import {
  formatSynergyTypeDesignation,
  getSynergyTypeLabel,
} from "@/lib/synergies/generateSynergyName";

/**
 * Dense designation chrome: `Verb: <icon+color>` when subtype art exists,
 * otherwise full text `Verb: Devour`. Title always includes the full string.
 */
export function DesignationLabel({
  type,
  subType,
  icon: iconProp,
  size = 18,
  className = "",
  /** When true, hide the category prefix if an icon is shown. */
  iconOnly = false,
}: {
  type: string;
  subType?: string | null;
  /** Pre-resolved Bungie path; otherwise fetched via designation-icons map. */
  icon?: string | null;
  size?: number;
  className?: string;
  iconOnly?: boolean;
}) {
  const full = formatSynergyTypeDesignation({ type, subType });
  const category = getSynergyTypeLabel(type);
  const sub = subType?.trim() || null;

  const { icons } = useDesignationIcons(
    iconProp !== undefined
      ? []
      : sub
        ? [{ type, subType: sub }]
        : [],
  );

  const mapped =
    iconProp !== undefined
      ? iconProp
      : iconFromMap(icons, type, sub);

  const elementVisual =
    type === "element" && sub ? visualForElement(sub) : null;
  const frameVisual = sub ? visualForWeaponFrame(sub) : null;
  const armorVisual = sub ? visualForArmorArchetype(sub) : null;

  const resolvedIcon =
    mapped ??
    elementVisual?.icon ??
    frameVisual?.icon ??
    armorVisual?.icon ??
    null;

  const accent =
    elementVisual?.color ??
    (sub && isDestinyElement(sub)
      ? ELEMENT_CSS_COLOR[sub as DestinyElement]
      : null) ??
    frameVisual?.color ??
    armorVisual?.color ??
    null;

  if (!sub) {
    return (
      <span className={className} title={full}>
        {category}
      </span>
    );
  }

  if (resolvedIcon) {
    return (
      <span
        className={`inline-flex items-center gap-1 min-w-0 ${className}`.trim()}
        title={full}
        aria-label={full}
      >
        {!iconOnly ? (
          <span className="text-[10px] tracking-wide text-muted shrink-0">
            {category}:
          </span>
        ) : null}
        {elementVisual || frameVisual || armorVisual ? (
          <span
            className="inline-flex shrink-0"
            style={accent ? { color: accent } : undefined}
          >
            <OfficialFilterIcon
              icon={resolvedIcon}
              label={sub}
              size={size}
            />
          </span>
        ) : (
          <DesignationIcon
            type={type}
            subType={sub}
            icon={resolvedIcon}
            size={size}
            label={full}
            accentColor={accent}
          />
        )}
      </span>
    );
  }

  return (
    <span className={className} title={full}>
      {full}
    </span>
  );
}
