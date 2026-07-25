// Dual-run + rollback ops gate (DART-060 / GAP-OPS-01 / RB-04 / RC-OPS).
//
// Offline operator/CI gate:
//   dart run tool/dual_run_ops_gate.dart
//
// Exit 0 only when:
//   1) dual-run runbook exists with required markers (incl. EXECUTED_ONCE)
//   2) Next + Windows host + web host trees are present (structural dual-run availability)
//   3) cutover checklist references the runbook / RC-OPS dual-run evidence

import 'dart:io';

import 'dual_run_ops/markers.dart';

/// Finds workspace root by walking up until the runbook path exists (or max hops).
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 10; i++) {
    final candidate = File('${dir.path}/$kDualRunRunbookRelativePath');
    if (candidate.existsSync()) {
      return dir;
    }
    // Fallback: packages/bungie exists at monorepo root even before runbook.
    final bungie = Directory('${dir.path}/packages/bungie');
    if (bungie.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

/// Missing required markers in runbook content (empty = ok).
List<String> missingRunbookMarkers(String content) {
  final missing = <String>[];
  for (final marker in kDualRunRunbookRequiredMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Shell relative paths that do not exist under [root].
List<String> missingShellPaths(Directory root) {
  final missing = <String>[];
  for (final rel in kDualRunShellRelativePaths) {
    final file = File('${root.path}/$rel');
    final dir = Directory('${root.path}/$rel');
    if (!file.existsSync() && !dir.existsSync()) {
      missing.add(rel);
    }
  }
  return missing;
}

/// Missing cutover evidence markers (empty = ok).
List<String> missingCutoverOpsMarkers(String content) {
  final missing = <String>[];
  for (final marker in kCutoverOpsEvidenceMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Full gate validation result for tests / CLI.
class DualRunOpsGateResult {
  DualRunOpsGateResult({
    required this.workspaceRoot,
    required this.runbookPath,
    required this.runbookExists,
    required this.missingMarkers,
    required this.missingShells,
    required this.cutoverPath,
    required this.cutoverExists,
    required this.missingCutoverMarkers,
    required this.errors,
  });

  final String workspaceRoot;
  final String runbookPath;
  final bool runbookExists;
  final List<String> missingMarkers;
  final List<String> missingShells;
  final String cutoverPath;
  final bool cutoverExists;
  final List<String> missingCutoverMarkers;
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Run offline dual-run ops gate against [workspaceRoot].
DualRunOpsGateResult validateDualRunOpsGate({Directory? workspaceRoot}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final errors = <String>[];

  final runbookPath = '${root.path}/$kDualRunRunbookRelativePath';
  final runbookFile = File(runbookPath);
  final runbookExists = runbookFile.existsSync();
  var missingMarkers = <String>[];
  if (!runbookExists) {
    errors.add('Missing dual-run runbook: $runbookPath');
  } else {
    missingMarkers = missingRunbookMarkers(runbookFile.readAsStringSync());
    for (final m in missingMarkers) {
      errors.add('Missing required runbook marker: $m');
    }
  }

  final missingShells = missingShellPaths(root);
  for (final s in missingShells) {
    errors.add('Missing dual-run shell path: $s');
  }

  final cutoverPath = '${root.path}/$kCutoverChecklistRelativePath';
  final cutoverFile = File(cutoverPath);
  final cutoverExists = cutoverFile.existsSync();
  var missingCutover = <String>[];
  if (!cutoverExists) {
    errors.add('Missing cutover checklist: $cutoverPath');
  } else {
    missingCutover = missingCutoverOpsMarkers(cutoverFile.readAsStringSync());
    for (final m in missingCutover) {
      errors.add('Missing cutover ops evidence marker: $m');
    }
  }

  return DualRunOpsGateResult(
    workspaceRoot: root.path,
    runbookPath: runbookPath,
    runbookExists: runbookExists,
    missingMarkers: missingMarkers,
    missingShells: missingShells,
    cutoverPath: cutoverPath,
    cutoverExists: cutoverExists,
    missingCutoverMarkers: missingCutover,
    errors: errors,
  );
}

/// CLI entry: exit 0 on success.
int runDualRunOpsGate({Directory? workspaceRoot}) {
  final result = validateDualRunOpsGate(workspaceRoot: workspaceRoot);
  if (result.ok) {
    stdout.writeln('Dual-run ops gate OK: ${result.runbookPath}');
    stdout.writeln('  shells: ${kDualRunShellRelativePaths.join(', ')}');
    stdout.writeln('  cutover: ${result.cutoverPath}');
    return 0;
  }
  stderr.writeln('Dual-run ops gate FAILED:');
  for (final e in result.errors) {
    stderr.writeln('  - $e');
  }
  return 1;
}

void main(List<String> args) {
  exit(runDualRunOpsGate());
}
