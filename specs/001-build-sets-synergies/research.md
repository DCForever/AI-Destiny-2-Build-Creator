# Research: Build Sets and Synergies

## Snapshot vs Live Set Attachment Implementation

**Decision**: 
- Snapshot mode: when attaching, copy the current list of item references (item hashes/ids) into the attachment record (as JSON array). The Build always uses that frozen list.
- Live mode: store only the set reference (set_id). At render time, resolve the current items from the Set.

**Rationale**: Matches the clarification ("A live by default, but per Build choose snapshot"). Simple DB, supports manifest updates for live sets, guarantees stable variants for snapshot. Leverages existing manifest resolution code. Keeps performance good (lazy resolve for live).

**Alternatives considered**:
- Always snapshot: loses the "live" feature requested.
- Versioned sets: more complex (need set versions table, migration pain).
- Full item denormalization: wastes space and loses reference benefits for live.

## Suggestion Engine (Sets, Synergies, Rolls)

**Decision**:
- Automatic contextual: rule + meta based (reuse existing data/rules , armor archetypes, stat benefits, meta pack) + simple matching on category/tags/exotic/subclass. Triggered on select in build editor.
- Explicit: "Suggest" button or goal description input uses the existing LLM research pipeline (with tool calls for manifest) to generate smart recommendations, falling back to rules.
- Rolls suggestions: extend existing roll tag/meta logic, with context from attached set/synergy.

**Rationale**: Per clarifications (C for combination) and spec assumptions ("combination of user-defined data, deterministic rules, and the existing LLM research pipeline"). Keeps "intelligent" without over-relying on LLM for everything. Reuses existing code for speed and consistency.

**Alternatives considered**:
- Pure LLM for all: non-deterministic, slower, higher cost/token use, harder to test.
- Pure rules: too limited for "intelligently generated" from original goals.
- Separate service: unnecessary complexity for this local app.

## UI/Interaction for Set Attachment and Suggestions

**Decision**:
- In build editor/sheet: new Set attachment UI with picker (search + filters from manifest), toggle for live vs snapshot (default live).
- Suggestions: auto surface as chips/panel when context changes (exotic, subclass). Explicit "Suggest for this goal" uses LLM.
- Set management: new or sidebar UI for CRUD sets, with category tags, add from current inventory or full manifest browser.
- Synergies: similar CRUD + tags on items/sets/builds.

**Rationale**: Supports clarifications and user stories (P3 has both auto and explicit, P5). Integrates with existing BuildForm and sheet components. Keeps UI simple and consistent with current generator/analyzer.

**Alternatives considered**:
- Separate dedicated /sets page only: less integrated, worse UX for attach during build.
- Always modal heavy: more clicks.

## Persistence and Schema

**Decision**:
- New tables: sets, set_items (junction), synergies, build_set_attachments (with mode and optional snapshot_item_ids json).
- Use existing item references (hashes from manifest) in junctions.
- Sets and synergies private per user (user_id FK).
- For snapshot: store the list at attach time in attachment.

**Rationale**: Supports all clarifications (deletion guard via FK or query, uniqueness in app + DB where possible, live/snapshot, fashion exclusion by type). Extends existing DB schema pattern. Easy queries for "attached sets".

**Alternatives considered**:
- JSON blob for whole set in build: loses sharing/reuse of sets across builds.
- Separate snapshot table: overkill.

## Weapon Roll Data in SetItem (Perks, Barrels, etc.)

**Decision**:
- SetItem for weapons stores full desired roll: selectedPerks (array of hashes for barrel/mag/traits/etc.), masterwork, otherData.
- Snapshot in BuildSetAttachment uses snapshotConfigs: [{itemId, selectedPerks, ...}] instead of (or in addition to) simple itemIds.
- If a SetItem is removed from a set ("deleted"), the roll data remains in history or can be recovered in UI for that slot; use the stored perks to offer alternative weapons/rolls that match (via rules or LLM similarity on perk benefits).

**Rationale**: Directly from user clarification. Allows remembering exact "what was in that weapon" (perks/barrels) even after removal from set or if the base weapon is deprecated in manifest. Enables "alternatives could be offered" in sets (e.g., "this exact roll is unavailable, here are similar weapons with matching traits").

**Alternatives considered**:
- Only store base itemId: loses the specific perks the user curated for the set.
- Separate "Roll" entity: over-normalization for this use case; embedding in SetItem is simpler and sufficient.

## Other (Manifest Updates, Scale, Private)

**Decision**:
- Manifest updates: for live sets, re-resolve items on load (graceful if items deprecated - skip or warn).
- Scale: 50+ item sets ok with current fuse + virtual lists if needed; 30+ sets supported per SC-007.
- Private: per user_id; no sharing in v1 per assumptions and clarif.
- "Intelligently generated synergies": covered by explicit LLM suggestions in the combination mode.

**Rationale**: Directly from spec clarifications, assumptions, edge cases, SC. Reuses existing manifest handling code.

These decisions were used to drive data-model, contracts, and will drive tasks.md. All respect constitution (small increments via the 6 stories, validation-first, co-located tests).