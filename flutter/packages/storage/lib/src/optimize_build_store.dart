import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'storage_root.dart';

/// Current on-disk schema for [OptimizeBuildStore].
///
/// v1: per-build optimized armor overlay (slots / stats / set bonuses / flag).
const int kOptimizeBuildSchemaVersion = 1;

/// Soft cap for `{StorageRoot}/fill_in/optimize_by_build.json` reads.
const int kOptimizeBuildStoreMaxBytes = 1 * 1024 * 1024;

/// Thrown when the Optimize build store cannot be read safely.
class OptimizeBuildStoreException implements Exception {
  OptimizeBuildStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One armor slot written by Optimize → Use this result.
class OptimizedArmorSlot {
  const OptimizedArmorSlot({
    required this.slotWire,
    required this.pieceName,
    required this.setId,
    required this.isExotic,
    this.instanceId,
    this.itemHash,
    this.statTotal,
  });

  final String slotWire;
  final String pieceName;
  final String setId;
  final bool isExotic;
  final String? instanceId;
  final int? itemHash;
  final int? statTotal;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'slot': slotWire,
        'pieceName': pieceName,
        'setId': setId,
        'isExotic': isExotic,
        if (instanceId != null) 'instanceId': instanceId,
        if (itemHash != null) 'itemHash': itemHash,
        if (statTotal != null) 'statTotal': statTotal,
      };

  factory OptimizedArmorSlot.fromJson(Map<String, dynamic> json) {
    return OptimizedArmorSlot(
      slotWire: (json['slot'] as String? ?? '').trim(),
      pieceName: (json['pieceName'] as String? ?? '').trim(),
      setId: (json['setId'] as String? ?? '').trim(),
      isExotic: json['isExotic'] == true,
      instanceId: json['instanceId'] as String?,
      itemHash: json['itemHash'] is int ? json['itemHash'] as int : null,
      statTotal: json['statTotal'] is int ? json['statTotal'] as int : null,
    );
  }
}

/// One EoF stat total persisted with an optimized result.
class OptimizedStatTotal {
  const OptimizedStatTotal({required this.idWire, required this.value});

  final String idWire;
  final int value;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': idWire,
        'value': value,
      };

  factory OptimizedStatTotal.fromJson(Map<String, dynamic> json) {
    return OptimizedStatTotal(
      idWire: (json['id'] as String? ?? '').trim(),
      value: json['value'] is int ? json['value'] as int : 0,
    );
  }
}

/// One set-bonus box persisted with an optimized result.
class OptimizedSetBonus {
  const OptimizedSetBonus({
    required this.setId,
    required this.setName,
    required this.pieces,
    required this.tier,
    required this.text,
  });

