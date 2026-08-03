// Inventory fidelity gate (DART-054 / GAP-INV-05 / PROC-03 / PROC-05).
//
// Offline operator/CI gate — separate from pure domain p0_parity_gate:
//   dart run tool/inventory_fidelity_gate.dart
//
// Exit 0 only when:
//   1) dual-run procedure doc exists with required markers
//   2) matching fixture pair compares clean at tolerance 0

import 'dart:io';

import 'inventory_fidelity/compare.dart';
import 'inventory_fidelity/markers.dart';
import 'inventory_fidelity/snapshot.dart';

bool _isDartWorkspaceRoot(Directory dir) {
  final pubspec = File.fromUri(dir.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  final text = pubspec.readAsStringSync();
  return text.contains(RegExp(r'^workspace\s*:', multiLine: true)) ||
      text.contains('destiny2_build_creator_workspace');
}

/// Finds the Melos/pub Dart workspace root (`flutter/` after DART-069).
///
/// Fixtures live under `flutter/tool/fixtures/...`. Walking only for the
/// monorepo `docs/` harness path incorrectly treated the git root as the
/// workspace and broke fixture resolution.
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  while (true) {
    if (_isDartWorkspaceRoot(dir)) {
      return dir;
    }
    final nestedFlutter = Directory.fromUri(dir.uri.resolve('flutter/'));
    if (_isDartWorkspaceRoot(nestedFlutter)) {
      return nestedFlutter;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}

/// Harness procedure docs live at the monorepo root (parent of `flutter/`).
Directory docsRootForHarness(Directory dartWorkspace) {
  final parent = dartWorkspace.parent;
  final atParent = File('${parent.path}/$kInventoryHarnessDocRelativePath');
  if (atParent.existsSync()) return parent;
  final atDart = File('${dartWorkspace.path}/$kInventoryHarnessDocRelativePath');
  if (atDart.existsSync()) return dartWorkspace;
  return parent;
}

/// Missing required markers in procedure doc (empty = ok).
List<String> missingHarnessDocMarkers(String content) {
  final missing = <String>[];
  for (final marker in kInventoryHarnessRequiredMarkers) {
    if (!content.contains(marker)) {
      missing.add(marker);
    }
  }
  return missing;
}

/// Full gate validation result for tests / CLI.
class InventoryFidelityGateResult {
  InventoryFidelityGateResult({
    required this.workspaceRoot,
    required this.docPath,
    required this.docExists,
    required this.missingMarkers,
    required this.nextFixturePath,
    required this.dartFixturePath,
    required this.fixturesExist,
    required this.compareResult,
    required this.errors,
  });

  final String workspaceRoot;
  final String docPath;
  final bool docExists;
  final List<String> missingMarkers;
  final String nextFixturePath;
  final String dartFixturePath;
  final bool fixturesExist;
  final InventoryFidelityCompareResult? compareResult;
  final List<String> errors;

  bool get ok => errors.isEmpty && (compareResult?.ok ?? false);
}

/// Run offline inventory fidelity gate against [workspaceRoot].
///
/// When [workspaceRoot] is omitted, the Dart workspace (`flutter/`) is used for
/// fixtures and tool sources; the harness doc is resolved from the monorepo
/// parent (`docs/...`) after DART-069. Explicit [workspaceRoot] keeps both doc
/// and fixtures under that directory (tests / temp roots).
InventoryFidelityGateResult validateInventoryFidelityGate({
  Directory? workspaceRoot,
}) {
  final dartRoot = workspaceRoot ?? findWorkspaceRoot();
  final docsRoot =
      workspaceRoot != null ? dartRoot : docsRootForHarness(dartRoot);
  final errors = <String>[];

  final docPath = '${docsRoot.path}/$kInventoryHarnessDocRelativePath';
  final docFile = File(docPath);
  final docExists = docFile.existsSync();
  var missing = <String>[];
  if (!docExists) {
    errors.add('Missing harness procedure doc: $docPath');
  } else {
    missing = missingHarnessDocMarkers(docFile.readAsStringSync());
    for (final m in missing) {
      errors.add('Missing required harness doc marker: $m');
    }
  }

  final nextPath = '${dartRoot.path}/$kNextMatchFixtureRelativePath';
  final dartPath = '${dartRoot.path}/$kDartMatchFixtureRelativePath';
  final nextFile = File(nextPath);
  final dartFile = File(dartPath);
  final fixturesExist = nextFile.existsSync() && dartFile.existsSync();
  InventoryFidelityCompareResult? compareResult;

  if (!nextFile.existsSync()) {
    errors.add('Missing Next match fixture: $nextPath');
  }
  if (!dartFile.existsSync()) {
    errors.add('Missing Dart match fixture: $dartPath');
  }

  if (fixturesExist) {
    try {
      final next = InventoryFidelitySnapshot.parse(nextFile.readAsStringSync());
      final dart = InventoryFidelitySnapshot.parse(dartFile.readAsStringSync());
      compareResult = compareInventoryFidelity(
        next: next,
        dart: dart,
        tolerance: 0,
      );
      if (!compareResult.ok) {
        errors.add(
          'Fixture compare failed:\n${compareResult.report()}',
        );
      }
    } on FormatException catch (e) {
      errors.add('Fixture parse error: $e');
    } catch (e) {
      errors.add('Fixture compare error: $e');
    }
  }

  return InventoryFidelityGateResult(
    workspaceRoot: dartRoot.path,
    docPath: docPath,
    docExists: docExists,
    missingMarkers: missing,
    nextFixturePath: nextPath,
    dartFixturePath: dartPath,
    fixturesExist: fixturesExist,
    compareResult: compareResult,
    errors: errors,
  );
}

/// CLI entry. Returns exit code.
int runInventoryFidelityGate({Directory? workspaceRoot}) {
  final result = validateInventoryFidelityGate(workspaceRoot: workspaceRoot);
  stdout.writeln('Inventory fidelity gate (DART-054)');
  stdout.writeln('Workspace: ${result.workspaceRoot}');
  stdout.writeln('');
  stdout.writeln(
    'Note: This gate is SEPARATE from pure domain p0_parity_gate (PROC-05).',
  );
  stdout.writeln('p0 green ≠ inventory count sameness vs Next.');
  stdout.writeln('');

  if (result.ok) {
    stdout.writeln('--- Doc markers: OK ---');
    stdout.writeln('--- Fixture compare: PASS (tolerance=0) ---');
    if (result.compareResult?.membershipNote != null) {
      stdout.writeln(result.compareResult!.membershipNote);
    }
    stdout.writeln('');
    stdout.writeln(
      'INVENTORY FIDELITY GATE PASSED: procedure doc + fixture parity OK.',
    );
    return 0;
  }

  stderr.writeln('INVENTORY FIDELITY GATE FAILED:');
  for (final e in result.errors) {
    stderr.writeln('  - $e');
  }
  return 1;
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Usage: dart run tool/inventory_fidelity_gate.dart\n'
      'Offline inventory fidelity gate (doc markers + fixture compare).\n'
      'Separate from dart run tool/p0_parity_gate.dart (PROC-05).',
    );
    exitCode = 0;
    return;
  }
  exitCode = runInventoryFidelityGate();
}
