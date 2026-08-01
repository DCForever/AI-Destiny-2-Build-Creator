import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  group('clean create (US1)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('creates all core tables', () async {
      // Touch connection so migrations run.
      final tables = await db.listUserTableNames();
      for (final name in expectedCoreTables) {
        expect(tables, contains(name), reason: 'missing table $name');
      }
    });

    test('foreign_keys pragma is ON', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('FK rejects set_item with missing set_id', () async {
      await expectLater(
        db.into(db.setItems).insert(
              SetItemsCompanion.insert(
                id: 'si-1',
                setId: 'missing-set',
                slot: 'kinetic',
                itemHash: 1,
                itemName: 'Ghost',
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('critical uniques and indexes (US2)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertUser({
      String membershipId = 'm-1',
      int membershipType = 3,
    }) {
      return db.into(db.users).insert(
            UsersCompanion.insert(
              bungieMembershipId: membershipId,
              membershipType: membershipType,
            ),
          );
    }

    test('users.bungie_membership_id is unique', () async {
      await insertUser(membershipId: 'dup');
      await expectLater(
        insertUser(membershipId: 'dup'),
        throwsA(isA<Exception>()),
      );
    });

    test('inventory_items (user_id, instance_id) is unique', () async {
      final userId = await insertUser();
      await db.into(db.inventoryItems).insert(
            InventoryItemsCompanion.insert(
              userId: userId,
              instanceId: 'inst-1',
              itemHash: 100,
              bucket: 'kinetic',
              location: 'vault',
              syncedAt: '2026-01-01T00:00:00Z',
            ),
          );
      await expectLater(
        db.into(db.inventoryItems).insert(
              InventoryItemsCompanion.insert(
                userId: userId,
                instanceId: 'inst-1',
                itemHash: 200,
                bucket: 'energy',
                location: 'vault',
                syncedAt: '2026-01-01T00:00:00Z',
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('sets (user_id, type, name) is unique', () async {
      final userId = await insertUser();
      await db.into(db.sets).insert(
            SetsCompanion.insert(
              id: 'set-1',
              userId: userId,
              name: 'Solar Weapons',
              type: 'weapon',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await expectLater(
        db.into(db.sets).insert(
              SetsCompanion.insert(
                id: 'set-2',
                userId: userId,
                name: 'Solar Weapons',
                type: 'weapon',
                createdAt: 't1',
                updatedAt: 't1',
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('set_tags (set_id, tag_id) is unique', () async {
      final userId = await insertUser();
      await db.into(db.sets).insert(
            SetsCompanion.insert(
              id: 'set-tags',
              userId: userId,
              name: 'Tagged',
              type: 'armor',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await db.into(db.setTags).insert(
            SetTagsCompanion.insert(setId: 'set-tags', tagId: 'pve'),
          );
      await expectLater(
        db.into(db.setTags).insert(
              SetTagsCompanion.insert(setId: 'set-tags', tagId: 'pve'),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('build_tags and build_synergy_types uniques', () async {
      final userId = await insertUser();
      await db.into(db.builds).insert(
            BuildsCompanion.insert(
              id: 'b1',
              userId: userId,
              name: 'Build',
              className: 'Hunter',
              subclass: 'Nightstalker',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await db.into(db.buildTags).insert(
            BuildTagsCompanion.insert(buildId: 'b1', tagId: 'raid'),
          );
      await expectLater(
        db.into(db.buildTags).insert(
              BuildTagsCompanion.insert(buildId: 'b1', tagId: 'raid'),
            ),
        throwsA(isA<Exception>()),
      );

      await db.into(db.buildSynergyTypes).insert(
            BuildSynergyTypesCompanion.insert(
              buildId: 'b1',
              type: 'element',
              attachedAt: 't0',
              subType: const Value('solar'),
            ),
          );
      await expectLater(
        db.into(db.buildSynergyTypes).insert(
              BuildSynergyTypesCompanion.insert(
                buildId: 'b1',
                type: 'element',
                attachedAt: 't1',
                subType: const Value('solar'),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('supporting indexes exist with product names', () async {
      // Ensure schema created.
      await db.listUserTableNames();

      final inv = await db.listIndexNames('inventory_items');
      expect(inv, contains('idx_inventory_user_hash'));
      expect(inv, contains('idx_inventory_user_bucket'));
      expect(inv, contains('idx_inventory_user_location'));

      final setsIdx = await db.listIndexNames('sets');
      expect(setsIdx, contains(setsUserTypeNameIndex));

      final attachIdx = await db.listIndexNames('variant_set_attachments');
      expect(attachIdx, contains('idx_variant_attachments_set'));
    });

    test('variant_set_attachments RESTRICT blocks set delete', () async {
      final userId = await insertUser();
      await db.into(db.sets).insert(
            SetsCompanion.insert(
              id: 'set-r',
              userId: userId,
              name: 'Restricted',
              type: 'weapon',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await db.into(db.builds).insert(
            BuildsCompanion.insert(
              id: 'b-r',
              userId: userId,
              name: 'B',
              className: 'Titan',
              subclass: 'Sunbreaker',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await db.into(db.buildVariants).insert(
            BuildVariantsCompanion.insert(
              id: 'v-r',
              buildId: 'b-r',
              name: 'Default',
              createdAt: 't0',
              updatedAt: 't0',
            ),
          );
      await db.into(db.variantSetAttachments).insert(
            VariantSetAttachmentsCompanion.insert(
              id: 'a-r',
              variantId: 'v-r',
              setId: 'set-r',
              mode: 'live',
              attachedAt: 't0',
            ),
          );

      await expectLater(
        (db.delete(db.sets)..where((t) => t.id.equals('set-r'))).go(),
        throwsA(isA<Exception>()),
      );
    });

    test('schema_notes document critical uniques', () {
      expect(criticalUniqueNotes['inventory_items'], ['user_id', 'instance_id']);
      expect(criticalUniqueNotes['sets'], ['user_id', 'type', 'name']);
      expect(supportingIndexNotes.containsKey('idx_inventory_user_hash'), isTrue);
      expect(variantSetAttachmentRestrictNote, contains('RESTRICT'));
    });
  });

  group('file open (US3)', () {
    test('temp file create close reopen retains tables', () async {
      final dir = await Directory.systemTemp.createTemp('d2bc-db-');
      final path = '${dir.path}${Platform.pathSeparator}app.db';
      try {
        final first = AppDatabase.file(path);
        final tables1 = await first.listUserTableNames();
        expect(tables1, containsAll(expectedCoreTables));
        final userId = await first.into(first.users).insert(
              UsersCompanion.insert(
                bungieMembershipId: 'file-user',
                membershipType: 2,
              ),
            );
        expect(userId, greaterThan(0));
        await first.close();

        final second = AppDatabase.file(path);
        final tables2 = await second.listUserTableNames();
        expect(tables2, containsAll(expectedCoreTables));
        final users = await second.select(second.users).get();
        expect(users, hasLength(1));
        expect(users.single.bungieMembershipId, 'file-user');
        await second.close();
      } finally {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    });
  });
}