  final String setId;
  final String setName;
  final int pieces;
  final String tier;
  final String text;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'setId': setId,
        'setName': setName,
        'pieces': pieces,
        'tier': tier,
        'text': text,
      };

  factory OptimizedSetBonus.fromJson(Map<String, dynamic> json) {
    return OptimizedSetBonus(
      setId: (json['setId'] as String? ?? '').trim(),
      setName: (json['setName'] as String? ?? '').trim(),
      pieces: json['pieces'] is int ? json['pieces'] as int : 0,
      tier: (json['tier'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
    );
  }
}

/// App-local Optimize overlay for one build (never Mario / warlock matrix).
class OptimizedBuildRecord {
  const OptimizedBuildRecord({
    required this.buildId,
    required this.isOptimized,
    required this.resultIndexOneBased,
    required this.slots,
    required this.stats,
    required this.setBonuses,
    this.exoticArmor,
    this.updatedAt,
  });

  final String buildId;
  final bool isOptimized;
  final int resultIndexOneBased;
  final List<OptimizedArmorSlot> slots;
  final List<OptimizedStatTotal> stats;
  final List<OptimizedSetBonus> setBonuses;
  final String? exoticArmor;
  final String? updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'isOptimized': isOptimized,
        'resultIndex': resultIndexOneBased,
        'slots': [for (final s in slots) s.toJson()],
        'stats': [for (final s in stats) s.toJson()],
        'setBonuses': [for (final b in setBonuses) b.toJson()],
        if (exoticArmor != null) 'exoticArmor': exoticArmor,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  factory OptimizedBuildRecord.fromJson(
    String buildId,
    Map<String, dynamic> json,
  ) {
    final slotsRaw = json['slots'];
    final statsRaw = json['stats'];
    final bonusesRaw = json['setBonuses'];
    return OptimizedBuildRecord(
      buildId: buildId,
      isOptimized: json['isOptimized'] == true,
      resultIndexOneBased:
          json['resultIndex'] is int ? json['resultIndex'] as int : 1,
      slots: [
        if (slotsRaw is List)
          for (final s in slotsRaw)
            if (s is Map<String, dynamic>) OptimizedArmorSlot.fromJson(s),
      ],
      stats: [
        if (statsRaw is List)
          for (final s in statsRaw)
            if (s is Map<String, dynamic>) OptimizedStatTotal.fromJson(s),
      ],
      setBonuses: [
        if (bonusesRaw is List)
          for (final b in bonusesRaw)
            if (b is Map<String, dynamic>) OptimizedSetBonus.fromJson(b),
      ],
      exoticArmor: json['exoticArmor'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class _ParsedOptimizeStore {
  const _ParsedOptimizeStore({
    required this.schemaVersion,
    required this.builds,
    required this.preservedRawBuilds,
  });

  final int? schemaVersion;
  final Map<String, OptimizedBuildRecord> builds;
  final Map<String, dynamic> preservedRawBuilds;
}

/// App-private per-build Optimize overlays under `{StorageRoot}/fill_in/`.
///
/// Writes only [StorageRoot.optimizeByBuildPath] via `.tmp` + rename.
/// Additive per build id. On schema mismatch, copies the prior file to a
/// timestamped `.bak-…` sibling (exclusive create) before rewrite.
class OptimizeBuildStore {
  OptimizeBuildStore({
    required StorageRoot root,
    this.maxBytes = kOptimizeBuildStoreMaxBytes,
    this.beforeRename,
    this.backupStampForTest,
  }) : _root = root;

  final StorageRoot _root;
  final int maxBytes;
  final Future<void> Function()? beforeRename;
  final String? backupStampForTest;

  String get storePath => _root.optimizeByBuildPath;

  String get _tempPath => '$storePath.tmp';

  Future<OptimizedBuildRecord?> loadForBuild(String buildId) async {
    final all = await loadAll();
    return all[buildId];
  }

  Future<Map<String, OptimizedBuildRecord>> loadAll() async {
    final file = File(storePath);
    if (!await file.exists()) return const <String, OptimizedBuildRecord>{};
    try {
      return (await _parseFile(file)).builds;
    } on OptimizeBuildStoreException {
      rethrow;
    } catch (_) {
      return const <String, OptimizedBuildRecord>{};
    }
  }

  Future<void> saveBuildRecord(OptimizedBuildRecord record) async {
    final id = record.buildId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(record.buildId, 'buildId', 'must be non-empty');
    }
    await Directory(_root.fillInCacheDir).create(recursive: true);

    final existingFile = File(storePath);
    var schemaVersion = kOptimizeBuildSchemaVersion;
    final builds = <String, OptimizedBuildRecord>{};
    final preservedRaw = <String, dynamic>{};

    if (await existingFile.exists()) {
      final parsed = await _parseFile(existingFile);
      builds.addAll(parsed.builds);
      preservedRaw.addAll(parsed.preservedRawBuilds);
      final existingVersion = parsed.schemaVersion;
      if (existingVersion != kOptimizeBuildSchemaVersion) {
        await _backupExclusive(
          existingFile,
          fromVersionLabel: existingVersion?.toString() ?? 'unknown',
        );
      }
      schemaVersion = kOptimizeBuildSchemaVersion;
    }

    builds[id] = OptimizedBuildRecord(
      buildId: id,
      isOptimized: record.isOptimized,
      resultIndexOneBased: record.resultIndexOneBased,
      slots: List<OptimizedArmorSlot>.unmodifiable(record.slots),
      stats: List<OptimizedStatTotal>.unmodifiable(record.stats),
      setBonuses: List<OptimizedSetBonus>.unmodifiable(record.setBonuses),
      exoticArmor: record.exoticArmor,
      updatedAt: record.updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
    preservedRaw.remove(id);
    await _writeAtomic(
      schemaVersion: schemaVersion,
      builds: builds,
      preservedRawBuilds: preservedRaw,
    );
  }

  /// Remove Optimize overlay for [buildId] (Undo cleared). Other builds kept.
  Future<void> clearBuild(String buildId) async {
    final id = buildId.trim();
    if (id.isEmpty) return;
    final existingFile = File(storePath);
    if (!await existingFile.exists()) return;

    final parsed = await _parseFile(existingFile);
    if (!parsed.builds.containsKey(id) &&
        !parsed.preservedRawBuilds.containsKey(id)) {
      return;
    }
    final builds = Map<String, OptimizedBuildRecord>.from(parsed.builds)
      ..remove(id);
    final preserved = Map<String, dynamic>.from(parsed.preservedRawBuilds)
      ..remove(id);
    if (parsed.schemaVersion != kOptimizeBuildSchemaVersion) {
      await _backupExclusive(
        existingFile,
        fromVersionLabel: parsed.schemaVersion?.toString() ?? 'unknown',
      );
    }
    await _writeAtomic(
      schemaVersion: kOptimizeBuildSchemaVersion,
      builds: builds,
      preservedRawBuilds: preserved,
    );
  }

  Future<_ParsedOptimizeStore> _parseFile(File file) async {
    final bytes = await _readCappedBytes(file);
    final text = utf8.decode(bytes);
    if (text.trim().isEmpty) {
      return const _ParsedOptimizeStore(
        schemaVersion: kOptimizeBuildSchemaVersion,
        builds: <String, OptimizedBuildRecord>{},
        preservedRawBuilds: <String, dynamic>{},
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw OptimizeBuildStoreException(
        'optimize_by_build root must be an object',
      );
    }
    final versionRaw = decoded['schemaVersion'];
    final int? schemaVersion = versionRaw is int ? versionRaw : null;
    final buildsRaw = decoded['builds'];
    final builds = <String, OptimizedBuildRecord>{};
    final preservedRaw = <String, dynamic>{};
    if (buildsRaw is Map<String, dynamic>) {
      for (final entry in buildsRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          builds[entry.key] =
              OptimizedBuildRecord.fromJson(entry.key, value);
        } else {
          preservedRaw[entry.key] = value;
        }
      }
    } else if (buildsRaw != null) {
      throw OptimizeBuildStoreException(
        'optimize_by_build builds must be an object',
      );
    }
    return _ParsedOptimizeStore(
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
        throw OptimizeBuildStoreException(
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
    required Map<String, OptimizedBuildRecord> builds,
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

  Future<File> _backupExclusive(
    File source, {
    required String fromVersionLabel,
  }) async {
    final stamp = backupStampForTest ??
        DateTime.now()
            .toUtc()
            .toIso8601String()
            .replaceAll(':', '')
            .replaceAll('.', '');
    final bakPath = '$storePath.bak-v$fromVersionLabel-$stamp';
    final bak = File(bakPath);
    await bak.create(exclusive: true);
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
