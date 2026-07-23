"use client";

import { useState } from "react";

import { Button, Callout, Cluster, Stack, Text } from "@/components/ui";

type Cat = "armor" | "weapon" | "mod";

export function CaptureSetsFromBuild({
  buildId,
  variantId,
  categories,
  onDone,
}: {
  buildId: string;
  variantId: string;
  /** Prefer single category from walkthrough; default all. */
  categories?: Cat[];
  onDone: (result: {
    createdSets: Array<{ id: string; type: string; name: string }>;
    skippedCategories: string[];
  }) => void;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const cats = categories ?? (["armor", "weapon", "mod"] as Cat[]);

  async function run() {
    setBusy(true);
    setError(null);
    setInfo(null);
    try {
      const res = await fetch(`/api/user/builds/${buildId}/create-sets`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          variantId,
          categories: cats,
          attachNow: true,
        }),
      });
      const body = (await res.json()) as {
        error?: string;
        code?: string;
        createdSets?: Array<{ id: string; type: string; name: string }>;
        skippedCategories?: string[];
      };
      if (!res.ok) {
        setError(
          body.error ??
            (body.code === "NOTHING_TO_CREATE"
              ? "Nothing to capture in the selected categories."
              : "Capture failed"),
        );
        return;
      }
      const created = body.createdSets ?? [];
      const skipped = body.skippedCategories ?? [];
      const skipNote =
        skipped.length > 0
          ? ` Skipped: ${skipped.join(", ")} (empty or unsupported).`
          : "";
      setInfo(
        created.length
          ? `Created ${created.map((s) => s.name).join(", ")}.${skipNote}`
          : `No sets created.${skipNote}`,
      );
      onDone({ createdSets: created, skippedCategories: skipped });
    } catch {
      setError("Capture failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted">
        Snapshot current resolved gear into library Set(s) and attach live
        (replace-by-type). Mods may be skipped if not snapshotable yet.
      </Text>
      <Cluster gap={4}>
        {cats.map((c) => (
          <span key={c} className="text-xs uppercase tracking-widest text-muted">
            {c}
          </span>
        ))}
      </Cluster>
      {error ? <Callout tone="danger">{error}</Callout> : null}
      {info ? <Callout tone="info">{info}</Callout> : null}
      <Button
        variant="accent"
        size="sm"
        disabled={busy}
        onClick={() => void run()}
      >
        {busy ? "Capturing…" : "Capture current gear into a Set"}
      </Button>
    </Stack>
  );
}
