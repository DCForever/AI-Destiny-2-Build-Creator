---
target: Synergy main page
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
timestamp: 2026-07-22T20-09-56Z
slug: src-components-synergy-synergypage-tsx
---
# Critique: Synergy main page

**Target:** src/components/synergy/SynergyPage.tsx (+ Filters, Library, Detail, EditPanel)
**Mode:** Operate
**Method:** dual-agent Assessment A (019f8b6e-249d-76bb-9b02-c4b342615b0c); Assessment B blocked — parent completed CLI detector only; browser overlays unavailable

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Row select → loadDetail has no pending state; previous detail can linger |
| 2 | Match System / Real World | 3 | Strong Destiny designation language; "survivor" / "submenu" / draft jargon |
| 3 | User Control and Freedom | 3 | Back/clear work; no dirty Close warn; no undo after merge/delete |
| 4 | Consistency and Standards | 2 | Native window.confirm, raw checkboxes/textarea vs Vault Terminal primitives |
| 5 | Error Prevention | 3 | Merge designation guard + link rules; survivor easy to mis-set |
| 6 | Recognition Rather Than Recall | 2 | Check vs select vs survivor is a three-mode mental model |
| 7 | Flexibility and Efficiency | 2 | Merge/duplicate/check-all exist; no keyboard accelerators; explicit Search click |
| 8 | Aesthetic and Minimalist Design | 2 | Detail repeats designation chrome; library bulk actions equal weight |
| 9 | Error Recovery | 2 | Callouts name failures generically; no undo after destructive ops |
| 10 | Help and Documentation | 2 | InfoHotspots help experts; no first-run why-synergies-exist |
| **Total** | | **23/40** | **Acceptable** |

## Design Specificity Verdict

**LLM (Assessment A):** Mostly authored for this product. DesignationLabel + coverage counts + link-kind EntityHotspots + same-designation merge encode Destiny compose intent. Leaks: browser confirms, raw form controls, clerk-style edit search, CMS-adjacent bulk chrome.

**Deterministic scan (Assessment B / parent CLI):** `detect.mjs --json` on all five synergy components → `[]`, exit 0. No token/spacing/contrast rule hits. Clean scan does not clear IA or status issues above.

**Visual overlays:** Not available. Assessment B blocked; no browser automation/injection in this run. No user-visible overlay claimed.

## Overall Impression

Domain bones are real Vault Terminal craft: designation-first library, dual-pane Workspace, coverage badges. The page still operates like a private CMS with a high-stakes merge bolted onto browse. Biggest opportunity: make selection status and merge survivor unmistakable, then demote clerk friction in create/edit.

## What's Working

1. **Designation as identity** — Type:Subtype via DesignationLabel, immutable on edit, feeds Build coverage language.
2. **Operate shell** — PageFrame + collapsible filters + Workspace focusMain/back matches Sets/Catalog contracts.
3. **Domain-aware merge** — Same-designation constraint, Merge N, blocked reasons encode library hygiene.

## Priority Issues

### P1 — Stale/invisible detail while loading selection
- **What:** onSelect sets id and void loadDetail with no detailPending; previous detail can remain.
- **Why:** Wrong mental object for edit/delete.
- **Fix:** pending id + skeleton; ignore stale responses; never show detail.id ≠ selectedId.
- **Suggested command:** /impeccable harden

### P1 — Merge survivor under-signaled
- **What:** Survivor = selected if checked else first checked; tiny "· survivor" + window.confirm.
- **Why:** Destructive library surgery; wrong survivor retains wrong row.
- **Fix:** Explicit survivor picker / confirm panel listing absorbed rows; VT dialog not window.confirm.
- **Suggested command:** /impeccable shape (or /impeccable clarify + harden)

### P1 — Create/Edit is clerk-form
- **What:** Manual Search click, raw textarea, silent Close discard, generic "add a link" errors.
- **Why:** Starves Build coverage quality; breaks arsenal fantasy.
- **Fix:** Debounced search / Enter; dirty Close; focus invalid; sticky designation preview; coaching empty draft.
- **Suggested command:** /impeccable polish (edit path) + /impeccable clarify

### P2 — Type IA is a 15-chip wall
- **What:** Full CREATABLE_SYNERGY_TYPES flat in filters and create.
- **Why:** Exceeds working memory.
- **Fix:** Group families or progressive type pick; optional counts from library.
- **Suggested command:** /impeccable layout or /impeccable distill

### P2 — Empty main underuses EmptyState
- **What:** Description only; New only in rail.
- **Why:** Wide main feels abandoned; narrow after back worse.
- **Fix:** Title + New synergy CTA + one-line role in Build coverage.
- **Suggested command:** /impeccable onboard

### P3 — Detail header repeats designation
- **What:** H1 label + type badge + subtype chip again.
- **Why:** Noise floor.
- **Fix:** One identity block; badges as status row only.
- **Suggested command:** /impeccable quieter or /impeccable distill

## Cognitive load

6/8 checklist failures (high). Decision points >4: 15 type chips; 5 library actions; dense subtype lists; 6 link kinds.

## Persona Red Flags

**Alex:** No keyboard accelerators; Search is click-only; merge survivor easy to misfire; window.confirm interrupt; no undo.

**Jordan:** "subtype submenu" / survivor / objects linked jargon; empty main no Create; never defines synergy vs set vs build; type+ cryptic.

**Sam:** window.confirm focus; dual checkbox+row button; selection via tone only (aria-current missing); detail fetch no aria-busy; hotspot hover-pin risk.

## Minor Observations

- Signed-in vs signed-out header copy diverge; both awkward.
- prefillType uses typeFilter[0] arbitrarily when multi-type.
- Filter subtype remove chips ≠ FilterChip summary pattern.
- Delete confirm uses detail.name not designation title; no buildCount gate in confirm.
- Duplicate → edit with no toast.
- Edit Panel tone=accent fights One Amber (whole form readiness-colored).
- String-only loading; no skeleton plates.

## Questions to Consider

1. If Synergy is Build's intent backbone, should default view be coverage gaps vs inert alphabetical library?
2. Should merge be a deliberate hygiene mode so Check/Merge never tax casual browse?
3. What if create started evidence-first (catalog object / uncovered build designation) instead of type chips → clerk search?
