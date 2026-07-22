"use client";

import { useState } from "react";
import Link from "next/link";

import { ArmorStatsPanel } from "@/components/catalog/ArmorStatsPanel";
import { SLOT_LABEL, type SetDetail, type SetItem } from "@/components/sets/types";
import {
  Badge,
  Button,
  Chip,
  Cluster,
  ConceptTagChip,
  EntityHotspot,
  Heading,
  MetaChip,
  Panel,
  Row,
  Section,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import { ARMOR_STAT_NAMES } from "@/data/rules/statBenefits";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import { armorEnergyCapacity, sumEnergyCosts } from "@/lib/builds/modEnergy";
import { buildDetailHref } from "@/lib/sets/buildDetailHref";
import { isLegacyModItem } from "@/lib/sets/modSetEnergy";
import {
  ARMOR_SLOTS,
  modSetArmorSlotOf,
  SLOTS_BY_SET_TYPE,
  type SetType,
} from "@/lib/sets/schemas";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

function itemMetaChips(item: SetItem): string[] {
  const meta: string[] = [];
  if (item.isExotic) meta.push("Exotic");
  if (item.element) meta.push(item.element);
  if (item.ammo) meta.push(item.ammo);
  if (item.itemTypeName) meta.push(item.itemTypeName);
  if (item.frame) meta.push(item.frame);
  if (item.classType) meta.push(item.classType);
  if (item.tierLabel) meta.push(item.tierLabel);
  else if (item.tier != null) meta.push(`Tier ${item.tier}`);
  if (item.originTraitName) meta.push(item.originTraitName);
  if (item.power != null) meta.push(`P${item.power}`);
  if (item.location) meta.push(item.location);
  if (item.instanceId) meta.push("Instance pinned");
  if (item.stale) meta.push("Stale hash");
  return meta;
}

function ItemExtras({ item }: { item: SetItem }) {
  const traits = item.selectedTraitPerks ?? [];
  const available = item.availableTraitPerks ?? [];
  const synergies = item.linkedSynergies ?? [];
  const hasExtras =
    traits.length > 0 || available.length > 0 || synergies.length > 0;

  return (
    <Stack gap={6} className="min-w-0 w-full">
      {hasExtras ? (
        <Stack gap={6}>
          {traits.length > 0 ? (
            <Stack gap={4}>
              <SectionLabel>Selected perks</SectionLabel>
              <Cluster gap={4}>
                {traits.map((p) => (
                  <Chip key={p.hash} accent>
                    {p.name}
                  </Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
          {available.length > 0 ? (
            <Stack gap={4}>
              <SectionLabel>Available perks</SectionLabel>
              <Cluster gap={4}>
                {available.map((p) => (
                  <Chip key={p.hash}>{p.name}</Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
          {synergies.length > 0 ? (
            <Stack gap={4}>
              <SectionLabel>Linked synergies</SectionLabel>
              <Cluster gap={4}>
                {synergies.map((s) => (
                  <Chip key={s.id} accent>
                    {s.label}
                  </Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
        </Stack>
      ) : null}
      {item.statValues ? (
        <ArmorStatsPanel
          statValues={item.statValues}
          totalStats={item.totalStats}
          statsIncomplete={item.statsIncomplete ?? false}
        />
      ) : item.instanceId &&
        ["helmet", "arms", "chest", "legs", "class_item", "exotic_armor"].includes(
          item.slot,
        ) ? (
        <Text size="xs" tone="muted">
          No armor stats on this copy — re-sync inventory.
        </Text>
      ) : !item.instanceId &&
        ["helmet", "arms", "chest", "legs", "class_item", "exotic_armor"].includes(
          item.slot,
        ) ? (
        <Text size="xs" tone="muted">
          No instance — stats unknown (wishlist).
        </Text>
      ) : null}
    </Stack>
  );
}

function filledCount(activeItems: SetItem[], slots: readonly string[]): number {
  return slots.filter((slot) => activeItems.some((i) => i.slot === slot)).length;
}

export function SetsDetail({
  set,
  onEdit,
  onFillSlot,
  onDelete,
  onUpdated,
  deleteBusy,
}: {
  set: SetDetail;
  onEdit: () => void;
  onFillSlot: (slot: string) => void;
  onDelete: () => void;
  onUpdated?: (next: SetDetail) => void;
  deleteBusy?: boolean;
}) {
  const activeItems = set.items.filter((i) => !i.removedAt);
  const slots = SLOTS_BY_SET_TYPE[set.type as SetType];
  const isMods = slots === "mods_only";
  const isArmor = set.type === "armor" || set.type === "Armor";
  const [removeBusy, setRemoveBusy] = useState<string | null>(null);
  const [removeError, setRemoveError] = useState<string | null>(null);

  async function removeItem(itemId: string) {
    setRemoveBusy(itemId);
    setRemoveError(null);
    try {
      const res = await fetch(
        `/api/user/sets/${set.id}/items?itemId=${encodeURIComponent(itemId)}`,
        { method: "DELETE" },
      );
      const body = (await res.json()) as { set?: SetDetail; error?: string };
      if (!res.ok || !body.set) {
        setRemoveError(body.error ?? "Failed to remove item");
        return;
      }
      onUpdated?.(body.set);
    } catch {
      setRemoveError("Failed to remove item");
    } finally {
      setRemoveBusy(null);
    }
  }

  const totals = set.armorStatTotals;
  const usedBy = set.usedByBuilds ?? [];
  const slotList = isMods ? ARMOR_SLOTS : (slots as readonly string[]);
  const filled = isMods
    ? activeItems.filter((i) => !isLegacyModItem(i.slot)).length
    : filledCount(activeItems, slotList);
  const capacitySlots = isMods ? ARMOR_SLOTS.length : slotList.length;
  const emptySlots = isMods
    ? 0
    : Math.max(0, capacitySlots - filled);

  return (
    <Panel as="article" tone="raised" className="w-full">
      <Stack gap={16}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={8} className="min-w-0 flex-1">
            <Heading level={1}>{set.name}</Heading>
            <Cluster gap={6}>
              <Badge tone="accent">{set.type}</Badge>
              {!isMods ? (
                <Badge
                  tone={
                    emptySlots === 0 && filled > 0
                      ? "verified"
                      : filled === 0
                        ? "unresolved"
                        : "fuzzy"
                  }
                  title="Filled slots vs set capacity"
                >
                  {filled}/{capacitySlots} filled
                </Badge>
              ) : (
                <Badge
                  tone={filled > 0 ? "verified" : "unresolved"}
                  title="Mods attached across armor pieces"
                >
                  {filled === 1 ? "1 mod" : `${filled} mods`}
                </Badge>
              )}
              {usedBy.length > 0 ? (
                <Badge tone="verified" title="Curated builds using this set">
                  {usedBy.length === 1
                    ? "1 build"
                    : `${usedBy.length} builds`}
                </Badge>
              ) : (
                <Badge tone="unresolved" title="No builds attach this set yet">
                  Unused
                </Badge>
              )}
              {(set.tagIds ?? []).map((t) => (
                <ConceptTagChip key={t} tagId={t} size={22} />
              ))}
            </Cluster>
          </Stack>
          <Row gap={4} wrap className="shrink-0">
            <Button size="sm" onClick={onEdit}>
              Edit meta
            </Button>
            <Button
              size="sm"
              variant="danger"
              disabled={deleteBusy}
              onClick={onDelete}
            >
              {deleteBusy ? "Deleting…" : "Delete"}
            </Button>
          </Row>
        </Row>

        <div className="h-px w-full bg-gradient-to-r from-accent/70 to-transparent" />

        {removeError ? (
          <Text size="xs" tone="danger">
            {removeError}
          </Text>
        ) : null}

        {isArmor ? (
          <Section label="Armor stats" gap={8}>
            <Text size="xs" tone="muted">
              Totals use pinned inventory copies; wishlist pieces have no rolls.
            </Text>
            {totals && totals.piecesWithStats > 0 ? (
              <Stack gap={6}>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-2">
                  {ARMOR_STAT_NAMES.map((name) => (
                    <Row key={name} justify="between" gap={8}>
                      <Text size="xs" tone="muted">
                        {name}
                      </Text>
                      <Text size="xs" weight="medium" className="tabular-nums">
                        {totals.statValues[name] ?? "—"}
                      </Text>
                    </Row>
                  ))}
                </div>
                <Text size="xs" weight="medium">
                  Total {totals.grandTotal}
                  {totals.incomplete ? " · incomplete" : ""}
                  {totals.piecesWithStats > 0
                    ? ` · ${totals.piecesWithStats} piece${
                        totals.piecesWithStats === 1 ? "" : "s"
                      }`
                    : ""}
                </Text>
              </Stack>
            ) : (
              <Text size="sm" tone="muted">
                No instance stats yet — pin owned armor copies when filling
                slots.
              </Text>
            )}
          </Section>
        ) : null}

        <Section
          label={
            usedBy.length > 0
              ? `Used by builds · ${usedBy.length}`
              : "Used by builds"
          }
          gap={8}
        >
          {usedBy.length === 0 ? (
            <Text size="sm" tone="muted">
              No curated builds use this set yet. Attach it on a build variant
              to see it here.
            </Text>
          ) : (
            <Stack gap={6}>
              {usedBy.map((b) => (
                <Link
                  key={b.buildId}
                  href={buildDetailHref(b.buildId)}
                  className="block focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-2 focus-visible:outline-accent"
                >
                  <Panel
                    tone="muted"
                    pad="sm"
                    className="hover:border-line-strong transition-colors"
                  >
                    <Stack gap={2}>
                      <Text size="sm" weight="medium">
                        {b.buildName}
                      </Text>
                      {b.variantNames.length > 0 ? (
                        <Text size="xs" tone="muted">
                          {b.variantNames.join(" · ")}
                        </Text>
                      ) : null}
                    </Stack>
                  </Panel>
                </Link>
              ))}
            </Stack>
          )}
        </Section>

        {isMods ? (
          <Section label="Mods by armor piece" gap={10}>
            <Text size="xs" tone="muted">
              Add mods under each armor piece. Slot-scoped plugs must match the
              piece; general / tuning mods work on any piece. Multiple mods per
              piece up to energy capacity (10 by default).
            </Text>
            <Stack gap={10}>
              {ARMOR_SLOTS.map((armorSlot) => {
                const pieceMods = activeItems.filter(
                  (i) => modSetArmorSlotOf(i.slot) === armorSlot,
                );
                const capacity = armorEnergyCapacity(null);
                const used = sumEnergyCosts(
                  pieceMods.map((m) => m.energyCost),
                );
                const overEnergy = used > capacity;
                return (
                  <Panel key={armorSlot} tone="muted" pad="sm">
                    <Stack gap={8}>
                      <Row justify="between" align="center" gap={8} wrap>
                        <Stack gap={4} className="min-w-0">
                          <Text size="sm" weight="medium">
                            {SLOT_LABEL[armorSlot] ?? armorSlot}
                          </Text>
                          <Cluster gap={4}>
                            <Badge tone={overEnergy ? "danger" : "unresolved"}>
                              Energy {used}/{capacity}
                            </Badge>
                            <Badge
                              tone={
                                pieceMods.length > 0 ? "accent" : "unresolved"
                              }
                            >
                              {pieceMods.length === 1
                                ? "1 mod"
                                : `${pieceMods.length} mods`}
                            </Badge>
                          </Cluster>
                        </Stack>
                        <Button
                          size="sm"
                          variant="accent"
                          onClick={() => onFillSlot(armorSlot)}
                        >
                          Add mod
                        </Button>
                      </Row>
                      {pieceMods.length === 0 ? (
                        <Text size="xs" tone="muted">
                          No mods on this piece yet.
                        </Text>
                      ) : (
                        <Stack gap={6}>
                          {pieceMods.map((item) => (
                            <Row
                              key={item.id}
                              justify="between"
                              align="start"
                              gap={8}
                              wrap
                            >
                              <EntityHotspot
                                kind="Mod"
                                name={item.itemName}
                                description={item.description}
                                icon={item.icon}
                                accentColor={accentFor(item.element)}
                                size={32}
                                showLabel="auto"
                                meta={[
                                  ...itemMetaChips(item),
                                  ...(item.energyCost != null
                                    ? [`${item.energyCost} energy`]
                                    : []),
                                  ...(item.slotCategory
                                    ? [item.slotCategory]
                                    : []),
                                ]}
                              />
                              <Button
                                size="sm"
                                variant="danger"
                                disabled={removeBusy === item.id}
                                onClick={() => void removeItem(item.id)}
                              >
                                {removeBusy === item.id ? "…" : "Remove"}
                              </Button>
                            </Row>
                          ))}
                        </Stack>
                      )}
                    </Stack>
                  </Panel>
                );
              })}
              {(() => {
                const legacy = activeItems.filter((i) =>
                  isLegacyModItem(i.slot),
                );
                if (legacy.length === 0) return null;
                return (
                  <Panel tone="warning" pad="sm">
                    <Stack gap={8}>
                      <Row justify="between" align="center" gap={8} wrap>
                        <Text size="sm" weight="medium">
                          Unscoped (legacy)
                        </Text>
                        <Badge tone="warning">
                          {legacy.length === 1
                            ? "1 leftover"
                            : `${legacy.length} leftovers`}
                        </Badge>
                      </Row>
                      <Text size="xs" tone="muted">
                        Older free-list mods. Remove and re-add under an armor
                        piece to organize.
                      </Text>
                      {legacy.map((item) => (
                        <Row
                          key={item.id}
                          justify="between"
                          align="start"
                          gap={8}
                          wrap
                        >
                          <EntityHotspot
                            kind="Mod"
                            name={item.itemName}
                            description={item.description}
                            icon={item.icon}
                            size={32}
                            showLabel="auto"
                          />
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={removeBusy === item.id}
                            onClick={() => void removeItem(item.id)}
                          >
                            {removeBusy === item.id ? "…" : "Remove"}
                          </Button>
                        </Row>
                      ))}
                    </Stack>
                  </Panel>
                );
              })()}
            </Stack>
          </Section>
        ) : (
          <Section
            label={
              capacitySlots > 0
                ? `Slots · ${filled}/${capacitySlots}`
                : "Slots"
            }
            gap={8}
          >
            <Stack gap={8}>
              {slotList.map((slot) => {
                const item = activeItems.find((i) => i.slot === slot);
                return (
                  <Panel key={slot} tone="muted" pad="sm">
                    <Row justify="between" align="start" gap={8} wrap>
                      <Stack gap={6} className="min-w-0 flex-1">
                        <Row gap={6} align="center" wrap>
                          <SectionLabel>
                            {SLOT_LABEL[slot] ?? slot}
                          </SectionLabel>
                          {item?.isExotic ? (
                            <Badge tone="fuzzy">Exotic</Badge>
                          ) : null}
                          {item?.stale ? (
                            <Badge tone="danger">Stale</Badge>
                          ) : null}
                          {item?.element && isDestinyElement(item.element) ? (
                            <MetaChip
                              label={item.element}
                              accentColor={accentFor(item.element)}
                            />
                          ) : null}
                          {!item ? (
                            <Badge tone="unresolved">Empty</Badge>
                          ) : null}
                        </Row>
                        {item ? (
                          <>
                            <EntityHotspot
                              kind={SLOT_LABEL[slot] ?? slot}
                              name={item.itemName}
                              description={item.description}
                              icon={item.icon}
                              accentColor={accentFor(item.element)}
                              size={40}
                              showLabel="auto"
                              meta={itemMetaChips(item)}
                            />
                            {item.description ? (
                              <Text
                                size="xs"
                                tone="muted"
                                className="line-clamp-2"
                              >
                                {item.description}
                              </Text>
                            ) : null}
                            <ItemExtras item={item} />
                          </>
                        ) : (
                          <Text size="xs" tone="muted">
                            Empty — fill from catalog or inventory.
                          </Text>
                        )}
                      </Stack>
                      <Stack gap={4} className="shrink-0">
                        <Button
                          size="sm"
                          variant={item ? "outline" : "accent"}
                          onClick={() => onFillSlot(slot)}
                        >
                          {item ? "Replace" : "Fill"}
                        </Button>
                        {item ? (
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={removeBusy === item.id}
                            onClick={() => void removeItem(item.id)}
                          >
                            {removeBusy === item.id ? "…" : "Remove"}
                          </Button>
                        ) : null}
                      </Stack>
                    </Row>
                  </Panel>
                );
              })}
            </Stack>
          </Section>
        )}

        {set.modEncourage ? (
          <Text size="xs" tone="warning">
            Some armor pieces may have empty mod slots.
          </Text>
        ) : null}
      </Stack>
    </Panel>
  );
}
