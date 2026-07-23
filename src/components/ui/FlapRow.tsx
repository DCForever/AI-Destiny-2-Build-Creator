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
 * Optional `channel` is a Destiny element/class CSS color for row lamp + wash.
 */
export function FlapRow({
  children,
  columns,
  selected = false,
  lamp = "none",
  channel,
  className = "",
  style,
  ...rest
}: {
  children: ReactNode;
  columns: string;
  selected?: boolean;
  lamp?: FlapLamp;
  /** CSS color for identity channel (element/class ink). */
  channel?: string | null;
  className?: string;
} & ButtonHTMLAttributes<HTMLButtonElement>) {
  const mergedStyle = {
    gridTemplateColumns: columns,
    ...(channel ? { ["--flap-channel" as string]: channel } : null),
    ...style,
  } as CSSProperties;

  return (
    <button
      type="button"
      className={`flap-row ${className}`.trim()}
      style={mergedStyle}
      data-selected={selected ? "true" : undefined}
      data-lamp={lamp !== "none" && !selected ? lamp : undefined}
      data-channel={channel ? "true" : undefined}
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
  hold,
  title,
  ...rest
}: {
  children?: ReactNode;
  className?: string;
  variant?: "default" | "name" | "meta" | "tally" | "channel";
  ready?: boolean;
  hold?: boolean;
  title?: string;
} & HTMLAttributes<HTMLDivElement>) {
  const v =
    variant === "name"
      ? "flap-cell flap-cell-name"
      : variant === "meta"
        ? "flap-cell flap-cell-meta"
        : variant === "tally"
          ? "flap-cell flap-cell-tally"
          : variant === "channel"
            ? "flap-cell flap-cell-channel"
            : "flap-cell";
  return (
    <div
      className={`${v} ${className}`.trim()}
      data-ready={ready ? "true" : undefined}
      data-hold={hold ? "true" : undefined}
      title={title}
      {...rest}
    >
      {children}
    </div>
  );
}

export function FlapTypeStamp({
  type,
  title,
}: {
  type: string;
  title?: string;
}) {
  return (
    <span className="flap-type-stamp" data-type={type} title={title ?? type}>
      {type}
    </span>
  );
}

export function FlapSeal({
  src,
  label,
  title,
  kind = "default",
}: {
  src?: string | null;
  label?: string;
  title?: string;
  kind?: "default" | "exotic";
}) {
  return (
    <span className="flap-seal" data-kind={kind} title={title ?? label}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt="" width={18} height={18} />
      ) : (
        <span className="flap-seal-fallback text-[10px] tracking-tight px-0.5 truncate max-w-full text-muted">
          {label?.slice(0, 3) ?? "—"}
        </span>
      )}
    </span>
  );
}
