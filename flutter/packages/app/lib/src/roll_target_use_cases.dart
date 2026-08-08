/// Catalog weapon roll target use cases (DART-073).
///
/// Soft scores only — never auto-applies; distinct from equip-ready wishlist.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';

import 'clock_ids.dart';

/// Map DB column records → domain columns.
List<RollTargetColumn> domainColumnsFromRecords(
  List<RollTargetColumnRecord> columns,
) {
  return [
    for (final c in columns)
      RollTargetColumn(
        columnKey: c.columnKey,
        label: c.label,
        preferredPlugHashes: c.preferredPlugHashes.toSet(),
        avoidPlugHashes: c.avoidPlugHashes.toSet(),
      ),
  ];
}

/// Map domain columns → DB records.
List<RollTargetColumnRecord> recordsFromDomainColumns(
  List<RollTargetColumn> columns,
) {
  return [
    for (final c in columns)
      RollTargetColumnRecord(
        columnKey: c.columnKey,
        label: c.label,
        preferredPlugHashes: c.preferredPlugHashes.toList()..sort(),
        avoidPlugHashes: c.avoidPlugHashes.toList()..sort(),
      ),
  ];
}

/// Map [RollTargetRecord] → domain [WeaponRollTarget].
WeaponRollTarget toDomainRollTarget(RollTargetRecord r) {
  return WeaponRollTarget(
    id: r.id,
    userId: r.userId.toString(),
    weaponKey: r.weaponKey,
    name: r.name,
    columns: domainColumnsFromRecords(r.columns),
    updatedAtMs: DateTime.tryParse(r.updatedAt)?.millisecondsSinceEpoch,
  );
}

/// Validate domain shape then create persisted target.
///
/// [isExotic] true rejects create (DBR-IDL-009 — fixed exotic perks).
Future<WeaponRollTarget> createWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String weaponKey,
  required String name,
  List<RollTargetColumn> columns = const [],
  String? id,
  String? nowIso,
  bool isExotic = false,
}) async {
  final targetId = id ?? defaultNewId();
  final now = nowIso ?? defaultNow();
  final domain = WeaponRollTarget(
    id: targetId,
    userId: userId.toString(),
    weaponKey: weaponKey,
    name: name.trim(),
    columns: columns,
  );
  validateRollTarget(domain, isExotic: isExotic);
  final record = await createRollTarget(
    db,
    userId,
    id: targetId,
    weaponKey: weaponKey,
    name: name,
    columns: recordsFromDomainColumns(columns),
    now: now,
  );
  return toDomainRollTarget(record);
}

Future<WeaponRollTarget?> updateWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String id,
  String? name,
  List<RollTargetColumn>? columns,
  String? nowIso,
  bool isExotic = false,
}) async {
  final now = nowIso ?? defaultNow();
  if (isExotic) {
    assertRollTargetsAllowedForWeapon(isExotic: true);
  }
  if (columns != null) {
    validateRollTarget(
      WeaponRollTarget(
        id: id,
        userId: userId.toString(),
        weaponKey: '',
        name: name ?? 'x',
        columns: columns,
      ),
      isExotic: isExotic,
    );
  }
  final record = await updateRollTarget(
    db,
    userId,
    id,
    name: name,
    columns: columns == null ? null : recordsFromDomainColumns(columns),
    now: now,
  );
  if (record == null) return null;
  return toDomainRollTarget(record);
}

Future<bool> deleteWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String id,
}) {
  return deleteRollTarget(db, userId, id);
}

Future<List<WeaponRollTarget>> listWeaponRollTargets(
  AppDatabase db, {
  required int userId,
  String? weaponKey,
}) async {
  final rows = await listRollTargets(db, userId, weaponKey: weaponKey);
  return rows.map(toDomainRollTarget).toList();
}

Future<WeaponRollTarget?> getWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String id,
}) async {
  final row = await getRollTarget(db, userId, id);
  if (row == null) return null;
  return toDomainRollTarget(row);
}

Future<void> setActiveWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String weaponKey,
  required String? targetId,
  String? nowIso,
}) {
  return setActiveRollTarget(
    db,
    userId,
    weaponKey,
    targetId: targetId,
    now: nowIso ?? defaultNow(),
  );
}

Future<WeaponRollTarget?> getActiveWeaponRollTarget(
  AppDatabase db, {
  required int userId,
  required String weaponKey,
}) async {
  final row = await getActiveRollTarget(db, userId, weaponKey);
  if (row == null) return null;
  return toDomainRollTarget(row);
}

/// Score and rank owned instances for a domain target (pure, no DB).
List<RankedRollTargetInstance> rankOwnedForRollTarget(
  WeaponRollTarget target,
  List<RollTargetInstanceInput> instances, {
  PlugFamilyLookup? familyOf,
}) {
  return rankOwnedAgainstTarget(target, instances, familyOf: familyOf);
}
