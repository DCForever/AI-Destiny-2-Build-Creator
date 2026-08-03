# Domain Acceptance Criteria — Destiny 2 Builds

**Created**: 2026-07-10  
**Updated**: 2026-08-03 (DAC-SET-002 Pair complete; DAC-SET-003 under-min not attachable — dart-070)  
**Status**: Canonical domain layer  
**Source**: Clarification session 2026-07-09 → 2026-07-10; product reconciliation 2026-07-14; Set minimum occupancy 2026-07-29; **Obsidian product packs re-sync 2026-07-29**

High-level, testable acceptance criteria for the Build Composer. Trace to [`domain-business-rules.md`](./domain-business-rules.md) (`DBR-*`).

Feature specs under `specs/00N-*/` remain the place for implementation slices; these ACs define product-level “done.”

---

## Priority journeys

| Priority | Journey | Done when |
|----------|---------|-----------|
| **P1** | Intent → compose → equip | DAC-P1-* pass |
| **P2** | Curate library | DAC-P2-* pass (supports P1; in-flow create still allowed) |

---

## P1 — Intent → compose → equip

### DAC-P1-001 — Intent to designated Synergy Types

**Given** a signed-in user starting a new Build  
**When** they state intent via controlled vocabulary (Synergy Types: type + optional subType)  
**Then** the user designates ≥1 Synergy Type (library Synergy records are not required to save)  
**And** the system bridges designations to matching curated Synergies (Type + Object) for coverage/suggestions when present  
**And** when a designated verb implies an element, that element is included in effective bridging without requiring a separate element designation  
**And** save is rejected with `NO_SYNERGY` if zero Synergy Types are designated  
**Refs**: DBR-SYN-001–003, DBR-SYN-013, DBR-PUR-003

### DAC-P1-002 — Build identity established

**Given** designated Synergy Types (and optional exotic armor item / build-shared exotic weapon / build-pinned Super)  
**When** the user saves the Build  
**Then** those fields form build identity  
**And** concept tags may be set for filtering only without becoming identity  
**Refs**: DBR-ID-001–010, DBR-ID-002

### DAC-P1-003 — Default variant full combat loadout

**Given** the default variant  
**When** the user marks it complete / saves as the build’s default  
**Then** it includes class, shared subclass tree, a legal subclass kit (aspects filled, fragments at capacity, Super + melee + grenade; class ability/movement only if required), all three weapon slots, all five armor slots, mods path, and artifact selected with **filled config**  
**And** fashion is optional  
**And** illegal kits, over-capacity mods, or >1 exotic weapon/armor cannot save  
**And** default save also requires required-link gate (equip-ready satisfaction) before success  
**Refs**: DBR-CMPL-001–001d, DBR-SUB-004–007, DBR-ART-003a, DBR-MOD-001, DBR-CMP-007, DBR-SYN-010a

### DAC-P1-004 — Compose via sets with overrides

**Given** a variant under edit  
**When** the user attaches Sets (live by default) and/or pins slot overrides  
**Then** the variant resolves to a coherent loadout without unresolved slot conflicts  
**Refs**: DBR-CMP-001–006

### DAC-P1-005 — Wishlist vs equip-ready

**Given** a variant with a desired roll the user does not own  
**When** they save  
**Then** the variant saves with desired roll data (item + plugs) marked unowned  
**And** in-game equip and DIM export for that variant are blocked until every applied slot has a pinned owned instance  
**Refs**: DBR-ROLL-001–005, DBR-EQP-003

### DAC-P1-006 — Soft guidance visible

**Given** a build with designated synergies and optional soft stat targets  
**When** the user views a variant  
**Then** they see passive indicators and a coverage breakdown (supported / weak / missing + hints) for synergies, stats, and related soft checks  
**And** weak coverage does not block save on non-default variants  
**Refs**: DBR-GUID-001–003, DBR-SYN-011, DBR-STAT-004

### DAC-P1-007 — Equip in-game (Bungie API)

**Given** an equip-ready default variant (owned instance pins on all applied slots)  
**When** the user equips  
**Then** inventory refreshes (respecting ~1/min rate limit), the user picks a class-matching character, items transfer from vault/other characters as needed, and the loadout + artifact config (+ fashion if specified) are applied via Bungie API  
**And** failures are reported as best-effort partial apply; retry is the recovery path  
**Refs**: DBR-EQP-001, DBR-EQP-005–008, DBR-ART-002–003, DBR-FASH-001

