# Feature Specification: Finish Armor Optimize UI
**Branch**: 031-finish-armor-optimize-ui | **Created**: 2026-07-23 | **Status**: Draft
**Input**: After Armor create/capture in Finish, open optimize workspace (V2+V5 wide / V6 narrow): goals, Find kits, top-3 compare, apply-combination.

**Prior**: 026, 028, 029, 030

## Scope
**In**: Finish armor path after covering set exists — constraints editor (synergy bonuses first, stats, toggles), run optimize with classType, top-3 compare + see all, apply kit in place, manual fill fallback, NO_INVENTORY guidance.
**Out**: Weapons optimizer; DIM LO; rewrite debug sets UI; changing 030 helpers beyond consumption.

## Stories
### US1 Goals then Find kits (P1)
After armor set attached empty/needs fill, show goals seeded from build; synergy-linked bonuses first; Find kits PATCHes constraints and optimizes with classType.
### US2 Top-3 compare and apply (P1)
Show top 3 kits with stats vs thresholds; Apply writes combination in place; armor category can satisfy.
### US3 Manual fill + errors (P2)
Manual fill fallback; empty/error reasons; inventory sync CTA when NO_INVENTORY.
### US4 Responsive chrome (P2)
Wide split goals|kits; narrow stacked chips + sticky apply.

## Requirements
FR-001 After armor create/capture (covering live set), Finish MUST open armor optimize workspace (not only slot list) when optimizer path available.
FR-002 Goals MUST seed exotic + soft stats via compose helpers; set-bonus picker synergy-first via 030 ranking.
FR-003 Find kits MUST PATCH optimizerConstraints then POST optimize with classType from build.
FR-004 Results MUST default top-3 compare with Apply per kit via apply-combination.
FR-005 See all N list escape required.
FR-006 Manual fill fallback required.
FR-007 emptyReason / errors surfaced; NO_INVENTORY suggests sync.
FR-008 Wide V2 split; narrow V6 stack (no forced dual pane).
FR-009 Weapons/Mods stay 029 slot-first.
FR-010 Skip for now / Exit preserved.

## Success
SC-001 Scripted Finish armor create → goals → find → apply fills 5 slots without Sets library.
SC-002 Synergy-linked bonuses appear above all list in goals UI.
SC-003 Gate green; 029 weapons path unchanged.
