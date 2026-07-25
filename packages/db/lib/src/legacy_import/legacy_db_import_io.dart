import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../app_database.dart';
import '../schema_notes.dart';

/// Core tables used for product-shape detection and row-count reporting.
const List<String> legacyImportCountTables = [
  'users',
  'inventory_items',
  'inventory_sync_meta',
  'loadouts',
  'sets',
  'set_items',
  'synergies',
  'synergy_links',
  'builds',
  'build_variants',
  'build_synergy_types',
  'variant_set_attachments',
];

/// Tables that indicate a product (Next/Drift) library DB when present with [users].
const List<String> legacyImportContentTables = [
  'builds',
  'sets',
  'synergies',
  'inventory_items',
];

/// Dry-run plan for a legacy → StorageRoot import.
class LegacyDbImportPlan {
  const LegacyDbImportPlan({
    required this.sourcePath,
    required this.targetPath,
    required this.sourceExists,
    required this.sourceSizeBytes,
    required this.sourceTablesPresent,
    required this.sourceTableCounts,
    required this.missingCoreTables,
    required this.targetExists,
    required this.targetSizeBytes,
    required this.warnings,
    required this.errors,
    required this.canApply,
    this.sourceEqualsTarget = false,
  });

  final String sourcePath;
  final String targetPath;
  final bool sourceExists;
  final int? sourceSizeBytes;
  final List<String> sourceTablesPresent;
  final Map<String, int> sourceTableCounts;
  final List<String> missingCoreTables;
  final bool targetExists;
  final int? targetSizeBytes;
  final List<String> warnings;
  final List<String> errors;
  final bool canApply;
  final bool sourceEqualsTarget;

  /// Human-readable multi-line summary for CLI / Settings.
  String get summaryText {
    final buf = StringBuffer()
      ..writeln('Source: $sourcePath')
      ..writeln('Target: $targetPath')
      ..writeln('canApply: $canApply');
    if (sourceSizeBytes != null) {
      buf.writeln('Source size: $sourceSizeBytes bytes');
    }
    if (targetExists) {
      buf.writeln('Target exists: yes (${targetSizeBytes ?? '?'} bytes)');
    } else {
      buf.writeln('Target exists: no');
    }
    if (sourceTableCounts.isNotEmpty) {
      buf.writeln('Row counts:');
      for (final e in sourceTableCounts.entries) {
        buf.writeln('  ${e.key}: ${e.value}');
      }
    }
    if (missingCoreTables.isNotEmpty) {
      buf.writeln('Missing core tables: ${missingCoreTables.join(', ')}');
    }
    for (final w in warnings) {
      buf.writeln('WARN: $w');
    }
    for (final e in errors) {
      buf.writeln('ERROR: $e');
    }
    return buf.toString().trimRight();
  }
}

/// Result of a successful [LegacyDbImporter.apply].
class LegacyDbImportResult {
  const LegacyDbImportResult({
    required this.sourcePath,
    required this.targetPath,
    required this.backupPath,
    required this.tableCountsAfter,
    required this.appliedAtIso,
  });

  final String sourcePath;
  final String targetPath;
  final String? backupPath;
  final Map<String, int> tableCountsAfter;
  final String appliedAtIso;
}

/// Error thrown when [LegacyDbImporter.apply] is refused.
class LegacyDbImportException implements Exception {
  LegacyDbImportException(this.message, {this.errors = const []});

  final String message;
  final List<String> errors;

  @override
  String toString() {
    if (errors.isEmpty) return 'LegacyDbImportException: $message';
    return 'LegacyDbImportException: $message\n${errors.map((e) => '  - $e').join('\n')}';
  }
}

/// Pure-Dart importer: Next `.cache/app.db` → platform StorageRoot `app.db`.
///
/// **Dry-run** opens source read-only, validates product shape, reports counts.
/// **Apply** backups target (if any), copies source → target, opens with
/// [AppDatabase.file] so DART-014 ensure* upgrades heal schema, then closes.
///
/// Import mode is **full replace** (not merge). Hosts should restart after apply
/// so a single lifetime DB connection rebinds to the new file.
class LegacyDbImporter {
  const LegacyDbImporter();