### DAC-P1-008 — DIM export

**Given** the same equip-ready variant  
**When** the user exports to DIM  
**Then** a full variant loadout is produced (subclass kit, gear, mods, fashion, artifact)  
**And** wishlist-only / unpinned variants cannot export  
**Refs**: DBR-EQP-002–004, DBR-EQP-003

### DAC-P1-009 — Library bar for P1 done

**Given** P1 compose+equip works  
**When** evaluating domain “done” for the primary journey  
**Then** the account also has ≥10 synergies and ≥10 sets spanning weapon/armor/mod (ideally pair or fashion)  
**Refs**: DBR-PUR-005

---

## P2 — Library curation

### DAC-P2-001 — Curated synergies with evidence links

**Given** a user curating synergies  
**When** they create/edit a synergy with links to weapons, perks, origin traits, set bonuses, exotic armor, artifact perks, etc.  
**Then** links validate against manifest data  
**And** links are evidence by default; any link kind may be marked required (AND semantics)  
**And** exotic weapon trait plugs are valid `weapon_perk` evidence targets (not only legendary perk rolls)  
**And** objects already linked on this synergy are omitted from that synergy’s link search results (no duplicate evidence targets on one row)  
**And** weapon-perk search shows whether a hit is an exotic intrinsic/trait vs a legendary perk  
**Refs**: DBR-SYN-001, DBR-SYN-007–009, DBR-SYN-014, BR-SYN-011, BR-SYN-012

### DAC-P2-001a — Library designation immutable after create

**Given** a library synergy already created with a type and optional subtype  
**When** the user edits that synergy  
**Then** they may change description and linked Objects  
**And** they cannot change type or subtype (UI read-only; API rejects designation changes)  
**Refs**: DBR-SYN-012

### DAC-P2-002 — Required links on default variant

**Given** a designated synergy with required links  
**When** saving the default variant  
**Then** save is blocked until all required links are satisfied  
**And** other variants only soft-warn  
**Refs**: DBR-SYN-010, DBR-SETB-002

### DAC-P2-003 — No personal custom synergy types (v1)

**Given** a user creating a library Synergy or designating Build Types  
**When** they open the type picker  
**Then** only product enum types and curated subTypes are available  
**And** inventing a personal type key is rejected  
**Refs**: DBR-SYN-005–006

### DAC-P2-003a — Expanded link kinds

**Given** a user editing library Synergy links  
**When** they add evidence  
**Then** they may choose any v1 linkable kind (weapon, weapon_perk, origin_trait, armor_set_bonus, exotic_armor, aspect, fragment, armor_mod, melee, grenade, super, artifact_perk)  
**And** class ability / movement / fashion are not offered as link kinds  
**Refs**: DBR-SYN-015–016

### DAC-P2-004 — LLM propose-for-confirm pass

**Given** the user manually starts an LLM description pass  
**When** the pass completes over the broad loadout surface  
**Then** proposed synergies/keywords/evidence are presented for confirmation  
**And** nothing becomes canonical until the user confirms/edits  
**Refs**: DBR-LLM-001–005

### DAC-P2-005 — In-flow create still works

**Given** a thin library  
**When** the user composes a build  
**Then** they can create needed synergies/sets during compose without a hard library gate  
**Refs**: DBR-PUR-004

---

## Variants & identity

### DAC-VAR-001 — Non-default gaps

**Given** a non-default variant with some empty combat slots  
**When** the user confirms equip-with-gaps  
**Then** specified slots apply and empty slots leave character gear unchanged  
**Refs**: DBR-CMPL-002–004, DBR-EQP-008

### DAC-VAR-002 — Artifact per variant

**Given** two variants of the same build  
**When** they select different artifacts and unlock configs  
**Then** each stores exactly one of the six artifacts with full config  
**And** equip applies that variant’s artifact config  
**And** default save fails if artifact config is empty/unfilled  
**Refs**: DBR-ART-001–003a, DBR-CMPL-001a

