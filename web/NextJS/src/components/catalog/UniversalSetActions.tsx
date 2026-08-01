"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import {
  Button,
  Callout,
  Cluster,
  FilterChip,
  Row,
  SelectField,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import {
  setTypesForHit,
  type CompositionSetType,
} from "@/lib/catalog/compositionKinds";
import {
  mapCompositionKindToDefaultSetType,
  resolveInstancePin,
  slotsForSetType,
  suggestSlotsForHit,
} from "@/lib/catalog/setPlacementFromHit";
import type { CompositionSearchHit } from "@/lib/catalog/universalSearch";
import { SLOT_LABEL } from "@/components/sets/types";
import { sortByName } from "@/lib/sortByName";

type WizardMode = "idle" | "create" | "add";

type SetSummary = {
  id: string;
  name: string;
  type: string;
  items?: Array<{ slot: string; itemName?: string; removedAt?: string | null }>;
};

type InstanceRow = { instanceId: string; power?: number; location?: string };

function slotLabel(slot: string): string {
  return SLOT_LABEL[slot] ?? slot;
}

function legalSlotsForHit(
  hit: CompositionSearchHit,
  setType: CompositionSetType,
): string[] {
  const allowed = new Set(slotsForSetType(setType));
  const suggested = suggestSlotsForHit(hit.kind, hit.meta).filter((s) =>
    allowed.has(s),
  );
  if (suggested.length > 0) return suggested;
  return [...allowed];
}