  /// Inspect [sourcePath] without writing [targetPath].
  Future<LegacyDbImportPlan> dryRun({
    required String sourcePath,
    required String targetPath,
  }) async {
    final source = p.normalize(sourcePath.trim());
    final target = p.normalize(targetPath.trim());
    final warnings = <String>[];
    final errors = <String>[];

    if (source.isEmpty) {
      errors.add('Source path is empty');
    }
    if (target.isEmpty) {
      errors.add('Target path is empty');
    }

    final sourceFile = File(source);
    final targetFile = File(target);
    final sourceExists = source.isNotEmpty && sourceFile.existsSync();
    final targetExists = target.isNotEmpty && targetFile.existsSync();
    int? sourceSize;
    int? targetSize;
    if (sourceExists) {
      sourceSize = sourceFile.lengthSync();
    }
    if (targetExists) {
      targetSize = targetFile.lengthSync();
    }

    final samePath = source.isNotEmpty &&
        target.isNotEmpty &&
        p.equals(source, target);

    if (!sourceExists && source.isNotEmpty) {
      errors.add('Source file does not exist: $source');
    }

    var tablesPresent = <String>[];
    var counts = <String, int>{};
    var missingCore = <String>[];

    if (sourceExists && errors.isEmpty) {
      try {
        final inspected = _inspectSource(source);
        tablesPresent = inspected.tables;
        counts = inspected.counts;
        missingCore = expectedCoreTables
            .where((t) => !tablesPresent.contains(t))
            .toList();

        if (!tablesPresent.contains('users')) {
          errors.add('Source is missing required table: users');
        }
        final hasContent = legacyImportContentTables
            .any((t) => tablesPresent.contains(t));
        if (!hasContent) {
          errors.add(
            'Source has no product content tables '
            '(need one of: ${legacyImportContentTables.join(', ')})',
          );
        }
        if (missingCore.isNotEmpty) {
          warnings.add(
            'Source is missing some core tables (ensure* / create may not '
            'add them on open): ${missingCore.join(', ')}',
          );
        }
        if (targetExists) {
          warnings.add(
            'Target already exists and will be replaced on apply '
            '(backup will be written first)',
          );
        }
        if (samePath) {
          errors.add(
            'Source and target paths are the same; refuse apply to avoid '
            'self-overwrite',
          );
        }
      } on SqliteException catch (e) {
        errors.add('Source is not a readable SQLite database: ${e.message}');
      } catch (e) {
        errors.add('Failed to inspect source: $e');
      }
    }

    final canApply = errors.isEmpty && sourceExists;

    return LegacyDbImportPlan(
      sourcePath: source,
      targetPath: target,
      sourceExists: sourceExists,
      sourceSizeBytes: sourceSize,
      sourceTablesPresent: tablesPresent,
      sourceTableCounts: counts,
      missingCoreTables: missingCore,
      targetExists: targetExists,
      targetSizeBytes: targetSize,
      warnings: warnings,
      errors: errors,
      canApply: canApply,
      sourceEqualsTarget: samePath,
    );
  }

  /// Apply import after validation. Refuses when dry-run would set canApply false.
  ///
  /// [priorPlan] is re-validated; if null, dry-run runs first.
  Future<LegacyDbImportResult> apply({
    required String sourcePath,
    required String targetPath,
    LegacyDbImportPlan? priorPlan,
  }) async {
    final plan = priorPlan ??
        await dryRun(sourcePath: sourcePath, targetPath: targetPath);
    // Always re-check current disk state (plan may be stale).
    final fresh = await dryRun(
      sourcePath: plan.sourcePath,
      targetPath: plan.targetPath,
    );
    if (!fresh.canApply) {
      throw LegacyDbImportException(
        'Apply refused: dry-run failed',
        errors: fresh.errors,
      );
    }

    final source = File(fresh.sourcePath);
    final target = File(fresh.targetPath);
    final parent = target.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    String? backupPath;
    final appliedAt = DateTime.now().toUtc();
    final stamp = _backupStamp(appliedAt);

    if (target.existsSync()) {
      backupPath = '${target.path}.bak-$stamp';
      target.copySync(backupPath);
    }

    // Copy to a temp sibling then rename for slightly safer replace.
    final staging = File('${target.path}.import-staging-$stamp');
    try {
      source.copySync(staging.path);
      if (target.existsSync()) {
        target.deleteSync();
      }
      staging.renameSync(target.path);
    } catch (e) {
      if (staging.existsSync()) {
        try {
          staging.deleteSync();
        } catch (_) {}
      }
      throw LegacyDbImportException('Failed to write target: $e');
    }

    // Open with Drift so ensure* upgrades heal late columns, then close.
    final db = AppDatabase.file(target.path);
    try {
      await db.customSelect('SELECT 1').get();
      final counts = await _countTables(db);
      return LegacyDbImportResult(
        sourcePath: fresh.sourcePath,
        targetPath: fresh.targetPath,
        backupPath: backupPath,
        tableCountsAfter: counts,
        appliedAtIso: appliedAt.toIso8601String(),
      );
    } finally {
      await db.close();
    }
  }

  _Inspected _inspectSource(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final tableRows = db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      final tables = tableRows.map((r) => r['name'] as String).toList();
      final counts = <String, int>{};
      for (final name in legacyImportCountTables) {
        if (!tables.contains(name)) continue;
        final row = db.select('SELECT COUNT(*) AS c FROM $name').first;
        counts[name] = row['c'] as int;
      }
      return _Inspected(tables: tables, counts: counts);
    } finally {
      db.dispose();
    }
  }

  Future<Map<String, int>> _countTables(AppDatabase db) async {
    final present = await db.listUserTableNames();
    final counts = <String, int>{};
    for (final name in legacyImportCountTables) {
      if (!present.contains(name)) continue;
      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM $name', readsFrom: {})
          .getSingle();
      counts[name] = row.read<int>('c');
    }
    return counts;
  }

  String _backupStamp(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }
}

class _Inspected {
  _Inspected({required this.tables, required this.counts});
  final List<String> tables;
  final Map<String, int> counts;
}
