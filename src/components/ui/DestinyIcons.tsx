"use client";

import type { CSSProperties } from "react";

import {
  CLASS_CSS_COLOR,
  ELEMENT_CSS_COLOR,
  type DestinyElement,
  type GuardianClassName,
} from "@/lib/destiny/identityVisuals";

type IconProps = {
  size?: number;
  title?: string;
  className?: string;
  style?: CSSProperties;
};

export function ClassIcon({
  className: guardianClass,
  size = 14,
  title,
  color,
}: IconProps & { className: GuardianClassName; color?: string }) {
  const stroke = color ?? CLASS_CSS_COLOR[guardianClass];
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 16 16",
    fill: "none" as const,
    "aria-label": title ?? guardianClass,
    role: "img" as const,
  };

  if (guardianClass === "Titan") {
    return (
      <svg {...common}>
        <title>{title ?? guardianClass}</title>
        <path
          d="M8 1.5 L13 4.5 V9.5 L8 14.5 L3 9.5 V4.5 Z"
          stroke={stroke}
          strokeWidth="1.4"
          fill={stroke}
          fillOpacity="0.2"
        />
      </svg>
    );
  }
  if (guardianClass === "Hunter") {
    return (
      <svg {...common}>
        <title>{title ?? guardianClass}</title>
        <path
          d="M8 2 L12 7 L8 14 L4 7 Z"
          stroke={stroke}
          strokeWidth="1.4"
          fill={stroke}
          fillOpacity="0.2"
        />
      </svg>
    );
  }
  return (
    <svg {...common}>
      <title>{title ?? guardianClass}</title>
      <circle
        cx="8"
        cy="8"
        r="5.5"
        stroke={stroke}
        strokeWidth="1.4"
        fill={stroke}
        fillOpacity="0.2"
      />
      <circle cx="8" cy="8" r="2" fill={stroke} />
    </svg>
  );
}

export function ElementIcon({
  element,
  size = 12,
  title,
  color,
}: IconProps & { element: DestinyElement; color?: string }) {
  const stroke = color ?? ELEMENT_CSS_COLOR[element];
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 16 16",
    fill: "none" as const,
    "aria-label": title ?? element,
    role: "img" as const,
  };
  const strokeProps = { stroke, strokeWidth: 1.4 as const };
  const fillProps = { fill: stroke, fillOpacity: 0.35 };

  if (element === "Kinetic") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <circle cx="8" cy="8" r="5.2" {...strokeProps} {...fillProps} />
      </svg>
    );
  }
  if (element === "Void") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <path d="M8 2 L13.5 13 H2.5 Z" {...strokeProps} {...fillProps} />
      </svg>
    );
  }
  if (element === "Arc") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <path
          d="M9 1.5 L4 8.5 H7.5 L6.5 14.5 L12.5 7 H9 Z"
          {...strokeProps}
          {...fillProps}
        />
      </svg>
    );
  }
  if (element === "Strand") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <path
          d="M4 3 C8 5 8 11 12 13 M12 3 C8 5 8 11 4 13 M3 8 H13"
          stroke={stroke}
          strokeWidth="1.4"
          fill="none"
        />
      </svg>
    );
  }
  if (element === "Stasis") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <path
          d="M8 1.5 L13 4.5 V11.5 L8 14.5 L3 11.5 V4.5 Z"
          {...strokeProps}
          {...fillProps}
        />
      </svg>
    );
  }
  if (element === "Prismatic") {
    return (
      <svg {...common}>
        <title>{title ?? element}</title>
        <path
          d="M8 2 L10 6 L14 6.5 L11 9.5 L12 14 L8 11.5 L4 14 L5 9.5 L2 6.5 L6 6 Z"
          {...strokeProps}
          {...fillProps}
        />
      </svg>
    );
  }
  // Solar
  return (
    <svg {...common}>
      <title>{title ?? element}</title>
      <path d="M8 1.5 L14 8 L8 14.5 L2 8 Z" {...strokeProps} {...fillProps} />
    </svg>
  );
}

export function SuperIcon({
  size = 14,
  title,
  color,
}: IconProps & { color?: string }) {
  const stroke = color ?? "var(--accent)";
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      fill="none"
      aria-label={title ?? "Super"}
      role="img"
    >
      <title>{title ?? "Super"}</title>
      <path
        d="M8 1 L9.2 5.8 L14 6.2 L10.2 9.2 L11.5 14 L8 11.4 L4.5 14 L5.8 9.2 L2 6.2 L6.8 5.8 Z"
        stroke={stroke}
        strokeWidth="1.2"
        fill={stroke}
        fillOpacity="0.4"
      />
    </svg>
  );
}

export type AmmoTypeName = "Primary" | "Special" | "Heavy";

/** Compact ammo-type glyph for icon-only catalog filters. */
export function AmmoIcon({
  ammo,
  size = 14,
  title,
  color = "currentColor",
}: IconProps & { ammo: AmmoTypeName; color?: string }) {
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 16 16",
    fill: "none" as const,
    "aria-label": title ?? ammo,
    role: "img" as const,
  };
  if (ammo === "Primary") {
    return (
      <svg {...common}>
        <title>{title ?? ammo}</title>
        <circle cx="8" cy="8" r="3.2" stroke={color} strokeWidth="1.4" fill={color} fillOpacity="0.35" />
      </svg>
    );
  }
  if (ammo === "Special") {
    return (
      <svg {...common}>
        <title>{title ?? ammo}</title>
        <circle cx="5" cy="8" r="2.4" stroke={color} strokeWidth="1.3" fill={color} fillOpacity="0.35" />
        <circle cx="11" cy="8" r="2.4" stroke={color} strokeWidth="1.3" fill={color} fillOpacity="0.35" />
      </svg>
    );
  }
  return (
    <svg {...common}>
      <title>{title ?? ammo}</title>
      <circle cx="3.5" cy="8" r="2" stroke={color} strokeWidth="1.2" fill={color} fillOpacity="0.35" />
      <circle cx="8" cy="8" r="2" stroke={color} strokeWidth="1.2" fill={color} fillOpacity="0.35" />
      <circle cx="12.5" cy="8" r="2" stroke={color} strokeWidth="1.2" fill={color} fillOpacity="0.35" />
    </svg>
  );
}

/** Compact glyph badge used next to labels. */
export function IconBadge({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <span
      title={label}
      className="inline-flex items-center justify-center leading-none"
      aria-label={label}
    >
      {children}
    </span>
  );
}
