# Feature Specification: Item Filter Enrichment

**Feature Branch**: `013-item-filter-enrichment`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "I want to enrich items so that we have the data needed for more advanced filtering lookups. Phoenix Dive doesn't indicate that it provides Cure and that it is Warlock only and only on Dawnblade or Prismatic. Chaos Reach Super is only on Stormcaller and it Jolts enemies and it is Arc."

## Clarifications

### Session 2026-07-08

- Q: How complete must structured effect-verb tags be for abilities in v1? → A: **Best-effort all abilities** — whitelist word-boundary tagging across the ability catalog, plus overrides for acceptance anchors / ambiguous wording (not anchors-only, not a full hand-authored map).
- Q: How should Prismatic subclass affinities be named on enriched abilities and in subclass filters? → A: **Class-qualified** — `Prismatic Warlock`, `Prismatic Titan`, `Prismatic Hunter` (not bare `Prismatic`).
- Q: For shared abilities (e.g. shared grenades), which subclass affinities should enrichment list? → A: **Element-matched dedicated subclasses + Prismatic only when membership is proven** (plug-set / override)—not by element alone; not empty affinities; not auto-all Prismatic variants.
- Q: Where must curators run structured class/subclass/element/verb filters in v1? → A: **Search/lookup + minimal debug controls** — structured filter params on ability search/lookup plus simple filter fields on an existing debug ability/subclass surface (not lookup-only, not a full polished filter panel).
- Q: When filtering by class (e.g. Warlock), should shared abilities be included? → A: **Include shared** — `classType=Warlock` returns Warlock-only and shared (`classType` null) abilities; wrong-class exclusives remain excluded.

## Iteration Scope

**In scope**: Enrich curated game items (abilities and other filterable entity types that participate in advanced lookups) with structured **eligibility** and **effect** metadata so users can filter and discover items by class, subclass affinity, damage element, and gameplay verbs/effects—not only by name or free-text description. Canonical examples: **Phoenix Dive** is Warlock-only, available on Dawnblade and Prismatic Warlock, and provides **Cure**; **Chaos Reach** is Stormcaller-only, **Arc**, and **Jolts** enemies.

**Out of scope**: Full production or polished multi-select advanced-filter chrome; inventing new synergy categories; changing how builds store subclass selections; semantic/AI inference of effects from prose when structured sources already exist; enriching every weapon perk or armor mod in v1 beyond the entity types required for the acceptance examples and parallel ability-like items. **In scope for verification UI**: minimal filter controls on an existing debug ability/subclass surface that use the same structured filters as search/lookup.

**Builds on**: [007-complete-verb-vocabulary](../007-complete-verb-vocabulary/plan.md) (curated verb glossary including Cure and Jolt), [006-synergy-refinement](../006-synergy-refinement/spec.md) (Element and Verb as first-class concepts), [009-description-search](../009-description-search/spec.md) (text search remains complementary, not a substitute for structured filters).

**Verification**: Given known items (Phoenix Dive, Chaos Reach), enriched records expose class, subclass affinities, element, and effect verbs; filter/lookup surfaces can answer “Warlock + Cure”, “Dawnblade or Prismatic Warlock movement”, and “Stormcaller Arc Super that Jolts” without relying on description keyword luck alone.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Filter Abilities by Class, Subclass, Element, and Effect (Priority: P1)

A curator or builder looking for abilities that fit a build wants to filter by **who can use them** and **what they do**, not only by name. They need Phoenix Dive to appear when filtering for Warlock abilities that provide Cure and are valid on Dawnblade or Prismatic Warlock, and Chaos Reach when filtering for Stormcaller Arc supers that Jolt.

**Why this priority**: This is the user’s explicit gap—today items may show a name and description (and sometimes class/element) but do not reliably expose subclass affinity or structured effect verbs needed for advanced lookups.

