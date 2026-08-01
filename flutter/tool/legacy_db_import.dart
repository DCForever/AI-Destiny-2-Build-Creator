// CLI: dry-run / apply Next .cache/app.db → StorageRoot app.db (DART-048).
//
// Usage:
//   dart run tool/legacy_db_import.dart --source <path> --target <path>
//   dart run tool/legacy_db_import.dart --source <path> --target <path> --apply
//
// Docs: docs/multiplatform-dart-legacy-db-import.md

import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';

void _usage() {
  stderr.writeln(
    'Usage: dart run tool/legacy_db_import.dart '
    '--source <legacy app.db> --target <StorageRoot app.db> [--apply]',
  );
}

Future<void> main(List<String> args) async {
  String? source;
  String? target;
  var apply = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--source' && i + 1 < args.length) {
      source = args[++i];
    } else if (a == '--target' && i + 1 < args.length) {
      target = args[++i];
    } else if (a == '--apply') {
      apply = true;
    } else if (a == '--help' || a == '-h') {
      _usage();
      exit(0);
    } else {
      stderr.writeln('Unknown arg: $a');
      _usage();
      exit(2);
    }
  }

  if (source == null || target == null) {
    _usage();
    exit(2);
  }

  const importer = LegacyDbImporter();
  final plan = await importer.dryRun(sourcePath: source, targetPath: target);
  stdout.writeln(plan.summaryText);

  if (!apply) {
    exit(plan.canApply ? 0 : 1);
  }

  if (!plan.canApply) {
    stderr.writeln('Apply refused: dry-run failed.');
    exit(1);
  }

  try {
    final result = await importer.apply(
      sourcePath: plan.sourcePath,
      targetPath: plan.targetPath,
      priorPlan: plan,
    );
    stdout.writeln('Applied: ${result.targetPath}');
    if (result.backupPath != null) {
      stdout.writeln('Backup: ${result.backupPath}');
    }
    stdout.writeln('Counts after: ${result.tableCountsAfter}');
    stdout.writeln('Restart the multiplatform host to use the imported DB.');
    exit(0);
  } on LegacyDbImportException catch (e) {
    stderr.writeln(e);
    exit(1);
  }
}
