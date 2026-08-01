import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  const later = '2026-07-24T13:00:00.000Z';
  final clock = fixedNow(now);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-att',
        membershipType: 3,
        displayName: 'Tester',
      );

  Future<({int userId, String variantId})> seedBuildVariant() async {
    final userId = await seedUser();
    await createBuildRecord(
      db,
      userId,
      id: 'b1',
      name: 'Build',
      className: 'Hunter',
      now: now,
    );
    await createVariantRecord(
      db,
      id: 'v1',
      buildId: 'b1',
      name: 'Default',
      isDefault: true,
      now: now,
    );
    return (userId: userId, variantId: 'v1');
  }

  group('US3 attach', () {
    test('prepareAttachments live for armor + mod', () async {
      final ctx = await seedBuildVariant();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'armor1', name: 'Armor', type: SetType.armor),
        now: clock,
      );
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'mod1', name: 'Mods', type: SetType.mod),
        now: clock,
      );

      final atts = await prepareAttachments(
        db,
        ctx.userId,
        ctx.variantId,
        const [
          SetAttachmentInput(setId: 'armor1', mode: AttachmentMode.live),
          SetAttachmentInput(setId: 'mod1', mode: AttachmentMode.live),
        ],
        now: clock,
      );

      expect(atts, hasLength(2));
      expect(atts.map((a) => a.setId).toSet(), {'armor1', 'mod1'});
      final domain = mapAttachmentsDomain(atts);
      expect(domain.every((a) => a.mode == AttachmentMode.live), isTrue);
    });

    test('snapshot freezes active items when configs omitted', () async {
      final ctx = await seedBuildVariant();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'armor1', name: 'Armor', type: SetType.armor),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        ctx.userId,
        'armor1',
        const UpsertSetItemCommand(
          id: 'si1',
          slot: 'helmet',
          itemHash: 42,
          itemName: 'Helm',
          selectedPerks: [7, 8],
        ),
        now: clock,
      );

      final atts = await prepareAttachments(
        db,
        ctx.userId,
        ctx.variantId,
        const [
          SetAttachmentInput(setId: 'armor1', mode: AttachmentMode.snapshot),
        ],
        now: clock,
      );

      expect(atts, hasLength(1));
      expect(atts.single.mode, 'snapshot');
      expect(atts.single.snapshotConfigs, isNotNull);
      expect(atts.single.snapshotConfigs, hasLength(1));
      expect(atts.single.snapshotConfigs!.single['itemHash'], 42);
      expect(atts.single.snapshotConfigs!.single['slot'], 'helmet');
    });

    test('second fashion throws fashion limit', () async {
      final ctx = await seedBuildVariant();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'f1', name: 'F1', type: SetType.fashion),
        now: clock,
      );
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'f2', name: 'F2', type: SetType.fashion),
        now: clock,
      );

      expect(
        () => prepareAttachments(
          db,
          ctx.userId,
          ctx.variantId,
          const [
            SetAttachmentInput(setId: 'f1', mode: AttachmentMode.live),
            SetAttachmentInput(setId: 'f2', mode: AttachmentMode.live),
          ],
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.fashionLimit,
          ),
        ),
      );

      // Validation fails before write — no partial fashion pair.
      expect(await getVariantAttachments(db, ctx.variantId), isEmpty);
    });

    test('replaceAttachmentByType swaps armor keeps weapon', () async {
      final ctx = await seedBuildVariant();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'armor1', name: 'A1', type: SetType.armor),
        now: clock,
      );
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'armor2', name: 'A2', type: SetType.armor),
        now: clock,
      );
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'w1', name: 'W1', type: SetType.weapon),
        now: clock,
      );

      await prepareAttachments(
        db,
        ctx.userId,
        ctx.variantId,
        const [
          SetAttachmentInput(setId: 'armor1', mode: AttachmentMode.live),
          SetAttachmentInput(setId: 'w1', mode: AttachmentMode.live),
        ],
        now: clock,
      );

      final after = await replaceAttachmentByType(
        db,
        ctx.userId,
        ctx.variantId,
        SetType.armor,
        'armor2',
        now: fixedNow(later),
      );

      expect(after.map((a) => a.setId).toSet(), {'armor2', 'w1'});
      final armorAtt = after.firstWhere((a) => a.setId == 'armor2');
      expect(armorAtt.mode, 'live');
    });

    test('invalid mode wire', () {
      expect(
        () => parseAttachmentModeWire('banana'),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidAttachmentMode,
          ),
        ),
      );
    });

    test('replaceAttachmentByType type mismatch', () async {
      final ctx = await seedBuildVariant();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'w1', name: 'W', type: SetType.weapon),
        now: clock,
      );

      expect(
        () => replaceAttachmentByType(
          db,
          ctx.userId,
          ctx.variantId,
          SetType.armor,
          'w1',
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.setTypeMismatch,
          ),
        ),
      );
    });
  });
}
