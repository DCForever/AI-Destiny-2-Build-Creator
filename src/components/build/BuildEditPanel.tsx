"use client";

import { useState } from "react";

import type { BuildDetail } from "@/components/build/types";
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
  Callout,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";

function designationsFromBuild(build: BuildDetail): SynergyTypeSelection[] {
  return (build.synergyTypes ?? []).map((t) => ({
    type: t.type as SynergyTypeSelection["type"],
    subType: t.subType,
  }));
}

/** Parent should pass key={build.id} so form state resets on selection change. */
export function BuildEditPanel({
  build,
  onClose,
  onSaved,
}: {
  build: BuildDetail;
  onClose: () => void;
  onSaved: (next: BuildDetail) => void;
}) {
  const [name, setName] = useState(build.name);
  const [exoticArmor, setExoticArmor] = useState<{
    hash: number;
    name: string;
  } | null>(
    build.exoticArmorHash != null && build.exoticArmorName
      ? { hash: build.exoticArmorHash, name: build.exoticArmorName }
      : null,
  );
  const [pinnedSuper, setPinnedSuper] = useState<string | null>(
    build.pinnedSuper ?? build.subclass.super ?? null,
  );
  const [synergyTypes, setSynergyTypes] = useState<SynergyTypeSelection[]>(
    designationsFromBuild(build),
  );
  const [softStatsDraft, setSoftStatsDraft] = useState(
    build.softStatTargets ? JSON.stringify(build.softStatTargets, null, 2) : "",
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [pendingPayload, setPendingPayload] = useState<Record<
    string,
    unknown
  > | null>(null);

  async function patchBuild(
    payload: Record<string, unknown>,
    okMessage: string,
  ) {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const body = (await res.json()) as {
        error?: string;
        code?: string;
        build?: BuildDetail;
      };
      if (res.status === 409 && body.code === "IDENTITY_CONFIRM_REQUIRED") {
        setPendingPayload(payload);
        setError(
          "This identity change requires Confirm (keep this build) or Fork (new build).",
        );
        return;
      }
      if (!res.ok || !body.build) {
        setError(body.error ?? "Failed to save build");
        return;
      }
      setPendingPayload(null);
      setMessage(okMessage);
      onSaved(body.build);
    } catch {
      setError("Failed to save build");
    } finally {
      setBusy(false);
    }
  }

  async function confirmIdentity(action: "confirm" | "fork") {
    if (!pendingPayload) return;
    await patchBuild(
      { ...pendingPayload, identityAction: action },
      action === "fork" ? "Forked new build" : "Identity confirmed",
    );
  }

  function parseSoftStats(): SoftStatTargets | null | undefined {
    const raw = softStatsDraft.trim();
    if (!raw) return null;
    try {
      return JSON.parse(raw) as SoftStatTargets;
    } catch {
      setError("Soft stat targets must be valid JSON");
      return undefined;
    }
  }

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="center" gap={8} wrap>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              Edit build · {build.name}
            </Text>
            <Text size="xs" tone="muted">
              Build identity: name, exotic armor, synergy types, pinned super,
              soft stats. Class/subclass kit changes that alter identity may
              ask Confirm or Fork.
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Close
          </Button>
        </Row>

        {error ? <Callout tone="danger">{error}</Callout> : null}
        {message ? <Callout tone="success">{message}</Callout> : null}

        {pendingPayload ? (
          <Panel tone="warning" pad="md">
            <Stack gap={8}>
              <Text size="sm" weight="medium" tone="warning">
                Identity change
              </Text>
              <Text size="sm" tone="muted">
                Confirm keeps this build; Fork creates a new build with the
                change.
              </Text>
              <Row gap={8} wrap>
                <Button
                  size="sm"
                  variant="accent"
                  disabled={busy}
                  onClick={() => void confirmIdentity("confirm")}
                >
                  Confirm
                </Button>
                <Button
                  size="sm"
                  disabled={busy}
                  onClick={() => void confirmIdentity("fork")}
                >
                  Fork
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={busy}
                  onClick={() => {
                    setPendingPayload(null);
                    setError(null);
                  }}
                >
                  Cancel
                </Button>
              </Row>
            </Stack>
          </Panel>
        ) : null}

        <TextField
          label="Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />

        <Section label="Exotic armor">
          <ManifestSearchPicker
            label="Search exotic armor"
            category="exotic-armor"
            classType={build.className as "Titan" | "Hunter" | "Warlock"}
            selected={exoticArmor}
            onSelect={(item) =>
              setExoticArmor(item ? { hash: item.hash, name: item.name } : null)
            }
          />
        </Section>

        <Section label="Pinned super">
          <ManifestSearchPicker
            label="Search supers"
            category="abilities"
            kind="super"
            subclass={build.subclass.name}
            selected={
              pinnedSuper
                ? ({ hash: 0, name: pinnedSuper } satisfies ManifestPick)
                : null
            }
            onSelect={(item) => setPinnedSuper(item?.name ?? null)}
          />
        </Section>

        <Section label="Synergy types">
          <SynergyTypeMultiSelect
            selected={synergyTypes}
            onChange={setSynergyTypes}
          />
        </Section>

        <Stack gap={4}>
          <Text size="xs" tone="muted">
            Soft stat targets (JSON)
          </Text>
          <textarea
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground min-h-[88px] font-mono"
            value={softStatsDraft}
            onChange={(e) => setSoftStatsDraft(e.target.value)}
            placeholder='{"resilience":100,"discipline":100}'
          />
        </Stack>

        <Row gap={8} wrap>
          <Button
            variant="accent"
            size="sm"
            disabled={busy || !name.trim() || synergyTypes.length === 0}
            onClick={() => {
              const softStatTargets = parseSoftStats();
              if (softStatTargets === undefined) return;
              void patchBuild(
                {
                  name: name.trim(),
                  exoticArmorHash: exoticArmor?.hash ?? null,
                  exoticArmorName: exoticArmor?.name ?? null,
                  pinnedSuper,
                  synergyTypes,
                  softStatTargets,
                },
                "Build saved",
              );
            }}
          >
            Save build
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
