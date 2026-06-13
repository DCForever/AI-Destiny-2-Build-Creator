"use client";

import { useState } from "react";
import { PromptPreviewDialog } from "@/components/PromptPreviewDialog";
import { composeAnalyzePromptPreview, type PromptPreview } from "@/lib/llm/composePromptPreview";
import type { AnalyzeRequest } from "@/lib/llm/analyzeSchema";

const ACTIVITY_OPTIONS = [
  "Grandmaster Nightfall", "Master Raid", "Raid", "Dungeon",
  "Solo Ops", "Trials of Osiris", "Competitive Crucible", "General PvE",
];

const CLASSES: AnalyzeRequest["className"][] = ["Titan", "Hunter", "Warlock"];

const LOADOUT_PLACEHOLDER = `Subclass: Nightstalker
Kinetic: Fatebringer (Explosive Payload, Frenzy)
Energy: Calus Mini-Tool (Incandescent)
Heavy: Gjallarhorn
Exotic armor: Orpheus Rig
Stats: 100 Mobility, 100 Recovery
Mods: …`;

function fieldLabel(text: string) {
  return (
    <span className="text-[11px] tracking-widest uppercase text-muted">{text}</span>
  );
}

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
    <form onSubmit={handleSubmit} className="panel-notch p-5 space-y-5" noValidate>
      <fieldset>
        <legend className="mb-2">{fieldLabel("Guardian Class")}</legend>
        <div className="flex gap-0 border border-line">
          {CLASSES.map((cls) => (
            <label key={cls} className="flex-1 text-center cursor-pointer">
              <input
                type="radio"
                name="guardianClass"
                value={cls}
                checked={className === cls}
                onChange={() => onClassNameChange(cls)}
                className="sr-only"
              />
              <span
                className={`block py-2 text-xs tracking-widest uppercase transition-colors ${
                  className === cls
                    ? "bg-accent text-background font-semibold"
                    : "text-muted hover:text-foreground"
                }`}
              >
                {cls}
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <div className="space-y-1">
        <label htmlFor="analyze-activity">{fieldLabel("Activity")}</label>
        <input
          id="analyze-activity"
          list="analyze-activity-list"
          value={activity}
          onChange={(e) => setActivity(e.target.value)}
          placeholder="e.g. Grandmaster Nightfall"
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
        />
        <datalist id="analyze-activity-list">
          {ACTIVITY_OPTIONS.map((a) => <option key={a} value={a} />)}
        </datalist>
        {errors.activity && <p className="text-xs text-danger">{errors.activity}</p>}
      </div>

      <div className="space-y-1">
        <label htmlFor="analyze-playstyle">{fieldLabel("Playstyle")}</label>
        <input
          id="analyze-playstyle"
          value={playstyle}
          onChange={(e) => setPlaystyle(e.target.value)}
          placeholder="Optional — e.g. aggressive melee"
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
        />
      </div>

      <div className="space-y-1">
        <label htmlFor="analyze-loadout">{fieldLabel("Current Loadout")}</label>
        <textarea
          id="analyze-loadout"
          rows={10}
          value={loadoutText}
          onChange={(e) => onLoadoutTextChange(e.target.value)}
          placeholder={LOADOUT_PLACEHOLDER}
          className="w-full bg-background border border-line px-3 py-2 font-mono text-xs text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
        />
        {errors.loadout && <p className="text-xs text-danger">{errors.loadout}</p>}
      </div>

      <div>
        <button
          type="button"
          onClick={() => setPrefsOpen((v) => !v)}
          className="flex items-center gap-2 text-[11px] tracking-widest uppercase text-muted hover:text-foreground transition-colors focus-visible:outline-accent"
          aria-expanded={prefsOpen}
        >
          <span>{prefsOpen ? "▼" : "▶"}</span>
          <span>Notes</span>
        </button>

        {prefsOpen && (
          <div className="mt-3 border-l border-line pl-4">
            <div className="space-y-1">
              <label htmlFor="analyze-notes">{fieldLabel("Notes")}</label>
              <textarea
                id="analyze-notes"
                rows={3}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Any other context for the analyzer…"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
              />
            </div>
          </div>
        )}
      </div>

      <button
        type="submit"
        disabled={disabled}
        className="w-full py-2.5 bg-accent text-background text-sm font-semibold tracking-widest uppercase hover:bg-accent-strong transition-colors disabled:opacity-40 disabled:cursor-not-allowed focus-visible:outline-accent"
      >
        Analyze Loadout
      </button>

      <button
        type="button"
        onClick={handlePreview}
        disabled={disabled}
        className="w-full py-2.5 text-sm tracking-widest uppercase border border-line text-muted hover:text-foreground hover:border-foreground/40 transition-colors disabled:opacity-40 disabled:cursor-not-allowed focus-visible:outline-accent"
      >
        Preview Prompt
      </button>

      {preview && (
        <PromptPreviewDialog
          open
          onClose={() => setPreview(null)}
          title="Analyzer Prompt Preview"
          preview={preview}
        />
      )}
    </form>
  );
}
