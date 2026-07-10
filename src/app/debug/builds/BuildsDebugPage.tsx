"use client";

import { useCallback, useMemo, useState } from "react";

import { conceptTagsByFacet } from "@/data/conceptTags";
import { ExoticArmorLookup } from "@/components/debug/ExoticArmorLookup";
import { ExoticWeaponLookup } from "@/components/debug/ExoticWeaponLookup";
import { SetAttachPicker } from "@/components/debug/SetAttachPicker";
import { SubclassStructuredForm, type SubclassFormValue } from "@/components/debug/SubclassStructuredForm";
import { SynergyMultiSelect } from "@/components/debug/SynergyMultiSelect";
import { VariantSelect } from "@/components/debug/VariantSelect";
import { mergeAttachment, removeAttachment, type AttachmentInput } from "@/lib/builds/attachmentMerge";
import { emptyLookupMessage, synergyIdentityFields } from "@/lib/debug/lookupParity";
import { sortByName } from "@/lib/sortByName";

type GuardianClass = "Titan" | "Hunter" | "Warlock";
type ExoticSelection = { hash: number; name: string };
type SynergySummary = { id: string; name: string; type: string };
type BuildSummary = { id: string; name: string; className?: string; exoticArmorHash?: number; exoticArmorName?: string };
type AttachmentRecord = AttachmentInput & { id?: string; set?: { name?: string; type?: string } };
type BuildVariant = {
  id: string;
  name: string;
  isDefault?: boolean;
  exoticWeaponHash: number | null;
  exoticWeaponName: string | null;
  artifactHash?: number | null;
  artifactName?: string | null;
  artifactConfig?: number[];
  notes: string | null;
  attachments: AttachmentRecord[];
};
type BuildDetail = BuildSummary & {
  className: GuardianClass;
  exoticArmorHash: number | null;
  exoticArmorName: string | null;
  exoticWeaponHash?: number | null;
  exoticWeaponName?: string | null;
  pinnedSuper?: string | null;
  softStatTargets?: Partial<Record<string, number>>;
  synergies: SynergySummary[];
  variants: BuildVariant[];
};
type JsonPanel = { label: string; request?: unknown; response?: unknown; error?: unknown };

const DEFAULT_SUBCLASS: SubclassFormValue = {
  name: "Sunbreaker",
  super: "",
  classAbility: "",
  movement: "",
  melee: "",
  grenade: "",
  aspects: [],
  fragments: [],
  rationale: "Debug build composition",
};

function buttonClass(disabled = false) {
  return `rounded px-3 py-1 text-sm ${disabled ? "bg-zinc-800 text-zinc-500" : "bg-emerald-700 text-white"}`;
}

function zincInputClass() {
  return "block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm";
}

function variantAttachments(variant: BuildVariant | null): AttachmentInput[] {
  return (variant?.attachments ?? []).map((attachment) => ({
    setId: attachment.setId,
    mode: attachment.mode,
  }));
}

