"use client";

import type { ArmorSlotName, WeaponSlotName } from "@/lib/manifest/types/records";
import type { ExoticFilterCriteria } from "@/lib/loadouts/types";

const ARMOR_SLOTS: ArmorSlotName[] = ["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"];
const WEAPON_SLOTS: WeaponSlotName[] = ["Kinetic", "Energy", "Power"];

export interface ExoticPickerOption {
  hash: number | null;
  name: string;
}

interface LoadoutExoticFilterBarProps {
  criteria: ExoticFilterCriteria;
  armorOptions: ExoticPickerOption[];
  weaponOptions: ExoticPickerOption[];
  onChange: (criteria: ExoticFilterCriteria) => void;
  onClearAll: () => void;
}

function selectClassName() {
  return "text-xs border border-line bg-transparent px-2 py-1 text-foreground";
}

export function LoadoutExoticFilterBar({
  criteria,
  armorOptions,
  weaponOptions,
  onChange,
  onClearAll,
}: LoadoutExoticFilterBarProps) {
  const armor = criteria.armor;
  const weapon = criteria.weapon;

  return (
    <div className="panel-notch p-4 space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-[11px] tracking-widest uppercase text-muted">Exotic filters</h2>
        <button
          type="button"
          onClick={onClearAll}
          className="text-xs text-muted hover:text-foreground underline"
        >
          Clear all
        </button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <fieldset className="space-y-2">
          <legend className="text-xs text-foreground mb-1">Armor</legend>
          <select
            className={selectClassName()}
            value={armor?.mode ?? ""}
            onChange={(e) => {
              const mode = e.target.value;
              if (!mode) {
                onChange({ ...criteria, armor: undefined });
                return;
              }
              if (mode === "exact") {
                const first = armorOptions[0];
                onChange({
                  ...criteria,
                  armor: first
                    ? { mode: "exact", hash: first.hash ?? undefined, name: first.name }
                    : { mode: "exact", name: "" },
                });
              } else {
                onChange({ ...criteria, armor: { mode: "slot", slot: "Helmet" } });
              }
            }}
          >
            <option value="">All armor</option>
            <option value="exact">Exact exotic</option>
            <option value="slot">Slot type</option>
          </select>
          {armor?.mode === "exact" && (
            <select
              className={`${selectClassName()} w-full`}
              value={armor.name ?? ""}
              onChange={(e) => {
                const opt = armorOptions.find((o) => o.name === e.target.value);
                onChange({
                  ...criteria,
                  armor: {
                    mode: "exact",
                    hash: opt?.hash ?? undefined,
                    name: e.target.value,
                  },
                });
              }}
            >
              <option value="">Select exotic armor…</option>
              {armorOptions.map((o) => (
                <option key={o.name} value={o.name}>
                  {o.name}
                </option>
              ))}
            </select>
          )}
          {armor?.mode === "slot" && (
            <select
              className={`${selectClassName()} w-full`}
              value={armor.slot ?? "Helmet"}
              onChange={(e) =>
                onChange({
                  ...criteria,
                  armor: { mode: "slot", slot: e.target.value as ArmorSlotName },
                })
              }
            >
              {ARMOR_SLOTS.map((slot) => (
                <option key={slot} value={slot}>
                  {slot}
                </option>
              ))}
            </select>
          )}
          <button
            type="button"
            className="text-xs text-muted hover:text-foreground"
            onClick={() => onChange({ ...criteria, armor: undefined })}
          >
            Clear armor
          </button>
        </fieldset>

        <fieldset className="space-y-2">
          <legend className="text-xs text-foreground mb-1">Weapon</legend>
          <select
            className={selectClassName()}
            value={weapon?.mode ?? ""}
            onChange={(e) => {
              const mode = e.target.value;
              if (!mode) {
                onChange({ ...criteria, weapon: undefined });
                return;
              }
              if (mode === "exact") {
                const first = weaponOptions[0];
                onChange({
                  ...criteria,
                  weapon: first
                    ? { mode: "exact", hash: first.hash ?? undefined, name: first.name }
                    : { mode: "exact", name: "" },
                });
              } else {
                onChange({ ...criteria, weapon: { mode: "slot", slot: "Kinetic" } });
              }
            }}
          >
            <option value="">All weapons</option>
            <option value="exact">Exact exotic</option>
            <option value="slot">Slot type</option>
          </select>
          {weapon?.mode === "exact" && (
            <select
              className={`${selectClassName()} w-full`}
              value={weapon.name ?? ""}
              onChange={(e) => {
                const opt = weaponOptions.find((o) => o.name === e.target.value);
                onChange({
                  ...criteria,
                  weapon: {
                    mode: "exact",
                    hash: opt?.hash ?? undefined,
                    name: e.target.value,
                  },
                });
              }}
            >
              <option value="">Select exotic weapon…</option>
              {weaponOptions.map((o) => (
                <option key={o.name} value={o.name}>
                  {o.name}
                </option>
              ))}
            </select>
          )}
          {weapon?.mode === "slot" && (
            <select
              className={`${selectClassName()} w-full`}
              value={weapon.slot ?? "Kinetic"}
              onChange={(e) =>
                onChange({
                  ...criteria,
                  weapon: { mode: "slot", slot: e.target.value as WeaponSlotName },
                })
              }
            >
              {WEAPON_SLOTS.map((slot) => (
                <option key={slot} value={slot}>
                  {slot}
                </option>
              ))}
            </select>
          )}
          <button
            type="button"
            className="text-xs text-muted hover:text-foreground"
            onClick={() => onChange({ ...criteria, weapon: undefined })}
          >
            Clear weapon
          </button>
        </fieldset>
      </div>
    </div>
  );
}
