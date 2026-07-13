"use client";

import { useState } from "react";

import type {
  BuildDetail,
  BuildSubclass,
  BuildVariantDetail,
} from "@/components/build/types";
import { ManifestSearchPicker, type ManifestPick } from "@/components/lookups/ManifestSearchPicker";
import { SetAttachPicker } from "@/components/lookups/SetAttachPicker";
import {
  Button,
  Callout,
  Chip,
  Cluster,
  FilterChip,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import {
  mergeAttachment,
  removeAttachment,
  type AttachmentInput,
} from "@/lib/builds/attachmentMerge";

export type VariantEditTab =
  | "general"
  | "sets"
  | "artifact"
  | "mods"
  | "abilities"
  | "aspects"
  | "fragments";

const TABS: { id: VariantEditTab; label: string }[] = [
  { id: "general", label: "General" },
  { id: "sets", label: "Sets" },
  { id: "artifact", label: "Artifact" },
  { id: "mods", label: "Mods" },
  { id: "abilities", label: "Abilities" },
  { id: "aspects", label: "Aspects" },
  { id: "fragments", label: "Fragments" },
];

function attachmentsOf(variant: BuildVariantDetail): AttachmentInput[] {
  return variant.attachments.map((a) => ({ setId: a.setId, mode: a.mode }));
}

function toggleList(list: string[], value: string): string[] {
  return list.includes(value)
    ? list.filter((x) => x !== value)
    : [...list, value];
}

function initialExotic(variant: BuildVariantDetail): ManifestPick | null {
  return variant.exoticWeaponHash != null && variant.exoticWeaponName
    ? { hash: variant.exoticWeaponHash, name: variant.exoticWeaponName }
    : null;
}

function initialArtifact(variant: BuildVariantDetail): ManifestPick | null {
  return variant.artifactHash != null
    ? {
        hash: variant.artifactHash,
        name: variant.artifactName ?? `Artifact ${variant.artifactHash}`,
        perks: [],
      }
    : null;
}

/** Parent should pass key={variant.id} so form state resets on variant switch. */
export function VariantEditPanel({
  build,
  variant,
  onClose,
  onSaved,
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  onClose: () => void;
  onSaved: (next: BuildDetail, preferredVariantId?: string) => void;
}) {
  const [tab, setTab] = useState<VariantEditTab>("general");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const [name, setName] = useState(variant.name);
  const [notes, setNotes] = useState(variant.notes ?? "");
  const [exoticWeapon, setExoticWeapon] = useState<ManifestPick | null>(() =>
    initialExotic(variant),
  );
  const [artifact, setArtifact] = useState<ManifestPick | null>(() =>
    initialArtifact(variant),
  );
  const [selectedPerkHashes, setSelectedPerkHashes] = useState<number[]>(
    () => variant.artifactConfig ?? [],
  );
  const [subclass, setSubclass] = useState<BuildSubclass>(() => build.subclass);

  async function patchVariant(
    payload: Record<string, unknown>,
    okMessage: string,
    preferredVariantId = variant.id,
  ) {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const res = await fetch(
        `/api/user/builds/${build.id}/variants/${variant.id}`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );
      const body = (await res.json()) as {
        error?: string;
        build?: BuildDetail;
      };
      if (!res.ok || !body.build) {
        setError(body.error ?? "Failed to save variant");
        return;
      }
      setMessage(okMessage);
      onSaved(body.build, preferredVariantId);
    } catch {
      setError("Failed to save variant");
    } finally {
      setBusy(false);
    }
  }

  async function patchBuildSubclass(okMessage: string) {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ subclass }),
      });
      const body = (await res.json()) as {
        error?: string;
        code?: string;
        build?: BuildDetail;
      };
      if (res.status === 409 && body.code === "IDENTITY_CONFIRM_REQUIRED") {
        setError(
          "Subclass change needs identity confirm/fork — keep ability names within the same subclass, or edit identity from debug Builds.",
        );
        return;
      }
      if (!res.ok || !body.build) {
        setError(body.error ?? "Failed to save abilities");
        return;
      }
      setMessage(okMessage);
      onSaved(body.build, variant.id);
    } catch {
      setError("Failed to save abilities");
    } finally {
      setBusy(false);
    }
  }

  async function duplicateVariant() {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}/variants`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ duplicateFromVariantId: variant.id }),
      });
      const body = (await res.json()) as {
        error?: string;
        build?: BuildDetail;
      };
      if (!res.ok || !body.build) {
        setError(body.error ?? "Failed to duplicate variant");
        return;
      }
      setMessage("Variant duplicated");
      const previousIds = new Set(build.variants.map((v) => v.id));
      const newId =
        body.build.variants.find((v) => !previousIds.has(v.id))?.id ??
        body.build.variants.at(-1)?.id;
      onSaved(body.build, newId);
    } catch {
      setError("Failed to duplicate variant");
    } finally {
      setBusy(false);
    }
  }

  function togglePerk(hash: number) {
    setSelectedPerkHashes((prev) =>
      prev.includes(hash) ? prev.filter((h) => h !== hash) : [...prev, hash],
    );
  }

  const setCount = variant.attachments.length;
  const tabCounts: Record<VariantEditTab, number | null> = {
    general: null,
    sets: setCount,
    artifact: selectedPerkHashes.length || (artifact ? 1 : 0),
    mods: null,
    abilities: 3,
    aspects: subclass.aspects.length,
    fragments: subclass.fragments.length,
  };

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="center" gap={8} wrap>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              Edit variant · {variant.name}
            </Text>
            <Text size="xs" tone="muted">
              One section at a time. Gear comes from Sets; other tabs edit this
              variant / build subclass.
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        <Cluster gap={6}>
          {TABS.map((t) => {
            const count = tabCounts[t.id];
            return (
              <FilterChip
                key={t.id}
                label={count != null ? `${t.label} · ${count}` : t.label}
                active={tab === t.id}
                onClick={() => setTab(t.id)}
              />
            );
          })}
        </Cluster>

        {error ? <Callout tone="danger">{error}</Callout> : null}
        {message ? <Callout tone="success">{message}</Callout> : null}

        {tab === "general" ? (
          <Stack gap={12}>
            <TextField
              label="Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
            <Stack gap={4}>
              <Text size="xs" tone="muted">
                Notes
              </Text>
              <textarea
                className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground min-h-[72px]"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="When to use this variant…"
              />
            </Stack>
            <Section label="Exotic weapon override">
              <Text size="xs" tone="muted" className="mb-2">
                Optional. Overrides build-level exotic weapon for this variant.
              </Text>
              <ManifestSearchPicker
                label="Exotic weapon"
                category="exotic-weapons"
                classType={build.className}
                selected={exoticWeapon}
                onSelect={setExoticWeapon}
                disabled={busy}
              />
            </Section>
            <Row gap={8} wrap>
              <Button
                variant="accent"
                size="sm"
                disabled={busy || !name.trim()}
                onClick={() =>
                  void patchVariant(
                    {
                      name: name.trim(),
                      notes: notes.trim() || null,
                      exoticWeaponHash: exoticWeapon?.hash ?? null,
                      exoticWeaponName: exoticWeapon?.name ?? null,
                    },
                    "General saved",
                  )
                }
              >
                Save general
              </Button>
              <Button
                size="sm"
                disabled={busy}
                onClick={() => void duplicateVariant()}
              >
                Duplicate variant
              </Button>
            </Row>
          </Stack>
        ) : null}

        {tab === "sets" ? (
          <Stack gap={12}>
            <Section label="Attached">
              {variant.attachments.length === 0 ? (
                <Text size="xs" tone="muted">
                  No sets attached
                </Text>
              ) : (
                <Stack gap={6}>
                  {variant.attachments.map((a) => (
                    <Row key={a.setId} justify="between" align="center" gap={8}>
                      <Cluster gap={6}>
                        <Chip accent>{a.set?.name ?? a.setId}</Chip>
                        <Chip>{a.mode}</Chip>
                        {a.set?.type ? <Chip>{a.set.type}</Chip> : null}
                      </Cluster>
                      <Button
                        size="sm"
                        variant="danger"
                        disabled={busy}
                        onClick={() =>
                          void patchVariant(
                            {
                              attachments: removeAttachment(
                                attachmentsOf(variant),
                                a.setId,
                              ),
                            },
                            "Set detached",
                          )
                        }
                      >
                        Detach
                      </Button>
                    </Row>
                  ))}
                </Stack>
              )}
            </Section>
            <Section label="Attach set">
              <SetAttachPicker
                disabled={busy}
                excludeIds={variant.attachments.map((a) => a.setId)}
                onAttach={(attachment) =>
                  void patchVariant(
                    {
                      attachments: mergeAttachment(
                        attachmentsOf(variant),
                        attachment,
                      ),
                    },
                    "Set attached",
                  )
                }
              />
            </Section>
          </Stack>
        ) : null}

        {tab === "artifact" ? (
          <Stack gap={12}>
            <Text size="xs" tone="muted">
              Pick a seasonal artifact, then toggle perks from its grid.
            </Text>
            <ManifestSearchPicker
              label="Artifact"
              category="artifacts"
              selected={artifact}
              onSelect={(item) => {
                setArtifact(item);
                if (item?.perks?.length) {
                  setSelectedPerkHashes((prev) =>
                    prev.filter((h) => item.perks!.some((p) => p.hash === h)),
                  );
                }
              }}
              disabled={busy}
            />
            {artifact?.perks && artifact.perks.length > 0 ? (
              <Section label="Artifact perks">
                <Cluster gap={6}>
                  {artifact.perks.map((perk) => (
                    <FilterChip
                      key={perk.hash}
                      label={perk.name}
                      active={selectedPerkHashes.includes(perk.hash)}
                      onClick={() => togglePerk(perk.hash)}
                    />
                  ))}
                </Cluster>
              </Section>
            ) : artifact ? (
              <Text size="xs" tone="muted">
                Browse/search again after selecting to load perk chips when the
                manifest includes them. Selected perk hashes:{" "}
                {selectedPerkHashes.length || "none"}.
              </Text>
            ) : null}
            <Row gap={8} wrap>
              <Button
                variant="accent"
                size="sm"
                disabled={busy || !artifact}
                onClick={() =>
                  void patchVariant(
                    {
                      artifactHash: artifact!.hash,
                      artifactName: artifact!.name,
                      artifactConfig: selectedPerkHashes,
                    },
                    "Artifact saved",
                  )
                }
              >
                Save artifact
              </Button>
              <Button
                size="sm"
                disabled={busy}
                onClick={() => {
                  setArtifact(null);
                  setSelectedPerkHashes([]);
                  void patchVariant(
                    { artifactHash: null, artifactName: null, artifactConfig: [] },
                    "Artifact cleared",
                  );
                }}
              >
                Clear
              </Button>
            </Row>
          </Stack>
        ) : null}

        {tab === "mods" ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              Armor mods live on set instances and resolve through attached sets.
              Edit mod rolls on the Sets screen, then attach here.
            </Text>
            <Cluster gap={6}>
              {variant.attachments.map((a) => (
                <Chip key={a.setId} accent>
                  {a.set?.name ?? a.setId}
                </Chip>
              ))}
            </Cluster>
            {variant.attachments.length === 0 ? (
              <Text size="xs" tone="muted">
                No sets attached yet.
              </Text>
            ) : null}
          </Stack>
        ) : null}

        {tab === "abilities" ? (
          <Stack gap={12}>
            <Text size="xs" tone="muted">
              {build.subclass.name} · {build.className}. Pick from manifest
              abilities for this subclass.
            </Text>
            {(
              [
                ["melee", "Melee"],
                ["grenade", "Grenade"],
                ["classAbility", "Class ability"],
              ] as const
            ).map(([key, label]) => (
              <Stack key={key} gap={6}>
                <Text size="sm">
                  {label}: <span className="text-accent">{subclass[key]}</span>
                </Text>
                <ManifestSearchPicker
                  label={`Search ${label.toLowerCase()}`}
                  category="abilities"
                  kind={key}
                  classType={build.className}
                  subclass={build.subclass.name}
                  selected={{ hash: 0, name: subclass[key] }}
                  onSelect={(item) => {
                    if (!item) return;
                    setSubclass((s) => ({ ...s, [key]: item.name }));
                  }}
                  disabled={busy}
                />
              </Stack>
            ))}
            <Button
              variant="accent"
              size="sm"
              disabled={busy}
              onClick={() => void patchBuildSubclass("Abilities saved")}
            >
              Save abilities
            </Button>
          </Stack>
        ) : null}

        {tab === "aspects" ? (
          <Stack gap={12}>
            <Text size="xs" tone="muted">
              Toggle aspects on this build&apos;s subclass (shared across
              variants).
            </Text>
            <Cluster gap={6}>
              {subclass.aspects.map((aspect) => (
                <FilterChip
                  key={aspect}
                  label={aspect}
                  active
                  onClick={() =>
                    setSubclass((s) => ({
                      ...s,
                      aspects: toggleList(s.aspects, aspect),
                    }))
                  }
                />
              ))}
            </Cluster>
            <ManifestSearchPicker
              label="Add aspect"
              category="aspects"
              classType={build.className}
              multi
              selectedNames={subclass.aspects}
              onToggleName={(name) =>
                setSubclass((s) => ({
                  ...s,
                  aspects: toggleList(s.aspects, name),
                }))
              }
              disabled={busy}
            />
            <Button
              variant="accent"
              size="sm"
              disabled={busy}
              onClick={() => void patchBuildSubclass("Aspects saved")}
            >
              Save aspects
            </Button>
          </Stack>
        ) : null}

        {tab === "fragments" ? (
          <Stack gap={12}>
            <Text size="xs" tone="muted">
              Toggle fragments on this build&apos;s subclass (shared across
              variants).
            </Text>
            <Cluster gap={6}>
              {subclass.fragments.map((fragment) => (
                <FilterChip
                  key={fragment}
                  label={fragment}
                  active
                  onClick={() =>
                    setSubclass((s) => ({
                      ...s,
                      fragments: toggleList(s.fragments, fragment),
                    }))
                  }
                />
              ))}
            </Cluster>
            <ManifestSearchPicker
              label="Add fragment"
              category="fragments"
              multi
              selectedNames={subclass.fragments}
              onToggleName={(name) =>
                setSubclass((s) => ({
                  ...s,
                  fragments: toggleList(s.fragments, name),
                }))
              }
              disabled={busy}
            />
            <Button
              variant="accent"
              size="sm"
              disabled={busy}
              onClick={() => void patchBuildSubclass("Fragments saved")}
            >
              Save fragments
            </Button>
          </Stack>
        ) : null}
      </Stack>
    </Panel>
  );
}
