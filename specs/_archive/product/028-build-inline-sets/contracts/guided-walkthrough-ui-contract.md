# Contract: Guided Finish Walkthrough UI

**Type**: Production Builds UI  
**Stories**: US2–US4 (hosts US1/US3 actions)  
**Rules**: FR-005–010, FR-012–023

## Entry

- **Primary**: "Finish build" (or equivalent) when `evaluateFinishGaps` → not complete on **default** variant.
- **Secondary**: Same entry available from variant Sets tab; discrete controls remain (FR-019).

## Shell

```text
FinishBuildWalkthrough
  header: progress Armor | Weapons | Mods (satisfied / current / skipped / todo)
  body:
    overview | categoryStep | fillStep | done
  footer: Skip for now | Back | Exit | Continue
```

## Category step actions (priority order when shown)

1. **Capture current gear into a Set** — if `canCapture` (preferred, FR-023) → `POST .../create-sets` with `categories: [cat]`, `attachNow: true`
2. **Create empty Set** → createSetAndAttach
3. **Link existing Set** → SetAttachPicker filtered by type → replace-by-type attach

## Fill step

- List `emptySlots` for covering set
- Each slot → open SlotFillPanel (or equivalent) for that set+slot
- On fill success → re-evaluate gaps; advance when category satisfied
- **Skip for now** on slot key `category:slot`

## Skip for now

- Category skip key: `armor` | `weapon` | `mod`
- Does not write server state
- Remaining gaps list still shows skipped items
- Incomplete banner remains until satisfied

## Snapshot guard

- If only snapshot covering set exists and user needs library mutation: prompt to switch to live / create live set; do not silently edit library through snapshot semantics incorrectly (FR-012)

## Refresh

- After any successful mutation: reload build/variant detail (or patch local state from response) so attachments and resolved loadout update without full manual reload (FR-009)

## Success

- When all categories satisfied (or only skipped remain — still incomplete): if complete → done success state; if only skips → summary of remaining work + Exit
