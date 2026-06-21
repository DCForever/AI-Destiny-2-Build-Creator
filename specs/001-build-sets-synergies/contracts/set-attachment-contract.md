# Contract: Set Attachment (UI / Data)

**Type**: Internal data + UI component contract for attaching Sets to Builds (P3).

## Data Shapes (zod validated, shared with DB)

```ts
// Attachment payload (for create/update)
type SetAttachmentInput = {
  setId: string;
  mode: 'live' | 'snapshot';  // per clarif
};

// Stored
type BuildSetAttachment = {
  id: string;
  buildId: string;
  setId: string;
  mode: 'live' | 'snapshot';
  snapshotItemIds?: string[] | null;  // legacy/simple
  snapshotConfigs?: Array<{
    itemId: string;
    selectedPerks?: string[];  // for weapons: barrel, mag, traits etc.
    masterworkHash?: string;
    // ...
  }> | null;  // full weapon roll data if snapshot
  attachedAt: string;
};

// SetItem (for weapons, stores the desired roll)
type SetItem = {
  setId: string;
  itemId: string;  // base weapon
  selectedPerks?: string[];  // perks/barrels/etc. for this weapon entry
  masterworkHash?: string;
  order?: number;
  // If the SetItem is removed ("deleted"), the perks/roll data is preserved
  // so the set can show "what was in that weapon" and offer alternatives.
};

// Set reference (live resolve uses this)
type SetRef = {
  id: string;
  name: string;
  category: string;
  type: 'weapon'|'armor'|...|'fashion';
  itemIds: string[];  // current for live; snapshot uses attachment's configs
  // For weapons, each can carry roll data when needed
};
```

**Validation** (from clarifs/FRs):
- mode choice required on attach.
- For snapshot, snapshotItemIds captured at attach.
- Delete Set blocked if any BuildSetAttachment exists (return list of buildIds for UI).

## UI Contract (Component: SetAttachPicker)

Props:
- availableSets: SetRef[]
- currentAttachments: BuildSetAttachment[]
- onAttach: (input: SetAttachmentInput) => void
- onDetach: (attachmentId: string) => void
- onModeChange?: (attachmentId, newMode) => void  // for edit

Behavior:
- Search + filter sets (by category, type, name). Exclude fashion from functional suggestions (per clarif A).
- Toggle/Radio: "Live (updates when Set changes)" | "Snapshot (freeze now)" . Default: live.
- Auto suggestions: when exotic/subclass changes, show recommended chips (click to attach with default mode).
- Explicit: "Suggest for goal" button opens input or uses current build context → proposals (per clarif C for suggestions).
- Display in build sheet: list with mode badge + items (live vs snapshot label). 

Events / Errors:
- Duplicate name error surfaced in set create (separate).
- Attach blocked? No (only delete blocked).
- Suggestion empty state: "No strong matches; try explicit goal".

See data-model.md for full entities. Quickstart.md for runnable flows. Implementation must pass the acceptance scenarios in spec.md US3.

This contract is internal; no public API version yet.