### DAC-VAR-003 — Fashion per variant

**Given** a variant with fashion (shaders, ghost/sparrow/ship/emblem, finisher)  
**When** the user equips/exports  
**Then** specified fashion applies and omitted fashion slots are left as-is  
**Refs**: DBR-FASH-001–005

### DAC-VAR-004 — Identity edit confirm/fork

**Given** an existing build with variants  
**When** the user changes designated synergies, set exotic armor item, build-shared exotic weapon, build-pinned Super, or subclass tree  
**Then** the system warns and offers confirm in-place or fork  
**Refs**: DBR-ID-008–008a, DBR-BLD-008

### DAC-VAR-004a — Tree change wipes kit

**Given** a build with filled subclass kits on variants  
**When** the user confirms a subclass tree change  
**Then** each variant’s Subclass area is wiped to an empty legal baseline for the new tree  
**And** default must be re-filled before default save succeeds  
**Refs**: DBR-BLD-009, DBR-SUB-001

### DAC-VAR-004b — Four variant areas

**Given** any variant  
**When** the user opens the Build composer  
**Then** exactly four areas are present: General, Subclass, Armor + Mods Sets, Weapons Set  
**Refs**: DBR-CMPL-005

### DAC-VAR-004c — Required links need pins

**Given** a default variant whose designated Synergies have required links  
**When** the user saves default with only wishlist (no equip-ready pin) matching a required target  
**Then** save is rejected for required-link failure  
**And** save succeeds once equip-ready pins (or applied kit pieces) satisfy all required links  
**Refs**: DBR-SYN-010a, DBR-CMPL-001d

### DAC-VAR-005 — Exotic class item within intent

**Given** a build whose exotic slot is an exotic class item  
**When** variants use different class items/perk configs that still fit designated synergies  
**Then** save is allowed with soft coverage guidance  
**And** each variant stores full class-item perk config  
**Refs**: DBR-ID-005, DBR-ROLL-009

### DAC-VAR-006 — Classic exotic armor item lock

**Given** a build with Felwinter’s Helm (or similar) set as exotic armor identity  
**When** variants pin different owned instances of that item  
**Then** identity remains the same item  
**And** changing to a different exotic armor item requires identity confirm/fork  
**Refs**: DBR-ID-003

---

## Destiny constraints

### DAC-DST-001 — Exotic limits

**Given** a variant that would equip two exotic weapons or two exotic armor pieces  
**When** the user saves  
**Then** save is rejected  
**And** the normal UI prevents selecting / completing the second exotic when composition is known  
**Refs**: DBR-CMP-007

### DAC-DST-002 — Mod energy

**Given** armor tier ≤4 (10 energy) or tier 5 (11 energy)  
**When** mods exceed capacity or are illegal for the piece  
**Then** save is rejected  
**And** the Mods UI shows remaining energy and refuses over-cap picks when cost is known  
**Refs**: DBR-MOD-001–003

### DAC-DST-003 — Subclass slot limits

**Given** a subclass kit over aspect/fragment limits or otherwise illegal  
**When** the user saves  
**Then** save is rejected  
**And** the Aspects/Fragments UI caps picks (max 2 aspects; fragments ≤ aspect capacity) when capacity is known  
**And** reducing aspect capacity trims excess fragments  
**Refs**: DBR-SUB-004, DBR-SUB-008–009

### DAC-DST-003a — Default subclass kit bar

**Given** the default variant Subclass area  
**When** the user saves as default  
**Then** aspects are filled (when max known), fragments are at capacity, and Super + melee + grenade are selected  
**And** empty class ability or movement does not block default unless an exotic forces them  
**Refs**: DBR-SUB-006–007, DBR-CMPL-001

### DAC-DST-004 — Exotic ability requirements

**Given** an exotic that requires a specific ability (curated `exoticAbilityRequirements`)  
**When** it is set on the build  
**Then** the system proposes pinning that ability  
**And** after confirm, mismatched kits cannot save  
**Refs**: DBR-SUB-005

### DAC-DST-005 — Soft element matching

**Given** a Solar (or other) subclass tree and off-element weapons  
**When** the user views coverage  
**Then** element mismatch is soft/synergy-based, not a blanket hard block  
**Refs**: DBR-STAT-007

