"use client";

import { useState } from "react";

import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
import { ManifestSearchPicker, type ManifestPick } from "@/components/lookups/ManifestSearchPicker";
import { Button, Cluster, Section, Stack, Text } from "@/components/ui";
import { resolveSubclassScope } from "@/lib/debug/subclassScope";

/** Grouped subclass kit editor (abilities · aspects · fragments). */
export function SubclassTab({
  build,
  variant,
  onSaved,
  onMessage,
  onError,
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  onSaved: (next: BuildDetail, preferredVariantId?: string) => void;
  onMessage: (m: string | null) => void;
  onError: (e: string | null) => void;
}) {
  // Prefer per-variant effective subclass (Phase E); fall back to build tree.
  const sub =
    (variant as { subclass?: typeof build.subclass }).subclass ?? build.subclass;
  const treeName = build.subclass.name;
  const scope = resolveSubclassScope(treeName);
  const [superName, setSuper] = useState(sub.super);
  const [classAbility, setClassAbility] = useState(sub.classAbility);
  const [melee, setMelee] = useState(sub.melee);
  const [grenade, setGrenade] = useState(sub.grenade);
  const [movement, setMovement] = useState(sub.movement);
  const [aspects, setAspects] = useState<string[]>(sub.aspects ?? []);
  const [fragments, setFragments] = useState<string[]>(sub.fragments ?? []);
  const [busy, setBusy] = useState(false);

  function pickName(item: ManifestPick | null, setter: (v: string) => void) {
    // Clear passes null — empty string restores Browse/Search chrome.
    setter(item?.name ?? "");
  }

  async function save() {
    setBusy(true);
    onError(null);
    try {
      // Kit is variant-owned (DBR-SUB-003); tree stays on build.
      const res = await fetch(
        `/api/user/builds/${build.id}/variants/${variant.id}`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            subclassKit: {
              super: superName,
              classAbility,
              melee,
              grenade,
              movement,
              aspects,
              fragments,
            },
          }),
        },
      );
      const body = (await res.json()) as { build?: BuildDetail; error?: string };
      if (!res.ok || !body.build) {
        onError(body.error ?? "Failed to save subclass kit");
        return;
      }
      onSaved(body.build, variant.id);
      onMessage("Subclass kit saved");
    } catch {
      onError("Failed to save subclass kit");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={12}>
      <Text size="xs" tone="muted">
        Grouped kit pickers — capacity and legality enforced on save.
      </Text>
      <div className="grid gap-3 md:grid-cols-2">
        <Section label="Class ability">
          <ManifestSearchPicker
            label="Class ability"
            category="abilities"
            kind="classAbility"
            classType={scope?.classType ?? build.className}
            element={scope?.element}
            subclass={treeName}
            selected={classAbility ? { hash: 0, name: classAbility } : null}
            onSelect={(i) => pickName(i, setClassAbility)}
          />
        </Section>
        <Section label="Melee">
          <ManifestSearchPicker
            label="Melee"
            category="abilities"
            kind="melee"
            classType={scope?.classType ?? build.className}
            element={scope?.element}
            subclass={treeName}
            selected={melee ? { hash: 0, name: melee } : null}
            onSelect={(i) => pickName(i, setMelee)}
          />
        </Section>
        <Section label="Grenade">
          <ManifestSearchPicker
            label="Grenade"
            category="abilities"
            kind="grenade"
            classType={scope?.classType ?? build.className}
            element={scope?.element}
            subclass={treeName}
            selected={grenade ? { hash: 0, name: grenade } : null}
            onSelect={(i) => pickName(i, setGrenade)}
          />
        </Section>
        <Section label="Movement">
          <ManifestSearchPicker
            label="Movement"
            category="abilities"
            kind="movement"
            classType={scope?.classType ?? build.className}
            element={scope?.element}
            subclass={treeName}
            selected={movement ? { hash: 0, name: movement } : null}
            onSelect={(i) => pickName(i, setMovement)}
          />
        </Section>
      </div>
      <Section label="Super">
        <ManifestSearchPicker
          label="Super"
          category="abilities"
          kind="super"
          classType={scope?.classType ?? build.className}
          element={scope?.element}
          subclass={sub.name}
          selected={superName ? { hash: 0, name: superName } : null}
          onSelect={(i) => pickName(i, setSuper)}
        />
      </Section>
      <Section label="Aspects">
        <Cluster gap={6}>
          {(aspects.length ? aspects : ["—"]).map((a) => (
            <Text key={a} size="xs">
              {a}
            </Text>
          ))}
        </Cluster>
        <ManifestSearchPicker
          label="Add aspect"
          category="aspects"
          classType={scope?.classType ?? build.className}
          element={scope?.element}
          subclass={sub.name}
          selected={null}
          onSelect={(i) => {
            if (i?.name && !aspects.includes(i.name)) setAspects((p) => [...p, i.name]);
          }}
        />
        <Button size="sm" variant="ghost" onClick={() => setAspects([])}>
          Clear aspects
        </Button>
      </Section>
      <Section label="Fragments">
        <Cluster gap={6}>
          {(fragments.length ? fragments : ["—"]).map((f) => (
            <Text key={f} size="xs">
              {f}
            </Text>
          ))}
        </Cluster>
        <ManifestSearchPicker
          label="Add fragment"
          category="fragments"
          classType={scope?.classType ?? build.className}
          element={scope?.element}
          subclass={sub.name}
          selected={null}
          onSelect={(i) => {
            if (i?.name && !fragments.includes(i.name)) setFragments((p) => [...p, i.name]);
          }}
        />
        <Button size="sm" variant="ghost" onClick={() => setFragments([])}>
          Clear fragments
        </Button>
      </Section>
      <Button variant="accent" size="sm" disabled={busy} onClick={() => void save()}>
        {busy ? "Saving…" : "Save subclass kit"}
      </Button>
    </Stack>
  );
}
