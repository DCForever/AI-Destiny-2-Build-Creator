"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { InstancePerkGridView } from "@/components/catalog/InstancePerkGridView";
import { filterCatalogClient } from "@/lib/catalog/filterCatalogClient";
import {
  CATALOG_AMMO_TYPES,
  CATALOG_ARMOR_ARCHETYPES,
  CATALOG_ELEMENTS,
  CATALOG_WEAPON_ARCHETYPES,
  toggleFilterValue,
} from "@/lib/catalog/filterOptions";
import {
  ARMOR_GROUP_DIMENSIONS,
  groupCatalogItems,
  WEAPON_GROUP_DIMENSIONS,
} from "@/lib/catalog/groupCatalogItems";
import type { CatalogGroupDimension, CatalogItem } from "@/lib/catalog/types";
import { sortByName } from "@/lib/sortByName";
import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Button,
  Callout,
  Chip,
  ClassFilterChip,
  ClassIcon,
  Cluster,
  EmptyState,
  EntityHotspot,
  FilterChip,
  MetaChip,
  OfficialFilterIcon,
  PageFrame,
  PageFrameBody,
  PageFrameChrome,
  PageHeader,
  Panel,
  Row,
  Section,
  SectionLabel,
  Stack,
  Text,
  TextField,
  WeaponTypeIcon,
  Workspace,
  WorkspaceMain,
  Heading,
} from "@/components/ui";
import {
  AMMO_OFFICIAL,
  ELEMENT_OFFICIAL,
  officialActiveStyle,
  visualForAmmo,
  visualForArmorArchetype,
  visualForElement,
  visualForWeaponFrame,
} from "@/lib/destiny/catalogFilterVisuals";
import {
  CLASS_CSS_COLOR,
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  isGuardianClass,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";

type Kind = "weapons" | "armor";
type Scope = "all" | "owned";

type InstanceRow = {
  instanceId: string;
  power?: number;
  location?: string;
  isMasterwork?: boolean;
  plugs?: {
    displayName: string;
    resolved: boolean;
    hash?: number;
    icon?: string | null;
    description?: string | null;
  }[];
};

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

const WEAPON_SLOTS = ["Kinetic", "Energy", "Power"] as const;
const ARMOR_SLOTS = ["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"] as const;
const CLASSES = ["Titan", "Hunter", "Warlock"] as const;

/**
 * Catalog browse: filters · results rail · item detail + owned instances.
 */
export function CatalogPage() {
  const [kind, setKind] = useState<Kind>("weapons");
  const [scope, setScope] = useState<Scope>("owned");
  const [query, setQuery] = useState("");
  const [slot, setSlot] = useState<string | null>(null);
  const [className, setClassName] = useState<string | null>(null);
  const [onlyExotic, setOnlyExotic] = useState(false);
  /** Multi group-by dimensions (order of activation = key order). */
  const [groupDims, setGroupDims] = useState<CatalogGroupDimension[]>([]);
  /** Multi-select filters (OR within each dimension). */
  const [elements, setElements] = useState<string[]>([]);
  const [ammos, setAmmos] = useState<string[]>([]);
  const [archetypes, setArchetypes] = useState<string[]>([]);
  const [librarySynergies, setLibrarySynergies] = useState<
    Array<{ id: string; name: string; type: string; subType: string | null }>
  >([]);
  const [synergyIds, setSynergyIds] = useState<string[]>([]);
  const [synergiesSignedIn, setSynergiesSignedIn] = useState(false);
  const [synergyQuery, setSynergyQuery] = useState("");
  const [moreFiltersOpen, setMoreFiltersOpen] = useState(false);

  /** Server base set (kind/scope/synergy only). */
  const [baseItems, setBaseItems] = useState<CatalogItem[]>([]);
  const [selected, setSelected] = useState<CatalogItem | null>(null);
  const [instances, setInstances] = useState<InstanceRow[]>([]);
  const [linkedSynergies, setLinkedSynergies] = useState<
    Array<{ id: string; name: string; type: string }>
  >([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);
  /** Debounced free-text for client filter (typing stays live without fetch). */
  const [debouncedQuery, setDebouncedQuery] = useState("");

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const res = await fetch("/api/user/synergies");
        if (res.status === 401) {
          if (!cancelled) {
            setSynergiesSignedIn(false);
            setLibrarySynergies([]);
          }
          return;
        }
        if (!res.ok) return;
        const body = (await res.json()) as {
          synergies?: Array<{
            id: string;
            name: string;
            type: string;
            subType: string | null;
          }>;
        };
        if (!cancelled) {
          setSynergiesSignedIn(true);
          setLibrarySynergies(sortByName(body.synergies ?? []));
        }
      } catch {
        /* optional */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const t = window.setTimeout(() => setDebouncedQuery(query), 150);
    return () => window.clearTimeout(t);
  }, [query]);

  /** Base catalog fill: server only for kind / scope / synergy. */
  const loadBase = useCallback(
    async (signal?: AbortSignal) => {
      setLoading(true);
      setError(null);
      setSyncMessage(null);
      try {
        const params = new URLSearchParams({
          scope,
          includeInstancePointer: "1",
          limit: "500",
        });
        for (const id of synergyIds) {
          params.append("synergyId", id);
        }

        const res = await fetch(`/api/catalog/${kind}?${params}`, { signal });
        const body = (await res.json()) as {
          items?: CatalogItem[];
          error?: string;
          message?: string;
          syncPrompt?: boolean;
        };
        if (signal?.aborted) return;
        if (!res.ok) {
          setError(body.error ?? "Catalog load failed");
          setBaseItems([]);
          return;
        }
        setBaseItems(sortByName(body.items ?? []));
        if (body.message) setSyncMessage(body.message);
      } catch (e) {
        if (e instanceof DOMException && e.name === "AbortError") return;
        setError("Catalog load failed");
        setBaseItems([]);
      } finally {
        if (!signal?.aborted) setLoading(false);
      }
    },
    [kind, scope, synergyIds],
  );

  useEffect(() => {
    const ac = new AbortController();
    void loadBase(ac.signal);
    return () => ac.abort();
  }, [loadBase]);

  /** Live client filter on base set (instant chip / text updates). */
  const items = useMemo(
    () =>
      filterCatalogClient(baseItems, {
        query: debouncedQuery,
        slot,
        elements,
        ammos,
        archetypes,
        className,
        onlyExotic,
      }),
    [
      baseItems,
      debouncedQuery,
      slot,
      elements,
      ammos,
      archetypes,
      className,
      onlyExotic,
    ],
  );

  // Drop selection when live filters hide the current item.
  useEffect(() => {
    if (!selected) return;
    if (!items.some((i) => i.hash === selected.hash)) {
      setSelected(null);
      setInstances([]);
      setLinkedSynergies([]);
    }
  }, [items, selected]);

  const refreshBase = useCallback(() => {
    setSelected(null);
    setInstances([]);
    setLinkedSynergies([]);
    void loadBase();
  }, [loadBase]);

  const selectItem = useCallback(
    async (item: CatalogItem) => {
      setSelected(item);
      setInstances([]);
      setLinkedSynergies([]);

      if (kind === "weapons") {
        try {
          const params = new URLSearchParams({
            kind: "weapon",
            itemHash: String(item.hash),
          });
          const res = await fetch(`/api/user/synergies/by-target?${params}`);
          const body = (await res.json()) as {
            synergies?: Array<{ id: string; name: string; type: string }>;
          };
          if (res.ok) setLinkedSynergies(sortByName(body.synergies ?? []));
        } catch {
          /* optional */
        }
      }

      if (item.ownedCount <= 0) return;
      const href =
        item.instancesHref ??
        `/api/user/inventory/instances?itemHash=${item.hash}&kind=${kind}`;
      try {
        const res = await fetch(href);
        const body = (await res.json()) as {
          instances?: InstanceRow[];
          message?: string;
        };
        if (res.ok) setInstances(body.instances ?? []);
        else if (body.message) setSyncMessage(body.message);
      } catch {
        /* optional */
      }
    },
    [kind],
  );

  const slotOptions = kind === "weapons" ? WEAPON_SLOTS : ARMOR_SLOTS;
  const groupDimOptions =
    kind === "weapons" ? WEAPON_GROUP_DIMENSIONS : ARMOR_GROUP_DIMENSIONS;

  const grouped = useMemo(
    () => groupCatalogItems(items, groupDims),
    [items, groupDims],
  );

  const synergyLabelById = useMemo(() => {
    const map = new Map<string, string>();
    for (const s of librarySynergies) {
      map.set(
        s.id,
        formatSynergyTypeDesignation({ type: s.type, subType: s.subType }),
      );
    }
    return map;
  }, [librarySynergies]);

  const synergyPickerOptions = useMemo(() => {
    const q = synergyQuery.trim().toLowerCase();
    return librarySynergies
      .filter((s) => !synergyIds.includes(s.id))
      .map((s) => ({
        id: s.id,
        label:
          synergyLabelById.get(s.id) ??
          formatSynergyTypeDesignation({ type: s.type, subType: s.subType }),
      }))
      .filter((o) => !q || o.label.toLowerCase().includes(q))
      .slice(0, 12);
  }, [librarySynergies, synergyIds, synergyQuery, synergyLabelById]);

  const multiFilterCount =
    elements.length +
    ammos.length +
    archetypes.length +
    synergyIds.length +
    groupDims.length +
    (slot ? 1 : 0) +
    (className ? 1 : 0);

  function toggleGroupDim(dim: CatalogGroupDimension) {
    setGroupDims((prev) => {
      if (prev.includes(dim)) return prev.filter((d) => d !== dim);
      return [...prev, dim];
    });
  }

  function clearMultiFilters() {
    setElements([]);
    setAmmos([]);
    setArchetypes([]);
    setSynergyIds([]);
    setSlot(null);
    setClassName(null);
    setGroupDims([]);
    setSynergyQuery("");
  }

  function renderResultRow(item: CatalogItem) {
    const active = selected?.hash === item.hash;
    return (
      <button
        key={item.hash}
        type="button"
        className="text-left w-full"
        onClick={() => void selectItem(item)}
      >
        <Panel
          tone={active ? "accent" : "muted"}
          pad="sm"
          className={
            active ? "" : "hover:border-line-strong transition-colors"
          }
        >
          <Row gap={10} align="start">
            <ItemIcon icon={item.icon} name={item.name} size={40} />
            <Stack gap={4} className="min-w-0">
              <Text size="sm" weight="medium">
                {item.name}
              </Text>
              <Row gap={6} wrap>
                {item.isExotic ? <Chip accent>Exotic</Chip> : null}
                {item.slot ? <Chip>{item.slot}</Chip> : null}
                {item.element
                  ? (() => {
                      const v = visualForElement(item.element);
                      return v ? (
                        <MetaChip
                          label={item.element!}
                          iconOnly
                          accentColor={v.color}
                          icon={
                            <OfficialFilterIcon
                              icon={v.icon}
                              label={item.element!}
                              size={14}
                            />
                          }
                        />
                      ) : (
                        <Chip>{item.element}</Chip>
                      );
                    })()
                  : null}
                {item.ammo
                  ? (() => {
                      const v = visualForAmmo(item.ammo);
                      return v ? (
                        <MetaChip
                          label={item.ammo!}
                          iconOnly
                          accentColor={v.color}
                          icon={
                            <OfficialFilterIcon
                              icon={v.icon}
                              label={item.ammo!}
                              size={14}
                            />
                          }
                        />
                      ) : (
                        <Chip>{item.ammo}</Chip>
                      );
                    })()
                  : null}
                {item.frame
                  ? (() => {
                      const v = visualForWeaponFrame(item.frame);
                      return v ? (
                        <MetaChip
                          label={item.frame!}
                          iconOnly
                          icon={
                            <OfficialFilterIcon
                              icon={v.icon}
                              label={item.frame!}
                              size={14}
                            />
                          }
                        />
                      ) : (
                        <Chip>{item.frame}</Chip>
                      );
                    })()
                  : item.itemTypeName ? (
                      <MetaChip
                        label={item.itemTypeName}
                        iconOnly
                        icon={
                          <WeaponTypeIcon
                            typeName={item.itemTypeName}
                            size={12}
                          />
                        }
                      />
                    ) : null}
                {item.ownedCount > 0 ? (
                  <Text size="xs" tone="muted" as="span">
                    ×{item.ownedCount}
                  </Text>
                ) : null}
              </Row>
              {item.description?.trim() ? (
                <span
                  className="text-[11px] text-muted leading-snug line-clamp-2"
                  title={item.description}
                >
                  {item.description}
                </span>
              ) : null}
            </Stack>
          </Row>
        </Panel>
      </button>
    );
  }

  return (
    <PageFrame>
      <PageFrameChrome>
        <Stack gap={12}>
          <PageHeader
            title="Catalog"
            description="Browse weapons and armor from the manifest or your owned inventory."
          />
          {error ? <Callout tone="danger">{error}</Callout> : null}
          {syncMessage ? <Callout tone="warning">{syncMessage}</Callout> : null}

          <Panel tone="muted" pad="sm">
          <Stack gap={6}>
            {/* Browse + scope */}
            <Cluster gap={4}>
              <FilterChip
                size="xs"
                label="Weapons"
                active={kind === "weapons"}
                onClick={() => {
                  setKind("weapons");
                  setSlot(null);
                  setClassName(null);
                  setGroupDims([]);
                  setElements([]);
                  setAmmos([]);
                  setArchetypes([]);
                }}
              />
              <FilterChip
                size="xs"
                label="Armor"
                active={kind === "armor"}
                onClick={() => {
                  setKind("armor");
                  setSlot(null);
                  setGroupDims([]);
                  setElements([]);
                  setAmmos([]);
                  setArchetypes([]);
                }}
              />
              <FilterChip
                size="xs"
                label="Owned"
                active={scope === "owned"}
                onClick={() => setScope("owned")}
              />
              <FilterChip
                size="xs"
                label="Manifest"
                active={scope === "all"}
                onClick={() => setScope("all")}
              />
              <FilterChip
                size="xs"
                label="Exotic only"
                active={onlyExotic}
                onClick={() => setOnlyExotic((v) => !v)}
              />
            </Cluster>

            {/* Search + action */}
            <Row gap={6} align="end" wrap>
              <TextField
                label="Search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") refreshBase();
                }}
                placeholder="Name, frame, perk… (live filter)"
                className="min-w-[200px] flex-1"
              />
              <Button
                size="sm"
                variant="accent"
                disabled={loading}
                onClick={() => refreshBase()}
              >
                {loading ? "…" : "Refresh"}
              </Button>
              {multiFilterCount > 0 ? (
                <Button size="sm" variant="ghost" onClick={clearMultiFilters}>
                  Clear
                </Button>
              ) : null}
            </Row>

            {/* Dense toolbar: slot · class · element · ammo */}
            <Row gap={8} align="center" wrap className="gap-y-2">
              <Cluster gap={3}>
                {slotOptions.map((s) => (
                  <FilterChip
                    key={s}
                    size="xs"
                    label={s}
                    active={slot === s}
                    onClick={() => setSlot((prev) => (prev === s ? null : s))}
                  />
                ))}
              </Cluster>
              {kind === "armor" ? (
                <Cluster gap={3}>
                  {CLASSES.map((c) => (
                    <ClassFilterChip
                      key={c}
                      className={c}
                      active={className === c}
                      onClick={() =>
                        setClassName((prev) => (prev === c ? null : c))
                      }
                    />
                  ))}
                </Cluster>
              ) : null}
              {kind === "weapons" ? (
                <>
                  <Cluster gap={3}>
                    {CATALOG_ELEMENTS.map((el) => {
                      const visual = ELEMENT_OFFICIAL[el as DestinyElement];
                      const color =
                        visual?.color ?? ELEMENT_CSS_COLOR[el as DestinyElement];
                      return (
                        <FilterChip
                          key={el}
                          size="xs"
                          label={el}
                          iconOnly
                          icon={
                            visual ? (
                              <OfficialFilterIcon
                                icon={visual.icon}
                                label={el}
                                size={16}
                              />
                            ) : null
                          }
                          active={elements.includes(el)}
                          activeStyle={{
                            borderColor: color,
                            boxShadow: `0 0 0 1px ${color}`,
                            backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
                          }}
                          onClick={() =>
                            setElements((prev) => toggleFilterValue(prev, el))
                          }
                        />
                      );
                    })}
                  </Cluster>
                  <Cluster gap={3}>
                    {CATALOG_AMMO_TYPES.map((a) => {
                      const visual = AMMO_OFFICIAL[a];
                      return (
                        <FilterChip
                          key={a}
                          size="xs"
                          label={a}
                          iconOnly
                          icon={
                            <OfficialFilterIcon
                              icon={visual.icon}
                              label={a}
                              size={16}
                            />
                          }
                          active={ammos.includes(a)}
                          activeStyle={{
                            borderColor: visual.color,
                            boxShadow: `0 0 0 1px ${visual.color}`,
                            backgroundColor: `color-mix(in srgb, ${visual.color} 14%, transparent)`,
                          }}
                          onClick={() =>
                            setAmmos((prev) => toggleFilterValue(prev, a))
                          }
                        />
                      );
                    })}
                  </Cluster>
                </>
              ) : null}
            </Row>

            {/* Synergy: search + selected chips only */}
            {synergiesSignedIn && librarySynergies.length > 0 ? (
              <Stack gap={4}>
                <Row gap={6} align="end" wrap>
                  <TextField
                    label={`Synergy${synergyIds.length ? ` · ${synergyIds.length}` : ""}`}
                    value={synergyQuery}
                    onChange={(e) => setSynergyQuery(e.target.value)}
                    placeholder="Filter synergies… e.g. tangle, melee"
                    className="min-w-[180px] flex-1"
                  />
                </Row>
                {synergyIds.length > 0 ? (
                  <Cluster gap={3}>
                    {synergyIds.map((id) => (
                      <FilterChip
                        key={id}
                        size="xs"
                        label={synergyLabelById.get(id) ?? id}
                        active
                        onClick={() =>
                          setSynergyIds((prev) =>
                            prev.filter((x) => x !== id),
                          )
                        }
                      />
                    ))}
                  </Cluster>
                ) : null}
                {synergyQuery.trim() || synergyPickerOptions.length <= 8 ? (
                  <Cluster gap={3}>
                    {synergyPickerOptions.map((o) => (
                      <FilterChip
                        key={o.id}
                        size="xs"
                        label={o.label}
                        active={false}
                        onClick={() => {
                          setSynergyIds((prev) =>
                            prev.includes(o.id) ? prev : [...prev, o.id],
                          );
                          setSynergyQuery("");
                        }}
                      />
                    ))}
                    {synergyQuery.trim() && synergyPickerOptions.length === 0 ? (
                      <Text size="xs" tone="muted">
                        No matches
                      </Text>
                    ) : null}
                  </Cluster>
                ) : (
                  <Text size="xs" tone="muted">
                    Type to search {librarySynergies.length} synergies
                  </Text>
                )}
              </Stack>
            ) : null}

            {/* More filters: archetype + group by */}
            <Row gap={6} align="center" wrap>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setMoreFiltersOpen((v) => !v)}
              >
                {moreFiltersOpen ? "▾ More filters" : "▸ More filters"}
                {archetypes.length + groupDims.length > 0
                  ? ` · ${archetypes.length + groupDims.length}`
                  : ""}
              </Button>
            </Row>
            {moreFiltersOpen ? (
              <Stack gap={6}>
                <Stack gap={2}>
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-wide"
                  >
                    {kind === "weapons" ? "Weapon type" : "Armor archetype"}
                    {archetypes.length > 0 ? ` · ${archetypes.length}` : ""}
                  </Text>
                  <Cluster gap={3}>
                    {kind === "weapons"
                      ? CATALOG_WEAPON_ARCHETYPES.map((t) => (
                          <FilterChip
                            key={t}
                            size="xs"
                            label={t}
                            iconOnly
                            icon={<WeaponTypeIcon typeName={t} size={14} />}
                            active={archetypes.includes(t)}
                            onClick={() =>
                              setArchetypes((prev) =>
                                toggleFilterValue(prev, t),
                              )
                            }
                          />
                        ))
                      : CATALOG_ARMOR_ARCHETYPES.map((t) => {
                          const visual = visualForArmorArchetype(t);
                          return (
                            <FilterChip
                              key={t}
                              size="xs"
                              label={t}
                              iconOnly={Boolean(visual)}
                              icon={
                                visual ? (
                                  <OfficialFilterIcon
                                    icon={visual.icon}
                                    label={t}
                                    size={16}
                                  />
                                ) : null
                              }
                              active={archetypes.includes(t)}
                              activeStyle={
                                visual
                                  ? officialActiveStyle(visual)
                                  : undefined
                              }
                              onClick={() =>
                                setArchetypes((prev) =>
                                  toggleFilterValue(prev, t),
                                )
                              }
                            />
                          );
                        })}
                  </Cluster>
                </Stack>
                <Stack gap={2}>
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-wide"
                  >
                    Group by
                    {groupDims.length > 0
                      ? ` · ${groupDims
                          .map(
                            (d) =>
                              groupDimOptions.find((o) => o.id === d)?.label ??
                              d,
                          )
                          .join(" · ")}`
                      : ""}
                  </Text>
                  <Cluster gap={3}>
                    {groupDimOptions.map((opt) => (
                      <FilterChip
                        key={opt.id}
                        size="xs"
                        label={opt.label}
                        active={groupDims.includes(opt.id)}
                        onClick={() => toggleGroupDim(opt.id)}
                      />
                    ))}
                  </Cluster>
                </Stack>
              </Stack>
            ) : null}
          </Stack>
        </Panel>
        </Stack>
      </PageFrameChrome>

      <PageFrameBody>
        <Workspace
          rail={
            <Panel
              as="aside"
              className="h-full min-h-0 flex flex-col overflow-hidden"
            >
              <div className="shrink-0">
                <SectionLabel>
                  Results
                  {items.length > 0 ? ` · ${items.length}` : ""}
                </SectionLabel>
              </div>
              <div className="flex-1 min-h-0 overflow-y-auto mt-3">
                {loading && baseItems.length === 0 ? (
                  <Text size="sm" tone="muted">
                    Loading catalog…
                  </Text>
                ) : items.length === 0 ? (
                  <Text size="sm" tone="muted">
                    {baseItems.length === 0
                      ? (syncMessage ?? "No items in this catalog.")
                      : "No items match filters."}
                  </Text>
                ) : (
                  <Stack gap={10}>
                    {groupDims.length === 0
                      ? items.map((item) => renderResultRow(item))
                      : grouped.map((group) => (
                          <Stack key={group.key} gap={6}>
                            <Row justify="between" align="baseline" gap={8}>
                              <Text
                                size="xs"
                                tone="muted"
                                className="uppercase tracking-widest"
                              >
                                {group.label}
                              </Text>
                              <Text size="xs" tone="muted" as="span">
                                {group.items.length}
                              </Text>
                            </Row>
                            <Stack gap={6}>
                              {group.items.map((item) =>
                                renderResultRow(item),
                              )}
                            </Stack>
                          </Stack>
                        ))}
                  </Stack>
                )}
              </div>
            </Panel>
          }
          main={
            !selected ? (
              <WorkspaceMain>
                <EmptyState description="Select an item to see detail and owned instances." />
              </WorkspaceMain>
            ) : (
              <WorkspaceMain>
                <Panel tone="raised" className="w-full">
                  <Stack gap={14}>
                    <Row gap={14} align="start" wrap>
                      <EntityHotspot
                        kind={selected.isExotic ? "Exotic" : "Item"}
                        name={selected.name}
                        description={selected.description}
                        icon={selected.icon}
                        accentColor={accentFor(selected.element)}
                        size={64}
                        showLabel="never"
                        meta={[
                          selected.slot,
                          selected.element,
                          selected.itemTypeName,
                          selected.frame,
                        ].filter(Boolean) as string[]}
                      />
                      <Stack gap={6} className="min-w-0 flex-1">
                        <Heading level={1}>{selected.name}</Heading>
                        <Cluster>
                          {selected.isExotic ? (
                            <Chip accent>Exotic</Chip>
                          ) : null}
                          {selected.slot ? <Chip>{selected.slot}</Chip> : null}
                          {selected.element
                            ? (() => {
                                const v = visualForElement(selected.element);
                                return v ? (
                                  <MetaChip
                                    label={selected.element!}
                                    iconOnly
                                    accentColor={v.color}
                                    icon={
                                      <OfficialFilterIcon
                                        icon={v.icon}
                                        label={selected.element!}
                                        size={14}
                                      />
                                    }
                                  />
                                ) : (
                                  <Chip>{selected.element}</Chip>
                                );
                              })()
                            : null}
                          {selected.ammo
                            ? (() => {
                                const v = visualForAmmo(selected.ammo);
                                return v ? (
                                  <MetaChip
                                    label={selected.ammo!}
                                    iconOnly
                                    accentColor={v.color}
                                    icon={
                                      <OfficialFilterIcon
                                        icon={v.icon}
                                        label={selected.ammo!}
                                        size={14}
                                      />
                                    }
                                  />
                                ) : (
                                  <Chip>{selected.ammo}</Chip>
                                );
                              })()
                            : null}
                          {selected.itemTypeName ? (
                            <MetaChip
                              label={selected.itemTypeName}
                              icon={
                                <WeaponTypeIcon
                                  typeName={selected.itemTypeName}
                                  size={12}
                                />
                              }
                            />
                          ) : null}
                          {selected.frame
                            ? (() => {
                                const v = visualForWeaponFrame(selected.frame);
                                return v ? (
                                  <MetaChip
                                    label={selected.frame!}
                                    iconOnly
                                    icon={
                                      <OfficialFilterIcon
                                        icon={v.icon}
                                        label={selected.frame!}
                                        size={14}
                                      />
                                    }
                                  />
                                ) : (
                                  <Chip>{selected.frame}</Chip>
                                );
                              })()
                            : null}
                          {selected.classType ? (
                            <Chip
                              icon={
                                isGuardianClass(selected.classType) ? (
                                  <ClassIcon
                                    className={selected.classType}
                                    color={
                                      CLASS_CSS_COLOR[selected.classType]
                                    }
                                    size={12}
                                  />
                                ) : null
                              }
                            >
                              {selected.classType}
                            </Chip>
                          ) : null}
                        </Cluster>
                      </Stack>
                    </Row>

                    {selected.setBonusName ? (
                      <Section label="Armor set bonus">
                        <Text size="sm">{selected.setBonusName}</Text>
                      </Section>
                    ) : null}

                    {selected.description ? (
                      <Section label="Description">
                        <Text size="sm" className="leading-relaxed whitespace-pre-wrap">
                          {selected.description}
                        </Text>
                      </Section>
                    ) : null}

                    <Section label="Ownership">
                      <Text size="sm">
                        {selected.ownedCount > 0
                          ? `${selected.ownedCount} owned cop${selected.ownedCount === 1 ? "y" : "ies"}`
                          : "Not in synced inventory"}
                      </Text>
                    </Section>

                    {instances.length > 0 ? (
                      <Section label="Owned instances">
                        <Stack gap={10}>
                          {instances.map((inst) => (
                            <Panel key={inst.instanceId} tone="muted" pad="sm">
                              <Stack gap={8}>
                                <Row gap={8} wrap>
                                  <Text size="sm">
                                    {inst.power != null
                                      ? `Power ${inst.power}`
                                      : inst.instanceId}
                                  </Text>
                                  {inst.isMasterwork ? (
                                    <Chip accent>Masterwork</Chip>
                                  ) : null}
                                  {inst.location ? (
                                    <Text size="xs" tone="muted" as="span">
                                      {inst.location}
                                    </Text>
                                  ) : null}
                                </Row>
                                {kind === "weapons" ? (
                                  <InstancePerkGridView
                                    instanceId={inst.instanceId}
                                    enabled
                                    frameHint={selected.frame}
                                  />
                                ) : (inst.plugs?.length ?? 0) > 0 ? (
                                  <Cluster gap={6}>
                                    {inst.plugs!.map((p) => (
                                      <EntityHotspot
                                        key={`${inst.instanceId}-${p.hash ?? p.displayName}`}
                                        kind="Mod / plug"
                                        name={p.displayName}
                                        description={p.description}
                                        icon={p.icon}
                                        size={28}
                                        showLabel="auto"
                                      />
                                    ))}
                                  </Cluster>
                                ) : null}
                              </Stack>
                            </Panel>
                          ))}
                        </Stack>
                      </Section>
                    ) : null}

                    {linkedSynergies.length > 0 ? (
                      <Section label="Linked synergies">
                        <Cluster>
                          {linkedSynergies.map((s) => (
                            <Chip key={s.id} accent>
                              {s.name}
                            </Chip>
                          ))}
                        </Cluster>
                      </Section>
                    ) : null}
                  </Stack>
                </Panel>
              </WorkspaceMain>
            )
          }
        />
      </PageFrameBody>
    </PageFrame>
  );
}
