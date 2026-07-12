"use client";

import { useEffect, useState } from "react";

import type {
  BuildDetail,
  BuildSubclass,
  BuildVariantDetail,
} from "@/components/build/types";
import { ExoticWeaponLookup } from "@/components/debug/ExoticWeaponLookup";
import { SetAttachPicker } from "@/components/debug/SetAttachPicker";
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
  const [exoticWeapon, setExoticWeapon] = useState<{
    hash: number;
    name: string;
  } | null>(
    variant.exoticWeaponHash != null && variant.exoticWeaponName
      ? { hash: variant.exoticWeaponHash, name: variant.exoticWeaponName }
      : null,
  );
  const [artifactHash, setArtifactHash] = useState(
    variant.artifactHash != null ? String(variant.artifactHash) : "",
  );
  const [artifactConfig, setArtifactConfig] = useState(
    (variant.artifactConfig ?? []).join(","),
  );
  const [subclass, setSubclass] = useState<BuildSubclass>(build.subclass);

  useEffect(() => {
    setName(variant.name);
    setNotes(variant.notes ?? "");
    setExoticWeapon(
      variant.exoticWeaponHash != null && variant.exoticWeaponName
        ? { hash: variant.exoticWeaponHash, name: variant.exoticWeaponName }
        : null,
    );
    setArtifactHash(
      variant.artifactHash != null ? String(variant.artifactHash) : "",
    );
    setArtifactConfig((variant.artifactConfig ?? []).join(","));
    setSubclass(build.subclass);
    setError(null);
    setMessage(null);
  }, [variant, build.subclass]);

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
          "Subclass change needs identity confirm/fork — use debug Builds for now, or keep ability names within the same subclass.",
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

  const setCount = variant.attachments.length;
  const tabCounts: Record<VariantEditTab, number | null> = {
    general: null,
    sets: setCount,
    artifact: variant.artifactConfig?.length ?? (variant.artifactHash ? 1 : 0),
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
              <ExoticWeaponLookup
                className={build.className}
                selected={exoticWeapon}
                onSelect={setExoticWeapon}
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
              Seasonal artifact hash and selected perk hashes (comma-separated).
            </Text>
            <TextField
              label="Artifact hash"
              value={artifactHash}
              onChange={(e) => setArtifactHash(e.target.value)}
              placeholder="Manifest artifact hash"
            />
            <TextField
              label="Perk config"
              value={artifactConfig}
              onChange={(e) => setArtifactConfig(e.target.value)}
              placeholder="e.g. 123,456,789"
            />
            {variant.artifactName ? (
              <Text size="sm">Current: {variant.artifactName}</Text>
            ) : null}
            <Row gap={8} wrap>
              <Button
                variant="accent"
                size="sm"
                disabled={busy || !artifactHash.trim()}
                onClick={() => {
                  const hash = Number(artifactHash.trim());
                  if (!Number.isFinite(hash)) {
                    setError("Artifact hash must be a number");
                    return;
                  }
                  const config = artifactConfig
                    .split(",")
                    .map((s) => Number(s.trim()))
                    .filter((n) => Number.isFinite(n) && n > 0);
                  void patchVariant(
                    { artifactHash: hash, artifactConfig: config },
                    "Artifact saved",
                  );
                }}
              >
                Save artifact
              </Button>
              <Button
                size="sm"
                disabled={busy}
                onClick={() =>
                  void patchVariant(
                    { artifactHash: null, artifactConfig: [] },
                    "Artifact cleared",
                  )
                }
              >
                Clear
              </Button>
            </Row>
          </Stack>
        ) : null}

        {tab === "mods" ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              Armor mods live on set instances and resolve through attached
              sets. Edit mod rolls on the Sets screen, then attach here.
            </Text>
            <Cluster gap={6}>
              {variant.attachments.map((a) => (
                <Chip key={a.setId} accent>
                  {a.set?.name ?? a.setId}
                </Chip>
              ))}
            </Cluster>
          </Stack>
        ) : null}

        {tab === "abilities" ? (
          <Stack gap={12}>
            <TextField
              label="Melee"
              value={subclass.melee}
              onChange={(e) =>
                setSubclass((s) => ({ ...s, melee: e.target.value }))
              }
            />
            <TextField
              label="Grenade"
              value={subclass.grenade}
              onChange={(e) =>
                setSubclass((s) => ({ ...s, grenade: e.target.value }))
              }
            />
            <TextField
              label="Class ability"
              value={subclass.classAbility}
              onChange={(e) =>
                setSubclass((s) => ({ ...s, classAbility: e.target.value }))
              }
            />
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
            <TextField
              label="Add aspect"
              placeholder="Aspect name"
              onKeyDown={(e) => {
                if (e.key !== "Enter") return;
                const value = (e.target as HTMLInputElement).value.trim();
                if (!value) return;
                setSubclass((s) => ({
                  ...s,
                  aspects: s.aspects.includes(value)
                    ? s.aspects
                    : [...s.aspects, value],
                }));
                (e.target as HTMLInputElement).value = "";
              }}
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
            <TextField
              label="Add fragment"
              placeholder="Fragment name"
              onKeyDown={(e) => {
                if (e.key !== "Enter") return;
                const value = (e.target as HTMLInputElement).value.trim();
                if (!value) return;
                setSubclass((s) => ({
                  ...s,
                  fragments: s.fragments.includes(value)
                    ? s.fragments
                    : [...s.fragments, value],
                }));
                (e.target as HTMLInputElement).value = "";
              }}
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
