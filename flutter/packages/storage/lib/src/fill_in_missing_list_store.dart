import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'storage_root.dart';

/// Current on-disk schema for [FillInMissingListStore].
const int kFillInMissingListSchemaVersion = 1;

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

/// App-private per-build Fill In plan under `{StorageRoot}/fill_in/`.
///
/// Writes only [StorageRoot.fillInMissingByBuildPath] via `.tmp` + rename.
/// Updates are **additive per build id**: saving build A never deletes build B
/// and never touches DIM link / artifact / armor-set / SQLite stores.
///
/// When an existing file's `schemaVersion` differs from
/// [kFillInMissingListSchemaVersion], the prior file is copied to a
/// timestamped `.bak-…` sibling with exclusive-create before rewrite.
class FillInMissingListStore {
  FillInMissingListStore({required StorageRoot root}) : _root = root;

  final StorageRoot _root;

  String get storePath => _root.fillInMissingByBuildPath;

  String get _tempPath => '$storePath.tmp';

  /// Load one build's saved plan, or null when absent.
  Future<FillInSavedBuildPlan?> loadForBuild(String buildId) async {
    final all = await _readAll();
    return all[buildId];
  }

  /// Load every saved build plan (empty map when missing/unreadable).
  Future<Map<String, FillInSavedBuildPlan>> loadAll() => _readAll();

  /// Upsert [plan] for its [FillInSavedBuildPlan.buildId] only.
  ///
  /// Other build entries in the file are preserved. Never writes outside
  /// [storePath] / its `.tmp` / schema backup siblings.
  Future<void> saveBuildPlan(FillInSavedBuildPlan plan) async {
    final id = plan.buildId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(plan.buildId, 'buildId', 'must be non-empty');
    }
    await Directory(_root.fillInCacheDir).create(recursive: true);

    final existingFile = File(storePath);
    var schemaVersion = kFillInMissingListSchemaVersion;
    final builds = <String, FillInSavedBuildPlan>{};

    if (await existingFile.exists()) {
      final parsed = await _parseFile(existingFile);
      schemaVersion = parsed.schemaVersion;
      builds.addAll(parsed.builds);
      if (schemaVersion != kFillInMissingListSchemaVersion) {
        await _backupExclusive(
          existingFile,
          fromVersion: schemaVersion,
        );
        schemaVersion = kFillInMissingListSchemaVersion;
      }
    }

    final stamped = FillInSavedBuildPlan(
      buildId: id,
      missing: plan.missing,
      similarWeaponName: plan.similarWeaponName,
      similarForName: plan.similarForName,
      updatedAt: plan.updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
    builds[id] = stamped;
    await _writeAtomic(schemaVersion: schemaVersion, builds: builds);
  }

  Future<Map<String, FillInSavedBuildPlan>> _readAll() async {
    final file = File(storePath);
    if (!await file.exists()) return const <String, FillInSavedBuildPlan>{};
    try {
      return (await _parseFile(file)).builds;
    } catch (_) {
      return const <String, FillInSavedBuildPlan>{};
    }
  }

  Future<({int schemaVersion, Map<String, FillInSavedBuildPlan> builds})>
      _parseFile(File file) async {
    final text = await file.readAsString();
    if (text.trim().isEmpty) {
      return (
        schemaVersion: kFillInMissingListSchemaVersion,
        builds: <String, FillInSavedBuildPlan>{},
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('fill_in missing list root must be an object');
    }
    final versionRaw = decoded['schemaVersion'];
    final schemaVersion = versionRaw is int
        ? versionRaw
        : kFillInMissingListSchemaVersion;
    final buildsRaw = decoded['builds'];
    final builds = <String, FillInSavedBuildPlan>{};
    if (buildsRaw is Map<String, dynamic>) {
      for (final entry in buildsRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          builds[entry.key] = FillInSavedBuildPlan.fromJson(entry.key, value);
        }
      }
    }
    return (schemaVersion: schemaVersion, builds: builds);
  }

  Future<void> _writeAtomic({
    required int schemaVersion,
    required Map<String, FillInSavedBuildPlan> builds,
  }) async {
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'builds': <String, dynamic>{
        for (final entry in builds.entries) entry.key: entry.value.toJson(),
      },
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
  Future<File> _backupExclusive(File source, {required int fromVersion}) async {
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final bakPath = '$storePath.bak-v$fromVersion-$stamp';
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
