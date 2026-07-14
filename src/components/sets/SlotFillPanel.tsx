"use client";

import { useMemo, useState } from "react";

import {
  CatalogScreen,
  type CatalogPickResult,
} from "@/components/catalog/CatalogScreen";
import { ManifestSearchPicker } from "@/components/lookups/ManifestSearchPicker";
import { SLOT_LABEL, type SetDetail } from "@/components/sets/types";
import {
  Button,
  Callout,
  Panel,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { fillStrategyForSet } from "@/lib/sets/fillSlotStrategy";
import { setSlotToCatalogBucket } from "@/lib/sets/catalogSlotMap";
import type { SetType } from "@/lib/sets/schemas";

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

  const catalogBucket = useMemo(
    () => setSlotToCatalogBucket(slot),
    [slot],
  );

  const [manifestPick, setManifestPick] = useState<{
    hash: number;
    name: string;
  } | null>(null);
  const [manualHash, setManualHash] = useState("");
  const [manualName, setManualName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
        setError(body.error ?? "Failed to put item in set slot");
        return;
      }
      onFilled(body.set);
    } catch {
      setError("Failed to put item in set slot");
    } finally {
      setBusy(false);
    }
  }

  function handleCatalogConfirm(pick: CatalogPickResult) {
    void putItem(pick.hash, pick.name, pick.instanceId);
  }

  const canSubmit =
    strategy.kind === "manifest"
      ? manifestPick != null
      : strategy.kind === "manual_hash_name"
        ? Number(manualHash.trim()) > 0 && manualName.trim().length > 0
        : false;

  if (strategy.kind === "catalog") {
    return (
      <div className="h-full min-h-0 flex flex-col gap-2 overflow-hidden">
        {error ? (
          <div className="shrink-0">
            <Callout tone="danger">{error}</Callout>
          </div>
        ) : null}
        <div className="flex-1 min-h-0 overflow-hidden">
          <CatalogScreen
            constraints={{
              kind: strategy.catalogKind,
              slot: catalogBucket,
              scope: "owned",
              lockKind: true,
              lockSlot: Boolean(catalogBucket),
            }}
            selection={{
              enabled: true,
              busy,
              confirmLabel: "Fill slot",
              onConfirm: handleCatalogConfirm,
              onCancel: onClose,
            }}
            chrome={{
              title: `Fill slot · ${SLOT_LABEL[slot] ?? slot}`,
              description: `${set.name} · ${set.type}`,
              embedded: true,
            }}
          />
        </div>
      </div>
    );
  }

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

        <Row gap={8}>
          <Button
            variant="accent"
            disabled={!canSubmit || busy}
            onClick={() => {
              if (strategy.kind === "manifest" && manifestPick) {
                void putItem(manifestPick.hash, manifestPick.name);
              } else if (strategy.kind === "manual_hash_name") {
                void putItem(
                  Number(manualHash.trim()),
                  manualName.trim(),
                );
              }
            }}
          >
            {busy ? "Saving…" : "Save to slot"}
          </Button>
          <Button variant="ghost" disabled={busy} onClick={onClose}>
            Cancel
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
