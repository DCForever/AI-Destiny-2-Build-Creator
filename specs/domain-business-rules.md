# Domain Business Rules — Destiny 2 Builds

**Created**: 2026-07-10  
**Updated**: 2026-08-07 (DBR-IDL-001–009 Catalog roll targets; exotics disallowed)  
**Status**: Canonical domain layer  
**Source**: Clarification session 2026-07-09 → 2026-07-10; product reconciliation 2026-07-14; presentation North Star 2026-07-27; Set minimum occupancy 2026-07-29; **Obsidian product packs re-sync 2026-07-29** (Domains + Destiny Objects in ProjectTracker vault)

High-level rules for how Destiny 2 builds work in this system and how the product should use them. Feature-level BRs remain in [`business-rules.md`](./business-rules.md); where they conflict, **this document wins** (see Supersessions).

**Companion**: [`domain-acceptance-criteria.md`](./domain-acceptance-criteria.md)

**Product working copy**: Obsidian ProjectTracker → `Projects/Destiny 2 Build Creator/` (Domains, Destiny Objects). Repo specs are the enforceable SSoT after re-sync; vault remains authoring workspace.

---

## How to read

| Column | Meaning |
|--------|---------|
| **ID** | Stable domain rule id (`DBR-*`) |
| **Rule** | Plain-language behavior the system must enforce |

---

## 1. Product purpose

| ID | Rule |
|----|------|
| DBR-PUR-001 | The system’s primary job is **Build composition**: assemble and maintain Destiny 2 builds from sets, synergies, and variants. |
| DBR-PUR-002 | Inventory organization, theorycraft discovery, and hunt planning are supporting capabilities, not the primary job. |
| DBR-PUR-003 | Primary success journey: **intent → compose → equip**. Secondary: **curate a reusable library** of sets and synergies. |
| DBR-PUR-004 | Users may create synergies and sets **in-flow** during compose; a deep library is not a hard gate to start composing. |
| DBR-PUR-005 | Library readiness bar for the primary journey: at least **≥10 synergies** and **≥10 sets** spanning weapon/armor/mod (ideally including pair or fashion). |

---

## 2. What a Build is

| ID | Rule |
|----|------|
| DBR-BLD-001 | A **Build** is both a **fully equippable loadout** and a **stable identity** with **variants**. |
| DBR-BLD-002 | Variants may swap weapons and/or armor (and other variant fields) while preserving identity — e.g. several kits that all create Ionic Traces and Jolt. |
| DBR-BLD-003 | Exactly one **default variant** per build. |
| DBR-BLD-004 | Builds are **class-bound** (Titan / Hunter / Warlock). Character is chosen at equip time. |
| DBR-BLD-005 | Builds are **private** per user. Shareable read-only links are planned, not required for the first equippable composer slice. |
| DBR-BLD-006 | Builds and variants may have free-form **notes** (not identity). |
| DBR-BLD-007 | **Class** is set at create and **cannot change** after create. |
| DBR-BLD-008 | Changing **subclass element/tree** after create requires **confirm in-place** or **fork** (same umbrella as identity-field changes). |
| DBR-BLD-009 | After a tree change is applied, each variant’s subclass **kit is wiped** to an **empty legal baseline** for the new tree (aspects, fragments, abilities cleared). User must re-fill; default must meet full loadout again before default save. |
| DBR-BLD-010 | Build library / identity chrome shows subclass as a **full mini kit strip**: element + aspects + fragments + all five ability icons (icon-first), not element-only. |

---

## 3. Build identity

Identity is what makes two loadouts the “same build” vs a different build.

