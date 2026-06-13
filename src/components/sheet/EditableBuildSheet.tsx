"use client";

import { useCallback, useState } from "react";
import type { BuildRequest, GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import { BuildSheet } from "./BuildSheet";
import { WeaponPicker, type WeaponSearchResult } from "./WeaponPicker";

interface EditableBuildSheetProps {
  sheet: ResolvedBuildSheet;
  build: GeneratedBuild;
  activity: string;
  className: BuildRequest["className"];
  onUpdate: (next: { build: GeneratedBuild; sheet: ResolvedBuildSheet }) => void;
  staleBanner?: string | null;
}

export function EditableBuildSheet({
  sheet,
  build,
  activity,
  className,
  onUpdate,
  staleBanner,
}: EditableBuildSheetProps) {
  const [pickerSlot, setPickerSlot] = useState<"Kinetic" | "Energy" | "Power" | null>(null);
  const [resolving, setResolving] = useState(false);
  const [refining, setRefining] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);
  const [changeRequest, setChangeRequest] = useState("");

  const handleWeaponSelect = useCallback(async (
    slot: "Kinetic" | "Energy" | "Power",
    result: WeaponSearchResult,
  ) => {
    setResolving(true);
    setEditError(null);
    const existing = build.weapons.find((w) => w.slot === slot);
    const weapon: GeneratedBuild["weapons"][number] = {
      slot,
      name: result.name,
      isExotic: result.isExotic ?? false,
      perks: existing?.perks ?? [],
      rationale: existing?.rationale ?? `Swapped to ${result.name}.`,
    };

    try {
      const res = await fetch("/api/build/resolve-slot", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ kind: "weapon", build, activity, slot, weapon }),
      });
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setEditError(body.error ?? "Failed to resolve weapon");
        return;
      }
      const body = await res.json() as { build: GeneratedBuild; sheet: ResolvedBuildSheet };
      onUpdate(body);
    } catch {
      setEditError("Failed to resolve weapon");
    } finally {
      setResolving(false);
    }
  }, [activity, build, onUpdate]);

  const handleRefine = async () => {
    const trimmed = changeRequest.trim();
    if (!trimmed) return;

    setRefining(true);
    setEditError(null);
    try {
      const res = await fetch("/api/build/refine", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          lockedSections: ["subclass", "exoticArmor", "armor", "mods", "artifact"],
          changeRequest: trimmed,
          priorBuild: build,
          activity,
          className,
        }),
      });
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setEditError(body.error ?? "Refine failed");
        return;
      }
      const body = await res.json() as {
        build: GeneratedBuild;
        sheet: ResolvedBuildSheet;
      };
      onUpdate(body);
      setChangeRequest("");
    } catch {
      setEditError("Refine failed");
    } finally {
      setRefining(false);
    }
  };

  return (
    <div className="space-y-4">
      {staleBanner && (
        <div className="panel-notch border-warning/40 px-4 py-3 text-xs text-warning">
          {staleBanner}
        </div>
      )}

      {editError && <p className="text-xs text-danger">{editError}</p>}
      {resolving && <p className="text-xs text-muted">Re-resolving weapon…</p>}

      <BuildSheet
        sheet={sheet}
        editable
        onWeaponSlotClick={(slot) => setPickerSlot(slot)}
      />

      <div className="panel-notch p-4 space-y-3">
        <div className="text-[11px] tracking-widest uppercase text-muted">
          Re-optimize with LLM
        </div>
        <textarea
          rows={2}
          value={changeRequest}
          onChange={(e) => setChangeRequest(e.target.value)}
          placeholder="Describe what to change (locked: subclass, armor, mods, artifact)…"
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
        />
        <button
          type="button"
          onClick={() => void handleRefine()}
          disabled={refining || !changeRequest.trim()}
          className="text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent disabled:opacity-50"
        >
          {refining ? "Refining…" : "Re-optimize with LLM"}
        </button>
      </div>

      {pickerSlot && (
        <WeaponPicker
          slot={pickerSlot}
          open
          onClose={() => setPickerSlot(null)}
          onSelect={(result) => void handleWeaponSelect(pickerSlot, result)}
        />
      )}
    </div>
  );
}
