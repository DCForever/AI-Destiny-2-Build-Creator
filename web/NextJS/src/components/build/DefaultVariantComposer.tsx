"use client";

import { useMemo, useState } from "react";

import type { BuildDetail, BuildVariantDetail, GuardianClass } from "@/components/build/types";
import { ArmorModSetTab } from "@/components/build/composer/ArmorModSetTab";
import { FinishTab } from "@/components/build/composer/FinishTab";
import { GeneralTab } from "@/components/build/composer/GeneralTab";
import { SubclassTab } from "@/components/build/composer/SubclassTab";
import { WeaponSetTab } from "@/components/build/composer/WeaponSetTab";
import {
  COMPOSER_TABS,
  type ComposerMode,
  type ComposerTab,
} from "@/components/build/composer/types";
import { Button, Callout, Cluster, FilterChip, Panel, Row, Stack, Text } from "@/components/ui";
import { composerTabAccess } from "@/lib/builds/composerTabAccess";
import type { createBuildPayload } from "@/lib/build/createBuildPayload";

export function DefaultVariantComposer({
  mode: _ignoredMode,
  build,
  variant,
  onClose,
  onCreated,
  onSaved,
  onEquip,
  onDimExport,
  onDimJson,
  characters,
  characterId,
  onCharacterId,
  actionBusy,
  actionMessage,
  createBusy,
  createError,
}: {
  mode: ComposerMode;
  build?: BuildDetail | null;
  variant?: BuildVariantDetail | null;
  onClose: () => void;
  onCreated: (input: ReturnType<typeof createBuildPayload>) => void | Promise<void>;
  onSaved: (next: BuildDetail, preferredVariantId?: string) => void;
  onEquip: () => void;
  onDimExport: () => void;
  onDimJson: () => void;
  characters: import("@/components/build/types").BungieCharacter[];
  characterId: string;
  onCharacterId: (id: string) => void;
  actionBusy: string | null;
  actionMessage: string | null;
  createBusy?: boolean;
  createError?: string | null;
}) {
  void _ignoredMode;
  const [tab, setTab] = useState<ComposerTab>("general");
  const [draftClass, setDraftClass] = useState<GuardianClass | null>(
    build?.className ?? null,
  );
  const [draftSubclass, setDraftSubclass] = useState<string | null>(
    build?.subclass?.name ?? null,
  );
  const [localError, setLocalError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const mode: ComposerMode = build?.id && variant?.id ? "live" : "draft";
  const className = mode === "live" ? build!.className : draftClass;
  const subclassName = mode === "live" ? build!.subclass?.name ?? null : draftSubclass;
  const buildId = build?.id ?? null;

  const access = useMemo(
    () =>
      composerTabAccess({
        tab,
        className,
        subclassName,
        buildId,
      }),
    [tab, className, subclassName, buildId],
  );

  function trySelectTab(next: ComposerTab) {
    const a = composerTabAccess({ tab: next, className, subclassName, buildId });
    if (!a.allowed) {
      setLocalError(a.reason ?? "Tab locked");
      return;
    }
    setLocalError(null);
    setTab(next);
  }

  return (
    <Panel tone="raised" pad="md">
      <Stack gap={12}>
        <Row justify="between" align="center" wrap gap={8}>
          <Text size="sm" className="font-display uppercase tracking-widest">
            {mode === "draft" ? "New build · composer" : `${build?.name ?? "Build"} · edit`}
          </Text>
          <Button size="sm" variant="ghost" onClick={onClose}>
            Close
          </Button>
        </Row>

        <Cluster gap={4}>
          {COMPOSER_TABS.filter((t) => t.isArea).map((t) => {
            const a = composerTabAccess({
              tab: t.id,
              className,
              subclassName,
              buildId,
            });
            return (
              <FilterChip
                key={t.id}
                label={t.label}
                active={tab === t.id}
                disabled={!a.allowed}
                onClick={() => trySelectTab(t.id)}
              />
            );
          })}
          {/* Finish is equip/export chrome (DBR-CMPL-005 — not a fifth product area). */}
          {COMPOSER_TABS.filter((t) => !t.isArea).map((t) => {
            const a = composerTabAccess({
              tab: t.id,
              className,
              subclassName,
              buildId,
            });
            return (
              <FilterChip
                key={t.id}
                label={t.label}
                active={tab === t.id}
                disabled={!a.allowed}
                onClick={() => trySelectTab(t.id)}
                className="ml-1 border-dashed opacity-95"
              />
            );
          })}
        </Cluster>

        {localError ? <Callout tone="warning">{localError}</Callout> : null}
        {message ? <Callout tone="success">{message}</Callout> : null}
        {createError ? <Callout tone="danger">{createError}</Callout> : null}
        {!access.mutationsAllowed && tab !== "general" && tab !== "finish" ? (
          <Text size="xs" tone="muted">
            {access.mutationReason}
          </Text>
        ) : null}

        {tab === "general" ? (
          <GeneralTab
            mode={mode}
            build={build ?? null}
            variant={variant ?? null}
            busy={Boolean(createBusy)}
            onDraftClass={setDraftClass}
            onDraftSubclass={setDraftSubclass}
            onCreate={(payload) => void onCreated(payload)}
            onSaved={onSaved}
            onMessage={setMessage}
            onError={setLocalError}
          />
        ) : null}
        {tab === "subclass" && build && variant ? (
          <SubclassTab
            build={build}
            variant={variant}
            onSaved={onSaved}
            onMessage={setMessage}
            onError={setLocalError}
          />
        ) : null}
        {tab === "armor" && build && variant ? (
          <ArmorModSetTab
            build={build}
            variant={variant}
            mutationsAllowed={access.mutationsAllowed}
            mutationReason={access.mutationReason}
            onSaved={onSaved}
            onMessage={setMessage}
            onError={setLocalError}
          />
        ) : null}
        {tab === "weapon" && build && variant ? (
          <WeaponSetTab
            build={build}
            variant={variant}
            mutationsAllowed={access.mutationsAllowed}
            mutationReason={access.mutationReason}
            onSaved={onSaved}
            onMessage={setMessage}
            onError={setLocalError}
          />
        ) : null}
        {tab === "finish" ? (
          <FinishTab
            build={build ?? null}
            variant={variant ?? null}
            characters={characters}
            characterId={characterId}
            onCharacterId={onCharacterId}
            busy={actionBusy}
            message={actionMessage}
            onEquip={onEquip}
            onDimExport={onDimExport}
            onDimJson={onDimJson}
          />
        ) : null}
      </Stack>
    </Panel>
  );
}
