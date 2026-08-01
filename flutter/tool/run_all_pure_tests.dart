// Run dart test for every pure package (DART-011 aggregate suite).
//
// Usage (from workspace root):
//   dart run tool/run_all_pure_tests.dart
//
// Exit 0 only if every package suite exits 0.

import 'dart:io';

import 'pure_package_graph_guard.dart' show findWorkspaceRoot;
import 'pure_packages.dart';

/// Run `dart test` in each pure package directory.
/// Returns 0 if all succeed, else the first non-zero exit (or 1).
Future<int> runAllPureTests({Directory? workspaceRoot}) async {
  final root = workspaceRoot ?? findWorkspaceRoot();
  var overall = 0;

  for (final rel in purePackageDirs) {
    final packageDir = Directory.fromUri(root.uri.resolve(rel));
    if (!packageDir.existsSync()) {
      stderr.writeln('FAIL: pure package directory missing: ${packageDir.path}');
      return 1;
    }

    stdout.writeln('');
    stdout.writeln('=== dart test $rel ===');
    final result = await Process.run(
      'dart',
      ['test'],
      workingDirectory: packageDir.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    final code = result.exitCode;
    if (code != 0) {
      stderr.writeln('FAIL: dart test exited $code in $rel');
      overall = code == 0 ? 1 : code;
    } else {
      stdout.writeln('OK: $rel');
    }
  }

  return overall;
}

Future<void> main(List<String> args) async {
  exitCode = await runAllPureTests();
}