### DAC-DST-006 — EoF soft stats

**Given** build-level soft targets on Class/Grenade/Melee/Super/Health/Weapons (up to 200)  
**When** a variant’s full loadout estimate is below targets  
**Then** warnings appear; save/equip still allowed  
**And** synergies may nudge related targets for user acceptance  
**Refs**: DBR-STAT-001–006

### DAC-DST-007 — Stale pins

**Given** a pinned instance missing after sync  
**When** the user opens the variant  
**Then** the pin is marked stale, desired roll retained, equip blocked until re-pin  
**Refs**: DBR-ROLL-006

### DAC-DST-008 — Catalyst / deepsight display

**Given** an exotic weapon with a catalyst in data (and/or an instance with catalyst socket)  
**When** viewed on Catalog/Set **detail** or a build loadout expand  
**Then** catalyst name/effect and status display when known (equipped/inserted; complete-unequipped warn; unfinished warn; unacquired warn)  
**And** the instance socket grid includes a catalyst column when the socket exists  
**And** incomplete/missing catalyst does **not** block Set save, variant save, or equip  
**And** deepsight/pattern remain display-only and do not gate save/equip  
**Refs**: DBR-ROLL-007–008, DO-WPN-040–051 (vault Destiny Weapon)

### DAC-DST-009 — UI prevention of hard composition constraints

**Given** a user composing a Set (slot fill) or Build/variant (equipment, exotics, kit, mods)  
**When** an action would violate a Destiny hard rule (illegal set slot item, **second exotic in a weapon/armor set**, dual exotic on a variant, slot conflict, illegal kit, mod energy, exotic ability mismatch)  
**Then** the normal UI filters or blocks the action with plain-language reasons  
**And** the API still rejects the same invalid payload if submitted  
**Refs**: DBR-GUID-003, DBR-CMP-006, DBR-CMP-007, DBR-SUB-004, DBR-SUB-005, DBR-MOD-001–002, BR-SLOT-008–009, BR-UI-001

### DAC-DST-010 — Weapon/Armor set minimum items

**Given** a Weapon Set or Armor Set with **fewer than 2** filled items  
**When** the user saves the set  
**Then** save is rejected with a clear reason (`SET_MIN_ITEMS`)  
**And** the user can continue filling slots until ≥2 items are present  
**Refs**: DBR-CMP-008, BR-SLOT-011

### DAC-DST-011 — Mod set multi-piece minimum

**Given** a Mod Set with mods on **zero or one** armor piece only  
**When** the user saves the set  
**Then** save is rejected with a clear reason (`MOD_SET_MIN_SLOTS`)  
**And** save succeeds once at least **two** distinct armor pieces each have ≥1 mod  
**Refs**: DBR-CMP-009, BR-SLOT-012

### DAC-SET-002 — Pair package complete on save

**Given** a Pair Set missing exotic weapon or exotic armor (or both)  
**When** the user saves or finalizes the package  
**Then** save is rejected with a clear reason (`PAIR_INCOMPLETE`)  
**And** save succeeds only when **both** exotic weapon and exotic armor slots are filled  
**And** Fashion Sets remain exempt from combat package floors (DBR-CMP-010)  
**Refs**: DBR-CMP-010 Pair path, BR-SLOT-014

### DAC-SET-003 — Under-min packages not attachable

**Given** a Set that fails package save floors (Weapon/Armor &lt;2 items, Mod on &lt;2 armor pieces, incomplete Pair)  
**When** the user tries to attach it to a Build variant  
**Then** attach is blocked with a clear reason (`SET_MIN_ITEMS`, `MOD_SET_MIN_SLOTS`, `PAIR_INCOMPLETE`, or `SET_NOT_ATTACHABLE`)  
**And** under-min scaffolds are not listed as attachable packages  
**And** hosts show plain-language errors (not bare hashes)  
**Refs**: BR-ATT-006, BR-ATT-006a, DBR-CMP-008–010, DAC-DST-010–011, DAC-SET-002

### DAC-DST-012 — Armor set bonus constraint

