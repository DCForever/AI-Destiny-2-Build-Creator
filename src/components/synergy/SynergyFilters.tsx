"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import {
  Button,
  Chip,
  Cluster,
  FilterChip,
  Panel,
  Row,
  SectionLabel,
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

const SORTED_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

type SubTypeOption = { name: string; description?: string };

/**
 * Type chips + expandable subtype submenu (canvas: "Filters with subtype submenu").
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
  const [expandedType, setExpandedType] = useState<SubTypeRequiredType | null>(
    null,
  );
  const [subQuery, setSubQuery] = useState("");
  const [subOptions, setSubOptions] = useState<SubTypeOption[]>([]);
  const [subLoading, setSubLoading] = useState(false);
  const [subError, setSubError] = useState<string | null>(null);

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
    // Server already filters when subQuery is set; still sort client-side for stability.
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

  const hasFilters =
    typeFilter.length > 0 || subTypeFilter.length > 0 || query.trim().length > 0;

  return (
    <Panel tone="muted" pad="md">
      <Stack gap={12}>
        <SectionLabel>Filters</SectionLabel>
        <TextField
          label="Search"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder="Search name, subtype, or link…"
        />

        <Stack gap={6}>
          <Text size="xs" tone="muted" className="uppercase tracking-widest">
            Type
          </Text>
          <Cluster gap={6}>
            {SORTED_TYPES.map((t) => {
              const hasSubs = requiresSubType(t);
              const active =
                typeFilter.includes(t) || expandedType === t;
              return (
                <FilterChip
                  key={t}
                  label={
                    hasSubs
                      ? `${getSynergyTypeLabel(t)} +`
                      : getSynergyTypeLabel(t)
                  }
                  active={active}
                  onClick={() => onTypeClick(t)}
                />
              );
            })}
          </Cluster>
        </Stack>

        {expandedType ? (
          <Panel tone="raised" pad="sm">
            <Stack gap={10}>
              <Row justify="between" align="center" gap={8} wrap>
                <Text size="sm" weight="medium">
                  {getSynergyTypeLabel(expandedType)} — specific options
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
                      <button
                        key={name}
                        type="button"
                        onClick={() => toggleSubType(name)}
                        title="Remove subtype filter"
                      >
                        <Chip accent>{name} ×</Chip>
                      </button>
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

        {hasFilters ? (
          <Row>
            <button
              type="button"
              className="text-[10px] tracking-widest uppercase text-muted hover:text-foreground"
              onClick={() => {
                onTypeFilterChange([]);
                onSubTypeFilterChange([]);
                onQueryChange("");
                setExpandedType(null);
                setSubQuery("");
              }}
            >
              Clear filters
            </button>
          </Row>
        ) : null}
      </Stack>
    </Panel>
  );
}
