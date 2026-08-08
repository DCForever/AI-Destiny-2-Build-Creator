/// Pure domain library for the multiplatform Destiny 2 Build Creator port.
///
/// This package must remain free of IO and UI dependencies (Flutter, Jaspr,
/// Drift, network clients, path providers). Models (DART-002), hard evaluators
/// (DART-003), set composition constraints (BR-SLOT-008/009), soft coverage /
/// soft-stat helpers (DART-004), pure resolveVariant merge/conflict/completeness
/// (DART-005), equip-ready / wishlist vs owned-pin gates (DART-006), pure equip
/// step planner (DART-037), finishGaps / next-slot helpers (DART-007), optimizer
/// enumerate/prune/score core (DART-008), and pure DIM loadout JSON builders +
/// equipReady-gated jsonOnly (DART-010) live here; later slices land next.
library;

export 'src/smoke.dart';

// Models (DART-002 + soft input DTOs + optimizer candidates + DIM shapes)
export 'src/models/constraints.dart';
export 'src/models/coverage.dart';
export 'src/models/dim_loadout.dart';
export 'src/models/equipment.dart';
export 'src/models/failure_codes.dart';
export 'src/models/kit.dart';
export 'src/models/library.dart';
export 'src/models/optimizer.dart';
export 'src/models/pin.dart';
export 'src/models/resolved_variant.dart';
export 'src/models/set_bonus.dart';
export 'src/models/slot_claim.dart';
export 'src/models/soft_stats.dart';
export 'src/models/synergy.dart';
export 'src/models/roll_target.dart';
export 'src/models/catalog_filter_collection.dart';

// Hard evaluators (DART-003)
export 'src/evaluators/destiny_build_constraints.dart';

// Set composition hard constraints (BR-SLOT-008/009 / DBR-CMP-007 kit hygiene)
export 'src/evaluators/destiny_set_constraints.dart';

// Set package minimum occupancy (DBR-CMP-008–010 / BR-SLOT-011–014)
export 'src/evaluators/set_minimum_occupancy.dart';

// Soft coverage + soft-stat helpers (DART-004)
export 'src/evaluators/soft_coverage.dart';
export 'src/evaluators/soft_stat_targets.dart';
export 'src/evaluators/stat_estimate.dart';
export 'src/evaluators/stat_nudges.dart';

// Resolve variant pure merge/conflict/completeness (DART-005)
export 'src/evaluators/resolve_variant.dart';

// Default kit bar + artifact completeness (pkg-default-three-gates)
export 'src/evaluators/default_loadout_completeness.dart';

// Per-variant effective subclass kit merge (pkg-variant-subclass-kit)
export 'src/evaluators/effective_subclass_kit.dart';

// Required synergy links hard gate (pkg-default-three-gates / DBR-SYN-010a)
export 'src/evaluators/assert_required_links.dart';

// Equip-ready / wishlist vs owned-pin gates (DART-006)
export 'src/evaluators/equip_ready.dart';

// Pure equip step planner (DART-037) — transfer/equip/artifact/fashion order
export 'src/evaluators/equip_plan.dart';

// Finish gaps / next-slot pure helpers (DART-007)
export 'src/evaluators/finish_gaps.dart';
export 'src/evaluators/finish_next_slot.dart';

// Optimizer pure core: enumerate / prune / score (DART-008)
export 'src/evaluators/optimizer_constraints.dart';
export 'src/evaluators/optimizer_enumerate.dart';
export 'src/evaluators/optimizer_prune.dart';
export 'src/evaluators/optimizer_score.dart';

// Optimizer pure pipeline + empty reasons (DART-035)
export 'src/evaluators/optimizer_explain_empty.dart';
export 'src/evaluators/optimizer_pipeline.dart';

// Pure DIM loadout JSON builders + equipReady-gated jsonOnly (DART-010)
export 'src/evaluators/dim_builders.dart';

// Catalog weapon roll targets: preferred + avoid score/rank (DART-073 system)
export 'src/evaluators/roll_target_score.dart';
