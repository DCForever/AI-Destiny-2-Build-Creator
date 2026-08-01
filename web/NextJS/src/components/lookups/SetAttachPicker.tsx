"use client";

import { useMemo, useState } from "react";

import { CONCEPT_TAGS } from "@/data/conceptTags";
import { SET_TYPES, type SetType } from "@/lib/sets/schemas";
import { sortByName } from "@/lib/sortByName";
import {
  Button,
  Cluster,
  FilterChip,
  Row,
  SelectField,
  Stack,
  Text,
  TextField,
} from "@/components/ui";

type AttachMode = "live" | "snapshot";
type SetSummary = { id: string; name: string; type: string };

export function SetAttachPicker({
  onAttach,
  disabled = false,
  excludeIds = [],
}: {
  onAttach: (
    attachment: { setId: string; mode: AttachMode },
    setMeta: SetSummary,
  ) => void;
  disabled?: boolean;
  excludeIds?: string[];
}) {
  const [type, setType] = useState<SetType>("weapon");
  const [query, setQuery] = useState("");
  const [tagId, setTagId] = useState<string | null>(null);
  const [sets, setSets] = useState<SetSummary[]>([]);
  const [selectedSetId, setSelectedSetId] = useState("");
  const [mode, setMode] = useState<AttachMode>("live");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loadedOnce, setLoadedOnce] = useState(false);

  const visible = useMemo(() => {
    const excluded = new Set(excludeIds);
    const q = query.trim().toLowerCase();
    return sets.filter((s) => {
      if (excluded.has(s.id)) return false;
      if (!q) return true;
      return `${s.name} ${s.type}`.toLowerCase().includes(q);
    });
  }, [sets, excludeIds, query]);

  const selected = visible.find((s) => s.id === selectedSetId) ?? null;

  async function loadSets() {
    setBusy(true);
    setError(null);
    try {
      const params = new URLSearchParams({ type });
      if (tagId) params.set("tags", tagId);
      const res = await fetch(`/api/user/sets?${params}`);
      const body = (await res.json()) as { sets?: SetSummary[]; error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to load sets");
        setSets([]);
        setSelectedSetId("");
        return;
      }
      const rows = sortByName(body.sets ?? []);
      setSets(rows);
      setSelectedSetId((cur) =>
        rows.some((s) => s.id === cur) ? cur : rows[0]?.id ?? "",
      );
      setLoadedOnce(true);
    } catch {
      setError("Failed to load sets");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={10}>
      <Row gap={8} wrap>
        <SelectField
          label="Set type"
          value={type}
          disabled={disabled}
          onChange={(e) => setType(e.target.value as SetType)}
        >
          {SET_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </SelectField>
        <SelectField
          label="Attach mode"
          value={mode}
          disabled={disabled}
          onChange={(e) => setMode(e.target.value as AttachMode)}
        >
          <option value="live">Live</option>
          <option value="snapshot">Snapshot</option>
        </SelectField>
      </Row>
      <TextField
        label="Filter loaded sets"
        value={query}
        disabled={disabled}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search name…"
      />
      <Stack gap={4}>
        <Text size="xs" tone="muted">
          Concept tag (optional)
        </Text>
        <Cluster gap={6}>
          {CONCEPT_TAGS.slice(0, 12).map((tag) => (
            <FilterChip
              key={tag.id}
              label={tag.label}
              active={tagId === tag.id}
              onClick={() => setTagId((prev) => (prev === tag.id ? null : tag.id))}
            />
          ))}
        </Cluster>
      </Stack>
      <Row gap={8}>
        <Button size="sm" disabled={disabled || busy} onClick={() => void loadSets()}>
          {busy ? "Loading…" : loadedOnce ? "Refresh" : "Load sets"}
        </Button>
      </Row>
      {error ? (
        <Text size="xs" tone="danger">
          {error}
        </Text>
      ) : null}
      {!loadedOnce ? (
        <Text size="xs" tone="muted">
          Load sets for the selected type, then attach.
        </Text>
      ) : visible.length === 0 ? (
        <Text size="xs" tone="muted">
          No sets for this type. Create one on the Sets tab first.
        </Text>
      ) : (
        <Stack gap={4} className="max-h-48 overflow-auto">
          {visible.map((set) => (
            <button
              key={set.id}
              type="button"
              disabled={disabled}
              className={`text-left px-2 py-1.5 text-sm border ${
                selectedSetId === set.id
                  ? "border-accent bg-accent/10"
                  : "border-line bg-surface-raised hover:border-line-strong"
              }`}
              onClick={() => setSelectedSetId(set.id)}
            >
              <span className="font-medium">{set.name}</span>
              <span className="ml-2 text-xs text-muted">{set.type}</span>
            </button>
          ))}
        </Stack>
      )}
      <Button
        size="sm"
        variant="accent"
        disabled={disabled || !selected}
        onClick={() => {
          if (!selected) return;
          onAttach({ setId: selected.id, mode }, selected);
        }}
      >
        Attach set
      </Button>
    </Stack>
  );
}
