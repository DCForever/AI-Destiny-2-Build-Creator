/// Web / non-IO stub for legacy DB import (DART-048).
///
/// File-based import from Next `.cache/app.db` is desktop/native only.
/// See `docs/multiplatform-dart-legacy-db-import.md`.
library;

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

  /// Human-readable multi-line summary for CLI / Settings (parity with IO impl).
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

/// Error thrown when [LegacyDbImporter.apply] is refused (parity with IO impl).
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

/// Legacy Next.js SQLite → platform StorageRoot importer (unsupported on web).
class LegacyDbImporter {
  const LegacyDbImporter();

  /// Dry-run is not available on web.
  Future<LegacyDbImportPlan> dryRun({
    required String sourcePath,
    required String targetPath,
  }) async {
    throw UnsupportedError(
      'LegacyDbImporter.dryRun requires dart:io (desktop/native). '
      'Import Next .cache/app.db on Flutter Windows — see '
      'docs/multiplatform-dart-legacy-db-import.md',
    );
  }

  /// Apply is not available on web.
  Future<LegacyDbImportResult> apply({
    required String sourcePath,
    required String targetPath,
    LegacyDbImportPlan? priorPlan,
  }) async {
    throw UnsupportedError(
      'LegacyDbImporter.apply requires dart:io (desktop/native). '
      'Import Next .cache/app.db on Flutter Windows — see '
      'docs/multiplatform-dart-legacy-db-import.md',
    );
  }
}