| ID | Rule |
|----|------|
| DBR-ID-001 | **Primary identity** is **designated synergies** (curated play-patterns / verbs/goals). |
| DBR-ID-002 | **Concept tags are not identity**. Tags are optional filter metadata (e.g. PVE, Dungeon) when no synergy covers that context. Changing tags does not fork identity. |
| DBR-ID-003 | **Exotic armor (non–class-item)**, when set, is identity by **item** (manifest hash), not by inventory instance. Variants may use different owned instances of that item. |
| DBR-ID-004 | Exotic armor is **optional**. When unset, identity does not include an exotic armor item. |
| DBR-ID-005 | **Exotic class items** fill the exotic-armor slot but are **intent/synergy-locked**, not item-hash-locked. Variants may use different class items/perks that still fit designated synergies (soft-checked). |
| DBR-ID-006 | **Exotic weapon** may be **variant-level** or **build-shared**. When build-shared, it is identity. |
| DBR-ID-006a | Exotic weapon is **variant-level by default**. User may **promote** to build-shared (identity). |
| DBR-ID-006b | Demote build-shared exotic weapon to variant-level is an identity change → confirm or fork. |
| DBR-ID-007 | **Super** is normally **variant-level**. It may be **build-pinned**; when pinned, it is identity. |
| DBR-ID-007a | Pin or unpin Super is an identity change → confirm or fork. |
| DBR-ID-008 | **Any** identity-field change requires **confirm in-place** (affects all variants) or **fork** to a new Build. No silent edit. |
| DBR-ID-008a | Identity-field changes include: add/remove/change designated Synergy Types; set/clear classic exotic armor item; promote/demote build-shared exotic weapon; pin/unpin Super; change subclass tree (DBR-BLD-008). |
| DBR-ID-008b | Not identity (no confirm/fork): concept tags, notes, soft stat targets, derived/manual name, variant composition (gear, kit picks, fashion, artifact). |
| DBR-ID-009 | Identity fields include: designated Synergy Types; exotic armor item when set; build-shared exotic weapon when set; build-pinned Super when set. |
| DBR-ID-010 | Gear, mods, aspects/fragments, non-pinned abilities, fashion, and artifact configs are **variant** concerns (not identity), except where exotic ability-requirements auto-pin abilities (DBR-SUB-005). |
| DBR-ID-011 | Synergy link kind `exotic_armor`: **classic** exotics target **item hash**; **exotic class items** target **perk configuration only** (not the item shell). |

---

## 4. Naming

| ID | Rule |
|----|------|
| DBR-NAME-001 | Default Build name is derived from: **Class, Element, Super, Exotic Armor, Exotic Weapon, Synergies**. |
| DBR-NAME-002 | Missing optional segments are **omitted** (no “None” placeholders). |
| DBR-NAME-003 | Default name uses the **default variant’s Super** when Super is not build-pinned. |
| DBR-NAME-004 | User may rename. Renamed names must be **unique per class** for that user. |
| DBR-NAME-005 | Variants have a **user label** plus an optional derived hint (e.g. exotic weapon, artifact). |

---

## 5. Subclass kit

| ID | Rule |
|----|------|
| DBR-SUB-001 | **Subclass element/tree** is shared across all variants (Solar, Arc, Void, Stasis, Strand, Prismatic). Tree is Build-owned; shown read-only in Variant Subclass area. |
| DBR-SUB-002 | **Prismatic** uses the same rules as other trees — no special identity model; own aspect/fragment/ability pools (no all-element widen). |
| DBR-SUB-003 | **Aspects, fragments, and ability choices** may differ per variant, except build-pinned Super / exotic-required pinned abilities. Edited only in the Variant **Subclass** area. |
| DBR-SUB-004 | Illegal subclass kits (invalid combinations or over aspect/fragment slot limits) **cannot be saved**. |
| DBR-SUB-005 | When an exotic requires a specific Super / melee / grenade / class ability, the system **auto-proposes** ability pins; user confirms; **mismatch blocks save**. |
| DBR-SUB-006 | **Default complete kit** requires: aspect slots filled (typically **2** when known), fragments filled **to capacity** granted by selected aspects, plus **Super**, **melee**, and **grenade** selected. |
| DBR-SUB-007 | **Class ability** and **movement** are always shown and editable in Subclass area; they are **not** required for default composition complete unless an exotic ability requirement forces them. |
| DBR-SUB-008 | Fragment capacity is the **sum** of capacity granted by selected aspects (when known). Zero aspects ⇒ zero fragment capacity. |
| DBR-SUB-009 | When aspect change reduces fragment capacity, **trim excess** fragments so the kit stays legal (do not leave a silently illegal kit). |
| DBR-SUB-010 | Abilities and aspects/fragments must match Build **class + tree**; illegal options are not selectable when known. |

