import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_logic.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = loadBuildsMockFixture();

  test('fixture has 10-20 builds and a few sets', () {
    expect(fixture.builds.length, inInclusiveRange(10, 20));
    expect(fixture.sets.length, inInclusiveRange(3, 8));
  });

  test('readiness rule: 10 builds and 3 uses per slot', () {
    final rows = computeAllReadiness(fixture);
    final techsec = rows.firstWhere((r) => r.setId == 'set_techsec');
    expect(techsec.buildCount, greaterThanOrEqualTo(kMockReadyBuildCount));
    for (final slot in kMockArmorSlots) {
      expect(
        techsec.slotUses[slot],
        greaterThanOrEqualTo(kMockReadySlotUses),
        reason: slot,
      );
    }
    expect(techsec.status, MockReadiness.ready);

    final walk = rows.firstWhere((r) => r.setId == 'set_walk');
    expect(walk.status, MockReadiness.notReady);
  });

  test('cap helper flags held above X', () {
    expect(heldExceedsCap(3, 2), isTrue);
    expect(heldExceedsCap(2, 2), isFalse);
    expect(moreThanCapLabel(2), 'More than 2 held');
    expect(moreThanCapLabel(4), 'More than 4 held');
  });

  test('filter by exotic armor and subclass', () {
    final filtered = filterMockBuilds(
      builds: fixture.builds,
      exoticArmor: 'Solipsism',
      subclass: 'Strand',
    );
    expect(filtered, hasLength(1));
    expect(filtered.single.name, 'Solipsism Strand mismatch');
  });

  test('Solipsism non-Prismatic builds are flagged', () {
    final bad = fixture.builds.where((b) => b.solipsismNotPrismatic);
    expect(bad, isNotEmpty);
    expect(
      bad.every((b) => b.subclass.toLowerCase() != 'prismatic'),
      isTrue,
    );
  });
}
