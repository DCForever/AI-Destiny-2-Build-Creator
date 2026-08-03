import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('v');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-var',
        membershipType: 3,
        displayName: 'Tester',
      );

  const meleeDesig = SynergyTypeDesignation(
    type: SynergyType('melee'),
    subType: 'Base',
  );

  Future<({int userId, String buildId, String defaultVariantId})>
      seedBuild() async {
    final userId = await seedUser();
    final detail = await createUserBuild(
      db,
      userId,
      const CreateBuildCommand(
        id: 'b-var',
        name: 'Variant Build',
        className: GuardianClass.hunter,
        subclass: SubclassKit(name: 'Arcstrider'),
        synergyTypes: [meleeDesig],
      ),
      now: clock,
      newId: ids,
    );
    return (
      userId: userId,
      buildId: detail.build.id,
      defaultVariantId: detail.variants.single.id,
    );
  }

  /// Seeds a weapon set that meets package min (≥2 items) while keeping [slot].
  Future<void> seedWeaponSet(
    int userId,
    String setId,
    String slot,
    int hash,
  ) async {
    await createUserSet(
      db,
      userId,
      CreateSetCommand(id: setId, name: setId, type: SetType.weapon),
      now: clock,
    );
    await upsertUserSetItem(
      db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item',
        slot: slot,
        itemHash: hash,
        itemName: 'Item $hash',
      ),
      now: clock,
    );
    // DBR-CMP-008 / BR-ATT-006: attach requires ≥2 filled domain slots.
    final secondSlot = slot == 'special' ? 'heavy' : 'special';
    await upsertUserSetItem(
      db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item-2',
        slot: secondSlot,
        itemHash: hash + 1000,
        itemName: 'Item ${hash + 1000}',
      ),
      now: clock,
    );
  }

  group('pkg-variant-subclass-kit', () {
    test('two variants keep independent kits under one tree', () async {
      final ctx = await seedBuild();
      // Default seeded from create may be empty pieces; set kit A.
      await updateUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        ctx.defaultVariantId,
        const UpdateVariantCommand(
          setSubclassKit: true,
          subclassKit: SubclassKit(
            aspects: ['Flow State'],
            superAbility: 'Arc Staff',
            melee: 'Combination Blow',
          ),
        ),
        now: clock,
      );
      final alt = await createUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        const CreateVariantCommand(
          id: 'v-kit-b',
          name: 'Alt kit',
          subclassKit: SubclassKit(
            aspects: ['Tempest Strike'],
            superAbility: "Storm's Edge",
            grenade: 'Skip Grenade',
          ),
        ),
        now: clock,
      );
      expect(alt, isNotNull);

      final build = await getBuild(db, ctx.userId, ctx.buildId);
      final def = await getVariant(db, ctx.buildId, ctx.defaultVariantId);
      final other = await getVariant(db, ctx.buildId, 'v-kit-b');
      expect(build, isNotNull);
      expect(def, isNotNull);
      expect(other, isNotNull);

      final treeName = subclassKitFromJson(build!.subclass).name;
      expect(treeName, 'Arcstrider');

      final effectiveA = loadEffectiveSubclassKit(
        buildSubclass: build.subclass,
        variantSubclassKit: def!.subclassKit,
        pinnedSuper: build.pinnedSuper,
      );
      final effectiveB = loadEffectiveSubclassKit(
        buildSubclass: build.subclass,
        variantSubclassKit: other!.subclassKit,
        pinnedSuper: build.pinnedSuper,
      );
      expect(effectiveA.name, 'Arcstrider');
      expect(effectiveB.name, 'Arcstrider');
      expect(effectiveA.aspects, ['Flow State']);
      expect(effectiveB.aspects, ['Tempest Strike']);
      expect(effectiveA.superAbility, 'Arc Staff');
      expect(effectiveB.superAbility, "Storm's Edge");
    });

    test('illegal kit hard-blocks without touching identity', () async {
      final ctx = await seedBuild();
      await expectLater(
        () => updateUserVariant(
          db,
          ctx.userId,
          ctx.buildId,
          ctx.defaultVariantId,
          const UpdateVariantCommand(
            setSubclassKit: true,
            subclassKit: SubclassKit(aspects: ['A', 'B', 'C']),
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.illegalSubclassKit,
          ),
        ),
      );
    });

    test('kit save does not require identity confirm', () async {
      final ctx = await seedBuild();
      final updated = await updateUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        ctx.defaultVariantId,
        const UpdateVariantCommand(
          setSubclassKit: true,
          subclassKit: SubclassKit(aspects: ['Flow State']),
        ),
        now: clock,
      );
      expect(updated, isNotNull);
      final kit = subclassKitFromJson(updated!.subclassKit);
      expect(kit.aspects, ['Flow State']);
    });
  });

  group('US2 variant equipment hard gates', () {
    test('non-default name-only update succeeds without full combat', () async {
      final ctx = await seedBuild();
      final alt = await createUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        const CreateVariantCommand(id: 'v-alt', name: 'Alt'),
        now: clock,
      );
      expect(alt, isNotNull);

      final updated = await updateUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        'v-alt',
        const UpdateVariantCommand(name: 'Alt Renamed'),
        now: clock,
      );
      expect(updated!.name, 'Alt Renamed');
    });

    test('slot conflict hard-blocks and rolls back attachments', () async {
      final ctx = await seedBuild();
      await seedWeaponSet(ctx.userId, 'w1', 'primary', 100);
      await seedWeaponSet(ctx.userId, 'w2', 'primary', 200);

      final alt = await createUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        const CreateVariantCommand(id: 'v-conflict', name: 'Conflict'),
        now: clock,
      );
      expect(alt, isNotNull);

      await expectLater(
        () => updateUserVariant(
          db,
          ctx.userId,
          ctx.buildId,
          'v-conflict',
          const UpdateVariantCommand(
            attachments: [
              SetAttachmentInput(setId: 'w1', mode: AttachmentMode.live),
              SetAttachmentInput(setId: 'w2', mode: AttachmentMode.live),
            ],
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.slotConflict,
          ),
        ),
      );

      final atts = await getVariantAttachments(db, 'v-conflict');
      expect(atts, isEmpty);
    });

    test('TOO_MANY_EXOTICS hard-blocks via classifier', () async {
      final ctx = await seedBuild();
      await createUserSet(
        db,
        ctx.userId,
        const CreateSetCommand(id: 'armor', name: 'Armor', type: SetType.armor),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        ctx.userId,
        'armor',
        const UpsertSetItemCommand(
          id: 'a1',
          slot: 'helmet',
          itemHash: 501,
          itemName: 'Exotic Helm A',
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        ctx.userId,
        'armor',
        const UpsertSetItemCommand(
          id: 'a2',
          slot: 'arms',
          itemHash: 502,
          itemName: 'Exotic Arms B',
        ),
        now: clock,
      );

      final ports = HardGatePorts(
        classifyExoticComposition: exoticCompositionFromHashSets(
          exoticArmor: {501, 502},
        ),
      );

      final alt = await createUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        const CreateVariantCommand(id: 'v-exo', name: 'Exotics'),
        now: clock,
      );
      expect(alt, isNotNull);

      await expectLater(
        () => updateUserVariant(
          db,
          ctx.userId,
          ctx.buildId,
          'v-exo',
          const UpdateVariantCommand(
            attachments: [
              SetAttachmentInput(setId: 'armor', mode: AttachmentMode.live),
            ],
          ),
          now: clock,
          ports: ports,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.tooManyExotics,
          ),
        ),
      );
    });

    test('default partial attachments → DEFAULT_VARIANT_INCOMPLETE', () async {
      final ctx = await seedBuild();
      await seedWeaponSet(ctx.userId, 'w-only', 'primary', 111);

      await expectLater(
        () => updateUserVariant(
          db,
          ctx.userId,
          ctx.buildId,
          ctx.defaultVariantId,
          const UpdateVariantCommand(
            attachments: [
              SetAttachmentInput(setId: 'w-only', mode: AttachmentMode.live),
            ],
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.defaultVariantIncomplete,
          ),
        ),
      );

      final atts = await getVariantAttachments(db, ctx.defaultVariantId);
      expect(atts, isEmpty);
    });

    test('non-default partial attachments save succeeds', () async {
      final ctx = await seedBuild();
      await seedWeaponSet(ctx.userId, 'w-partial', 'primary', 222);
      final alt = await createUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        const CreateVariantCommand(id: 'v-partial', name: 'Partial'),
        now: clock,
      );
      expect(alt, isNotNull);

      final updated = await updateUserVariant(
        db,
        ctx.userId,
        ctx.buildId,
        'v-partial',
        const UpdateVariantCommand(
          attachments: [
            SetAttachmentInput(setId: 'w-partial', mode: AttachmentMode.live),
          ],
        ),
        now: clock,
      );
      expect(updated, isNotNull);
      final atts = await getVariantAttachments(db, 'v-partial');
      expect(atts, hasLength(1));
      expect(atts.single.setId, 'w-partial');
    });
  });
}
