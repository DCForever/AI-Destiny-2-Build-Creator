"use client";

import { useMemo, useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Button,
  Cluster,
  EntityHotspot,
  FilterChip,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import {
  groupAndSortModSearchResults,
  modSlotCategoryLabel,
} from "@/lib/manifest/modSearchGroups";

export type ManifestPick = {
  hash: number;
  name: string;
  icon?: string | null;
  kind?: string;
  description?: string;
  /** Aspects: sockets for fragments. */
  fragmentCapacity?: number;
  /** Mods: armor energy cost. */
  energyCost?: number | null;
  /** Mods: helmet | arms | chest | legs | classItem | general | tuning */
  slotCategory?: string;
  perks?: Array<{ hash: number; name: string; column?: number; row?: number }>;
};

type Category =
  | "weapons"
  | "exotic-weapons"
  | "mods"
  | "exotic-armor"
  | "aspects"
  | "fragments"
  | "abilities"
  | "artifacts";

export function ManifestSearchPicker({
  label,
  category,
  kind,
  classType,
  subclass,
  selected,
  onSelect,
  multi,
  selectedNames,
  onToggleName,
  /** Prefer when capacity/cost meta is needed (aspects/mods). */
  onTogglePick,
  disabled,
  emptyBrowse = true,
  /** When multi, block adding beyond this count (aspects). */
  maxSelected,
  /**
   * Mod fill context: only show plugs legal for this armor piece
   * (matching category + general/tuning). Filters search/browse results.
   */
  targetArmorSlot,
}: {
  label: string;
  category: Category;
  kind?: "super" | "grenade" | "melee" | "classAbility" | "movement";
  classType?: "Titan" | "Hunter" | "Warlock";
  subclass?: string;
  selected?: ManifestPick | null;
  onSelect?: (item: ManifestPick | null) => void;
  multi?: boolean;
  selectedNames?: string[];
  onToggleName?: (name: string) => void;
  onTogglePick?: (item: ManifestPick) => void;
  disabled?: boolean;
  emptyBrowse?: boolean;
  maxSelected?: number;
  targetArmorSlot?: string | null;
}) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<ManifestPick[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function runSearch(forceEmpty = false) {
    const q = query.trim();
    if (!q && !emptyBrowse && !forceEmpty) return;
    setBusy(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        category,
        q,
        limit: q ? "20" : category === "mods" ? "80" : "50",
      });
      if (kind) params.set("kind", kind);
      if (classType) params.set("classType", classType);
      if (subclass) params.set("subclass", subclass);
      if (category === "mods" && targetArmorSlot) {
        params.set("armorSlot", targetArmorSlot);
      }
      const res = await fetch(`/api/manifest/search?${params}`);
      const body = (await res.json()) as {
        results?: ManifestPick[];
        error?: string;
      };
      if (!res.ok) {
        setError(body.error ?? "Search failed");
        setResults([]);
        return;
      }
      setResults(body.results ?? []);
    } catch {
      setError("Search failed");
      setResults([]);
    } finally {
      setBusy(false);
    }
  }

  const modGroups = useMemo(() => {
    if (category !== "mods" || results.length === 0) return null;
    return groupAndSortModSearchResults(results, {
      targetArmorSlot,
      hideDeprecated: true,
    });
  }, [category, results, targetArmorSlot]);

  function renderResultButton(item: ManifestPick) {
    const active = multi
      ? selectedNames?.includes(item.name)
      : selected?.hash === item.hash;
    const atMax =
      multi &&
      maxSelected != null &&
      !active &&
      (selectedNames?.length ?? 0) >= maxSelected;
    const slotLabel = modSlotCategoryLabel(item.slotCategory);
    return (
      <button
        key={`${item.hash}-${item.name}`}
        type="button"
        disabled={disabled || atMax}
        className={`text-left px-2 py-1.5 text-sm border ${
          active
            ? "border-accent bg-accent/10 text-foreground"
            : "border-line bg-surface-raised hover:border-line-strong text-foreground"
        } disabled:opacity-50`}
        onClick={() => {
          if (multi) {
            if (onTogglePick) onTogglePick(item);
            else onToggleName?.(item.name);
          } else {
            onSelect?.(item);
            setResults([]);
            setQuery("");
          }
        }}
      >
        <span className="flex items-center gap-2 min-w-0">
          <ItemIcon icon={item.icon ?? null} name={item.name} size={32} />
          <span className="min-w-0">
            <span className="font-medium">{item.name}</span>
            {item.kind ? (
              <span className="ml-2 text-xs text-muted">{item.kind}</span>
            ) : null}
            {typeof item.fragmentCapacity === "number" ? (
              <span className="ml-2 text-xs text-muted">
                +{item.fragmentCapacity} frag
              </span>
            ) : null}
            {typeof item.energyCost === "number" ? (
              <span className="ml-2 text-xs text-muted">
                {item.energyCost} energy
              </span>
            ) : null}
            {slotLabel ? (
              <span className="ml-2 text-xs text-muted">{slotLabel}</span>
            ) : null}
            {item.description?.trim() ? (
              <span
                className="block text-xs text-muted leading-snug line-clamp-2 mt-0.5"
                title={item.description}
              >
                {item.description}
              </span>
            ) : null}
          </span>
        </span>
      </button>
    );
  }

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted">
        {label}
      </Text>
      {!multi && selected ? (
        <Row justify="between" align="center" gap={8}>
          <EntityHotspot
            kind={selected.kind ?? category}
            name={selected.name}
            description={selected.description}
            icon={selected.icon}
            size={32}
            showLabel="always"
          />
          <Button
            size="sm"
            variant="ghost"
            disabled={disabled}
            onClick={() => onSelect?.(null)}
          >
            Clear
          </Button>
        </Row>
      ) : null}
      {multi && (selectedNames?.length ?? 0) > 0 ? (
        <Cluster gap={6}>
          {selectedNames!.map((name) => (
            <FilterChip
              key={name}
              label={name}
              active
              onClick={() => onToggleName?.(name)}
            />
          ))}
        </Cluster>
      ) : null}
      <Row gap={8} align="end" wrap>
        <TextField
          label="Search"
          value={query}
          disabled={disabled}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void runSearch();
          }}
          className="min-w-[200px] flex-1"
        />
        <Button size="sm" disabled={disabled || busy} onClick={() => void runSearch()}>
          {busy ? "…" : emptyBrowse && !query.trim() ? "Browse" : "Search"}
        </Button>
      </Row>
      {error ? (
        <Text size="xs" tone="danger">
          {error}
        </Text>
      ) : null}
      {modGroups && modGroups.length > 0 ? (
        <Stack gap={10} className="max-h-72 overflow-auto">
          {modGroups.map((group) => (
            <Stack key={group.key} gap={4}>
              <Text
                size="xs"
                tone="muted"
                weight="medium"
                className="uppercase tracking-wide sticky top-0 bg-surface z-[1] py-0.5"
              >
                {group.label}
                <span className="ml-1 font-normal opacity-70">
                  ({group.items.length})
                </span>
              </Text>
              <Stack gap={4}>
                {group.items.map((item) =>
                  renderResultButton({
                    hash: item.hash,
                    name: item.name,
                    description: item.description ?? undefined,
                    slotCategory: item.slotCategory ?? undefined,
                    energyCost: item.energyCost,
                    icon: (item.icon as string | null | undefined) ?? null,
                  }),
                )}
              </Stack>
            </Stack>
          ))}
        </Stack>
      ) : results.length > 0 ? (
        <Stack gap={4} className="max-h-48 overflow-auto">
          {results.map((item) => renderResultButton(item))}
        </Stack>
      ) : null}
    </Stack>
  );
}
