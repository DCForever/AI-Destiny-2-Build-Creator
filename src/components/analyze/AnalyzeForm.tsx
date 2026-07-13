"use client";

import { useState } from "react";
import { PromptPreviewDialog } from "@/components/PromptPreviewDialog";
import { composeAnalyzePromptPreview, type PromptPreview } from "@/lib/llm/composePromptPreview";
import type { AnalyzeRequest } from "@/lib/llm/analyzeSchema";
import {
  Button,
  Cluster,
  FilterChip,
  Panel,
  SectionLabel,
  Stack,
  Text,
  TextField,
} from "@/components/ui";

const ACTIVITY_OPTIONS = [
  "Grandmaster Nightfall",
  "Master Raid",
  "Raid",
  "Dungeon",
  "Solo Ops",
  "Trials of Osiris",
  "Competitive Crucible",
  "General PvE",
];

const CLASSES: AnalyzeRequest["className"][] = ["Titan", "Hunter", "Warlock"];

const LOADOUT_PLACEHOLDER = `Subclass: Nightstalker
Kinetic: Fatebringer (Explosive Payload, Frenzy)
Energy: Calus Mini-Tool (Incandescent)
Heavy: Gjallarhorn
Exotic armor: Orpheus Rig
Stats: 100 Mobility, 100 Recovery
Mods: …`;

interface AnalyzeFormProps {
  onSubmit: (req: AnalyzeRequest) => void;
  disabled: boolean;
  loadoutText: string;
  onLoadoutTextChange: (value: string) => void;
  className: AnalyzeRequest["className"];
  onClassNameChange: (value: AnalyzeRequest["className"]) => void;
}

export function AnalyzeForm({
  onSubmit,
  disabled,
  loadoutText,
  onLoadoutTextChange,
  className,
  onClassNameChange,
}: AnalyzeFormProps) {
  const [activity, setActivity] = useState("");
  const [playstyle, setPlaystyle] = useState("");
  const [notes, setNotes] = useState("");
  const [prefsOpen, setPrefsOpen] = useState(false);
  const [errors, setErrors] = useState<{ activity?: string; loadout?: string }>({});
  const [preview, setPreview] = useState<PromptPreview | null>(null);

  const validate = (): boolean => {
    const next: { activity?: string; loadout?: string } = {};
    if (!activity.trim()) next.activity = "Required";
    if (!loadoutText.trim()) next.loadout = "Required";
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const analyzeRequest = (): AnalyzeRequest => ({
    className,
    activity: activity.trim(),
    playstyle: playstyle.trim() || undefined,
    loadoutText: loadoutText.trim(),
    notes: notes.trim() || undefined,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    onSubmit(analyzeRequest());
  };

  const handlePreview = () => {
    if (!validate()) return;
    setPreview(composeAnalyzePromptPreview(analyzeRequest()));
  };

  return (
    <Panel pad="lg">
      <form onSubmit={handleSubmit} className="space-y-5" noValidate>
        <Stack gap={8}>
          <SectionLabel>Guardian Class</SectionLabel>
          <Cluster gap={6}>
            {CLASSES.map((cls) => (
              <FilterChip
                key={cls}
                label={cls}
                active={className === cls}
                onClick={() => onClassNameChange(cls)}
                disabled={disabled}
              />
            ))}
          </Cluster>
        </Stack>

        <div className="space-y-1">
          <label htmlFor="analyze-activity">
            <Text size="xs" tone="muted" className="tracking-widest uppercase">
              Activity
            </Text>
          </label>
          <input
            id="analyze-activity"
            list="analyze-activity-list"
            value={activity}
            onChange={(e) => setActivity(e.target.value)}
            placeholder="e.g. Grandmaster Nightfall"
            className="w-full bg-surface-raised border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
          />
          <datalist id="analyze-activity-list">
            {ACTIVITY_OPTIONS.map((a) => (
              <option key={a} value={a} />
            ))}
          </datalist>
          {errors.activity && <p className="text-xs text-danger">{errors.activity}</p>}
        </div>

        <TextField
          label="Playstyle"
          value={playstyle}
          onChange={(e) => setPlaystyle(e.target.value)}
          placeholder="Optional — e.g. aggressive melee"
        />

        <div className="space-y-1">
          <label htmlFor="analyze-loadout">
            <Text size="xs" tone="muted" className="tracking-widest uppercase">
              Current Loadout
            </Text>
          </label>
          <textarea
            id="analyze-loadout"
            rows={10}
            value={loadoutText}
            onChange={(e) => onLoadoutTextChange(e.target.value)}
            placeholder={LOADOUT_PLACEHOLDER}
            className="w-full bg-surface-raised border border-line px-3 py-2 font-mono text-xs text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
          />
          {errors.loadout && <p className="text-xs text-danger">{errors.loadout}</p>}
        </div>

        <div>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            onClick={() => setPrefsOpen((v) => !v)}
            aria-expanded={prefsOpen}
          >
            {prefsOpen ? "▼" : "▶"} Notes
          </Button>

          {prefsOpen && (
            <div className="mt-3 border-l border-line pl-4">
              <div className="space-y-1">
                <label htmlFor="analyze-notes">
                  <Text size="xs" tone="muted" className="tracking-widest uppercase">
                    Notes
                  </Text>
                </label>
                <textarea
                  id="analyze-notes"
                  rows={3}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Any other context for the analyzer…"
                  className="w-full bg-surface-raised border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
                />
              </div>
            </div>
          )}
        </div>

        <Stack gap={8}>
          <Button type="submit" variant="accent" disabled={disabled} className="w-full">
            Analyze Loadout
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={handlePreview}
            disabled={disabled}
            className="w-full"
          >
            Preview Prompt
          </Button>
        </Stack>

        {preview && (
          <PromptPreviewDialog
            open
            onClose={() => setPreview(null)}
            title="Analyzer Prompt Preview"
            preview={preview}
          />
        )}
      </form>
    </Panel>
  );
}