---

## 6. Synergies

| ID | Rule |
|----|------|
| DBR-SYN-001 | A Synergy is **Type linked with an Object**: a curated play-pattern (`type` + optional `subType`) with linked gear evidence (Objects: weapon, perk, origin trait, armor set bonus, exotic armor, artifact perk, aspect, fragment, armor mod, melee/grenade/super abilities, etc.). |
| DBR-SYN-002 | Builds are created **intent-first**: user designates **Synergy Types** (`type` + optional `subType` only). The system **bridges** those Types to matching curated Synergies (Type + Object) for coverage and suggestions. A library Synergy need not exist for a Type designation to be valid. |
| DBR-SYN-003 | Every Build must designate **≥1 Synergy Type** to save (`NO_SYNERGY` otherwise). |
| DBR-SYN-004 | Multiple designated Synergy Types on a Build contribute **equally** to suggestions and coverage. Soft UI nudge toward roughly **2–5**; no hard maximum. |
| DBR-SYN-004a | At most **one** library Synergy exists per designation (`type` + `subType`) per user. Bridge does **not** union multiple library rows for the same Type. |
| DBR-SYN-005 | **v1:** Personal custom type keys are **not** allowed. Vocabulary is the product type enum + curated subType lists only. |
| DBR-SYN-005a | A later product version may add personal types; that needs an explicit decision. |
| DBR-SYN-006 | **v1:** No promote-to-global personal vocabulary. Curated lists live in product + code (verbs, elements, enemies, frames, ammo, weapon_slot, …). |
| DBR-SYN-007 | Synergy links are **evidence by default**. Authors may mark specific links **required**. |
| DBR-SYN-008 | Required flag may apply to **any** link kind in the v1 linkable kinds set (see DBR-SYN-015). |
| DBR-SYN-009 | Multiple required links on one synergy are **AND** — all must be satisfied. |
| DBR-SYN-010 | Required-link hard checks apply to the **default variant only**; other variants get soft warnings. |
| DBR-SYN-010a | A required link is **satisfied** only when an **equip-ready pin** (or applied kit piece for non-gear kinds) on the resolved default loadout matches the target. **Wishlist-only** identity does **not** satisfy required links. |
| DBR-SYN-011 | Non-default variants receive **soft guidance** for synergy coverage (suggestions/warnings); weak coverage does not block save. |
| DBR-SYN-012 | A library Synergy’s **designation** (`type` + `subType`) is **immutable after create**. Create may set type/subtype; edit may change description and linked Objects only. Attempts to change type or subtype after create are rejected. |
| DBR-SYN-013 | When a build designates a **verb** with a known element alignment (e.g. Ionic Trace → Arc, Jolt → Arc), the system may **imply** the matching **element** designation for bridging, matching, and coverage — without requiring the user to also designate Element explicitly. Explicit element designations still take precedence when present. |
| DBR-SYN-014 | **Weapon perk** evidence includes **exotic weapon trait plugs** (and other exotic WEAPON PERKS sockets), not only legendary perk rolls — e.g. Lodestar **Arc Alignment** is a valid `weapon_perk` target for a Verb: Jolt library synergy. |
| DBR-SYN-014a | For `weapon_perk` coverage and required-link satisfaction, **base and enhanced** (family variants) of the same trait **count as a match** when family is known. Saved rolls still store the specific plug hash. |
| DBR-SYN-014b | `armor_set_bonus` links store **bonus family + target tier** (2 or 4). Required satisfaction: contributing member count on resolved loadout **≥ target tier** (higher count OK). Tier must exist on that family in data. Independent of Armor Set package constraint (DBR-SETB-003+). |
| DBR-SYN-015 | **v1 linkable kinds**: `weapon`, `weapon_perk`, `origin_trait`, `armor_set_bonus`, `exotic_armor`, `aspect`, `fragment`, `armor_mod`, `melee`, `grenade`, `super`, `artifact_perk`. No class_ability / movement / fashion / generic inventory_item kinds in v1. |
| DBR-SYN-016 | Ability link kinds (`melee`, `grenade`, `super`) resolve to ability definitions, not to Synergy **designation** type rows of the same names. |
| DBR-SYN-017 | Designation types **ammo** (Primary/Special/Heavy) and **weapon_slot** (Kinetic/Energy/Power) are distinct; do not conflate ammo economy with inventory bucket. |

