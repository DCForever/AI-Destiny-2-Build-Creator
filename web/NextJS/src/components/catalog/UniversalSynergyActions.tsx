"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import {
  Button,
  Callout,
  Row,
  SelectField,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import { synergyLinkFromHit } from "@/lib/catalog/synergyLinkFromHit";
import type { CompositionSearchHit } from "@/lib/catalog/universalSearch";
import {
  formatSynergyTypeDesignation,
  getSynergyTypeLabel,
} from "@/lib/synergies/generateSynergyName";
import { linkDedupeKey, type MergeableLink } from "@/lib/synergies/mergeSynergies";
import {
  CREATABLE_SYNERGY_TYPES,
  type CreatableSynergyType,
  type SynergyLinkInput,
} from "@/lib/synergies/schemas";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import { sortByName } from "@/lib/sortByName";

type WizardMode = "idle" | "create" | "add";

type SynergyRow = {
  id: string;
  name: string;
  type: string;
  subType: string | null;
  links?: MergeableLink[];
};

type SubTypeOption = { name: string; value?: string };

export function UniversalSynergyActions({
  hit,
  onSuccess,
}: {
  hit: CompositionSearchHit;
  onSuccess: (message: string) => void;
}) {
  const link = useMemo(() => synergyLinkFromHit(hit), [hit]);

  const [mode, setMode] = useState<WizardMode>("idle");
  const [type, setType] = useState<CreatableSynergyType>("verb");
  const [subType, setSubType] = useState("");
  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const [synergies, setSynergies] = useState<SynergyRow[]>([]);
  const [synergyId, setSynergyId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needSignIn, setNeedSignIn] = useState(false);
  const [alreadyLinked, setAlreadyLinked] = useState(false);

  const needsSub = requiresSubType(type);

  useEffect(() => {
    setMode("idle");
    setError(null);
    setNeedSignIn(false);
    setAlreadyLinked(false);
    setSynergyId("");
  }, [hit.id]);

  useEffect(() => {
    if (!needsSub) {
      setSubTypeOptions([]);
      setSubType("");
      return;
    }
    let cancelled = false;
    void (async () => {
      try {
        const res = await fetch(
          `/api/catalog/synergy-pickers/subtypes?category=${encodeURIComponent(type)}`,
        );
        if (!res.ok || cancelled) return;
        const body = (await res.json()) as { options?: SubTypeOption[] };
        const options = body.options ?? [];
        if (!cancelled) {
          setSubTypeOptions(options);
          setSubType((prev) => prev || options[0]?.name || "");
        }
      } catch {
        /* optional */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [type, needsSub]);

  const loadSynergies = useCallback(async () => {
    const res = await fetch("/api/user/synergies");
    if (res.status === 401) {
      setNeedSignIn(true);
      setSynergies([]);
      return;
    }
    if (!res.ok) {
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      throw new Error(body.error ?? "Failed to load synergies");
    }
    setNeedSignIn(false);
    const body = (await res.json()) as { synergies?: SynergyRow[] };
    setSynergies(sortByName(body.synergies ?? []));
  }, []);

  async function openCreate() {
    setError(null);
    setMode("create");
    setType("verb");
    setSubType("");
  }

  async function openAdd() {
    setError(null);
    setAlreadyLinked(false);
    setMode("add");
    setSynergyId("");
    try {
      await loadSynergies();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load synergies");
    }
  }

  function isAlreadyOn(row: SynergyRow, candidate: SynergyLinkInput): boolean {
    const key = linkDedupeKey(candidate);
    return (row.links ?? []).some((l) => linkDedupeKey(l) === key);
  }

  async function submitCreate() {
    if (!link) {
      setError("This hit cannot be linked as synergy evidence.");
      return;
    }
    if (needsSub && !subType.trim()) {
      setError("Subtype is required for this synergy type.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/user/synergies", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type,
          subType: needsSub ? subType.trim() : null,
          links: [link],
        }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        synergy?: { name?: string };
        error?: string;
      };
      if (res.status === 401) {
        setNeedSignIn(true);
        setError("Sign in to create a Synergy.");
        return;
      }
      if (!res.ok || !body.synergy) {
        setError(body.error ?? "Failed to create synergy");
        return;
      }
      setMode("idle");
      onSuccess(
        `Linked ${hit.name} on synergy “${body.synergy.name ?? formatSynergyTypeDesignation({ type, subType: needsSub ? subType : null })}”.`,
      );
    } catch {
      setError("Failed to create synergy");
    } finally {
      setBusy(false);
    }
  }

  async function submitAdd() {
    if (!link) {
      setError("This hit cannot be linked as synergy evidence.");
      return;
    }
    if (!synergyId) {
      setError("Choose a synergy");
      return;
    }
    const row = synergies.find((s) => s.id === synergyId);
    if (!row) {
      setError("Choose a synergy");
      return;
    }
    if (isAlreadyOn(row, link)) {
      setAlreadyLinked(true);
      setError(null);
      return;
    }

    setBusy(true);
    setError(null);
    setAlreadyLinked(false);
    try {
      // Prefer detail GET so we have full links when list is summary-only.
      let existingLinks: MergeableLink[] = row.links ?? [];
      const detailRes = await fetch(`/api/user/synergies/${synergyId}`);
      if (detailRes.status === 401) {
        setNeedSignIn(true);
        setError("Sign in to update a Synergy.");
        return;
      }
      if (detailRes.ok) {
        const detailBody = (await detailRes.json()) as {
          synergy?: { links?: MergeableLink[]; name?: string };
        };
        existingLinks = detailBody.synergy?.links ?? existingLinks;
        if (
          detailBody.synergy &&
          isAlreadyOn(
            { ...row, links: existingLinks },
            link,
          )
        ) {
          setAlreadyLinked(true);
          return;
        }
      }

      const nextLinks: SynergyLinkInput[] = [
        ...existingLinks.map((l) => ({
          kind: l.kind as SynergyLinkInput["kind"],
          displayName: l.displayName,
          itemHash: l.itemHash ?? undefined,
          perkHash: l.perkHash ?? undefined,
          parentItemHash: l.parentItemHash ?? undefined,
          originTraitName: l.originTraitName ?? undefined,
          originTraitHash: l.originTraitHash ?? undefined,
          armorSetName: l.armorSetName ?? undefined,
          bonusPieces:
            l.bonusPieces === 2 || l.bonusPieces === 4
              ? (l.bonusPieces as 2 | 4)
              : undefined,
          bonusName: l.bonusName ?? undefined,
          armorSetHash: l.armorSetHash ?? undefined,
        })),
        link,
      ];

      const res = await fetch(`/api/user/synergies/${synergyId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ links: nextLinks }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        synergy?: { name?: string };
        error?: string;
      };
      if (res.status === 401) {
        setNeedSignIn(true);
        setError("Sign in to update a Synergy.");
        return;
      }
      if (!res.ok) {
        setError(body.error ?? "Failed to add link");
        return;
      }
      setMode("idle");
      onSuccess(
        `Linked ${hit.name} on synergy “${body.synergy?.name ?? row.name}”.`,
      );
    } catch {
      setError("Failed to add synergy link");
    } finally {
      setBusy(false);
    }
  }

  if (!hit.actions.synergy || !link) {
    return (
      <Text size="sm" tone="muted">
        Not eligible as synergy evidence.
      </Text>
    );
  }

  return (
    <Stack gap={10}>
      {needSignIn ? (
        <Callout tone="warning" title="Sign in required">
          Sign in with Bungie to create or add to Synergies.
        </Callout>
      ) : null}
      {error ? <Callout tone="danger">{error}</Callout> : null}
      {alreadyLinked ? (
        <Callout tone="info" title="Already linked">
          This object is already on the chosen synergy — no duplicate was added.
        </Callout>
      ) : null}

      {mode === "idle" ? (
        <Row gap={8} wrap>
          <Button size="sm" variant="accent" onClick={() => void openCreate()}>
            Create Synergy
          </Button>
          <Button size="sm" variant="outline" onClick={() => void openAdd()}>
            Add to existing Synergy
          </Button>
        </Row>
      ) : null}

      {mode === "create" ? (
        <Stack gap={8}>
          <Text size="sm" weight="medium">
            Create Synergy
          </Text>
          <SelectField
            label="Type"
            value={type}
            onChange={(e) => setType(e.target.value as CreatableSynergyType)}
          >
            {CREATABLE_SYNERGY_TYPES.map((t) => (
              <option key={t} value={t}>
                {getSynergyTypeLabel(t)}
              </option>
            ))}
          </SelectField>
          {needsSub ? (
            subTypeOptions.length > 0 ? (
              <SelectField
                label="Subtype"
                value={subType}
                onChange={(e) => setSubType(e.target.value)}
              >
                {subTypeOptions.map((o) => (
                  <option key={o.name} value={o.name}>
                    {o.name}
                  </option>
                ))}
              </SelectField>
            ) : (
              <TextField
                label="Subtype"
                value={subType}
                onChange={(e) => setSubType(e.target.value)}
                placeholder="Required subtype"
              />
            )
          ) : (
            <Text size="xs" tone="muted">
              No subtype for this type
            </Text>
          )}
          <Text size="xs" tone="muted">
            Initial link · {link.kind} · {link.displayName}
          </Text>
          <Row gap={8} wrap>
            <Button
              size="sm"
              variant="accent"
              disabled={busy || (needsSub && !subType.trim())}
              onClick={() => void submitCreate()}
            >
              {busy ? "Saving…" : "Create & link"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={busy}
              onClick={() => {
                setMode("idle");
                setError(null);
              }}
            >
              Cancel
            </Button>
          </Row>
        </Stack>
      ) : null}

      {mode === "add" ? (
        <Stack gap={8}>
          <Text size="sm" weight="medium">
            Add to existing Synergy
          </Text>
          <SelectField
            label="Synergy"
            value={synergyId}
            onChange={(e) => {
              setSynergyId(e.target.value);
              setAlreadyLinked(false);
            }}
          >
            <option value="">Select a synergy…</option>
            {synergies.map((s) => (
              <option key={s.id} value={s.id}>
                {formatSynergyTypeDesignation({
                  type: s.type,
                  subType: s.subType,
                })}{" "}
                — {s.name}
              </option>
            ))}
          </SelectField>
          {synergies.length === 0 && !needSignIn ? (
            <Text size="xs" tone="muted">
              No synergies yet — create one instead.
            </Text>
          ) : null}
          <Row gap={8} wrap>
            <Button
              size="sm"
              variant="accent"
              disabled={busy || !synergyId}
              onClick={() => void submitAdd()}
            >
              {busy ? "Saving…" : "Add link"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={busy}
              onClick={() => {
                setMode("idle");
                setError(null);
                setAlreadyLinked(false);
              }}
            >
              Cancel
            </Button>
          </Row>
        </Stack>
      ) : null}
    </Stack>
  );
}
