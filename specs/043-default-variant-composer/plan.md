# Implementation Plan: Default Variant Composer

**Branch**: `043-default-variant-composer` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/043-default-variant-composer/spec.md`

## Summary

Replace the multi-surface create → detail → Finish walkthrough / flat VariantEdit Sets dump with one **tabbed default-variant composer**: **General · Subclass · Armor & Mod Set (Reuse|Create+Optimize) · Weapon Set (Reuse|Create) · Finish** (always visible; equip/export gated). **New build** opens this shell on General (no separate CreateBuildPanel). Reuse existing set-attach, optimize workspace, finish-gaps, equip-ready, and create-build picker scoping; re-orchestrate UI and a small amount of pure helpers (tab gating, missing reasons, synergy-first weapon ranking, set name/tag inheritance on create).

## Technical Context

**Language/Version**: TypeScript 5.x / Next.js App Router (React 19 client components)

**Primary Dependencies**: Existing build UI (`BuildPage`, `VariantEditPanel`, `CreateBuildPanel`, `FinishBuildWalkthrough`, `FinishArmorOptimizeWorkspace`), lookups (`ManifestSearchPicker`, `SetAttachPicker`), set/build APIs (`create-set-attach`, sets list, variant PATCH), `finishGaps` / `equipReady`, Matte Flap Ledger UI primitives

**Storage**: Existing SQLite builds/variants/sets/synergies — **no domain schema rewrite**; optional set `conceptTags` + generated names on create-set-attach path

**Testing**: Vitest co-located unit tests for pure helpers; component-level tests where practical; `npm run gate`

**Target Platform**: Desktop-first web (local Next.js)

**Project Type**: Full-stack Next.js app (UI orchestration feature)

**Performance Goals**: Tab switches keep form state without remount thrash; set list loads on demand; optimize remains user-triggered

**Constraints**: Domain DAC/DBR hard blocks and soft-guidance never-auto-apply unchanged; live attach default; FR-022 tab locks; Finish always visible (clarify B)

**Scale/Scope**: Build page shell + composer tabs + helpers; retire CreateBuildPanel as primary New build path; fold Finish walkthrough equip actions into Finish tab; non-default variants share same shell

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: Stories map to vertical slices (shell+gating → General → Subclass → Armor Reuse → Armor Create/Optimize → Weapon → Finish → non-default parity). Each slice independently demoable.
- **II. Test-First (NON-NEGOTIABLE)**: New pure modules (`composerTabAccess`, `finishMissingReasons`, weapon synergy rank, set name/tag from synergies) get failing tests first; UI wiring follows.
- **III. Green Commit Checkpoints**: Commit after each story/sub-increment only when `npm run gate` is green.
- **IV. Co-located tests**: `*.test.ts` next to helpers under `src/lib/builds/` (or `src/lib/build/`).
- **V. Validation-first**: Reuse existing API validation; no new unvalidated external payloads.

Post-design: still compliant. No Complexity Tracking rows.

## Project Structure

### Documentation (this feature)

```text
specs/043-default-variant-composer/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── default-variant-composer-contract.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
src/components/build/
├── BuildPage.tsx                    # New build → composer; drop CreateBuildPanel primary path
├── DefaultVariantComposer.tsx       # NEW shell: tabs + draft/live modes
├── composer/
│   ├── GeneralTab.tsx               # NEW — intent, identity, artifact, soft guidance
│   ├── SubclassTab.tsx              # NEW — grouped abilities/aspects/fragments
│   ├── ArmorModSetTab.tsx           # NEW — Reuse | Create + Improve/Optimize
│   ├── WeaponSetTab.tsx             # NEW — Reuse | Create P/S/H
│   └── FinishTab.tsx                # NEW — missing reasons + equip/DIM (from BuildActions)
├── CreateBuildPanel.tsx             # Retire from primary New build (keep temporarily if debug/tests need)
├── VariantEditPanel.tsx             # Delegate to DefaultVariantComposer or thin wrapper
├── FinishBuildWalkthrough.tsx       # Deprecate as primary; logic/gaps reused by FinishTab / Armor create
├── FinishArmorOptimizeWorkspace.tsx # Embed under Armor Create / Improve
├── CreateSetAttachForm.tsx          # Reuse under Armor/Weapon Create
├── CaptureSetsFromBuild.tsx         # Optional secondary only (not primary chrome)
└── BuildActions.tsx                 # Equip/DIM surfaces consumed by FinishTab

src/lib/builds/
├── composerTabAccess.ts             # NEW — FR-022 gating
├── composerTabAccess.test.ts
├── finishMissingReasons.ts          # NEW — map finishGaps → Finish copy
├── finishMissingReasons.test.ts
├── finishGaps.ts                    # Existing completeness
├── equipReady.ts                    # Existing equip-ready
├── createSetAndAttach.ts            # Extend name + conceptTags from build synergies
└── weaponSynergyRank.ts             # NEW — FR-015 ordering helper
src/lib/builds/weaponSynergyRank.test.ts

docs/build-composer-flow - Future direction.excalidraw   # Canonical UX
docs/ui-mocks/default-variant-composer.html              # Optional HTML mock (plan UI rule)
```

**Structure Decision**: Single Next.js app; new composer under `src/components/build/composer/`; pure access/ranking helpers under `src/lib/builds/`. No new packages.

## Complexity Tracking

> None
