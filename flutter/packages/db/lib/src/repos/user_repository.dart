import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

/// Minimal user insert for FK ownership (library CRUD / tests).
Future<int> insertUser(
  AppDatabase db, {
  required String bungieMembershipId,
  required int membershipType,
  String displayName = '',
  String? lastSyncAt,
}) {
  return db.into(db.users).insert(
        UsersCompanion.insert(
          bungieMembershipId: bungieMembershipId,
          membershipType: membershipType,
          displayName: Value(displayName),
          lastSyncAt: Value(lastSyncAt),
        ),
      );
}

/// Ensure a user row exists for [bungieMembershipId] (product `ensureUser`).
///
/// Updates membership type / display name when the row already exists.
Future<User> ensureUser(
  AppDatabase db, {
  required String bungieMembershipId,
  required int membershipType,
  String displayName = '',
}) async {
  final existing = await getUserByMembership(
    db,
    bungieMembershipId: bungieMembershipId,
  );
  if (existing != null) {
    if (existing.membershipType != membershipType ||
        existing.displayName != displayName) {
      await updateUserMembership(
        db,
        existing.id,
        membershipType: membershipType,
        displayName: displayName,
      );
      return (await getUser(db, existing.id))!;
    }
    return existing;
  }
  final id = await insertUser(
    db,
    bungieMembershipId: bungieMembershipId,
    membershipType: membershipType,
    displayName: displayName,
  );
  return (await getUser(db, id))!;
}

/// Update membership fields after Bungie profile resolve (DART-024).
Future<void> updateUserMembership(
  AppDatabase db,
  int userId, {
  required int membershipType,
  required String displayName,
}) {
  return (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          membershipType: Value(membershipType),
          displayName: Value(displayName),
        ),
      );
}

Future<User?> getUser(AppDatabase db, int id) {
  return (db.select(db.users)..where((t) => t.id.equals(id))).getSingleOrNull();
}

Future<User?> getUserByMembership(
  AppDatabase db, {
  required String bungieMembershipId,
}) {
  return (db.select(db.users)
        ..where((t) => t.bungieMembershipId.equals(bungieMembershipId)))
      .getSingleOrNull();
}
