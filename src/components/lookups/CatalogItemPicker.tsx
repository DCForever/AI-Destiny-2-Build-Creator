"use client";

import { useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import type { CatalogItem } from "@/lib/catalog/types";
import {
  CATALOG_AMMO_TYPES,
  CATALOG_ARMOR_ARCHETYPES,
  CATALOG_ELEMENTS,
  CATALOG_WEAPON_ARCHETYPES,
  toggleFilterValue,
} from "@/lib/catalog/filterOptions";
import { setSlotToCatalogBucket } from "@/lib/sets/catalogSlotMap";
import {
  Button,
  Cluster,
  FilterChip,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";

export type CatalogPick = {
  hash: number;
  name: string;
  slot?: string;
  ownedCount: number;
  instancesHref?: string;
};

/**
 * Catalog search for Sets fill-slot and similar pickers.
 * Weapons: multi element / ammo / archetype. Armor: multi archetype (frame).
 */
export function CatalogItemPicker({
  kind,
  setSlot,
  scope = "all",
  selected,
  onSelect,
  disabled,
  /** When true (default), show multi-select element/archetype filters. */
  showMultiFilters = true,
}: {
  kind: "weapons" | "armor";
  /** Set domain slot (primary, helmet, …) mapped to catalog bucket. */
  setSlot?: string;
  scope?: "all" | "owned";
  selected?: CatalogPick | null;
  onSelect: (item: CatalogPick | null) => void;
  disabled?: boolean;
  showMultiFilters?: boolean;
}) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<CatalogItem[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [elements, setElements] = useState<string[]>([]);
  const [ammos, setAmmos] = useState<string[]>([]);
  const [archetypes, setArchetypes] = useState<string[]>([]);

  async function runSearch() {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const params = new URLSearchParams({
        scope,
        includeInstancePointer: "1",
        limit: "40",
      });
      if (query.trim()) params.set("q", query.trim());
      const bucket = setSlot ? setSlotToCatalogBucket(setSlot) : null;
      if (bucket) params.set("slot", bucket);
      if (kind === "weapons") {
        if (elements.length) params.set("element", elements.join(","));
        if (ammos.length) params.set("ammo", ammos.join(","));
        if (archetypes.length) params.set("itemType", archetypes.join(","));
      } else if (kind === "armor") {
        // Armor uses `frame` for Armor 3.0 archetype name.
        if (archetypes.length) params.set("frame", archetypes.join(","));
      }
      const res = await fetch(`/api/catalog/${kind}?${params}`);
      const body = (await res.json()) as {
        items?: CatalogItem[];
        error?: string;
        message?: string;
        syncPrompt?: boolean;
      };
      if (!res.ok) {
        setError(body.error ?? "Catalog search failed");
        setResults([]);
        return;
      }
      setResults(body.items ?? []);
      if (body.syncPrompt && body.message) setMessage(body.message);
    } catch {
      setError("Catalog search failed");
      setResults([]);
    } finally {
      setBusy(false);
    }
  }

  const multiActive =
    elements.length + ammos.length + archetypes.length > 0;

  return (
    <Stack gap={8}>
      {selected ? (
        <Row justify="between" align="center" gap={8}>
          <Cluster gap={6}>
            <Text size="sm">{selected.name}</Text>
            {selected.ownedCount > 0 ? (
              <Text size="xs" tone="muted" as="span">
                · {selected.ownedCount} owned
              </Text>
            ) : null}
          </Cluster>
          <Button
            size="sm"
            variant="ghost"
            disabled={disabled}
            onClick={() => onSelect(null)}
          >
            Clear
          </Button>
        </Row>
      ) : null}
      <Row gap={8} align="end" wrap>
        <TextField
          label="Catalog search"
          value={query}
          disabled={disabled}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void runSearch();
          }}
          className="min-w-[200px] flex-1"
          placeholder="Name, perk, frame…"
        />
        <Button
          size="sm"
          disabled={disabled || busy}
          onClick={() => void runSearch()}
        >
          {busy ? "…" : "Search"}
        </Button>
      </Row>
      <Cluster gap={6}>
        <FilterChip
          label={scope === "owned" ? "Owned" : "Manifest"}
          active
          onClick={() => undefined}
        />
        {setSlot ? (
          <FilterChip
            label={`Slot · ${setSlot}`}
            active
            onClick={() => undefined}
          />
        ) : null}
      </Cluster>

      {showMultiFilters ? (
        <Stack gap={6}>
          {kind === "weapons" ? (
            <>
              <Stack gap={2}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Element
                  {elements.length > 0 ? ` · ${elements.length}` : ""}
                </Text>
                <Cluster gap={6}>
                  {CATALOG_ELEMENTS.map((el) => (
                    <FilterChip
                      key={el}
                      label={el}
                      active={elements.includes(el)}
                      onClick={() =>
                        setElements((prev) => toggleFilterValue(prev, el))
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
              <Stack gap={2}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Ammo
                  {ammos.length > 0 ? ` · ${ammos.length}` : ""}
                </Text>
                <Cluster gap={6}>
                  {CATALOG_AMMO_TYPES.map((a) => (
                    <FilterChip
                      key={a}
                      label={a}
                      active={ammos.includes(a)}
                      onClick={() =>
                        setAmmos((prev) => toggleFilterValue(prev, a))
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
              <Stack gap={2}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Archetype
                  {archetypes.length > 0 ? ` · ${archetypes.length}` : ""}
                </Text>
                <Cluster gap={6}>
                  {CATALOG_WEAPON_ARCHETYPES.map((t) => (
                    <FilterChip
                      key={t}
                      label={t}
                      active={archetypes.includes(t)}
                      onClick={() =>
                        setArchetypes((prev) => toggleFilterValue(prev, t))
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
            </>
          ) : (
            <Stack gap={2}>
              <Text
                size="xs"
                tone="muted"
                className="uppercase tracking-widest"
              >
                Armor archetype
                {archetypes.length > 0 ? ` · ${archetypes.length}` : ""}
              </Text>
              <Cluster gap={6}>
                {CATALOG_ARMOR_ARCHETYPES.map((t) => (
                  <FilterChip
                    key={t}
                    label={t}
                    active={archetypes.includes(t)}
                    onClick={() =>
                      setArchetypes((prev) => toggleFilterValue(prev, t))
                    }
                  />
                ))}
              </Cluster>
            </Stack>
          )}
          {multiActive ? (
            <Button
              size="sm"
              variant="ghost"
              disabled={disabled}
              onClick={() => {
                setElements([]);
                setAmmos([]);
                setArchetypes([]);
              }}
            >
              Clear filters
            </Button>
          ) : null}
        </Stack>
      ) : null}

      {error ? (
        <Text size="xs" tone="danger">
          {error}
        </Text>
      ) : null}
      {message ? (
        <Text size="xs" tone="muted">
          {message}
        </Text>
      ) : null}
      {results.length > 0 ? (
        <Stack gap={4} className="max-h-56 overflow-auto">
          {results.map((item) => (
            <button
              key={item.hash}
              type="button"
              disabled={disabled}
              className="text-left px-2 py-1.5 text-sm border border-line bg-surface-raised hover:border-line-strong disabled:opacity-50"
              onClick={() => {
                onSelect({
                  hash: item.hash,
                  name: item.name,
                  slot: item.slot,
                  ownedCount: item.ownedCount,
                  instancesHref: item.instancesHref,
                });
                setResults([]);
                setQuery("");
              }}
            >
              <span className="flex items-center gap-2 min-w-0">
                <ItemIcon icon={item.icon} name={item.name} size={32} />
                <span className="min-w-0">
                  <span className="font-medium">{item.name}</span>
                  <span className="ml-2 text-xs text-muted">
                    {[
                      item.slot,
                      item.element,
                      item.ammo,
                      item.itemTypeName ?? item.frame,
                      item.isExotic ? "Exotic" : null,
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                    {item.ownedCount > 0 ? ` · ×${item.ownedCount}` : ""}
                  </span>
                </span>
              </span>
            </button>
          ))}
        </Stack>
      ) : null}
    </Stack>
  );
}