### LLM-assisted discovery

| ID | Rule |
|----|------|
| DBR-LLM-001 | A **manual** LLM pass may analyze descriptions of equippable/changeable build pieces to **propose** synergies and gear evidence. |
| DBR-LLM-002 | LLM output is **propose-for-confirmation** — user confirms/edits before records become real. |
| DBR-LLM-003 | Pass scope: weapons, perks/traits, armor/exotics, abilities/aspects/fragments, mods, artifact perks. |
| DBR-LLM-004 | LLM may propose **new keywords**; user confirms into personal or global vocabulary. |
| DBR-LLM-005 | Re-runs are **manual**. Destiny is not expected to receive significant further updates; this is occasional curation. |

---

## 7. Composition (sets, slots, attachments)

| ID | Rule |
|----|------|
| DBR-CMP-001 | **Sets are the normal composition path** (Weapon, Armor, Mod, Pair, Fashion). |
| DBR-CMP-002 | Users may also **pin/override individual slots** on a variant. |
| DBR-CMP-003 | Set attachments default to **live**; user may snapshot for a frozen equipable variant. |
| DBR-CMP-004 | **Pair Sets** are optional convenience packages for exotic combos; exotics may also be set directly or via other sets. |
| DBR-CMP-005 | **Mods** come from **Mod Sets attached per variant**. |
| DBR-CMP-006 | Cross-set slot conflicts still block save until resolved. |
| DBR-CMP-007 | At most **one exotic weapon** and **one exotic armor** (including exotic class item) — **hard on save**. |
| DBR-CMP-008 | A **Weapon Set** or **Armor Set** is valid only with **≥2 items** filled across its domain slots. Individual slots may be empty while filling; **save** of the set is blocked below this minimum. |
| DBR-CMP-009 | A **Mod Set** is valid only when it has mods on **more than one armor piece** (helmet, arms, chest, legs, and/or class item — at least **two** distinct pieces with ≥1 mod each). Empty pieces are allowed; **save** is blocked if mods occupy only zero or one piece. |
| DBR-CMP-010 | **Pair** and **Fashion** sets keep their own slot rules; DBR-CMP-008–009 do not redefine Pair (exotic convenience) or Fashion occupancy. |

---

## 8. Rolls, instances, wishlist

| ID | Rule |
|----|------|
| DBR-ROLL-001 | Planning may reference **catalog** items and **desired rolls** not yet owned. |
| DBR-ROLL-002 | A wishlist/unowned slot stores **desired roll data**: item hash + perk/plug selections (including origin trait, masterwork, crafted/enhanced plugs as applicable) — not an instance id. |
| DBR-ROLL-003 | **Crafted/enhanced** details live in roll/instance data, not as a separate identity dimension. |
| DBR-ROLL-004 | **Equip** requires a **pinned owned instance** for **every equipment slot being applied**. |
| DBR-ROLL-005 | Variants may be **saved** without instance pins (wishlist OK). Equip/export is blocked until pins exist for applied slots. |
| DBR-ROLL-006 | If a pinned instance disappears after sync: keep item + desired roll, mark **stale pin**, block equip until re-pinned. |
| DBR-ROLL-007 | **Exotic catalysts**: first-class on weapon detail when the exotic has a catalyst in data. Display status — equipped/inserted; complete-but-unequipped (warn); unfinished (warn); unacquired (warn). Own socket/column on the instance perk grid when present. Soft only — **do not** gate Set save, variant save, or equip. Do not invent progress/sources. See vault [[Destiny Weapon]] DO-WPN-040–051. |
| DBR-ROLL-008 | **Deepsight / pattern progress**: display-only with warns; no save/equip gate. |
| DBR-ROLL-009 | Exotic class item variants store **full selected perk config** (instance or wishlist desired config). |
| DBR-ROLL-010 | Catalog **browse** for composition supports multi-dimension filtering (e.g. element, ammo, archetype/frame, slot, class, exotic constraint, free-text, optional synergy membership) with **include OR within a facet**, **AND across facets**, and **exclude** drops; optional **group-by** one or more dimensions for browse. Catalog is a composition aid, not a separate product job (see DBR-PUR-002). |

