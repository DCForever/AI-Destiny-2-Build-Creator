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
  FlapTypeStamp,
  Heading,
  Panel,
  Row,
  Section,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import { ARMOR_STAT_NAMES, STAT_MAX } from "@/data/rules/statBenefits";
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
  if (item.instanceId) meta.push("Instance");
  else meta.push("Wishlist");
  if (item.stale) meta.push("Stale");
  return meta;
}

const ARMOR_ITEM_SLOTS = new Set([
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
  "exotic_armor",
]);

/** Fixed-height stat row shared by totals rail + piece cards (cross-read). */
const ARMOR_STAT_ROW =
  "h-5 flex items-center gap-x-1.5 min-w-0";

function ItemTraitChips({ item }: { item: SetItem }) {
  const traits = item.selectedTraitPerks ?? [];
  const available = item.availableTraitPerks ?? [];
  if (traits.length === 0 && available.length === 0) return null;
  return (
    <Stack gap={4} className="min-w-0 w-full">
      {traits.length > 0 ? (
        <Cluster gap={4}>
          {traits.map((p) => (
            <Chip key={p.hash} accent>
              {p.name}
            </Chip>
          ))}
        </Cluster>
      ) : null}
      {available.length > 0 ? (
        <Cluster gap={4}>
          {available.slice(0, 6).map((p) => (
            <Chip key={p.hash}>{p.name}</Chip>
          ))}
        </Cluster>
      ) : null}
    </Stack>
  );
}

/** Perks/stats in the card body — synergies render in the footer. */
function ItemExtras({
  item,
  omitStats = false,
}: {
  item: SetItem;
  /** When true, stats render in the aligned armor board instead. */
  omitStats?: boolean;
}) {
  const traits = item.selectedTraitPerks ?? [];
  const available = item.availableTraitPerks ?? [];
  const hasBodyExtras = traits.length > 0 || available.length > 0;
  const showStats = !omitStats && Boolean(item.statValues);
  if (!hasBodyExtras && !showStats) {
    if (omitStats) return null;
    if (item.instanceId && ARMOR_ITEM_SLOTS.has(item.slot)) {
      return (
        <Text size="xs" tone="muted">
          No armor stats on this copy — re-sync inventory.
        </Text>
      );
    }
    if (!item.instanceId && ARMOR_ITEM_SLOTS.has(item.slot)) {
      return (
        <Text size="xs" tone="muted">
          Wishlist — no instance rolls.
        </Text>
      );
    }
    return null;
  }

  return (
    <Stack gap={4} className="min-w-0 w-full">
      <ItemTraitChips item={item} />
      {showStats ? (
        <ArmorStatsPanel
          statValues={item.statValues}
          totalStats={item.totalStats}
          statsIncomplete={item.statsIncomplete ?? false}
        />
      ) : null}
    </Stack>
  );
}

/** One aligned stat row for a piece (or empty placeholder). */
function ArmorPieceStatRow({
  name,
  value,
}: {
  name: string;
  value?: number;
}) {
const has = typeof value === "number";
  const ratio = has
    ? Math.min(1, Math.max(0, value / STAT_MAX))
    : 0;
  return (
    <div className={ARMOR_STAT_ROW} title={name}>
      <Text
        size="xs"
        weight="medium"
        tone={has ? "default" : "muted"}
        className="tabular-nums w-7 shrink-0 text-right"
        as="span"
      >
        {has ? value : "—"}
      </Text>
      <div className="h-1.5 flex-1 min-w-0 rounded-sm bg-surface-raised border border-line overflow-hidden">
        {has ? (
          <div
            className="h-full bg-foreground/70"
            style={{ width: `${Math.round(ratio * 100)}%` }}
          />
        ) : null}
      </div>
    </div>
  );
}

function ArmorTotalsStatRow({
  name,
  value,
}: {
  name: string;
  value?: number;
}) {
  const has = typeof value === "number";
  return (
    <div className={`${ARMOR_STAT_ROW} justify-between gap-2`} title={name}>
      <Text size="xs" tone="muted" className="truncate" as="span">
        {name}
      </Text>
      <Text
        size="xs"
        weight="medium"
        tone={has ? "default" : "muted"}
        className="tabular-nums shrink-0"
        as="span"
      >
        {has ? value : "—"}
      </Text>
    </div>
  );
}

function LinkedSynergiesFooter({
  synergies,
}: {
  synergies: NonNullable<SetItem["linkedSynergies"]>;
}) {
  if (synergies.length === 0) return null;
  return (
    <div className="border-t border-line pt-2 mt-1">
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
    </div>
  );
}

