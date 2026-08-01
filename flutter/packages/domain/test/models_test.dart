import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('EquipmentSlot wire names', () {
    test('match TypeScript EquipmentSlot strings', () {
      expect(EquipmentSlot.primary.wireName, 'primary');
      expect(EquipmentSlot.special.wireName, 'special');
      expect(EquipmentSlot.heavy.wireName, 'heavy');
      expect(EquipmentSlot.helmet.wireName, 'helmet');
      expect(EquipmentSlot.arms.wireName, 'arms');
      expect(EquipmentSlot.chest.wireName, 'chest');
      expect(EquipmentSlot.legs.wireName, 'legs');
      expect(EquipmentSlot.classItem.wireName, 'class_item');
      expect(EquipmentSlot.exoticWeapon.wireName, 'exotic_weapon');
      expect(EquipmentSlot.exoticArmor.wireName, 'exotic_armor');
      expect(EquipmentSlot.tryParse('class_item'), EquipmentSlot.classItem);
      expect(EquipmentSlot.combatSlots, hasLength(8));
    });

    test('SetType wire names match product schemas', () {
      expect(
        SetType.values.map((e) => e.wireName).toList(),
        ['weapon', 'armor', 'mod', 'pair', 'fashion'],
      );
    });
  });

  group('SlotClaim & ResolvedVariantEquipment', () {
    test('constructs immutable claim with optional pin fields', () {
      const claim = SlotClaim(
        slot: EquipmentSlot.helmet,
        itemHash: 42,
        itemName: 'Helm of Example',
        source: ClaimSource.set,
        setId: 'set-1',
        selectedPerks: [1, 2],
        instanceId: null,
      );
      expect(claim.slot.wireName, 'helmet');
      expect(claim.itemHash, 42);
      expect(claim.source.wireName, 'set');
      expect(claim.instanceId, isNull);
      expect(
        claim,
        const SlotClaim(
          slot: EquipmentSlot.helmet,
          itemHash: 42,
          itemName: 'Helm of Example',
          source: ClaimSource.set,
          setId: 'set-1',
          selectedPerks: [1, 2],
        ),
      );
    });

    test('ExpandedSetItem.toSlotClaim maps pair source', () {
      const item = ExpandedSetItem(
        slot: EquipmentSlot.exoticArmor,
        itemHash: 9,
        itemName: 'Cuirass',
        setId: 'pair-1',
        setType: SetType.pair,
      );
      final claim = item.toSlotClaim();
      expect(claim.source, ClaimSource.pairSet);
      expect(claim.source.wireName, 'pair_set');
    });

    test('ResolvedVariantEquipment holds map and conflicts', () {
      const a = SlotClaim(
        slot: EquipmentSlot.primary,
        itemHash: 1,
        itemName: 'A',
        source: ClaimSource.set,
        setId: 's1',
      );
      const b = SlotClaim(
        slot: EquipmentSlot.primary,
        itemHash: 2,
        itemName: 'B',
        source: ClaimSource.variantExoticWeapon,
      );
      const resolved = ResolvedVariantEquipment(
        equipment: {EquipmentSlot.primary: a},
        conflicts: [
          SlotConflict(slot: EquipmentSlot.primary, claimants: [a, b]),
        ],
      );
      expect(resolved.hasConflicts, isTrue);
      expect(resolved.claimFor(EquipmentSlot.primary), a);
      expect(resolved.conflicts.single.claimants, hasLength(2));
    });
  });

  group('Pins', () {
    test('PinStatus kinds and EquipReadyResult shape', () {
      const wishlist = PinStatus(
        slot: EquipmentSlot.chest,
        status: PinStatusKind.wishlist,
      );
      const pinned = PinStatus(
        slot: EquipmentSlot.helmet,
        status: PinStatusKind.pinned,
        instanceId: 'inst-1',
      );
      const stale = PinStatus(
        slot: EquipmentSlot.arms,
        status: PinStatusKind.stale,
        instanceId: 'gone',
        reason: PinStaleReason.instanceMissing,
      );
      expect(wishlist.status.wireName, 'wishlist');
      expect(pinned.status.wireName, 'pinned');
      expect(stale.reason!.wireName, 'instance_missing');
      expect(PinStaleReason.hashMismatch.wireName, 'hash_mismatch');

      const ready = EquipReadyResult(
        equipReady: true,
        pinStatuses: [pinned],
      );
      const notReady = EquipReadyResult(
        equipReady: false,
        pinStatuses: [wishlist, stale],
      );
      expect(ready.equipReady, isTrue);
      expect(notReady.equipReady, isFalse);
      expect(notReady.pinStatuses, hasLength(2));
    });
  });

  group('Failure codes & constraints', () {
    test('pure hard-gate codes match TypeScript strings', () {
      expect(DomainFailureCodes.tooManyExotics, 'TOO_MANY_EXOTICS');
      expect(DomainFailureCodes.illegalSubclassKit, 'ILLEGAL_SUBCLASS_KIT');
      expect(DomainFailureCodes.modEnergyExceeded, 'MOD_ENERGY_EXCEEDED');
      expect(
        DomainFailureCodes.exoticAbilityMismatch,
        'EXOTIC_ABILITY_MISMATCH',
      );
      expect(DomainFailureCodes.noSynergy, 'NO_SYNERGY');
      expect(
        DomainFailureCodes.pureHardGateCodes,
        containsAll([
          'TOO_MANY_EXOTICS',
          'ILLEGAL_SUBCLASS_KIT',
          'MOD_ENERGY_EXCEEDED',
          'EXOTIC_ABILITY_MISMATCH',
          'NO_SYNERGY',
        ]),
      );
      expect(DomainFailureCodes.notEquipReady, 'NOT_EQUIP_READY');
      expect(DomainFailureCodes.slotConflict, 'SLOT_CONFLICT');
    });

    test('ConstraintEvaluation holds hard blocks distinct from soft warnings', () {
      const evalResult = ConstraintEvaluation(
        hardBlocks: [
          HardBlock(
            code: DomainFailureCodes.tooManyExotics,
            message: 'At most one exotic weapon',
          ),
        ],
        softWarnings: [
          SoftWarning(
            code: DomainFailureCodes.exoticAbilityPinProposed,
            message: 'Confirm ability pins',
          ),
        ],
      );
      expect(evalResult.isHardBlocked, isTrue);
      expect(evalResult.hardBlocks.single.code, 'TOO_MANY_EXOTICS');
      expect(evalResult.softWarnings.single.code, 'EXOTIC_ABILITY_PIN_PROPOSED');
      // SoftWarning is not a HardBlock type
      expect(evalResult.softWarnings.single, isA<SoftWarning>());
      expect(evalResult.hardBlocks.single, isA<HardBlock>());
      expect(evalResult.softWarnings.single, isNot(isA<HardBlock>()));
    });
  });

  group('Kits', () {
    test('SubclassKit and AbilityKit construct without evaluation', () {
      const kit = SubclassKit(
        aspects: ['Knockout', 'Touch of Thunder'],
        fragments: ['Spark of Beacons'],
        superAbility: 'Thundercrash',
        melee: 'Ballistic Slam',
        grenade: 'Lightning Grenade',
        classAbility: 'Towering Barricade',
        name: 'Striker',
      );
      expect(kit.aspectCount, 2);
      expect(kit.fragmentCount, 1);
      expect(kit.abilityKit.superAbility, 'Thundercrash');
      expect(maxSubclassAspects, 2);

      const composition = ExoticComposition(
        exoticWeaponHashes: [111],
        exoticArmorHashes: [222],
      );
      expect(composition.exoticWeaponHashes, [111]);

      const piece = ModEnergyPiece(
        slot: 'helmet',
        energyUsed: 12,
        energyCapacity: 10,
      );
      expect(piece.exceedsCapacity, isTrue);

      const evalInput = SubclassKitEvalInput(
        aspectCount: 3,
        fragmentCount: 5,
        fragmentCapacity: 4,
        capacityResolved: true,
      );
      expect(evalInput.maxAspects, 2);
    });
  });

  group('Coverage & soft stats', () {
    test('CoverageResult is soft-only and never a ConstraintEvaluation', () {
      const row = SynergyCoverageRow(
        synergyId: 'verb::jolt',
        name: 'Jolt',
        tier: CoverageTier.weak,
        matchedLinks: [
          LinkMatchSummary(kind: 'weapon', displayName: 'Riskrunner'),
        ],
        unmatchedLinks: [
          LinkMatchSummary(kind: 'weapon_perk', displayName: 'Voltshot'),
        ],
        hint: 'Add voltshot weapon',
      );
      const coverage = CoverageResult(
        synergies: [row],
        setBonuses: [
          SetBonusSoftRow(
            setName: 'Example Set',
            pieceCount: 2,
            status: SetBonusSoftStatus.partial,
            armorSetHash: 99,
          ),
        ],
        elementMismatches: [
          ElementSoftMismatch(
            slot: EquipmentSlot.special,
            weaponElement: 'Solar',
            subclassElement: 'Arc',
            hint: 'Element differs',
          ),
        ],
        targets: SoftStatTargets({ArmorStatName.weapons: 100}),
        softStats: [
          SoftStatWarningRow(
            stat: ArmorStatName.weapons,
            target: 100,
            estimate: 70,
            hint: 'Weapons estimate 70 is below target 100.',
          ),
        ],
      );
      expect(coverage.synergies.single.tier.wireName, 'weak');
      expect(coverage, isA<CoverageResult>());
      expect(coverage, isNot(isA<ConstraintEvaluation>()));
      expect(coverage.softStats.single.stat.wireName, 'Weapons');
      expect(
        ArmorStatName.all.map((e) => e.wireName).toList(),
        ['Health', 'Melee', 'Grenade', 'Super', 'Class', 'Weapons'],
      );
    });
  });

  group('Library shapes', () {
    test('Build, Variant, GearSet, Synergy construct for evaluators', () {
      const designation = SynergyTypeDesignation(
        type: SynergyType('verb'),
        subType: 'jolt',
      );
      expect(designation.designationKey, 'verb::jolt');

      const build = Build(
        id: 'b1',
        name: 'Arc Punch',
        className: GuardianClass.titan,
        subclass: SubclassKit(name: 'Striker', aspects: ['Knockout']),
        exoticArmorHash: 555,
        synergyTypes: [designation],
      );
      expect(build.className.wireName, 'Titan');
      expect(build.synergyTypes.single.type.wireName, 'verb');

      const variant = Variant(
        id: 'v1',
        buildId: 'b1',
        name: 'Default',
        isDefault: true,
      );
      expect(variant.isDefault, isTrue);

      const set = GearSet(
        id: 's1',
        name: 'Arc Armor',
        type: SetType.armor,
      );
      expect(set.type.wireName, 'armor');

      const attachment = Attachment(
        id: 'a1',
        variantId: 'v1',
        setId: 's1',
        mode: AttachmentMode.live,
      );
      expect(attachment.mode.wireName, 'live');

      const item = SetItem(
        id: 'i1',
        setId: 's1',
        slot: 'helmet',
        itemHash: 7,
        itemName: 'Helm',
        instanceId: 'inst',
      );
      expect(item.instanceId, 'inst');

      const synergy = Synergy(
        id: 'syn-1',
        name: 'Jolt chain',
        type: SynergyType('verb'),
        subType: 'jolt',
        links: [
          SynergyLink(
            id: 'l1',
            synergyId: 'syn-1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Riskrunner',
            itemHash: 123,
          ),
        ],
      );
      expect(synergy.designation.designationKey, 'verb::jolt');
      expect(synergy.links.single.kind.wireName, 'weapon');
      expect(creatableSynergyTypeWires, contains('verb'));
      expect(legacySynergyTypeWires, contains('damage'));
    });
  });
}
