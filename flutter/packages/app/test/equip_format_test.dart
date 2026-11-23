import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('formatApplyOutcomeLabel', () {
    test('exotic weapon and armor annotations; never primary/None', () {
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'Barrow-Dyad',
          slot: 'primary',
          isExotic: true,
        ),
        'Barrow-Dyad (Exotic weapon)',
      );
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'Briarbinds',
          slot: 'arms',
          isExotic: true,
        ),
        'Briarbinds (Exotic armor)',
      );
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'primary',
          slot: 'primary',
          isExotic: true,
        ),
        isNot('primary'),
      );
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'None',
          slot: 'helmet',
        ),
        'Helmet',
      );
      expect(
        formatApplyOutcomeLabel(rawLabel: '', slot: 'primary'),
        'Kinetic',
      );
    });
  });

  group('readableApplySlotLabel', () {
    test('maps wires to human labels', () {
      expect(readableApplySlotLabel('primary'), 'Kinetic');
      expect(readableApplySlotLabel('energy'), 'Energy');
      expect(readableApplySlotLabel('heavy'), 'Power');
      expect(readableApplySlotLabel('arms'), 'Gauntlets');
      expect(readableApplySlotLabel('class_item'), 'Class Item');
    });
  });
}
