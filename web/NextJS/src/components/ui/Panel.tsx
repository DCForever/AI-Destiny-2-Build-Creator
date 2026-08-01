import type { ReactNode } from "react";

type PanelTone = "default" | "raised" | "accent" | "muted" | "danger" | "warning";
type PanelPad = "none" | "sm" | "md" | "lg";

const PAD: Record<PanelPad, string> = {
  none: "p-0",
  sm: "p-2",
  md: "p-3",
  lg: "p-4",
};

const TONE: Record<PanelTone, string> = {
  default: "panel-notch",
  raised: "panel-notch panel-notch-raised",
  accent: "panel-notch border-accent bg-[color-mix(in_srgb,var(--accent)_6%,var(--surface))]",
  muted: "panel-notch bg-surface-raised/40",
  danger: "panel-notch border-danger/40 bg-[color-mix(in_srgb,var(--danger)_6%,var(--surface))]",
  warning: "panel-notch border-warning/40 bg-[color-mix(in_srgb,var(--warning)_6%,var(--surface))]",
};

export function Panel({
  children,
  tone = "default",
  pad = "md",
  className = "",
  as: Tag = "div",
}: {
  children: ReactNode;
  tone?: PanelTone;
  pad?: PanelPad;
  className?: string;
  as?: "div" | "aside" | "article" | "section" | "form";
}) {
  return (
    <Tag className={`${TONE[tone]} ${PAD[pad]} ${className}`.trim()}>
      {children}
    </Tag>
  );
}
