import 'package:destiny2_windows_host/builds/build_identity_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSynergyDesignationKey', () {
    test('type only', () {
      expect(formatSynergyDesignationKey('melee'), 'melee');
      expect(formatSynergyDesignationKey('  grenade  '), 'grenade');
    });

    test('type::subType', () {
      expect(formatSynergyDesignationKey('melee', 'Base'), 'melee::Base');
      expect(formatSynergyDesignationKey('verb', '  jolt  '), 'verb::jolt');
    });

    test('empty subtype omits separator', () {
      expect(formatSynergyDesignationKey('element', ''), 'element');
      expect(formatSynergyDesignationKey('element', '   '), 'element');
      expect(formatSynergyDesignationKey('element', null), 'element');
    });
  });

  group('formatSynergyDesignationList', () {
    test('joins multiple keys', () {
      expect(
        formatSynergyDesignationList([
          (type: 'melee', subType: 'Base'),
          (type: 'grenade', subType: null),
        ]),
        'melee::Base, grenade',
      );
    });

    test('empty list', () {
      expect(formatSynergyDesignationList([]), '');
    });
  });

  group('formatExoticsSummary', () {
    test('dash when none', () {
      expect(formatExoticsSummary(), '—');
    });

    test('names preferred over hashes', () {
      expect(
        formatExoticsSummary(
          exoticArmorName: 'Synthoceps',
          exoticArmorHash: 1,
          exoticWeaponName: 'Tractor',
          exoticWeaponHash: 2,
        ),
        'Synthoceps · Tractor',
      );
    });

    test('hash fallback', () {
      expect(
        formatExoticsSummary(exoticArmorHash: 42),
        'Armor 42',
      );
    });
  });

  group('formatIdentitySummary', () {
    test('class only', () {
      expect(formatIdentitySummary(className: 'Hunter'), 'Hunter');
    });

    test('class + super', () {
      expect(
        formatIdentitySummary(
          className: 'Warlock',
          pinnedSuper: 'Well of Radiance',
        ),
        'Warlock · Well of Radiance',
      );
    });
  });
}
