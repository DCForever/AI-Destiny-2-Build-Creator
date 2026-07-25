import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'library_records.dart';

SynergyRecord _rowToSynergy(Synergy row) {
  return SynergyRecord(
    id: row.id,
    userId: row.userId,
    name: row.name,
    type: row.type,
    subType: row.subType,
    description: row.description,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

SynergyLinkRecord _rowToLink(SynergyLink row) {
  return SynergyLinkRecord(
    id: row.id,
    synergyId: row.synergyId,
    kind: row.kind,
    displayName: row.displayName,
    itemHash: row.itemHash,
    perkHash: row.perkHash,
    parentItemHash: row.parentItemHash,
    originTraitName: row.originTraitName,
    originTraitHash: row.originTraitHash,
    armorSetName: row.armorSetName,
    bonusPieces: row.bonusPieces,
    bonusName: row.bonusName,
    armorSetHash: row.armorSetHash,
  );
}

Future<List<SynergyLinkRecord>> _listLinks(
  AppDatabase db,
  String synergyId,
) async {
  final rows = await (db.select(db.synergyLinks)
        ..where((t) => t.synergyId.equals(synergyId)))
      .get();
  return rows.map(_rowToLink).toList();
}

Future<Map<String, List<SynergyLinkRecord>>> _listLinksForIds(
  AppDatabase db,
  List<String> synergyIds,
) async {
  final map = {for (final id in synergyIds) id: <SynergyLinkRecord>[]};
  if (synergyIds.isEmpty) return map;
  final rows = await (db.select(db.synergyLinks)
        ..where((t) => t.synergyId.isIn(synergyIds)))
      .get();
  for (final row in rows) {
    map.putIfAbsent(row.synergyId, () => <SynergyLinkRecord>[]).add(
          _rowToLink(row),
        );
  }
  return map;
}

Future<List<SynergyWithLinks>> _rowsToSynergies(
  AppDatabase db,
  List<Synergy> rows,
) async {
  if (rows.isEmpty) return const [];
  final linksBy = await _listLinksForIds(db, rows.map((r) => r.id).toList());
  return rows
      .map(
        (row) => SynergyWithLinks(
          record: _rowToSynergy(row),
          links: linksBy[row.id] ?? const [],
        ),
      )
      .toList();
}

/// Input for inserting a synergy link (id optional — generated if omitted).
class SynergyLinkInput {
  const SynergyLinkInput({
    this.id,
    required this.kind,
    required this.displayName,
    this.itemHash,
    this.perkHash,
    this.parentItemHash,
    this.originTraitName,
    this.originTraitHash,
    this.armorSetName,
    this.bonusPieces,
    this.bonusName,
    this.armorSetHash,
  });

  final String? id;
  final String kind;
  final String displayName;
  final int? itemHash;
  final int? perkHash;
  final int? parentItemHash;
  final String? originTraitName;
  final int? originTraitHash;
  final String? armorSetName;
  final int? bonusPieces;
  final String? bonusName;
  final int? armorSetHash;
}

Future<void> _insertLinks(
  AppDatabase db,
  String synergyId,
  List<SynergyLinkInput> links,
) async {
  var i = 0;
  for (final link in links) {
    final linkId = link.id ?? '${synergyId}-link-${i++}';
    await db.into(db.synergyLinks).insert(
          SynergyLinksCompanion.insert(
            id: linkId,
            synergyId: synergyId,
            kind: link.kind,
            displayName: link.displayName,
            itemHash: Value(link.itemHash),
            perkHash: Value(link.perkHash),
            parentItemHash: Value(link.parentItemHash),
            originTraitName: Value(link.originTraitName),
            originTraitHash: Value(link.originTraitHash),
            armorSetName: Value(link.armorSetName),
            bonusPieces: Value(link.bonusPieces),
            bonusName: Value(link.bonusName),
            armorSetHash: Value(link.armorSetHash),
          ),
        );
  }
}

Future<List<SynergyWithLinks>> listSynergies(
  AppDatabase db,
  int userId, {
  String? type,
}) async {
  final query = db.select(db.synergies)..where((t) => t.userId.equals(userId));
  if (type != null) {
    query.where((t) => t.type.equals(type));
  }
  final rows = await query.get();
  return _rowsToSynergies(db, rows);
}

Future<SynergyWithLinks?> getSynergy(
  AppDatabase db,
  int userId,
  String id,
) async {
  final row = await (db.select(db.synergies)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  return SynergyWithLinks(
    record: _rowToSynergy(row),
    links: await _listLinks(db, row.id),
  );
}

Future<SynergyWithLinks> createSynergyRecord(
  AppDatabase db,
  int userId, {
  required String id,
  required String name,
  required String type,
  String? subType,
  String description = '',
  List<SynergyLinkInput> links = const [],
  required String now,
}) async {
  await db.into(db.synergies).insert(
        SynergiesCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          type: type,
          subType: Value(subType),
          description: Value(description),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await _insertLinks(db, id, links);
  return (await getSynergy(db, userId, id))!;
}

Future<SynergyWithLinks?> updateSynergyRecord(
  AppDatabase db,
  int userId,
  String id, {
  String? name,
  String? type,
  Value<String?> subType = const Value.absent(),
  String? description,
  List<SynergyLinkInput>? links,
  required String now,
}) async {
  final existing = await getSynergy(db, userId, id);
  if (existing == null) return null;

  await (db.update(db.synergies)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .write(
    SynergiesCompanion(
      name: Value(name ?? existing.name),
      type: Value(type ?? existing.type),
      subType: subType.present ? subType : Value(existing.subType),
      description: Value(description ?? existing.description),
      updatedAt: Value(now),
    ),
  );

  if (links != null) {
    await (db.delete(db.synergyLinks)..where((t) => t.synergyId.equals(id)))
        .go();
    await _insertLinks(db, id, links);
  }
  return getSynergy(db, userId, id);
}

Future<bool> deleteSynergyRecord(
  AppDatabase db,
  int userId,
  String id,
) async {
  final n = await (db.delete(db.synergies)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
  return n > 0;
}
