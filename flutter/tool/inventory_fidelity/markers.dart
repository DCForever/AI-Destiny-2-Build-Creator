// Required markers in the dual-run procedure doc (DART-054 inventory fidelity gate).

/// Relative path from workspace root to the harness procedure doc.
const String kInventoryHarnessDocRelativePath =
    'docs/multiplatform-dart-inventory-live-parity-harness.md';

/// Relative paths to matching fixture pair used by the offline gate.
const String kNextMatchFixtureRelativePath =
    'tool/fixtures/inventory_fidelity/next_match.json';
const String kDartMatchFixtureRelativePath =
    'tool/fixtures/inventory_fidelity/dart_match.json';

/// Substrings that must appear in the harness procedure doc.
const List<String> kInventoryHarnessRequiredMarkers = [
  'DUAL_RUN_PROCEDURE',
  'INVENTORY_FIDELITY_SNAPSHOT',
  'INVENTORY_FIDELITY_GATE',
  'p0_parity_gate',
  'byLocation',
  'byBucket',
  'resolvedFromTransfer',
  'storedTotal',
  'tolerance',
  'inventory_fidelity_compare',
  'inventory_fidelity_gate',
  'PROC-05',
  'GAP-INV-05',
];
