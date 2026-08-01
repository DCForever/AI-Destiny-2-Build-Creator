"use client";

import type { LoadoutListRow } from "@/lib/loadouts/types";

export function discoveryOverlayTitle(title: string, matchCount: number): string {
  if (matchCount === 0) return `${title} — no other matches`;
  return `${title} (${matchCount})`;
}

interface LoadoutDiscoveryOverlayProps {
  open: boolean;
  title: string;
  matches: LoadoutListRow[];
  onClose: () => void;
}

export function LoadoutDiscoveryOverlay({
  open,
  title,
  matches,
  onClose,
}: LoadoutDiscoveryOverlayProps) {
  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="discovery-overlay-title"
    >
      <div className="panel-notch max-h-[80vh] w-full max-w-lg overflow-hidden flex flex-col bg-background">
        <div className="flex items-center justify-between gap-3 border-b border-line px-4 py-3">
          <h2 id="discovery-overlay-title" className="text-sm text-foreground">
            {discoveryOverlayTitle(title, matches.length)}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="text-xs border border-line px-2 py-1 text-muted hover:text-foreground"
          >
            Close
          </button>
        </div>
        <ul className="overflow-y-auto p-4 space-y-2" role="list">
          {matches.length === 0 ? (
            <li className="text-sm text-muted">No other loadouts match this criteria.</li>
          ) : (
            matches.map((row) => (
              <li key={row.id} className="border border-line px-3 py-2">
                <div className="text-sm text-foreground">{row.name}</div>
                <div className="text-xs text-muted mt-1">
                  {[
                    row.className,
                    row.exoticSummary.exoticArmor?.name
                      ? `Armor: ${row.exoticSummary.exoticArmor.name}`
                      : null,
                    row.exoticSummary.exoticWeapon?.name
                      ? `Weapon: ${row.exoticSummary.exoticWeapon.name}`
                      : null,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}
