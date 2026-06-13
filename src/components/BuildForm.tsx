"use client";

import { useCallback, useEffect, useState } from "react";
import { SUBCLASSES_BY_CLASS, formatSubclassLabel } from "@/data/subclasses";
import { PromptPreviewDialog } from "@/components/PromptPreviewDialog";
import { composeBuildPromptPreview, type PromptPreview } from "@/lib/llm/composePromptPreview";
import type { BuildRequest } from "@/lib/llm/buildSchema";
import type { UserPreferences } from "@/lib/preferences/types";
import { DEFAULT_PREFERENCES } from "@/lib/preferences/types";

const ACTIVITY_OPTIONS = [
  "Grandmaster Nightfall", "Master Raid", "Raid", "Dungeon",
  "Solo Ops", "Trials of Osiris", "Competitive Crucible", "General PvE",
];

const CLASSES: BuildRequest["className"][] = ["Titan", "Hunter", "Warlock"];

type GenerationMode = NonNullable<UserPreferences["defaultGenerationMode"]>;

type FormData = {
  className: BuildRequest["className"];
  subclass: string;
  activity: string;
  playstyle: string;
  preferredExotic: string;
  preferredWeapon: string;
  notes: string;
  generationMode: GenerationMode;
  weaponTypesInclude: string;
  weaponTypesExclude: string;
  prioritizeOwned: boolean;
};

function fieldLabel(text: string) {
  return (
    <span className="text-[11px] tracking-widest uppercase text-muted">{text}</span>
  );
}

interface BuildFormProps {
  onSubmit: (req: BuildRequest) => void;
  isGenerating: boolean;
  multiPassAvailable?: boolean;
}

