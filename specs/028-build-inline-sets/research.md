# Research: Build Inline Sets

**Feature**: 028-build-inline-sets  
**Date**: 2026-07-23

## R1 — Walkthrough state: server session vs derived client

**Decision**: **Derive gaps from current variant state** (attachments + `resolveVariantEquipment`) on each open/step. Optional **client-only** UI state for current step index and which gaps the user chose Skip for now in this session (does not persist as satisfied).

**Rationale**:
- Spec: exit/resume must keep confirmed Sets/fills; skip must not mark satisfied (FR-022, FR-021).
- Durable server walkthrough table adds lifecycle without product need.
- Completeness already exists in domain via equipment resolution and DBR-CMPL-001.

**Alternatives considered**:
- Persist walkthrough session rows — overkill; drift vs attachments.
- URL-only deep step state — brittle for multi-step wizards.

## R2 — Gap evaluation module

**Decision**: Add pure `evaluateFinishGaps({ attachments, equipment, isDefaultVariant })` in `src/lib/builds/finishGaps.ts` returning ordered categories with status `satisfied | needs_set | needs_fill | capture_available`, empty slots, and covering set id when present.

**Rationale**:
- Testable without React; drives both banner and walkthrough.
- Required slots for default variant: all `ARMOR_SLOTS` and `WEAPON_SLOTS`; mods: soft/encouraged — treat **Mod** as unsatisfied when no mod-type set and no armor-slot mods if product already surfaces mod gaps; v1 minimum: Mod needs covering Mod Set **or** documented skip if no mod claims path (align create-sets mod skip).
- Covering Set: live (or any) attachment whose `set.type` maps to category (`armor`/`weapon`/`mod`). Pair does not auto-satisfy Armor/Weapons alone unless research later expands (v1 Pair is optional create path only).

**Alternatives considered**:
- Only client heuristics from attachment count — fails FR-021 empty attached Set case.
- Full equipReady gate as only signal — mixes pins/wishlist with set coverage.

## R3 — Create empty Set + attach

**Decision**: `createSetAndAttach` service: allocate unique name → `createSetRecord` / `createUserSet` → `replaceAttachmentByType` or merge live attach when no same-type live set (prefer replace-by-type for consistency with capture when user is finishing that category).

**Rationale**: Mirrors create-sets attach-now semantics; avoids two competing attach rules.

**Alternatives considered**:
- Attach without replace (allow multiple armor sets) — conflicts with finish clarity and BR-OPT-001 spirit for same-type live.

## R4 — Fill from Builds

**Decision**: Reuse `SlotFillPanel` (or extract shared fill controller) hosted inside walkthrough / variant editor with `set` loaded by id; onFilled refreshes build detail.

**Rationale**: Keeps slot legality, exotic exclusivity, instance pin in one place (008 path).

**Alternatives**: Duplicate catalog pickers in Builds — drift risk.

## R5 — Capture current gear

**Decision**: Call existing `POST /api/user/builds/[id]/create-sets` with `categories: [current]`, `attachNow: true`, `variantId`. Prefer button when `capture_available` (resolved claims ≥1 and no covering set, or covering set empty and claims exist — prefer capture when claims exist without full satisfaction via set items).

**Rationale**: Spec FR-023; 026 already implements armor/weapon snapshot; mod may skip — surface `skippedCategories`.

**Alternatives**: New capture endpoint — unnecessary.

## R6 — UI shell

**Decision**: `FinishBuildWalkthrough` modal or full-pane stepper on Builds: progress Armor/Weapons/Mods; step body switches create | link | capture | fill list; Skip for now / Exit.

**Rationale**: Primary path FR-018 without redesigning Sets library.

## R7 — Default vs non-default variants

**Decision**: Strong Finish CTA on **default** incomplete variants (DBR-CMPL-001). Non-default: optional softer entry; do not force full completeness (DBR-CMPL-002).

## R8 — Pair / Fashion

**Decision**: Pair available on create-type list (P3). Fashion excluded from walkthrough primary types.

## R9 — Post-v1 slice split

**Decision**: Freeze 028 as shipped v1. Split the Warp slot-first + Armor optimizer plan into **029** Finish chrome, **030** optimizer foundation (API/helpers), **031** Armor Finish UI.

**Rationale**: 028 tasks T001–T029 are complete and green; armor optimizer UI was explicitly out of 028 scope; rewriting shipped FR/US would falsely reopen acceptance. Follow-ons get their own Spec Kit lifecycle.

**Alternatives considered**: Extend 028 tasks in place (rejected — mixes shipped v1 with new scope); single mega-029 (rejected — user chose three logical slices).

## R10 — UI pairing locked (pointer for 031)

**Decision**: Desktop/wide = V2 split goals|kits + V5 top-3 compare; phone/narrow = V6 compact rail (sticky Apply, chip goals). Full research and implement live in **031**.

## Cross-cutting

- No new SQLite tables.
- Auth required for all mutations.
- Gate after each story.
- Fix any literal `` `r`n `` artifacts if found in specs during implement.
