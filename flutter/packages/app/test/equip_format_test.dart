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
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'Null Composure',
          slot: 'energy',
          isExotic: false,
        ),
        'Null Composure',
      );
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'Eyes of Tomorrow',
          slot: 'heavy',
          isExotic: true,
        ),
        'Eyes of Tomorrow (Exotic weapon)',
      );
      expect(
        formatApplyOutcomeLabel(
          rawLabel: 'Cuirass of the Falling Star',
          slot: 'chest',
          isExotic: true,
        ),
        'Cuirass of the Falling Star (Exotic armor)',
      );
    });
  });

  group('readableApplySlotLabel', () {
    test('maps wires to human labels', () {
      expect(readableApplySlotLabel('primary'), 'Kinetic');
      expect(readableApplySlotLabel('kinetic'), 'Kinetic');
      expect(readableApplySlotLabel('energy'), 'Energy');
      expect(readableApplySlotLabel('special'), 'Energy');
      expect(readableApplySlotLabel('heavy'), 'Power');
      expect(readableApplySlotLabel('power'), 'Power');
      expect(readableApplySlotLabel('helmet'), 'Helmet');
      expect(readableApplySlotLabel('arms'), 'Gauntlets');
      expect(readableApplySlotLabel('gauntlets'), 'Gauntlets');
      expect(readableApplySlotLabel('chest'), 'Chest');
      expect(readableApplySlotLabel('legs'), 'Legs');
      expect(readableApplySlotLabel('class_item'), 'Class Item');
      expect(readableApplySlotLabel('classitem'), 'Class Item');
      expect(readableApplySlotLabel('exotic_weapon'), 'Exotic weapon');
      expect(readableApplySlotLabel('exotic_armor'), 'Exotic armor');
      expect(readableApplySlotLabel(''), 'Item');
      expect(readableApplySlotLabel('None'), 'Item');
      expect(readableApplySlotLabel(null), 'Item');
    });
  });
}
