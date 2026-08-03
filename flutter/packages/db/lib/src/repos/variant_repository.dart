import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'json_codec.dart';
import 'library_records.dart';

VariantRecord _rowToVariant(BuildVariant row) {
  return VariantRecord(
    id: row.id,
    buildId: row.buildId,
    name: row.name,
    isDefault: row.isDefault == 1,
    exoticWeaponHash: row.exoticWeaponHash,
    exoticWeaponName: row.exoticWeaponName,
    artifactHash: row.artifactHash,
    artifactName: row.artifactName,
    artifactConfig: parseIntJsonArray(row.artifactConfig),
    subclassKit: decodeJsonValue(row.subclassKit),
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

AttachmentRecord _rowToAttachment(VariantSetAttachment row) {
  return AttachmentRecord(
    id: row.id,
    variantId: row.variantId,
    setId: row.setId,
    mode: row.mode,
    snapshotConfigs: parseSnapshotConfigsJson(row.snapshotConfigs),
    attachedAt: row.attachedAt,
  );
}

Future<List<VariantRecord>> listVariants(
  AppDatabase db,
  String buildId,
) async {
  final rows = await (db.select(db.buildVariants)
        ..where((t) => t.buildId.equals(buildId)))
      .get();
  return rows.map(_rowToVariant).toList();
}

Future<VariantRecord?> getVariant(
  AppDatabase db,
  String buildId,
  String variantId,
) async {
  final row = await (db.select(db.buildVariants)
        ..where(
          (t) => t.id.equals(variantId) & t.buildId.equals(buildId),
        ))
      .getSingleOrNull();
  return row == null ? null : _rowToVariant(row);
}

Future<VariantRecord> createVariantRecord(
  AppDatabase db, {
  required String id,
  required String buildId,
  required String name,
  bool isDefault = false,
  int? exoticWeaponHash,
  String? exoticWeaponName,
  int? artifactHash,
  String? artifactName,
  List<int> artifactConfig = const [],
  Object? subclassKit,
  String? notes,
  required String now,
}) async {
  await db.into(db.buildVariants).insert(
        BuildVariantsCompanion.insert(
          id: id,
          buildId: buildId,
          name: name,
          isDefault: Value(isDefault ? 1 : 0),
          exoticWeaponHash: Value(exoticWeaponHash),
          exoticWeaponName: Value(exoticWeaponName),
          artifactHash: Value(artifactHash),
          artifactName: Value(artifactName),
          artifactConfig: Value(encodeIntJsonArray(artifactConfig)),
          subclassKit: Value(encodeJsonValue(subclassKit ?? const <String, Object?>{})),
          notes: Value(notes),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return (await getVariant(db, buildId, id))!;
}

Future<VariantRecord?> updateVariantRecord(
  AppDatabase db,
  String buildId,
  String variantId, {
  String? name,
  Value<int?> exoticWeaponHash = const Value.absent(),
  Value<String?> exoticWeaponName = const Value.absent(),
  Value<int?> artifactHash = const Value.absent(),
  Value<String?> artifactName = const Value.absent(),
  List<int>? artifactConfig,
  Value<Object?> subclassKit = const Value.absent(),
  Value<String?> notes = const Value.absent(),
  required String now,
}) async {
  final existing = await getVariant(db, buildId, variantId);
  if (existing == null) return null;

  await (db.update(db.buildVariants)
        ..where(
          (t) => t.id.equals(variantId) & t.buildId.equals(buildId),
        ))
      .write(
    BuildVariantsCompanion(
      name: Value(name ?? existing.name),
      exoticWeaponHash: exoticWeaponHash.present
          ? exoticWeaponHash
          : Value(existing.exoticWeaponHash),
      exoticWeaponName: exoticWeaponName.present
          ? exoticWeaponName
          : Value(existing.exoticWeaponName),
      artifactHash:
          artifactHash.present ? artifactHash : Value(existing.artifactHash),
      artifactName:
          artifactName.present ? artifactName : Value(existing.artifactName),
      artifactConfig: Value(
        encodeIntJsonArray(artifactConfig ?? existing.artifactConfig),
      ),
      subclassKit: subclassKit.present
          ? Value(encodeJsonValue(subclassKit.value ?? const <String, Object?>{}))
          : Value(encodeJsonValue(existing.subclassKit ?? const <String, Object?>{})),
      notes: notes.present ? notes : Value(existing.notes),
      updatedAt: Value(now),
    ),
  );
  return getVariant(db, buildId, variantId);
}

Future<bool> deleteVariantRecord(
  AppDatabase db,
  String buildId,
  String variantId,
) async {
  final n = await (db.delete(db.buildVariants)
        ..where(
          (t) => t.id.equals(variantId) & t.buildId.equals(buildId),
        ))
      .go();
  return n > 0;
}

Future<List<AttachmentRecord>> listAttachments(
  AppDatabase db,
  String variantId,
) async {
  final rows = await (db.select(db.variantSetAttachments)
        ..where((t) => t.variantId.equals(variantId)))
      .get();
  return rows.map(_rowToAttachment).toList();
}

/// Replace all attachments for [variantId] with [attachments].
///
/// When [AttachmentWrite.id] is omitted, allocates `$variantId-att-N` that
/// does not collide with ids already claimed by sibling writes (BUG-20260726-016:
/// re-attach replace-by-type kept `…-att-0` while the new row also got `…-att-0`).
Future<List<AttachmentRecord>> replaceAttachments(
  AppDatabase db,
  String variantId,
  List<AttachmentWrite> attachments,
  String now,
) async {
  await (db.delete(db.variantSetAttachments)
        ..where((t) => t.variantId.equals(variantId)))
      .go();

  final usedIds = <String>{
    for (final a in attachments)
      if (a.id != null && a.id!.isNotEmpty) a.id!,
  };
  var nextIndex = 0;
  String allocateId() {
    String candidate;
    do {
      candidate = '$variantId-att-${nextIndex++}';
    } while (usedIds.contains(candidate));
    usedIds.add(candidate);
    return candidate;
  }

  for (final a in attachments) {
    final id = (a.id != null && a.id!.isNotEmpty) ? a.id! : allocateId();
    await db.into(db.variantSetAttachments).insert(
          VariantSetAttachmentsCompanion.insert(
            id: id,
            variantId: variantId,
            setId: a.setId,
            mode: a.mode,
            snapshotConfigs: Value(encodeSnapshotConfigsJson(a.snapshotConfigs)),
            attachedAt: now,
          ),
        );
  }
  return listAttachments(db, variantId);
}

/// Input for [replaceAttachments].
class AttachmentWrite {
  const AttachmentWrite({
    this.id,
    required this.setId,
    required this.mode,
    this.snapshotConfigs,
  });

  final String? id;
  final String setId;
  final String mode;
  final List<Map<String, Object?>>? snapshotConfigs;
}
