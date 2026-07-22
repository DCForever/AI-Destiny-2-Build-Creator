import type {
  ButtonHTMLAttributes,
  CSSProperties,
  HTMLAttributes,
  ReactNode,
} from "react";

type FlapLamp = "none" | "warning" | "danger";

/**
 * One ruled row on a Matte Flap Ledger board.
 * Pass `columns` as a CSS grid-template-columns value matching cell count.
 */
export function FlapRow({
  children,
  columns,
  selected = false,
  lamp = "none",
  className = "",
  ...rest
}: {
  children: ReactNode;
  columns: string;
  selected?: boolean;
  lamp?: FlapLamp;
  className?: string;
} & ButtonHTMLAttributes<HTMLButtonElement>) {
  const style = { gridTemplateColumns: columns } as CSSProperties;
  return (
    <button
      type="button"
      className={`flap-row ${className}`.trim()}
      style={style}
      data-selected={selected ? "true" : undefined}
      data-lamp={lamp !== "none" && !selected ? lamp : undefined}
      {...rest}
    >
      {children}
    </button>
  );
}

export function FlapBoard({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={`flap-board ${className}`.trim()}>{children}</div>;
}

export function FlapHeader({
  columns,
  cells,
  className = "",
}: {
  columns: string;
  cells: ReactNode[];
  className?: string;
}) {
  return (
    <div
      className={`flap-header ${className}`.trim()}
      style={{ gridTemplateColumns: columns } as CSSProperties}
      aria-hidden
    >
      {cells.map((cell, i) => (
        <div key={i} className="flap-header-cell">
          {cell}
        </div>
      ))}
    </div>
  );
}

export function FlapCell({
  children,
  className = "",
  variant = "default",
  ready,
  title,
  ...rest
}: {
  children?: ReactNode;
  className?: string;
  variant?: "default" | "name" | "meta" | "tally";
  ready?: boolean;
  title?: string;
} & HTMLAttributes<HTMLDivElement>) {
  const v =
    variant === "name"
      ? "flap-cell flap-cell-name"
      : variant === "meta"
        ? "flap-cell flap-cell-meta"
        : variant === "tally"
          ? "flap-cell flap-cell-tally"
          : "flap-cell";
  return (
    <div
      className={`${v} ${className}`.trim()}
      data-ready={ready ? "true" : undefined}
      title={title}
      {...rest}
    >
      {children}
    </div>
  );
}

export function FlapSeal({
  src,
  label,
  title,
}: {
  src?: string | null;
  label?: string;
  title?: string;
}) {
  return (
    <span className="flap-seal" title={title ?? label}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt="" width={18} height={18} />
      ) : (
        <span className="text-[10px] text-muted tracking-tight px-0.5 truncate max-w-full">
          {label?.slice(0, 3) ?? "—"}
        </span>
      )}
    </span>
  );
}

