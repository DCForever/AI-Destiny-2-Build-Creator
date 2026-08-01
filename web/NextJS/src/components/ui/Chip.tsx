import type { ButtonHTMLAttributes, CSSProperties, ReactNode } from "react";

export function Chip({
  children,
  accent = false,
  className = "",
  icon,
  title,
}: {
  children?: ReactNode;
  accent?: boolean;
  className?: string;
  /** Leading icon; chip stays dense when children omitted. */
  icon?: ReactNode;
  title?: string;
}) {
  return (
    <span
      title={title}
      className={`inline-flex items-center gap-1 text-[10px] tracking-wide px-2 py-0.5 border whitespace-nowrap ${
        accent ? "border-accent/50 text-accent" : "border-line text-muted"
      } ${className}`.trim()}
    >
      {icon}
      {children}
    </span>
  );
}

/** Read-only meta tag with optional official icon + accent border. */
export function MetaChip({
  label,
  icon,
  accentColor,
  iconOnly = false,
  className = "",
}: {
  label: string;
  icon?: ReactNode;
  accentColor?: string;
  iconOnly?: boolean;
  className?: string;
}) {
  return (
    <span
      title={label}
      aria-label={label}
      style={
        accentColor
          ? {
              borderColor: accentColor,
              color: accentColor,
            }
          : undefined
      }
      className={`inline-flex items-center gap-1 text-[10px] tracking-wide border whitespace-nowrap ${
        iconOnly ? "p-1" : "px-2 py-0.5"
      } ${accentColor ? "" : "border-line text-muted"} ${className}`.trim()}
    >
      {icon}
      {iconOnly ? null : label}
    </span>
  );
}

export type FilterChipMode = "off" | "include" | "exclude";

export function FilterChip({
  label,
  active,
  onClick,
  className = "",
  icon,
  iconOnly = false,
  size = "md",
  activeStyle,
  /** off | include | exclude — when set, overrides binary `active` styling. */
  mode,
  ...rest
}: {
  label: string;
  active: boolean;
  onClick: () => void;
  className?: string;
  /** Optional leading icon (or sole content when iconOnly). */
  icon?: ReactNode;
  /** Render icon only; label is still used for aria-label/title. */
  iconOnly?: boolean;
  /** Dense catalog toolbars use xs. */
  size?: "xs" | "md";
  /** Inline style overrides for active state (e.g. element-colored border). */
  activeStyle?: CSSProperties;
  mode?: FilterChipMode;
} & Omit<ButtonHTMLAttributes<HTMLButtonElement>, "children" | "onClick">) {
  const dense = size === "xs";
  const resolved: FilterChipMode =
    mode ?? (active ? "include" : "off");
  const pressed = resolved !== "off";
  const modeTitle =
    resolved === "include"
      ? `${label} (include) — click to exclude`
      : resolved === "exclude"
        ? `${label} (exclude) — click to clear`
        : `${label} — click to include`;
  const toneClass =
    resolved === "include"
      ? "border-accent text-accent bg-accent/10"
      : resolved === "exclude"
        ? "border-danger/60 text-danger bg-danger/10 line-through decoration-danger/80"
        : "border-line text-muted hover:text-foreground";
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={pressed}
      aria-label={modeTitle}
      title={modeTitle}
      style={
        resolved === "include" && activeStyle
          ? activeStyle
          : resolved === "exclude" && activeStyle
            ? {
                ...activeStyle,
                borderColor: "var(--danger, #e85d5d)",
                opacity: 0.95,
              }
            : undefined
      }
      className={`${
        iconOnly
          ? dense
            ? "inline-flex items-center justify-center p-1 border transition-colors"
            : "inline-flex items-center justify-center p-1.5 border transition-colors"
          : dense
            ? "text-[9px] tracking-wide uppercase px-1.5 py-0.5 border transition-colors"
            : "text-[10px] tracking-widest uppercase px-2 py-1 border transition-colors"
      } ${toneClass} ${className}`.trim()}
      {...rest}
    >
      {iconOnly ? (
        icon
      ) : (
        <>
          {icon}
          {label}
        </>
      )}
    </button>
  );
}
