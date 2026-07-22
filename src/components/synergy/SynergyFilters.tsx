"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import {
  Button,
  Cluster,
  CollapsibleFilterSection,
  FilterChip,
  Panel,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import {
  requiresSubType,
  type SubTypeRequiredType,
} from "@/lib/synergies/synergyTypeRules";
import { compareDisplayName } from "@/lib/sortByName";

type CreatableType = (typeof CREATABLE_SYNERGY_TYPES)[number];

/** Stable family groups — reduces the flat 15-chip wall. */
const TYPE_FAMILIES: { label: string; types: CreatableType[] }[] = [
  {
    label: "Kit",
    types: ["melee", "verb", "grenade", "super", "element"],
  },
  {
    label: "Weapons",
    types: [
      "primary_weapon",
      "special_weapon",
      "heavy_weapon",
      "general_weapon",
      "weapon_archetype",
    ],
  },
  {
    label: "Play",
    types: ["dps", "healing", "solo", "damage_resist", "team"],
  },
];

type SubTypeOption = { name: string; description?: string };

/**
 * Instrument strip: search always visible; type/subtype facets collapsed by default.
 */
export function SynergyFilters({
  query,
  onQueryChange,
  typeFilter,
  onTypeFilterChange,
  subTypeFilter,
  onSubTypeFilterChange,
}: {
  query: string;
  onQueryChange: (value: string) => void;
  typeFilter: string[];
  onTypeFilterChange: (next: string[]) => void;
  subTypeFilter: string[];
  onSubTypeFilterChange: (next: string[]) => void;
}) {
const facetCount = typeFilter.length + subTypeFilter.length;
  const activeCount = facetCount + (query.trim().length > 0 ? 1 : 0);
  const [filtersOpen, setFiltersOpen] = useState(() => facetCount > 0);
  const [expandedType, setExpandedType] = useState<SubTypeRequiredType | null>(
    null,
  );
  const [subQuery, setSubQuery] = useState("");
  const [subOptions, setSubOptions] = useState<SubTypeOption[]>([]);
  const [subLoading, setSubLoading] = useState(false);
  const [subError, setSubError] = useState<string | null>(null);

  // Open facets when filters become active from outside; never force-open on clear.
  useEffect(() => {
    if (facetCount > 0) setFiltersOpen(true);
  }, [facetCount]);

  const loadSubTypes = useCallback(async (category: SubTypeRequiredType, q: string) => {
    setSubLoading(true);
    setSubError(null);
    try {
      const params = new URLSearchParams({ category });
      if (q.trim()) {
        params.set("q", q.trim());
        params.set("limit", "80");
      }
      const res = await fetch(
        `/api/catalog/synergy-pickers/subtypes?${params}`,
      );
      const body = (await res.json()) as {
        options?: SubTypeOption[];
        error?: string;
      };
      if (!res.ok) {
        setSubError(body.error ?? "Failed to load subtypes");
        setSubOptions([]);
        return;
      }
      setSubOptions(body.options ?? []);
    } catch {
      setSubError("Failed to load subtypes");
      setSubOptions([]);
    } finally {
      setSubLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!expandedType) {
      return;
    }
    let cancelled = false;
    void (async () => {
      setSubLoading(true);
      setSubError(null);
      try {
        const params = new URLSearchParams({ category: expandedType });
        if (subQuery.trim()) {
          params.set("q", subQuery.trim());
          params.set("limit", "80");
        }
        const res = await fetch(
          `/api/catalog/synergy-pickers/subtypes?${params}`,
        );
        if (cancelled) return;
        const body = (await res.json()) as {
          options?: SubTypeOption[];
          error?: string;
        };
        if (!res.ok) {
          setSubError(body.error ?? "Failed to load subtypes");
          setSubOptions([]);
          return;
        }
        setSubOptions(body.options ?? []);
      } catch {
        if (!cancelled) {
          setSubError("Failed to load subtypes");
          setSubOptions([]);
        }
      } finally {
        if (!cancelled) setSubLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [expandedType, subQuery]);

  const visibleSubs = useMemo(() => {
    return [...subOptions].sort((a, b) =>
      compareDisplayName(a.name, b.name),
    );
  }, [subOptions]);

  function onTypeClick(type: (typeof CREATABLE_SYNERGY_TYPES)[number]) {
    if (requiresSubType(type)) {
      setExpandedType((prev) => (prev === type ? null : type));
      setSubQuery("");
      onTypeFilterChange(
        typeFilter.includes(type) ? typeFilter : [...typeFilter, type],
      );
      return;
    }
    setExpandedType(null);
    onTypeFilterChange(
      typeFilter.includes(type)
        ? typeFilter.filter((t) => t !== type)
        : [...typeFilter, type],
    );
  }

  function toggleSubType(name: string) {
    onSubTypeFilterChange(
      subTypeFilter.includes(name)
        ? subTypeFilter.filter((s) => s !== name)
        : [...subTypeFilter, name],
    );
  }

  function clearFilters() {
    onTypeFilterChange([]);
    onSubTypeFilterChange([]);
    onQueryChange("");
    setExpandedType(null);
    setSubQuery("");
    setFiltersOpen(false);
  }

  return (
    <CollapsibleFilterSection
      open={filtersOpen}
      onOpenChange={setFiltersOpen}
activeCount={activeCount}
      onClear={activeCount > 0 ? clearFilters : undefined}
      panel={false}
      label="Type filters"
      leading={
        <div className="min-w-0 flex-1 max-w-md">
          <label className="sr-only" htmlFor="synergy-search">
            Search designations
          </label>
          <input
            id="synergy-search"
            type="search"
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
            placeholder="Search name, subtype, or link…"
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground placeholder:text-muted"
          />
        </div>
      }
      summary={
        <Cluster gap={3}>
          {typeFilter.map((t) => (
            <FilterChip
              key={t}
              size="xs"
              label={getSynergyTypeLabel(t)}
              active
              onClick={() =>
                onTypeFilterChange(typeFilter.filter((x) => x !== t))
              }
            />
          ))}
          {subTypeFilter.map((name) => (
            <FilterChip
              key={name}
              size="xs"
              label={name}
              active
              onClick={() => toggleSubType(name)}
            />
          ))}
        </Cluster>
      }
    >
      <Stack gap={10}>
        <Stack gap={10}>
          <Text size="xs" tone="muted" className="uppercase tracking-widest">
            Type
          </Text>
          {TYPE_FAMILIES.map((family) => (
            <Stack key={family.label} gap={4}>
              <Text size="xs" tone="muted">
                {family.label}
              </Text>
              <Cluster gap={6}>
                {family.types.map((t) => {
                  const hasSubs = requiresSubType(t);
                  const active =
                    typeFilter.includes(t) || expandedType === t;
                  return (
                    <FilterChip
                      key={t}
                      label={
                        hasSubs
                          ? `${getSynergyTypeLabel(t)} ·`
                          : getSynergyTypeLabel(t)
                      }
                      active={active}
                      onClick={() => onTypeClick(t)}
                      title={
                        hasSubs
                          ? `${getSynergyTypeLabel(t)} — open subtypes`
                          : getSynergyTypeLabel(t)
                      }
                    />
                  );
                })}
              </Cluster>
            </Stack>
          ))}
        </Stack>

        {expandedType ? (
          <Panel tone="raised" pad="sm">
            <Stack gap={10}>
              <Row justify="between" align="center" gap={8} wrap>
                <Text size="sm" weight="medium">
                  {getSynergyTypeLabel(expandedType)} — subtypes
                </Text>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setExpandedType(null)}
                >
                  Close
                </Button>
              </Row>
              <TextField
                label="Search subtypes"
                value={subQuery}
                onChange={(e) => setSubQuery(e.target.value)}
                placeholder={`Search ${getSynergyTypeLabel(expandedType).toLowerCase()}…`}
              />
              {subError ? (
                <Text size="xs" tone="danger">
                  {subError}
                </Text>
              ) : null}
              {subLoading ? (
                <Text size="xs" tone="muted">
                  Loading subtypes…
                </Text>
              ) : visibleSubs.length === 0 ? (
                <Text size="xs" tone="muted">
                  No subtypes match.
                </Text>
              ) : (
                <Cluster gap={6}>
                  {visibleSubs.map((opt) => (
                    <FilterChip
                      key={opt.name}
                      label={opt.name}
                      active={subTypeFilter.includes(opt.name)}
                      onClick={() => toggleSubType(opt.name)}
                    />
                  ))}
                </Cluster>
              )}
              {subTypeFilter.length > 0 ? (
                <Stack gap={6}>
                  <Text size="xs" tone="muted">
                    Selected subtypes
                  </Text>
                  <Cluster gap={6}>
                    {subTypeFilter.map((name) => (
                      <FilterChip
                        key={name}
                        size="xs"
                        label={name}
                        active
                        onClick={() => toggleSubType(name)}
                        title="Remove subtype filter"
                      />
                    ))}
                  </Cluster>
                </Stack>
              ) : null}
              <Row gap={8}>
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={subLoading}
                  onClick={() => void loadSubTypes(expandedType, subQuery)}
                >
                  Refresh subtypes
                </Button>
              </Row>
            </Stack>
          </Panel>
        ) : null}
      </Stack>
    </CollapsibleFilterSection>
  );
}
