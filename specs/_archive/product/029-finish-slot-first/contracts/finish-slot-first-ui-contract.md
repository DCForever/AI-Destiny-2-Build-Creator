# Contract: Finish slot-first UI

**Feature**: 029-finish-slot-first  
**Date**: 2026-07-23

## Shell

`FinishBuildWalkthrough` remains the Finish host (overview · category · fill · done). Category order chips Armor → Weapons → Mods unchanged.

## Category step — MUST show

- Status + covering set name when present
- **Capture** control when `canCapture` (preferred placement above Create)
- **One-tap Create** button labeled for category (e.g. “Create Weapons set & fill”) when status is `needs_set` or `capture_available`
- **Skip for now**, Back/Exit
- When `needs_fill` + live: either auto-entered fill step or immediate path into first empty slot (not a create form)

## Category step — MUST NOT show (Finish only)

- Name text field
- Type chip selector
- Concept tag picker
- Attach live/snapshot mode toggle
- `SetAttachPicker` / “Or link an existing Set” block

## Fill step

- Host `BuildSlotFillHost` for current `slot` on live `coveringSetId`
- On filled: re-evaluate; if more empty required slots, open next without returning to create chrome
- On close without fill: return to category or overview without losing covering set

## Overview

- List unsatisfied gaps; Continue opens category in simplified mode
- Complete → done success callout

## Sets tab (VariantEditPanel) — MUST retain

- CreateSetAttachForm (name optional, type chips, pair if allowed)
- SetAttachPicker / link existing
- Capture entry if already present outside Finish

## Copy

- Walkthrough subtitle should describe create/capture then fill slots — not “link” as primary.
