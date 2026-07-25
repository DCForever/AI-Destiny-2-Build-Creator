"use client";

import { useState } from "react";

import type { BuildDetail, BuildVariantDetail, GuardianClass } from "@/components/build/types";
import {
  SynergyTypeMultiSelect,
  type SynergyTypeSelection,
} from "@/components/build/SynergyTypeMultiSelect";
import {
  ManifestSearchPicker,
  type ManifestPick,
} from "@/components/lookups/ManifestSearchPicker";
import {
  Button,
  Cluster,
  ClassFilterChip,
  Section,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { formatSubclassLabel } from "@/data/subclasses";
import {
  defaultSubclassForClass,
  pinnedSuperAfterSubclassChange,
  subclassAfterClassChange,
  subclassesForClass,
} from "@/lib/build/createBuildLookups";
import { createBuildPayload } from "@/lib/build/createBuildPayload";
import { fetchSubclassKitForCreate } from "@/lib/build/createSubclassKit";
import { resolveSubclassScope } from "@/lib/debug/subclassScope";
import type { ComposerMode } from "@/components/build/composer/types";

const CLASSES: GuardianClass[] = ["Titan", "Hunter", "Warlock"];

export function GeneralTab({
  mode,
  build,
  variant,
  busy,
  onDraftClass,
  onDraftSubclass,
  onCreate,
  onSaved,
  onMessage,
  onError,
}: {
  mode: ComposerMode;
  build: BuildDetail | null;
  variant: BuildVariantDetail | null;
  busy: boolean;
  onDraftClass: (c: GuardianClass | null) => void;
  onDraftSubclass: (s: string | null) => void;
  onCreate: (input: ReturnType<typeof createBuildPayload>) => void;
  onSaved: (next: BuildDetail, preferredVariantId?: string) => void;
  onMessage: (m: string | null) => void;
  onError: (e: string | null) => void;
}) {
  const [name, setName] = useState(build?.name ?? "");
  const [className, setClassName] = useState<GuardianClass>(build?.className ?? "Titan");
  const [subclassName, setSubclassName] = useState(
    build?.subclass?.name ?? defaultSubclassForClass(build?.className ?? "Titan"),
  );
  const [pinnedSuper, setPinnedSuper] = useState<string | null>(build?.pinnedSuper ?? null);
  const [exotic, setExotic] = useState<{ hash: number; name: string } | null>(
    build?.exoticArmorHash != null && build.exoticArmorName
      ? { hash: build.exoticArmorHash, name: build.exoticArmorName }
      : null,
  );
  const [synergyTypes, setSynergyTypes] = useState<SynergyTypeSelection[]>(
    (build?.synergyTypes as SynergyTypeSelection[] | undefined) ?? [],
  );
  const [artifact, setArtifact] = useState<ManifestPick | null>(
    variant?.artifactHash != null
      ? {
          hash: variant.artifactHash,
          name: variant.artifactName ?? `Artifact ${variant.artifactHash}`,
          perks: [],
        }
      : null,
  );
  const [perkHashes, setPerkHashes] = useState<number[]>(variant?.artifactConfig ?? []);
  const [sourcingKit, setSourcingKit] = useState(false);
  const [saveBusy, setSaveBusy] = useState(false);

  const subclassScope = resolveSubclassScope(subclassName);
  const canCreate = synergyTypes.length > 0 && !busy && !sourcingKit;

  function handleClassChange(next: GuardianClass) {
    setClassName(next);
    onDraftClass(next);
    setSubclassName((prev) => {
      const nextSubclass = subclassAfterClassChange(next, prev);
      onDraftSubclass(nextSubclass);
      setPinnedSuper((pin) => pinnedSuperAfterSubclassChange(prev, nextSubclass, pin));
      return nextSubclass;
    });
    setExotic(null);
  }

  function handleSubclassChange(next: string) {
    setSubclassName((prev) => {
      onDraftSubclass(next);
      setPinnedSuper((pin) => pinnedSuperAfterSubclassChange(prev, next, pin));
      return next;
    });
  }

  async function handleCreate() {
    onError(null);
    setSourcingKit(true);
    try {
      const subclassDefaults = await fetchSubclassKitForCreate(subclassName, pinnedSuper);
      onCreate(
        createBuildPayload({
          name,
          className,
          subclassName,
          pinnedSuper,
          exotic,
          synergyTypes,
          subclassDefaults,
        }),
      );
    } catch (err) {
      onError(err instanceof Error ? err.message : "Failed to source subclass kit");
    } finally {
      setSourcingKit(false);
    }
  }

  async function handleLiveIdentitySave() {
    if (!build) return;
    setSaveBusy(true);
    onError(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: name.trim() || build.name,
          synergyTypes,
          pinnedSuper,
          exoticArmorHash: exotic?.hash ?? null,
          exoticArmorName: exotic?.name ?? null,
        }),
      });
      const body = (await res.json()) as { build?: BuildDetail; error?: string };
      if (!res.ok || !body.build) {
        onError(body.error ?? "Failed to save identity");
        return;
      }
      if (variant && artifact) {
        const vr = await fetch(`/api/user/builds/${build.id}/variants/${variant.id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            artifactHash: artifact.hash,
            artifactName: artifact.name,
            artifactConfig: perkHashes,
          }),
        });
        const vb = (await vr.json()) as { build?: BuildDetail; error?: string };
        if (!vr.ok) {
          onError(vb.error ?? "Failed to save artifact");
          return;
        }
        if (vb.build) {
          onSaved(vb.build, variant.id);
          onMessage("General saved");
          return;
        }
      }
      onSaved(body.build, variant?.id);
      onMessage("General saved");
    } catch {
      onError("Failed to save");
    } finally {
      setSaveBusy(false);
    }
  }

  return (
    <Stack gap={12}>
      <Section label="Identity">
        <TextField
          label="Name (optional)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Auto-derived if empty"
        />
        <Section label="Class">
          <Cluster>
            {CLASSES.map((cls) => (
              <ClassFilterChip
                key={cls}
                className={cls}
                active={className === cls}
                onClick={() => handleClassChange(cls)}
                size="md"
              />
            ))}
          </Cluster>
        </Section>
        <Section label="Subclass">
          <select
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground"
            value={subclassName}
            onChange={(e) => handleSubclassChange(e.target.value)}
          >
            {subclassesForClass(className).map((s) => (
              <option key={s} value={s}>
                {formatSubclassLabel(s)}
              </option>
            ))}
          </select>
        </Section>
        <Section label="Pinned super (optional)">
          <ManifestSearchPicker
            label="Search supers"
            category="abilities"
            kind="super"
            classType={subclassScope?.classType ?? className}
            element={subclassScope?.element}
            subclass={subclassName}
            selected={pinnedSuper ? ({ hash: 0, name: pinnedSuper } satisfies ManifestPick) : null}
            onSelect={(item) => setPinnedSuper(item?.name ?? null)}
          />
        </Section>
        <Section label="Exotic armor">
          <ManifestSearchPicker
            label="Search exotic armor"
            category="exotic-armor"
            classType={className}
            selected={exotic}
            onSelect={(item) =>
              setExotic(item ? { hash: item.hash, name: item.name } : null)
            }
          />
        </Section>
      </Section>

      <Section label="Synergy types (required)">
        <Text size="xs" tone="muted" className="mb-2">
          Intent only — soft guidance never auto-applies.
        </Text>
        <SynergyTypeMultiSelect selected={synergyTypes} onChange={setSynergyTypes} />
      </Section>

      {mode === "live" ? (
        <Section label="Artifact">
          <ManifestSearchPicker
            label="Artifact"
            category="artifacts"
            selected={artifact}
            onSelect={(item) => {
              setArtifact(item);
              if (item?.perks?.length) {
                setPerkHashes((prev) =>
                  prev.filter((h) => item.perks!.some((p) => p.hash === h)),
                );
              }
            }}
          />
          {artifact?.perks && artifact.perks.length > 0 ? (
            <Cluster gap={6} className="mt-2">
              {artifact.perks.map((perk) => (
                <Button
                  key={perk.hash}
                  size="sm"
                  variant={perkHashes.includes(perk.hash) ? "accent" : "ghost"}
                  onClick={() =>
                    setPerkHashes((prev) =>
                      prev.includes(perk.hash)
                        ? prev.filter((h) => h !== perk.hash)
                        : [...prev, perk.hash],
                    )
                  }
                >
                  {perk.name}
                </Button>
              ))}
            </Cluster>
          ) : null}
        </Section>
      ) : null}

      <Section label="Soft guidance">
        <Text size="xs" tone="muted">
          Coverage and stat coaching appear as you compose sets (never auto-applies pins).
        </Text>
      </Section>

      {mode === "draft" ? (
        <Button variant="accent" disabled={!canCreate} onClick={() => void handleCreate()}>
          {busy || sourcingKit ? "Creating…" : "Save general · create build"}
        </Button>
      ) : (
        <Button variant="accent" disabled={saveBusy || synergyTypes.length === 0} onClick={() => void handleLiveIdentitySave()}>
          {saveBusy ? "Saving…" : "Save general"}
        </Button>
      )}
    </Stack>
  );
}
