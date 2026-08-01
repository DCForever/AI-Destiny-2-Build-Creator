// Production cutover re-gate (DART-061 / GAP-CUT-01 / RC-BRANCH).
//
// Offline operator/CI gate:
//   dart run tool/production_cutover_regate.dart
//
// Exit 0 only when:
//   1) cutover checklist has PROGRAM_GATE: GO and PRODUCTION_CUTOVER: GO
//   2) every RC-* appears with PASS status (no FAIL on RC lines)
//   3) GO evidence markers + non-goal residual (GAP-FEAT-02 / jsonOnly)
//   4) branching.md has merge-after-GO policy markers (RC-BRANCH)
//   5) feature-gaps.md closes GAP-CUT-01 and keeps GAP-FEAT-02 non-goal residual

import 'dart:io';

import 'production_cutover/markers.dart';

/// Finds workspace root by walking up until the cutover checklist exists.
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 10; i++) {
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

/// Missing dual-gate verdict markers (empty = ok).
List<String> missingVerdictMarkers(String content) {
  final missing = <String>[];
  for (final marker in kCutoverVerdictRequiredMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// RC-* criteria that lack a PASS status token near their ID in content.
///
/// Heuristic: for each RC-*, require both the criterion id and the substring
/// `**PASS**` or `| **PASS**` somewhere after a line that starts a table cell
/// for that id. Simpler reliable rule used here: content must contain
/// `**RC-XXX**` (or `RC-XXX`) and must not contain `RC-XXX` ... `FAIL` on the
/// same line when that line is a criteria status row.
List<String> missingRcPassStatuses(String content) {
  final missing = <String>[];
  final lines = content.split('\n');
  for (final rc in kRetirementCriteria) {
    // Prefer status rows in the Next retirement criteria table:
    // | **RC-NAV** | ... | **PASS** ...
    final statusLine = lines.where((l) {
      final hasId = l.contains('**$rc**') ||
          (l.contains(rc) && l.trimLeft().startsWith('|'));
      return hasId && l.contains('|');
    }).toList();

    final hasPass = statusLine.any(
      (l) =>
          l.contains('**PASS**') ||
          l.contains('| PASS') ||
          l.contains(' PASS '),
    );
    final hasFail = statusLine.any(
      (l) =>
          l.contains('**FAIL**') ||
          l.contains('| FAIL') ||
          RegExp(r'\bFAIL\b').hasMatch(l),
    );

    if (!content.contains(rc)) {
      missing.add('$rc (missing entirely)');
    } else if (hasFail) {
      missing.add('$rc (status FAIL)');
    } else if (!hasPass && statusLine.isNotEmpty) {
      // Table rows exist but no PASS token.
      missing.add('$rc (no PASS on status row)');
    } else if (statusLine.isEmpty) {
      // Fall back: require RC id + global PASS mention is insufficient;
      // require at least "**PASS**" somewhere after first occurrence.
      final idx = content.indexOf(rc);
      final tail = content.substring(idx);
      if (!tail.contains('**PASS**') && !tail.contains('PASS')) {
        missing.add('$rc (no PASS evidence)');
      }
    }
  }
  return missing;
}

/// Missing GO evidence markers in checklist (empty = ok).
List<String> missingGoEvidenceMarkers(String content) {
  final missing = <String>[];
  for (final marker in kCutoverGoEvidenceMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Missing branching policy markers (empty = ok).
List<String> missingBranchingMarkers(String content) {
  final missing = <String>[];
  for (final marker in kBranchingPolicyRequiredMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Missing feature-gaps cutover markers (empty = ok).
List<String> missingFeatureGapsMarkers(String content) {
  final missing = <String>[];
  for (final marker in kFeatureGapsCutoverMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  // GAP-CUT-01 must not remain bare `planned` without closed/done language.
  // Accept closed/done near GAP-CUT-01.
  final cutIdx = content.indexOf('GAP-CUT-01');
  if (cutIdx >= 0) {
    final window = content.substring(
      cutIdx,
      (cutIdx + 800).clamp(0, content.length),
    );
    final closed = window.contains('closed') ||
        window.contains('`done`') ||
        window.contains('**done**') ||
        window.contains('done`') ||
        RegExp(r'\bdone\b', caseSensitive: false).hasMatch(window) ||
        window.contains('CLOSED');
    // Also allow master-table style `done` in Status column near id.
    if (!closed) {
      // Search a wider surrounding for status.
      final widerStart = (cutIdx - 200).clamp(0, content.length);
      final wider = content.substring(
        widerStart,
        (cutIdx + 400).clamp(0, content.length),
      );
      final closedWider = wider.contains('closed') ||
          wider.contains('`done`') ||
          wider.contains('**done**') ||
          RegExp(r'\|\s*`?done`?\s*\|', caseSensitive: false).hasMatch(wider) ||
          wider.contains('CLOSED');
      if (!closedWider) {
        missing.add('GAP-CUT-01 closed/done status');
      }
    }
  }
  return missing;
}

/// Full gate validation result for tests / CLI.
class ProductionCutoverRegateResult {
  ProductionCutoverRegateResult({
    required this.workspaceRoot,
    required this.cutoverPath,
    required this.cutoverExists,
    required this.missingVerdict,
    required this.missingRcPass,
    required this.missingGoEvidence,
    required this.branchingPath,
    required this.branchingExists,
    required this.missingBranching,
    required this.gapsPath,
    required this.gapsExist,
    required this.missingGaps,
    required this.errors,
  });

  final String workspaceRoot;
  final String cutoverPath;
  final bool cutoverExists;
  final List<String> missingVerdict;
  final List<String> missingRcPass;
  final List<String> missingGoEvidence;
  final String branchingPath;
  final bool branchingExists;
  final List<String> missingBranching;
  final String gapsPath;
  final bool gapsExist;
  final List<String> missingGaps;
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Run offline production cutover re-gate against [workspaceRoot].
ProductionCutoverRegateResult validateProductionCutoverRegate({
  Directory? workspaceRoot,
}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final errors = <String>[];

  final cutoverPath = '${root.path}/$kCutoverChecklistRelativePath';
  final cutoverFile = File(cutoverPath);
  final cutoverExists = cutoverFile.existsSync();
  var missingVerdict = <String>[];
  var missingRc = <String>[];
  var missingGo = <String>[];
  if (!cutoverExists) {
    errors.add('Missing cutover checklist: $cutoverPath');
  } else {
    final content = cutoverFile.readAsStringSync();
    missingVerdict = missingVerdictMarkers(content);
    for (final m in missingVerdict) {
      errors.add('Missing cutover verdict marker: $m');
    }
    // Explicitly reject NO-GO as the active PRODUCTION_CUTOVER verdict line.
    final noGoLine = RegExp(
      r'PRODUCTION_CUTOVER:\s*NO-GO\b',
    );
    if (noGoLine.hasMatch(content) &&
        !RegExp(r'PRODUCTION_CUTOVER:\s*GO\b').hasMatch(content)) {
      errors.add('PRODUCTION_CUTOVER is still NO-GO');
    }
    // If both appear (historical notes), require an active GO line.
    if (!RegExp(r'PRODUCTION_CUTOVER:\s*GO\b').hasMatch(content)) {
      if (!missingVerdict.contains('PRODUCTION_CUTOVER: GO')) {
        errors.add('PRODUCTION_CUTOVER: GO verdict line missing');
      }
    }
    missingRc = missingRcPassStatuses(content);
    for (final m in missingRc) {
      errors.add('RC status not PASS: $m');
    }
    missingGo = missingGoEvidenceMarkers(content);
    for (final m in missingGo) {
      errors.add('Missing cutover GO evidence marker: $m');
    }
  }

  final branchingPath = '${root.path}/$kBranchingDocRelativePath';
  final branchingFile = File(branchingPath);
  final branchingExists = branchingFile.existsSync();
  var missingBranching = <String>[];
  if (!branchingExists) {
    errors.add('Missing branching doc: $branchingPath');
  } else {
    missingBranching =
        missingBranchingMarkers(branchingFile.readAsStringSync());
    for (final m in missingBranching) {
      errors.add('Missing branching policy marker: $m');
    }
  }

  final gapsPath = '${root.path}/$kFeatureGapsRelativePath';
  final gapsFile = File(gapsPath);
  final gapsExist = gapsFile.existsSync();
  var missingGaps = <String>[];
  if (!gapsExist) {
    errors.add('Missing feature-gaps doc: $gapsPath');
  } else {
    missingGaps = missingFeatureGapsMarkers(gapsFile.readAsStringSync());
    for (final m in missingGaps) {
      errors.add('Missing feature-gaps cutover marker: $m');
    }
  }

  return ProductionCutoverRegateResult(
    workspaceRoot: root.path,
    cutoverPath: cutoverPath,
    cutoverExists: cutoverExists,
    missingVerdict: missingVerdict,
    missingRcPass: missingRc,
    missingGoEvidence: missingGo,
    branchingPath: branchingPath,
    branchingExists: branchingExists,
    missingBranching: missingBranching,
    gapsPath: gapsPath,
    gapsExist: gapsExist,
    missingGaps: missingGaps,
    errors: errors,
  );
}

/// CLI entry: exit 0 on success.
int runProductionCutoverRegate({Directory? workspaceRoot}) {
  final result = validateProductionCutoverRegate(workspaceRoot: workspaceRoot);
  if (result.ok) {
    stdout.writeln('Production cutover re-gate OK: ${result.cutoverPath}');
    stdout.writeln('  PRODUCTION_CUTOVER: GO');
    stdout.writeln('  RC-* PASS: ${kRetirementCriteria.join(', ')}');
    stdout.writeln('  branching: ${result.branchingPath}');
    stdout.writeln('  gaps: ${result.gapsPath}');
    return 0;
  }
  stderr.writeln('Production cutover re-gate FAILED:');
  for (final e in result.errors) {
    stderr.writeln('  - $e');
  }
  return 1;
}

void main(List<String> args) {
  exit(runProductionCutoverRegate());
}
