import 'package:destiny2_web_host/compose/build_format.dart';
import 'package:test/test.dart';

void main() {
  group('build_format', () {
    test('formatSynergyDesignationKey', () {
      expect(formatSynergyDesignationKey('melee'), 'melee');
      expect(formatSynergyDesignationKey('melee', 'Base'), 'melee::Base');
    });

    test('formatBuildListTitle', () {
      expect(formatBuildListTitle(null), 'Untitled build');
      expect(formatBuildListTitle('  '), 'Untitled build');
      expect(formatBuildListTitle('Hunter Loop'), 'Hunter Loop');
    });

    test('formatIdentitySummary', () {
      expect(
        formatIdentitySummary(className: 'Hunter'),
        'Hunter',
      );
      expect(
        formatIdentitySummary(className: 'Titan', pinnedSuper: 'Hammer'),
        'Titan · Hammer',
      );
    });
  });
}
