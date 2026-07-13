"use client";

import { useCallback, useMemo, useState } from "react";

import { InstancePerkGridView } from "@/components/catalog/InstancePerkGridView";
import { filterCatalogClient } from "@/lib/catalog/filterCatalogClient";
import {
  CATALOG_AMMO_TYPES,
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
  Cluster,
  EmptyState,
  EntityHotspot,
  FilterChip,
  PageHeader,
  Panel,
  Row,
  Section,
  SectionLabel,
  Stack,
  Text,
  TextField,
  Workspace,
  WorkspaceMain,
  Heading,
} from "@/components/ui";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";

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

  const [items, setItems] = useState<CatalogItem[]>([]);
  const [selected, setSelected] = useState<CatalogItem | null>(null);
  const [instances, setInstances] = useState<InstanceRow[]>([]);
  const [linkedSynergies, setLinkedSynergies] = useState<
    Array<{ id: string; name: string; type: string }>
  >([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);

  const runSearch = useCallback(async () => {
    setLoading(true);
    setError(null);
    setSyncMessage(null);
    setSelected(null);
    setInstances([]);
    setLinkedSynergies([]);
    setHasSearched(true);
    try {
      const params = new URLSearchParams({
        scope,
        includeInstancePointer: "1",
        limit: "100",
      });
      if (query.trim()) params.set("q", query.trim());
      if (slot) params.set("slot", slot);
      if (kind === "armor" && className) params.set("className", className);
      if (kind === "weapons") {
        if (elements.length) params.set("element", elements.join(","));
        if (ammos.length) params.set("ammo", ammos.join(","));
        if (archetypes.length) params.set("itemType", archetypes.join(","));
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
        setItems([]);
        return;
      }
      let rows = body.items ?? [];
      rows = filterCatalogClient(rows, { onlyExotic });
      setItems(sortByName(rows));
      if (body.syncPrompt && body.message) setSyncMessage(body.message);
    } catch {
      setError("Catalog search failed");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [
    kind,
    scope,
    query,
    slot,
    className,
    onlyExotic,
    elements,
    ammos,
    archetypes,
  ]);

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

  function toggleGroupDim(dim: CatalogGroupDimension) {
    setGroupDims((prev) => {
      if (prev.includes(dim)) return prev.filter((d) => d !== dim);
      return [...prev, dim];
    });
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
                {item.element ? <Chip>{item.element}</Chip> : null}
                {item.ammo ? <Chip>{item.ammo}</Chip> : null}
                {item.itemTypeName ? <Chip>{item.itemTypeName}</Chip> : null}
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

  return (
    <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6">
      <Stack gap={16}>
        <PageHeader
          title="Catalog"
          description="Browse weapons and armor from the manifest or your owned inventory."
        />

        {error ? <Callout tone="danger">{error}</Callout> : null}
        {syncMessage ? <Callout tone="warning">{syncMessage}</Callout> : null}

        <Panel tone="muted" pad="md">
          <Stack gap={10}>
            <SectionLabel>Browse</SectionLabel>
            <Cluster gap={6}>
              <FilterChip
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
                label="Owned"
                active={scope === "owned"}
                onClick={() => setScope("owned")}
              />
              <FilterChip
                label="Manifest"
                active={scope === "all"}
                onClick={() => setScope("all")}
              />
              <FilterChip
                label="Exotic only"
                active={onlyExotic}
                onClick={() => setOnlyExotic((v) => !v)}
              />
            </Cluster>
            <TextField
              label="Search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") void runSearch();
              }}
              placeholder="Name, frame, perk…"
            />
            <Stack gap={4}>
              <Text size="xs" tone="muted" className="uppercase tracking-widest">
                Slot
              </Text>
              <Cluster gap={6}>
                {slotOptions.map((s) => (
                  <FilterChip
                    key={s}
                    label={s}
                    active={slot === s}
                    onClick={() => setSlot((prev) => (prev === s ? null : s))}
                  />
                ))}
              </Cluster>
            </Stack>
            {kind === "armor" ? (
              <Stack gap={4}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Class
                </Text>
                <Cluster gap={6}>
                  {CLASSES.map((c) => (
                    <FilterChip
                      key={c}
                      label={c}
                      active={className === c}
                      onClick={() =>
                        setClassName((prev) => (prev === c ? null : c))
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
            ) : null}
            {kind === "weapons" ? (
              <>
                <Stack gap={4}>
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
                <Stack gap={4}>
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
                <Stack gap={4}>
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
                {elements.length + ammos.length + archetypes.length > 0 ? (
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setElements([]);
                      setAmmos([]);
                      setArchetypes([]);
                    }}
                  >
                    Clear multi-filters
                  </Button>
                ) : null}
              </>
            ) : null}
            <Stack gap={4}>
              <Text size="xs" tone="muted" className="uppercase tracking-widest">
                Group by
                {groupDims.length > 0
                  ? ` · ${groupDims.map((d) => groupDimOptions.find((o) => o.id === d)?.label ?? d).join(" · ")}`
                  : " · none"}
              </Text>
              <Cluster gap={6}>
                {groupDimOptions.map((opt) => (
                  <FilterChip
                    key={opt.id}
                    label={opt.label}
                    active={groupDims.includes(opt.id)}
                    onClick={() => toggleGroupDim(opt.id)}
                  />
                ))}
                {groupDims.length > 0 ? (
                  <FilterChip
                    label="Clear groups"
                    active={false}
                    onClick={() => setGroupDims([])}
                  />
                ) : null}
              </Cluster>
            </Stack>
            <Row gap={8}>
              <Button
                size="sm"
                variant="accent"
                disabled={loading}
                onClick={() => void runSearch()}
              >
                {loading ? "Searching…" : "Search"}
              </Button>
            </Row>
          </Stack>
        </Panel>

        <Workspace
          rail={
            <Panel as="aside" className="flex flex-col min-h-[420px]">
              <Stack gap={12}>
                <SectionLabel>
                  Results
                  {items.length > 0 ? ` · ${items.length}` : ""}
                </SectionLabel>
                {loading ? (
                  <Text size="sm" tone="muted">
                    Searching…
                  </Text>
                ) : !hasSearched ? (
                  <Text size="sm" tone="muted">
                    Run a search to list items.
                  </Text>
                ) : items.length === 0 ? (
                  <Text size="sm" tone="muted">
                    No items match.
                  </Text>
                ) : (
                  <Stack gap={10} className="max-h-[70vh] overflow-auto">
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
                              {group.items.map((item) => renderResultRow(item))}
                            </Stack>
                          </Stack>
                        ))}
                  </Stack>
                )}
              </Stack>
            </Panel>
          }
          main={
            !selected ? (
              <EmptyState description="Select an item to see detail and owned instances." />
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
                          {selected.element ? (
                            <Chip>{selected.element}</Chip>
                          ) : null}
                          {selected.ammo ? <Chip>{selected.ammo}</Chip> : null}
                          {selected.itemTypeName ? (
                            <Chip>{selected.itemTypeName}</Chip>
                          ) : null}
                          {selected.frame ? <Chip>{selected.frame}</Chip> : null}
                          {selected.classType ? (
                            <Chip>{selected.classType}</Chip>
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
      </Stack>
    </div>
  );
}
