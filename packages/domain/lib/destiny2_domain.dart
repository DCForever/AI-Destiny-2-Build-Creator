/// Pure domain library for the multiplatform Destiny 2 Build Creator port.
///
/// This package must remain free of IO and UI dependencies (Flutter, Jaspr,
/// Drift, network clients, path providers). Models live here (DART-002);
/// evaluators land in later DART slices.
library;

export 'src/smoke.dart';

// Models (DART-002)
export 'src/models/constraints.dart';
export 'src/models/coverage.dart';
export 'src/models/equipment.dart';
export 'src/models/failure_codes.dart';
export 'src/models/kit.dart';
export 'src/models/library.dart';
export 'src/models/pin.dart';
export 'src/models/resolved_variant.dart';
export 'src/models/slot_claim.dart';
export 'src/models/soft_stats.dart';
export 'src/models/synergy.dart';
