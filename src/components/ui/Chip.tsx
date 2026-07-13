import type { ButtonHTMLAttributes, ReactNode } from "react";

export function Chip({
  children,
  accent = false,
  className = "",
}: {
  children: ReactNode;
  accent?: boolean;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center text-[10px] tracking-wide px-2 py-0.5 border whitespace-nowrap ${
        accent ? "border-accent/50 text-accent" : "border-line text-muted"
      } ${className}`.trim()}
    >
      {children}
    </span>
  );
}

export function FilterChip({
  label,
  active,
  onClick,
  className = "",
  ...rest
}: {
  label: string;
  active: boolean;
  onClick: () => void;
  className?: string;
} & Omit<ButtonHTMLAttributes<HTMLButtonElement>, "children" | "onClick">) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={`text-[10px] tracking-widest uppercase px-2 py-1 border transition-colors ${
        active
          ? "border-accent text-accent bg-accent/10"
          : "border-line text-muted hover:text-foreground"
      } ${className}`.trim()}
      {...rest}
    >
      {label}
    </button>
  );
}
