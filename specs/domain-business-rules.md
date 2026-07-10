# Domain Business Rules — Destiny 2 Builds

**Created**: 2026-07-10  
**Status**: Canonical domain layer  
**Source**: Clarification session 2026-07-09 → 2026-07-10  

High-level rules for how Destiny 2 builds work in this system and how the product should use them. Feature-level BRs remain in [`business-rules.md`](./business-rules.md); where they conflict, **this document wins** (see Supersessions).

**Companion**: [`domain-acceptance-criteria.md`](./domain-acceptance-criteria.md)

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
| DBR-ID-007 | **Super** is normally **variant-level**. It may be **build-pinned**; when pinned, it is identity. |
| DBR-ID-008 | Changing identity fields requires **confirm in-place** (affects all variants) or **fork** to a new Build. |
| DBR-ID-009 | Identity fields include: designated synergies; exotic armor item when set; build-shared exotic weapon when set; build-pinned Super when set. |
| DBR-ID-010 | Gear, mods, aspects/fragments, non-pinned abilities, fashion, and artifact configs are **variant** concerns (not identity), except where exotic ability-requirements auto-pin abilities (see DBR-EXO-003). |

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
| DBR-SUB-001 | **Subclass element/tree** is shared across all variants (Solar, Arc, Void, Stasis, Strand, Prismatic). |
| DBR-SUB-002 | **Prismatic** uses the same rules as other trees — no special identity model. |
| DBR-SUB-003 | **Aspects, fragments, and ability choices** may differ per variant, except build-pinned Super / exotic-required pinned abilities. |
| DBR-SUB-004 | Illegal subclass kits (invalid combinations or over aspect/fragment slot limits) **cannot be saved**. |
| DBR-SUB-005 | When an exotic requires a specific Super / melee / grenade / class ability, the system **auto-proposes build-pinned abilities**; user confirms; **mismatch blocks save**. |

---

## 6. Synergies

| ID | Rule |
|----|------|
| DBR-SYN-001 | A Synergy is a **curated play-pattern**: named goal with linked gear evidence. |
| DBR-SYN-002 | Builds are created **intent-first**: user states goals via a **controlled vocabulary** (verbs/goals/synergy types); system helps find or create matching curated synergies. |
| DBR-SYN-003 | Every Build must designate **≥1** synergy to save (`NO_SYNERGY` otherwise). |
| DBR-SYN-004 | Multiple designated synergies contribute **equally** to suggestions and coverage. Soft UI nudge toward roughly **2–5**; no hard maximum. |
| DBR-SYN-005 | Users may create **personal custom synergy types** grounded in keyword/verb-like concepts (e.g. Corruption, Poison). |
| DBR-SYN-006 | Keywords may come from the **global vocabulary** or **personal keywords**, with optional later promote-to-global. |
| DBR-SYN-007 | Synergy links are **evidence by default**. Authors may mark specific links **required**. |
| DBR-SYN-008 | Required flag may apply to **any** link kind (weapon, perk, origin trait, armor set bonus, etc.). |
| DBR-SYN-009 | Multiple required links on one synergy are **AND** — all must be satisfied. |
| DBR-SYN-010 | Required-link hard checks apply to the **default variant only**; other variants get soft warnings. |
| DBR-SYN-011 | Non-default variants receive **soft guidance** for synergy coverage (suggestions/warnings); weak coverage does not block save. |

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
| DBR-ROLL-007 | **Catalysts**: display status only — equipped; unequipped (warn); unfinished (warn); unacquired. Do not gate save/equip. |
| DBR-ROLL-008 | **Deepsight / pattern progress**: display-only with warns; no save/equip gate. |
| DBR-ROLL-009 | Exotic class item variants store **full selected perk config** (instance or wishlist desired config). |

---

## 9. Completeness: default vs other variants

| ID | Rule |
|----|------|
| DBR-CMPL-001 | **Default variant** must be a **full combat loadout** (class, subclass kit, all weapon slots, all armor slots, mods as part of the build). |
| DBR-CMPL-002 | **Non-default variants** may leave some combat slots **empty**. |
| DBR-CMPL-003 | On equip-with-gaps, **empty combat slots leave the character’s current gear as-is**. |
| DBR-CMPL-004 | Non-default variants may equip with gaps only after **user confirmation**. |

---

## 10. Stats (Edge of Fate)

| ID | Rule |
|----|------|
| DBR-STAT-001 | Soft stat targets use the EoF six: **Class, Grenade, Melee, Super, Health, Weapons**. |
| DBR-STAT-002 | Targets are optional **per-stat thresholds** at **build level** (shared across variants). |
| DBR-STAT-003 | Valid target range supports benefits up to **200** (max for benefits). |
| DBR-STAT-004 | Missing targets do not block save/equip; below-target is a **warning** via soft guidance. |
| DBR-STAT-005 | Coverage uses a **full loadout estimate**: armor (including class item), mods, fragments/aspects, and other known loadout bonuses. |
| DBR-STAT-006 | Designated synergies may **suggest/nudge** related soft stat targets; user accepts or ignores. |
| DBR-STAT-007 | Weapon damage type vs subclass element is **soft / synergy-based** — no blanket hard element lock. |

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
| DBR-SETB-002 | If a designated synergy has a **required** set-bonus link, the **default variant** cannot save until that bonus is present (AND with other required links). |

---

## 13. Artifacts

| ID | Rule |
|----|------|
| DBR-ART-001 | There are **6 fixed artifacts**, switchable via API; not expected to grow/change. |
| DBR-ART-002 | Each variant selects **exactly one** of the 6 artifacts. |
| DBR-ART-003 | Each variant stores a **full artifact config** (selected unlocks/mods) and equip **applies** them. |

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
| DBR-GUID-003 | Hard blocks are reserved for true Destiny/system constraints (exotics limits, energy, illegal kits, ownership/pins for equip, required links on default, etc.). |

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

## 17. Clarifications log

### Session 2026-07-09 / 2026-07-10

Summarized decisions from the domain Q&A (Q1–Q101). Corrections applied in-place: Q14→B (curated synergies); Q16→B (exotic armor optional); Q47→A (save without pins OK).

---

## Supersessions vs `business-rules.md`

| Legacy rule | Domain replacement |
|-------------|-------------------|
| BR-BLD-002 (tags + aspects shared as identity) | DBR-ID-*; DBR-SUB-*; tags not identity |
| BR-BLD-003 / BR-BLD-004 (exotic armor always build-level; exotic weapon always variant) | DBR-ID-003–006 (optional armor; weapon build-or-variant; class-item intent lock) |
| BR-SAVE-001 / BR-SAVE-002 / BR-SAVE-004 (≥1 slot) | DBR-CMPL-001–002 (default full; others may gap) |
| BR-FASH-002 (fashion never in composition/equip) | DBR-FASH-001–005 (fashion in equip; still not synergies/stats) |
| BR-VAR-002 (variants typically snapshots) | DBR-CMP-003 (live default; snapshot optional) |
| BR-SUG-001 emphasis | DBR-GUID-002 (synergy coverage primary) |

Feature FRs remain historically useful; implementers should follow **DBR-*** when conflicting.
