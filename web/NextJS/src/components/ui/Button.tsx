import type { ButtonHTMLAttributes, ReactNode } from "react";

type Variant = "accent" | "outline" | "ghost" | "danger";
type Size = "sm" | "md";

const VARIANT: Record<Variant, string> = {
  accent:
    "badge badge-accent hover:opacity-90 disabled:opacity-40",
  outline:
    "border border-line text-foreground hover:border-accent disabled:opacity-40",
  ghost: "text-muted hover:text-foreground disabled:opacity-40",
  danger:
    "border border-danger/40 text-danger hover:bg-danger/10 disabled:opacity-40",
};

const SIZE: Record<Size, string> = {
  sm: "px-2 py-1 text-[10px] tracking-widest uppercase",
  md: "px-3 py-2 text-[11px] tracking-widest uppercase",
};

export function Button({
  children,
  variant = "outline",
  size = "md",
  className = "",
  type = "button",
  ...rest
}: {
  children: ReactNode;
  variant?: Variant;
  size?: Size;
  className?: string;
} & ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      type={type}
      className={`${VARIANT[variant]} ${SIZE[size]} ${className}`.trim()}
      {...rest}
    >
      {children}
    </button>
  );
}
