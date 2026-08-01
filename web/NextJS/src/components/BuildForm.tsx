"use client";

import { useCallback, useEffect, useState } from "react";
import { SUBCLASSES_BY_CLASS, formatSubclassLabel } from "@/data/subclasses";
import { KNOWN_WEAPON_TYPES, toggleWeaponType } from "@/data/weaponTypes";
import { ExoticArmorLookup } from "@/components/debug/ExoticArmorLookup";
import { WeaponNameLookup } from "@/components/debug/WeaponNameLookup";
import { PromptPreviewDialog } from "@/components/PromptPreviewDialog";
import { composeBuildPromptPreview, type PromptPreview } from "@/lib/llm/composePromptPreview";
import type { BuildRequest } from "@/lib/llm/buildSchema";
import { buildFormPreferenceFields } from "@/lib/llm/buildFormPreferences";
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
  preferredExotic: { hash: number; name: string } | null;
  preferredWeapon: { hash: number; name: string } | null;
  notes: string;
  generationMode: GenerationMode;
  weaponTypesInclude: string[];
  weaponTypesExclude: string[];
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
    preferredExotic: null,
    preferredWeapon: null,
    notes: "",
    generationMode: DEFAULT_PREFERENCES.defaultGenerationMode ?? "standard",
    weaponTypesInclude: [],
    weaponTypesExclude: [],
    prioritizeOwned: false,
  });
  const [prefsOpen, setPrefsOpen] = useState(false);
  const [errors, setErrors] = useState<Partial<Record<"subclass" | "activity" | "playstyle", string>>>({});
  const [preview, setPreview] = useState<PromptPreview | null>(null);
  const [prefsLoaded, setPrefsLoaded] = useState(false);

  const set = (key: "subclass" | "activity" | "playstyle" | "notes", value: string) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const setClassName = (className: BuildRequest["className"]) =>
    setForm((prev) => ({ ...prev, className, subclass: "", preferredExotic: null }));

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
    const next: Partial<Record<"subclass" | "activity" | "playstyle", string>> = {};
    if (!form.subclass.trim()) next.subclass = "Required";
    if (!form.activity.trim()) next.activity = "Required";
    if (!form.playstyle.trim()) next.playstyle = "Required";
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const buildRequest = (): BuildRequest => {
    const prefs = buildFormPreferenceFields({
      preferredExotic: form.preferredExotic?.name ?? null,
      preferredWeapon: form.preferredWeapon?.name ?? null,
      weaponTypesInclude: form.weaponTypesInclude,
      weaponTypesExclude: form.weaponTypesExclude,
      prioritizeOwned: form.prioritizeOwned,
      notes: form.notes,
    });

    return {
      className: form.className,
      subclass: form.subclass.trim(),
      activity: form.activity.trim(),
      playstyle: form.playstyle.trim(),
      generationMode: form.generationMode,
      ...prefs,
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
            <ExoticArmorLookup
              className={form.className}
              selected={form.preferredExotic}
              onSelect={(item) => setForm((prev) => ({ ...prev, preferredExotic: item }))}
            />
            <WeaponNameLookup
              selected={form.preferredWeapon}
              onSelect={(item) => setForm((prev) => ({ ...prev, preferredWeapon: item }))}
            />
            <div className="space-y-2">
              <span className="text-[11px] tracking-widest uppercase text-muted">Weapon types to include</span>
              <div className="flex flex-wrap gap-2">
                {KNOWN_WEAPON_TYPES.map((type) => {
                  const active = form.weaponTypesInclude.includes(type);
                  return (
                    <button
                      key={`include-${type}`}
                      type="button"
                      className={`border px-2 py-1 text-xs ${
                        active ? "border-accent text-accent" : "border-line text-muted"
                      }`}
                      onClick={() =>
                        setForm((prev) => ({
                          ...prev,
                          weaponTypesInclude: toggleWeaponType(prev.weaponTypesInclude, type),
                        }))
                      }
                    >
                      {type}
                    </button>
                  );
                })}
              </div>
            </div>
            <div className="space-y-2">
              <span className="text-[11px] tracking-widest uppercase text-muted">Weapon types to exclude</span>
              <div className="flex flex-wrap gap-2">
                {KNOWN_WEAPON_TYPES.map((type) => {
                  const active = form.weaponTypesExclude.includes(type);
                  return (
                    <button
                      key={`exclude-${type}`}
                      type="button"
                      className={`border px-2 py-1 text-xs ${
                        active ? "border-accent text-accent" : "border-line text-muted"
                      }`}
                      onClick={() =>
                        setForm((prev) => ({
                          ...prev,
                          weaponTypesExclude: toggleWeaponType(prev.weaponTypesExclude, type),
                        }))
                      }
                    >
                      {type}
                    </button>
                  );
                })}
              </div>
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
        {isGenerating ? "Generating…" : "Generate Build"}
      </button>
      <button
        type="button"
        onClick={handlePreview}
        disabled={isGenerating}
        className="w-full py-2 border border-line text-xs tracking-widest uppercase text-muted hover:text-foreground transition-colors disabled:opacity-40 focus-visible:outline-accent"
      >
        Preview prompt
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
