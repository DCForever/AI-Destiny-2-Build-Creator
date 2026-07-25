/// Pure domain library for the multiplatform Destiny 2 Build Creator port.
///
/// This package must remain free of IO and UI dependencies (Flutter, Jaspr,
/// Drift, network clients, path providers). Models (DART-002), hard evaluators
/// (DART-003), soft coverage / soft-stat helpers (DART-004), pure
/// resolveVariant merge/conflict/completeness (DART-005), and equip-ready /
/// wishlist vs owned-pin gates (DART-006) live here; later slices land next.
library;

export 'src/smoke.dart';

// Models (DART-002 + soft input DTOs)
export 'src/models/constraints.dart';
export 'src/models/coverage.dart';
export 'src/models/equipment.dart';
export 'src/models/failure_codes.dart';
export 'src/models/kit.dart';
export 'src/models/library.dart';
export 'src/models/pin.dart';
export 'src/models/resolved_variant.dart';
export 'src/models/set_bonus.dart';
export 'src/models/slot_claim.dart';
export 'src/models/soft_stats.dart';
export 'src/models/synergy.dart';

// Hard evaluators (DART-003)
export 'src/evaluators/destiny_build_constraints.dart';

// Soft coverage + soft-stat helpers (DART-004)
export 'src/evaluators/soft_coverage.dart';
export 'src/evaluators/soft_stat_targets.dart';
export 'src/evaluators/stat_estimate.dart';
export 'src/evaluators/stat_nudges.dart';

// Resolve variant pure merge/conflict/completeness (DART-005)
export 'src/evaluators/resolve_variant.dart';

// Equip-ready / wishlist vs owned-pin gates (DART-006)
export 'src/evaluators/equip_ready.dart';
