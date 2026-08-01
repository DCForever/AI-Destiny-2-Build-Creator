import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  final sets = [
    const FilterableSet(
      id: '1',
      name: 'Kinetic Kit',
      type: 'weapon',
      tagIds: ['pve', 'solar'],
    ),
    const FilterableSet(
      id: '2',
      name: 'Void Armor',
      type: 'armor',
      tagIds: ['pve'],
    ),
    const FilterableSet(
      id: '3',
      name: 'Fashion',
      type: 'fashion',
      tagIds: ['pvp'],
    ),
  ];

  group('filterSets', () {
    test('query matches name', () {
      expect(
        filterSets(sets, const SetListFilters(query: 'void')).map((s) => s.id),
        ['2'],
      );
      expect(
        filterSets(sets, const SetListFilters(query: 'weapon')).map((s) => s.id),
        ['1'],
      );
    });

    test('types facet', () {
      expect(
        filterSets(
          sets,
          const SetListFilters(types: ['armor', 'fashion']),
        ).map((s) => s.id),
        ['2', '3'],
      );
    });

    test('tags AND', () {
      expect(
        filterSets(sets, const SetListFilters(tags: ['pve'])).map((s) => s.id),
        ['1', '2'],
      );
      expect(
        filterSets(
          sets,
          const SetListFilters(tags: ['solar', 'pve']),
        ).map((s) => s.id),
        ['1'],
      );
    });

    test('combined query + type', () {
      expect(
        filterSets(
          sets,
          const SetListFilters(query: 'kit', types: ['fashion']),
        ),
        isEmpty,
      );
    });
  });

  final synergies = [
    const FilterableSynergy(
      id: 'a',
      name: 'Hammer Strike',
      type: 'melee',
      subType: 'Base',
    ),
    const FilterableSynergy(
      id: 'b',
      name: 'Radiant Loop',
      type: 'verb',
      subType: 'Radiant',
    ),
    const FilterableSynergy(
      id: 'c',
      name: 'Grenade Spam',
      type: 'grenade',
    ),
  ];

  group('filterSynergies', () {
    test('types', () {
      expect(
        filterSynergies(
          synergies,
          const SynergyListFilters(types: ['melee']),
        ).map((r) => r.id),
        ['a'],
      );
    });

    test('subTypes AND with types', () {
      expect(
        filterSynergies(
          synergies,
          const SynergyListFilters(subTypes: ['Radiant']),
        ).map((r) => r.id),
        ['b'],
      );
      expect(
        filterSynergies(
          synergies,
          const SynergyListFilters(subTypes: ['Radiant'], types: ['dps']),
        ),
        isEmpty,
      );
    });

    test('query', () {
      expect(
        filterSynergies(
          synergies,
          const SynergyListFilters(query: 'hammer'),
        ).map((r) => r.id),
        ['a'],
      );
    });
  });
}
