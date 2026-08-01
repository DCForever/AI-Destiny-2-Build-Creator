"use client";

import { useState } from "react";

import { Button, Callout, Row, Stack, Text } from "@/components/ui";

const FINISH_TYPES = [
  { id: "armor", label: "Armor" },
  { id: "weapon", label: "Weapons" },
  { id: "mod", label: "Mods" },
  { id: "pair", label: "Pair" },
] as const;

export type FinishSetType = (typeof FINISH_TYPES)[number]["id"];

export function CreateSetAttachForm({
  buildId,
  variantId,
  defaultType = "armor",
  allowPair = true,
  busy: busyExt,
  onCreated,
}: {
  buildId: string;
  variantId: string;
  defaultType?: FinishSetType;
  allowPair?: boolean;
  busy?: boolean;
  onCreated: (result: {
    set: { id: string; name: string; type: string };
    attachment: { setId: string; mode: "live"; variantId: string } | null;
  }) => void;
}) {
  const types = FINISH_TYPES.filter((t) => allowPair || t.id !== "pair");
  const [name, setName] = useState("");
  const [type, setType] = useState<FinishSetType>(defaultType);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const locked = busy || Boolean(busyExt);

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/builds/${buildId}/create-set-attach`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          variantId,
          type,
          name: name.trim() || undefined,
          attachNow: true,
        }),
      });
      const body = (await res.json()) as {
        error?: string;
        set?: { id: string; name: string; type: string };
        attachment?: { setId: string; mode: "live"; variantId: string } | null;
      };
      if (!res.ok || !body.set) {
        setError(body.error ?? "Failed to create set");
        return;
      }
      onCreated({ set: body.set, attachment: body.attachment ?? null });
      setName("");
    } catch {
      setError("Failed to create set");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted">
        Create a library Set and live-attach it to this variant (replaces any
        same-type live Set).
      </Text>
      {error ? <Callout tone="danger">{error}</Callout> : null}
      <label className="block">
        <span className="text-xs text-muted uppercase tracking-widest">Name</span>
        <input
          className="mt-1 w-full bg-surface-raised border border-line px-2 py-1.5 text-sm"
          value={name}
          disabled={locked}
          placeholder="Optional — defaults from build name"
          onChange={(e) => setName(e.target.value)}
        />
      </label>
      <Row gap={6} wrap>
        {types.map((t) => (
          <Button
            key={t.id}
            size="sm"
            variant={type === t.id ? "accent" : "ghost"}
            disabled={locked}
            onClick={() => setType(t.id)}
          >
            {t.label}
          </Button>
        ))}
      </Row>
      <Button
        variant="accent"
        size="sm"
        disabled={locked}
        onClick={() => void submit()}
      >
        {locked ? "Creating…" : "Create & attach"}
      </Button>
    </Stack>
  );
}