### 8.1 Catalog roll targets (ideal + anti-ideal) — not equip wishlist

User-authored **roll targets** on Catalog weapon identities. **Not** DBR-ROLL wishlist pins (desired roll on Set/Variant without instance). Soft scores only.

| ID | Rule |
|----|------|
| DBR-IDL-001 | A user may define **named roll targets** per weapon identity (e.g. PvE / PvP). Multiple names per weapon are allowed. |
| DBR-IDL-002 | Each target column may list **preferred** plug hashes (multi-accept: any listed plug matches that column for ideal score). |
| DBR-IDL-003 | Each target column may list **avoid** plug hashes (multi-reject: any listed plug **hits** anti-ideal for that column). |
| DBR-IDL-004 | Preferred and avoid sets on the **same column must be disjoint**; overlapping writes are rejected. |
| DBR-IDL-005 | **Preferred score** = matched preferred columns / scored preferred columns (empty preferred columns are unscored). |
| DBR-IDL-006 | **Avoid score** = avoid hits among avoid-scored columns (empty avoid columns are unscored). Higher hits = worse. |
| DBR-IDL-007 | Owned-instance **rank** for an active target: preferred ratio **desc**, then avoid hits **asc**, then power/tier as product tie-break. Soft display only. |
| DBR-IDL-008 | Roll-target scores **never** hard-block Set/variant save, equip, or DIM export. Soft never auto-applies. Do not invent can-roll plugs. |
| DBR-IDL-009 | **Exotic weapons** do **not** support roll targets (ideal/avoid). Exotic perk columns are **fixed** identity; preferred/avoid multi-pick, dual scores, and rank-by-target do not apply. Legendary (and other non-exotic) weapons only. |

---

## 9. Completeness: default vs other variants

| ID | Rule |
|----|------|
| DBR-CMPL-001 | **Default variant** must be a **full combat loadout**: legal subclass kit (DBR-SUB-006–007), all three weapon slots, all five armor slots, Mod Set path for combat mods, and artifact selected with **filled config** (DBR-ART-003a). |
| DBR-CMPL-001a | Artifact **selection alone is not enough** — artifact perk/config must be complete for default. |
| DBR-CMPL-001b | **Fashion is optional** on default (not required for composition complete). |
| DBR-CMPL-001c | Class and subclass **tree** come from the Build (shared). Variant supplies kit choices in Subclass area. |
| DBR-CMPL-001d | Default save has **three gates**: (1) compose complete, (2) required synergy links satisfied via equip-ready pins (DBR-SYN-010a), (3) equip-ready for equip/export. |
| DBR-CMPL-002 | **Non-default variants** may leave some combat slots **empty** and need not pass gates 1–2 for save (soft guidance only for coverage). |
| DBR-CMPL-003 | On equip-with-gaps, **empty combat slots leave the character’s current gear as-is**. |
| DBR-CMPL-004 | Non-default variants may equip with gaps only after **user confirmation**. |
| DBR-CMPL-005 | Every variant has exactly **four areas**: General, Subclass, Armor + Mods Sets, Weapons Set. |

---

## 10. Stats (Edge of Fate)
<!-- Updated 2026-07-23: DBR-STAT-008 Armor Set board base roll excludes equipped mods -->

