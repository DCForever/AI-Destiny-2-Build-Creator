"use client";

import { useState } from "react";

import type { SetDetail } from "@/components/sets/types";
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
  SelectField,
} from "@/components/ui";
import { CONCEPT_TAGS } from "@/data/conceptTags";
import { SET_TYPES, type SetType } from "@/lib/sets/schemas";

/** Parent should pass key={mode-id} so form state resets cleanly. */
export function SetsEditPanel({
  mode,
  initial,
  prefillType,
  onClose,
  onSaved,
}: {
  mode: "create" | "edit";
  initial?: SetDetail | null;
  prefillType?: string | null;
  onClose: () => void;
  onSaved: (set: SetDetail) => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [type, setType] = useState<SetType>(
    (initial?.type as SetType) ??
      (prefillType as SetType) ??
      "weapon",
  );
  const [tagIds, setTagIds] = useState<string[]>(initial?.tagIds ?? []);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function toggleTag(id: string) {
    setTagIds((prev) =>
      prev.includes(id) ? prev.filter((t) => t !== id) : [...prev, id],
    );
  }

  async function handleSave() {
    if (!name.trim()) {
      setError("Name is required");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const payload = { name: name.trim(), type, tagIds };
      const res =
        mode === "create"
          ? await fetch("/api/user/sets", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(payload),
            })
          : await fetch(`/api/user/sets/${initial!.id}`, {
              method: "PATCH",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(payload),
            });
      const body = (await res.json()) as { set?: SetDetail; error?: string };
      if (!res.ok || !body.set) {
        setError(body.error ?? "Failed to save set");
        return;
      }
      onSaved(body.set);
    } catch {
      setError("Failed to save set");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="center">
          <Text size="sm" weight="medium">
            {mode === "create" ? "Create set" : `Edit · ${initial?.name}`}
          </Text>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <TextField
          label="Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="e.g. Solar Add Clear Kit"
        />

        <SelectField
          label="Type"
          value={type}
          disabled={mode === "edit"}
          onChange={(e) => setType(e.target.value as SetType)}
        >
          {SET_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </SelectField>

        <Stack gap={6}>
          <Text size="xs" tone="muted">
            Concept tags
          </Text>
          <Cluster gap={6}>
            {CONCEPT_TAGS.map((tag) => (
              <FilterChip
                key={tag.id}
                label={tag.label}
                active={tagIds.includes(tag.id)}
                onClick={() => toggleTag(tag.id)}
              />
            ))}
          </Cluster>
        </Stack>

        <Row gap={8}>
          <Button
            size="sm"
            variant="accent"
            disabled={busy || !name.trim()}
            onClick={() => void handleSave()}
          >
            {busy ? "Saving…" : "Save"}
          </Button>
          <Button size="sm" variant="ghost" disabled={busy} onClick={onClose}>
            Cancel
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