**Independent Test**: Query or browse enriched ability data for Phoenix Dive and Chaos Reach; confirm each record carries the expected class, subclass affinities, element, and effect verbs; apply a multi-field filter that would fail if any of those fields were missing.

**Acceptance Scenarios**:

1. **Given** Phoenix Dive is in the curated ability catalog, **When** a user inspects its enrichment, **Then** it is marked Warlock-only, affiliated with Dawnblade and **Prismatic Warlock** (not other Warlock subclasses), and lists **Cure** among its effect verbs.
2. **Given** Chaos Reach is in the curated ability catalog, **When** a user inspects its enrichment, **Then** it is marked Stormcaller-only (or Warlock + Stormcaller affinity as applicable), element **Arc**, and lists **Jolt** among its effect verbs.
3. **Given** a filter for Warlock + Cure (and optionally Dawnblade or Prismatic Warlock), **When** results are returned, **Then** Phoenix Dive is included and abilities that do not provide Cure or are not Warlock-eligible are excluded.
4. **Given** a filter for Stormcaller + Arc + Jolt (or Super + those constraints), **When** results are returned, **Then** Chaos Reach is included and non-matching supers are excluded.
5. **Given** an ability with no known effect verbs, **When** enrichment is shown, **Then** effect verbs are empty or explicitly absent—not invented from unrelated description words—and the ability remains filterable by class, subclass, and element when those are known.

---

### User Story 2 - Discover Items Without Memorizing Exact Names (Priority: P1)

A user remembers the **mechanic** (“something that Cures on Warlock Solar/Prismatic”) or the **subclass + effect** (“Stormcaller super that Jolts”) but not the ability name. Structured enrichment lets them find the right item through filters instead of guessing names or scanning long description text.

**Why this priority**: Advanced filtering is only valuable if enrichment is complete enough that common discovery questions succeed without exact-name knowledge.

**Independent Test**: Without typing “Phoenix Dive” or “Chaos Reach”, apply filters matching the user’s examples and confirm those items appear in results with enough identity (name + key enrichment fields) to select confidently.

**Acceptance Scenarios**:

1. **Given** the user does not know the name Phoenix Dive, **When** they filter for Warlock abilities that provide Cure and are valid on Dawnblade or Prismatic Warlock, **Then** Phoenix Dive appears in the result set.
2. **Given** the user does not know the name Chaos Reach, **When** they filter for Stormcaller Arc supers that Jolt, **Then** Chaos Reach appears in the result set.
3. **Given** multiple abilities share an effect verb (e.g. Cure), **When** the user adds class and/or subclass filters, **Then** results narrow to eligible items only.
4. **Given** no items match the combined filters, **When** results are shown, **Then** the user sees a clear empty state—not unrelated items.

---

### User Story 3 - Enrichment Stays Accurate Across Shared and Exclusive Items (Priority: P2)

Some abilities are class-exclusive and subclass-limited; others are shared across subclasses or classes (e.g. shared grenades). Enrichment must represent exclusivity correctly so filters do not over-include or under-include.

**Why this priority**: Incorrect subclass or class affinity would make advanced filters untrustworthy even if effect verbs are present.

**Independent Test**: Compare a class-exclusive subclass-limited ability (Phoenix Dive / Chaos Reach) with a shared ability; confirm enrichment reflects exclusivity vs sharing and filters behave accordingly.

**Acceptance Scenarios**:

1. **Given** a Warlock-only ability limited to Dawnblade and Prismatic Warlock, **When** the user filters for Titan or Hunter, **Then** that ability is excluded.
2. **Given** a Warlock-only ability limited to Dawnblade and Prismatic Warlock, **When** the user filters for Voidwalker or Shadebinder, **Then** that ability is excluded.
3. **Given** a shared ability available to multiple subclasses (e.g. a shared Arc grenade), **When** enrichment is inspected, **Then** `subclassAffinities` lists the element-matched dedicated subclasses (e.g. Striker, Arcstrider, Stormcaller) and includes class-qualified Prismatic affinities only when membership is proven—not by element match alone—so filters for any listed subclass include it.
4. **Given** a shared ability (`classType` null) and a Warlock-only ability, **When** the user filters by class Warlock, **Then** both the shared ability and the Warlock-only ability are included; Titan-only or Hunter-only abilities are excluded.
5. **Given** an ability’s element is Arc, **When** the user filters for Solar, **Then** that ability is excluded.