| ID | Rule |
|----|------|
| DBR-STAT-001 | Soft stat targets use the EoF six: **Class, Grenade, Melee, Super, Health, Weapons**. |
| DBR-STAT-002 | Targets are optional **per-stat thresholds** at **build level** (shared across variants). |
| DBR-STAT-003 | Valid target range supports benefits up to **200** (max for benefits). |
| DBR-STAT-004 | Missing targets do not block save/equip; below-target is a **warning** via soft guidance. |
| DBR-STAT-005 | Coverage uses a **full loadout estimate**: armor (including class item), mods, fragments/aspects, and other known loadout bonuses. |
| DBR-STAT-006 | Designated synergies may **suggest/nudge** related soft stat targets; user accepts or ignores. |
| DBR-STAT-007 | Weapon damage type vs subclass element is **soft / synergy-based** — no blanket hard element lock. |
| DBR-STAT-008 | **Armor Set** piece/board stats are the piece **base roll** (sum of `armor_stats` plug investments). Equipped armor mods, masterwork, and tuning are excluded from that board. Full-loadout soft-target coverage still follows DBR-STAT-005. |

---

## 11. Armor energy / tier / mods

| ID | Rule |
|----|------|
| DBR-MOD-001 | Illegal or over-capacity mod loadouts **cannot be saved**. |
| DBR-MOD-002 | Armor energy capacity: **Tier ≤4 → 10**; **Tier 5 → 11**. |
| DBR-MOD-003 | Armor **tier** is an instance/validation concern (capacity + suggestions), not build identity. |
| DBR-MOD-004 | **Activity-gated mods** may be saved; soft/contextual warnings; activity tags may mark intent. |

---

## 12. Armor set bonuses

| ID | Rule |
|----|------|
| DBR-SETB-001 | Variants show **soft coverage** for active 2pc/4pc and which designated synergies they support. |
| DBR-SETB-002 | If a designated synergy has a **required** set-bonus link, the **default variant** cannot save until that bonus is satisfied (AND with other required links). Satisfaction uses DBR-SYN-014b (count ≥ link target tier) and DBR-SYN-010a (equip-ready path). |
| DBR-SETB-003 | An **Armor Set** may declare **zero or one** optional **armor set bonus constraint**: bonus family + target tier (2 or 4). Only Armor Sets may use this constraint. |
| DBR-SETB-004 | When a constraint is set: every **non-exotic** filled piece must be a **member** of that family; contributing member count must meet the target tier on **save and attach**. |
| DBR-SETB-005 | **Exotic armor does not count** toward the contributing tier. Soft-warn when an exotic likely blocks the target. |
| DBR-SETB-006 | Without a constraint, no family is required on Armor Set save; UI may still show detected 2pc/4pc coverage (soft). |
| DBR-SETB-007 | Armor Set **constraint** and Synergy `armor_set_bonus` **link** share family+tier vocabulary but are **independent** — setting one does not auto-create the other. |

---

## 13. Artifacts

| ID | Rule |
|----|------|
| DBR-ART-001 | There are **6 fixed artifacts**, switchable via API; not expected to grow/change. Do not invent a 7th product artifact type. |
| DBR-ART-002 | Each variant selects **exactly one** of the 6 artifacts (General area). |
| DBR-ART-003 | Each variant stores a **full artifact config** (selected unlocks/mods) and equip **applies** them. |
| DBR-ART-003a | On **default**, artifact config/perks must be **filled** (non-empty valid equip config). Empty config fails compose complete. |
| DBR-ART-004 | Switching artifact is variant-local (not Build identity); prior config is cleared/invalidated; user rebuilds for the new artifact. |

---

## 14. Fashion / cosmetics

| ID | Rule |
|----|------|
| DBR-FASH-001 | Fashion/cosmetics are part of **full equip** and DIM export when specified. |
| DBR-FASH-002 | Fashion attaches **per variant** (Fashion Sets). |
| DBR-FASH-003 | Fashion layer may include shaders/ornaments, **ghost, sparrow, ship, emblem**, and **finisher**. |
| DBR-FASH-004 | Omitted fashion slots **leave character cosmetics as-is** on equip. |
| DBR-FASH-005 | Fashion is **not** identity and does not drive synergies/suggestions/stats. |
| DBR-FASH-006 | **Emotes** and **consumables/temporary buffs** are out of scope. |

---

## 15. Soft guidance UX

