"use client";

import { useEffect, useMemo, useState } from "react";

import {
  LINK_KINDS,
  LINK_KIND_LABEL,
  type LinkKind,
  type SynergyDetail,
  type SynergyDraftLink,
} from "@/components/synergy/types";
import {
  Button,
  Callout,
  Chip,
  Cluster,
  FilterChip,
  Panel,
  Row,
  Section,
  SelectField,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { generateSynergyName, getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import type { SynergyPickerItem } from "@/lib/synergies/synergyPickerLinks";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import { compareDisplayName, sortByName } from "@/lib/sortByName";

type SubTypeOption = { name: string; description?: string };
type WeaponOption = { hash: number; name: string; description?: string };

const SORTED_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

function linksToDraft(detail: SynergyDetail): SynergyDraftLink[] {
  return detail.links.map((link) => {
    const base = {
      kind: link.kind as SynergyDraftLink["kind"],
      displayName: link.displayName,
    };
    if (link.kind === "weapon") {
      return { ...base, itemHash: link.itemHash ?? undefined };
    }
    if (link.kind === "weapon_perk") {
      return { ...base, perkHash: link.perkHash ?? undefined };
    }
    if (link.kind === "origin_trait") {
      return {
        ...base,
        originTraitName: link.originTraitName ?? undefined,
        originTraitHash: link.originTraitHash ?? undefined,
      };
    }
    return {
      ...base,
      armorSetName: link.armorSetName ?? undefined,
      bonusPieces: (link.bonusPieces === 2 || link.bonusPieces === 4
        ? link.bonusPieces
        : undefined) as 2 | 4 | undefined,
      bonusName: link.bonusName ?? undefined,
      armorSetHash: link.armorSetHash ?? undefined,
    };
  });
}

export function SynergyEditPanel({
  mode,
  initial,
  prefillType,
  onClose,
  onSaved,
}: {
  mode: "create" | "edit";
  initial?: SynergyDetail | null;
  prefillType?: string | null;
  onClose: () => void;
  onSaved: (synergy: SynergyDetail) => void;
}) {
  const [type, setType] = useState(
    (initial?.type as (typeof CREATABLE_SYNERGY_TYPES)[number]) ??
      (prefillType as (typeof CREATABLE_SYNERGY_TYPES)[number]) ??
      "verb",
  );
  const [subType, setSubType] = useState(initial?.subType ?? "");
  const [description, setDescription] = useState(initial?.description ?? "");
  const [draftLinks, setDraftLinks] = useState<SynergyDraftLink[]>(
    initial ? linksToDraft(initial) : [],
  );

  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const [subTypeSearch, setSubTypeSearch] = useState("");
  const [linkKind, setLinkKind] = useState<LinkKind>("origin_trait");
  const [linkSearch, setLinkSearch] = useState("");
  const [linkOptions, setLinkOptions] = useState<SynergyPickerItem[]>([]);
  const [weaponOptions, setWeaponOptions] = useState<WeaponOption[]>([]);
  const [selectedLink, setSelectedLink] = useState<
    SynergyPickerItem | WeaponOption | null
  >(null);

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const needsSubType = requiresSubType(type);

  useEffect(() => {
    if (!needsSubType) {
      setSubTypeOptions([]);
      return;
    }
    let cancelled = false;
    void (async () => {
      const params = new URLSearchParams({ category: type });
      if (subTypeSearch.trim()) {
        params.set("q", subTypeSearch.trim());
        params.set("limit", "100");
      }
      const res = await fetch(
        `/api/catalog/synergy-pickers/subtypes?${params}`,
      );
      if (!res.ok || cancelled) return;
      const body = (await res.json()) as { options?: SubTypeOption[] };
      const options = body.options ?? [];
      setSubTypeOptions(options);
      setSubType((prev) => prev || options[0]?.name || "");
    })();
    return () => {
      cancelled = true;
    };
  }, [type, needsSubType, subTypeSearch]);

  const previewName = useMemo(() => {
    const linkDisplayName = draftLinks[0]?.displayName ?? "Unlinked";
    return generateSynergyName({
      type,
      subType: needsSubType ? subType || null : null,
      linkDisplayName,
    });
  }, [type, subType, needsSubType, draftLinks]);

  async function searchLinks() {
    setSelectedLink(null);
    if (linkKind === "weapon") {
      const params = new URLSearchParams({
        q: linkSearch,
        limit: "30",
      });
      const res = await fetch(`/api/catalog/weapons?${params}`);
      const body = (await res.json()) as {
        items?: { hash: number; name: string; description?: string }[];
      };
      if (res.ok) {
        setWeaponOptions(
          sortByName(
            (body.items ?? []).map((i) => ({
              hash: i.hash,
              name: i.name,
              description: i.description ?? "",
            })),
          ),
        );
      }
      setLinkOptions([]);
      return;
    }
    const params = new URLSearchParams({ kind: linkKind, q: linkSearch });
    if (linkSearch.trim()) params.set("limit", "100");
    const res = await fetch(`/api/catalog/synergy-pickers/links?${params}`);
    const body = (await res.json()) as { items?: SynergyPickerItem[] };
    if (res.ok) setLinkOptions(sortByName(body.items ?? []));
    setWeaponOptions([]);
  }

  function buildLinkFromSelection(): SynergyDraftLink | null {
    if (!selectedLink) return null;
    if (linkKind === "weapon" && "hash" in selectedLink && !("kind" in selectedLink)) {
      return {
        kind: "weapon",
        displayName: selectedLink.name,
        itemHash: selectedLink.hash,
      };
    }
    const picker = selectedLink as SynergyPickerItem;
    const base = { kind: picker.kind, displayName: picker.name };
    switch (picker.kind) {
      case "origin_trait":
        return {
          ...base,
          originTraitName: picker.originTraitName,
          originTraitHash: picker.originTraitHash,
        };
      case "weapon_perk":
        return { ...base, perkHash: picker.perkHash };
      case "armor_set_bonus":
        return {
          ...base,
          armorSetName: picker.armorSetName!,
          bonusPieces: picker.bonusPieces!,
          bonusName: picker.bonusName!,
          armorSetHash: picker.armorSetHash,
        };
      default:
        return null;
    }
  }

  function addSelectedLink() {
    const link = buildLinkFromSelection();
    if (!link) {
      setError("Select a catalog link first");
      return;
    }
    setDraftLinks((prev) => [...prev, link]);
    setSelectedLink(null);
    setError(null);
  }

  async function save() {
    if (draftLinks.length === 0) {
      setError("Add at least one link");
      return;
    }
    if (needsSubType && !subType.trim()) {
      setError("Subtype is required for this synergy type");
      return;
    }
    setBusy(true);
    setError(null);
    const payload = {
      type,
      subType: needsSubType ? subType.trim() : null,
      description: description.trim(),
      links: draftLinks,
    };
    try {
      const url =
        mode === "edit" && initial
          ? `/api/user/synergies/${initial.id}`
          : "/api/user/synergies";
      const res = await fetch(url, {
        method: mode === "edit" ? "PATCH" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const body = (await res.json()) as {
        error?: string;
        synergy?: SynergyDetail;
      };
      if (!res.ok || !body.synergy) {
        setError(body.error ?? "Failed to save synergy");
        return;
      }
      onSaved(body.synergy);
    } catch {
      setError("Failed to save synergy");
    } finally {
      setBusy(false);
    }
  }

  const pickerRows =
    linkKind === "weapon" ? weaponOptions : linkOptions;

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="center" gap={8} wrap>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              {mode === "edit" ? "Edit synergy" : "New synergy"}
            </Text>
            <Text size="xs" tone="muted">
              Preview name: {previewName}
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <Section label="Type">
          <Cluster>
            {SORTED_TYPES.map((t) => (
              <FilterChip
                key={t}
                label={getSynergyTypeLabel(t)}
                active={type === t}
                onClick={() => {
                  setType(t);
                  setSubType("");
                  setSubTypeSearch("");
                }}
              />
            ))}
          </Cluster>
        </Section>

        {needsSubType ? (
          <Stack gap={8}>
            <TextField
              label="Subtype search"
              value={subTypeSearch}
              onChange={(e) => setSubTypeSearch(e.target.value)}
              placeholder="Filter subtypes…"
            />
            <SelectField
              label="Subtype"
              value={subType}
              onChange={(e) => setSubType(e.target.value)}
            >
              {subTypeOptions.length === 0 ? (
                <option value="">Loading…</option>
              ) : (
                subTypeOptions.map((opt) => (
                  <option key={opt.name} value={opt.name}>
                    {opt.name}
                  </option>
                ))
              )}
            </SelectField>
          </Stack>
        ) : null}

        <Stack gap={4}>
          <Text size="xs" tone="muted">
            Description
          </Text>
          <textarea
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground min-h-[72px]"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="How this synergy works…"
          />
        </Stack>

        <Section label="Draft links">
          {draftLinks.length === 0 ? (
            <Text size="xs" tone="muted">
              No links yet
            </Text>
          ) : (
            <Stack gap={6}>
              {draftLinks.map((link, index) => (
                <Row key={`${link.kind}-${link.displayName}-${index}`} justify="between" align="center" gap={8}>
                  <Cluster>
                    <Chip>{LINK_KIND_LABEL[link.kind] ?? link.kind}</Chip>
                    <Chip accent>{link.displayName}</Chip>
                  </Cluster>
                  <Button
                    size="sm"
                    variant="danger"
                    onClick={() =>
                      setDraftLinks((prev) =>
                        prev.filter((_, i) => i !== index),
                      )
                    }
                  >
                    Remove
                  </Button>
                </Row>
              ))}
            </Stack>
          )}
        </Section>

        <Section label="Add link">
          <Stack gap={8}>
            <SelectField
              label="Kind"
              value={linkKind}
              onChange={(e) => {
                setLinkKind(e.target.value as LinkKind);
                setSelectedLink(null);
                setLinkOptions([]);
                setWeaponOptions([]);
              }}
            >
              {LINK_KINDS.map((kind) => (
                <option key={kind} value={kind}>
                  {LINK_KIND_LABEL[kind]}
                </option>
              ))}
            </SelectField>
            <Row gap={8} align="end" wrap>
              <div className="flex-1 min-w-[160px]">
                <TextField
                  label="Search"
                  value={linkSearch}
                  onChange={(e) => setLinkSearch(e.target.value)}
                  placeholder="Search catalog…"
                />
              </div>
              <Button size="sm" onClick={() => void searchLinks()}>
                Search
              </Button>
            </Row>
            {pickerRows.length > 0 ? (
              <SelectField
                label="Result"
                value={
                  selectedLink
                    ? "hash" in selectedLink && !("kind" in selectedLink)
                      ? String(selectedLink.hash)
                      : `${(selectedLink as SynergyPickerItem).kind}-${selectedLink.name}`
                    : ""
                }
                onChange={(e) => {
                  const value = e.target.value;
                  if (linkKind === "weapon") {
                    const item =
                      weaponOptions.find((w) => String(w.hash) === value) ??
                      null;
                    setSelectedLink(item);
                    return;
                  }
                  const item =
                    linkOptions.find(
                      (o) => `${o.kind}-${o.name}` === value,
                    ) ?? null;
                  setSelectedLink(item);
                }}
              >
                <option value="">Select…</option>
                {pickerRows.map((item) => {
                  const value =
                    "hash" in item && !("kind" in item)
                      ? String(item.hash)
                      : `${(item as SynergyPickerItem).kind}-${item.name}`;
                  return (
                    <option key={value} value={value}>
                      {item.name}
                    </option>
                  );
                })}
              </SelectField>
            ) : null}
            <Button
              size="sm"
              disabled={!selectedLink}
              onClick={addSelectedLink}
            >
              Add to draft
            </Button>
          </Stack>
        </Section>

        <Row gap={8} wrap>
          <Button
            variant="accent"
            size="sm"
            disabled={busy}
            onClick={() => void save()}
          >
            {mode === "edit" ? "Save synergy" : "Create synergy"}
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
