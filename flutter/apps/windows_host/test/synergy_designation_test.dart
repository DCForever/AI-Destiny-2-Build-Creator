import 'package:destiny2_windows_host/synergies/synergy_designation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSynergyDesignation (human chrome)', () {
    test('type only when subtype empty or null', () {
      expect(formatSynergyDesignation('melee'), 'Melee');
      expect(formatSynergyDesignation('melee', null), 'Melee');
      expect(formatSynergyDesignation('melee', ''), 'Melee');
      expect(formatSynergyDesignation('melee', '  '), 'Melee');
    });

    test('human label when subtype present', () {
      expect(formatSynergyDesignation('melee', 'Base'), 'Melee: Base');
      expect(formatSynergyDesignation('verb', 'jolt'), 'Verb: jolt');
      expect(formatSynergyDesignation('  melee  ', '  Base  '), 'Melee: Base');
    });
  });

  group('formatSynergyDesignationWire', () {
    test('type only when subtype empty or null', () {
      expect(formatSynergyDesignationWire('melee'), 'melee');
      expect(formatSynergyDesignationWire('melee', null), 'melee');
      expect(formatSynergyDesignationWire('melee', ''), 'melee');
      expect(formatSynergyDesignationWire('melee', '  '), 'melee');
    });

    test('type::subType when subtype present', () {
      expect(formatSynergyDesignationWire('melee', 'Base'), 'melee::Base');
      expect(formatSynergyDesignationWire('verb', 'jolt'), 'verb::jolt');
      expect(
        formatSynergyDesignationWire('  melee  ', '  Base  '),
        'melee::Base',
      );
    });
  });

  group('synergyLinkKindLabel', () {
    test('known wires', () {
      expect(synergyLinkKindLabel('exotic_armor'), 'Exotic armor');
      expect(synergyLinkKindLabel('weapon'), 'Weapon');
    });

    test('unknown falls back to wire', () {
      expect(synergyLinkKindLabel('custom_kind'), 'custom_kind');
    });
  });
}
