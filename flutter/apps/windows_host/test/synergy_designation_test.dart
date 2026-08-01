import 'package:destiny2_windows_host/synergies/synergy_designation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSynergyDesignation', () {
    test('type only when subtype empty or null', () {
      expect(formatSynergyDesignation('melee'), 'melee');
      expect(formatSynergyDesignation('melee', null), 'melee');
      expect(formatSynergyDesignation('melee', ''), 'melee');
      expect(formatSynergyDesignation('melee', '  '), 'melee');
    });

    test('type::subType when subtype present', () {
      expect(formatSynergyDesignation('melee', 'Base'), 'melee::Base');
      expect(formatSynergyDesignation('verb', 'jolt'), 'verb::jolt');
      expect(formatSynergyDesignation('  melee  ', '  Base  '), 'melee::Base');
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
