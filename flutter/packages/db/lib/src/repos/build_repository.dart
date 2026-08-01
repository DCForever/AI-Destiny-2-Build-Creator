import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'json_codec.dart';
import 'library_records.dart';

BuildRecord _rowToBuild(
  Build row,
  List<String> tagIds,
  List<SynergyTypeDesignationRecord> synergyTypes,
) {
  return BuildRecord(
    id: row.id,
    userId: row.userId,
    name: row.name,
    className: row.className,
    subclass: decodeJsonValue(row.subclass),
    exoticArmorHash: row.exoticArmorHash,
    exoticArmorName: row.exoticArmorName,
    exoticWeaponHash: row.exoticWeaponHash,
    exoticWeaponName: row.exoticWeaponName,
    pinnedSuper: row.pinnedSuper,
    softStatTargets: parseSoftStatTargetsJson(row.softStatTargets),
    tagIds: tagIds,
    synergyTypes: synergyTypes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

Future<List<String>> _loadBuildTags(AppDatabase db, String buildId) async {
  final rows = await (db.select(db.buildTags)
        ..where((t) => t.buildId.equals(buildId)))
      .get();
  final tags = rows.map((r) => r.tagId).toList()..sort();
  return tags;
}

Future<List<SynergyTypeDesignationRecord>> _loadBuildSynergyTypes(
  AppDatabase db,
  String buildId,
) async {
  final rows = await (db.select(db.buildSynergyTypes)
        ..where((t) => t.buildId.equals(buildId)))
      .get();
  return rows
      .map(
        (r) => SynergyTypeDesignationRecord(
          type: r.type,
          subType: (r.subType?.trim().isEmpty ?? true) ? null : r.subType,
        ),
      )
      .toList();
}

Future<Map<String, List<String>>> _loadBuildTagsForIds(
  AppDatabase db,
  List<String> buildIds,
) async {
  final map = {for (final id in buildIds) id: <String>[]};
  if (buildIds.isEmpty) return map;
  final rows = await (db.select(db.buildTags)
        ..where((t) => t.buildId.isIn(buildIds)))
      .get();
  for (final row in rows) {
    map.putIfAbsent(row.buildId, () => <String>[]).add(row.tagId);
  }
  for (final id in map.keys) {
    map[id]!.sort();
  }
  return map;
}

Future<Map<String, List<SynergyTypeDesignationRecord>>>
    _loadBuildSynergyTypesForIds(
  AppDatabase db,
  List<String> buildIds,
) async {
  final map = {
    for (final id in buildIds) id: <SynergyTypeDesignationRecord>[],
  };
  if (buildIds.isEmpty) return map;
  final rows = await (db.select(db.buildSynergyTypes)
        ..where((t) => t.buildId.isIn(buildIds)))
      .get();
  for (final row in rows) {
    final d = SynergyTypeDesignationRecord(
      type: row.type,
      subType: (row.subType?.trim().isEmpty ?? true) ? null : row.subType,
    );
    map.putIfAbsent(row.buildId, () => <SynergyTypeDesignationRecord>[]).add(d);
  }
  return map;
}

Future<List<BuildRecord>> _rowsToBuilds(
  AppDatabase db,
  List<Build> rows,
) async {
  if (rows.isEmpty) return const [];
  final ids = rows.map((r) => r.id).toList();
  final tagsByBuild = await _loadBuildTagsForIds(db, ids);
  final synergyByBuild = await _loadBuildSynergyTypesForIds(db, ids);
  return rows
      .map(
        (row) => _rowToBuild(
          row,
          tagsByBuild[row.id] ?? const [],
          synergyByBuild[row.id] ?? const [],
        ),
      )
      .toList();
}

Future<void> _insertSynergyTypes(
  AppDatabase db,
  String buildId,
  List<SynergyTypeDesignationRecord> designations,
  String now,
) async {
  for (final d in designations) {
    final sub =
        d.subType != null && d.subType!.trim().isNotEmpty ? d.subType! : '';
    await db.into(db.buildSynergyTypes).insert(
          BuildSynergyTypesCompanion.insert(
            buildId: buildId,
            type: d.type,
            subType: Value(sub),
            attachedAt: now,
          ),
        );
  }
}

/// List all builds for [userId].
Future<List<BuildRecord>> listBuilds(AppDatabase db, int userId) async {
  final rows = await (db.select(db.builds)
        ..where((t) => t.userId.equals(userId)))
      .get();
  return _rowsToBuilds(db, rows);
}

/// Get one build scoped to [userId], or null.
Future<BuildRecord?> getBuild(
  AppDatabase db,
  int userId,
  String id,
) async {
  final row = await (db.select(db.builds)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  final tags = await _loadBuildTags(db, row.id);
  final types = await _loadBuildSynergyTypes(db, row.id);
  return _rowToBuild(row, tags, types);
}

/// Create a build with optional tags and synergy type designations.
Future<BuildRecord> createBuildRecord(
  AppDatabase db,
  int userId, {
  required String id,
  required String name,
  required String className,
  Object? subclass,
  int? exoticArmorHash,
  String? exoticArmorName,
  int? exoticWeaponHash,
  String? exoticWeaponName,
  String? pinnedSuper,
  Map<String, Object?>? softStatTargets,
  List<String> tagIds = const [],
  List<SynergyTypeDesignationRecord> synergyTypes = const [],
  required String now,
}) async {
  await db.into(db.builds).insert(
        BuildsCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          className: className,
          subclass: encodeJsonValue(subclass ?? const <String, Object?>{}),
          exoticArmorHash: Value(exoticArmorHash),
          exoticArmorName: Value(exoticArmorName),
          exoticWeaponHash: Value(exoticWeaponHash),
          exoticWeaponName: Value(exoticWeaponName),
          pinnedSuper: Value(pinnedSuper),
          softStatTargets: Value(encodeSoftStatTargetsJson(softStatTargets)),
          createdAt: now,
          updatedAt: now,
        ),
      );
  for (final tagId in tagIds) {
    await db.into(db.buildTags).insert(
          BuildTagsCompanion.insert(buildId: id, tagId: tagId),
        );
  }
  await _insertSynergyTypes(db, id, synergyTypes, now);
  return (await getBuild(db, userId, id))!;
}

/// Patch a build; returns null if missing.
///
/// Nullable fields use [Value] wrappers: omit (null param) keeps existing;
/// pass [Value] with null to clear.
Future<BuildRecord?> updateBuildRecord(
  AppDatabase db,
  int userId,
  String id, {
  String? name,
  String? className,
  Object? subclass,
  Value<int?> exoticArmorHash = const Value.absent(),
  Value<String?> exoticArmorName = const Value.absent(),
  Value<int?> exoticWeaponHash = const Value.absent(),
  Value<String?> exoticWeaponName = const Value.absent(),
  Value<String?> pinnedSuper = const Value.absent(),
  Map<String, Object?>? softStatTargets,
  List<String>? tagIds,
  List<SynergyTypeDesignationRecord>? synergyTypes,
  required String now,
}) async {
  final existing = await getBuild(db, userId, id);
  if (existing == null) return null;

  await (db.update(db.builds)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .write(
    BuildsCompanion(
      name: Value(name ?? existing.name),
      className: Value(className ?? existing.className),
      subclass: Value(encodeJsonValue(subclass ?? existing.subclass)),
      exoticArmorHash: exoticArmorHash.present
          ? exoticArmorHash
          : Value(existing.exoticArmorHash),
      exoticArmorName: exoticArmorName.present
          ? exoticArmorName
          : Value(existing.exoticArmorName),
      exoticWeaponHash: exoticWeaponHash.present
          ? exoticWeaponHash
          : Value(existing.exoticWeaponHash),
      exoticWeaponName: exoticWeaponName.present
          ? exoticWeaponName
          : Value(existing.exoticWeaponName),
      pinnedSuper:
          pinnedSuper.present ? pinnedSuper : Value(existing.pinnedSuper),
      softStatTargets: Value(
        encodeSoftStatTargetsJson(
          softStatTargets ?? existing.softStatTargets,
        ),
      ),
      updatedAt: Value(now),
    ),
  );

  if (tagIds != null) {
    await (db.delete(db.buildTags)..where((t) => t.buildId.equals(id))).go();
    for (final tagId in tagIds) {
      await db.into(db.buildTags).insert(
            BuildTagsCompanion.insert(buildId: id, tagId: tagId),
          );
    }
  }
  if (synergyTypes != null) {
    await (db.delete(db.buildSynergyTypes)
          ..where((t) => t.buildId.equals(id)))
        .go();
    await _insertSynergyTypes(db, id, synergyTypes, now);
  }

  return getBuild(db, userId, id);
}

/// Delete build (cascades variants/attachments/tags). Returns true if deleted.
Future<bool> deleteBuildRecord(
  AppDatabase db,
  int userId,
  String id,
) async {
  final n = await (db.delete(db.builds)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
  return n > 0;
}
