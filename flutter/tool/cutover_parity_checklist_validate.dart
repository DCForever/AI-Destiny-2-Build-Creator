// Structural validator for DART-049 cutover parity checklist (P5 program gate).
//
//   dart run tool/cutover_parity_checklist_validate.dart
//
// Exit 0 only when docs/multiplatform-dart-cutover-parity-checklist.md contains
// required headings, dual-gate markers, AppShell nav keys, and RC-* criteria.

import 'dart:io';

/// Relative path from workspace root to the canonical checklist.
const String kCutoverChecklistRelativePath =
    'docs/multiplatform-dart-cutover-parity-checklist.md';

/// Required substrings that must appear in the checklist body.
const List<String> kRequiredMarkers = [
  'PROGRAM_GATE:',
  'PRODUCTION_CUTOVER:',
  '## Product production nav parity',
  '## Capability parity',
  '## Next retirement criteria',
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
  // AppShell production nav keys
  'loadouts',
  'build',
  'synergy',
  'sets',
  'catalog',
  'settings',
];

/// Verdict markers must each be followed by GO or NO-GO on the same line.
final RegExp kProgramGateLine = RegExp(
  r'PROGRAM_GATE:\s*(GO|NO-GO)\b',
);
final RegExp kProductionCutoverLine = RegExp(
  r'PRODUCTION_CUTOVER:\s*(GO|NO-GO)\b',
);

/// Finds workspace root by walking up from [start] until the checklist path exists.
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/$kCutoverChecklistRelativePath');
    if (candidate.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

/// Returns missing required markers (empty = pass structure).
List<String> missingRequiredMarkers(String content) {
  final missing = <String>[];
  for (final marker in kRequiredMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Validates dual-gate verdict line shapes. Returns error messages (empty = ok).
List<String> validateVerdictLines(String content) {
  final errors = <String>[];
  if (!kProgramGateLine.hasMatch(content)) {
    errors.add(
      'PROGRAM_GATE must appear as "PROGRAM_GATE: GO" or "PROGRAM_GATE: NO-GO"',
    );
  }
  if (!kProductionCutoverLine.hasMatch(content)) {
    errors.add(
      'PRODUCTION_CUTOVER must appear as "PRODUCTION_CUTOVER: GO" or '
      '"PRODUCTION_CUTOVER: NO-GO"',
    );
  }
  return errors;
}

/// Full validation result for tests / CLI.
class CutoverChecklistValidation {
  CutoverChecklistValidation({
    required this.filePath,
    required this.exists,
    required this.missingMarkers,
    required this.verdictErrors,
  });

  final String filePath;
  final bool exists;
  final List<String> missingMarkers;
  final List<String> verdictErrors;

  bool get ok =>
      exists && missingMarkers.isEmpty && verdictErrors.isEmpty;

  List<String> get allErrors {
    final out = <String>[];
    if (!exists) {
      out.add('Missing checklist file: $filePath');
    }
    for (final m in missingMarkers) {
      out.add('Missing required marker: $m');
    }
    out.addAll(verdictErrors);
    return out;
  }
}

/// Validate checklist at [workspaceRoot].
CutoverChecklistValidation validateCutoverChecklist({
  Directory? workspaceRoot,
}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final file = File('${root.path}/$kCutoverChecklistRelativePath');
  if (!file.existsSync()) {
    return CutoverChecklistValidation(
      filePath: file.path,
      exists: false,
      missingMarkers: List<String>.from(kRequiredMarkers),
      verdictErrors: const [],
    );
  }
  final content = file.readAsStringSync();
  return CutoverChecklistValidation(
    filePath: file.path,
    exists: true,
    missingMarkers: missingRequiredMarkers(content),
    verdictErrors: validateVerdictLines(content),
  );
}

/// CLI entry: exit 0 on success.
int runCutoverChecklistValidate({Directory? workspaceRoot}) {
  final result = validateCutoverChecklist(workspaceRoot: workspaceRoot);
  if (result.ok) {
    stdout.writeln('Cutover parity checklist OK: ${result.filePath}');
    return 0;
  }
  stderr.writeln('Cutover parity checklist FAILED: ${result.filePath}');
  for (final e in result.allErrors) {
    stderr.writeln('  - $e');
  }
  return 1;
}

void main(List<String> args) {
  exitCode = runCutoverChecklistValidate();
}
