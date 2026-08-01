import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('formatSlotPinLabel', () {
    test('null/empty → wishlist', () {
      expect(formatSlotPinLabel(null), 'wishlist');
      expect(formatSlotPinLabel(''), 'wishlist');
      expect(formatSlotPinLabel('  '), 'wishlist');
    });

    test('non-empty instance → instance', () {
      expect(formatSlotPinLabel('inst-1'), 'instance');
    });
  });

  group('formatSlotPinDetail', () {
    test('wishlist vs instance detail', () {
      expect(formatSlotPinDetail(null), 'wishlist');
      expect(formatSlotPinDetail('inst-9'), 'instance · inst-9');
    });
  });

  group('formatAttachmentSummary', () {
    test('uses name when present', () {
      expect(
        formatAttachmentSummary(
          setId: 's1',
          setName: 'Kinetic Core',
          mode: 'live',
        ),
        'Kinetic Core (live)',
      );
    });

    test('falls back to setId', () {
      expect(
        formatAttachmentSummary(setId: 's1', setName: null, mode: 'snapshot'),
        's1 (snapshot)',
      );
    });
  });

  group('formatAttachmentListSummary', () {
    test('joins multiple', () {
      final s = formatAttachmentListSummary([
        (setId: 'a', setName: 'Armor', mode: 'live'),
        (setId: 'w', setName: 'Weapons', mode: 'live'),
      ]);
      expect(s, 'Armor (live), Weapons (live)');
    });
  });

  group('formatComposeError', () {
    test('trims and fallback', () {
      expect(formatComposeError('  SLOT_CONFLICT  '), 'SLOT_CONFLICT');
      expect(formatComposeError(null), 'Compose failed');
      expect(formatComposeError(''), 'Compose failed');
    });
  });
}
