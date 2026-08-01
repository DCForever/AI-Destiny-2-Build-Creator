import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('coverage tier labels', () {
    test('formatCoverageTierLabel uses wire names', () {
      expect(formatCoverageTierLabel(CoverageTier.supported), 'supported');
      expect(formatCoverageTierLabel(CoverageTier.weak), 'weak');
      expect(formatCoverageTierLabel(CoverageTier.missing), 'missing');
    });

    test('coverageTierToneKey maps tiers', () {
      expect(coverageTierToneKey(CoverageTier.supported), 'success');
      expect(coverageTierToneKey(CoverageTier.weak), 'warning');
      expect(coverageTierToneKey(CoverageTier.missing), 'danger');
    });

    test('formatSynergyCoverageChipLabel', () {
      const row = SynergyCoverageRow(
        synergyId: 'melee::Base',
        name: 'Melee Loop',
        tier: CoverageTier.missing,
      );
      expect(
        formatSynergyCoverageChipLabel(row),
        'Melee Loop · missing',
      );
    });
  });

  group('soft rows', () {
    test('formatSetBonusSoftSummary', () {
      const row = SetBonusSoftRow(
        setName: 'Artifice',
        pieceCount: 2,
        status: SetBonusSoftStatus.partial,
      );
      expect(formatSetBonusSoftSummary(row), 'Artifice · partial (2 pc)');
    });

    test('formatElementSoftMismatchSummary', () {
      const row = ElementSoftMismatch(
        slot: EquipmentSlot.special,
        weaponElement: 'Solar',
        subclassElement: 'Arc',
        hint: 'match element',
      );
      expect(
        formatElementSoftMismatchSummary(row),
        'special: Solar vs Arc',
      );
    });

    test('formatSoftStatWarningSummary', () {
      const row = SoftStatWarningRow(
        stat: ArmorStatName.melee,
        target: 100,
        estimate: 72,
        hint: 'below target',
      );
      expect(
        formatSoftStatWarningSummary(row),
        'Melee: 72 / target 100',
      );
    });
  });

  group('soft stat targets', () {
    test('formatSoftStatTargetsSummary empty', () {
      expect(formatSoftStatTargetsSummary(const SoftStatTargets()), '');
    });

    test('formatSoftStatTargetsSummary ordered', () {
      final t = SoftStatTargets({
        ArmorStatName.melee: 80,
        ArmorStatName.health: 100,
      });
      expect(formatSoftStatTargetsSummary(t), 'Health:100, Melee:80');
    });

    test('parseSoftStatTargetField empty clears', () {
      final r = parseSoftStatTargetField('  ');
      expect(r.value, isNull);
      expect(r.error, isNull);
    });

    test('parseSoftStatTargetField validates range', () {
      expect(parseSoftStatTargetField('0').error, isNotNull);
      expect(parseSoftStatTargetField('201').error, isNotNull);
      expect(parseSoftStatTargetField('100').value, 100);
    });

    test('softStatTargetsFromFieldMap builds targets', () {
      final t = softStatTargetsFromFieldMap({
        'Health': '100',
        'Melee': '',
        'Grenade': '50',
      });
      expect(t[ArmorStatName.health], 100);
      expect(t[ArmorStatName.melee], isNull);
      expect(t[ArmorStatName.grenade], 50);
    });

    test('softStatTargetsFromFieldMap rejects invalid', () {
      expect(
        () => softStatTargetsFromFieldMap({'Health': 'nope'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('advisory caption is non-empty and mentions never auto-applies', () {
      expect(kSoftGuidanceAdvisoryCaption, isNotEmpty);
      expect(
        kSoftGuidanceAdvisoryCaption.toLowerCase(),
        contains('never auto-applies'),
      );
      expect(
        kSoftGuidanceAdvisoryCaption.toLowerCase(),
        contains('does not block save'),
      );
    });
  });
}
