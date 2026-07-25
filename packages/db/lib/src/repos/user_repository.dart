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
