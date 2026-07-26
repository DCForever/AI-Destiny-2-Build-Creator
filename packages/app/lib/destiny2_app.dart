/// In-process application use cases for the multiplatform Destiny 2 Build
/// Creator port (slices 027+).
///
/// Orchestrates [destiny2_db] repositories with pure [destiny2_domain]
/// validation. No HTTP routes, Flutter/Jaspr UI, or CLIENT_SECRET.
///
/// Includes set/synergy CRUD + attach, build/variant hard gates + soft coverage
/// query, and optimizer isolate runner + confirm-only materialize/apply.
library;

export 'src/attachment_use_cases.dart';
export 'src/build_use_cases.dart';
export 'src/clock_ids.dart';
export 'src/compose_hard_blocks.dart';
export 'src/coverage_use_cases.dart';
export 'src/errors.dart';
export 'src/hard_gate_ports.dart';
export 'src/hard_gates.dart';
export 'src/identity_change.dart';
export 'src/mappers.dart';
export 'src/optimizer_isolate.dart';
export 'src/optimizer_use_cases.dart';
export 'src/set_use_cases.dart';
export 'src/synergy_use_cases.dart';
export 'src/variant_use_cases.dart';
