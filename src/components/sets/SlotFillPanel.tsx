"use client";

import { useMemo, useState } from "react";

import {
  CatalogItemPicker,
  type CatalogPick,
} from "@/components/lookups/CatalogItemPicker";
import { ManifestSearchPicker } from "@/components/lookups/ManifestSearchPicker";
import { SLOT_LABEL, type SetDetail } from "@/components/sets/types";
import {
  Button,
  Callout,
  Cluster,
  FilterChip,
  Panel,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { fillStrategyForSet } from "@/lib/sets/fillSlotStrategy";
import { modSlotForHash, type SetType } from "@/lib/sets/schemas";

type InstanceRow = {
  instanceId: string;
  power?: number;
  location?: string;
  plugs?: { displayName: string; resolved: boolean }[];
};

export function SlotFillPanel({
  set,
  slot,
  onClose,
  onFilled,
}: {
  set: SetDetail;
  slot: string;
  onClose: () => void;
  onFilled: (next: SetDetail) => void;
}) {
  const setType = set.type as SetType;
  const strategy = useMemo(
    () => fillStrategyForSet(setType, slot),
    [setType, slot],
  );

  const [scope, setScope] = useState<"all" | "owned">("owned");
  const [picked, setPicked] = useState<CatalogPick | null>(null);
  const [manifestPick, setManifestPick] = useState<{
    hash: number;
    name: string;
  } | null>(null);
  const [manualHash, setManualHash] = useState("");
  const [manualName, setManualName] = useState("");
  const [instances, setInstances] = useState<InstanceRow[]>([]);
  const [instanceId, setInstanceId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadInstances(item: CatalogPick, catalogKind: "weapons" | "armor") {
    setInstances([]);
    setInstanceId(null);
    if (item.ownedCount <= 0) return;
    const href =
      item.instancesHref ??
      `/api/user/inventory/instances?itemHash=${item.hash}&kind=${
        catalogKind === "armor" ? "armor" : "weapons"
      }`;
    try {
      const res = await fetch(href);
      const body = (await res.json()) as {
        instances?: InstanceRow[];
        message?: string;
      };
      if (!res.ok) return;
      setInstances(body.instances ?? []);
    } catch {
      /* optional */
    }
  }

  async function putItem(
    hash: number,
    name: string,
    inst?: string | null,
    targetSlot = slot,
  ) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/sets/${set.id}/items`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slot: targetSlot,
          itemHash: hash,
          itemName: name,
          instanceId: inst ?? undefined,
          confirmReplace: true,
        }),
      });
      const body = (await res.json()) as { set?: SetDetail; error?: string };
      if (!res.ok || !body.set) {
        setError(body.error ?? "Failed to put item in slot");
        return;
      }
      onFilled(body.set);
    } catch {
      setError("Failed to put item in slot");
    } finally {
      setBusy(false);
    }
  }

  const canSubmit =
    strategy.kind === "catalog"
      ? picked != null
      : strategy.kind === "manifest"
        ? manifestPick != null
        : Number(manualHash.trim()) > 0 && manualName.trim().length > 0;

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="center" gap={8} wrap>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              {setType === "mod"
                ? "Add mod"
                : `Fill slot · ${SLOT_LABEL[slot] ?? slot}`}
            </Text>
            <Text size="xs" tone="muted">
              {set.name} · {set.type}
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        {error ? <Callout tone="danger">{error}</Callout> : null}

        {strategy.kind === "catalog" ? (
          <>
            <Cluster gap={6}>
              <FilterChip
                label="Owned"
                active={scope === "owned"}
                onClick={() => setScope("owned")}
              />
              <FilterChip
                label="Manifest"
                active={scope === "all"}
                onClick={() => setScope("all")}
              />
            </Cluster>
            <CatalogItemPicker
              kind={strategy.catalogKind}
              setSlot={slot}
              scope={scope}
              selected={picked}
              disabled={busy}
              showMultiFilters
              onSelect={(item) => {
                setPicked(item);
                setManifestPick(null);
                if (item) void loadInstances(item, strategy.catalogKind);
                else {
                  setInstances([]);
                  setInstanceId(null);
                }
              }}
            />
            <Text size="xs" tone="muted">
              Multi-select element / ammo / archetype narrows catalog results
              (OR within each group). Slot is already fixed for this fill.
            </Text>
          </>
        ) : null}

        {strategy.kind === "manifest" ? (
          <ManifestSearchPicker
            label={strategy.label}
            category={strategy.category}
            selected={manifestPick}
            onSelect={setManifestPick}
            disabled={busy}
          />
        ) : null}

        {strategy.kind === "manual_hash_name" ? (
          <Stack gap={10}>
            <Text size="xs" tone="muted">
              {strategy.hint}
            </Text>
            <TextField
              label="Item name"
              value={manualName}
              disabled={busy}
              onChange={(e) => setManualName(e.target.value)}
              placeholder={
                slot === "ghost"
                  ? "e.g. Shell name"
                  : slot === "sparrow"
                    ? "e.g. Sparrow name"
                    : "Display name"
              }
            />
            <TextField
              label="Item hash"
              value={manualHash}
              disabled={busy}
              onChange={(e) => setManualHash(e.target.value)}
              placeholder="Bungie inventory item hash"
              inputMode="numeric"
            />
          </Stack>
        ) : null}

        {instances.length > 0 ? (
          <Stack gap={6}>
            <Text size="xs" tone="muted">
              Owned copies
            </Text>
            <Stack gap={4} className="max-h-40 overflow-auto">
              {instances.map((inst) => (
                <button
                  key={inst.instanceId}
                  type="button"
                  className={`text-left px-2 py-1.5 text-sm border ${
                    instanceId === inst.instanceId
                      ? "border-accent bg-accent/10"
                      : "border-line bg-surface-raised"
                  }`}
                  onClick={() => setInstanceId(inst.instanceId)}
                >
                  <Text size="sm" as="span">
                    {inst.power != null ? `Power ${inst.power}` : inst.instanceId}
                  </Text>
                  {inst.location ? (
                    <Text size="xs" tone="muted" as="span" className="ml-2">
                      {inst.location}
                    </Text>
                  ) : null}
                  {(inst.plugs?.length ?? 0) > 0 ? (
                    <Text size="xs" tone="muted" className="mt-1">
                      {inst.plugs!
                        .slice(0, 4)
                        .map((p) => p.displayName)
                        .join(" · ")}
                    </Text>
                  ) : null}
                </button>
              ))}
            </Stack>
          </Stack>
        ) : null}

        <Row gap={8}>
          <Button
            size="sm"
            variant="accent"
            disabled={busy || !canSubmit}
            onClick={() => {
              if (strategy.kind === "catalog" && picked) {
                void putItem(picked.hash, picked.name, instanceId);
                return;
              }
              if (strategy.kind === "manifest" && manifestPick) {
                const targetSlot =
                  setType === "mod"
                    ? modSlotForHash(manifestPick.hash)
                    : slot;
                void putItem(
                  manifestPick.hash,
                  manifestPick.name,
                  null,
                  targetSlot,
                );
                return;
              }
              if (strategy.kind === "manual_hash_name") {
                const hash = Number(manualHash.trim());
                if (!Number.isFinite(hash) || hash <= 0) {
                  setError("Item hash must be a positive number");
                  return;
                }
                if (!manualName.trim()) {
                  setError("Item name is required for fashion items");
                  return;
                }
                void putItem(hash, manualName.trim(), null);
              }
            }}
          >
            {setType === "mod"
              ? "Add mod to set"
              : `Put in ${SLOT_LABEL[slot] ?? slot}`}
          </Button>
          <Button size="sm" variant="ghost" disabled={busy} onClick={onClose}>
            Cancel
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
