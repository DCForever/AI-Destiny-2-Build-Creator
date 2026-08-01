// Dual-run ops markers (DART-060 / GAP-OPS-01 / RB-04 / RC-OPS).
// Shared by gate CLI and unit tests.

/// Relative path from workspace root to the dual-run runbook.
const String kDualRunRunbookRelativePath =
    'docs/multiplatform-dart-dual-run-rollback-runbook.md';

/// Relative path to cutover checklist (cross-check RC-OPS evidence).
const String kCutoverChecklistRelativePath =
    'docs/multiplatform-dart-cutover-parity-checklist.md';

/// Required substrings in the dual-run runbook body.
const List<String> kDualRunRunbookRequiredMarkers = [
  'DUAL_RUN_RUNBOOK',
  'ROLLBACK_PROCEDURE',
  'EXECUTION_NOTES',
  'EXECUTED_ONCE',
  'COMPOSE_EQUIP_REVERIFY',
  'equip-ready',
  'Bungie equip partial',
  'DIM jsonOnly',
  'keep Next sole production',
  'soft never auto-applies',
  'CLIENT_SECRET',
  'RC-OPS',
  'RB-04',
  'PRODUCTION_CUTOVER',
  'NO-GO',
];

/// Paths that must exist for dual-run shell availability (structural).
/// Relative to monorepo root (not nested Dart workspace root).
const List<String> kDualRunShellRelativePaths = [
  // Next sole production tree
  'package.json',
  'src/app',
  // Dart cutover-primary hosts (DART-069: under flutter/)
  'flutter/apps/windows_host',
  'flutter/apps/web_host',
];

/// Markers expected in cutover checklist after DART-060 (RC-OPS PASS).
const List<String> kCutoverOpsEvidenceMarkers = [
  'RC-OPS',
  'dual-run',
  'multiplatform-dart-dual-run-rollback-runbook',
];
