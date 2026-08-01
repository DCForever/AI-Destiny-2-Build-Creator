"use client";

import { useState } from "react";

import type { SetDetail } from "@/components/sets/types";
import {
  Badge,
  Button,
  Callout,
  Cluster,
  ConceptTagFilterChip,
  Panel,
  Row,
  SectionLabel,
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
    <Panel tone="default" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={8} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Text size="sm" weight="medium">
              {mode === "create" ? "New set" : "Edit set meta"}
            </Text>
            <Row gap={6} align="center" wrap>
              <Text size="sm" tone="muted" className="min-w-0 truncate">
                {mode === "edit"
                  ? (initial?.name ?? "Set")
                  : name.trim() || "Name this kit"}
              </Text>
              <Badge
                tone={mode === "edit" ? "verified" : "accent"}
                title={
                  mode === "edit"
                    ? "Type is locked after create"
                    : "Choose kit type before filling slots"
                }
              >
                {type}
              </Badge>
            </Row>
            <Text size="xs" tone="muted">
              {mode === "edit"
                ? "Update name and tags only — fill slots from the set detail."
                : "Create the kit shell, then fill slots from the open set."}
            </Text>
          </Stack>
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
          <SectionLabel>Concept tags</SectionLabel>
          <Cluster gap={6}>
            {CONCEPT_TAGS.map((tag) => (
              <ConceptTagFilterChip
                key={tag.id}
                tagId={tag.id}
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
