"use client";

import type { ReactNode } from "react";

import { Button } from "@/components/ui/Button";
import { Panel } from "@/components/ui/Panel";
import { Stack } from "@/components/ui/Stack";

/**
 * Catalog-style filter chrome: collapsed single row with optional summary chips;
 * expanded body for full controls.
 */
export function CollapsibleFilterSection({
  open,
  onOpenChange,
  activeCount = 0,
  summary,
  onClear,
  leading,
  trailing,
  children,
  panel = true,
  label = "Filters",
  className = "",
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Drives `· n` on the Filters button and Clear visibility. */
  activeCount?: number;
  /** Shown only when collapsed and non-empty (applied chips, etc.). */
  summary?: ReactNode;
  onClear?: () => void;
  /** Always-visible controls on the left of the Filters toggle. */
  leading?: ReactNode;
  /** Always-visible actions on the right (Refresh, etc.). */
  trailing?: ReactNode;
  children?: ReactNode;
  /** Wrap in muted panel (default). Set false when parent already provides chrome. */
  panel?: boolean;
  label?: string;
  className?: string;
}) {
  const body = (
    <Stack gap={6} className={className}>
      <div className="flex flex-wrap items-center gap-2">
        {leading ? (
          <div className="flex flex-wrap items-center gap-2 min-w-0">
            {leading}
          </div>
        ) : null}

        <Button
          size="sm"
          variant={open ? "accent" : "ghost"}
          onClick={() => onOpenChange(!open)}
        >
          {open ? `▾ ${label}` : `▸ ${label}`}
          {activeCount > 0 ? ` · ${activeCount}` : ""}
        </Button>

        {!open && summary ? (
          <div className="flex flex-wrap items-center gap-2 min-w-0 flex-1">
            {summary}
          </div>
        ) : null}

        <div className="flex flex-wrap items-center gap-2 shrink-0 ml-auto">
          {activeCount > 0 && onClear ? (
            <Button size="sm" variant="ghost" onClick={onClear}>
              Clear · {activeCount}
            </Button>
          ) : null}
          {trailing}
        </div>
      </div>

      {open && children ? <div className="min-w-0">{children}</div> : null}
    </Stack>
  );

  if (!panel) return body;
  return (
    <Panel tone="muted" pad="sm">
      {body}
    </Panel>
  );
}
