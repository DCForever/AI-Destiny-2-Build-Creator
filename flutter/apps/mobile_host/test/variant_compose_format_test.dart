import 'package:destiny2_mobile_host/builds/variant_compose_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSlotPinLabel', () {
    test('null/empty → wishlist', () {
      expect(formatSlotPinLabel(null), 'wishlist');
      expect(formatSlotPinLabel(''), 'wishlist');
      expect(formatSlotPinLabel('  '), 'wishlist');
    });

    test('non-empty → instance', () {
      expect(formatSlotPinLabel('inst-1'), 'instance');
    });
  });

  group('formatSlotPinDetail', () {
    test('wishlist vs instance id', () {
      expect(formatSlotPinDetail(null), 'wishlist');
      expect(formatSlotPinDetail('x'), 'instance · x');
    });
  });

  group('formatAttachmentSummary', () {
    test('name preferred over id', () {
      expect(
        formatAttachmentSummary(
          setId: 's1',
          setName: 'Kinetic Core',
          mode: 'live',
        ),
        'Kinetic Core (live)',
      );
      expect(
        formatAttachmentSummary(setId: 's1', setName: null, mode: ''),
        's1 (live)',
      );
    });
  });

  test('formatComposeError trims and fallback', () {
    expect(formatComposeError(null), 'Compose failed');
    expect(formatComposeError('  SLOT_CONFLICT  '), 'SLOT_CONFLICT');
  });
}