export function BuildsDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [builds, setBuilds] = useState<BuildSummary[]>([]);
  const [selectedBuildId, setSelectedBuildId] = useState("");
  const [buildDetail, setBuildDetail] = useState<BuildDetail | null>(null);
  const [selectedVariantId, setSelectedVariantId] = useState("");
  const [availableSynergies, setAvailableSynergies] = useState<SynergySummary[]>([]);
  const [designationIds, setDesignationIds] = useState<string[]>([]);
  const [variantNotes, setVariantNotes] = useState("");
  const [artifactHashInput, setArtifactHashInput] = useState("");
  const [artifactConfigInput, setArtifactConfigInput] = useState("");
  const [softStatDraft, setSoftStatDraft] = useState("");
  const [suggestGoal, setSuggestGoal] = useState("");
  const [filterExoticArmor, setFilterExoticArmor] = useState<ExoticSelection | null>(null);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [advancedSubclassJson, setAdvancedSubclassJson] = useState(JSON.stringify(DEFAULT_SUBCLASS, null, 2));
  const [rawExoticArmorHash, setRawExoticArmorHash] = useState("");
  const [createForm, setCreateForm] = useState({
    name: "",
    className: "Titan" as GuardianClass,
    tagIds: ["solar", "pve"],
    exoticArmor: null as ExoticSelection | null,
    exoticWeapon: null as ExoticSelection | null,
    pinnedSuper: "",
    synergyIds: [] as string[],
    subclass: DEFAULT_SUBCLASS,
  });
  const [editExoticArmor, setEditExoticArmor] = useState<ExoticSelection | null>(null);
  const [pendingIdentityPayload, setPendingIdentityPayload] = useState<Record<string, unknown> | null>(null);
  const [loadoutGaps, setLoadoutGaps] = useState<string[]>([]);
  const [characters, setCharacters] = useState<
    Array<{ characterId: string; classType: GuardianClass; light: number }>
  >([]);
  const [equipCharacterId, setEquipCharacterId] = useState("");

  const record = useCallback((next: JsonPanel) => setPanel(next), []);
  const tagFacets = useMemo(() => conceptTagsByFacet(), []);
  const selectedVariant = useMemo(
    () => buildDetail?.variants.find((variant) => variant.id === selectedVariantId) ?? null,
    [buildDetail, selectedVariantId],
  );
  const selectedVariantName = selectedVariant?.name ?? "selected variant";
  const selectedVariantExoticWeapon = selectedVariant?.exoticWeaponHash
    ? { hash: selectedVariant.exoticWeaponHash, name: selectedVariant.exoticWeaponName ?? `Exotic (${selectedVariant.exoticWeaponHash})` }
    : null;
  const canUseVariant = Boolean(selectedBuildId && selectedVariantId && selectedVariant);
  const classFilteredCharacters = useMemo(() => {
    const buildClass = buildDetail?.className;
    if (!buildClass) return characters;
    return characters.filter((c) => c.classType === buildClass);
  }, [characters, buildDetail?.className]);
  const canEquip = Boolean(canUseVariant && equipCharacterId);
  const createBlockedMessage =
    availableSynergies.length === 0
      ? "Create is blocked until at least one synergy exists."
      : createForm.synergyIds.length === 0
        ? "Select at least one synergy designation before creating a build."
        : "";
  const createDisabled = Boolean(createBlockedMessage);

  const loadBuilds = useCallback(async () => {
    const hash = filterExoticArmor?.hash ?? (rawExoticArmorHash.trim() ? Number(rawExoticArmorHash.trim()) : null);
    const params = new URLSearchParams();
    if (hash) params.set("exoticArmorHash", String(hash));
    const query = params.toString() ? `?${params}` : "";
    const url = `/api/user/builds${query}`;
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok) setBuilds(sortByName((body.builds ?? []) as BuildSummary[]));
    record({ label: `GET ${url}`, response: body, error: res.ok ? undefined : body });
  }, [filterExoticArmor, rawExoticArmorHash, record]);

  const loadSynergies = useCallback(async () => {
    const res = await fetch("/api/user/synergies");
    const body = await res.json();
    if (res.ok) setAvailableSynergies(sortByName((body.synergies ?? []) as SynergySummary[]));
    record({ label: "GET /api/user/synergies", response: body, error: res.ok ? undefined : body });
  }, [record]);

  const loadBuildDetail = useCallback(
    async (id: string, preferredVariantId?: string) => {
      if (!id) {
        setBuildDetail(null);
        setSelectedVariantId("");
        setDesignationIds([]);
        return;
      }

      const url = `/api/user/builds/${id}`;
      const res = await fetch(url);
      const body = await res.json();
      if (!res.ok) {
        record({ label: `GET ${url}`, error: body });
        return;
      }

      const build = body.build as BuildDetail;
      const variants = build.variants ?? [];
      const preferred = variants.find((variant) => variant.id === preferredVariantId);
      const current = variants.find((variant) => variant.id === selectedVariantId);
      const fallback = variants.find((variant) => variant.isDefault) ?? variants[0] ?? null;
      setBuildDetail(build);
      setDesignationIds((build.synergies ?? []).map((synergy) => synergy.id));
      setSelectedVariantId((preferred ?? current ?? fallback)?.id ?? "");
      record({ label: `GET ${url}`, response: body });
    },
    [record, selectedVariantId],
  );

  function updateCreateForm(next: Partial<typeof createForm>) {
    setCreateForm((current) => ({ ...current, ...next }));
    if (next.subclass) setAdvancedSubclassJson(JSON.stringify(next.subclass, null, 2));
  }

  async function loadBuildData() {
    await loadSynergies();
    await loadBuilds();
  }

  function selectBuild(id: string) {
    setSelectedBuildId(id);
    void loadBuildDetail(id);
  }

  function toggleCreateTag(tagId: string, checked: boolean) {
    updateCreateForm({
      tagIds: checked
        ? [...new Set([...createForm.tagIds, tagId])]
        : createForm.tagIds.filter((id) => id !== tagId),
    });
  }

  async function createBuild() {
    if (createDisabled) {
      record({ label: "Create build blocked", error: { message: createBlockedMessage || "Fix create form." } });
      return;
    }

    let subclass = createForm.subclass;
    if (showAdvanced && advancedSubclassJson.trim()) {
      try {
        subclass = JSON.parse(advancedSubclassJson) as SubclassFormValue;
      } catch {
        record({ label: "Create build blocked", error: { message: "Advanced subclass JSON is invalid." } });
        return;
      }
    }

    const payload = {
      name: createForm.name.trim() || undefined,
      className: createForm.className,
      subclass,
      exoticArmorHash: createForm.exoticArmor?.hash ?? null,
      exoticArmorName: createForm.exoticArmor?.name ?? null,
      exoticWeaponHash: createForm.exoticWeapon?.hash ?? null,
      exoticWeaponName: createForm.exoticWeapon?.name ?? null,
      pinnedSuper: createForm.pinnedSuper.trim() || null,
      tagIds: createForm.tagIds,
      synergyIds: createForm.synergyIds,
      defaultVariant: { name: "Default" },
    };
    record({ label: "POST /api/user/builds", request: payload });
    const res = await fetch("/api/user/builds", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      const build = body.build as BuildDetail;
      setSelectedBuildId(build.id);
      await loadBuilds();
      await loadBuildDetail(build.id, build.variants?.[0]?.id);
    }
    record({ label: "POST /api/user/builds", request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function patchVariant(payload: Record<string, unknown>, label: string, preferredVariantId = selectedVariantId) {
    if (!selectedBuildId || !selectedVariantId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}`;
    record({ label, request: payload });
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      setLoadoutGaps([]);
      await loadBuildDetail(selectedBuildId, preferredVariantId);
    } else if (body?.code === "DEFAULT_VARIANT_INCOMPLETE") {
      const missing = Array.isArray(body.missing) ? (body.missing as string[]) : [];
      setLoadoutGaps(missing);
    }
    record({ label, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function attachSet(attachment: AttachmentInput) {
    if (!selectedVariant) return;
    const attachments = mergeAttachment(variantAttachments(selectedVariant), attachment);
    await patchVariant({ attachments }, `Attach to ${selectedVariant.name}`);
  }

  async function detachSet(setId: string) {
    if (!selectedVariant) return;
    const attachments = removeAttachment(variantAttachments(selectedVariant), setId);
    await patchVariant({ attachments }, `Remove set from ${selectedVariant.name}`);
  }

  async function saveDesignations() {
    if (!selectedBuildId) return;
    const url = `/api/user/builds/${selectedBuildId}`;
    const payload = { synergyIds: designationIds };
    record({ label: `PATCH ${url}`, request: payload });
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.status === 409 && body?.code === "IDENTITY_CONFIRM_REQUIRED") {
      setPendingIdentityPayload(payload);
      record({ label: `PATCH ${url}`, request: payload, error: body });
      return;
    }
    if (res.ok) await loadBuildDetail(selectedBuildId);
    record({ label: `PATCH ${url}`, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function saveExoticArmor() {
    if (!selectedBuildId) return;
    const url = `/api/user/builds/${selectedBuildId}`;
    const payload = {
      exoticArmorHash: editExoticArmor?.hash ?? null,
      exoticArmorName: editExoticArmor?.name ?? null,
    };
    record({ label: `PATCH ${url} exoticArmor`, request: payload });
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.status === 409 && body?.code === "IDENTITY_CONFIRM_REQUIRED") {
      setPendingIdentityPayload(payload);
      record({ label: `PATCH ${url} exoticArmor`, request: payload, error: body });
      return;
    }
    if (res.ok) {
      setEditExoticArmor(null);
      await loadBuildDetail(selectedBuildId);
    }
    record({
      label: `PATCH ${url} exoticArmor`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  async function confirmIdentityAction(action: "confirm" | "fork") {
    if (!selectedBuildId || !pendingIdentityPayload) return;
    const url = `/api/user/builds/${selectedBuildId}`;
    const payload = { ...pendingIdentityPayload, identityAction: action };
    record({ label: `PATCH ${url} (${action})`, request: payload });
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      setPendingIdentityPayload(null);
      const build = body.build as BuildDetail;
      setSelectedBuildId(build.id);
      await loadBuilds();
      await loadBuildDetail(build.id);
    }
    record({
      label: `PATCH ${url} (${action})`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  async function duplicateVariant() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants`;
    const payload = { duplicateFromVariantId: selectedVariantId, name: `${selectedVariantName} Copy`, notes: variantNotes || null };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    const copy = (body.build?.variants ?? []).find((variant: BuildVariant) => variant.name === payload.name);
    if (res.ok) await loadBuildDetail(selectedBuildId, copy?.id);
    record({ label: `POST ${url}`, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function fetchResolved() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/resolved`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: `GET ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function fetchCoverage() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/coverage`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: `GET ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function checkEquipGate() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/equip-gate`;
    const res = await fetch(url, { method: "POST" });
    const body = await res.json();
    record({ label: `POST ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function loadCharacters() {
    const url = "/api/bungie/characters";
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok && Array.isArray(body.characters)) {
      setCharacters(body.characters);
      const buildClass = buildDetail?.className;
      const filtered = buildClass
        ? body.characters.filter(
            (c: { classType: string }) => c.classType === buildClass,
          )
        : body.characters;
      if (filtered[0]?.characterId) setEquipCharacterId(filtered[0].characterId);
    }
    record({ label: `GET ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function equipVariant() {
    if (!canUseVariant || !equipCharacterId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/equip`;
    const payload = { characterId: equipCharacterId };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({
      label: `POST ${url}`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  async function checkDimExportGate() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/dim-export-gate`;
    const res = await fetch(url, { method: "POST" });
    const body = await res.json();
    record({ label: `POST ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function exportToDim(jsonOnly = false) {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/dim-export`;
    const payload = { jsonOnly };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({
      label: `POST ${url}`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  async function exportResolved() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/resolved`;
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok) {
      const href = URL.createObjectURL(new Blob([JSON.stringify(body, null, 2)], { type: "application/json" }));
      const anchor = document.createElement("a");
      anchor.href = href;
      anchor.download = `resolved-${selectedBuildId}-${selectedVariantId}.json`;
      anchor.click();
      URL.revokeObjectURL(href);
    }
    record({ label: `Export ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function compareVariantsCall() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/compare?variantIds=${encodeURIComponent(selectedVariantId)}`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: `GET ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function suggestSetsCall() {
    if (!canUseVariant) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/suggest-sets`;
    const payload = suggestGoal.trim() ? { goal: suggestGoal.trim() } : {};
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({ label: `POST ${url}`, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function suggestSynergiesCall() {
    if (!selectedBuildId) return;
    const url = `/api/user/builds/${selectedBuildId}/suggest-synergies`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: `GET ${url}`, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function suggestRollsCall() {
    const payload = {
      buildId: selectedBuildId || undefined,
      synergyIds: designationIds.length ? designationIds : undefined,
      limit: 5,
    };
    const res = await fetch("/api/user/suggestions/rolls", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({ label: "POST /api/user/suggestions/rolls", request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  return (
    <div className="grid min-w-0 gap-6 lg:grid-cols-2 [&>*]:min-w-0">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Build pipeline</h1>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Load builds</legend>
          <ExoticArmorLookup className={createForm.className} selected={filterExoticArmor} onSelect={setFilterExoticArmor} />
          <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadBuildData()}>
            Load synergies + builds
          </button>
          <select className={zincInputClass()} value={selectedBuildId} onChange={(event) => selectBuild(event.target.value)}>
            <option value="">Build —</option>
            {builds.map((build) => (
              <option key={build.id} value={build.id}>
                {build.name}
              </option>
            ))}
          </select>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Create build</legend>
          <input
            className={zincInputClass()}
            placeholder="Name (optional — blank derives default)"
            value={createForm.name}
            onChange={(event) => updateCreateForm({ name: event.target.value })}
          />
          <select
            className={zincInputClass()}
            value={createForm.className}
            onChange={(event) => updateCreateForm({ className: event.target.value as GuardianClass })}
          >
            <option value="Titan">Titan</option>
            <option value="Hunter">Hunter</option>
            <option value="Warlock">Warlock</option>
          </select>
          <ExoticArmorLookup
            className={buildDetail?.className ?? createForm.className}
            selected={createForm.exoticArmor}
            onSelect={(exoticArmor) => updateCreateForm({ exoticArmor })}
          />
          <button
            type="button"
            className={buttonClass(!createForm.exoticArmor)}
            disabled={!createForm.exoticArmor}
            onClick={() => updateCreateForm({ exoticArmor: null })}
          >
            Clear exotic armor
          </button>
          <ExoticWeaponLookup
            className={createForm.className}
            selected={createForm.exoticWeapon}
            onSelect={(exoticWeapon) => updateCreateForm({ exoticWeapon })}
          />
          <p className="text-xs text-zinc-500">Build-shared exotic weapon (identity when set)</p>
          <input
            className={zincInputClass()}
            placeholder="Pinned Super (optional identity)"
            value={createForm.pinnedSuper}
            onChange={(event) => updateCreateForm({ pinnedSuper: event.target.value })}
          />
          <div>
            <p className="mb-1 text-sm font-medium">Synergy designations</p>
            <SynergyMultiSelect
              synergies={availableSynergies}
              selectedIds={createForm.synergyIds}
              onChange={(synergyIds) => updateCreateForm({ synergyIds })}
            />
            {createBlockedMessage ? (
              <p className="mt-2 text-xs text-amber-300">
                {createBlockedMessage}{" "}
                <a className="underline" href="/debug/synergies">
                  Create a synergy first
                </a>
              </p>
            ) : null}
          </div>
          <SubclassStructuredForm
            className={createForm.className}
            value={createForm.subclass}
            onChange={(subclass) => updateCreateForm({ subclass })}
          />
          <div className="space-y-2">
            <p className="text-sm font-medium">Concept tags</p>
            {Object.entries(tagFacets).map(([facet, tags]) => (
              <div key={facet} className="flex flex-wrap gap-2 text-xs">
                <span className="w-20 text-zinc-500">{facet}</span>
                {tags.map((tag) => (
                  <label key={tag.id} className="flex items-center gap-1">
                    <input
                      type="checkbox"
                      checked={createForm.tagIds.includes(tag.id)}
                      onChange={(event) => toggleCreateTag(tag.id, event.target.checked)}
                    />
                    {tag.label}
                  </label>
                ))}
              </div>
            ))}
          </div>
          <button type="button" className={buttonClass(createDisabled)} disabled={createDisabled} onClick={() => void createBuild()}>
            Create build
          </button>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Variant accounting</legend>
          <VariantSelect variants={buildDetail?.variants ?? []} selectedId={selectedVariantId} onChange={setSelectedVariantId} allowClear />
          {selectedVariant ? (
            <p className="text-xs text-zinc-500">
              Active: {selectedVariant.name} · {selectedVariant.id}
            </p>
          ) : (
            <p className="text-xs text-zinc-500">{emptyLookupMessage("variant")}</p>
          )}
          <ExoticWeaponLookup
            className={createForm.className}
            selected={selectedVariantExoticWeapon}
            onSelect={(item) =>
              void patchVariant(
                {
                  exoticWeaponHash: item?.hash ?? null,
                  exoticWeaponName: item?.name ?? null,
                },
                item ? `Set exotic weapon on ${selectedVariantName}` : `Clear exotic weapon on ${selectedVariantName}`,
              )
            }
          />
          <label className="block text-xs text-zinc-400">
            Artifact hash
            <input
              className={zincInputClass()}
              placeholder="Manifest artifact hash"
              value={artifactHashInput || (selectedVariant?.artifactHash != null ? String(selectedVariant.artifactHash) : "")}
              onChange={(event) => setArtifactHashInput(event.target.value)}
            />
          </label>
          <label className="block text-xs text-zinc-400">
            Artifact config (comma perk hashes)
            <input
              className={zincInputClass()}
              placeholder="111,222"
              value={
                artifactConfigInput ||
                (selectedVariant?.artifactConfig?.length ? selectedVariant.artifactConfig.join(",") : "")
              }
              onChange={(event) => setArtifactConfigInput(event.target.value)}
            />
          </label>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className={buttonClass(!canUseVariant)}
              disabled={!canUseVariant}
              onClick={() => {
                const hashRaw = (artifactHashInput || String(selectedVariant?.artifactHash ?? "")).trim();
                const configRaw = (
                  artifactConfigInput ||
                  (selectedVariant?.artifactConfig ?? []).join(",")
                ).trim();
                const artifactConfig = configRaw
                  ? configRaw
                      .split(",")
                      .map((s) => Number(s.trim()))
                      .filter((n) => Number.isFinite(n) && n > 0)
                  : [];
                if (!hashRaw) {
                  void patchVariant(
                    { artifactHash: null, artifactConfig: [] },
                    `Clear artifact on ${selectedVariantName}`,
                  );
                  return;
                }
                const artifactHash = Number(hashRaw);
                if (!Number.isFinite(artifactHash)) return;
                void patchVariant(
                  { artifactHash, artifactConfig },
                  `Set artifact on ${selectedVariantName}`,
                );
              }}
            >
              Save artifact
            </button>
            <button
              type="button"
              className={buttonClass(!canUseVariant)}
              disabled={!canUseVariant}
              onClick={() => {
                setArtifactHashInput("");
                setArtifactConfigInput("");
                void patchVariant(
                  { artifactHash: null, artifactConfig: [] },
                  `Clear artifact on ${selectedVariantName}`,
                );
              }}
            >
              Clear artifact
            </button>
          </div>
          <input
            className={zincInputClass()}
            placeholder="Notes for duplicate"
            value={variantNotes}
            onChange={(event) => setVariantNotes(event.target.value)}
          />
          <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void duplicateVariant()}>
            Duplicate selected variant
          </button>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Attach / detach sets</legend>
          <SetAttachPicker
            disabled={!canUseVariant}
            onAttach={(attachment) => void attachSet(attachment)}
          />
          <p className="text-xs text-zinc-500">
            Attach to {selectedVariant ? selectedVariant.name : "a selected variant"}
          </p>
          {loadoutGaps.length > 0 ? (
            <p className="rounded border border-amber-700/60 bg-amber-950/40 px-2 py-1 text-xs text-amber-100">
              Default incomplete: missing {loadoutGaps.join(", ")}
            </p>
          ) : null}
          <div className="space-y-1">
            {(selectedVariant?.attachments ?? []).length === 0 ? (
              <p className="text-xs text-zinc-500">No sets attached to this variant.</p>
            ) : null}
            {(selectedVariant?.attachments ?? []).map((attachment) => (
              <div key={attachment.setId} className="flex items-center justify-between gap-2 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm">
                <span>
                  {attachment.set?.name ?? attachment.setId}
                  <span className="ml-2 text-xs text-zinc-500">{attachment.mode}</span>
                </span>
                <button type="button" className="rounded bg-zinc-700 px-2 py-0.5 text-xs" onClick={() => void detachSet(attachment.setId)}>
                  Remove
                </button>
              </div>
            ))}
          </div>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Synergy edit</legend>
          <SynergyMultiSelect synergies={availableSynergies} selectedIds={designationIds} onChange={setDesignationIds} />
          <button type="button" className={buttonClass(!selectedBuildId || designationIds.length === 0)} disabled={!selectedBuildId || designationIds.length === 0} onClick={() => void saveDesignations()}>
            Save designations
          </button>
          <div className="space-y-2 border-t border-zinc-800 pt-3">
            <p className="text-xs text-zinc-500">
              Build exotic armor (classic = hash identity; ClassItem = intent-lock). Current:{" "}
              {buildDetail?.exoticArmorHash
                ? `${buildDetail.exoticArmorName ?? "?"} (${buildDetail.exoticArmorHash})`
                : "none"}
            </p>
            <ExoticArmorLookup
              selected={editExoticArmor}
              onSelect={(exoticArmor) => setEditExoticArmor(exoticArmor)}
            />
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                className={buttonClass(!selectedBuildId)}
                disabled={!selectedBuildId}
                onClick={() => void saveExoticArmor()}
              >
                Save exotic armor
              </button>
              <button
                type="button"
                className={buttonClass(!editExoticArmor)}
                disabled={!editExoticArmor}
                onClick={() => setEditExoticArmor(null)}
              >
                Clear draft
              </button>
              <button
                type="button"
                className={buttonClass(!selectedBuildId || buildDetail?.exoticArmorHash == null)}
                disabled={!selectedBuildId || buildDetail?.exoticArmorHash == null}
                onClick={() => {
                  setEditExoticArmor(null);
                  void (async () => {
                    if (!selectedBuildId) return;
                    const url = `/api/user/builds/${selectedBuildId}`;
                    const payload = { exoticArmorHash: null, exoticArmorName: null };
                    const res = await fetch(url, {
                      method: "PATCH",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify(payload),
                    });
                    const body = await res.json();
                    if (res.status === 409 && body?.code === "IDENTITY_CONFIRM_REQUIRED") {
                      setPendingIdentityPayload(payload);
                    } else if (res.ok) await loadBuildDetail(selectedBuildId);
                    record({
                      label: `PATCH ${url} clear exoticArmor`,
                      request: payload,
                      response: res.ok ? body : undefined,
                      error: res.ok ? undefined : body,
                    });
                  })();
                }}
              >
                Clear build exotic
              </button>
            </div>
          </div>
          {pendingIdentityPayload ? (
            <div className="space-y-2 rounded border border-amber-700/60 bg-amber-950/40 p-2 text-xs text-amber-100">
              <p>Identity change requires confirm or fork.</p>
              <div className="flex flex-wrap gap-2">
                <button type="button" className={buttonClass()} onClick={() => void confirmIdentityAction("confirm")}>
                  Confirm in-place
                </button>
                <button type="button" className={buttonClass()} onClick={() => void confirmIdentityAction("fork")}>
                  Fork as new build
                </button>
                <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => setPendingIdentityPayload(null)}>
                  Cancel
                </button>
              </div>
            </div>
          ) : null}
          <div className="space-y-1 text-xs text-zinc-400">
            {(buildDetail?.synergies ?? []).map((synergy) => {
              const identity = synergyIdentityFields(synergy);
              return (
                <p key={identity.id}>
                  {identity.name} · {identity.type}
                </p>
              );
            })}
          </div>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Soft stat targets (build-level)</legend>
          <input
            className={zincInputClass()}
            placeholder='JSON e.g. {"Health":100,"Weapons":80}'
            value={
              softStatDraft ||
              (buildDetail?.softStatTargets ? JSON.stringify(buildDetail.softStatTargets) : "")
            }
            onChange={(event) => setSoftStatDraft(event.target.value)}
          />
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className={buttonClass(!selectedBuildId)}
              disabled={!selectedBuildId}
              onClick={() => {
                let softStatTargets: Record<string, number> = {};
                try {
                  const raw = softStatDraft.trim() || "{}";
                  softStatTargets = JSON.parse(raw) as Record<string, number>;
                } catch {
                  return;
                }
                void (async () => {
                  const url = `/api/user/builds/${selectedBuildId}`;
                  const payload = { softStatTargets };
                  const res = await fetch(url, {
                    method: "PATCH",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload),
                  });
                  const body = await res.json();
                  if (res.ok) await loadBuildDetail(selectedBuildId);
                  record({
                    label: `PATCH ${url} softStatTargets`,
                    request: payload,
                    response: res.ok ? body : undefined,
                    error: res.ok ? undefined : body,
                  });
                })();
              }}
            >
              Save soft targets
            </button>
            <button
              type="button"
              className={buttonClass(!selectedBuildId)}
              disabled={!selectedBuildId}
              onClick={() => {
                void (async () => {
                  const url = `/api/user/builds/${selectedBuildId}/suggest-stat-targets`;
                  const res = await fetch(url);
                  const body = await res.json();
                  record({
                    label: `GET ${url}`,
                    response: res.ok ? body : undefined,
                    error: res.ok ? undefined : body,
                  });
                })();
              }}
            >
              Suggest stat nudges
            </button>
            <button
              type="button"
              className={buttonClass(!selectedBuildId)}
              disabled={!selectedBuildId}
              onClick={() => {
                void (async () => {
                  const url = `/api/user/builds/${selectedBuildId}`;
                  const payload = { acceptStatNudges: true };
                  const res = await fetch(url, {
                    method: "PATCH",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload),
                  });
                  const body = await res.json();
                  if (res.ok) {
                    setSoftStatDraft("");
                    await loadBuildDetail(selectedBuildId);
                  }
                  record({
                    label: `PATCH ${url} acceptStatNudges`,
                    request: payload,
                    response: res.ok ? body : undefined,
                    error: res.ok ? undefined : body,
                  });
                })();
              }}
            >
              Accept nudges
            </button>
          </div>
        </fieldset>

        <fieldset className="space-y-3 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Suggestions / compare / export</legend>
          <input className={zincInputClass()} placeholder="Optional goal" value={suggestGoal} onChange={(event) => setSuggestGoal(event.target.value)} />
          <div className="flex flex-wrap gap-2">
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void suggestSetsCall()}>
              Suggest sets
            </button>
            <button type="button" className={buttonClass(!selectedBuildId)} disabled={!selectedBuildId} onClick={() => void suggestSynergiesCall()}>
              Suggest synergies
            </button>
            <button type="button" className={buttonClass(!selectedBuildId)} disabled={!selectedBuildId} onClick={() => void suggestRollsCall()}>
              Suggest rolls
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void compareVariantsCall()}>
              Compare selected
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void fetchResolved()}>
              Resolve
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void fetchCoverage()}>
              Fetch Coverage
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void checkEquipGate()}>
              Check equip gate
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void checkDimExportGate()}>
              Check DIM gate
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void exportToDim(true)}>
              Export to DIM (JSON)
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void exportToDim(false)}>
              Export to DIM
            </button>
            <button type="button" className={buttonClass(!canUseVariant)} disabled={!canUseVariant} onClick={() => void exportResolved()}>
              Export
            </button>
          </div>
          <div className="flex flex-wrap items-end gap-2">
            <button type="button" className={buttonClass(false)} onClick={() => void loadCharacters()}>
              Load characters
            </button>
            <label className="text-sm">
              Equip character
              <select
                className={zincInputClass()}
                value={equipCharacterId}
                onChange={(event) => setEquipCharacterId(event.target.value)}
                disabled={classFilteredCharacters.length === 0}
              >
                <option value="">Select…</option>
                {classFilteredCharacters.map((c) => (
                  <option key={c.characterId} value={c.characterId}>
                    {c.classType} · {c.light} ({c.characterId.slice(-6)})
                  </option>
                ))}
              </select>
            </label>
            <button type="button" className={buttonClass(!canEquip)} disabled={!canEquip} onClick={() => void equipVariant()}>
              Equip
            </button>
          </div>
        </fieldset>

        <details className="rounded border border-zinc-800 p-3" open={showAdvanced} onToggle={(event) => setShowAdvanced(event.currentTarget.open)}>
          <summary className="cursor-pointer text-sm font-medium">Advanced</summary>
          <div className="mt-3 space-y-2">
            <label className="block text-sm">
              Advanced raw exoticArmorHash filter
              <input className={zincInputClass()} value={rawExoticArmorHash} onChange={(event) => setRawExoticArmorHash(event.target.value)} />
            </label>
            <label className="block text-sm">
              Advanced subclass JSON override
              <textarea
                className="mt-1 block h-40 w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 font-mono text-xs"
                value={advancedSubclassJson}
                onChange={(event) => setAdvancedSubclassJson(event.target.value)}
              />
            </label>
          </div>
        </details>
      </section>

      <section>
        <h2 className="mb-2 text-sm font-medium">{panel.label}</h2>
        <div className="mb-3 rounded border border-zinc-800 bg-zinc-950 p-3 text-xs text-zinc-400">
          <p>Selected build: {selectedBuildId || "none"}</p>
          <p>Selected variant: {selectedVariantId || "none"}</p>
        </div>
        {panel.error !== undefined && (
          <pre className="mb-2 overflow-auto rounded bg-red-950/50 p-3 text-xs text-red-200">{JSON.stringify(panel.error, null, 2)}</pre>
        )}
        {panel.request !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Request</p>
            <pre className="mb-2 overflow-auto rounded bg-zinc-900 p-3 text-xs">{JSON.stringify(panel.request, null, 2)}</pre>
          </>
        )}
        {panel.response !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Response</p>
            <pre className="overflow-auto rounded bg-zinc-900 p-3 text-xs">{JSON.stringify(panel.response, null, 2)}</pre>
          </>
        )}
      </section>
    </div>
  );
}