| ID | Rule |
|----|------|
| DBR-GUID-001 | Soft guidance uses **passive indicators** and a **coverage breakdown** (supported / weak / missing + hints). |
| DBR-GUID-002 | Suggestions primarily optimize for **synergy coverage**. |
| DBR-GUID-003 | Hard blocks are reserved for true Destiny/system constraints (exotics limits, energy, illegal kits, ownership/pins for equip, required links on default, etc.). Where pickers exist, **hard constraints must not be UI-selectable** (filter/disable illegal options); primary Save/Create/Fill actions stay **disabled** when hard blocks remain. Soft guidance never disables Save on non-default variants. API remains authoritative. |

---

## 16. Equip & export

| ID | Rule |
|----|------|
| DBR-EQP-001 | In-game equip via **direct Bungie API** is a core capability. |
| DBR-EQP-002 | **DIM export** of a full variant loadout is also a core capability. |
| DBR-EQP-003 | Both equip and DIM export require **owned, instance-pinned** slots for everything being applied; wishlist-only variants are blocked. |
| DBR-EQP-004 | DIM export includes: subclass kit, weapons/armor, mods, fashion, artifact config. |
| DBR-EQP-005 | At equip, user **always chooses** the target character among class-matching characters. |
| DBR-EQP-006 | Equip **transfers** required items from vault/other characters, then equips. |
| DBR-EQP-007 | Inventory is **refreshed on equip**, subject to Bungie rate limits (~**once per minute**); reuse a fresh-enough sync within that window. |
| DBR-EQP-008 | Equip is **best-effort partial**: apply what succeeded, report failures, leave character as-is; **retry** until it works. No hard rollback requirement. |

---

## 17. Destiny data presentation (DIM North Star)

How the product **shows** Destiny entities and loadouts — not which product workflows we own.

| ID | Rule |
|----|------|
| DBR-UI-001 | **Destiny Item Manager (DIM)** is the **North Star** for presenting Destiny data in general: item/armor/weapon detail, perk grids, stat bars, mod placement chrome, loadout readouts, and similar inventory-like surfaces. Prefer DIM-familiar density, labeling, and affordances unless a product rule explicitly diverges. |
| DBR-UI-002 | The main intentional divergence from DIM is **build creation / composition workflow** (intent-first synergy types, sets library, variants, soft guidance, finish/optimizer composer paths). Those journeys are product-owned; do not force DIM’s create-loadout / LO flows as the compose path. |
| DBR-UI-003 | **DIM product parity is not required.** Notes, tags, ornaments, full vault transfer UI, and other DIM product features remain optional/non-goals unless separately specified. North Star means **presentation of Destiny data**, not cloning DIM as a product. |
| DBR-UI-004 | Visual reference captures for DIM-aligned surfaces live under [`docs/dim-reference-screenshots/`](../docs/dim-reference-screenshots/). Use them when designing or reviewing Catalog, Sets item detail, loadout/readout chrome, perk/mod UI, and similar. |
| DBR-UI-005 | **Icon-first presentation.** Destiny entities should surface primarily via **icons and assets** (item/perk/mod icons, element/ammo/class/weapon-type glyphs, rarity frames, loadout icon strips)—not long text labels. Text is secondary: tooltips/hotspots, accessible names, search results, and fallback when art is missing. Prefer dense icon grids/strips over text-heavy tables for inventory-like readouts. |
| DBR-UI-006 | **No bare hashes in primary UI.** Item/plug hashes are never row labels, perk titles, or main detail headlines. Readable name + icon first. Hashes only as a **footer addendum** on detail (support/debug). Search may match hash; result row still shows name. |
| DBR-UI-007 | Weapon **detail** shows selected plugs, **can-roll** pool, and **possible crafted options** when craftable (when data exists)—**including craftable exotics**. Craftable is not legendary-only. Exotic catalyst (DBR-ROLL-007) remains independent when both craft and catalyst exist. Do not invent pool/craft options. Set **slot rows** stay icon-only (no full perk grid). |
| DBR-UI-008 | Armor Set **board** uses **base roll** stats only (DBR-STAT-008). Catalog/instance live stats must be labeled when shown. Acquire/farm sources on detail **when Destiny data provides them** — never invent. |

---

## 18. Clarifications log

### Session 2026-07-09 / 2026-07-10

