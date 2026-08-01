/// Pure static sandbox tables for the multiplatform Destiny 2 Build Creator port.
///
/// This package must remain free of IO and UI dependencies (Flutter, Jaspr,
/// Drift, network clients, path providers). Tables mirror product `src/data/`
/// curated sandbox constants (DART-009). Soft display tables never auto-apply
/// and never hard-block saves — hard gates stay in `destiny2_domain`.
///
/// When Destiny ships a sandbox patch, follow
/// `docs/sandbox-data-update-process.md`.
library;

export 'src/ability_timings.dart';
export 'src/activity_rules.dart';
export 'src/armor_archetypes.dart';
export 'src/armor_stat_name.dart';
export 'src/champion_counters.dart';
export 'src/concept_tags.dart';
export 'src/exotic_ability_requirements.dart';
export 'src/stat_benefits.dart';
export 'src/subclasses.dart';
export 'src/synergy_elements.dart';
export 'src/synergy_verbs.dart';
export 'src/weapon_types.dart';