function filledCount(activeItems: SetItem[], slots: readonly string[]): number {
  return slots.filter((slot) => activeItems.some((i) => i.slot === slot)).length;
}

function firstEmptySlot(
  activeItems: SetItem[],
  slotList: readonly string[],
): string | null {
  return slotList.find((slot) => !activeItems.some((i) => i.slot === slot)) ?? null;
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
  const nextEmpty = isMods ? null : firstEmptySlot(activeItems, slotList);
  const typeKey = String(set.type);

  const readinessTone = isMods
    ? filled > 0
      ? "verified"
      : "unresolved"
    : emptySlots === 0 && filled > 0
      ? "verified"
      : filled === 0
        ? "unresolved"
        : "fuzzy";

  return (
    <Panel as="article" tone="raised" pad="md" className="w-full">
      <Stack gap={12}>
        {/* 1. Identity */}
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Heading level={1}>{set.name}</Heading>
            <Cluster gap={6}>
              <FlapTypeStamp type={typeKey} />
              {(set.tagIds ?? []).map((t) => (
                <ConceptTagChip key={t} tagId={t} size={18} />
              ))}
            </Cluster>
          </Stack>
          <Row gap={4} wrap className="shrink-0">
            <Button size="sm" variant="outline" onClick={onEdit}>
              Edit
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

        <div className="keyline" />

        {/* 2. Readiness */}
        <div
          className="border px-2.5 py-2"
          style={{
            borderColor:
              readinessTone === "verified"
                ? "color-mix(in srgb, var(--success) 35%, var(--line))"
                : readinessTone === "fuzzy"
                  ? "color-mix(in srgb, var(--warning) 35%, var(--line))"
                  : "var(--line)",
            background:
              readinessTone === "verified"
                ? "color-mix(in srgb, var(--success) 6%, var(--surface))"
                : readinessTone === "fuzzy"
                  ? "color-mix(in srgb, var(--warning) 6%, var(--surface))"
                  : "transparent",
          }}
        >
          <Row justify="between" align="center" gap={8} wrap>
            <Cluster gap={6}>
              {isMods ? (
                <Badge tone={filled > 0 ? "verified" : "unresolved"}>
                  {filled === 1 ? "1 mod" : `${filled} mods`}
                </Badge>
              ) : (
                <Badge tone={readinessTone}>
                  {filled}/{capacitySlots} filled
                  {emptySlots > 0 ? ` · ${emptySlots} empty` : ""}
                </Badge>
              )}
              {usedBy.length > 0 ? (
                <Badge tone="verified">
                  {usedBy.length === 1
                    ? "1 build"
                    : `${usedBy.length} builds`}
                </Badge>
              ) : (
                <Badge tone="unresolved">Unused</Badge>
              )}
            </Cluster>
            {!isMods && nextEmpty ? (
              <Button
                size="sm"
                variant="accent"
                onClick={() => onFillSlot(nextEmpty)}
              >
                Fill next · {SLOT_LABEL[nextEmpty] ?? nextEmpty}
              </Button>
            ) : !isMods && emptySlots === 0 && filled > 0 ? (
              <Text size="xs" tone="muted" className="uppercase tracking-widest">
                All slots filled
              </Text>
            ) : isMods ? (
              <Button
                size="sm"
                variant="accent"
                onClick={() => onFillSlot(ARMOR_SLOTS[0]!)}
              >
                Add mod
              </Button>
            ) : null}
          </Row>
        </div>

        {removeError ? (
          <Text size="xs" tone="danger">
            {removeError}
          </Text>
        ) : null}

        {/* 3. Slot board */}
{isMods ? (
          <Section label="Mods by armor piece" gap={8}>
<div className="grid gap-3 grid-cols-[repeat(auto-fit,minmax(10.5rem,1fr))]">
              {ARMOR_SLOTS.map((armorSlot) => {
                const pieceMods = activeItems.filter(
                  (i) => modSetArmorSlotOf(i.slot) === armorSlot,
                );
                const capacity = armorEnergyCapacity(null);
                const used = sumEnergyCosts(
                  pieceMods.map((m) => m.energyCost),
                );
                const overEnergy = used > capacity;
                const emptyPiece = pieceMods.length === 0;
                return (
                  <Panel
                    key={armorSlot}
                    tone={emptyPiece ? "default" : "muted"}
                    pad="sm"
                    className={
                      emptyPiece
                        ? "h-full border-dashed border-warning/50 bg-[color-mix(in_srgb,var(--warning)_5%,transparent)]"
                        : "h-full"
                    }
                  >
<Stack gap={8} className="h-full">
                      <Stack gap={4} className="min-w-0">
                        <SectionLabel>
                          {SLOT_LABEL[armorSlot] ?? armorSlot}
                        </SectionLabel>
                        <Cluster gap={4}>
                          <Badge tone={overEnergy ? "danger" : "unresolved"}>
                            {used}/{capacity}
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
                      {emptyPiece ? (
                        <Text size="xs" tone="muted" className="flex-1">
                          Empty piece — add mods up to energy capacity.
                        </Text>
                      ) : (
                        <Stack gap={4} className="flex-1 min-w-0">
                          {pieceMods.map((item) => (
                            <Row
                              key={item.id}
                              justify="between"
                              align="center"
                              gap={6}
                              wrap
                            >
                              <EntityHotspot
                                kind="Mod"
                                name={item.itemName}
                                description={item.description}
                                icon={item.icon}
                                accentColor={accentFor(item.element)}
                                size={28}
                                showLabel="auto"
                                meta={[
                                  ...itemMetaChips(item),
                                  ...(item.energyCost != null
                                    ? [`${item.energyCost} energy`]
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
                      <div className="mt-auto pt-1">
                        <Button
                          size="sm"
                          variant="accent"
                          className="w-full"
                          onClick={() => onFillSlot(armorSlot)}
                        >
                          Add mod
                        </Button>
                      </div>
                    </Stack>
                  </Panel>
                );
              })}
            </div>
            {(() => {
              const legacy = activeItems.filter((i) => isLegacyModItem(i.slot));
              if (legacy.length === 0) return null;
              return (
                <Panel tone="warning" pad="sm">
                  <Stack gap={6}>
                    <Text size="sm" weight="medium">
                      Unscoped (legacy)
                    </Text>
                    <Text size="xs" tone="muted">
                      Remove and re-add under an armor piece.
                    </Text>
                    {legacy.map((item) => (
                      <Row
                        key={item.id}
                        justify="between"
                        align="center"
                        gap={8}
                        wrap
                      >
                        <EntityHotspot
                          kind="Mod"
                          name={item.itemName}
                          description={item.description}
                          icon={item.icon}
                          size={28}
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
          </Section>
) : isArmor ? (
          <Section
            label={
              capacitySlots > 0
                ? `Slots · ${filled}/${capacitySlots}`
                : "Slots"
            }
            gap={8}
          >
            {/*
              One shared CSS grid + subgrid columns so totals and each piece
              share identical row tracks — Health/Melee/… line up across.
              Horizontal scroll on narrow panes instead of wrapping cards.
            */}
            <div className="overflow-x-auto -mx-0.5 px-0.5">
              <div
                className="grid gap-x-3 min-w-0"
                style={{
                  gridTemplateColumns: `7.75rem repeat(${slotList.length}, minmax(10.25rem, 1fr))`,
                  gridTemplateRows: `auto auto auto repeat(${ARMOR_STAT_NAMES.length}, auto) auto auto`,
                }}
              >
                {/* Totals rail */}
                <aside
                  className="row-span-full grid grid-rows-subgrid min-w-0 border border-line bg-surface-raised p-2"
                >
                  <div className="min-w-0">
                    <SectionLabel>Totals</SectionLabel>
                    <Cluster gap={4} className="mt-1">
                      {totals && totals.piecesWithStats > 0 ? (
                        <Badge tone={totals.incomplete ? "fuzzy" : "verified"}>
                          {totals.piecesWithStats}pc
                          {totals.incomplete ? " · inc" : ""}
                        </Badge>
                      ) : (
                        <Badge tone="unresolved">No stats</Badge>
                      )}
                    </Cluster>
                  </div>
                  <div className="min-w-0 flex items-end">
                    <Text size="sm" weight="medium" className="leading-snug">
                      Set sum
                    </Text>
                  </div>
                  <div className="min-w-0" aria-hidden />
                  {ARMOR_STAT_NAMES.map((name) => (
                    <ArmorTotalsStatRow
                      key={name}
                      name={name}
                      value={
                        totals && totals.piecesWithStats > 0
                          ? totals.statValues[name]
                          : undefined
                      }
                    />
                  ))}
                  <div className={ARMOR_STAT_ROW}>
                    <Text size="xs" weight="medium" as="span">
                      {totals && totals.piecesWithStats > 0
                        ? `Total ${totals.grandTotal}`
                        : "Total —"}
                    </Text>
                  </div>
<div className="min-w-0 pt-1 flex flex-col justify-end">
                    <Text size="xs" tone="muted">
                      {totals && totals.piecesWithStats > 0
                        ? "Sum across pinned instances"
                        : "Pin owned armor for rolls"}
                    </Text>
                  </div>
                </aside>

                {slotList.map((slot) => {
                  const item = activeItems.find((i) => i.slot === slot);
                  const empty = !item;
                  return (
                    <div
                      key={slot}
                      className={
                        empty
                          ? "row-span-full grid grid-rows-subgrid min-w-0 border border-dashed border-accent/40 bg-[color-mix(in_srgb,var(--accent)_5%,transparent)] p-2"
                          : "row-span-full grid grid-rows-subgrid min-w-0 panel-notch bg-surface-raised/40 p-2"
                      }
                    >
                      <div className="min-w-0">
                        <Row justify="between" align="start" gap={6}>
                          <Stack gap={4} className="min-w-0 flex-1 pr-1">
                            <SectionLabel>
                              {SLOT_LABEL[slot] ?? slot}
                            </SectionLabel>
                            <Cluster gap={4}>
                              {empty ? (
                                <Badge tone="unresolved">Empty</Badge>
                              ) : null}
                              {item?.isExotic ? (
                                <Badge tone="fuzzy">Exotic</Badge>
                              ) : null}
                              {item?.stale ? (
                                <Badge tone="danger">Stale</Badge>
                              ) : null}
                              {item && !item.instanceId ? (
                                <Badge tone="fuzzy">Wishlist</Badge>
                              ) : null}
                              {item?.instanceId ? (
                                <Badge tone="verified">Instance</Badge>
                              ) : null}
                            </Cluster>
                          </Stack>
                          {item ? (
                            <div className="shrink-0 -mt-0.5">
                              <EntityHotspot
                                kind={SLOT_LABEL[slot] ?? slot}
                                name={item.itemName}
                                description={item.description}
                                icon={item.icon}
                                accentColor={accentFor(item.element)}
                                size={44}
                                showLabel="never"
                                meta={itemMetaChips(item)}
                              />
                            </div>
                          ) : null}
                        </Row>
                      </div>

                      <div className="min-w-0 flex items-end">
                        {item ? (
                          <Text
                            size="sm"
                            weight="medium"
                            className="leading-snug line-clamp-2"
                          >
                            {item.itemName}
                          </Text>
                        ) : (
                          <Text size="xs" tone="muted">
                            Empty — fill from catalog or inventory.
                          </Text>
                        )}
                      </div>

                      <div className="min-w-0">
                        {item ? <ItemExtras item={item} omitStats /> : null}
                      </div>

                      {ARMOR_STAT_NAMES.map((name) => (
                        <ArmorPieceStatRow
                          key={name}
                          name={name}
                          value={
                            item?.statValues
                              ? item.statValues[name]
                              : undefined
                          }
                        />
                      ))}

                      <div className={ARMOR_STAT_ROW}>
                        <Text size="xs" tone="muted" as="span">
                          {typeof item?.totalStats === "number"
                            ? `Total ${item.totalStats}${item.statsIncomplete ? " · incomplete" : ""}`
                            : item
                              ? item.instanceId
                                ? "No stats"
                                : "Wishlist"
                              : ""}
                        </Text>
                      </div>

<div className="min-w-0 pt-1 flex flex-col justify-end gap-2">
                        {item?.linkedSynergies &&
                        item.linkedSynergies.length > 0 ? (
                          <LinkedSynergiesFooter
                            synergies={item.linkedSynergies}
                          />
                        ) : null}
                        <div className="flex flex-col gap-1">
                          <Button
                            size="sm"
                            variant={item ? "outline" : "accent"}
                            className="w-full"
                            onClick={() => onFillSlot(slot)}
                          >
                            {item ? "Replace" : "Fill"}
                          </Button>
                          {item ? (
                            <Button
                              size="sm"
                              variant="danger"
                              className="w-full"
                              disabled={removeBusy === item.id}
                              onClick={() => void removeItem(item.id)}
                            >
                              {removeBusy === item.id ? "…" : "Clear"}
                            </Button>
                          ) : null}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
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
            <div className="grid gap-3 grid-cols-[repeat(auto-fit,minmax(11rem,1fr))]">
              {slotList.map((slot) => {
                const item = activeItems.find((i) => i.slot === slot);
                const empty = !item;
                return (
                  <Panel
                    key={slot}
                    tone={empty ? "default" : "muted"}
                    pad="sm"
                    className={
                      empty
                        ? "h-full border-dashed border-accent/40 bg-[color-mix(in_srgb,var(--accent)_5%,transparent)]"
                        : "h-full"
                    }
                  >
                    <Stack gap={8} className="h-full min-h-0">
                      <Row justify="between" align="start" gap={6}>
                        <Stack gap={4} className="min-w-0 flex-1 pr-1">
                          <SectionLabel>
                            {SLOT_LABEL[slot] ?? slot}
                          </SectionLabel>
                          <Cluster gap={4}>
                            {empty ? (
                              <Badge tone="unresolved">Empty</Badge>
                            ) : null}
                            {item?.isExotic ? (
                              <Badge tone="fuzzy">Exotic</Badge>
                            ) : null}
                            {item?.stale ? (
                              <Badge tone="danger">Stale</Badge>
                            ) : null}
                            {item && !item.instanceId ? (
                              <Badge tone="fuzzy">Wishlist</Badge>
                            ) : null}
                            {item?.instanceId ? (
                              <Badge tone="verified">Instance</Badge>
                            ) : null}
                          </Cluster>
                        </Stack>
                        {item ? (
                          <div className="shrink-0 -mt-0.5">
                            <EntityHotspot
                              kind={SLOT_LABEL[slot] ?? slot}
                              name={item.itemName}
                              description={item.description}
                              icon={item.icon}
                              accentColor={accentFor(item.element)}
                              size={44}
                              showLabel="never"
                              meta={itemMetaChips(item)}
                            />
                          </div>
                        ) : null}
                      </Row>

                      {item ? (
                        <Stack gap={6} className="min-w-0 flex-1">
                          <Text
                            size="sm"
                            weight="medium"
                            className="leading-snug line-clamp-2"
                          >
                            {item.itemName}
                          </Text>
                          <ItemExtras item={item} />
                        </Stack>
                      ) : (
                        <Text size="xs" tone="muted" className="flex-1">
                          Empty — fill from catalog or inventory.
                        </Text>
                      )}

                      <div className="mt-auto pt-1 flex flex-col gap-2">
                        {item?.linkedSynergies &&
                        item.linkedSynergies.length > 0 ? (
                          <LinkedSynergiesFooter
                            synergies={item.linkedSynergies}
                          />
                        ) : null}
                        <div className="flex flex-col gap-1">
                          <Button
                            size="sm"
                            variant={item ? "outline" : "accent"}
                            className="w-full"
                            onClick={() => onFillSlot(slot)}
                          >
                            {item ? "Replace" : "Fill"}
                          </Button>
                          {item ? (
                            <Button
                              size="sm"
                              variant="danger"
                              className="w-full"
                              disabled={removeBusy === item.id}
                              onClick={() => void removeItem(item.id)}
                            >
                              {removeBusy === item.id ? "…" : "Clear"}
                            </Button>
                          ) : null}
                        </div>
                      </div>
                    </Stack>
                  </Panel>
                );
              })}
            </div>
          </Section>
        )}

        {set.modEncourage ? (
          <Text size="xs" tone="warning">
            Some armor pieces may have empty mod slots.
          </Text>
        ) : null}

        {/* 4. Used by */}
        <div
          className="border px-2.5 py-2"
          style={{
            borderColor:
              usedBy.length > 0
                ? "color-mix(in srgb, var(--success) 30%, var(--line))"
                : "var(--line)",
            background:
              usedBy.length > 0
                ? "color-mix(in srgb, var(--success) 5%, var(--surface))"
                : "transparent",
          }}
        >
          <Stack gap={6}>
            <SectionLabel>
              {usedBy.length > 0
                ? `Used by builds · ${usedBy.length}`
                : "Used by builds"}
            </SectionLabel>
            {usedBy.length === 0 ? (
              <Text size="sm" tone="muted">
                Not attached to builds yet. Attach on a build variant to see it
                here.
              </Text>
            ) : (
              <Cluster gap={6}>
                {usedBy.map((b) => (
                  <Link
                    key={b.buildId}
                    href={buildDetailHref(b.buildId)}
                    className="inline-flex flex-col gap-0.5 text-[11px] px-2 py-1 border border-line bg-surface-raised text-foreground hover:border-accent hover:text-accent transition-colors max-w-[14rem]"
                    title={
                      b.variantNames.length > 0
                        ? `${b.buildName} · ${b.variantNames.join(" · ")}`
                        : b.buildName
                    }
                  >
                    <span className="truncate font-medium">{b.buildName}</span>
                    {b.variantNames.length > 0 ? (
                      <span className="truncate text-muted">
                        {b.variantNames.join(" · ")}
                      </span>
                    ) : null}
                  </Link>
                ))}
              </Cluster>
            )}
          </Stack>
        </div>
      </Stack>
    </Panel>
  );
}
