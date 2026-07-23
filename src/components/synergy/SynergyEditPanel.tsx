"use client";

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";

import {
  LINK_KINDS,
  LINK_KIND_LABEL,
  type LinkKind,
  type SynergyDetail,
  type SynergyDraftLink,
} from "@/components/synergy/types";
import {
  Badge,
  Button,
  Callout,
  Chip,
  Cluster,
  DesignationLabel,
  FilterChip,
  Panel,
  Row,
  Section,
  SelectField,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import {
  filterOutLinkedPickerItems,
  filterOutLinkedWeapons,
  pickerItemToMergeable,
} from "@/lib/synergies/filterLinkedPickerResults";
import {
  formatSynergyTypeDesignation,
  generateSynergyName,
  getSynergyTypeLabel,
} from "@/lib/synergies/generateSynergyName";
import { linkDedupeKey } from "@/lib/synergies/mergeSynergies";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import type { SynergyPickerItem } from "@/lib/synergies/synergyPickerLinks";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import { sortByName } from "@/lib/sortByName";

type SubTypeOption = { name: string; description?: string };
type WeaponOption = { hash: number; name: string; description?: string };

type CreatableType = (typeof CREATABLE_SYNERGY_TYPES)[number];

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

const LINK_SEARCH_DEBOUNCE_MS = 320;
const SUBTYPE_SEARCH_DEBOUNCE_MS = 250;

function linksToDraft(detail: SynergyDetail): SynergyDraftLink[] {
  return detail.links.map((link) => {
    const base = {
      kind: link.kind as SynergyDraftLink["kind"],
      displayName: link.displayName,
    };
    if (link.kind === "weapon" || link.kind === "exotic_armor") {
      return { ...base, itemHash: link.itemHash ?? undefined };
    }
    if (link.kind === "weapon_perk" || link.kind === "artifact_perk") {
      return {
        ...base,
        perkHash: link.perkHash ?? undefined,
        parentItemHash: link.parentItemHash ?? undefined,
      };
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

function draftLinksEqual(a: SynergyDraftLink[], b: SynergyDraftLink[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (linkDedupeKey(a[i]!) !== linkDedupeKey(b[i]!)) return false;
  }
  return true;
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
  const baseline = useMemo(() => {
    if (mode === "edit" && initial) {
      return {
        type: initial.type as (typeof CREATABLE_SYNERGY_TYPES)[number],
        subType: initial.subType ?? "",
        description: initial.description ?? "",
        links: linksToDraft(initial),
      };
    }
    return {
      type:
        (prefillType as (typeof CREATABLE_SYNERGY_TYPES)[number]) ?? "verb",
      subType: "",
      description: "",
      links: [] as SynergyDraftLink[],
    };
  }, [mode, initial, prefillType]);

  const [type, setType] = useState(baseline.type);
  const [subType, setSubType] = useState(baseline.subType);
  const [description, setDescription] = useState(baseline.description);
  const [draftLinks, setDraftLinks] = useState<SynergyDraftLink[]>(
    baseline.links,
  );

  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const [subTypeSearch, setSubTypeSearch] = useState("");
  const [debouncedSubTypeSearch, setDebouncedSubTypeSearch] = useState("");
  const [linkKind, setLinkKind] = useState<LinkKind>("origin_trait");
  const [linkSearch, setLinkSearch] = useState("");
  const [linkOptions, setLinkOptions] = useState<SynergyPickerItem[]>([]);
  const [weaponOptions, setWeaponOptions] = useState<WeaponOption[]>([]);
  const [selectedLink, setSelectedLink] = useState<
    SynergyPickerItem | WeaponOption | null
  >(null);
  const [linkSearchBusy, setLinkSearchBusy] = useState(false);
  const [linkSearchTouched, setLinkSearchTouched] = useState(false);
  const [discardConfirmOpen, setDiscardConfirmOpen] = useState(false);

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldError, setFieldError] = useState<
    "links" | "subtype" | "selection" | null
  >(null);

  const errorRef = useRef<HTMLDivElement | null>(null);
  const draftLinksRef = useRef<HTMLDivElement | null>(null);
  const subtypeRef = useRef<HTMLDivElement | null>(null);
  const addLinkRef = useRef<HTMLDivElement | null>(null);
  const linkSearchSeq = useRef(0);

  const needsSubType = requiresSubType(type);

  const isDirty = useMemo(() => {
    if (mode === "create") {
      // Auto-filled subtype alone is not dirty — notes, links, or type change are.
      return (
        description.trim().length > 0 ||
        draftLinks.length > 0 ||
        type !== baseline.type
      );
    }
    return (
      description.trim() !== baseline.description.trim() ||
      !draftLinksEqual(draftLinks, baseline.links)
    );
  }, [mode, description, draftLinks, type, baseline]);

  useEffect(() => {
    const t = window.setTimeout(() => {
      setDebouncedSubTypeSearch(subTypeSearch);
    }, SUBTYPE_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(t);
  }, [subTypeSearch]);

  useEffect(() => {
    if (!needsSubType) {
      return;
    }
    let cancelled = false;
    void (async () => {
      const params = new URLSearchParams({ category: type });
      if (debouncedSubTypeSearch.trim()) {
        params.set("q", debouncedSubTypeSearch.trim());
        params.set("limit", "100");
      }
      const res = await fetch(
        `/api/catalog/synergy-pickers/subtypes?${params}`,
      );
      if (!res.ok || cancelled) return;
      const body = (await res.json()) as { options?: SubTypeOption[] };
      const options = body.options ?? [];
      if (cancelled) return;
      setSubTypeOptions(options);
      setSubType((prev) => prev || options[0]?.name || "");
    })();
    return () => {
      cancelled = true;
    };
  }, [type, needsSubType, debouncedSubTypeSearch]);

  const designationTitle = useMemo(
    () =>
      formatSynergyTypeDesignation({
        type,
        subType: needsSubType ? subType || null : null,
      }),
    [type, subType, needsSubType],
  );

  const previewName = useMemo(() => {
    const linkDisplayName = draftLinks[0]?.displayName ?? "Unlinked";
    return generateSynergyName({
      type,
      subType: needsSubType ? subType || null : null,
      linkDisplayName,
    });
  }, [type, subType, needsSubType, draftLinks]);

  const runLinkSearch = useCallback(
    async (query: string, kind: LinkKind) => {
      const seq = ++linkSearchSeq.current;
      setLinkSearchBusy(true);
      setSelectedLink(null);
      try {
        if (kind === "weapon") {
          const params = new URLSearchParams({
            q: query,
            limit: "30",
          });
          const res = await fetch(`/api/catalog/weapons?${params}`);
          if (seq !== linkSearchSeq.current) return;
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
          } else {
            setWeaponOptions([]);
          }
          setLinkOptions([]);
          return;
        }
        const params = new URLSearchParams({ kind, q: query });
        if (query.trim()) params.set("limit", "100");
        const res = await fetch(
          `/api/catalog/synergy-pickers/links?${params}`,
        );
        if (seq !== linkSearchSeq.current) return;
        const body = (await res.json()) as { items?: SynergyPickerItem[] };
        if (res.ok) setLinkOptions(sortByName(body.items ?? []));
        else setLinkOptions([]);
        setWeaponOptions([]);
      } finally {
        if (seq === linkSearchSeq.current) setLinkSearchBusy(false);
      }
    },
    [],
  );

  // Debounced catalog search after the field has been used (or kind changed post-touch).
  useEffect(() => {
    if (!linkSearchTouched) return;
    const t = window.setTimeout(() => {
      void runLinkSearch(linkSearch, linkKind);
    }, LINK_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(t);
  }, [linkSearch, linkKind, linkSearchTouched, runLinkSearch]);

  function focusField(target: "links" | "subtype" | "selection") {
    const node =
      target === "links"
        ? draftLinksRef.current
        : target === "subtype"
          ? subtypeRef.current
          : addLinkRef.current;
    window.requestAnimationFrame(() => {
      errorRef.current?.scrollIntoView({ block: "nearest", behavior: "smooth" });
      node?.scrollIntoView({ block: "nearest", behavior: "smooth" });
      const focusable = node?.querySelector<HTMLElement>(
        "button, input, select, textarea, [tabindex]:not([tabindex='-1'])",
      );
      // Keep focus on the invalid control so keyboard users can fix it immediately.
      (focusable ?? errorRef.current)?.focus();
    });
  }

  function setValidationError(
    message: string,
    target: "links" | "subtype" | "selection",
  ) {
    setError(message);
    setFieldError(target);
    focusField(target);
  }

  function buildLinkFromSelection(): SynergyDraftLink | null {
    if (!selectedLink) return null;
    if (
      linkKind === "weapon" &&
      "hash" in selectedLink &&
      !("kind" in selectedLink)
    ) {
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
        return { ...base, perkHash: picker.perkHash ?? picker.hash };
      case "armor_set_bonus":
        return {
          ...base,
          armorSetName: picker.armorSetName!,
          bonusPieces: picker.bonusPieces!,
          bonusName: picker.bonusName!,
          armorSetHash: picker.armorSetHash,
        };
      case "exotic_armor":
        return {
          ...base,
          itemHash: picker.hash,
        };
      case "artifact_perk":
        return {
          ...base,
          perkHash: picker.perkHash ?? picker.hash,
          parentItemHash: picker.parentItemHash,
        };
      default:
        return null;
    }
  }

  function addSelectedLink() {
    const link = buildLinkFromSelection();
    if (!link) {
      setValidationError(
        `Choose a ${LINK_KIND_LABEL[linkKind] ?? "catalog"} result, then add it to this designation.`,
        "selection",
      );
      return;
    }
    const key = linkDedupeKey(link);
    if (draftLinks.some((d) => linkDedupeKey(d) === key)) {
      setValidationError(
        `${link.displayName} is already linked on this designation.`,
        "selection",
      );
      setSelectedLink(null);
      return;
    }
    setDraftLinks((prev) => [...prev, link]);
    setSelectedLink(null);
    setError(null);
    setFieldError(null);
  }

  async function save() {
    if (draftLinks.length === 0) {
      setValidationError(
        "Link at least one catalog object so Build can cover this designation.",
        "links",
      );
      return;
    }
    if (needsSubType && !subType.trim()) {
      setValidationError(
        "Pick a subtype for this designation (e.g. Scorch under Verb).",
        "subtype",
      );
      return;
    }
    setBusy(true);
    setError(null);
    setFieldError(null);
    // Edit: omit type/subType — designation is immutable after create.
    const payload =
      mode === "edit"
        ? {
            description: description.trim(),
            links: draftLinks,
          }
        : {
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
        setFieldError(null);
        errorRef.current?.focus();
        return;
      }
      onSaved(body.synergy);
    } catch {
      setError("Failed to save synergy");
      setFieldError(null);
      errorRef.current?.focus();
    } finally {
      setBusy(false);
    }
  }

  function requestClose() {
    if (busy) return;
    if (isDirty) {
      setDiscardConfirmOpen(true);
      return;
    }
    onClose();
  }

  function confirmDiscard() {
    setDiscardConfirmOpen(false);
    onClose();
  }

  const pickerRows = useMemo(() => {
    if (linkKind === "weapon") {
      return filterOutLinkedWeapons(weaponOptions, draftLinks);
    }
    return filterOutLinkedPickerItems(linkOptions, draftLinks);
  }, [linkKind, weaponOptions, linkOptions, draftLinks]);

  // Drop selection if it is now filtered out (already linked).
  useEffect(() => {
    if (!selectedLink) return;
    if (
      linkKind === "weapon" &&
      "hash" in selectedLink &&
      !("kind" in selectedLink)
    ) {
      const stillVisible = pickerRows.some(
        (row) =>
          "hash" in row &&
          !("kind" in row) &&
          (row as { hash: number }).hash === selectedLink.hash,
      );
      if (!stillVisible) setSelectedLink(null);
      return;
    }
    const key = linkDedupeKey(
      pickerItemToMergeable(selectedLink as SynergyPickerItem),
    );
    const stillVisible = (pickerRows as SynergyPickerItem[]).some(
      (row) =>
        "kind" in row && linkDedupeKey(pickerItemToMergeable(row)) === key,
    );
    if (!stillVisible) setSelectedLink(null);
  }, [selectedLink, pickerRows, linkKind]);

  function onLinkSearchKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter") {
      e.preventDefault();
      setLinkSearchTouched(true);
      void runLinkSearch(linkSearch, linkKind);
    }
  }

  const controlClass =
    "w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground min-h-[72px]";

  return (
    <Panel tone="default" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={8} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Text size="sm" weight="medium">
              {mode === "edit" ? "Edit designation" : "New designation"}
            </Text>
            <div className="sticky top-0 z-10 -mx-1 px-1 py-1 bg-surface/95 backdrop-blur-sm border-b border-line/60">
              <Stack gap={4}>
                <Row gap={6} align="center" wrap>
                  <DesignationLabel
                    type={type}
                    subType={needsSubType ? subType || null : null}
                    size={28}
                    className="text-sm font-medium text-foreground"
                  />
                  {mode === "edit" ? (
                    <Badge tone="verified" title="Type and subtype locked">
                      Locked
                    </Badge>
                  ) : (
                    <Badge tone="accent" title="Shown on Build coverage">
                      Preview
                    </Badge>
                  )}
                </Row>
                <Text size="xs" tone="muted">
                  {designationTitle}
                  {draftLinks.length > 0
                    ? ` · library name preview: ${previewName}`
                    : " · links feed Build coverage for this type/subtype"}
                </Text>
              </Stack>
            </div>
          </Stack>
          <Button
            size="sm"
            variant="ghost"
            onClick={requestClose}
            disabled={busy}
          >
            Close
          </Button>
        </Row>

        {error ? (
          <div ref={errorRef} tabIndex={-1} className="outline-none">
            <Callout tone="danger">{error}</Callout>
          </div>
        ) : null}

        {discardConfirmOpen ? (
          <div role="region" aria-label="Discard unsaved changes">
            <Panel tone="warning" pad="md">
              <Stack gap={8}>
                <Text size="sm" weight="medium" tone="warning">
                  Discard unsaved changes?
                </Text>
                <Text size="sm" tone="muted">
                  Closing drops edits to description and linked objects for this
                  designation. This cannot be undone.
                </Text>
                <Row gap={8} wrap>
                  <Button
                    size="sm"
                    variant="danger"
                    disabled={busy}
                    onClick={confirmDiscard}
                  >
                    Discard
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    disabled={busy}
                    onClick={() => setDiscardConfirmOpen(false)}
                  >
                    Keep editing
                  </Button>
                </Row>
              </Stack>
            </Panel>
          </div>
        ) : null}

        {mode === "edit" ? (
          <Section label="Designation">
            <Text size="xs" tone="muted">
              Type and subtype stay fixed after create. Update notes and linked
              catalog objects only — Build still matches this designation by
              type/subtype.
            </Text>
          </Section>
        ) : (
          <>
            <Section label="Type">
              <Stack gap={10}>
                {TYPE_FAMILIES.map((family) => (
                  <Stack key={family.label} gap={4}>
                    <Text size="xs" tone="muted">
                      {family.label}
                    </Text>
                    <Cluster>
                      {family.types.map((t) => (
                        <FilterChip
                          key={t}
                          label={getSynergyTypeLabel(t)}
                          active={type === t}
                          onClick={() => {
                            setType(t);
                            setSubType("");
                            setSubTypeSearch("");
                            setError(null);
                            setFieldError(null);
                          }}
                        />
                      ))}
                    </Cluster>
                  </Stack>
                ))}
              </Stack>
            </Section>

            {needsSubType ? (
              <div ref={subtypeRef}>
                <Stack gap={8}>
                  <TextField
                    label="Subtype search"
                    value={subTypeSearch}
                    onChange={(e) => setSubTypeSearch(e.target.value)}
                    placeholder="Filter subtypes…"
                    aria-invalid={fieldError === "subtype" || undefined}
                  />
                  <SelectField
                    label="Subtype"
                    value={subType}
                    onChange={(e) => {
                      setSubType(e.target.value);
                      if (fieldError === "subtype") {
                        setFieldError(null);
                        setError(null);
                      }
                    }}
                    aria-invalid={fieldError === "subtype" || undefined}
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
              </div>
            ) : null}
          </>
        )}

        <Stack gap={4}>
          <label htmlFor="synergy-description" className="block space-y-1">
            <Text size="xs" tone="muted" as="span">
              Notes
            </Text>
          </label>
          <textarea
            id="synergy-description"
            className={controlClass}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="How this designation plays — optional notes for you"
            rows={3}
          />
        </Stack>

        {/* Add link first so draft growth does not push search/results down */}
        <div ref={addLinkRef}>
          <Section label="Add catalog link">
            <Stack gap={8}>
              <Text size="xs" tone="muted">
                Search the vault catalog, pick a result, then add it. Objects
                already on this designation are hidden from results.
              </Text>
              <SelectField
                label="Kind"
                value={linkKind}
                onChange={(e) => {
                  setLinkKind(e.target.value as LinkKind);
                  setSelectedLink(null);
                  setLinkOptions([]);
                  setWeaponOptions([]);
                  setLinkSearchTouched(false);
                  setLinkSearch("");
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
                    label="Search catalog"
                    value={linkSearch}
                    onChange={(e) => {
                      setLinkSearch(e.target.value);
                      setLinkSearchTouched(true);
                    }}
                    onKeyDown={onLinkSearchKeyDown}
                    placeholder="Type to search — Enter runs now"
                    autoComplete="off"
                    aria-invalid={fieldError === "selection" || undefined}
                  />
                </div>
                <Button
                  size="sm"
                  onClick={() => {
                    setLinkSearchTouched(true);
                    void runLinkSearch(linkSearch, linkKind);
                  }}
                  disabled={linkSearchBusy}
                >
                  {linkSearchBusy ? "Searching…" : "Search"}
                </Button>
              </Row>
              {linkSearchBusy && pickerRows.length === 0 ? (
                <Text size="xs" tone="muted">
                  Searching catalog…
                </Text>
              ) : null}
              {!linkSearchBusy &&
              linkSearchTouched &&
              pickerRows.length === 0 ? (
                <Text size="xs" tone="muted">
                  No unmatched {LINK_KIND_LABEL[linkKind]?.toLowerCase() ?? "items"}{" "}
                  for this query. Try another term or kind.
                </Text>
              ) : null}
              {pickerRows.length > 0 ? (
                <Stack gap={4} className="max-h-48 overflow-auto">
                  <Text size="xs" tone="muted">
                    Results · {pickerRows.length}
                    {selectedLink ? " · pick highlighted, then Add" : ""}
                  </Text>
                  {pickerRows.map((item) => {
                    const picker = item as
                      | SynergyPickerItem
                      | {
                          hash: number;
                          name: string;
                          description?: string;
                        };
                    const value =
                      "hash" in item && !("kind" in item)
                        ? String(item.hash)
                        : "kind" in picker && picker.kind === "artifact_perk"
                          ? `artifact_perk-${(picker as SynergyPickerItem).perkHash ?? picker.hash}-${(picker as SynergyPickerItem).parentItemHash ?? ""}`
                          : `${(picker as SynergyPickerItem).kind}-${item.name}`;
                    const selectedValue = selectedLink
                      ? "hash" in selectedLink && !("kind" in selectedLink)
                        ? String(selectedLink.hash)
                        : selectedLink &&
                            "kind" in selectedLink &&
                            selectedLink.kind === "artifact_perk"
                          ? `artifact_perk-${selectedLink.perkHash ?? selectedLink.hash}-${selectedLink.parentItemHash ?? ""}`
                          : `${(selectedLink as SynergyPickerItem).kind}-${selectedLink.name}`
                      : "";
                    const active = selectedValue === value;
                    const itemDescription =
                      "description" in item &&
                      typeof item.description === "string"
                        ? item.description.trim()
                        : "";
                    const artifactName =
                      "artifactName" in item &&
                      typeof item.artifactName === "string"
                        ? item.artifactName.trim()
                        : "";
                    const sourceLabel =
                      "sourceLabel" in item &&
                      typeof (item as SynergyPickerItem).sourceLabel ===
                        "string"
                        ? (item as SynergyPickerItem).sourceLabel!.trim()
                        : "";
                    return (
                      <button
                        key={value}
                        type="button"
                        className={`text-left px-2 py-1.5 text-sm border ${
                          active
                            ? "border-accent bg-accent/10 text-foreground"
                            : "border-line bg-surface-raised hover:border-line-strong text-foreground"
                        }`}
                        onClick={() => {
                          if (linkKind === "weapon") {
                            const found =
                              weaponOptions.find(
                                (w) => String(w.hash) === value,
                              ) ?? null;
                            setSelectedLink(found);
                            if (fieldError === "selection") {
                              setFieldError(null);
                              setError(null);
                            }
                            return;
                          }
                          const found =
                            linkOptions.find((o) => {
                              if (o.kind === "artifact_perk") {
                                return (
                                  `artifact_perk-${o.perkHash ?? o.hash}-${o.parentItemHash ?? ""}` ===
                                  value
                                );
                              }
                              return `${o.kind}-${o.name}` === value;
                            }) ?? null;
                          setSelectedLink(found);
                          if (fieldError === "selection") {
                            setFieldError(null);
                            setError(null);
                          }
                        }}
                      >
                        <span className="font-medium">{item.name}</span>
                        {sourceLabel ? (
                          <span className="block text-[10px] tracking-wide uppercase text-muted mt-0.5">
                            {sourceLabel}
                          </span>
                        ) : artifactName ? (
                          <span className="block text-[10px] tracking-wide uppercase text-muted mt-0.5">
                            {artifactName}
                          </span>
                        ) : null}
                        {itemDescription ? (
                          <span
                            className="block text-xs text-muted leading-snug line-clamp-2 mt-0.5"
                            title={itemDescription}
                          >
                            {itemDescription}
                          </span>
                        ) : null}
                      </button>
                    );
                  })}
                </Stack>
              ) : null}
              <Button
                size="sm"
                disabled={!selectedLink}
                onClick={addSelectedLink}
              >
                Add to designation
              </Button>
            </Stack>
          </Section>
        </div>

        <div ref={draftLinksRef}>
          <Section label="Linked objects">
            {draftLinks.length === 0 ? (
              <Stack gap={6}>
                <Text size="sm" tone="muted">
                  No catalog evidence yet.
                </Text>
                <Text size="xs" tone="muted">
                  Add weapons, perks, armor, or artifact rows above. Build uses
                  these links to show coverage for{" "}
                  <strong>{designationTitle}</strong>.
                </Text>
                {fieldError === "links" ? (
                  <Badge tone="danger">Required to save</Badge>
                ) : null}
              </Stack>
            ) : (
              <Stack
                gap={6}
                className="max-h-40 overflow-y-auto overscroll-contain"
              >
                {draftLinks.map((link, index) => (
                  <Row
                    key={`${link.kind}-${link.displayName}-${index}`}
                    justify="between"
                    align="center"
                    gap={8}
                  >
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
        </div>

        <Row gap={8} wrap>
          <Button
            variant="accent"
            size="sm"
            disabled={busy}
            onClick={() => void save()}
          >
            {busy
              ? "Saving…"
              : mode === "edit"
                ? "Save designation"
                : "Create designation"}
          </Button>
          {isDirty ? (
            <Text size="xs" tone="muted" as="span">
              Unsaved changes
            </Text>
          ) : null}
        </Row>
      </Stack>
    </Panel>
  );
}
