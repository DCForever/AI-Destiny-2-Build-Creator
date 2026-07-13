"use client";

/** Left color stripe + optional glyph for In-Game Loadout chrome. */
export function LoadoutColorBar({
  color,
  children,
}: {
  color: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="flex min-w-0 flex-1">
      <div
        className="w-1.5 shrink-0 self-stretch rounded-sm"
        style={{ background: color }}
        aria-hidden
      />
      <div className="min-w-0 flex-1 flex items-start gap-3 pl-3">
        {children}
      </div>
    </div>
  );
}

/** Circular loadout “icon” plate with class glyph. */
export function LoadoutIconPlate({
  color,
  children,
}: {
  color: string;
  children: React.ReactNode;
}) {
  return (
    <span
      className="inline-flex size-9 shrink-0 items-center justify-center border border-line bg-surface-raised"
      style={{ boxShadow: `inset 0 0 0 1px ${color}33` }}
    >
      {children}
    </span>
  );
}
