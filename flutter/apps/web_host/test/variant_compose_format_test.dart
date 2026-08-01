import 'package:destiny2_web_host/compose/variant_compose_format.dart';
import 'package:test/test.dart';

void main() {
  group('variant_compose_format', () {
    test('pin labels wishlist vs instance', () {
      expect(formatSlotPinLabel(null), 'wishlist');
      expect(formatSlotPinLabel(''), 'wishlist');
      expect(formatSlotPinLabel('inst-1'), 'instance');
      expect(formatSlotPinDetail('inst-1'), 'instance · inst-1');
    });

    test('attachment summary', () {
      expect(
        formatAttachmentSummary(
          setId: 's1',
          setName: 'Kinetic Core',
          mode: 'live',
        ),
        'Kinetic Core (live)',
      );
    });
  });
}
