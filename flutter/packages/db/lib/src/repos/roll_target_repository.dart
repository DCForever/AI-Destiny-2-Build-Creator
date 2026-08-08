import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

/// One column on a persisted roll target (preferred + avoid multi-picks).
class RollTargetColumnRecord {
  const RollTargetColumnRecord({
    required this.columnKey,
    this.label,
    this.preferredPlugHashes = const [],
    this.avoidPlugHashes = const [],
  });

  final String columnKey;
  final String? label;
  final List<int> preferredPlugHashes;
  final List<int> avoidPlugHashes;

  Map<String, Object?> toJson() => {
        'columnKey': columnKey,
        if (label != null && label!.isNotEmpty) 'label': label,
        'preferred': preferredPlugHashes,
        'avoid': avoidPlugHashes,
      };

  static RollTargetColumnRecord fromJson(Map<String, Object?> m) {
    return RollTargetColumnRecord(
      columnKey: m['columnKey']?.toString() ?? '',
      label: m['label']?.toString(),
      preferredPlugHashes: _intList(m['preferred']),
      avoidPlugHashes: _intList(m['avoid']),
    );
  }

  bool get hasPreferredAvoidOverlap {
    final a = preferredPlugHashes.toSet();
    for (final h in avoidPlugHashes) {
      if (a.contains(h)) return true;
    }
    return false;
  }
}

/// Persisted Catalog weapon roll target (DBR-IDL-*).
class RollTargetRecord {
  const RollTargetRecord({
    required this.id,
    required this.userId,
    required this.weaponKey,
    required this.name,
    this.columns = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String weaponKey;
  final String name;
  final List<RollTargetColumnRecord> columns;
  final String createdAt;
  final String updatedAt;
}

/// Thrown when preferred ∩ avoid is non-empty or name conflicts.
class RollTargetPersistException implements Exception {
  const RollTargetPersistException(this.message, {required this.code});

  final String code;
  final String message;

  @override
  String toString() => 'RollTargetPersistException($code: $message)';
}

List<int> _intList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<num>().map((n) => n.toInt()).toList();
}

String encodeRollTargetColumns(List<RollTargetColumnRecord> columns) {
  return jsonEncode(columns.map((c) => c.toJson()).toList());
}

List<RollTargetColumnRecord> parseRollTargetColumns(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map>()
        .map(
          (m) => RollTargetColumnRecord.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v as Object?)),
          ),
        )
        .where((c) => c.columnKey.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}

void _assertNoPreferredAvoidOverlap(List<RollTargetColumnRecord> columns) {
  for (final col in columns) {
    if (col.hasPreferredAvoidOverlap) {
      throw const RollTargetPersistException(
        'Preferred and avoid plugs must be disjoint on each column',
        code: 'ROLL_TARGET_PREFERRED_AVOID_OVERLAP',
      );
    }
  }
}

