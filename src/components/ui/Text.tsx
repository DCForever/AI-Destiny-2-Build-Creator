import type { ReactNode } from "react";

type Tone = "default" | "muted" | "accent" | "danger" | "warning" | "success";

const TONE: Record<Tone, string> = {
  default: "text-foreground",
  muted: "text-muted",
  accent: "text-accent",
  danger: "text-danger",
  warning: "text-warning",
  success: "text-success",
};

export function Text({
  children,
  size = "md",
  tone = "default",
  weight = "normal",
  className = "",
  as: Tag = "p",
}: {
  children: ReactNode;
  size?: "xs" | "sm" | "md";
  tone?: Tone;
  weight?: "normal" | "medium" | "semibold";
  className?: string;
  as?: "p" | "span" | "div";
}) {
  const sizeClass =
    size === "xs" ? "text-[11px]" : size === "sm" ? "text-sm" : "text-base";
  const weightClass =
    weight === "semibold"
      ? "font-medium"
      : weight === "medium"
        ? "font-medium"
        : "";

  return (
    <Tag
      className={`${sizeClass} ${TONE[tone]} ${weightClass} ${className}`.trim()}
    >
      {children}
    </Tag>
  );
}

export function Heading({
  children,
  level = 1,
  className = "",
}: {
  children: ReactNode;
  level?: 1 | 2 | 3;
  className?: string;
}) {
  const Tag = (`h${level}` as const);
  const size =
    level === 1 ? "text-lg" : level === 2 ? "text-sm tracking-wide uppercase text-accent" : "text-xs tracking-[0.14em] uppercase text-muted";
  return <Tag className={`${size} text-foreground ${className}`.trim()}>{children}</Tag>;
}
