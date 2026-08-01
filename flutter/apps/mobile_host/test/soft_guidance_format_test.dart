import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_mobile_host/builds/soft_guidance_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advisory caption forbids auto-apply language', () {
    expect(kSoftGuidanceAdvisoryCaption, contains('never auto-applies'));
    expect(kSoftGuidanceAdvisoryCaption.toLowerCase(), isNot(contains('auto apply kit')));
  });

  test('coverage tier labels and tones', () {
    expect(formatCoverageTierLabel(CoverageTier.missing), 'missing');
    expect(coverageTierToneKey(CoverageTier.supported), 'success');
    expect(coverageTierToneKey(CoverageTier.weak), 'warning');
    expect(coverageTierToneKey(CoverageTier.missing), 'danger');
  });

  test('parse soft stat target field', () {
    expect(parseSoftStatTargetField('').value, isNull);
    expect(parseSoftStatTargetField('100').value, 100);
    expect(parseSoftStatTargetField('0').error, isNotNull);
    expect(parseSoftStatTargetField('abc').error, isNotNull);
  });

  test('softStatTargetsFromFieldMap', () {
    final t = softStatTargetsFromFieldMap({'Health': '100', 'Melee': ''});
    expect(t[ArmorStatName.health], 100);
    expect(t[ArmorStatName.melee], isNull);
  });

  test('formatSoftStatTargetsSummary', () {
    final t = SoftStatTargets({ArmorStatName.health: 100});
    expect(formatSoftStatTargetsSummary(t), contains('Health:100'));
    expect(formatSoftStatTargetsSummary(const SoftStatTargets()), '');
  });
}
