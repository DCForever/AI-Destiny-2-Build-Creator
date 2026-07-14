"use client";

import { useState } from "react";

import type { ArmorSlotName, WeaponSlotName } from "@/lib/manifest/types/records";
import type { ExoticFilterCriteria } from "@/lib/loadouts/types";
import {
  Button,
  Cluster,
  CollapsibleFilterSection,
  FilterChip,
  SelectField,
  Stack,
  Text,
} from "@/components/ui";

const ARMOR_SLOTS: ArmorSlotName[] = [
  "Helmet",
  "Gauntlets",
  "Chest",
  "Legs",
  "ClassItem",
];
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

export function LoadoutExoticFilterBar({
  criteria,
  armorOptions,
  weaponOptions,
  onChange,
  onClearAll,
}: LoadoutExoticFilterBarProps) {
  const [filtersOpen, setFiltersOpen] = useState(false);
  const armor = criteria.armor;
  const weapon = criteria.weapon;

  const activeCount =
    (armor ? 1 : 0) + (weapon ? 1 : 0);

  const summaryChips = (
    <Cluster gap={3}>
      {armor ? (
        <FilterChip
          size="xs"
          label={
            armor.mode === "exact"
              ? `Armor · ${armor.name || "exact"}`
              : `Armor · ${armor.slot ?? "slot"}`
          }
          active
          onClick={() => onChange({ ...criteria, armor: undefined })}
        />
      ) : null}
      {weapon ? (
        <FilterChip
          size="xs"
          label={
            weapon.mode === "exact"
              ? `Weapon · ${weapon.name || "exact"}`
              : `Weapon · ${weapon.slot ?? "slot"}`
          }
          active
          onClick={() => onChange({ ...criteria, weapon: undefined })}
        />
      ) : null}
    </Cluster>
  );

  return (
    <CollapsibleFilterSection
      open={filtersOpen}
      onOpenChange={setFiltersOpen}
      activeCount={activeCount}
      onClear={onClearAll}
      label="Exotic filters"
      summary={summaryChips}
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Stack gap={8}>
          <Text size="xs" weight="medium">
            Armor
          </Text>
          <SelectField
            label="Armor filter"
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
                    ? {
                        mode: "exact",
                        hash: first.hash ?? undefined,
                        name: first.name,
                      }
                    : { mode: "exact", name: "" },
                });
              } else {
                onChange({
                  ...criteria,
                  armor: { mode: "slot", slot: "Helmet" },
                });
              }
            }}
          >
            <option value="">All armor</option>
            <option value="exact">Exact exotic</option>
            <option value="slot">Slot type</option>
          </SelectField>
          {armor?.mode === "exact" && (
            <SelectField
              label="Exotic armor"
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
            </SelectField>
          )}
          {armor?.mode === "slot" && (
            <SelectField
              label="Armor slot"
              value={armor.slot ?? "Helmet"}
              onChange={(e) =>
                onChange({
                  ...criteria,
                  armor: {
                    mode: "slot",
                    slot: e.target.value as ArmorSlotName,
                  },
                })
              }
            >
              {ARMOR_SLOTS.map((slot) => (
                <option key={slot} value={slot}>
                  {slot}
                </option>
              ))}
            </SelectField>
          )}
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onChange({ ...criteria, armor: undefined })}
          >
            Clear armor
          </Button>
        </Stack>

        <Stack gap={8}>
          <Text size="xs" weight="medium">
            Weapon
          </Text>
          <SelectField
            label="Weapon filter"
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
                    ? {
                        mode: "exact",
                        hash: first.hash ?? undefined,
                        name: first.name,
                      }
                    : { mode: "exact", name: "" },
                });
              } else {
                onChange({
                  ...criteria,
                  weapon: { mode: "slot", slot: "Kinetic" },
                });
              }
            }}
          >
            <option value="">All weapons</option>
            <option value="exact">Exact exotic</option>
            <option value="slot">Slot type</option>
          </SelectField>
          {weapon?.mode === "exact" && (
            <SelectField
              label="Exotic weapon"
              value={weapon.name ?? ""}
              onChange={(e) => {
                const opt = weaponOptions.find(
                  (o) => o.name === e.target.value,
                );
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
            </SelectField>
          )}
          {weapon?.mode === "slot" && (
            <SelectField
              label="Weapon slot"
              value={weapon.slot ?? "Kinetic"}
              onChange={(e) =>
                onChange({
                  ...criteria,
                  weapon: {
                    mode: "slot",
                    slot: e.target.value as WeaponSlotName,
                  },
                })
              }
            >
              {WEAPON_SLOTS.map((slot) => (
                <option key={slot} value={slot}>
                  {slot}
                </option>
              ))}
            </SelectField>
          )}
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onChange({ ...criteria, weapon: undefined })}
          >
            Clear weapon
          </Button>
        </Stack>
      </div>
    </CollapsibleFilterSection>
  );
}
