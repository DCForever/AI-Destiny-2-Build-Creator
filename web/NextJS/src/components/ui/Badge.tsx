import type { HTMLAttributes, ReactNode } from "react";

/**
 * Status / readiness badge — square instrument chrome with wash fills.
 * Maps 1:1 to globals.css `.badge` + tone modifiers (DESIGN.md Badge Wash Rule).
 */
export type BadgeTone =
  | "verified"
  | "accent"
  | "fuzzy"
  | "warning"
  | "unresolved"
  | "illegal"
  | "danger";

const TONE_CLASS: Record<BadgeTone, string> = {
  verified: "badge-verified",
  accent: "badge-accent",
  fuzzy: "badge-fuzzy",
  /** Alias of fuzzy — soft miss / caution gold. */
  warning: "badge-fuzzy",
  unresolved: "badge-unresolved",
  illegal: "badge-illegal",
  /** Alias of illegal — hard blocker coral. */
  danger: "badge-illegal",
};

export function badgeToneClass(tone: BadgeTone): string {
  return TONE_CLASS[tone];
}

export function Badge({
  children,
  tone = "accent",
  className = "",
  title,
  ...rest
}: {
  children: ReactNode;
  tone?: BadgeTone;
  className?: string;
  title?: string;
} & Omit<HTMLAttributes<HTMLSpanElement>, "children" | "className" | "title">) {
  return (
    <span
      title={title}
      className={`badge ${badgeToneClass(tone)} ${className}`.trim()}
      {...rest}
    >
      {children}
    </span>
  );
}
