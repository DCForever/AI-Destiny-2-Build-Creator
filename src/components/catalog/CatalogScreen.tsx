"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { OwnedInstanceCard } from "@/components/catalog/OwnedInstanceCard";
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
  SlotIcon,
  Stack,
  Text,
  TextField,
  WeaponTypeIcon,
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
import {
  CATALOG_BACK_TO_RESULTS_CLASSES,
  EMBEDDED_CATALOG_CHROME_CLASSES,
  catalogBodyRootClasses,
  catalogDetailPaneClasses,
  catalogResultsPaneClasses,
} from "@/lib/ui/viewportLayout";
import type {
  CatalogChromeConfig,
  CatalogConstraints,
  CatalogKind,
  CatalogScope,
  CatalogSelectionConfig,
} from "@/components/catalog/catalogScreenTypes";

export type {
  CatalogChromeConfig,
  CatalogConstraints,
  CatalogKind,
  CatalogPickResult,
  CatalogScope,
  CatalogSelectionConfig,
} from "@/components/catalog/catalogScreenTypes";

type InstanceRow = {
  instanceId: string;
  power?: number;
  location?: string;
  isMasterwork?: boolean;
  tier?: string | number;
  statValues?: Partial<Record<string, number>>;
  totalStats?: number;
  statsIncomplete?: boolean;
  plugs?: {
    displayName: string;
    resolved: boolean;
    hash?: number;
    icon?: string | null;
    description?: string | null;
  }[];
};

/** Plugs that failed resolution show the numeric hash — never surface those. */
function isDisplayablePlug(p: {
  displayName: string;
  resolved?: boolean;
  hash?: number;
}): boolean {
  if (p.resolved === false) return false;
  const name = p.displayName?.trim() ?? "";
  if (!name) return false;
  if (/^\d+$/.test(name)) return false;
  if (p.hash != null && name === String(p.hash)) return false;
  return true;
}

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
 * Shared Catalog UI: free browse on /catalog, or constrained pick embed (Set fill).
 */
