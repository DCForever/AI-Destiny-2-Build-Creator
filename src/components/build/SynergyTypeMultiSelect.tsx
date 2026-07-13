"use client";

import { useEffect, useMemo, useState } from "react";

import {
  Button,
  Chip,
  Cluster,
  DesignationIcon,
  Row,
  Stack,
  Text,
  useDesignationIcons,
} from "@/components/ui";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import {
  formatSynergyTypeDesignation,
  getSynergyTypeLabel,
  synergyTypeDesignationKey,
} from "@/lib/synergies/generateSynergyName";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import { compareDisplayName } from "@/lib/sortByName";

export type SynergyTypeSelection = {
  type: (typeof CREATABLE_SYNERGY_TYPES)[number];
  subType: string | null;
};

type SubTypeOption = { name: string; value?: string; icon?: string | null };

const SORTED_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

function selectionKey(s: SynergyTypeSelection): string {
  return synergyTypeDesignationKey(s);
}

/**
 * Production multi-select for build synergy type designations (type + optional subtype).
 */
export function SynergyTypeMultiSelect({
  selected,
  onChange,
  disabled,
}: {
  selected: SynergyTypeSelection[];
  onChange: (next: SynergyTypeSelection[]) => void;
  disabled?: boolean;
}) {
  const [draftType, setDraftType] =
    useState<(typeof CREATABLE_SYNERGY_TYPES)[number]>("verb");
  const [draftSubType, setDraftSubType] = useState("");
  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const needsSub = requiresSubType(draftType);

  useEffect(() => {
    if (!needsSub) return;
    let cancelled = false;
    void (async () => {
      const res = await fetch(
        `/api/catalog/synergy-pickers/subtypes?category=${encodeURIComponent(draftType)}`,
      );
      if (!res.ok || cancelled) return;
      const body = (await res.json()) as { options?: SubTypeOption[] };
      const options = body.options ?? [];
      setSubTypeOptions(options);
      setDraftSubType((prev) => prev || options[0]?.name || "");
    })();
    return () => {
      cancelled = true;
    };
  }, [draftType, needsSub]);

  function changeDraftType(next: (typeof CREATABLE_SYNERGY_TYPES)[number]) {
    setDraftType(next);
    if (!requiresSubType(next)) {
      setSubTypeOptions([]);
      setDraftSubType("");
    } else {
      setDraftSubType("");
      setSubTypeOptions([]);
    }
  }

  const selectedKeys = useMemo(
    () => new Set(selected.map(selectionKey)),
    [selected],
  );

  const { getIcon } = useDesignationIcons(selected);

  function addDraft() {
    if (needsSub && !draftSubType.trim()) return;
    const next: SynergyTypeSelection = {
      type: draftType,
      subType: needsSub ? draftSubType.trim() : null,
    };
    const key = selectionKey(next);
    if (selectedKeys.has(key)) return;
    onChange([...selected, next]);
  }

  function remove(key: string) {
    onChange(selected.filter((s) => selectionKey(s) !== key));
  }

  return (
    <Stack gap={10}>
      <Row gap={8} wrap align="end">
        <label className="flex flex-col gap-1 min-w-[140px] flex-1">
          <Text size="xs" tone="muted">
            Type
          </Text>
          <select
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground"
            value={draftType}
            disabled={disabled}
            onChange={(e) =>
              changeDraftType(
                e.target.value as (typeof CREATABLE_SYNERGY_TYPES)[number],
              )
            }
          >
            {SORTED_TYPES.map((t) => (
              <option key={t} value={t}>
                {getSynergyTypeLabel(t)}
              </option>
            ))}
          </select>
        </label>
        {needsSub ? (
          <label className="flex flex-col gap-1 min-w-[140px] flex-1">
            <Text size="xs" tone="muted">
              Subtype
            </Text>
            <select
              className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground"
              value={draftSubType}
              disabled={disabled}
              onChange={(e) => setDraftSubType(e.target.value)}
            >
              {subTypeOptions.length === 0 ? (
                <option value="">Loading…</option>
              ) : null}
              {subTypeOptions.map((o) => (
                <option key={o.name} value={o.name}>
                  {o.name}
                </option>
              ))}
            </select>
          </label>
        ) : (
          <Text size="xs" tone="muted" className="pb-2">
            No subtype for this category
          </Text>
        )}
        <Button
          size="sm"
          variant="accent"
          disabled={disabled || (needsSub && !draftSubType.trim())}
          onClick={addDraft}
        >
          Add type
        </Button>
      </Row>

      {selected.length === 0 ? (
        <Text size="xs" tone="muted">
          Designate at least one synergy type (intent).
        </Text>
      ) : (
        <Cluster gap={6}>
          {selected.map((s) => {
            const key = selectionKey(s);
            return (
              <Row key={key} gap={4} align="center">
                <DesignationIcon
                  type={s.type}
                  subType={s.subType}
                  icon={
                    getIcon(s.type, s.subType) ??
                    subTypeOptions.find((o) => o.name === s.subType)?.icon ??
                    null
                  }
                  size={22}
                  label={formatSynergyTypeDesignation(s)}
                />
                <Chip accent>{formatSynergyTypeDesignation(s)}</Chip>
                <Button
                  size="sm"
                  variant="ghost"
                  disabled={disabled}
                  onClick={() => remove(key)}
                >
                  Remove
                </Button>
              </Row>
            );
          })}
        </Cluster>
      )}
    </Stack>
  );
}
