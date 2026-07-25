// P0 phase gate (DART-011): pure package graph guard + full pure test suite.
//
// Single command for CI / local proof that pure domain is trustworthy before P1:
//   dart run tool/p0_parity_gate.dart
//
// Exit 0 only when both steps succeed.

import 'dart:io';

import 'pure_package_graph_guard.dart';
import 'run_all_pure_tests.dart';

Future<void> main(List<String> args) async {
  final root = findWorkspaceRoot();
  stdout.writeln('P0 parity gate (DART-011)');
  stdout.writeln('Workspace: ${root.path}');
  stdout.writeln('');

  stdout.writeln('--- Step 1/2: pure package graph guard ---');
  final guardCode = runGraphGuard(workspaceRoot: root);
  if (guardCode != 0) {
    stderr.writeln('');
    stderr.writeln('P0 gate FAILED: graph guard.');
    exitCode = guardCode;
    return;
  }

  stdout.writeln('');
  stdout.writeln('--- Step 2/2: full pure test suite ---');
  final testCode = await runAllPureTests(workspaceRoot: root);
  if (testCode != 0) {
    stderr.writeln('');
    stderr.writeln('P0 gate FAILED: pure test suite.');
    exitCode = testCode;
    return;
  }

  stdout.writeln('');
  stdout.writeln(
    'P0 gate PASSED: pure packages clean + full pure suite green.',
  );
  stdout.writeln('P1 (DART-012 storage-root / Drift) may proceed.');
  exitCode = 0;
}
