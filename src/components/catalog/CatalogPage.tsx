"use client";

import { useCallback, useState } from "react";

import { filterCatalogClient } from "@/lib/catalog/filterCatalogClient";
import type { CatalogItem } from "@/lib/catalog/types";
import { sortByName } from "@/lib/sortByName";
import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Button,
  Callout,
  Chip,
  Cluster,
  EmptyState,
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

type Kind = "weapons" | "armor";
type Scope = "all" | "owned";

type InstanceRow = {
  instanceId: string;
  power?: number;
  location?: string;
  isMasterwork?: boolean;
  plugs?: { displayName: string; resolved: boolean }[];
};

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
  }, [kind, scope, query, slot, className, onlyExotic]);

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
                }}
              />
              <FilterChip
                label="Armor"
                active={kind === "armor"}
                onClick={() => {
                  setKind("armor");
                  setSlot(null);
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
            {kind === "armor" ? (
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
            ) : null}
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
                  <Stack gap={8} className="max-h-[70vh] overflow-auto">
                    {items.map((item) => {
                      const active = selected?.hash === item.hash;
                      return (
                        <button
                          key={item.hash}
                          type="button"
                          className="text-left"
                          onClick={() => void selectItem(item)}
                        >
                          <Panel
                            tone={active ? "accent" : "muted"}
                            pad="sm"
                            className={
                              active
                                ? ""
                                : "hover:border-line-strong transition-colors"
                            }
                          >
                            <Row gap={10} align="start">
                              <ItemIcon
                                icon={item.icon}
                                name={item.name}
                                size={40}
                              />
                              <Stack gap={4} className="min-w-0">
                                <Text size="sm" weight="medium">
                                  {item.name}
                                </Text>
                                <Row gap={6} wrap>
                                  {item.isExotic ? (
                                    <Chip accent>Exotic</Chip>
                                  ) : null}
                                  {item.slot ? <Chip>{item.slot}</Chip> : null}
                                  {item.element ? (
                                    <Chip>{item.element}</Chip>
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
                    })}
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
                      <ItemIcon
                        icon={selected.icon}
                        name={selected.name}
                        size={64}
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
                        <Stack gap={8}>
                          {instances.map((inst) => (
                            <Panel key={inst.instanceId} tone="muted" pad="sm">
                              <Stack gap={4}>
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
                                {(inst.plugs?.length ?? 0) > 0 ? (
                                  <Cluster gap={4}>
                                    {inst.plugs!.map((p) => (
                                      <Chip key={`${inst.instanceId}-${p.displayName}`}>
                                        {p.displayName}
                                      </Chip>
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