export function UniversalSetActions({
  hit,
  onSuccess,
}: {
  hit: CompositionSearchHit;
  onSuccess: (message: string) => void;
}) {
  const typeOptions = useMemo(() => setTypesForHit(hit.kind), [hit.kind]);
  const defaultType = useMemo(
    () => mapCompositionKindToDefaultSetType(hit.kind) ?? typeOptions[0] ?? "weapon",
    [hit.kind, typeOptions],
  );

  const [mode, setMode] = useState<WizardMode>("idle");
  const [setType, setSetType] = useState<CompositionSetType>(defaultType);
  const [name, setName] = useState(hit.name);
  const [slot, setSlot] = useState<string>("");
  const [sets, setSets] = useState<SetSummary[]>([]);
  const [setId, setSetId] = useState<string>("");
  const [instances, setInstances] = useState<InstanceRow[]>([]);
  const [instanceId, setInstanceId] = useState<string | null>(null);
  const [pinMode, setPinMode] = useState<"wishlist" | "auto" | "pick">("wishlist");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needSignIn, setNeedSignIn] = useState(false);
  const [pendingReplace, setPendingReplace] = useState(false);
  /** Set id created in this wizard (reuse on replace confirm). */
  const [createdSetId, setCreatedSetId] = useState<string | null>(null);
  const [createdSetName, setCreatedSetName] = useState<string | null>(null);

  const slots = useMemo(() => legalSlotsForHit(hit, setType), [hit, setType]);

  useEffect(() => {
    setSetType(defaultType);
    setName(hit.name);
    setMode("idle");
    setError(null);
    setPendingReplace(false);
    setNeedSignIn(false);
    setCreatedSetId(null);
    setCreatedSetName(null);
  }, [hit.id, defaultType, hit.name]);

  useEffect(() => {
    if (slots.length === 0) {
      setSlot("");
      return;
    }
    setSlot((prev) => (prev && slots.includes(prev) ? prev : slots[0]!));
  }, [slots]);

  const loadInstances = useCallback(async () => {
    if (hit.hash == null) {
      setInstances([]);
      setPinMode("wishlist");
      setInstanceId(null);
      return;
    }
    const kindParam =
      hit.kind === "armor" || hit.kind === "exotic_armor" ? "armor" : "weapons";
    try {
      const res = await fetch(
        `/api/user/inventory/instances?itemHash=${hit.hash}&kind=${kindParam}`,
      );
      if (res.status === 401) {
        setInstances([]);
        setPinMode("wishlist");
        setInstanceId(null);
        return;
      }
      if (!res.ok) {
        setInstances([]);
        setPinMode("wishlist");
        setInstanceId(null);
        return;
      }
      const body = (await res.json()) as { instances?: InstanceRow[] };
      const list = body.instances ?? [];
      setInstances(list);
      const pin = resolveInstancePin(list);
      setPinMode(pin.mode);
      if (pin.mode === "auto") setInstanceId(pin.instanceId);
      else if (pin.mode === "wishlist") setInstanceId(null);
      else setInstanceId(null);
    } catch {
      setInstances([]);
      setPinMode("wishlist");
      setInstanceId(null);
    }
  }, [hit.hash, hit.kind]);

  const loadSets = useCallback(
    async (type: CompositionSetType) => {
      const res = await fetch(`/api/user/sets?type=${encodeURIComponent(type)}`);
      if (res.status === 401) {
        setNeedSignIn(true);
        setSets([]);
        return;
      }
      if (!res.ok) {
        const body = (await res.json().catch(() => ({}))) as { error?: string };
        throw new Error(body.error ?? "Failed to load sets");
      }
      setNeedSignIn(false);
      const body = (await res.json()) as { sets?: SetSummary[] };
      setSets(sortByName(body.sets ?? []));
    },
    [],
  );

  async function openCreate() {
    setError(null);
    setPendingReplace(false);
    setCreatedSetId(null);
    setCreatedSetName(null);
    setMode("create");
    setSetType(defaultType);
    setName(hit.name);
    await loadInstances();
  }

  async function openAdd() {
    setError(null);
    setPendingReplace(false);
    setMode("add");
    setSetType(defaultType);
    setSetId("");
    try {
      await Promise.all([loadInstances(), loadSets(defaultType)]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to open add flow");
    }
  }

  async function onChangeAddType(next: CompositionSetType) {
    setSetType(next);
    setSetId("");
    setError(null);
    try {
      await loadSets(next);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load sets");
    }
  }

  async function putItem(
    targetSetId: string,
    targetSlot: string,
    confirmReplace: boolean,
  ): Promise<{ ok: true; setName?: string } | { ok: false; occupied?: boolean; error: string; status?: number }> {
    if (hit.hash == null) {
      return { ok: false, error: "This hit has no item hash to place on a Set." };
    }
    const res = await fetch(`/api/user/sets/${targetSetId}/items`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        slot: targetSlot,
        itemHash: hit.hash,
        itemName: hit.name,
        instanceId: instanceId ?? undefined,
        confirmReplace: confirmReplace || undefined,
      }),
    });
    const body = (await res.json().catch(() => ({}))) as {
      set?: { name?: string };
      error?: string;
      code?: string;
    };
    if (res.status === 401) {
      setNeedSignIn(true);
      return { ok: false, error: "Sign in required", status: 401 };
    }
    if (res.status === 409 && body.code === "SLOT_OCCUPIED") {
      return { ok: false, occupied: true, error: body.error ?? "Slot occupied" };
    }
    if (!res.ok) {
      return { ok: false, error: body.error ?? "Failed to place item on set" };
    }
    return { ok: true, setName: body.set?.name };
  }

  async function submitCreate(confirmReplace = false) {
    if (!name.trim()) {
      setError("Set name is required");
      return;
    }
    if (!slot) {
      setError("Choose a slot");
      return;
    }
    if (pinMode === "pick" && !instanceId) {
      setError("Pick an owned copy (or leave unset only when none are owned).");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      let targetId = createdSetId;
      let targetName = createdSetName ?? name.trim();
      if (!targetId) {
        const createRes = await fetch("/api/user/sets", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: name.trim(), type: setType, tagIds: [] }),
        });
        const createBody = (await createRes.json().catch(() => ({}))) as {
          set?: { id: string; name: string };
          error?: string;
        };
        if (createRes.status === 401) {
          setNeedSignIn(true);
          setError("Sign in to create a Set.");
          return;
        }
        if (!createRes.ok || !createBody.set) {
          setError(createBody.error ?? "Failed to create set");
          return;
        }
        targetId = createBody.set.id;
        targetName = createBody.set.name;
        setCreatedSetId(targetId);
        setCreatedSetName(targetName);
      }
      const placed = await putItem(targetId, slot, confirmReplace);
      if (!placed.ok) {
        if (placed.occupied) {
          setPendingReplace(true);
          setError(null);
          return;
        }
        setError(placed.error);
        return;
      }
      setPendingReplace(false);
      setCreatedSetId(null);
      setCreatedSetName(null);
      setMode("idle");
      onSuccess(`Added ${hit.name} to set “${targetName}”.`);
    } catch {
      setError("Failed to create set");
    } finally {
      setBusy(false);
    }
  }

  async function submitAdd(confirmReplace = false) {
    if (!setId) {
      setError("Choose a set");
      return;
    }
    if (!slot) {
      setError("Choose a slot");
      return;
    }
    if (pinMode === "pick" && !instanceId) {
      setError("Pick an owned copy when multiple are owned.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const placed = await putItem(setId, slot, confirmReplace);
      if (!placed.ok) {
        if (placed.occupied) {
          setPendingReplace(true);
          setError(null);
          return;
        }
        setError(placed.error);
        return;
      }
      const targetName =
        placed.setName ?? sets.find((s) => s.id === setId)?.name ?? "set";
      setPendingReplace(false);
      setMode("idle");
      onSuccess(`Added ${hit.name} to set “${targetName}”.`);
    } catch {
      setError("Failed to add to set");
    } finally {
      setBusy(false);
    }
  }

  if (!hit.actions.set || typeOptions.length === 0) {
    return (
      <Text size="sm" tone="muted">
        Not eligible for Set placement.
      </Text>
    );
  }

  if (hit.hash == null) {
    return (
      <Text size="sm" tone="muted">
        This hit has no item hash and cannot be placed on a Set.
      </Text>
    );
  }

  return (
    <Stack gap={10}>
      {needSignIn ? (
        <Callout tone="warning" title="Sign in required">
          Sign in with Bungie to create or add to Sets.
        </Callout>
      ) : null}
      {error ? <Callout tone="danger">{error}</Callout> : null}

      {mode === "idle" ? (
        <Row gap={8} wrap>
          <Button size="sm" variant="accent" onClick={() => void openCreate()}>
            Create Set
          </Button>
          <Button size="sm" variant="outline" onClick={() => void openAdd()}>
            Add to existing Set
          </Button>
        </Row>
      ) : null}

      {mode === "create" ? (
        <Stack gap={8}>
          <Text size="sm" weight="medium">
            Create Set
          </Text>
          <TextField
            label="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={120}
          />
          {typeOptions.length > 1 ? (
            <SelectField
              label="Set type"
              value={setType}
              onChange={(e) => setSetType(e.target.value as CompositionSetType)}
            >
              {typeOptions.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </SelectField>
          ) : (
            <Text size="xs" tone="muted">
              Type · {setType}
            </Text>
          )}
          <SelectField
            label="Slot"
            value={slot}
            onChange={(e) => setSlot(e.target.value)}
          >
            {slots.map((s) => (
              <option key={s} value={s}>
                {slotLabel(s)}
              </option>
            ))}
          </SelectField>
          <InstancePicker
            pinMode={pinMode}
            instances={instances}
            instanceId={instanceId}
            onChange={setInstanceId}
          />
          {pendingReplace ? (
            <Callout tone="warning" title="Replace occupied slot?">
              Confirm to replace the item already in this slot.
            </Callout>
          ) : null}
          <Row gap={8} wrap>
            <Button
              size="sm"
              variant="accent"
              disabled={busy}
              onClick={() => void submitCreate(pendingReplace)}
            >
              {busy ? "Saving…" : pendingReplace ? "Confirm replace" : "Create & place"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={busy}
              onClick={() => {
                setMode("idle");
                setPendingReplace(false);
                setError(null);
              }}
            >
              Cancel
            </Button>
          </Row>
        </Stack>
      ) : null}

      {mode === "add" ? (
        <Stack gap={8}>
          <Text size="sm" weight="medium">
            Add to existing Set
          </Text>
          {typeOptions.length > 1 ? (
            <SelectField
              label="Set type"
              value={setType}
              onChange={(e) => void onChangeAddType(e.target.value as CompositionSetType)}
            >
              {typeOptions.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </SelectField>
          ) : null}
          <SelectField
            label="Set"
            value={setId}
            onChange={(e) => setSetId(e.target.value)}
          >
            <option value="">Select a set…</option>
            {sets.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </SelectField>
          {sets.length === 0 && !needSignIn ? (
            <Text size="xs" tone="muted">
              No {setType} sets yet — create one instead.
            </Text>
          ) : null}
          <SelectField
            label="Slot"
            value={slot}
            onChange={(e) => setSlot(e.target.value)}
          >
            {slots.map((s) => (
              <option key={s} value={s}>
                {slotLabel(s)}
              </option>
            ))}
          </SelectField>
          <InstancePicker
            pinMode={pinMode}
            instances={instances}
            instanceId={instanceId}
            onChange={setInstanceId}
          />
          {pendingReplace ? (
            <Callout tone="warning" title="Replace occupied slot?">
              Confirm to replace the item already in this slot.
            </Callout>
          ) : null}
          <Row gap={8} wrap>
            <Button
              size="sm"
              variant="accent"
              disabled={busy || !setId}
              onClick={() => void submitAdd(pendingReplace)}
            >
              {busy ? "Saving…" : pendingReplace ? "Confirm replace" : "Add to set"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={busy}
              onClick={() => {
                setMode("idle");
                setPendingReplace(false);
                setError(null);
              }}
            >
              Cancel
            </Button>
          </Row>
        </Stack>
      ) : null}
    </Stack>
  );
}

function InstancePicker({
  pinMode,
  instances,
  instanceId,
  onChange,
}: {
  pinMode: "wishlist" | "auto" | "pick";
  instances: InstanceRow[];
  instanceId: string | null;
  onChange: (id: string | null) => void;
}) {
  if (pinMode === "wishlist") {
    return (
      <Text size="xs" tone="muted">
        No owned copies — will attach catalog identity only.
      </Text>
    );
  }
  if (pinMode === "auto") {
    return (
      <Text size="xs" tone="muted">
        Auto-pinning the only owned copy
        {instanceId ? ` (${instanceId.slice(0, 8)}…)` : ""}.
      </Text>
    );
  }
  return (
    <Stack gap={4}>
      <Text size="xs" tone="muted">
        Multiple owned copies — pick one
      </Text>
      <Cluster gap={4}>
        {instances.map((inst) => {
          const active = instanceId === inst.instanceId;
          const label = [
            inst.power != null ? `PL ${inst.power}` : null,
            inst.location,
            inst.instanceId.slice(0, 8),
          ]
            .filter(Boolean)
            .join(" · ");
          return (
            <FilterChip
              key={inst.instanceId}
              size="xs"
              label={label}
              active={active}
              onClick={() => onChange(active ? null : inst.instanceId)}
            />
          );
        })}
      </Cluster>
    </Stack>
  );
}
