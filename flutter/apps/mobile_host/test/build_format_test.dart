import 'package:destiny2_mobile_host/builds/build_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatBuildListTitle falls back when blank', () {
    expect(formatBuildListTitle(''), 'Untitled build');
    expect(formatBuildListTitle('  '), 'Untitled build');
    expect(formatBuildListTitle(null), 'Untitled build');
    expect(formatBuildListTitle('Arc Hunter'), 'Arc Hunter');
  });

  test('formatSynergyDesignationKey', () {
    expect(formatSynergyDesignationKey('melee'), 'melee');
    expect(formatSynergyDesignationKey('melee', 'Base'), 'melee::Base');
  });

  test('formatIdentitySummary', () {
    expect(formatIdentitySummary(className: 'Hunter'), 'Hunter');
    expect(
      formatIdentitySummary(className: 'Hunter', pinnedSuper: 'Golden Gun'),
      'Hunter · Golden Gun',
    );
  });
}
