import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'storage_root.dart';

/// Current on-disk schema for [FillInMissingListStore].
const int kFillInMissingListSchemaVersion = 1;

/// Soft cap for `{StorageRoot}/fill_in/missing_by_build.json` reads.
///
/// Rejected by length **before** parsing. Oversized files are never overwritten.
const int kFillInMissingListMaxBytes = 1 * 1024 * 1024;

/// Thrown when the Fill In missing-list store cannot be read safely.
class FillInMissingListStoreException implements Exception {
  FillInMissingListStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One build's saved Fill In missing list (+ optional similar weapon plan).
class FillInSavedBuildPlan {
  const FillInSavedBuildPlan({
    required this.buildId,
    required this.missing,
    this.similarWeaponName,
    this.similarForName,
    this.updatedAt,
  });

  final String buildId;
  final List<String> missing;
  final String? similarWeaponName;
  final String? similarForName;
  final String? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'missing': missing,
      if (similarWeaponName != null) 'similarWeaponName': similarWeaponName,
      if (similarForName != null) 'similarForName': similarForName,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  factory FillInSavedBuildPlan.fromJson(String buildId, Map<String, dynamic> json) {
    final rawMissing = json['missing'];
    final missing = <String>[];
    if (rawMissing is List) {
      for (final entry in rawMissing) {
        if (entry is String && entry.trim().isNotEmpty) {
          missing.add(entry);
        }
      }
    }
    return FillInSavedBuildPlan(
      buildId: buildId,
      missing: List<String>.unmodifiable(missing),
      similarWeaponName: json['similarWeaponName'] as String?,
      similarForName: json['similarForName'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class _ParsedMissingList {
  const _ParsedMissingList({
    required this.schemaVersion,
    required this.builds,
    required this.preservedRawBuilds,
  });

  /// Null when `schemaVersion` is absent or not an int (unknown).
  final int? schemaVersion;
  final Map<String, FillInSavedBuildPlan> builds;

  /// Non-object `builds` entries preserved verbatim on save (never dropped).
  final Map<String, dynamic> preservedRawBuilds;
}

/// App-private per-build Fill In plan under `{StorageRoot}/fill_in/`.
///
/// Writes only [StorageRoot.fillInMissingByBuildPath] via `.tmp` + rename.
/// Updates are **additive per build id**: saving build A never deletes build B
/// and never touches DIM link / artifact / armor-set / SQLite stores.
///
/// When an existing file's `schemaVersion` is missing or differs from
/// [kFillInMissingListSchemaVersion], the prior file is copied to a
/// timestamped `.bak-…` sibling with exclusive-create before rewrite.
class FillInMissingListStore {
  FillInMissingListStore({
    required StorageRoot root,
    this.maxBytes = kFillInMissingListMaxBytes,
    this.beforeRename,
  }) : _root = root;

  final StorageRoot _root;

  /// Size cap checked against file length before reading bytes.
  final int maxBytes;

  /// Test hook: invoked after the `.tmp` is flushed, before rename.
  /// Throw to simulate a mid-write failure without truncating the store.
  final Future<void> Function()? beforeRename;

  String get storePath => _root.fillInMissingByBuildPath;

  String get _tempPath => '$storePath.tmp';

  /// Load one build's saved plan, or null when absent.
  Future<FillInSavedBuildPlan?> loadForBuild(String buildId) async {
    final all = await _readAll();
    return all[buildId];
  }

  /// Load every saved build plan (empty map when missing).
  ///
  /// Oversized files fail closed with [FillInMissingListStoreException].
  Future<Map<String, FillInSavedBuildPlan>> loadAll() => _readAll();

  /// Upsert [plan] for its [FillInSavedBuildPlan.buildId] only.
  ///
  /// Other build entries in the file are preserved (including non-object
  /// values). Never writes outside [storePath] / its `.tmp` / schema backup
  /// siblings. Oversized existing files are never overwritten.
  Future<void> saveBuildPlan(FillInSavedBuildPlan plan) async {
    final id = plan.buildId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(plan.buildId, 'buildId', 'must be non-empty');
    }
    await Directory(_root.fillInCacheDir).create(recursive: true);

    final existingFile = File(storePath);
    var schemaVersion = kFillInMissingListSchemaVersion;
    final builds = <String, FillInSavedBuildPlan>{};
    final preservedRaw = <String, dynamic>{};

    if (await existingFile.exists()) {
      final parsed = await _parseFile(existingFile);
      builds.addAll(parsed.builds);
      preservedRaw.addAll(parsed.preservedRawBuilds);
      final existingVersion = parsed.schemaVersion;
      if (existingVersion != kFillInMissingListSchemaVersion) {
        await _backupExclusive(
          existingFile,
          fromVersionLabel: existingVersion?.toString() ?? 'unknown',
        );
      }
      schemaVersion = kFillInMissingListSchemaVersion;
    }

    final stamped = FillInSavedBuildPlan(
      buildId: id,
      missing: plan.missing,
      similarWeaponName: plan.similarWeaponName,
      similarForName: plan.similarForName,
      updatedAt: plan.updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
    builds[id] = stamped;
    // Upsert replaces any prior non-object entry for the same id.
    preservedRaw.remove(id);
    await _writeAtomic(
      schemaVersion: schemaVersion,
      builds: builds,
      preservedRawBuilds: preservedRaw,
    );
  }

  Future<Map<String, FillInSavedBuildPlan>> _readAll() async {
    final file = File(storePath);
    if (!await file.exists()) return const <String, FillInSavedBuildPlan>{};
    try {
      return (await _parseFile(file)).builds;
    } on FillInMissingListStoreException {
      rethrow;
    } catch (_) {
      return const <String, FillInSavedBuildPlan>{};
    }
  }

  Future<_ParsedMissingList> _parseFile(File file) async {
    final bytes = await _readCappedBytes(file);
    final text = utf8.decode(bytes);
    if (text.trim().isEmpty) {
      return const _ParsedMissingList(
        schemaVersion: kFillInMissingListSchemaVersion,
        builds: <String, FillInSavedBuildPlan>{},
        preservedRawBuilds: <String, dynamic>{},
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw FillInMissingListStoreException(
        'fill_in missing list root must be an object',
      );
    }
    final versionRaw = decoded['schemaVersion'];
    final int? schemaVersion = versionRaw is int ? versionRaw : null;
    final buildsRaw = decoded['builds'];
    final builds = <String, FillInSavedBuildPlan>{};
    final preservedRaw = <String, dynamic>{};
    if (buildsRaw is Map<String, dynamic>) {
      for (final entry in buildsRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          builds[entry.key] = FillInSavedBuildPlan.fromJson(entry.key, value);
        } else {
          preservedRaw[entry.key] = value;
        }
      }
    } else if (buildsRaw != null) {
      throw FillInMissingListStoreException(
        'fill_in missing list builds must be an object',
      );
    }
    return _ParsedMissingList(
      schemaVersion: schemaVersion,
      builds: builds,
      preservedRawBuilds: preservedRaw,
    );
  }

  Future<Uint8List> _readCappedBytes(File file) async {
    if (maxBytes < 1) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be >= 1');
    }
    final handle = await file.open(mode: FileMode.read);
    try {
      final length = await handle.length();
      if (length > maxBytes) {
        throw FillInMissingListStoreException(
          'file exceeds size limit ($length > $maxBytes bytes)',
        );
      }
      if (length == 0) return Uint8List(0);
      return await handle.read(length);
    } finally {
      await handle.close();
    }
  }

  Future<void> _writeAtomic({
    required int schemaVersion,
    required Map<String, FillInSavedBuildPlan> builds,
    required Map<String, dynamic> preservedRawBuilds,
  }) async {
    final buildsJson = <String, dynamic>{
      for (final entry in builds.entries) entry.key: entry.value.toJson(),
      ...preservedRawBuilds,
    };
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'builds': buildsJson,
    };
    final bytes = Uint8List.fromList(
      utf8.encode('${const JsonEncoder.withIndent('  ').convert(payload)}\n'),
    );
    final tmp = File(_tempPath);
    final handle = await tmp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    try {
      final hook = beforeRename;
      if (hook != null) await hook();
      await tmp.rename(storePath);
    } catch (_) {
      if (await tmp.exists()) {
        await tmp.delete();
      }
      rethrow;
    }
  }

  /// Timestamped sibling backup with exclusive-create (fails if name exists).
  ///
  /// Dart's portable [FileMode] has no writeOnlyExclusive on all SDKs — we
  /// refuse an existing path, then open [FileMode.writeOnly].
  Future<File> _backupExclusive(
    File source, {
    required String fromVersionLabel,
  }) async {
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final bakPath = '$storePath.bak-v$fromVersionLabel-$stamp';
    final bak = File(bakPath);
    if (await bak.exists()) {
      throw StateError('backup already exists: $bakPath');
    }
    final bytes = await source.readAsBytes();
    final handle = await bak.open(mode: FileMode.writeOnly);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    return bak;
  }
}
