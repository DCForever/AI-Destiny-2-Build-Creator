// CLI: compare Next vs Dart inventory fidelity snapshots (DART-054).
//
//   dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json
//   dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json --tolerance 0
//
// Exit 0 only when all compared counts are within tolerance and membership matches.

import 'dart:io';

import 'inventory_fidelity/compare.dart';
import 'inventory_fidelity/snapshot.dart';

void main(List<String> args) {
  exitCode = runInventoryFidelityCompare(args);
}

/// Parse args and run compare. Returns process exit code.
int runInventoryFidelityCompare(List<String> args) {
  String? nextPath;
  String? dartPath;
  var tolerance = 0;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--next' && i + 1 < args.length) {
      nextPath = args[++i];
    } else if (a == '--dart' && i + 1 < args.length) {
      dartPath = args[++i];
    } else if (a == '--tolerance' && i + 1 < args.length) {
      tolerance = int.tryParse(args[++i]) ?? -1;
    } else if (a == '--help' || a == '-h') {
      _printUsage(stdout);
      return 0;
    } else {
      stderr.writeln('Unknown argument: $a');
      _printUsage(stderr);
      return 2;
    }
  }

  if (nextPath == null || dartPath == null) {
    stderr.writeln('Required: --next <path> and --dart <path>');
    _printUsage(stderr);
    return 2;
  }
  if (tolerance < 0) {
    stderr.writeln('--tolerance must be a non-negative integer');
    return 2;
  }

  final nextFile = File(nextPath);
  final dartFile = File(dartPath);
  if (!nextFile.existsSync()) {
    stderr.writeln('Next snapshot not found: $nextPath');
    return 2;
  }
  if (!dartFile.existsSync()) {
    stderr.writeln('Dart snapshot not found: $dartPath');
    return 2;
  }

  try {
    final next = InventoryFidelitySnapshot.parse(nextFile.readAsStringSync());
    final dart = InventoryFidelitySnapshot.parse(dartFile.readAsStringSync());
    final result = compareInventoryFidelity(
      next: next,
      dart: dart,
      tolerance: tolerance,
    );
    stdout.writeln(result.report());
    return result.ok ? 0 : 1;
  } on FormatException catch (e) {
    stderr.writeln('Parse error: $e');
    return 2;
  } catch (e) {
    stderr.writeln('Compare failed: $e');
    return 2;
  }
}

void _printUsage(IOSink sink) {
  sink.writeln(
    'Usage: dart run tool/inventory_fidelity_compare.dart '
    '--next <next.json> --dart <dart.json> [--tolerance N]',
  );
  sink.writeln(
    'Compares inventory count snapshots (byLocation/byBucket/raw/resolution).',
  );
  sink.writeln('Exit 0 = pass, 1 = count/membership fail, 2 = usage/parse error.');
}