Summarized decisions from the domain Q&A (Q1–Q101). Corrections applied in-place: Q14→B (curated synergies); Q16→B (exotic armor optional); Q47→A (save without pins OK).

### Product reconciliation 2026-07-14

Landed product rules from `feature/overhall` commits + in-progress work: library designation immutability (type+subtype); verb→element implied bridging; catalog multi-facet browse; exotic trait plugs as `weapon_perk` evidence.

### Presentation North Star 2026-07-27

DIM is the North Star for **showing** Destiny data (item detail, perks, stats, mods, loadout chrome). Prefer **icons and assets over text** (DIM-style). Main deviations are around **build creation workflow**. Full DIM product parity remains a non-goal. Reference screenshots: `docs/dim-reference-screenshots/`.

### Set minimum occupancy 2026-07-29

Weapon/Armor sets require **≥2 items** on save. Mod sets require mods on **≥2 armor pieces** on save. Aligns product descriptions (Obsidian Domain Set) with library quality: a “set” is not a single slot.

### Obsidian product packs re-sync 2026-07-29

Full Domain + Destiny Object product definitions authored in ProjectTracker vault. Specs re-sync lands:

- Subclass complete kit bar (aspects + fragments at capacity + Super/melee/grenade; class/movement optional)
- Tree change wipe; mini kit strip; four variant areas; three default gates
- No personal Synergy types in v1; expanded link kinds; ammo vs weapon_slot; perk family match; armor_set_bonus link tier; exotic_armor class-item = perk config
- Armor Set bonus package constraint; artifact filled config; UI no bare hashes / can-roll / base board
- Required links satisfied by equip-ready pins only

Working copy remains the vault; this file is enforceable domain SSoT after re-sync.

---

## Supersessions vs `business-rules.md`

| Legacy rule | Domain replacement |
|-------------|-------------------|
| BR-BLD-002 (tags + aspects shared as identity) | DBR-ID-*; DBR-SUB-*; tags not identity |
| BR-BLD-003 / BR-BLD-004 (exotic armor always build-level; exotic weapon always variant) | DBR-ID-003–006b (optional armor; weapon build-or-variant; class-item intent lock) |
| BR-SAVE-001 / BR-SAVE-002 / BR-SAVE-004 (≥1 slot) | DBR-CMPL-001–002 (default full; others may gap) |
| BR-FASH-002 (fashion never in composition/equip) | DBR-FASH-001–005 (fashion in equip; still not synergies/stats) |
| BR-VAR-002 (variants typically snapshots) | DBR-CMP-003 (live default; snapshot optional) |
| BR-SLOT-004 / BR-SLOT-007 (mods optional for valid Mod Set save) | DBR-CMP-009 (Mod Set save requires mods on ≥2 armor pieces; empty pieces still OK; UI may still encourage filling) |
| BR-SLOT-005 alone (any empty OK with no set-level floor) | DBR-CMP-008–009 (per-slot empty still OK; set save needs Weapon/Armor ≥2 items, Mod multi-piece) |
| BR-SUG-001 emphasis | DBR-GUID-002 (synergy coverage primary) |
| BR-SYN-001 unrestricted “CRUD” of type after create | DBR-SYN-012 (designation immutable after create; links/description remain editable) |
| DBR-SYN-005/006 personal custom types / promote-to-global (pre–2026-07-29) | DBR-SYN-005–006 **v1: no personal types**; curated enum only |
| DBR-SYN-004 “union multiple library rows for same Type” | DBR-SYN-004a at most one library Synergy per designation per user |
| DBR-SETB-002 vague “bonus present” | DBR-SYN-014b + DBR-SETB-002 (link target tier; count ≥ tier) |
| BR-CAT-001–003 vague “filter/search” only | DBR-ROLL-010 + BR-CAT-006–008 (facet include/exclude + group-by) |

Feature FRs remain historically useful; implementers should follow **DBR-*** when conflicting.

**Destiny Object product notes** (vault `Destiny Objects/`) hold presentation and object-level DO-* rules. Domain DBRs above are the enforceable subset; DO-* inform UI/implement detail without requiring every DO id in this file.
