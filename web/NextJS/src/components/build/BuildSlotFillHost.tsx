"use client";

import { useCallback, useEffect, useState } from "react";

import { SlotFillPanel } from "@/components/sets/SlotFillPanel";
import type { SetDetail } from "@/components/sets/types";
import { Callout, Stack, Text } from "@/components/ui";

export function BuildSlotFillHost({
  setId,
  slot,
  attachmentMode,
  onClose,
  onFilled,
}: {
  setId: string;
  slot: string;
  attachmentMode: "live" | "snapshot";
  onClose: () => void;
  onFilled: () => void;
}) {
  const [set, setSet] = useState<SetDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/sets/${setId}`);
      const body = (await res.json()) as { set?: SetDetail; error?: string };
      if (!res.ok || !body.set) {
        setError(body.error ?? "Failed to load set");
        setSet(null);
        return;
      }
      setSet(body.set as SetDetail);
    } catch {
      setError("Failed to load set");
    } finally {
      setLoading(false);
    }
  }, [setId]);

  useEffect(() => {
    void load();
  }, [load]);

  if (attachmentMode === "snapshot") {
    return (
      <Callout tone="warning">
        This attachment is a snapshot. Switch to a live Set (create or link live)
        to edit library pieces from Builds without breaking frozen configs.
        <button type="button" className="ml-2 underline" onClick={onClose}>
          Close
        </button>
      </Callout>
    );
  }

  if (loading) {
    return (
      <Text size="sm" tone="muted">
        Loading set…
      </Text>
    );
  }
  if (error || !set) {
    return <Callout tone="danger">{error ?? "Set not found"}</Callout>;
  }

  return (
    <Stack gap={8} className="min-h-0 flex-1">
      <SlotFillPanel
        set={set}
        slot={slot}
        onClose={onClose}
        onFilled={() => {
          onFilled();
          onClose();
        }}
      />
    </Stack>
  );
}
