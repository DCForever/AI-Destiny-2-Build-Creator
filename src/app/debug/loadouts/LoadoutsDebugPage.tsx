"use client";

import { useCallback, useState } from "react";

import type { ExoticFilterCriteria } from "@/lib/loadouts/types";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

const ARMOR_SLOTS = ["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"] as const;
const WEAPON_SLOTS = ["Kinetic", "Energy", "Power"] as const;

function buildQuery(criteria: ExoticFilterCriteria): string {
  const params = new URLSearchParams();
  const armor = criteria.armor;
  const weapon = criteria.weapon;

  if (armor) {
    params.set("armorMode", armor.mode);
    if (armor.mode === "exact") {
      if (armor.hash !== undefined) params.set("armorHash", String(armor.hash));
      if (armor.name) params.set("armorName", armor.name);
    } else if (armor.slot) {
      params.set("armorSlot", armor.slot);
    }
  }

  if (weapon) {
    params.set("weaponMode", weapon.mode);
    if (weapon.mode === "exact") {
      if (weapon.hash !== undefined) params.set("weaponHash", String(weapon.hash));
      if (weapon.name) params.set("weaponName", weapon.name);
    } else if (weapon.slot) {
      params.set("weaponSlot", weapon.slot);
    }
  }

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function LoadoutsDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [armorMode, setArmorMode] = useState<"" | "exact" | "slot">("");
  const [armorHash, setArmorHash] = useState("");
  const [armorName, setArmorName] = useState("");
  const [armorSlot, setArmorSlot] = useState<(typeof ARMOR_SLOTS)[number]>("Helmet");
  const [weaponMode, setWeaponMode] = useState<"" | "exact" | "slot">("");
  const [weaponHash, setWeaponHash] = useState("");
  const [weaponName, setWeaponName] = useState("");
  const [weaponSlot, setWeaponSlot] = useState<(typeof WEAPON_SLOTS)[number]>("Kinetic");

  const record = useCallback((next: JsonPanel) => setPanel(next), []);

  async function fetchLoadouts() {
    const criteria: ExoticFilterCriteria = {};

    if (armorMode === "exact") {
      criteria.armor = {
        mode: "exact",
        hash: armorHash.trim() ? Number(armorHash) : undefined,
        name: armorName.trim() || undefined,
      };
    } else if (armorMode === "slot") {
      criteria.armor = { mode: "slot", slot: armorSlot };
    }

    if (weaponMode === "exact") {
      criteria.weapon = {
        mode: "exact",
        hash: weaponHash.trim() ? Number(weaponHash) : undefined,
        name: weaponName.trim() || undefined,
      };
    } else if (weaponMode === "slot") {
      criteria.weapon = { mode: "slot", slot: weaponSlot };
    }

    const query = buildQuery(criteria);
    const res = await fetch(`/api/user/loadouts${query}`);
    const body = await res.json();
    record({
      label: `GET /api/user/loadouts${query}`,
      response: body,
      error: res.ok ? undefined : body,
    });
  }

  return (
    <div className="space-y-6 max-w-3xl">
      <h1 className="text-lg font-medium">Loadouts — exotic filter API</h1>

      <div className="grid gap-4 sm:grid-cols-2 border border-zinc-800 p-4 rounded">
        <fieldset className="space-y-2">
          <legend className="text-sm text-zinc-400">Armor filter</legend>
          <select
            className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
            value={armorMode}
            onChange={(e) => setArmorMode(e.target.value as typeof armorMode)}
          >
            <option value="">None</option>
            <option value="exact">exact</option>
            <option value="slot">slot</option>
          </select>
          {armorMode === "exact" && (
            <>
              <input
                className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
                placeholder="armorHash"
                value={armorHash}
                onChange={(e) => setArmorHash(e.target.value)}
              />
              <input
                className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
                placeholder="armorName"
                value={armorName}
                onChange={(e) => setArmorName(e.target.value)}
              />
            </>
          )}
          {armorMode === "slot" && (
            <select
              className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
              value={armorSlot}
              onChange={(e) => setArmorSlot(e.target.value as typeof armorSlot)}
            >
              {ARMOR_SLOTS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          )}
        </fieldset>

        <fieldset className="space-y-2">
          <legend className="text-sm text-zinc-400">Weapon filter</legend>
          <select
            className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
            value={weaponMode}
            onChange={(e) => setWeaponMode(e.target.value as typeof weaponMode)}
          >
            <option value="">None</option>
            <option value="exact">exact</option>
            <option value="slot">slot</option>
          </select>
          {weaponMode === "exact" && (
            <>
              <input
                className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
                placeholder="weaponHash"
                value={weaponHash}
                onChange={(e) => setWeaponHash(e.target.value)}
              />
              <input
                className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
                placeholder="weaponName"
                value={weaponName}
                onChange={(e) => setWeaponName(e.target.value)}
              />
            </>
          )}
          {weaponMode === "slot" && (
            <select
              className="w-full bg-zinc-900 border border-zinc-700 px-2 py-1 text-sm"
              value={weaponSlot}
              onChange={(e) => setWeaponSlot(e.target.value as typeof weaponSlot)}
            >
              {WEAPON_SLOTS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          )}
        </fieldset>
      </div>

      <button
        type="button"
        onClick={() => void fetchLoadouts()}
        className="text-sm border border-zinc-600 px-4 py-2 hover:bg-zinc-900"
      >
        GET /api/user/loadouts
      </button>

      <div className="border border-zinc-800 rounded p-4">
        <p className="text-sm text-amber-400 mb-2">{panel.label}</p>
        <pre className="text-xs overflow-auto max-h-96 text-zinc-300">
          {JSON.stringify(panel.error ?? panel.response ?? panel.request, null, 2)}
        </pre>
      </div>
    </div>
  );
}