---

### Edge Cases

- Ability exists in catalog but subclass affinity cannot be determined from available sources: record remains usable for name/description search; structured subclass filters treat it as unknown (excluded from positive subclass matches unless the product explicitly offers an “unknown affinity” bucket).
- Ability description mentions a verb casually but the ability does not apply that effect: enrichment MUST NOT list that verb as an effect.
- Same display name appears on multiple classes or elements: each distinct item keeps its own class, subclass, element, and effect enrichment.
- Prismatic access: abilities usable on a Prismatic subclass as well as a dedicated subclass (e.g. Dawnblade + Prismatic Warlock) list **both** affinities using **class-qualified** Prismatic names (`Prismatic Warlock`, `Prismatic Titan`, `Prismatic Hunter`)—not bare `Prismatic`.
- Effect vocabulary alignment: effect verbs use the project’s curated verb names (e.g. Cure, Jolt)—not free-form synonyms—so filters match synergy/verb vocabulary.
- Shared abilities: subclass affinities expand to element-matched dedicated subclasses; Prismatic class-qualified affinities are added only when membership is proven (plug-set or override), never solely because the element appears on Prismatic.
- Class filter with shared items: filtering by a specific class includes shared abilities usable by that class; it does not require a separate “include shared” flag.
- Items that are not abilities (aspects, fragments, etc.): when included in this iteration’s enrichment scope, they follow the same class/subclass/element/effect rules; when deferred, they remain out of advanced structured filters until a later increment.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST enrich filterable ability items with structured **class eligibility** (Titan, Hunter, Warlock, or shared/all where applicable) so class-based filters are reliable. When a class filter is set (e.g. Warlock), results MUST include that class’s exclusive abilities **and** shared abilities (`classType` null); MUST exclude abilities exclusive to other classes.
- **FR-002**: System MUST enrich filterable ability items with structured **subclass affinities** (e.g. Dawnblade, Stormcaller, Prismatic Warlock) listing every subclass on which the item is available. Prismatic affinities MUST use class-qualified names (`Prismatic Warlock`, `Prismatic Titan`, `Prismatic Hunter`), not bare `Prismatic`. For **shared** abilities (`classType` null / shared category), affinities MUST list element-matched dedicated subclasses and MUST add Prismatic class variants only when membership is proven (not by element alone).
- **FR-003**: System MUST enrich filterable ability items with structured **damage element** (Kinetic, Arc, Solar, Void, Stasis, Strand, Prismatic) when the item has an elemental identity.
- **FR-004**: System MUST enrich filterable ability items with structured **effect verbs** drawn from the curated Destiny verb vocabulary (e.g. Cure, Jolt) for effects the item provides or applies. In v1, enrichment MUST be **best-effort across the ability catalog**: apply whitelist word-boundary tagging (and linked structured text when available) to all abilities, and apply explicit overrides for acceptance anchors or ambiguous wording; abilities with no confident match MUST keep an empty verb list rather than inventing tags.
- **FR-005**: System MUST support advanced lookups that combine class, subclass affinity, element, and effect verb filters (AND across selected dimensions) so queries matching the Phoenix Dive and Chaos Reach examples succeed.
- **FR-006**: Enrichment for Phoenix Dive MUST include at least: class Warlock; subclass affinities Dawnblade and Prismatic Warlock; effect verb Cure.
- **FR-007**: Enrichment for Chaos Reach MUST include at least: subclass affinity Stormcaller; element Arc; effect verb Jolt.
- **FR-008**: Effect verb enrichment MUST be explicit and validated—not inferred solely by loose substring match against description text—so casual mention of a word does not create a false effect tag.
- **FR-009**: When enrichment fields are unknown or unavailable, the system MUST represent absence clearly and MUST NOT invent class, subclass, element, or effect values.
- **FR-010**: Existing name and description search MUST continue to work; structured enrichment is additive for advanced filtering, not a replacement for text search.
- **FR-011**: Enrichment data used for filtering MUST be available via the project's ability search/lookup surfaces **and** via **minimal debug UI controls** on an existing ability/subclass debug surface (fields for class, subclass, element, and verb that apply the same filters)—not lookup-only and not a full production filter panel.