**Given** an Armor Set with a set-bonus constraint (family + 2pc or 4pc)  
**When** the user fills a non-exotic piece outside the family or saves below the target member count  
**Then** fill/save/attach is rejected (`ARMOR_SET_BONUS_MISMATCH` or `ARMOR_SET_BONUS_INCOMPLETE`)  
**And** exotic pieces do not count toward the tier  
**Refs**: DBR-SETB-003–006

### DAC-DST-013 — Required armor_set_bonus link tier

**Given** a library Synergy with a required `armor_set_bonus` link at target tier 4  
**When** the default variant has only 2 contributing members of that family  
**Then** default save fails the required-link gate  
**And** with 4 contributing members (and equip-ready path) the link is satisfied  
**Refs**: DBR-SYN-014b, DBR-SETB-002

### DAC-DST-014 — Weapon perk family match

**Given** a required `weapon_perk` link to a trait family  
**When** the resolved loadout has the enhanced variant of that trait pinned  
**Then** the required link is satisfied when family mapping is known  
**Refs**: DBR-SYN-014a

### DAC-DST-015 — No bare hashes in primary UI

**Given** a perk, mod, or item on a row or detail headline  
**When** the user views primary UI  
**Then** they see readable name + icon, not a bare hash as the label  
**And** hashes may appear only in a detail footer addendum  
**Refs**: DBR-UI-006

---

## Naming & browsing

### DAC-NME-001 — Default and unique names

**Given** a new build  
**When** saved without a custom name  
**Then** a default name is derived from Class, Element, Super, Exotic Armor, Exotic Weapon, Synergies (omitting missing segments)  
**And** manual renames are unique per class  
**Refs**: DBR-NAME-001–004

### DAC-NME-002 — Tag filter without identity

**Given** builds tagged PVE or Dungeon without matching synergies  
**When** the user filters by those tags  
**Then** matching builds appear  
**And** changing tags does not trigger identity confirm/fork  
**Refs**: DBR-ID-002

### DAC-NME-003 — Catalog multi-facet browse

**Given** a user browsing weapons or armor in Catalog (including set-fill constrained pick)  
**When** they combine free-text with multi-value facets (e.g. element, ammo, archetype) including include and exclude  
**Then** results respect OR-within-facet, AND-across-facets, and exclude-drop semantics  
**And** optional group-by dimensions partition the result list without changing filter semantics  
**Refs**: DBR-ROLL-010

### DAC-NME-004 — Armor set stats and item detail

**Given** an Armor set with one or more **pinned inventory instances**  
**When** the user opens set detail  
**Then** they see per-piece Health, Melee, Grenade, Super, Class, Weapons (when synced) and set **totals** for those stats  
**And** each item row shows identity meta (element, type/frame, tier, origin trait), selected trait perks (not barrel/mag/stock), available trait names, and linked library synergies when present  
**And** wishlist/unpinned pieces show that stats are unknown  
**Refs**: DBR-STAT-001, DBR-CMP-001, BR-SET-010

---

## Out of scope (domain)

| Item | AC expectation |
|------|----------------|
| Emotes | Not modeled |
| Consumables / temporary buffs | Not modeled |
| Continuous realtime inventory sync | Not required; sync-on-equip with rate limit |
| Hard rollback on partial equip | Not required; retry |
| Shareable links | Planned later; not P1 |
| Auto LLM on every manifest change | Not required; manual re-run |

---

## Traceability (AC → DBR)

| AC pack | Primary DBRs |
|---------|----------------|
| DAC-P1-* | DBR-PUR-*, DBR-SYN-*, DBR-CMPL-*, DBR-EQP-*, DBR-ROLL-*, DBR-GUID-* |
| DAC-P2-* | DBR-SYN-*, DBR-LLM-*, DBR-PUR-004–005 (incl. DBR-SYN-012–017) |
| DAC-VAR-* | DBR-ID-*, DBR-ART-*, DBR-FASH-*, DBR-CMPL-*, DBR-BLD-008–009 |
| DAC-DST-* | DBR-CMP-007–010, DBR-MOD-*, DBR-SUB-*, DBR-SETB-*, DBR-STAT-*, DBR-ROLL-*, DBR-GUID-003, DBR-UI-006 |
| DAC-NME-* | DBR-NAME-*, DBR-ID-002, DBR-ROLL-010, DBR-STAT-001, DBR-CMP-001 |
