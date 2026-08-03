import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  const melee = SynergyTypeDesignation(
    type: SynergyType('melee'),
    subType: 'Base',
  );
  const grenade = SynergyTypeDesignation(
    type: SynergyType('grenade'),
  );

  group('detectIdentityFieldChanges', () {
    test('empty when only name-like fields omitted', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: null,
        existingExoticArmorHash: 1,
        nextExoticArmorHash: 1,
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: 'Golden Gun',
        nextPinnedSuper: 'Golden Gun',
        existingSubclass: const SubclassKit(name: 'Gunslinger'),
      );
      expect(fields, isEmpty);
    });

    test('synergyTypes change', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: [grenade],
        existingExoticArmorHash: null,
        nextExoticArmorHash: null,
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: null,
        nextPinnedSuper: null,
        existingSubclass: const SubclassKit(),
      );
      expect(fields, contains('synergyTypes'));
    });

    test('class-item to class-item exotic is not identity', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: null,
        existingExoticArmorHash: 10,
        nextExoticArmorHash: 20,
        setExoticArmor: true,
        existingExoticArmorSlot: 'ClassItem',
        nextExoticArmorSlot: 'ClassItem',
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: null,
        nextPinnedSuper: null,
        existingSubclass: const SubclassKit(),
      );
      expect(fields, isNot(contains('exoticArmorHash')));
    });

    test('classic exotic armor change is identity', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: null,
        existingExoticArmorHash: 10,
        nextExoticArmorHash: 20,
        setExoticArmor: true,
        existingExoticArmorSlot: 'Helmet',
        nextExoticArmorSlot: 'Helmet',
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: null,
        nextPinnedSuper: null,
        existingSubclass: const SubclassKit(),
      );
      expect(fields, contains('exoticArmorHash'));
    });

    test('subclass tree rename is identity (DBR-ID-008a)', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: null,
        existingExoticArmorHash: null,
        nextExoticArmorHash: null,
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: null,
        nextPinnedSuper: null,
        existingSubclass: const SubclassKit(name: 'Gunslinger', aspects: ['A']),
        nextSubclass: const SubclassKit(name: 'Arcstrider', aspects: ['A']),
      );
      expect(fields, contains('subclass'));
    });

    test('kit-only subclass diffs are not identity (DBR-ID-008b/010)', () {
      final fields = detectIdentityFieldChanges(
        existingSynergyTypes: [melee],
        nextSynergyTypes: null,
        existingExoticArmorHash: null,
        nextExoticArmorHash: null,
        existingExoticWeaponHash: null,
        nextExoticWeaponHash: null,
        existingPinnedSuper: null,
        nextPinnedSuper: null,
        existingSubclass: const SubclassKit(name: 'Gunslinger', aspects: ['A']),
        nextSubclass: const SubclassKit(
          name: 'Gunslinger',
          aspects: ['A', 'B'],
          fragments: ['F1'],
          superAbility: 'Golden Gun',
        ),
      );
      expect(fields, isEmpty);
      expect(fields, isNot(contains('subclass')));
    });
  });

  group('compose hard blocks', () {
    test('dual exotic armor hard-blocks', () {
      final blocks = evaluateComposeHardBlocks(
        const ComposeHardBlockInput(
          exoticArmorHashes: [1, 2],
          synergyTypeCount: 1,
        ),
      );
      expect(blocks.any((b) => b.code == DomainFailureCodes.tooManyExotics), isTrue);
      expect(composeSaveHardBlocked(blocks), isTrue);
    });

    test('illegal aspects hard-block', () {
      final blocks = evaluateComposeHardBlocks(
        const ComposeHardBlockInput(
          aspectCount: 3,
          fragmentCount: 0,
          fragmentCapacity: 4,
          capacityResolved: true,
          synergyTypeCount: 1,
        ),
      );
      expect(
        blocks.any((b) => b.code == DomainFailureCodes.illegalSubclassKit),
        isTrue,
      );
    });

    test('soft path not represented in hard blocks', () {
      final blocks = evaluateComposeHardBlocks(
        const ComposeHardBlockInput(synergyTypeCount: 1),
      );
      expect(blocks, isEmpty);
      expect(composeSaveHardBlocked(blocks), isFalse);
    });

    test('capacity caption plain language', () {
      final over = formatSubclassCapacityCaption(
        aspectCount: 2,
        fragmentCount: 5,
        fragmentCapacity: 4,
        capacityResolved: true,
      );
      expect(over, contains('too many fragments'));
      final unknown = formatSubclassCapacityCaption(
        aspectCount: 1,
        fragmentCount: 2,
        fragmentCapacity: 0,
        capacityResolved: false,
      );
      expect(unknown, contains('unknown'));
    });
  });
}
