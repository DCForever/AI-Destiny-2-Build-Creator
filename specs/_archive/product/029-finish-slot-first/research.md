# Research: Finish Slot-First Chrome

**Feature**: 029-finish-slot-first  
**Date**: 2026-07-23

## R1 — Reuse create-set-attach vs new endpoint

**Decision**: Keep `POST /api/user/builds/[id]/create-set-attach` and omit `name`/`tagIds` from Finish clients. Server already builds `${build.name} ${TypeLabel}` via `createSetAndAttach`.

**Rationale**: Spec FR-002 matches existing default naming; no API churn; Sets tab can still pass optional name.

**Alternatives considered**: New “finish-create” endpoint — unnecessary duplication.

## R2 — Where to strip chrome

**Decision**: Change **FinishBuildWalkthrough** category step only. Leave `CreateSetAttachForm` and `SetAttachPicker` on `VariantEditPanel` Sets tab.

**Rationale**: FR-008/FR-009; avoids regressing advanced create/link.

**Alternatives considered**: Delete form component — breaks Sets tab US1 from 028.

## R3 — Post-create navigation

**Decision**: After successful Create or Capture, re-evaluate gaps; if category `needs_fill` with live covering set, set step to `fill` with `fillSlot = emptySlots[0]` (first in required order). If satisfied, return overview / next category. Do not stay on category with create form.

**Rationale**: FR-003, FR-007; emptySlots already ordered from `REQUIRED_SLOTS` filters.

**Alternatives considered**: Manual “Fill empty” button list only (028) — fails SC-001 one-confirmation path.

## R4 — Slot-first loop after each fill

**Decision**: On `onFilled`, refresh resolved equipment + build detail, recompute gap for active category; if more `emptySlots`, open next first empty; else leave fill step to overview/next.

**Rationale**: FR-004; pure helper `nextFinishFillSlot(gap)` keeps React thin.

**Alternatives considered**: Show all empty slot buttons forever — not slot-first primary loop.

## R5 — Link existing in Finish

**Decision**: Remove SetAttachPicker from Finish category step. Users link from Sets tab; Finish then sees covering set and enters fill.

**Rationale**: Product decision + FR-008; still FR-009 on Sets tab.

**Alternatives considered**: Collapsed “Advanced: link” disclosure — rejected for this slice to match locked “hide link from Finish”.

## R6 — Capture UI density

**Decision**: Keep `CaptureSetsFromBuild` with category filter; ensure it appears **above** one-tap Create when `canCapture`; copy should read as preferred primary.

**Rationale**: FR-006; 028 already mounts Capture when `canCapture`.

## R7 — Mods

**Decision**: Mods with `needs_set` get one-tap Create mod set (no slot loop if `emptySlots` empty and satisfaction is set-or-coverage). No false capture if `canCapture` false.

**Rationale**: finishGaps mod path; FR-011.

## R8 — Armor vs 031

**Decision**: Armor uses identical Finish chrome and fill loop in 029. No branch to optimizer. Document hook point: 031 may intercept post-create when category === armor.

**Rationale**: FR-012.

## Cross-cutting

- No new SQLite tables.
- Auth unchanged on mutations.
- Gate after helpers and after UI.
- UI mock reference: weapons path in `docs/ui-mocks/finish-build-slot-first.html`.
