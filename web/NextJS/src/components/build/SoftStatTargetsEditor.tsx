"use client";

import { ARMOR_STAT_NAMES, STAT_MAX, type ArmorStatName } from "@/data/rules/statBenefits";
import {
  clampSoftStatDraftValue,
  type SoftStatDraft,
} from "@/lib/builds/softStatTargets";
import { Cluster, Stack, Text, TextField } from "@/components/ui";

export function SoftStatTargetsEditor({
  draft,
  onChange,
  disabled = false,
}: {
  draft: SoftStatDraft;
  onChange: (next: SoftStatDraft) => void;
  disabled?: boolean;
}) {
  function setStat(name: ArmorStatName, value: string) {
    onChange({ ...draft, [name]: value });
  }

  function clearStat(name: ArmorStatName) {
    onChange({ ...draft, [name]: "" });
  }

  function blurClamp(name: ArmorStatName) {
    const next = clampSoftStatDraftValue(draft[name] ?? "");
    if (next !== (draft[name] ?? "")) {
      onChange({ ...draft, [name]: next });
    }
  }

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted">
        Soft stat targets (Armor 3.0). Leave blank to clear a target. Values are
        1–{STAT_MAX}.
      </Text>
      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
        {ARMOR_STAT_NAMES.map((name) => (
          <Stack key={name} gap={4}>
            <TextField
              label={name}
              type="number"
              min={1}
              max={STAT_MAX}
              step={1}
              inputMode="numeric"
              disabled={disabled}
              value={draft[name] ?? ""}
              placeholder="—"
              onChange={(e) => setStat(name, e.target.value)}
              onBlur={() => blurClamp(name)}
            />
            {(draft[name] ?? "").trim() ? (
              <button
                type="button"
                className="text-xs text-muted hover:text-foreground text-left underline-offset-2 hover:underline disabled:opacity-50"
                disabled={disabled}
                onClick={() => clearStat(name)}
              >
                Clear {name}
              </button>
            ) : null}
          </Stack>
        ))}
      </div>
      <Cluster gap={6}>
        {ARMOR_STAT_NAMES.filter((n) => (draft[n] ?? "").trim()).map((name) => (
          <Text key={name} size="xs" tone="muted" as="span">
            {name}: {draft[name]}
          </Text>
        ))}
      </Cluster>
    </Stack>
  );
}
