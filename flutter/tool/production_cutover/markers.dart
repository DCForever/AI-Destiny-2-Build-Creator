// Production cutover re-gate markers (DART-061 / GAP-CUT-01 / RC-BRANCH).
// Shared by gate CLI and unit tests.

/// Relative path from workspace root to the canonical cutover checklist.
const String kCutoverChecklistRelativePath =
    'docs/multiplatform-dart-cutover-parity-checklist.md';

/// Relative path to branching / merge policy doc.
const String kBranchingDocRelativePath =
    'docs/multiplatform-dart-branching.md';

/// Relative path to feature gaps catalog.
const String kFeatureGapsRelativePath =
    'docs/multiplatform-dart-feature-gaps.md';

/// Dual-gate verdict lines required for production cutover GO.
const List<String> kCutoverVerdictRequiredMarkers = [
  'PROGRAM_GATE: GO',
  'PRODUCTION_CUTOVER: GO',
];

/// Every RC-* must appear with PASS evidence in the checklist.
const List<String> kRetirementCriteria = [
  'RC-NAV',
  'RC-DOMAIN',
  'RC-COMPOSE',
  'RC-EQUIP',
  'RC-AUTH',
  'RC-SYNC',
  'RC-DATA',
  'RC-WEB-DATA',
  'RC-SECRETS',
  'RC-SOFT',
  'RC-OPS',
  'RC-BRANCH',
];

/// Additional checklist markers for formal GO / branch policy / non-goals.
const List<String> kCutoverGoEvidenceMarkers = [
  'PRODUCTION_CUTOVER_GO',
  'RC-BRANCH',
  'merge',
  'feature/multiplatform-dart',
  'GAP-FEAT-02',
  'jsonOnly',
  'soft never auto-applies',
  'CLIENT_SECRET',
  'DART-061',
  'GAP-CUT-01',
];

/// Branching doc must document merge-only-after-GO (RC-BRANCH).
const List<String> kBranchingPolicyRequiredMarkers = [
  'RC-BRANCH',
  'PRODUCTION_CUTOVER',
  'GO',
  'feature/multiplatform-dart',
  'main',
  'PRODUCTION_CUTOVER_GO',
];

/// Feature-gaps markers: GAP-CUT-01 closed; GAP-FEAT-02 remains non-goal.
const List<String> kFeatureGapsCutoverMarkers = [
  'GAP-CUT-01',
  'GAP-FEAT-02',
  'DART-061',
  'dim.gg',
  'jsonOnly',
];
