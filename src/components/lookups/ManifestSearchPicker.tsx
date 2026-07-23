"use client";

import { useEffect, useMemo, useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Button,
  Chip,
  Cluster,
  EntityHotspot,
  FilterChip,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";
import { groupAndSortExoticArmorSearchResults } from "@/lib/manifest/exoticArmorSearchGroups";
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
  /** Exotic armor / weapons: slot name from manifest. */
  slot?: string;
  /** Aspects: sockets for fragments. */
  fragmentCapacity?: number;
  /** Mods: armor energy cost. */
  energyCost?: number | null;
  /** Mods: helmet | arms | chest | legs | classItem | general | tuning */
  slotCategory?: string;
  perks?: Array<{ hash: number; name: string; column?: number; row?: number }>;
  linkedSynergies?: Array<{ id: string; label: string }>;
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

type LinkedSynergyChip = { id: string; label: string };

export function ManifestSearchPicker({
  label,
  category,
  kind,
  classType,
  subclass,
  element,
  selected,
  onSelect,
  multi,
  selectedNames,
  onToggleName,
  onTogglePick,
  disabled,
  emptyBrowse = true,
  maxSelected,
  targetArmorSlot,
}: {
  label: string;
  category: Category;
  kind?: "super" | "grenade" | "melee" | "classAbility" | "movement";
  classType?: "Titan" | "Hunter" | "Warlock";
  subclass?: string;
  element?: string;
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
  const [synergiesByHash, setSynergiesByHash] = useState<
    Record<string, LinkedSynergyChip[]>
  >({});

  const singleSelected = !multi && selected;
  const showSearchChrome = multi || !selected;

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
      if (element) params.set("element", element);
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
        setSynergiesByHash({});
        return;
      }
      setResults(body.results ?? []);
    } catch {
      setError("Search failed");
      setResults([]);
      setSynergiesByHash({});
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    if (category !== "exotic-armor" || results.length === 0) {
      setSynergiesByHash({});
      return;
    }
    let cancelled = false;
    const hashes = results.map((r) => r.hash).filter((h) => h > 0);
    if (hashes.length === 0) {
      setSynergiesByHash({});
      return;
    }

    async function load() {
      try {
        const params = new URLSearchParams({ kind: "exotic_armor" });
        for (const h of hashes) params.append("itemHash", String(h));
        const res = await fetch(`/api/user/synergies/by-target?${params}`);
        if (!res.ok || cancelled) {
          if (!cancelled) setSynergiesByHash({});
          return;
        }
        const body = (await res.json()) as {
          byItemHash?: Record<
            string,
            Array<{ id: string; type: string; subType?: string | null }>
          >;
          synergies?: Array<{
            id: string;
            type: string;
            subType?: string | null;
          }>;
        };

        const next: Record<string, LinkedSynergyChip[]> = {};
        if (body.byItemHash) {
          for (const [hash, list] of Object.entries(body.byItemHash)) {
            next[hash] = (list ?? []).map((s) => ({
              id: s.id,
              label: formatSynergyTypeDesignation({
                type: s.type,
                subType: s.subType,
              }),
            }));
          }
        } else if (body.synergies && hashes.length === 1) {
          next[String(hashes[0])] = body.synergies.map((s) => ({
            id: s.id,
            label: formatSynergyTypeDesignation({
              type: s.type,
              subType: s.subType,
            }),
          }));
        }
        if (!cancelled) setSynergiesByHash(next);
      } catch {
        if (!cancelled) setSynergiesByHash({});
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [category, results]);

  const modGroups = useMemo(() => {
    if (category !== "mods" || results.length === 0) return null;
    return groupAndSortModSearchResults(results, {
      targetArmorSlot,
      hideDeprecated: true,
    });
  }, [category, results, targetArmorSlot]);

  const exoticGroups = useMemo(() => {
    if (category !== "exotic-armor" || results.length === 0) return null;
    return groupAndSortExoticArmorSearchResults(results);
  }, [category, results]);

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
    const chips =
      synergiesByHash[String(item.hash)] ?? item.linkedSynergies ?? [];
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
            setSynergiesByHash({});
          }
        }}
      >
        <span className="flex items-start gap-2 min-w-0">
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
            {chips.length > 0 ? (
              <Cluster gap={4} className="mt-1">
                {chips.map((c) => (
                  <Chip key={c.id} accent>
                    {c.label}
                  </Chip>
                ))}
              </Cluster>
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
      {singleSelected ? (
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
      {showSearchChrome ? (
        <>
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
            <Button
              size="sm"
              disabled={disabled || busy}
              onClick={() => void runSearch()}
            >
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
          ) : exoticGroups && exoticGroups.length > 0 ? (
            <Stack gap={10} className="max-h-72 overflow-auto">
              {exoticGroups.map((group) => (
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
                        description:
                          typeof item.description === "string"
                            ? item.description
                            : undefined,
                        slot:
                          typeof item.slot === "string" ? item.slot : undefined,
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
        </>
      ) : null}
    </Stack>
  );
}
