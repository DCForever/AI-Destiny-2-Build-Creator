// PROC-06 intentional thinning process gate (pkg-ledger-process-hygiene).
//
// Offline operator/CI gate:
//   dart run tool/proc06_thinning_gate.dart
//
// Exit 0 only when:
//   1) finish-spec thinning checklist doc exists with required markers
//   2) finish-spec skill references PROC-06 / thinning checklist
//   3) feature-gaps process table marks PROC-06 closed with gate evidence

import 'dart:io';

/// Relative path of the thinning checklist SSoT.
const kProc06ChecklistRelativePath = 'docs/finish-spec-thinning-checklist.md';

/// Relative path of feature gap ledger.
const kFeatureGapsRelativePath = 'docs/multiplatform-dart-feature-gaps.md';

/// Relative path of finish-spec skill.
const kFinishSpecSkillRelativePath = '.cursor/skills/finish-spec/SKILL.md';

/// Markers that must appear in the thinning checklist doc.
const kProc06ChecklistMarkers = <String>[
  'PROC-06-THINNING-CHECKLIST',
  'INTENTIONAL-THINNING-SAME-CHANGE',
  'GAP-RESIDUAL-REQUIRED',
  'SOFT-NEVER-AUTO-APPLIES',
  'NO-SILENT-MVP-OK',
];

/// Markers that must appear in finish-spec skill.
const kProc06SkillMarkers = <String>[
  'PROC-06',
  'finish-spec-thinning-checklist',
];

/// Markers that must appear in feature-gaps for closed PROC-06.
const kProc06FeatureGapsMarkers = <String>[
  'PROC-06',
  'closed',
  'proc06_thinning_gate',
];

/// Finds workspace root by walking up until checklist path exists.
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/$kProc06ChecklistRelativePath');
    if (candidate.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

List<String> missingMarkers(String content, List<String> required) {
  final missing = <String>[];
  for (final marker in required) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Full gate validation result for tests / CLI.
class Proc06ThinningGateResult {
  Proc06ThinningGateResult({
    required this.workspaceRoot,
    required this.checklistPath,
    required this.checklistExists,
    required this.missingChecklistMarkers,
    required this.skillPath,
    required this.skillExists,
    required this.missingSkillMarkers,
    required this.featureGapsPath,
    required this.featureGapsExists,
    required this.missingFeatureGapsMarkers,
    required this.errors,
  });

  final String workspaceRoot;
  final String checklistPath;
  final bool checklistExists;
  final List<String> missingChecklistMarkers;
  final String skillPath;
  final bool skillExists;
  final List<String> missingSkillMarkers;
  final String featureGapsPath;
  final bool featureGapsExists;
  final List<String> missingFeatureGapsMarkers;
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Run offline PROC-06 thinning gate against [workspaceRoot].
Proc06ThinningGateResult validateProc06ThinningGate({
  Directory? workspaceRoot,
}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final errors = <String>[];

  final checklistPath = '${root.path}/$kProc06ChecklistRelativePath';
  final checklistFile = File(checklistPath);
  final checklistExists = checklistFile.existsSync();
  var missingChecklist = <String>[];
  if (!checklistExists) {
    errors.add('Missing checklist: $kProc06ChecklistRelativePath');
  } else {
    missingChecklist = missingMarkers(
      checklistFile.readAsStringSync(),
      kProc06ChecklistMarkers,
    );
    if (missingChecklist.isNotEmpty) {
      errors.add(
        'Checklist missing markers: ${missingChecklist.join(', ')}',
      );
    }
  }

  final skillPath = '${root.path}/$kFinishSpecSkillRelativePath';
  final skillFile = File(skillPath);
  final skillExists = skillFile.existsSync();
  var missingSkill = <String>[];
  if (!skillExists) {
    errors.add('Missing finish-spec skill: $kFinishSpecSkillRelativePath');
  } else {
    missingSkill = missingMarkers(
      skillFile.readAsStringSync(),
      kProc06SkillMarkers,
    );
    if (missingSkill.isNotEmpty) {
      errors.add(
        'finish-spec skill missing markers: ${missingSkill.join(', ')}',
      );
    }
  }

  final gapsPath = '${root.path}/$kFeatureGapsRelativePath';
  final gapsFile = File(gapsPath);
  final gapsExists = gapsFile.existsSync();
  var missingGaps = <String>[];
  if (!gapsExists) {
    errors.add('Missing feature gaps: $kFeatureGapsRelativePath');
  } else {
    final gapsText = gapsFile.readAsStringSync();
    missingGaps = missingMarkers(gapsText, kProc06FeatureGapsMarkers);
    if (missingGaps.isNotEmpty) {
      errors.add(
        'feature-gaps PROC-06 closed language missing: ${missingGaps.join(', ')}',
      );
    }
    // Require explicit closed status near PROC-06 table row.
    final procRow = RegExp(
      r'\*\*PROC-06\*\*[^\n]*`closed`',
      multiLine: true,
    );
    if (!procRow.hasMatch(gapsText)) {
      errors.add(
        'feature-gaps must mark **PROC-06** as `closed` in the process table',
      );
    }
  }

  return Proc06ThinningGateResult(
    workspaceRoot: root.path,
    checklistPath: checklistPath,
    checklistExists: checklistExists,
    missingChecklistMarkers: missingChecklist,
    skillPath: skillPath,
    skillExists: skillExists,
    missingSkillMarkers: missingSkill,
    featureGapsPath: gapsPath,
    featureGapsExists: gapsExists,
    missingFeatureGapsMarkers: missingGaps,
    errors: errors,
  );
}

/// CLI entry: print result and return exit code.
int runProc06ThinningGate() {
  final result = validateProc06ThinningGate();
  if (result.ok) {
    stdout.writeln('PROC-06 thinning gate PASS');
    stdout.writeln('  checklist: ${result.checklistPath}');
    stdout.writeln('  skill: ${result.skillPath}');
    stdout.writeln('  feature-gaps: ${result.featureGapsPath}');
    return 0;
  }
  stderr.writeln('PROC-06 thinning gate FAIL');
  for (final e in result.errors) {
    stderr.writeln('  - $e');
  }
  return 1;
}

void main(List<String> args) {
  exit(runProc06ThinningGate());
}
