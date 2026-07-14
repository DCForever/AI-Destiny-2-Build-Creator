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
import {
  isModLegalForArmorSlot,
} from "@/lib/builds/modEnergy";
import {
  assertSetCompositionAllowed,
  setAlreadyHasExotic,
  setItemMetaFromCatalog,
  setItemMetaFromManifestCategory,
  type SetItemMeta,
  type SetOccupant,
} from "@/lib/sets/destinySetConstraints";
import { fillStrategyForSet } from "@/lib/sets/fillSlotStrategy";
import { setSlotToCatalogBucket } from "@/lib/sets/catalogSlotMap";
import {
  costsFromOccupants,
  evaluateModSetPieceEnergy,
  itemsForModArmorSlot,
} from "@/lib/sets/modSetEnergy";
import {
  isArmorSetSlot,
  modSetArmorSlotOf,
  modSetSlotKey,
  type SetType,
} from "@/lib/sets/schemas";

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

  /** Bare armor piece when filling a mod set (e.g. "helmet"). */
  const modFillArmorSlot = useMemo(() => {
    if (setType !== "mod") return null;
    if (isArmorSetSlot(slot)) return slot;
    return modSetArmorSlotOf(slot);
  }, [setType, slot]);

  const slotOccupied = useMemo(() => {
    if (setType === "mod") {
      // Multi-mod per piece: only "occupied" for exact helmet:hash key
      return set.items.some((i) => i.slot === slot && !i.removedAt);
    }
    return set.items.some((i) => i.slot === slot && !i.removedAt);
  }, [set.items, setType, slot]);

  const occupiedName = useMemo(() => {
    if (!slotOccupied) return null;
    return (
      set.items.find((i) => i.slot === slot && !i.removedAt)?.itemName ??
      "current item"
    );
  }, [set.items, slot, slotOccupied]);

  /** Occupants in other slots (exclude the slot being filled/replaced). */
  const otherOccupants = useMemo((): SetOccupant[] => {
    return set.items
      .filter((i) => !i.removedAt && i.slot !== slot)
      .map((i) => {
        const isExo = i.isExotic === true;
        let kind: SetItemMeta["kind"] = "unknown";
        if (setType === "weapon") {
          kind = isExo ? "exotic_weapon" : "weapon";
        } else if (setType === "armor") {
          kind = isExo ? "exotic_armor" : "armor";
        } else if (setType === "pair") {
          kind =
            i.slot === "exotic_weapon" || i.slot.includes("weapon")
              ? "exotic_weapon"
              : "exotic_armor";
        } else if (setType === "mod") {
          kind = "mod";
        }
        return {
          slot: i.slot,
          meta: {
            kind,
            isExotic: isExo || kind === "exotic_weapon" || kind === "exotic_armor",
            name: i.itemName,
            equipmentSlot: setSlotToCatalogBucket(i.slot),
          },
        };
      });
  }, [set.items, setType, slot]);

  const existingExoticWeapon = useMemo(
    () => setAlreadyHasExotic(setType, otherOccupants, "weapon"),
    [setType, otherOccupants],
  );
  const existingExoticArmor = useMemo(
    () => setAlreadyHasExotic(setType, otherOccupants, "armor"),
    [setType, otherOccupants],
  );

  /** Catalog: hide exotics when this set already has one of that kind. */
  const excludeExoticInCatalog =
    (setType === "weapon" && existingExoticWeapon != null) ||
    (setType === "armor" && existingExoticArmor != null);

  const [manifestPick, setManifestPick] = useState<{
    hash: number;
    name: string;
    energyCost?: number | null;
    slotCategory?: string;
  } | null>(null);
  const [manualHash, setManualHash] = useState("");
  const [manualName, setManualName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pendingReplace, setPendingReplace] = useState<{
    hash: number;
    name: string;
    inst?: string | null;
    targetSlot: string;
  } | null>(null);

  function clientAssert(meta: SetItemMeta, targetSlot: string): boolean {
    const fit = assertSetCompositionAllowed(
      setType,
      targetSlot,
      meta,
      otherOccupants,
    );
    if (!fit.ok) {
      setError(fit.reasons[0] ?? "Item does not fit this set");
      return false;
    }

    if (setType === "mod") {
      const armorSlot = modSetArmorSlotOf(targetSlot) ?? modFillArmorSlot;
      if (armorSlot && meta.slotCategory) {
        if (!isModLegalForArmorSlot(armorSlot, meta.slotCategory)) {
          setError(
            `This mod is not legal for ${SLOT_LABEL[armorSlot] ?? armorSlot}`,
          );
          return false;
        }
      }
      if (armorSlot) {
        const pieceItems = itemsForModArmorSlot(set.items, armorSlot).filter(
          (i) => i.slot !== targetSlot,
        );
        const pieceOccupants = otherOccupants.filter(
          (o) => modSetArmorSlotOf(o.slot) === armorSlot,
        );
        // Prefer meta costs when known
        const energy = evaluateModSetPieceEnergy({
          armorSlot,
          existingCosts: costsFromOccupants(pieceOccupants),
          candidateCost: meta.energyCost,
        });
        if (!energy.ok) {
          setError(energy.reason);
          return false;
        }
        void pieceItems;
      }
    }
    return true;
  }

  async function putItem(
    hash: number,
    name: string,
    inst?: string | null,
    targetSlot = slot,
    confirmReplace = false,
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
          confirmReplace: confirmReplace || undefined,
        }),
      });
      const body = (await res.json()) as {
        set?: SetDetail;
        error?: string;
        code?: string;
      };
      if (res.status === 409 && body.code === "SLOT_OCCUPIED") {
        setPendingReplace({ hash, name, inst, targetSlot });
        setError(null);
        return;
      }
      if (!res.ok || !body.set) {
        setError(body.error ?? "Failed to put item in set slot");
        return;
      }
      setPendingReplace(null);
      onFilled(body.set);
    } catch {
      setError("Failed to put item in set slot");
    } finally {
      setBusy(false);
    }
  }

  function requestFill(
    hash: number,
    name: string,
    meta: SetItemMeta,
    inst?: string | null,
    targetSlot = slot,
  ) {
    if (!clientAssert(meta, targetSlot)) return;

    if (slotOccupied && setType !== "mod") {
      setPendingReplace({ hash, name, inst, targetSlot });
      setError(null);
      return;
    }

    void putItem(hash, name, inst, targetSlot, false);
  }

  function handleCatalogConfirm(pick: CatalogPickResult) {
    const meta = setItemMetaFromCatalog({
      kind: strategy.kind === "catalog" ? strategy.catalogKind : "weapons",
      slot: pick.item.slot ?? pick.slot,
      isExotic: pick.item.isExotic,
    });
    requestFill(pick.hash, pick.name, meta, pick.instanceId);
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
        {excludeExoticInCatalog ? (
          <div className="shrink-0">
            <Callout tone="info">
              This set already has an exotic
              {existingExoticWeapon?.meta.name
                ? ` (${existingExoticWeapon.meta.name})`
                : existingExoticArmor?.meta.name
                  ? ` (${existingExoticArmor.meta.name})`
                  : ""}
              . Showing non-exotic pieces for this slot — replace the exotic
              piece&apos;s slot to change it.
            </Callout>
          </div>
        ) : null}
        {pendingReplace ? (
          <div className="shrink-0">
            <Panel tone="warning" pad="md">
              <Stack gap={8}>
                <Text size="sm" tone="warning">
                  Replace {occupiedName ?? "current item"} with{" "}
                  {pendingReplace.name}?
                </Text>
                <Row gap={8}>
                  <Button
                    size="sm"
                    variant="accent"
                    disabled={busy}
                    onClick={() =>
                      void putItem(
                        pendingReplace.hash,
                        pendingReplace.name,
                        pendingReplace.inst,
                        pendingReplace.targetSlot,
                        true,
                      )
                    }
                  >
                    {busy ? "Replacing…" : "Confirm replace"}
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    disabled={busy}
                    onClick={() => setPendingReplace(null)}
                  >
                    Cancel
                  </Button>
                </Row>
              </Stack>
            </Panel>
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
              excludeExotic: excludeExoticInCatalog,
            }}
            selection={{
              enabled: true,
              busy: busy || pendingReplace != null,
              confirmLabel: slotOccupied ? "Replace slot…" : "Fill slot",
              onConfirm: handleCatalogConfirm,
              onCancel: onClose,
            }}
            chrome={{
              title: `Fill slot · ${SLOT_LABEL[slot] ?? slot}`,
              description: excludeExoticInCatalog
                ? `${set.name} · ${set.type} · legendary only (exotic already in set)`
                : `${set.name} · ${set.type}`,
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
                ? `Add mod · ${SLOT_LABEL[modFillArmorSlot ?? slot] ?? slot}`
                : `Fill slot · ${SLOT_LABEL[slot] ?? slot}`}
            </Text>
            <Text size="xs" tone="muted">
              {set.name} · {set.type}
              {setType === "mod"
                ? " · slot-scoped or general/tuning · energy capacity 10"
                : ""}
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        {error ? <Callout tone="danger">{error}</Callout> : null}

        {pendingReplace ? (
          <Panel tone="warning" pad="md">
            <Stack gap={8}>
              <Text size="sm" tone="warning">
                Replace {occupiedName ?? "current item"} with{" "}
                {pendingReplace.name}?
              </Text>
              <Row gap={8}>
                <Button
                  size="sm"
                  variant="accent"
                  disabled={busy}
                  onClick={() =>
                    void putItem(
                      pendingReplace.hash,
                      pendingReplace.name,
                      pendingReplace.inst,
                      pendingReplace.targetSlot,
                      true,
                    )
                  }
                >
                  {busy ? "Replacing…" : "Confirm replace"}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={busy}
                  onClick={() => setPendingReplace(null)}
                >
                  Cancel
                </Button>
              </Row>
            </Stack>
          </Panel>
        ) : null}

        {strategy.kind === "manifest" ? (
          <ManifestSearchPicker
            label={strategy.label}
            category={strategy.category}
            targetArmorSlot={
              strategy.category === "mods" ? modFillArmorSlot : null
            }
            selected={
              manifestPick
                ? {
                    hash: manifestPick.hash,
                    name: manifestPick.name,
                    energyCost: manifestPick.energyCost,
                    slotCategory: manifestPick.slotCategory,
                  }
                : null
            }
            onSelect={(item) => {
              if (!item) {
                setManifestPick(null);
                return;
              }
              if (
                setType === "mod" &&
                modFillArmorSlot &&
                item.slotCategory &&
                !isModLegalForArmorSlot(modFillArmorSlot, item.slotCategory)
              ) {
                setError(
                  `${item.name} (${item.slotCategory}) is not legal for ${SLOT_LABEL[modFillArmorSlot] ?? modFillArmorSlot}`,
                );
                return;
              }
              setError(null);
              setManifestPick({
                hash: item.hash,
                name: item.name,
                energyCost: item.energyCost,
                slotCategory: item.slotCategory,
              });
            }}
            disabled={busy || pendingReplace != null}
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
              disabled={busy || pendingReplace != null}
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
              disabled={busy || pendingReplace != null}
              onChange={(e) => setManualHash(e.target.value)}
              placeholder="Bungie inventory item hash"
              inputMode="numeric"
            />
          </Stack>
        ) : null}

        <Row gap={8}>
          <Button
            variant="accent"
            disabled={!canSubmit || busy || pendingReplace != null}
            onClick={() => {
              if (strategy.kind === "manifest" && manifestPick) {
                const meta = setItemMetaFromManifestCategory(strategy.category, {
                  slotCategory: manifestPick.slotCategory,
                  energyCost: manifestPick.energyCost,
                  name: manifestPick.name,
                });
                const targetSlot =
                  setType === "mod" && modFillArmorSlot
                    ? modSetSlotKey(modFillArmorSlot, manifestPick.hash)
                    : slot;
                requestFill(
                  manifestPick.hash,
                  manifestPick.name,
                  meta,
                  undefined,
                  targetSlot,
                );
              } else if (strategy.kind === "manual_hash_name") {
                requestFill(
                  Number(manualHash.trim()),
                  manualName.trim(),
                  { kind: "unknown" },
                );
              }
            }}
          >
            {busy
              ? "Saving…"
              : slotOccupied
                ? "Replace slot…"
                : setType === "mod"
                  ? "Add mod"
                  : "Save to slot"}
          </Button>
          <Button variant="ghost" disabled={busy} onClick={onClose}>
            Cancel
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