RollTargetRecord _rowToRecord(WeaponRollTargetRow row) {
  return RollTargetRecord(
    id: row.id,
    userId: row.userId,
    weaponKey: row.weaponKey,
    name: row.name,
    columns: parseRollTargetColumns(row.columnsJson),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// List roll targets for [userId], optionally filtered by [weaponKey].
Future<List<RollTargetRecord>> listRollTargets(
  AppDatabase db,
  int userId, {
  String? weaponKey,
}) async {
  final q = db.select(db.weaponRollTargets)
    ..where((t) => t.userId.equals(userId));
  if (weaponKey != null) {
    q.where((t) => t.weaponKey.equals(weaponKey));
  }
  final rows = await q.get();
  rows.sort((a, b) {
    final w = a.weaponKey.compareTo(b.weaponKey);
    if (w != 0) return w;
    return a.name.compareTo(b.name);
  });
  return rows.map(_rowToRecord).toList();
}

Future<RollTargetRecord?> getRollTarget(
  AppDatabase db,
  int userId,
  String id,
) async {
  final row = await (db.select(db.weaponRollTargets)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  return _rowToRecord(row);
}

/// Create a roll target. Throws on preferred∩avoid or unique name conflict.
Future<RollTargetRecord> createRollTarget(
  AppDatabase db,
  int userId, {
  required String id,
  required String weaponKey,
  required String name,
  List<RollTargetColumnRecord> columns = const [],
  required String now,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const RollTargetPersistException(
      'Name is required',
      code: 'ROLL_TARGET_NAME_REQUIRED',
    );
  }
  _assertNoPreferredAvoidOverlap(columns);
  try {
    await db.into(db.weaponRollTargets).insert(
          WeaponRollTargetsCompanion.insert(
            id: id,
            userId: userId,
            weaponKey: weaponKey,
            name: trimmed,
            columnsJson: Value(encodeRollTargetColumns(columns)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  } catch (e) {
    throw RollTargetPersistException(
      'Could not create roll target (duplicate name for weapon?)',
      code: 'ROLL_TARGET_CREATE_FAILED',
    );
  }
  return (await getRollTarget(db, userId, id))!;
}

/// Update name and/or columns. Returns null if missing / not owned.
Future<RollTargetRecord?> updateRollTarget(
  AppDatabase db,
  int userId,
  String id, {
  String? name,
  List<RollTargetColumnRecord>? columns,
  required String now,
}) async {
  final existing = await getRollTarget(db, userId, id);
  if (existing == null) return null;
  final nextName = name?.trim() ?? existing.name;
  if (nextName.isEmpty) {
    throw const RollTargetPersistException(
      'Name is required',
      code: 'ROLL_TARGET_NAME_REQUIRED',
    );
  }
  final nextColumns = columns ?? existing.columns;
  _assertNoPreferredAvoidOverlap(nextColumns);
  try {
    final n = await (db.update(db.weaponRollTargets)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .write(
      WeaponRollTargetsCompanion(
        name: Value(nextName),
        columnsJson: Value(encodeRollTargetColumns(nextColumns)),
        updatedAt: Value(now),
      ),
    );
    if (n == 0) return null;
  } catch (e) {
    throw const RollTargetPersistException(
      'Could not update roll target (duplicate name for weapon?)',
      code: 'ROLL_TARGET_UPDATE_FAILED',
    );
  }
  return getRollTarget(db, userId, id);
}

/// Delete target; active pointer cascades via FK when target removed.
Future<bool> deleteRollTarget(AppDatabase db, int userId, String id) async {
  final n = await (db.delete(db.weaponRollTargets)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
  return n > 0;
}

/// Active target id for [weaponKey], or null.
Future<String?> getActiveRollTargetId(
  AppDatabase db,
  int userId,
  String weaponKey,
) async {
  final row = await (db.select(db.weaponRollTargetActive)
        ..where(
          (t) => t.userId.equals(userId) & t.weaponKey.equals(weaponKey),
        ))
      .getSingleOrNull();
  return row?.targetId;
}

/// Set active target for ranking. [targetId] must belong to user + weapon.
/// Pass null to clear.
Future<void> setActiveRollTarget(
  AppDatabase db,
  int userId,
  String weaponKey, {
  required String? targetId,
  required String now,
}) async {
  if (targetId == null) {
    await (db.delete(db.weaponRollTargetActive)
          ..where(
            (t) => t.userId.equals(userId) & t.weaponKey.equals(weaponKey),
          ))
        .go();
    return;
  }
  final target = await getRollTarget(db, userId, targetId);
  if (target == null || target.weaponKey != weaponKey) {
    throw const RollTargetPersistException(
      'Active target must exist for this weapon',
      code: 'ROLL_TARGET_ACTIVE_INVALID',
    );
  }
  await db.into(db.weaponRollTargetActive).insertOnConflictUpdate(
        WeaponRollTargetActiveCompanion.insert(
          userId: userId,
          weaponKey: weaponKey,
          targetId: targetId,
          updatedAt: now,
        ),
      );
}

/// Load active target record for [weaponKey], or null.
Future<RollTargetRecord?> getActiveRollTarget(
  AppDatabase db,
  int userId,
  String weaponKey,
) async {
  final id = await getActiveRollTargetId(db, userId, weaponKey);
  if (id == null) return null;
  return getRollTarget(db, userId, id);
}
