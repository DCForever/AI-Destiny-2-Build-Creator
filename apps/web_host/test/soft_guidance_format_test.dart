import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/compose/soft_guidance_format.dart';
import 'package:test/test.dart';

void main() {
  group('soft_guidance_format', () {
    test('advisory caption forbids auto-apply language inverted', () {
      expect(kSoftGuidanceAdvisoryCaption, contains('never auto-applies'));
      expect(kSoftGuidanceAdvisoryCaption, contains('does not block save'));
    });

    test('coverage tier labels and tones', () {
      expect(formatCoverageTierLabel(CoverageTier.missing), 'missing');
      expect(coverageTierToneKey(CoverageTier.supported), 'success');
      expect(coverageTierToneKey(CoverageTier.weak), 'warning');
      expect(coverageTierToneKey(CoverageTier.missing), 'danger');
    });

    test('softStatTargetsFromFieldMap Health', () {
      final t = softStatTargetsFromFieldMap({'Health': '100'});
      expect(t[ArmorStatName.health], 100);
    });

    test('softStatTargetsFromFieldMap all ArmorStatName (GAP-UI-01)', () {
      final fields = <String, String>{
        for (final s in ArmorStatName.all) s.wireName: '100',
      };
      final t = softStatTargetsFromFieldMap(fields);
      for (final s in ArmorStatName.all) {
        expect(t[s], 100, reason: s.wireName);
      }
      final summary = formatSoftStatTargetsSummary(t);
      for (final s in ArmorStatName.all) {
        expect(summary, contains(s.wireName));
      }
    });

    test('parse invalid soft target', () {
      final bad = parseSoftStatTargetField('nope');
      expect(bad.error, isNotNull);
    });
  });
}
