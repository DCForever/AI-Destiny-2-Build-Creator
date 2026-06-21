# Data Model: Build Sets and Synergies

## Overview
Extends the existing build/loadout/user model in SQLite. New entities for Sets (with items), Synergies, and Build attachments (supporting live references or snapshots per clarification).

All entities are user-owned (via user_id). Item references use manifest identifiers (e.g. hash or name key from Bungie manifest stores) for loose coupling.

## Entities

### Set
User-curated collection.
- id: string (primary key, uuid or cuid)
- userId: string (FK to users)
- name: string (unique within user + category + type per clarif)
- category: string (e.g. "Melee:Ferropotent", "Solar Weapons PVE", "Grenade")
- type: 'weapon' | 'armor' | 'mod' | 'pair' | 'fashion'
- createdAt: datetime
- updatedAt: datetime

**Validation**:
- name + category + type unique per user (enforced in app + DB unique constraint where possible)
- Fashion type treated as cosmetic only (FR-018)

**Relationships**:
- has many SetItem
- can be attached to many Builds via BuildSetAttachment

### SetItem
Junction for items in a set (supports 50+ items per edge case).
- setId: string (FK)
- itemId: string (manifest reference, e.g. item hash or canonical name)
- order: number (optional, for display order)
- addedAt: datetime

**Weapon-specific data** (for weapon type SetItems; required for full roll storage per user clarification):
- selectedPerks: json (array of selected perk hashes, e.g. barrel, magazine, trait1, trait2, etc.)
- masterworkHash?: string (optional)
- otherData?: json (e.g. catalyst, ornament, etc. for the specific weapon roll)

**Validation**:
- itemId must exist in current manifest (checked on add/update for live).
- For weapons: selectedPerks must be valid for the item's sockets (validated on save).
- The full roll data (perks etc.) is stored directly in the SetItem so that if the entry is later removed ("deleted") from the set, the previous configuration (exact perks, barrels, etc.) can still be shown and used to offer alternatives (similar weapons/rolls matching the perks).

**Relationships**:
- For snapshots: the roll data is captured at attach time.

### Synergy
User-defined interaction.
- id: string
- userId: string
- name: string
- type: 'melee' | 'verb' | 'grenade' | 'primary-weapon' | 'special-weapon' | 'heavy-weapon' | 'kinetic-weapon' | 'super' | 'damage' | 'healing' (per spec)
- description: string (text, rationale)
- createdAt, updatedAt

**Relationships**:
- many-to-many with Items or Sets via association (for simplicity, use JSON elements or junction table for itemIds/setIds referenced in synergy)

**Validation**: name reasonable length; type from enum.

### BuildSetAttachment
Links Build to Set (supports clarif on live/snapshot per Build).
- id: string
- buildId: string (FK to existing builds/loadouts)
- setId: string (FK)
- mode: 'live' | 'snapshot'
- snapshotItemIds: json | null (array of itemIds if mode=snapshot; frozen at attach time)  [deprecated in favor of snapshotConfigs for weapons]
- snapshotConfigs: json | null (array of {itemId, selectedPerks, masterworkHash?, ...} for full weapon rolls if mode=snapshot; frozen at attach time. For non-weapons, falls back to itemId only.)
- attachedAt: datetime

**Validation**:
- If mode=snapshot, either snapshotItemIds or snapshotConfigs required (use snapshotConfigs for weapons to preserve perks/barrels/etc.).
- Deletion of Set: blocked if any attachment exists (per clarif and FR-017); show list of builds.

**Relationships**:
- belongs to Build
- belongs to Set

### Existing Entities (extended)
- **Build** (or Loadout): now has 0..* BuildSetAttachment. Supports variants by using different attachments (P6).
- **Item** (from manifest): referenced by id in SetItem, attachments, synergies.

## State Transitions / Lifecycle
- Set: create (with items) -> edit (add/remove items, rename, recategorize) -> delete (only if no attachments)
- Attachment: attach (choose mode) -> edit build (change mode or set) -> detach
- For live attachments: on build view/render, always fetch current Set items (reflects edits).
- For snapshot: use stored list (stable even if Set changes or deleted later - but deletion prevented).
- Synergy: CRUD independent; surfaced as tags/notes on items/sets/builds.
- Fashion Set: can be created/attached but ignored in functional resolution/suggestions/synergies.

## Indexes / Queries (for performance per SC-007)
- Sets by user + category/type (for uniqueness + filter)
- Attachments by buildId (for build sheet)
- Set items by setId (for large sets)
- Suggestions use existing fuse.js + in-memory indexes from manifest/rules.

This model directly supports all 6 user stories, clarifications, FRs, SCs, and edge cases from the spec. References to manifest items allow updates without breaking sets (live mode re-resolves). 

See quickstart.md for validation scenarios. Contracts define the shapes for UI/DB.