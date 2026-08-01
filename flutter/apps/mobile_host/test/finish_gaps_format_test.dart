import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_mobile_host/builds/finish_gaps_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('finish_gaps_format (mobile)', () {
    test('status labels', () {
      expect(
        formatFinishGapStatusLabel(FinishGapStatus.satisfied),
        'Complete',
      );
      expect(
        formatFinishGapStatusLabel(FinishGapStatus.needsSet),
        'Needs covering set',
      );
      expect(
        formatFinishGapStatusLabel(FinishGapStatus.needsFill),
        'Needs fill',
      );
    });

    test('complete summary and policy caption', () {
      expect(kFinishGapsPolicyCaption, contains('finish-complete'));
      expect(kFinishGapsPolicyCaption, contains('never auto-applies'));

      final incomplete = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
        ),
      );
      expect(incomplete.complete, isFalse);
      expect(
        formatFinishGapsCompleteSummary(incomplete),
        contains('Finish incomplete'),
      );
      expect(incomplete.gaps, isNotEmpty);
      for (final g in incomplete.gaps) {
        expect(formatFinishGapRowSummary(g), contains(finishCategoryLabel(g.category)));
      }
    });

    test('finishAttachmentModeFromWire', () {
      expect(finishAttachmentModeFromWire('snapshot'), AttachmentMode.snapshot);
      expect(finishAttachmentModeFromWire('live'), AttachmentMode.live);
    });
  });
}
