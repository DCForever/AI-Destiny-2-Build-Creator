import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'library_records.dart';

SetRecord _rowToSet(LibrarySet row, List<String> tagIds) {
  return SetRecord(
    id: row.id,
    userId: row.userId,
    name: row.name,
    type: row.type,
    tagIds: tagIds,
    optimizerConstraints: row.optimizerConstraints,
    linkedModSetId: row.linkedModSetId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

Future<List<String>> _loadTagsForSet(AppDatabase db, String setId) async {
  final rows = await (db.select(db.setTags)
        ..where((t) => t.setId.equals(setId)))
      .get();
  final tags = rows.map((r) => r.tagId).toList()..sort();
  return tags;
}

Future<Map<String, List<String>>> _loadTagsForSetIds(
  AppDatabase db,
  List<String> setIds,
) async {
  final map = {for (final id in setIds) id: <String>[]};
  if (setIds.isEmpty) return map;
  final rows = await (db.select(db.setTags)
        ..where((t) => t.setId.isIn(setIds)))
      .get();
  for (final row in rows) {
    map.putIfAbsent(row.setId, () => <String>[]).add(row.tagId);
  }
  for (final id in map.keys) {
    map[id]!.sort();
  }
  return map;
}

Future<List<SetRecord>> _rowsToSets(
  AppDatabase db,
  List<LibrarySet> rows,
) async {
  if (rows.isEmpty) return const [];
  final tagsBySet = await _loadTagsForSetIds(
    db,
    rows.map((r) => r.id).toList(),
  );
  return rows
      .map((row) => _rowToSet(row, tagsBySet[row.id] ?? const []))
      .toList();
}

/// List sets for [userId], optionally filtered by [type].
Future<List<SetRecord>> listSets(
  AppDatabase db,
  int userId, {
  String? type,
}) async {
  final query = db.select(db.sets)..where((t) => t.userId.equals(userId));
  if (type != null) {
    query.where((t) => t.type.equals(type));
  }
  final rows = await query.get();
  return _rowsToSets(db, rows);
}

Future<SetRecord?> getSet(AppDatabase db, int userId, String id) async {
  final row = await (db.select(db.sets)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  return _rowToSet(row, await _loadTagsForSet(db, row.id));
}

Future<SetRecord> createSetRecord(
  AppDatabase db,
  int userId, {
  required String id,
  required String name,
  required String type,
  List<String> tagIds = const [],
  String? optimizerConstraints,
  String? linkedModSetId,
  required String now,
}) async {
  await db.into(db.sets).insert(
        SetsCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          type: type,
          optimizerConstraints: Value(optimizerConstraints),
          linkedModSetId: Value(linkedModSetId),
          createdAt: now,
          updatedAt: now,
        ),
      );
  for (final tagId in tagIds) {
    await db
        .into(db.setTags)
        .insert(SetTagsCompanion.insert(setId: id, tagId: tagId));
  }
  return (await getSet(db, userId, id))!;
}

Future<SetRecord?> updateSetRecord(
  AppDatabase db,
  int userId,
  String id, {
  String? name,
  String? type,
  List<String>? tagIds,
  Value<String?> optimizerConstraints = const Value.absent(),
  Value<String?> linkedModSetId = const Value.absent(),
  required String now,
}) async {
  final existing = await getSet(db, userId, id);
  if (existing == null) return null;

  await (db.update(db.sets)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .write(
    SetsCompanion(
      name: Value(name ?? existing.name),
      type: Value(type ?? existing.type),
      optimizerConstraints: optimizerConstraints.present
          ? optimizerConstraints
          : Value(existing.optimizerConstraints),
      linkedModSetId: linkedModSetId.present
          ? linkedModSetId
          : Value(existing.linkedModSetId),
      updatedAt: Value(now),
    ),
  );

  if (tagIds != null) {
    await (db.delete(db.setTags)..where((t) => t.setId.equals(id))).go();
    for (final tagId in tagIds) {
      await db
          .into(db.setTags)
          .insert(SetTagsCompanion.insert(setId: id, tagId: tagId));
    }
  }
  return getSet(db, userId, id);
}

/// Delete set if not attached. Throws [SetInUseException] when attachments exist.
///
/// Schema also enforces ON DELETE RESTRICT as a backstop.
Future<bool> deleteSetRecord(AppDatabase db, int userId, String id) async {
  final existing = await getSet(db, userId, id);
  if (existing == null) return false;

  final refs = await findAttachmentsBySetId(db, id);
  if (refs.isNotEmpty) {
    throw SetInUseException(id, refs);
  }

  final n = await (db.delete(db.sets)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
  return n > 0;
}

/// True if another set already has (userId, type, name).
Future<bool> findDuplicateSetName(
  AppDatabase db,
  int userId, {
  required String type,
  required String name,
  String? excludeId,
}) async {
  final row = await (db.select(db.sets)
        ..where(
          (t) =>
              t.userId.equals(userId) &
              t.type.equals(type) &
              t.name.equals(name),
        ))
      .getSingleOrNull();
  if (row == null) return false;
  if (excludeId != null && row.id == excludeId) return false;
  return true;
}

/// Builds/variants that attach [setId] (for “in use” UX and RESTRICT checks).
Future<List<SetAttachmentRef>> findAttachmentsBySetId(
  AppDatabase db,
  String setId,
) async {
  final query = db.select(db.variantSetAttachments).join([
    innerJoin(
      db.buildVariants,
      db.buildVariants.id.equalsExp(db.variantSetAttachments.variantId),
    ),
    innerJoin(
      db.builds,
      db.builds.id.equalsExp(db.buildVariants.buildId),
    ),
  ])
    ..where(db.variantSetAttachments.setId.equals(setId));

  final rows = await query.get();
  return rows
      .map(
        (row) => SetAttachmentRef(
          buildId: row.readTable(db.builds).id,
          buildName: row.readTable(db.builds).name,
          variantId: row.readTable(db.buildVariants).id,
          variantName: row.readTable(db.buildVariants).name,
        ),
      )
      .toList();
}
