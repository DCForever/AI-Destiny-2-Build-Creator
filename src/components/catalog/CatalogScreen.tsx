"use client";

import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";

import { OwnedInstanceCard } from "@/components/catalog/OwnedInstanceCard";
import { UniversalSearchPanel } from "@/components/catalog/UniversalSearchPanel";
import {
  cycleFacetValue,
  emptyFacet,
  facetActiveCount,
  facetChipState,
  filterCatalogClient,
  type FacetFilter,
} from "@/lib/catalog/filterCatalogClient";
import {
  CATALOG_AMMO_TYPES,
  CATALOG_ARMOR_ARCHETYPES,
  CATALOG_ELEMENTS,
  CATALOG_WEAPON_ARCHETYPES,
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
  AmmoTypeIcon,
  Button,
  Callout,
  Chip,
  ClassFilterChip,
  ClassIcon,
  Cluster,
  DesignationLabel,
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
  type GuardianClassName,
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
  CatalogBrowseMode,
  CatalogChromeConfig,
  CatalogConstraints,
  CatalogKind,
  CatalogScope,
  CatalogSelectionConfig,
} from "@/components/catalog/catalogScreenTypes";

export type {
  CatalogBrowseMode,
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

  const [browseMode, setBrowseMode] = useState<CatalogBrowseMode>(() =>
    constraints?.kind ?? "weapons",
  );
  const kind: CatalogKind =
    browseMode === "universal" ? "weapons" : browseMode;
  const isUniversal = browseMode === "universal" && !lockKind;

  const setKind = useCallback(
    (next: CatalogKind) => {
      setBrowseMode(next);
    },
    [],
  );
  const [scope, setScope] = useState<CatalogScope>(
    () => constraints?.scope ?? "owned",
  );
  const [query, setQuery] = useState("");
  /** Locked slot from constraints; free multi-slot uses slotsFacet. */
  const lockedSlot = lockSlot ? (constraints?.slot ?? null) : null;
  const [selectedInstanceId, setSelectedInstanceId] = useState<string | null>(
    null,
  );
  /** Multi group-by dimensions (order of activation = key order). */
  const [groupDims, setGroupDims] = useState<CatalogGroupDimension[]>([]);
  /** Multi-value facets: include OR / exclude drop (cycle chips). */
  const [elements, setElements] = useState<FacetFilter>(() => emptyFacet());
  const [ammos, setAmmos] = useState<FacetFilter>(() => emptyFacet());
  const [archetypes, setArchetypes] = useState<FacetFilter>(() => emptyFacet());
  const [classNames, setClassNames] = useState<FacetFilter>(() => emptyFacet());
  const [slotsFacet, setSlotsFacet] = useState<FacetFilter>(() =>
    lockSlot && constraints?.slot
      ? { include: [constraints.slot], exclude: [] }
      : emptyFacet(),
  );
  const [librarySynergies, setLibrarySynergies] = useState<
    Array<{ id: string; name: string; type: string; subType: string | null }>
  >([]);
  const [synergies, setSynergies] = useState<FacetFilter>(() => emptyFacet());
  const [synergyHashInclude, setSynergyHashInclude] = useState<number[]>([]);
  const [synergyHashExclude, setSynergyHashExclude] = useState<number[]>([]);
  const [synergiesSignedIn, setSynergiesSignedIn] = useState(false);
  const [synergyQuery, setSynergyQuery] = useState("");
  /** Full filter chrome (search + facets). Collapsed = single summary row. */
  const [filtersOpen, setFiltersOpen] = useState(false);
  /** Weapon type + group-by section inside expanded filters. */
  const [moreFiltersOpen, setMoreFiltersOpen] = useState(true);
  /** null = no constraint; true = exotic only; false = exclude exotic */
  const exoticFilterLocked =
    constraints?.onlyExotic === true || constraints?.excludeExotic === true;
  const [exotic, setExotic] = useState<boolean | null>(() =>
    constraints?.onlyExotic
      ? true
      : constraints?.excludeExotic
        ? false
        : null,
  );
  const synergyAvailable =
    synergiesSignedIn && librarySynergies.length > 0;

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

  async function fetchCatalogHashesForSynergy(
    synergyId: string,
    signal?: AbortSignal,
  ): Promise<number[]> {
    const params = new URLSearchParams({
      scope,
      includeInstancePointer: "1",
      limit: "500",
      synergyId,
    });
    const res = await fetch(`/api/catalog/${kind}?${params}`, { signal });
    if (!res.ok) return [];
    const body = (await res.json()) as { items?: CatalogItem[] };
    return (body.items ?? []).map((i) => i.hash);
  }

  /** Base catalog fill: kind / scope; synergy include/exclude via server and/or hash sets. */
  const loadBase = useCallback(
    async (signal?: AbortSignal) => {
      setLoading(true);
      setError(null);
      setSyncMessage(null);
      try {
        const hasSynInclude = synergies.include.length > 0;
        const hasSynExclude = synergies.exclude.length > 0;
        // Include-only: server allowlist. Any exclude (or mix): broad fetch + client hash sets.
        const params = new URLSearchParams({
          scope,
          includeInstancePointer: "1",
          limit: "500",
        });
        // Slot-locked embeds (set fill): server-side slot filter so results
        // appear without typing a search query.
        if (lockSlot && lockedSlot) {
          params.set("slot", lockedSlot);
        }
        if (hasSynInclude && !hasSynExclude) {
          for (const id of synergies.include) {
            params.append("synergyId", id);
          }
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
          setSynergyHashInclude([]);
          setSynergyHashExclude([]);
          return;
        }

        // Resolve hash sets before committing baseItems so filters never flash open.
        let nextInclude: number[] = [];
        let nextExclude: number[] = [];
        if (hasSynInclude && hasSynExclude) {
          const includeSets = await Promise.all(
            synergies.include.map((id) =>
              fetchCatalogHashesForSynergy(id, signal),
            ),
          );
          if (signal?.aborted) return;
          nextInclude = [...new Set(includeSets.flat())];
        }
        if (hasSynExclude) {
          const excludeSets = await Promise.all(
            synergies.exclude.map((id) =>
              fetchCatalogHashesForSynergy(id, signal),
            ),
          );
          if (signal?.aborted) return;
          nextExclude = [...new Set(excludeSets.flat())];
        }

        setBaseItems(sortByName(body.items ?? []));
        setSynergyHashInclude(nextInclude);
        setSynergyHashExclude(nextExclude);
        if (body.message) setSyncMessage(body.message);
      } catch (e) {
        if (e instanceof DOMException && e.name === "AbortError") return;
        setError("Catalog load failed");
        setBaseItems([]);
        setSynergyHashInclude([]);
        setSynergyHashExclude([]);
      } finally {
        if (!signal?.aborted) setLoading(false);
      }
    },
    [kind, scope, synergies.include, synergies.exclude, lockSlot, lockedSlot],
  );

  useEffect(() => {
    if (isUniversal) return;
    const ac = new AbortController();
    void loadBase(ac.signal);
    return () => ac.abort();
  }, [loadBase, isUniversal]);

  /** Live client filter on base set (instant chip / text updates). */
  const items = useMemo(
    () =>
      filterCatalogClient(baseItems, {
        query: debouncedQuery,
        slots: lockSlot && lockedSlot
          ? { include: [lockedSlot], exclude: [] }
          : slotsFacet,
        elements,
        ammos,
        archetypes,
        classNames,
        exotic,
        itemHashesInclude:
          synergies.include.length > 0 && synergies.exclude.length > 0
            ? synergyHashInclude
            : undefined,
        itemHashesExclude:
          synergies.exclude.length > 0 ? synergyHashExclude : undefined,
      }),
    [
      baseItems,
      debouncedQuery,
      lockSlot,
      lockedSlot,
      slotsFacet,
      elements,
      ammos,
      archetypes,
      classNames,
      exotic,
      synergies.include.length,
      synergies.exclude.length,
      synergyHashInclude,
      synergyHashExclude,
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
    if (lockKind && constraints?.kind) setBrowseMode(constraints.kind);
  }, [lockKind, constraints?.kind]);
  useEffect(() => {
    if (lockSlot && constraints?.slot) {
      setSlotsFacet({ include: [constraints.slot], exclude: [] });
    }
  }, [lockSlot, constraints?.slot]);
  useEffect(() => {
    if (constraints?.onlyExotic) setExotic(true);
    else if (constraints?.excludeExotic) setExotic(false);
  }, [constraints?.onlyExotic, constraints?.excludeExotic]);

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

  const synergyBusyIds = useMemo(
    () => new Set([...synergies.include, ...synergies.exclude]),
    [synergies.include, synergies.exclude],
  );

  const synergyPickerOptions = useMemo(() => {
    const q = synergyQuery.trim().toLowerCase();
    return librarySynergies
      .filter((s) => !synergyBusyIds.has(s.id))
      .map((s) => ({
        id: s.id,
        label:
          synergyLabelById.get(s.id) ??
          formatSynergyTypeDesignation({ type: s.type, subType: s.subType }),
      }))
      .filter((o) => !q || o.label.toLowerCase().includes(q))
      .slice(0, 12);
  }, [librarySynergies, synergyBusyIds, synergyQuery, synergyLabelById]);

  const multiFilterCount =
    facetActiveCount(elements) +
    facetActiveCount(ammos) +
    facetActiveCount(archetypes) +
    facetActiveCount(synergies) +
    facetActiveCount(classNames) +
    (lockSlot ? 0 : facetActiveCount(slotsFacet)) +
    groupDims.length +
    (exotic != null && !exoticFilterLocked ? 1 : 0) +
    (debouncedQuery.trim() ? 1 : 0);

  function toggleGroupDim(dim: CatalogGroupDimension) {
    setGroupDims((prev) => {
      if (prev.includes(dim)) return prev.filter((d) => d !== dim);
      return [...prev, dim];
    });
  }

  function clearMultiFilters() {
    setElements(emptyFacet());
    setAmmos(emptyFacet());
    setArchetypes(emptyFacet());
    setSynergies(emptyFacet());
    setSynergyHashInclude([]);
    setSynergyHashExclude([]);
    if (!lockSlot) setSlotsFacet(emptyFacet());
    setClassNames(emptyFacet());
    setGroupDims([]);
    setSynergyQuery("");
    setQuery("");
    if (!exoticFilterLocked) setExotic(null);
  }

  function cycleExotic() {
    if (exoticFilterLocked) return;
    setExotic((prev) => {
      if (prev === null) return true;
      if (prev === true) return false;
      return null;
    });
  }

  /** Compact applied-filter chips for the collapsed single-row summary. */
  type AppliedSummaryChip = {
    key: string;
    label: string;
    mode: "include" | "exclude";
    icon?: ReactNode;
    iconOnly?: boolean;
    activeStyle?: CSSProperties;
    onClick: () => void;
  };

  function asAppliedMode(
    mode: ReturnType<typeof facetChipState>,
  ): "include" | "exclude" {
    return mode === "exclude" ? "exclude" : "include";
  }

  const appliedSummaryChips = useMemo((): AppliedSummaryChip[] => {
    const chips: AppliedSummaryChip[] = [];

    if (debouncedQuery.trim()) {
      const q = debouncedQuery.trim();
      chips.push({
        key: "query",
        label: q.length > 18 ? `${q.slice(0, 16)}…` : q,
        mode: "include",
        onClick: () => setQuery(""),
      });
    }

    if (exotic != null && !exoticFilterLocked) {
      chips.push({
        key: "exotic",
        label: exotic ? "Exotic only" : "No exotic",
        mode: exotic ? "include" : "exclude",
        onClick: () => {
          setExotic((prev) => {
            if (prev === null) return true;
            if (prev === true) return false;
            return null;
          });
        },
      });
    }

    if (!lockSlot) {
      for (const s of [...slotsFacet.include, ...slotsFacet.exclude]) {
        chips.push({
          key: `slot-${s}`,
          label: s,
          mode: asAppliedMode(facetChipState(slotsFacet, s)),
          icon:
            kind === "armor" ? <SlotIcon slot={s} size={12} /> : undefined,
          onClick: () =>
            setSlotsFacet((prev) => cycleFacetValue(prev, s)),
        });
      }
    }

    for (const c of [...classNames.include, ...classNames.exclude]) {
      const color = CLASS_CSS_COLOR[c as GuardianClassName];
      chips.push({
        key: `class-${c}`,
        label: c,
        mode: asAppliedMode(facetChipState(classNames, c)),
        iconOnly: true,
        icon: (
          <ClassIcon
            className={c as GuardianClassName}
            color={color}
            size={14}
          />
        ),
        activeStyle: {
          borderColor: color,
          boxShadow: `0 0 0 1px ${color}`,
          backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
        },
        onClick: () =>
          setClassNames((prev) => cycleFacetValue(prev, c)),
      });
    }

    for (const el of [...elements.include, ...elements.exclude]) {
      const visual = ELEMENT_OFFICIAL[el as DestinyElement];
      const color =
        visual?.color ?? ELEMENT_CSS_COLOR[el as DestinyElement];
      chips.push({
        key: `el-${el}`,
        label: el,
        mode: asAppliedMode(facetChipState(elements, el)),
        iconOnly: true,
        icon: visual ? (
          <OfficialFilterIcon icon={visual.icon} label={el} size={14} />
        ) : undefined,
        activeStyle: {
          borderColor: color,
          boxShadow: `0 0 0 1px ${color}`,
          backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
        },
        onClick: () => setElements((prev) => cycleFacetValue(prev, el)),
      });
    }

    for (const a of [...ammos.include, ...ammos.exclude]) {
      const visual = AMMO_OFFICIAL[a as keyof typeof AMMO_OFFICIAL];
      chips.push({
        key: `ammo-${a}`,
        label: a,
        mode: asAppliedMode(facetChipState(ammos, a)),
        iconOnly: true,
        icon: <AmmoTypeIcon ammo={a} size={14} />,
        activeStyle: visual
          ? {
              borderColor: visual.color,
              color: visual.color,
              boxShadow: `0 0 0 1px ${visual.color}`,
              backgroundColor: `color-mix(in srgb, ${visual.color} 14%, transparent)`,
            }
          : undefined,
        onClick: () => setAmmos((prev) => cycleFacetValue(prev, a)),
      });
    }

    for (const t of [...archetypes.include, ...archetypes.exclude]) {
      const armorVisual = visualForArmorArchetype(t);
      chips.push({
        key: `arch-${t}`,
        label: t,
        mode: asAppliedMode(facetChipState(archetypes, t)),
        iconOnly: true,
        icon:
          kind === "weapons" ? (
            <WeaponTypeIcon typeName={t} size={14} />
          ) : armorVisual ? (
            <OfficialFilterIcon
              icon={armorVisual.icon}
              label={t}
              size={14}
            />
          ) : undefined,
        activeStyle:
          kind === "armor" && armorVisual
            ? officialActiveStyle(armorVisual)
            : undefined,
        onClick: () =>
          setArchetypes((prev) => cycleFacetValue(prev, t)),
      });
    }

    for (const id of [...synergies.include, ...synergies.exclude]) {
      const s = librarySynergies.find((x) => x.id === id);
      const label =
        synergyLabelById.get(id) ??
        (s
          ? formatSynergyTypeDesignation({
              type: s.type,
              subType: s.subType,
            })
          : id);
      chips.push({
        key: `syn-${id}`,
        label,
        mode: asAppliedMode(facetChipState(synergies, id)),
        iconOnly: Boolean(s),
        icon: s ? (
          <DesignationLabel
            type={s.type}
            subType={s.subType}
            size={14}
            iconOnly
          />
        ) : undefined,
        onClick: () =>
          setSynergies((prev) => cycleFacetValue(prev, id)),
      });
    }

    for (const d of groupDims) {
      const label =
        groupDimOptions.find((o) => o.id === d)?.label ?? d;
      chips.push({
        key: `group-${d}`,
        label: `Group · ${label}`,
        mode: "include",
        onClick: () => {
          setGroupDims((prev) => {
            if (prev.includes(d)) return prev.filter((x) => x !== d);
            return [...prev, d];
          });
        },
      });
    }

    return chips;
  }, [
    debouncedQuery,
    exotic,
    exoticFilterLocked,
    lockSlot,
    slotsFacet,
    classNames,
    elements,
    ammos,
    archetypes,
    synergies,
    librarySynergies,
    synergyLabelById,
    groupDims,
    kind,
    groupDimOptions,
  ]);

  function confirmPick(instanceId?: string | null) {
    if (!selection?.enabled || !selected) return;
    selection.onConfirm({
      hash: selected.hash,
      name: selected.name,
      slot: selected.slot ?? lockedSlot ?? undefined,
      ownedCount: selected.ownedCount,
      instanceId: instanceId ?? null,
      item: selected,
    });
  }

  const title =
    chrome?.title ?? "Catalog";
  const description =
    chrome?.description ??
    (isUniversal
      ? "Search composition entities across weapons, armor, mods, perks, and more."
      : "Browse weapons and armor from the manifest or your owned inventory.");

  /** R2 compact result card — no description; meta is icon-dense. */
  function renderResultCard(item: CatalogItem) {
    const active = selected?.hash === item.hash;
    const elementVisual = item.element
      ? visualForElement(item.element)
      : null;
    const ammoVisual = item.ammo ? visualForAmmo(item.ammo) : null;
    const frameVisual = item.frame
      ? visualForWeaponFrame(item.frame)
      : null;

    return (
      <button
        key={item.hash}
        type="button"
        className="text-left w-full min-w-0 h-full"
        title={item.name}
        onClick={() => void selectItem(item)}
      >
        <Panel
          tone={active ? "accent" : "muted"}
          pad="sm"
          className={`h-full ${
            active ? "" : "hover:border-line-strong transition-colors"
          }`}
        >
          <Row gap={8} align="start">
            <ItemIcon icon={item.icon} name={item.name} size={36} />
            <Stack gap={3} className="min-w-0 flex-1">
              <Text size="sm" weight="medium" className="truncate">
                {item.name}
              </Text>
              <Row gap={4} wrap className="items-center">
                {item.isExotic ? <Chip accent>Ex</Chip> : null}
                {item.slot ? (
                  <MetaChip
                    label={item.slot}
                    iconOnly
                    icon={<SlotIcon slot={item.slot} size={12} />}
                  />
                ) : null}
                {elementVisual ? (
                  <MetaChip
                    label={item.element!}
                    iconOnly
                    accentColor={elementVisual.color}
                    icon={
                      <OfficialFilterIcon
                        icon={elementVisual.icon}
                        label={item.element!}
                        size={12}
                      />
                    }
                  />
                ) : item.element ? (
                  <Chip>{item.element}</Chip>
                ) : null}
                {item.ammo ? (
                  <MetaChip
                    label={item.ammo}
                    iconOnly
                    accentColor={ammoVisual?.color}
                    icon={
                      <span
                        style={
                          ammoVisual?.color
                            ? { color: ammoVisual.color }
                            : undefined
                        }
                      >
                        <AmmoTypeIcon ammo={item.ammo} size={12} />
                      </span>
                    }
                  />
                ) : null}
                {frameVisual ? (
                  <MetaChip
                    label={item.frame!}
                    iconOnly
                    icon={
                      <OfficialFilterIcon
                        icon={frameVisual.icon}
                        label={item.frame!}
                        size={12}
                      />
                    }
                  />
                ) : item.itemTypeName ? (
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
            {/* Single row when collapsed: browse + Filters toggle + applied summary */}
            <div className="flex flex-wrap items-center gap-2">
              <Cluster gap={4} className="min-w-0">
                {!lockKind ? (
                  <>
                    <FilterChip
                      size="xs"
                      label="Weapons"
                      active={browseMode === "weapons"}
                      onClick={() => {
                        setKind("weapons");
                        if (!lockSlot) setSlotsFacet(emptyFacet());
                        setClassNames(emptyFacet());
                        setGroupDims([]);
                        setElements(emptyFacet());
                        setAmmos(emptyFacet());
                        setArchetypes(emptyFacet());
                      }}
                    />
                    <FilterChip
                      size="xs"
                      label="Armor"
                      active={browseMode === "armor"}
                      onClick={() => {
                        setKind("armor");
                        if (!lockSlot) setSlotsFacet(emptyFacet());
                        setGroupDims([]);
                        setElements(emptyFacet());
                        setAmmos(emptyFacet());
                        setArchetypes(emptyFacet());
                      }}
                    />
                    <FilterChip
                      size="xs"
                      label="Universal"
                      active={browseMode === "universal"}
                      onClick={() => setBrowseMode("universal")}
                    />
                  </>
                ) : (
                  <Chip accent>
                    {kind === "weapons" ? "Weapons" : "Armor"}
                  </Chip>
                )}
                {!isUniversal ? (
                  <>
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
                  </>
                ) : null}
                {!isUniversal && filtersOpen ? (
                  <FilterChip
                    size="xs"
                    label={
                      exotic === false
                        ? "No exotic"
                        : exotic === true
                          ? "Exotic only"
                          : "Exotic"
                    }
                    active={exotic != null}
                    mode={
                      exotic === true
                        ? "include"
                        : exotic === false
                          ? "exclude"
                          : "off"
                    }
                    onClick={cycleExotic}
                  />
                ) : null}
                {lockSlot && lockedSlot ? (
                  <Chip icon={<SlotIcon slot={lockedSlot} size={12} />}>
                    Slot · {lockedSlot}
                  </Chip>
                ) : null}
              </Cluster>

              {!isUniversal ? (
              <Button
                size="sm"
                variant={filtersOpen ? "accent" : "ghost"}
                onClick={() => setFiltersOpen((v) => !v)}
              >
                {filtersOpen ? "▾ Filters" : "▸ Filters"}
                {multiFilterCount > 0 ? ` · ${multiFilterCount}` : ""}
              </Button>
              ) : null}

              {!isUniversal && !filtersOpen && appliedSummaryChips.length > 0 ? (
                <Cluster gap={3} className="min-w-0 flex-1">
                  {appliedSummaryChips.map((chip) => (
                    <FilterChip
                      key={chip.key}
                      size="xs"
                      label={chip.label}
                      active
                      mode={chip.mode}
                      icon={chip.icon}
                      iconOnly={chip.iconOnly}
                      activeStyle={chip.activeStyle}
                      onClick={chip.onClick}
                    />
                  ))}
                </Cluster>
              ) : null}

              {!isUniversal ? (
              <div className="flex flex-wrap items-center gap-2 shrink-0 ml-auto">
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
                    Clear · {multiFilterCount}
                  </Button>
                ) : null}
              </div>
              ) : null}
            </div>

            {/* Expanded: S5 grid — Search | Synergy | facets */}
            {!isUniversal && filtersOpen ? (
            <div
              className={
                synergyAvailable
                  ? "grid grid-cols-1 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_minmax(10rem,1.1fr)] gap-2 sm:gap-3 items-start"
                  : "grid grid-cols-1 sm:grid-cols-[minmax(0,1fr)_minmax(10rem,1.1fr)] gap-2 sm:gap-3 items-start"
              }
            >
              <TextField
                label="Search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") refreshBase();
                }}
                placeholder="Name, frame, perk…"
                className="min-w-0 w-full"
              />
              {synergyAvailable ? (
                <TextField
                  label={`Synergy${
                    facetActiveCount(synergies)
                      ? ` · ${facetActiveCount(synergies)}`
                      : ""
                  }`}
                  value={synergyQuery}
                  onChange={(e) => setSynergyQuery(e.target.value)}
                  placeholder="e.g. tangle, melee"
                  className="min-w-0 w-full"
                />
              ) : null}

              <Stack gap={4} className="min-w-0">
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
                        active={facetChipState(slotsFacet, s) !== "off"}
                        mode={facetChipState(slotsFacet, s)}
                        onClick={() =>
                          setSlotsFacet((prev) => cycleFacetValue(prev, s))
                        }
                      />
                    ))}
                  </Cluster>
                ) : null}
                {kind === "armor" ? (
                  <Cluster gap={3}>
                    {CLASSES.map((c) => {
                      const mode = facetChipState(classNames, c);
                      return (
                        <ClassFilterChip
                          key={c}
                          className={c as GuardianClassName}
                          active={mode !== "off"}
                          mode={mode}
                          onClick={() =>
                            setClassNames((prev) => cycleFacetValue(prev, c))
                          }
                        />
                      );
                    })}
                  </Cluster>
                ) : null}
                {kind === "weapons" ? (
                  <>
                    <Cluster gap={3}>
                      {CATALOG_ELEMENTS.map((el) => {
                        const visual = ELEMENT_OFFICIAL[el as DestinyElement];
                        const color =
                          visual?.color ??
                          ELEMENT_CSS_COLOR[el as DestinyElement];
                        const mode = facetChipState(elements, el);
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
                            active={mode !== "off"}
                            mode={mode}
                            activeStyle={{
                              borderColor: color,
                              boxShadow: `0 0 0 1px ${color}`,
                              backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
                            }}
                            onClick={() =>
                              setElements((prev) => cycleFacetValue(prev, el))
                            }
                          />
                        );
                      })}
                    </Cluster>
                    <Cluster gap={3}>
                      {CATALOG_AMMO_TYPES.map((a) => {
                        const visual = AMMO_OFFICIAL[a];
                        const mode = facetChipState(ammos, a);
                        return (
                          <FilterChip
                            key={a}
                            size="xs"
                            label={a}
                            iconOnly
                            icon={<AmmoTypeIcon ammo={a} size={16} />}
                            active={mode !== "off"}
                            mode={mode}
                            activeStyle={{
                              borderColor: visual.color,
                              color: visual.color,
                              boxShadow: `0 0 0 1px ${visual.color}`,
                              backgroundColor: `color-mix(in srgb, ${visual.color} 14%, transparent)`,
                            }}
                            onClick={() =>
                              setAmmos((prev) => cycleFacetValue(prev, a))
                            }
                          />
                        );
                      })}
                    </Cluster>
                  </>
                ) : null}

                {synergyAvailable && facetActiveCount(synergies) > 0 ? (
                  <Cluster gap={3}>
                    {[...synergies.include, ...synergies.exclude].map((id) => {
                      const s = librarySynergies.find((x) => x.id === id);
                      const mode = facetChipState(synergies, id);
                      const label =
                        synergyLabelById.get(id) ??
                        (s
                          ? formatSynergyTypeDesignation({
                              type: s.type,
                              subType: s.subType,
                            })
                          : id);
                      return (
                        <FilterChip
                          key={id}
                          size="xs"
                          label={label}
                          active={mode !== "off"}
                          mode={mode}
                          iconOnly={Boolean(s)}
                          icon={
                            s ? (
                              <DesignationLabel
                                type={s.type}
                                subType={s.subType}
                                size={14}
                                iconOnly
                              />
                            ) : null
                          }
                          onClick={() =>
                            setSynergies((prev) => cycleFacetValue(prev, id))
                          }
                        />
                      );
                    })}
                  </Cluster>
                ) : null}
                {synergyAvailable && synergyQuery.trim() ? (
                  <Cluster gap={3}>
                    {synergyPickerOptions.map((o) => {
                      const s = librarySynergies.find((x) => x.id === o.id);
                      return (
                        <FilterChip
                          key={o.id}
                          size="xs"
                          label={o.label}
                          active={false}
                          mode="off"
                          iconOnly={Boolean(s)}
                          icon={
                            s ? (
                              <DesignationLabel
                                type={s.type}
                                subType={s.subType}
                                size={14}
                                iconOnly
                              />
                            ) : null
                          }
                          onClick={() => {
                            setSynergies((prev) =>
                              cycleFacetValue(prev, o.id),
                            );
                            setSynergyQuery("");
                          }}
                        />
                      );
                    })}
                    {synergyPickerOptions.length === 0 ? (
                      <Text size="xs" tone="muted">
                        No matches
                      </Text>
                    ) : null}
                  </Cluster>
                ) : synergyAvailable && facetActiveCount(synergies) === 0 ? (
                  <Text size="xs" tone="muted">
                    Type to search synergies · include / exclude
                  </Text>
                ) : null}

                <div>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => setMoreFiltersOpen((v) => !v)}
                  >
                    {moreFiltersOpen ? "▾ More" : "▸ More"}
                    {facetActiveCount(archetypes) + groupDims.length > 0
                      ? ` · ${facetActiveCount(archetypes) + groupDims.length}`
                      : ""}
                  </Button>
                </div>
                {moreFiltersOpen ? (
                  <Stack gap={4}>
                    <Stack gap={2}>
                      <Text
                        size="xs"
                        tone="muted"
                        className="uppercase tracking-wide"
                      >
                        {kind === "weapons"
                          ? "Weapon type"
                          : "Armor archetype"}
                        {facetActiveCount(archetypes) > 0
                          ? ` · ${facetActiveCount(archetypes)}`
                          : ""}
                      </Text>
                      <Cluster gap={3}>
                        {kind === "weapons"
                          ? CATALOG_WEAPON_ARCHETYPES.map((t) => {
                              const mode = facetChipState(archetypes, t);
                              return (
                                <FilterChip
                                  key={t}
                                  size="xs"
                                  label={t}
                                  iconOnly
                                  icon={
                                    <WeaponTypeIcon typeName={t} size={14} />
                                  }
                                  active={mode !== "off"}
                                  mode={mode}
                                  onClick={() =>
                                    setArchetypes((prev) =>
                                      cycleFacetValue(prev, t),
                                    )
                                  }
                                />
                              );
                            })
                          : CATALOG_ARMOR_ARCHETYPES.map((t) => {
                              const visual = visualForArmorArchetype(t);
                              const mode = facetChipState(archetypes, t);
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
                                  active={mode !== "off"}
                                  mode={mode}
                                  activeStyle={
                                    visual
                                      ? officialActiveStyle(visual)
                                      : undefined
                                  }
                                  onClick={() =>
                                    setArchetypes((prev) =>
                                      cycleFacetValue(prev, t),
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
                                  groupDimOptions.find((o) => o.id === d)
                                    ?.label ?? d,
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
            </div>
            ) : null}
          </Stack>
        </Panel>
        </Stack>
  );

  const hasSelection = selected != null;
  /**
   * 1–4 columns from **pane** width (not viewport): auto-fill with a floor
   * and a 4-col cap so dual-pane rails stay 1-wide while full results scale up.
   */
  const resultsGridClass =
    "grid gap-2 grid-cols-[repeat(auto-fill,minmax(max(10.5rem,calc(100%/4)),1fr))]";

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
                ) : groupDims.length === 0 ? (
                  <div className={resultsGridClass}>
                    {items.map((item) => renderResultCard(item))}
                  </div>
                ) : (
                  <Stack gap={8}>
                    {grouped.map((group) => (
                      <Stack key={group.key} gap={4}>
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
                        <div className={resultsGridClass}>
                          {group.items.map((item) => renderResultCard(item))}
                        </div>
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

  const gearBody = (
    <div className={catalogBodyRootClasses(hasSelection)}>
      <div className={catalogResultsPaneClasses(hasSelection)}>
        {resultsPane}
      </div>
      {hasSelection && detailPane ? (
        <div className={catalogDetailPaneClasses()}>{detailPane}</div>
      ) : null}
    </div>
  );

  const body = isUniversal ? <UniversalSearchPanel /> : gearBody;

  if (embedded) {
    // Parent must be a height-locked flex child (Sets fill pane). Chrome
    // height-capped on small screens; dual-pane body scrolls rail/detail.
    // lockKind embeds never show Universal (set fill).
    return (
      <div className="h-full min-h-0 flex flex-col overflow-hidden w-full">
        <div className={EMBEDDED_CATALOG_CHROME_CLASSES}>{chromeBlock}</div>
        <div className="flex-1 min-h-0 overflow-hidden basis-0">{body}</div>
      </div>
    );
  }

  return (
    <PageFrame>
      <PageFrameChrome>{isUniversal ? (
        <Stack gap={12}>
          <PageHeader title={title} description={description} />
          <Panel tone="muted" pad="sm">
            <Cluster gap={4}>
              <FilterChip
                size="xs"
                label="Weapons"
                active={false}
                onClick={() => setBrowseMode("weapons")}
              />
              <FilterChip
                size="xs"
                label="Armor"
                active={false}
                onClick={() => setBrowseMode("armor")}
              />
              <FilterChip
                size="xs"
                label="Universal"
                active
                onClick={() => setBrowseMode("universal")}
              />
            </Cluster>
          </Panel>
        </Stack>
      ) : chromeBlock}</PageFrameChrome>
      <PageFrameBody>{body}</PageFrameBody>
    </PageFrame>
  );
}
