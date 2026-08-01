import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'json_codec.dart';
import 'library_records.dart';

SetItemRecord _rowToItem(SetItem row) {
  return SetItemRecord(
    id: row.id,
    setId: row.setId,
    slot: row.slot,
    itemHash: row.itemHash,
    itemName: row.itemName,
    instanceId: row.instanceId,
    selectedPerks: parseIntJsonArray(row.selectedPerks),
    masterworkHash: row.masterworkHash,
    modHashes: row.modHashes == null
        ? null
        : parseIntJsonArray(row.modHashes),
    sortOrder: row.sortOrder,
    removedAt: row.removedAt,
  );
}

/// All items for a set (including soft-removed).
Future<List<SetItemRecord>> listSetItems(AppDatabase db, String setId) async {
  final rows = await (db.select(db.setItems)
        ..where((t) => t.setId.equals(setId)))
      .get();
  return rows.map(_rowToItem).toList();
}

/// Active items only (`removed_at` IS NULL).
Future<List<SetItemRecord>> listActiveSetItems(
  AppDatabase db,
  String setId,
) async {
  final rows = await (db.select(db.setItems)
        ..where((t) => t.setId.equals(setId) & t.removedAt.isNull()))
      .get();
  return rows.map(_rowToItem).toList();
}

/// Persistence-level insert. If an active row exists for [slot] and
/// [replaceExisting] is true, soft-removes it first. If occupied and
/// [replaceExisting] is false, throws [StateError].
///
/// Domain composition/energy validation is out of scope (DART-027+).
Future<SetItemRecord> upsertSetItemRecord(
  AppDatabase db, {
  required String id,
  required String setId,
  required String slot,
  required int itemHash,
  required String itemName,
  String? instanceId,
  List<int> selectedPerks = const [],
  int? masterworkHash,
  List<int>? modHashes,
  int sortOrder = 0,
  bool replaceExisting = true,
  required String now,
}) async {
  final active = await (db.select(db.setItems)
        ..where(
          (t) =>
              t.setId.equals(setId) & t.slot.equals(slot) & t.removedAt.isNull(),
        ))
      .getSingleOrNull();

  if (active != null) {
    if (!replaceExisting) {
      throw StateError('Slot $slot is occupied on set $setId');
    }
    await (db.update(db.setItems)..where((t) => t.id.equals(active.id))).write(
      SetItemsCompanion(removedAt: Value(now)),
    );
  }

  await db.into(db.setItems).insert(
        SetItemsCompanion.insert(
          id: id,
          setId: setId,
          slot: slot,
          itemHash: itemHash,
          itemName: itemName,
          selectedPerks: Value(encodeIntJsonArray(selectedPerks)),
          masterworkHash: Value(masterworkHash),
          modHashes: Value(
            modHashes == null ? null : encodeIntJsonArray(modHashes),
          ),
          instanceId: Value(instanceId),
          sortOrder: Value(sortOrder),
        ),
      );

  final row = await (db.select(db.setItems)..where((t) => t.id.equals(id)))
      .getSingle();
  return _rowToItem(row);
}

Future<bool> softRemoveSetItem(
  AppDatabase db, {
  required String setId,
  required String itemId,
  required String now,
}) async {
  final n = await (db.update(db.setItems)
        ..where(
          (t) =>
              t.id.equals(itemId) &
              t.setId.equals(setId) &
              t.removedAt.isNull(),
        ))
      .write(SetItemsCompanion(removedAt: Value(now)));
  return n > 0;
}

Future<int> countActiveItemsInSet(AppDatabase db, String setId) async {
  final rows = await listActiveSetItems(db, setId);
  return rows.length;
}