### Key Entities

- **Enriched Item**: A curated game item (primarily abilities such as supers, melees, grenades, class abilities, and movement abilities) with identity plus structured eligibility and effect metadata for filtering.
- **Class Eligibility**: Which guardian class(es) may use the item (exclusive or shared).
- **Subclass Affinity**: Which subclass identities the item is available on, including class-qualified Prismatic names (`Prismatic Warlock`, `Prismatic Titan`, `Prismatic Hunter`) where applicable.
- **Damage Element**: The item’s elemental identity when it has one.
- **Effect Verb**: A curated gameplay keyword/status the item provides or applies (e.g. Cure, Jolt), aligned with the project verb vocabulary.
- **Advanced Filter Query**: A combination of one or more enrichment dimensions used to narrow item lookup results.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In verification against the acceptance examples, Phoenix Dive and Chaos Reach each expose 100% of the required enrichment fields listed in FR-006 and FR-007.
- **SC-002**: Users can find Phoenix Dive and Chaos Reach using only structured filters (no exact name) in under 30 seconds in a guided verification session.
- **SC-003**: At least 95% of curated abilities that have a known class and element in source data expose those fields in enrichment used for filtering.
- **SC-004**: For a sample of 20 abilities with known effect verbs (including Cure and Jolt examples), structured effect filters return the expected items with zero false positives caused by description-only word matches.
- **SC-005**: Combining class + subclass + element + effect filters reduces result sets to only eligible items for the Phoenix Dive and Chaos Reach scenarios (no off-class or wrong-subclass inclusions).

## Assumptions

- Primary v1 focus is **abilities** (super, grenade, melee, class ability, movement); aspects/fragments/mods may already carry partial class/element data and can reuse the same enrichment model later if not fully covered here.
- Class and element for many abilities already exist in curated projections; this feature adds **subclass affinity** and **effect verbs**, and ensures all four dimensions are consistently available for advanced filters.
- Effect verbs align with the curated verb glossary from the complete-verb-vocabulary work (Cure, Jolt, etc.), not ad-hoc synonyms.
- Verb completeness in v1 is best-effort catalog-wide tagging plus overrides for anchors/ambiguity—not a guarantee that every ability that “should” have a verb in lore is tagged, and not a full hand-maintained verb map.
- Prismatic subclass affinities use class-qualified names (`Prismatic Warlock`, etc.); Prismatic may also appear as an **element** where that is already the project convention. Dawnblade + Prismatic Warlock dual availability is represented as two affinities on the same item.
- Shared ability affinities: element-matched dedicated subclasses plus proven Prismatic membership only (not auto-all Prismatic variants; not empty affinities for shared items that have a known element).
- Class filter semantics: specific class includes exclusives for that class plus shared; excludes other classes’ exclusives.
- Advanced filters ship as search/lookup filter params plus minimal debug UI fields on an existing ability/subclass surface; polished production filter chrome can follow in a later feature.
- Description search (009) remains available as a fallback when structured effect tags are absent.
- “Items” in the user request means curated catalog entities used in lookups—not inventory instance rolls.
