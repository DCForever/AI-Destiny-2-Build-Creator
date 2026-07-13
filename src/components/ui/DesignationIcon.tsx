"use client";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import { ElementIcon } from "@/components/ui/DestinyIcons";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import { designationIconKey } from "@/lib/synergies/designationIcons";

/**
 * Official Bungie icon for a designation when mapped; otherwise element glyph
 * for element types, else letter placeholder via ItemIcon.
 */
export function DesignationIcon({
  type,
  subType,
  icon,
  size = 28,
  label,
}: {
  type: string;
  subType?: string | null;
  /** Relative Bungie path from designation-icons API / map */
  icon?: string | null;
  size?: number;
  label?: string;
}) {
  const name = label ?? subType ?? type;

  if (icon) {
    return <ItemIcon icon={icon} name={name} size={size} />;
  }

  if (type === "element" && subType && isDestinyElement(subType)) {
    return (
      <ElementIcon
        element={subType as DestinyElement}
        color={ELEMENT_CSS_COLOR[subType as DestinyElement]}
        size={size}
        title={subType}
      />
    );
  }

  return <ItemIcon icon={null} name={name} size={size} />;
}

export function iconFromMap(
  icons: Record<string, string | null> | undefined,
  type: string,
  subType?: string | null,
): string | null {
  if (!icons) return null;
  return icons[designationIconKey(type, subType)] ?? null;
}
