# Implement plan: Sets Create wizard dual-truth (RES-SET-CREATE-01)

**Status:** approved (2026-08-10 — continue with workflow / plan gate)  
**Brief:** `docs/ux-redesign/sets/002-create-wizard-brief.md`  
**Mockups (approved):** `mockups/001-armor-desktop.html`, `…-mobile.html` (create steps)  
**Hosts:** windows (Capture exit); mobile structure-only  
**Blocking dual-truth gaps:** none (`blocking_gap_ids: []`)  
**Residual id:** RES-SET-CREATE-01  

---

## Gap vs ship today

| Mockup (SSoT) | Ship today |
| --- | --- |
| Multi-step Type → Class → Bonus → Name | Single-scroll `SetsCreateWizard` (all unlocked fields once Type+Class set) |
| Step dots + crumb `New set · type\|class\|bonus\|name` | Flat title “Create set”; no dots/crumb |
| Footer **Back** / **Continue** / **Cancel**; Create only on final | In-body **Create** after lock; no Back/Continue |
| One step visible at a time; choice-grid type/class | Type+Class always stacked; bonus+name when locked |
| Bonus searchable + EntityInfoHotspot **only on Bonus** | Goals editor appears with name when locked |
| Hide product-path **Quick create** | Rail header shows Quick create + keys reused by host tests |
| Post-create → empty **board** (layout A) | Persist + refresh list only; no auto `openBoard` |

Domain/app already OK: G-SET-013 helpers, auto-name, tags hard-block, `CreateSetCommand` with class/goals. **No purity package changes.** Do **not** change design tokens.

---

## Mockup region → Flutter map

| Mockup region (desktop create modal) | Surface | Widget / host |
| --- | --- | --- |
| Modal bar title + crumb | `sets.create` | `SetsLifecycleModal` title driven by step crumb (`New set · type` …) |
| `.wizard-steps` dots (on/done) | `sets.create` | `SetsCreateWizard` step chrome (`sets_create_step_dots`) |
| Type choice-grid | `sets.create.type` | Type step only — choice chips/buttons (`sets_create_type`) |
| Class choice-grid | `sets.create` | Class step only — Titan/Hunter/Warlock (`sets_create_class_*`) |
| Bonus goals catalog + info | `sets.create` | Step Bonus only: existing `SetsBonusGoalsEditor` + EntityInfoHotspot (do not reinvent) |
| Name + auto-name preview (+ optional tags) | `sets.create.name` / tags | Name step: field + preview; optional `SetsTagMultiSelect` (G-SET-033) if already wired |
| Modal foot Back / Cancel / Continue\|Create | G-SET-001 | `SetsLifecycleModal.footer` slots — not in-body primary |
| Non-Armor thin shell | `sets.create` | Skip Class/Bonus; final thin-create step |
| Empty board after create | `sets.detail` | Host: persist → select → `openBoard` → `SetsArmorBoard` empty layout A |
| Library New set entry | `sets.library` | `SetsLibraryWorkspace.onNewSet` → modal only |
| Quick create rail | — | **Hide** on product path; test-only flag if needed |
| Mobile sheet stack | same | Structure-only step machine in `mobile_host` |

Out of scope (do not reintroduce): owned fill/compare, Optimize primary cutover, full Neon non-Armor boards, Synergy Type chrome, token redesign.

---

## Package placement

| Layer | Change |
| --- | --- |
| **domain / sandbox_data** | None (already multi-goal + pure) |
| **app** | None required; reuse `resolveArmorSetName`, `CreateSetCommand`, tag block helpers |
| **ui_tokens** | **Do not** change design system tokens |
| **ui_flutter/sets** | Evolve `SetsCreateWizard` to step machine; optional small step-chrome helpers; keep `SetsLifecycleModal` footer |
| **windows_host/sets** | Step state on `SetsLifecycleController`; modal footer wiring; hide Quick create; post-create board |
| **mobile_host** | Structure-only stepped create sheet |
| **widgetbook** | Use-cases per step |
| **product-map** | `sets.create` flutter-windows partial→done after Capture; flow already form→board |

### Purity / layering

- Presentation-only in `ui_flutter`; host maps app DTOs.
- Reuse `loadArmorSetBonusFamilies` — no new IO package.
- No secrets; Public+PKCE unchanged.

---

## Step machine (product)

**Armor** (4 steps, index 0–3):

