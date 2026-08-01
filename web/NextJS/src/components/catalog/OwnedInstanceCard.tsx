"use client";

import { memo, useEffect, useRef, useState } from "react";

import { ArmorStatsPanel } from "@/components/catalog/ArmorStatsPanel";
import { InstancePerkGridView } from "@/components/catalog/InstancePerkGridView";
import {
  Button,
  Chip,
  Cluster,
  EntityHotspot,
  Panel,
  Row,
  Stack,
  Text,
} from "@/components/ui";

export type OwnedInstanceCardPlug = {
  displayName: string;
  resolved?: boolean;
  hash?: number;
  icon?: string | null;
  description?: string | null;
};

export type OwnedInstanceCardData = {
  instanceId: string;
  power?: number;
  location?: string;
  isMasterwork?: boolean;
  tier?: string | number;
  plugs?: OwnedInstanceCardPlug[];
  statValues?: Partial<Record<string, number>>;
  totalStats?: number;
  statsIncomplete?: boolean;
};

/**
 * Variant-style card for one owned weapon or armor copy.
 * Shared chrome so side-by-side comparison stays consistent.
 * Weapon perk grids load only when the card is (nearly) on-screen to avoid
 * N concurrent perk-grid fetches when opening a multi-copy detail pane.
 */
export const OwnedInstanceCard = memo(function OwnedInstanceCard({
  kind,
  instance,
  frameHint,
  selected = false,
  pickMode = false,
  pickBusy = false,
  onToggleSelect,
  onUse,
}: {
  kind: "weapons" | "armor";
  instance: OwnedInstanceCardData;
  frameHint?: string | null;
  selected?: boolean;
  pickMode?: boolean;
  pickBusy?: boolean;
  onToggleSelect?: () => void;
  onUse?: () => void;
}) {
  const plugs = instance.plugs ?? [];
  const rootRef = useRef<HTMLDivElement | null>(null);
  const [perkGridEnabled, setPerkGridEnabled] = useState(kind !== "weapons");

  useEffect(() => {
    if (kind !== "weapons") {
      setPerkGridEnabled(true);
      return;
    }
    setPerkGridEnabled(false);
    const el = rootRef.current;
    if (!el || typeof IntersectionObserver === "undefined") {
      setPerkGridEnabled(true);
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          setPerkGridEnabled(true);
          io.disconnect();
        }
      },
      { root: null, rootMargin: "120px 0px", threshold: 0.01 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [kind, instance.instanceId]);

  return (
    <div ref={rootRef} className="h-full min-w-0">
    <Panel
      tone={selected ? "accent" : "muted"}
      pad="sm"
      className="h-full min-w-0 flex flex-col"
    >
      <Stack gap={kind === "armor" ? 6 : 10} className="min-h-0 flex-1">
        <Row justify="between" align="start" gap={6} wrap>
          <Stack gap={2} className="min-w-0">
            <Row gap={4} wrap align="center">
              <Text size="sm" weight="medium">
                {instance.power != null
                  ? `P${instance.power}`
                  : "Copy"}
              </Text>
              {instance.isMasterwork ? <Chip accent>MW</Chip> : null}
              {instance.tier != null && instance.tier !== "" ? (
                <Chip>T{String(instance.tier)}</Chip>
              ) : null}
              {instance.location ? (
                <Text size="xs" tone="muted" as="span">
                  {instance.location}
                </Text>
              ) : null}
            </Row>
          </Stack>
          {pickMode ? (
            <Button
              size="sm"
              variant={selected ? "accent" : "outline"}
              disabled={pickBusy}
              onClick={onToggleSelect}
            >
              {selected ? "Selected" : "Select"}
            </Button>
          ) : null}
        </Row>

        {kind === "weapons" ? (
          perkGridEnabled ? (
            <InstancePerkGridView
              instanceId={instance.instanceId}
              enabled
              frameHint={frameHint}
            />
          ) : (
            <Text size="xs" tone="muted">
              Loading instance detail…
            </Text>
          )
        ) : (
          <Stack gap={10}>
            <ArmorStatsPanel
              statValues={instance.statValues}
              totalStats={instance.totalStats}
              statsIncomplete={instance.statsIncomplete}
            />
            {plugs.length > 0 ? (
              <Stack gap={4}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Mods · plugs
                </Text>
                <Cluster gap={6}>
                  {plugs.map((p, plugIdx) => (
                    <EntityHotspot
                      key={`${instance.instanceId}-${plugIdx}-${p.hash ?? p.displayName}`}
                      kind="Mod / plug"
                      name={p.displayName}
                      description={p.description}
                      icon={p.icon}
                      size={28}
                      showLabel="never"
                    />
                  ))}
                </Cluster>
              </Stack>
            ) : null}
          </Stack>
        )}

        {pickMode ? (
          <Button
            size="sm"
            variant="accent"
            disabled={pickBusy}
            onClick={onUse}
            className="mt-auto"
          >
            {pickBusy ? "Saving…" : "Use this copy"}
          </Button>
        ) : null}
      </Stack>
    </Panel>
    </div>
  );
});
