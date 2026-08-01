import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/compose/finish_gaps_format.dart';
import 'package:test/test.dart';

void main() {
  group('finish_gaps_format (jaspr)', () {
    test('policy requires finish-complete AND equip-ready', () {
      expect(kFinishGapsPolicyCaption, contains('finish-complete AND equip-ready'));
      expect(
        canProceedWithFinishAndEquipReady(
          finishComplete: false,
          equipReady: true,
        ),
        isFalse,
      );
      expect(
        canProceedWithFinishAndEquipReady(
          finishComplete: true,
          equipReady: true,
        ),
        isTrue,
      );
    });

    test('row summaries for incomplete gaps', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: false,
        ),
      );
      expect(r.complete, isFalse);
      for (final g in r.gaps) {
        final line = formatFinishGapRowSummary(g);
        expect(line, isNotEmpty);
        expect(
          line,
          anyOf(
            contains('Needs covering set'),
            contains('Needs fill'),
            contains('Complete'),
            contains('Capture'),
          ),
        );
      }
    });
  });
}