export function BuildForm({ onSubmit, isGenerating, multiPassAvailable = false }: BuildFormProps) {
  const [form, setForm] = useState<FormData>({
    className: DEFAULT_PREFERENCES.defaultClass ?? "Titan",
    subclass: "",
    activity: "",
    playstyle: "",
    preferredExotic: "",
    preferredWeapon: "",
    notes: "",
    generationMode: DEFAULT_PREFERENCES.defaultGenerationMode ?? "standard",
    weaponTypesInclude: "",
    weaponTypesExclude: "",
    prioritizeOwned: false,
  });
  const [prefsOpen, setPrefsOpen] = useState(false);
  const [errors, setErrors] = useState<Partial<Record<keyof FormData, string>>>({});
  const [preview, setPreview] = useState<PromptPreview | null>(null);
  const [prefsLoaded, setPrefsLoaded] = useState(false);

  const set = (key: keyof FormData, value: string) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const setClassName = (className: BuildRequest["className"]) =>
    setForm((prev) => ({ ...prev, className, subclass: "" }));

  const persistGenerationMode = useCallback(async (generationMode: GenerationMode) => {
    try {
      await fetch("/api/user/preferences", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ defaultGenerationMode: generationMode }),
      });
    } catch {
      // Preference sync is best-effort; generation still works with local state.
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const res = await fetch("/api/user/preferences");
      if (cancelled) return;
      if (res.status === 401) {
        setPrefsLoaded(true);
        return;
      }
      if (!res.ok) {
        setPrefsLoaded(true);
        return;
      }
      const body = await res.json() as { preferences: UserPreferences };
      setForm((prev) => ({
        ...prev,
        className: body.preferences.defaultClass ?? prev.className,
        generationMode: body.preferences.defaultGenerationMode ?? prev.generationMode,
      }));
      setPrefsLoaded(true);
    })();
    return () => { cancelled = true; };
  }, []);

  const validate = (): boolean => {
    const next: Partial<Record<keyof FormData, string>> = {};
    if (!form.subclass.trim()) next.subclass = "Required";
    if (!form.activity.trim()) next.activity = "Required";
    if (!form.playstyle.trim()) next.playstyle = "Required";
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const buildRequest = (): BuildRequest => {
    const splitTypes = (raw: string) =>
      raw.split(",").map((s) => s.trim()).filter(Boolean);
    const include = splitTypes(form.weaponTypesInclude);
    const exclude = splitTypes(form.weaponTypesExclude);
    const weaponTypePreferences =
      include.length > 0 || exclude.length > 0 || form.prioritizeOwned
        ? {
            include: include.length > 0 ? include : undefined,
            exclude: exclude.length > 0 ? exclude : undefined,
            prioritizeOwned: form.prioritizeOwned || undefined,
          }
        : undefined;

    return {
      className: form.className,
      subclass: form.subclass.trim(),
      activity: form.activity.trim(),
      playstyle: form.playstyle.trim(),
      preferredExotic: form.preferredExotic.trim() || undefined,
      preferredWeapon: form.preferredWeapon.trim() || undefined,
      notes: form.notes.trim() || undefined,
      generationMode: form.generationMode,
      weaponTypePreferences,
    };
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    onSubmit(buildRequest());
  };

  const handlePreview = () => {
    if (!validate()) return;
    setPreview(composeBuildPromptPreview(buildRequest()));
  };

  const handleGenerationModeChange = (checked: boolean) => {
    const generationMode: GenerationMode = checked ? "multi-pass" : "standard";
    setForm((prev) => ({ ...prev, generationMode }));
    void persistGenerationMode(generationMode);
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
                checked={form.className === cls}
                onChange={() => setClassName(cls)}
                className="sr-only"
              />
              <span
                className={`block py-2 text-xs tracking-widest uppercase transition-colors ${
                  form.className === cls
                    ? "bg-accent text-background font-semibold"
                    : "text-muted hover:text-foreground"
                }`}
              >
                {cls}
              </span>
            </label>
          ))}
        </div>
        {!prefsLoaded && (
          <p className="text-[10px] text-muted mt-1">Loading preferences…</p>
        )}
      </fieldset>

      {multiPassAvailable && (
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={form.generationMode === "multi-pass"}
            onChange={(e) => handleGenerationModeChange(e.target.checked)}
            className="accent-accent"
          />
          <span className="text-xs text-muted">
            Multi-pass generation <span className="text-[10px]">(experimental, slower)</span>
          </span>
        </label>
      )}

      <div className="space-y-1">
        <label htmlFor="subclass">{fieldLabel("Subclass")}</label>
        <select
          id="subclass"
          value={form.subclass}
          onChange={(e) => set("subclass", e.target.value)}
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground focus-visible:outline-accent focus-visible:border-accent"
        >
          <option value="" disabled>Select subclass…</option>
          {SUBCLASSES_BY_CLASS[form.className].map((s) => (
            <option key={s} value={s}>{formatSubclassLabel(s)}</option>
          ))}
        </select>
        {errors.subclass && <p className="text-xs text-danger">{errors.subclass}</p>}
      </div>

      <div className="space-y-1">
        <label htmlFor="activity">{fieldLabel("Activity")}</label>
        <input
          id="activity"
          list="activity-list"
          value={form.activity}
          onChange={(e) => set("activity", e.target.value)}
          placeholder="e.g. Grandmaster Nightfall"
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
        />
        <datalist id="activity-list">
          {ACTIVITY_OPTIONS.map((a) => <option key={a} value={a} />)}
        </datalist>
        {errors.activity && <p className="text-xs text-danger">{errors.activity}</p>}
      </div>

      <div className="space-y-1">
        <label htmlFor="playstyle">{fieldLabel("Playstyle")}</label>
        <input
          id="playstyle"
          value={form.playstyle}
          onChange={(e) => set("playstyle", e.target.value)}
          placeholder="e.g. aggressive melee"
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
        />
        {errors.playstyle && <p className="text-xs text-danger">{errors.playstyle}</p>}
      </div>

      <div>
        <button
          type="button"
          onClick={() => setPrefsOpen((v) => !v)}
          className="flex items-center gap-2 text-[11px] tracking-widest uppercase text-muted hover:text-foreground transition-colors focus-visible:outline-accent"
          aria-expanded={prefsOpen}
        >
          <span>{prefsOpen ? "▼" : "▶"}</span>
          <span>Preferences</span>
        </button>

        {prefsOpen && (
          <div className="mt-3 space-y-4 border-l border-line pl-4">
            <div className="space-y-1">
              <label htmlFor="exotic">{fieldLabel("Preferred Exotic")}</label>
              <input
                id="exotic"
                value={form.preferredExotic}
                onChange={(e) => set("preferredExotic", e.target.value)}
                placeholder="Optional"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="weapon">{fieldLabel("Preferred Weapon")}</label>
              <input
                id="weapon"
                value={form.preferredWeapon}
                onChange={(e) => set("preferredWeapon", e.target.value)}
                placeholder="Optional"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="weapon-types-include">{fieldLabel("Weapon types to include")}</label>
              <input
                id="weapon-types-include"
                value={form.weaponTypesInclude}
                onChange={(e) => set("weaponTypesInclude", e.target.value)}
                placeholder="e.g. Hand Cannon, Scout Rifle (comma-separated)"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="weapon-types-exclude">{fieldLabel("Weapon types to exclude")}</label>
              <input
                id="weapon-types-exclude"
                value={form.weaponTypesExclude}
                onChange={(e) => set("weaponTypesExclude", e.target.value)}
                placeholder="e.g. Sidearm, Glaive (comma-separated)"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
              />
            </div>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={form.prioritizeOwned}
                onChange={(e) => setForm((prev) => ({ ...prev, prioritizeOwned: e.target.checked }))}
                className="accent-accent"
              />
              <span className="text-xs text-muted">Prioritize weapons I own (requires inventory sync)</span>
            </label>
            <div className="space-y-1">
              <textarea
                id="notes"
                rows={3}
                value={form.notes}
                onChange={(e) => set("notes", e.target.value)}
                placeholder="Any other preferences…"
                className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent resize-none"
              />
            </div>
          </div>
        )}
      </div>

      <button
        type="submit"
        disabled={isGenerating}
        className="w-full py-2.5 bg-accent text-background text-sm font-semibold tracking-widest uppercase hover:bg-accent-strong transition-colors disabled:opacity-40 disabled:cursor-not-allowed focus-visible:outline-accent"
      >
        Generate Build
      </button>

      <button
        type="button"
        onClick={handlePreview}
        disabled={isGenerating}
        className="w-full py-2.5 text-sm tracking-widest uppercase border border-line text-muted hover:text-foreground hover:border-foreground/40 transition-colors disabled:opacity-40 disabled:cursor-not-allowed focus-visible:outline-accent"
      >
        Preview Prompt
      </button>

      {preview && (
        <PromptPreviewDialog
          open
          onClose={() => setPreview(null)}
          title="Build Prompt Preview"
          preview={preview}
        />
      )}
    </form>
  );
}