export function CatalogScreen({
  constraints,
  selection,
  chrome,
}: {
  constraints?: CatalogConstraints;
  selection?: CatalogSelectionConfig;
  chrome?: CatalogChromeConfig;
} = {}) {
  const lockKind = constraints?.lockKind === true;
  const lockSlot = constraints?.lockSlot === true;
  const pickMode = selection?.enabled === true;
  const embedded = chrome?.embedded === true;

  const [kind, setKind] = useState<CatalogKind>(
    () => constraints?.kind ?? "weapons",
  );
  const [scope, setScope] = useState<CatalogScope>(
    () => constraints?.scope ?? "owned",
  );
  const [query, setQuery] = useState("");
  const [slot, setSlot] = useState<string | null>(
    () => constraints?.slot ?? null,
  );
  const [className, setClassName] = useState<string | null>(null);
  const [onlyExotic, setOnlyExotic] = useState(
    () => constraints?.onlyExotic ?? false,
  );
  const [selectedInstanceId, setSelectedInstanceId] = useState<string | null>(
    null,
  );
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
  /** Secondary filter chips collapsed by default (esp. pick/embed) so body stays usable. */
  const [filtersExpanded, setFiltersExpanded] = useState(false);

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
      setSelectedInstanceId(null);
    }
  }, [items, selected]);

  // Keep locked constraints enforced if parent props change.
  useEffect(() => {
    if (lockKind && constraints?.kind) setKind(constraints.kind);
  }, [lockKind, constraints?.kind]);
  useEffect(() => {
    if (lockSlot) setSlot(constraints?.slot ?? null);
  }, [lockSlot, constraints?.slot]);

  const refreshBase = useCallback(() => {
    setSelected(null);
    setInstances([]);
    setLinkedSynergies([]);
    setSelectedInstanceId(null);
    void loadBase();
  }, [loadBase]);

  const selectItem = useCallback(
    async (item: CatalogItem) => {
      setSelected(item);
      setInstances([]);
      setLinkedSynergies([]);
      setSelectedInstanceId(null);

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
        if (res.ok) {
          setInstances(
            (body.instances ?? []).map((row) => ({
              ...row,
              plugs: (row.plugs ?? []).filter(isDisplayablePlug),
            })),
          );
        } else if (body.message) setSyncMessage(body.message);
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
    (slot && !lockSlot ? 1 : 0) +
    (className ? 1 : 0) +
    (onlyExotic && !constraints?.onlyExotic ? 1 : 0);

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
    if (!lockSlot) setSlot(null);
    setClassName(null);
    setGroupDims([]);
    setSynergyQuery("");
    if (!constraints?.onlyExotic) setOnlyExotic(false);
  }

  function confirmPick(instanceId?: string | null) {
    if (!selection?.enabled || !selected) return;
    selection.onConfirm({
      hash: selected.hash,
      name: selected.name,
      slot: selected.slot ?? slot ?? undefined,
      ownedCount: selected.ownedCount,
      instanceId: instanceId ?? null,
      item: selected,
    });
  }

  const title =
    chrome?.title ?? "Catalog";
  const description =
    chrome?.description ??
    "Browse weapons and armor from the manifest or your owned inventory.";

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
                {item.slot ? (
                  <Chip icon={<SlotIcon slot={item.slot} size={12} />}>
                    {item.slot}
                  </Chip>
                ) : null}
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

  const chromeBlock = (
        <Stack gap={12}>
          <PageHeader
            title={title}
            description={description}
            actions={
              pickMode && selection?.onCancel ? (
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={selection.busy}
                  onClick={() => selection.onCancel?.()}
                >
                  Close
                </Button>
              ) : undefined
            }
          />
          {error ? <Callout tone="danger">{error}</Callout> : null}
          {syncMessage ? <Callout tone="warning">{syncMessage}</Callout> : null}

          <Panel tone="muted" pad="sm">
          <Stack gap={6}>
            {/* Browse + scope */}
            <Cluster gap={4}>
              {!lockKind ? (
                <>
                  <FilterChip
                    size="xs"
                    label="Weapons"
                    active={kind === "weapons"}
                    onClick={() => {
                      setKind("weapons");
                      if (!lockSlot) setSlot(null);
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
                      if (!lockSlot) setSlot(null);
                      setGroupDims([]);
                      setElements([]);
                      setAmmos([]);
                      setArchetypes([]);
                    }}
                  />
                </>
              ) : (
                <Chip accent>
                  {kind === "weapons" ? "Weapons" : "Armor"}
                </Chip>
              )}
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
                onClick={() => {
                  if (constraints?.onlyExotic) return;
                  setOnlyExotic((v) => !v);
                }}
              />
              {lockSlot && slot ? (
                <Chip icon={<SlotIcon slot={slot} size={12} />}>
                  Slot · {slot}
                </Chip>
              ) : null}
            </Cluster>

            {/* Search · Synergy (side-by-side from ~sm) + actions */}
            <div className="flex flex-wrap items-end gap-2 sm:gap-3">
              <TextField
                label="Search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") refreshBase();
                }}
                placeholder="Name, frame, perk…"
                className="w-full max-w-[14rem] min-[420px]:w-[11rem] sm:w-[12rem] md:w-[13rem] shrink-0"
              />
              {synergiesSignedIn && librarySynergies.length > 0 ? (
                <TextField
                  label={`Synergy${synergyIds.length ? ` · ${synergyIds.length}` : ""}`}
                  value={synergyQuery}
                  onChange={(e) => setSynergyQuery(e.target.value)}
                  placeholder="e.g. tangle, melee"
                  className="w-full max-w-[14rem] min-[420px]:w-[11rem] sm:w-[12rem] md:w-[13rem] shrink-0"
                />
              ) : null}
              <div className="flex flex-wrap items-center gap-2 pb-0.5">
                <Button
                  size="sm"
                  variant="accent"
                  disabled={loading}
                  onClick={() => refreshBase()}
                >
                  {loading ? "…" : "Refresh"}
                </Button>
                <Button
                  size="sm"
                  variant={filtersExpanded ? "accent" : "ghost"}
                  onClick={() => setFiltersExpanded((v) => !v)}
                >
                  {filtersExpanded ? "▾ Filters" : "▸ Filters"}
                  {multiFilterCount > 0 ? ` · ${multiFilterCount}` : ""}
                </Button>
                {multiFilterCount > 0 ? (
                  <Button size="sm" variant="ghost" onClick={clearMultiFilters}>
                    Clear
                  </Button>
                ) : null}
              </div>
            </div>
            {synergiesSignedIn &&
            librarySynergies.length > 0 &&
            (synergyIds.length > 0 ||
              synergyQuery.trim() ||
              filtersExpanded) ? (
              <Stack gap={3}>
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
                {synergyQuery.trim() ||
                (filtersExpanded && synergyPickerOptions.length <= 8) ? (
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
                    {synergyQuery.trim() &&
                    synergyPickerOptions.length === 0 ? (
                      <Text size="xs" tone="muted">
                        No matches
                      </Text>
                    ) : null}
                  </Cluster>
                ) : filtersExpanded ? (
                  <Text size="xs" tone="muted">
                    Type to search {librarySynergies.length} synergies
                  </Text>
                ) : null}
              </Stack>
            ) : null}

            {/* Secondary filters — collapsed by default so body keeps height */}
            {filtersExpanded ? (
            <Row gap={8} align="center" wrap className="gap-y-2">
              {!lockSlot ? (
                <Cluster gap={3}>
                  {slotOptions.map((s) => (
                    <FilterChip
                      key={s}
                      size="xs"
                      label={s}
                      icon={
                        kind === "armor" ? (
                          <SlotIcon slot={s} size={12} />
                        ) : null
                      }
                      active={slot === s}
                      onClick={() =>
                        setSlot((prev) => (prev === s ? null : s))
                      }
                    />
                  ))}
                </Cluster>
              ) : null}
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
            ) : null}

            {filtersExpanded ? (
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
            ) : null}
            {filtersExpanded && moreFiltersOpen ? (
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
  );

  const hasSelection = selected != null;

  const resultsPane = (
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
              <div className="flex-1 min-h-0 overflow-y-auto mt-3 overscroll-contain">
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
  );

  const detailPane = selected ? (
              <WorkspaceMain>
                <div className={CATALOG_BACK_TO_RESULTS_CLASSES}>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setSelected(null);
                      setInstances([]);
                      setLinkedSynergies([]);
                      setSelectedInstanceId(null);
                    }}
                  >
                    ← Results
                  </Button>
                </div>
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
                          {selected.slot ? (
                            <Chip
                              icon={
                                <SlotIcon slot={selected.slot} size={12} />
                              }
                            >
                              {selected.slot}
                            </Chip>
                          ) : null}
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
                        <Stack gap={8}>
                          <EntityHotspot
                            kind="Armor set"
                            name={selected.setBonusName}
                            description="Armor 3.0 equipable set bonus (definition-level)."
                            icon={selected.setBonusIcon ?? null}
                            size={36}
                            showLabel="always"
                          />
                          {(selected.setBonusPerks?.length ?? 0) > 0 ? (
                            <Stack gap={4}>
                              {selected.setBonusPerks!.map((tier) => (
                                <Text
                                  key={`set-perk-${tier.requiredCount}-${tier.name}`}
                                  size="xs"
                                  className="leading-snug"
                                >
                                  <span className="text-accent">
                                    {tier.requiredCount}pc
                                  </span>
                                  {tier.name ? ` · ${tier.name}` : ""}
                                  {tier.description
                                    ? ` — ${tier.description}`
                                    : ""}
                                </Text>
                              ))}
                            </Stack>
                          ) : null}
                        </Stack>
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

                    {pickMode && selected ? (
                      <Section label="Fill slot">
                        <Stack gap={8}>
                          <Row gap={8} wrap>
                            <Button
                              size="sm"
                              variant="accent"
                              disabled={selection?.busy}
                              onClick={() =>
                                confirmPick(selectedInstanceId)
                              }
                            >
                              {selection?.busy
                                ? "Saving…"
                                : (selection?.confirmLabel ??
                                  (selectedInstanceId
                                    ? "Use selected copy"
                                    : "Use item"))}
                            </Button>
                            {selectedInstanceId ? (
                              <Button
                                size="sm"
                                variant="outline"
                                disabled={selection?.busy}
                                onClick={() => confirmPick(null)}
                              >
                                Use definition only
                              </Button>
                            ) : null}
                          </Row>
                          <Text size="xs" tone="muted">
                            {selectedInstanceId
                              ? "Confirm uses the selected owned copy."
                              : "Optional: pick an owned copy below, or use the item definition."}
                          </Text>
                        </Stack>
                      </Section>
                    ) : null}

                    {instances.length > 0 ? (
                      <Section
                        label={`Owned copies · ${instances.length}`}
                      >
                        <div
                          className={
                            kind === "armor"
                              ? "grid gap-2 grid-cols-1 min-[360px]:grid-cols-2 xl:grid-cols-3"
                              : "grid gap-2 grid-cols-1 xl:grid-cols-2"
                          }
                        >
                          {instances.map((inst) => (
                            <OwnedInstanceCard
                              key={inst.instanceId}
                              kind={kind}
                              instance={inst}
                              frameHint={selected.frame}
                              pickMode={pickMode}
                              pickBusy={selection?.busy}
                              selected={
                                pickMode &&
                                selectedInstanceId === inst.instanceId
                              }
                              onToggleSelect={() =>
                                setSelectedInstanceId((prev) =>
                                  prev === inst.instanceId
                                    ? null
                                    : inst.instanceId,
                                )
                              }
                              onUse={() => confirmPick(inst.instanceId)}
                            />
                          ))}
                        </div>
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
  ) : null;

  const body = (
    <div className={catalogBodyRootClasses(hasSelection)}>
      <div className={catalogResultsPaneClasses(hasSelection)}>
        {resultsPane}
      </div>
      {hasSelection && detailPane ? (
        <div className={catalogDetailPaneClasses()}>{detailPane}</div>
      ) : null}
    </div>
  );

  if (embedded) {
    // Parent must be a height-locked flex child (Sets fill pane). Chrome
    // height-capped on small screens; dual-pane body scrolls rail/detail.
    return (
      <div className="h-full min-h-0 flex flex-col overflow-hidden w-full">
        <div className={EMBEDDED_CATALOG_CHROME_CLASSES}>{chromeBlock}</div>
        <div className="flex-1 min-h-0 overflow-hidden basis-0">{body}</div>
      </div>
    );
  }

  return (
    <PageFrame>
      <PageFrameChrome>{chromeBlock}</PageFrameChrome>
      <PageFrameBody>{body}</PageFrameBody>
    </PageFrame>
  );
}
