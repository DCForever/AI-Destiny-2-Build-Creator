import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

import 'clock_ids.dart';
import 'errors.dart';
import 'mappers.dart';

/// Input for attaching a set to a variant.
class SetAttachmentInput {
  const SetAttachmentInput({
    required this.setId,
    required this.mode,
    this.snapshotConfigs,
  });

  final String setId;
  final AttachmentMode mode;
  final List<Map<String, Object?>>? snapshotConfigs;
}

AttachmentMode parseAttachmentModeWire(String wire) {
  final t = wire.trim();
  if (t == AttachmentMode.live.wireName) return AttachmentMode.live;
  if (t == AttachmentMode.snapshot.wireName) return AttachmentMode.snapshot;
  throw UseCaseException(
    UseCaseErrorCode.invalidAttachmentMode,
    'Invalid attachment mode: $wire',
    details: {'mode': wire},
  );
}

/// List attachments for a variant.
Future<List<AttachmentRecord>> getVariantAttachments(
  AppDatabase db,
  String variantId,
) {
  return listAttachments(db, variantId);
}

/// Domain map for attachment rows.
List<Attachment> mapAttachmentsDomain(List<AttachmentRecord> rows) =>
    rows.map(attachmentFromRecord).toList();

Future<List<Map<String, Object?>>> _buildSnapshotConfigs(
  AppDatabase db,
  String setId,
) async {
  final items = await listActiveSetItems(db, setId);
  return items.map(setItemRecordToSnapshotMap).toList();
}

/// Replace all attachments for [variantId] from [inputs].
///
/// Missing/unowned sets are skipped (product prepareAttachments parity).
/// At most one fashion set; snapshot freezes active items when configs omitted.
Future<List<AttachmentRecord>> prepareAttachments(
  AppDatabase db,
  int userId,
  String variantId,
  List<SetAttachmentInput> inputs, {
  NowClock now = defaultNow,
}) async {
  final prepared = <AttachmentWrite>[];
  var fashionCount = 0;

  for (final input in inputs) {
    final set = await getSet(db, userId, input.setId);
    if (set == null) continue;

    if (set.type == SetType.fashion.wireName) {
      fashionCount += 1;
      if (fashionCount > 1) {
        throw UseCaseException(
          UseCaseErrorCode.fashionLimit,
          'Variant may attach at most one fashion set',
          details: {'setId': input.setId},
        );
      }
    }

    List<Map<String, Object?>>? snapshotConfigs;
    if (input.mode == AttachmentMode.snapshot) {
      snapshotConfigs = input.snapshotConfigs ??
          await _buildSnapshotConfigs(db, input.setId);
    }

    prepared.add(
      AttachmentWrite(
        setId: input.setId,
        mode: input.mode.wireName,
        snapshotConfigs: snapshotConfigs,
      ),
    );
  }

  return replaceAttachments(db, variantId, prepared, now());
}

/// Detach any attachments whose set type matches [type], then live-attach
/// [newSetId]. Other set types on the variant are preserved.
Future<List<AttachmentRecord>> replaceAttachmentByType(
  AppDatabase db,
  int userId,
  String variantId,
  SetType type,
  String newSetId, {
  NowClock now = defaultNow,
}) async {
  final newSet = await getSet(db, userId, newSetId);
  if (newSet == null || newSet.type != type.wireName) {
    throw UseCaseException(
      UseCaseErrorCode.setTypeMismatch,
      'Set $newSetId is not a ${type.wireName} set for this user',
      details: {
        'setId': newSetId,
        'expectedType': type.wireName,
        'actualType': newSet?.type,
      },
    );
  }

  final existing = await listAttachments(db, variantId);
  final kept = <AttachmentWrite>[];

  for (final att in existing) {
    final set = await getSet(db, userId, att.setId);
    if (set == null) continue;
    if (set.type == type.wireName) continue;
    kept.add(
      AttachmentWrite(
        id: att.id,
        setId: att.setId,
        mode: att.mode,
        snapshotConfigs: att.snapshotConfigs,
      ),
    );
  }

  kept.add(
    AttachmentWrite(
      setId: newSetId,
      mode: AttachmentMode.live.wireName,
    ),
  );

  return replaceAttachments(db, variantId, kept, now());
}