0. **Type** — choice-grid; Continue disabled until type selected (default Armor ok if preselected).  
1. **Class** — choice-grid; Continue until class; Back → Type.  
2. **Bonus** — optional None or legal G-SET-013; Continue always allowed (illegal combos rejected by editor).  
3. **Name** — name + auto-name preview; primary **Create** / mockup “Open empty board”; Back → Bonus.

**Non-Armor:** after Type Continue → thin shell name (or single thin step); **no** Class/Bonus; create thin set; **no** full board (status/select thin detail only).

Sentinel: `sets_create_pieces_hidden` while step &lt; Name (or always during create) so pieces/compare never mount in create modal.

Footer keys (stable for tests/Capture):

- `sets_create_back` (hidden step 0)  
- `sets_create_cancel`  
- `sets_create_continue` (steps 0–2 Armor; not final)  
- `sets_create_button` (Create only final step — keep key for migrate)

Chrome keys: `sets_create_step_dots`, `sets_create_crumb` (or title includes crumb), `sets_create_wizard` root.

---

## Files (primary ≤24)

| Path | Role |
| --- | --- |
| `flutter/packages/ui_flutter/lib/src/sets/sets_create_wizard.dart` | Step-index body: one step UI; dots; no in-body Create on early steps |
| `flutter/packages/ui_flutter/lib/src/sets/sets_lifecycle_modal.dart` | Footer already exists; ensure Back/Continue/Cancel layout slots if needed |
| `flutter/packages/ui_flutter/test/sets_armor_widgets_test.dart` | Step machine widget tests (Type/Class/Bonus/Name, non-Armor, pieces hidden) |
| `flutter/apps/windows_host/lib/sets/sets_lifecycle_controller.dart` | `createStep`, `canContinue`, `advance`/`back`, reset on `openCreate` |
| `flutter/apps/windows_host/lib/sets/sets_library_page.dart` | Wire modal footer; hide Quick create; post-create `openBoard` empty layout A |
| `flutter/apps/windows_host/test/sets_armor_host_smoke_test.dart` | Host smoke: stepped create → board |
| `flutter/apps/windows_host/test/sets_library_page_test.dart` | Migrate off Quick create → modal step path |
| `flutter/apps/windows_host/test/shell_primary_ui_functionality_test.dart` | Same key migration for create |
| `flutter/apps/windows_host/lib/sets/sets_armor_capture_fixtures.dart` | New must-shot ids + surface keys for 002 |
| `flutter/apps/windows_host/lib/main_sets_armor_capture.dart` | Scenario cases for create steps (or sibling capture target) |
| `flutter/apps/mobile_host/lib/sets/sets_structure_pages.dart` | Structure-only stepped sheet |
| `flutter/apps/mobile_host/test/sets_structure_smoke_test.dart` | Mobile create sheet step smoke |
| `flutter/apps/widgetbook/lib/use_cases/sets/armor_use_cases.dart` | Per-step / non-Armor use-cases |
| `docs/product-map/surfaces.yaml` | `sets.create` flutter-windows status after ship+Capture |
| `docs/product-map/flows.yaml` | Confirm `flow.sets.create` form→board (minor if phases already match) |
| `docs/ux-redesign/sets/implementation-shots/002-create-wizard/` | Capture package COMPARE + must PNGs |
| `docs/ux-redesign/sets/002-create-wizard-implement-plan.md` | This plan |

Supporting (same PR, out of JSON cap if needed): export barrel unchanged; `sets_bonus_goals_editor.dart` touch only if step-only visibility keys; Widgetbook `main.directories.g.dart` regen.

---

## Implementation steps (ordered)

1. **Controller step API** — `createStep`, `maxStep` (armor 3 / non-armor 1), `canContinueCreate`, `continueCreate`, `backCreate`; reset on `openCreate`.  
2. **`SetsCreateWizard` step body** — controlled `step` + draft props; render only active step; step dots; pieces-hidden sentinel always in create. Move Create out of early steps (footer or final-step only).  
3. **Host modal footer** — Back / Cancel / Continue|Create; title crumb; wire families loader only for Bonus step (may pre-load once).  
4. **Hide Quick create** — remove product rail tile; keep optional `showLegacyQuickCreate` / test harness only; update host tests.  
5. **Post-create board** — on successful Armor create: select set id → close create → `openBoard` → show empty `SetsArmorBoard` in lifecycle modal (layout A). Non-Armor: no board.  
6. **Mobile structure** — stepped sheet mirrors machine.  
7. **Widgetbook** — step fixtures.  
8. **Tests** — inventory below.  
9. **product-map:sync** after hub status bump.  
10. **Capture** — must matrix under `implementation-shots/002-create-wizard/`.

