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

  test('readiness filter: Ready / Not ready still work', () {
    final rows = computeAllReadiness(fixture);
    final ready = filterMockBuilds(
      builds: fixture.builds,
      readiness: MockReadiness.ready,
      readinessRows: rows,
    );
    final notReady = filterMockBuilds(
      builds: fixture.builds,
      readiness: MockReadiness.notReady,
      readinessRows: rows,
    );
    expect(ready, isNotEmpty);
    expect(notReady, isNotEmpty);
    expect(
      ready.every(
        (b) => rows
            .where((r) => b.setIds.contains(r.setId))
            .any((r) => r.status == MockReadiness.ready),
      ),
      isTrue,
    );
    expect(
      notReady.every(
        (b) {
          final linked = rows.where((r) => b.setIds.contains(r.setId));
          if (linked.isEmpty) return true;
          return linked.every((r) => r.status == MockReadiness.notReady);
        },
      ),
      isTrue,
    );
  });

  test('readiness filter: Filled In matches slot.filledIn and plan ids', () {
    // Decision: proposed counts — filledInBuildIds come from
    // buildsMockHasFillIn (proposed + filled + applied).
    final withSlot = MockBuild(
      id: 'filled_slot',
      name: 'Slot filled',
      subclass: 'Strand',
      exoticArmor: '',
      exoticWeapon: '',
      slots: const [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_a',
          pieceName: 'Helm',
          filledIn: true,
        ),
      ],
      loop: 'loop',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: const [],
    );
    final proposedOnly = MockBuild(
      id: 'proposed_plan',
      name: 'Proposed only',
      subclass: 'Strand',
      exoticArmor: '',
      exoticWeapon: '',
      slots: const [],
      loop: 'loop',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: const [],
    );
    final plain = MockBuild(
      id: 'plain',
      name: 'Plain',
      subclass: 'Strand',
      exoticArmor: '',
      exoticWeapon: '',
      slots: const [],
      loop: 'loop',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: const [],
    );

    final filtered = filterMockBuilds(
      builds: [withSlot, proposedOnly, plain],
      readiness: MockReadiness.filledIn,
      filledInBuildIds: {'proposed_plan'},
    );
    expect(filtered.map((b) => b.id), ['filled_slot', 'proposed_plan']);
    expect(
      buildMatchesFilledInReadiness(
        proposedOnly,
        filledInBuildIds: {'proposed_plan'},
      ),
      isTrue,
    );
    expect(buildMatchesFilledInReadiness(plain), isFalse);
  });

  test('readiness filter: Optimized matches nothing without a producer', () {
    expect(
      fixture.builds.every((b) => !isMockBuildOptimized(b)),
      isTrue,
    );
    final filtered = filterMockBuilds(
      builds: fixture.builds,
      readiness: MockReadiness.optimized,
      readinessRows: computeAllReadiness(fixture),
    );
    expect(filtered, isEmpty);
  });
}
