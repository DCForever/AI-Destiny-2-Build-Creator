import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const build = MockBuild(
    id: 'b1',
    name: 'Source',
    subclass: 'Solar',
    exoticArmor: '',
    exoticWeapon: '',
    slots: [
      MockSlotAssignment(slot: 'helmet', setId: 'a', pieceName: 'Helm'),
      MockSlotAssignment(slot: 'arms', setId: 'a', pieceName: 'Arms'),
    ],
    loop: '',
    artifact: MockArtifact(name: '—', season: '—'),
    setBonuses: [],
    stats: [],
  );

  test('places by ModRecord slotCategory hash map (no Unplaced)', () {
    final placed = placeDimMods(
      mods: const [
        CachedDimNamedHash(hash: 11, name: 'Ashes to Assets'),
        CachedDimNamedHash(hash: 22, name: 'Powerful Friends'),
        CachedDimNamedHash(hash: 33, name: 'Heavy Handed'),
      ],
      build: build,
      slotCategoryByModHash: const {
        11: 'helmet',
        22: 'arms',
        33: 'chest',
      },
    );
    expect(placed.unplaced, isEmpty);
    expect(placed.bySlot['helmet'], ['Ashes to Assets']);
    expect(placed.bySlot['arms'], ['Powerful Friends']);
    expect(placed.bySlot['chest'], ['Heavy Handed']);
  });

  test('general / unknown mods get most likely slot with slot guessed note', () {
    final placed = placeDimMods(
      mods: const [
        CachedDimNamedHash(hash: 99, name: 'Time Dilation'),
      ],
      build: build,
      slotCategoryByModHash: const {99: 'general'},
    );
    expect(placed.unplaced, isEmpty);
    final all = [
      for (final e in placed.bySlot.entries)
        for (final m in e.value) '${e.key}::$m',
    ];
    expect(all, hasLength(1));
    expect(all.single, contains('slot guessed'));
    expect(all.single.startsWith('class_item::'), isTrue);
  });

  test('name heuristic without catalog still avoids Unplaced', () {
    final placed = placeDimMods(
      mods: const [
        CachedDimNamedHash(hash: 1, name: 'Helmet Targeting'),
      ],
      build: build,
    );
    expect(placed.unplaced, isEmpty);
    expect(placed.bySlot['helmet']!.single, contains('Helmet Targeting'));
    expect(placed.bySlot['helmet']!.single, contains('slot guessed'));
  });
}