---

## Tests (always — not optional)

| Test | Proves |
| --- | --- |
| widget: Armor step 0 Type only; Continue disabled until type | step machine Type |
| widget: step 1 Class only; Continue until class; Back works | step machine Class |
| widget: step 2 Bonus optional; Continue always; illegal combo blocked | G-SET-013 |
| widget: step 3 Name + auto-name preview; Create present | final step |
| widget: Non-Armor skips Class/Bonus; thin shell create | non-Armor path |
| widget: pieces/compare never shown during any create step | G-SET-004/040 |
| widget: step dots + crumb reflect step | chrome dual-truth structure |
| widget: footer Back hidden on step 0; Create only final | footer contract |
| widget: empty board shell (post-create fixture) | layout A empty |
| widget: tags hard-block if tags on Name step | G-SET-033 |
| host smoke windows: library New → Type→Class→Bonus→Name Create → empty board | end-to-end |
| host: Quick create not visible on product rail | hide product path |
| host: non-Armor create thin (no board) | thin shell |
| mobile structure smoke: create sheet mounts steps | structure-only |
| Capture fixtures: must-shot keys registered | shot harness |

---

## Shot matrix (002-create-wizard)

Shots dir: `docs/ux-redesign/sets/implementation-shots/002-create-wizard/`

| id | must | proves | drive |
| --- | --- | --- | --- |
| `desktop-create-step-type` | true | step-dots; type-grid; continue-disabled-until-type; no-bonus-no-name | host-fixture |
| `desktop-create-step-class` | true | class-grid; pieces-hidden; back-visible | host-fixture |
| `desktop-create-step-bonus` | true | bonus-editor-only; searchable-catalog; entity-info-hotspot | host-fixture |
| `desktop-create-step-name` | true | name-field; auto-name-preview; create-primary | host-fixture |
| `desktop-create-post-board` | true | empty-board-layout-a; optimize-primary; five-pick | host-fixture |
| `desktop-create-no-quick-create` | true | library-new-only; no-quick-create-rail | host-fixture |
| `desktop-create-non-armor-thin` | false | skip-class-bonus; thin-shell | host-fixture |
| `widget-create-step-machine` | false | full step machine | widget-test-only |

At least one `must:true`. Prefer host-fixture for step chrome (live inventory not required).

---

## Product-map

- `sets.create` flutter-windows: `partial` → `done` after Capture must-rows.  
- `flow.sets.create` already: open → form (type/class/goals/name) → board — verify rules include G-SET-001/004/013/033/040.  
- Run `npm run product-map:sync` from monorepo root after hub edit.

---

## Risks

1. Host tests (`sets_library_page_test`, shell smoke) depend on Quick create keys — must migrate same PR or product still shows Quick create.  
2. Post-create board needs created set id after persist — race if refresh does not select new set.  
3. Moving Create into footer can break Capture/smoke that expect in-body `sets_create_button` before step 3.  
4. Non-Armor step index must not show Bonus editor or EntityInfoHotspot.  
5. Single-scroll residual reintroduced if host still mounts all fields.  
6. Capture harness still on 001 ids — add 002 scenarios without undoing Armor matrix.

---

## Acceptance

- [x] Armor: step 0 Type only; Continue disabled until type  
- [x] Armor: step 1 Class only; Continue until class; Back works  
- [x] Armor: step 2 Bonus optional legal G-SET-013; Continue always  
- [x] Armor: step 3 Name + auto-name; Create persists and selects set  
- [x] Non-Armor: skip Class/Bonus; thin shell works  
- [x] Pieces/compare never during create  
- [x] Quick create not on product Sets rail  
- [x] Post-create opens empty board layout A  
- [x] Widget tests + Windows host smoke  
- [x] Capture fixtures/harness under `002-create-wizard/` (PNGs pending driver Capture)  

**Shipped:** 2026-08-10 — RES-SET-CREATE-01 code dual-truth; Capture PNG checklist in `implementation-shots/002-create-wizard/COMPARE.md`.
