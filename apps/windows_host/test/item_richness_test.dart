import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_windows_host/widgets/item_richness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPerkColumns', () {
    test('groups reusable plugs by column with equipped marked', () {
      final cols = buildPerkColumns(
        socketPlugs: [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 101,
            'reusablePlugHashes': [101, 102],
          },
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait 1',
            'equippedPlugHash': 201,
            'reusablePlugHashes': [201, 202],
          },
        ],
        plugNameByHash: {
          101: 'Fluted Barrel',
          102: 'Smallbore',
          201: 'Firefly',
          202: 'Outlaw',
        },
      );

      expect(cols, hasLength(2));
      expect(cols[0].label, 'Barrel');
      expect(cols[0].options, hasLength(2));
      expect(cols[0].options.where((o) => o.equipped).single.displayName,
          'Fluted Barrel');
      expect(cols[1].options.map((o) => o.displayName).toList(),
          ['Firefly', 'Outlaw']);
    });

    test('falls back to plug cards when no sockets', () {
      final cols = buildPerkColumns(
        plugCards: const [
          ResolvedPlugCard(
            hash: 1,
            displayName: 'Kill Clip',
            columnLabel: 'Trait 2',
            isTrait: true,
          ),
        ],
      );
      expect(cols, hasLength(1));
      expect(cols.single.label, 'Trait 2');
      expect(cols.single.options.single.displayName, 'Kill Clip');
    });
  });

  testWidgets('ItemRichnessPanel shows identity and toggles sections',
      (tester) async {
    const def = CatalogItem(
      hash: 99,
      name: 'Midnight Coup',
      element: 'Solar',
      itemTypeName: 'Hand Cannon',
      frame: 'Adaptive Frame',
      description: 'A single shot can change the course of a battle.',
      isExotic: false,
      ownedCount: 2,
      owned: true,
      slot: 'Kinetic',
    );
    final inst = CatalogInstanceProjection(
      instanceId: 'i1',
      itemHash: 99,
      bucket: 'Kinetic',
      location: 'vault',
      power: 1810,
      isMasterwork: true,
      isCrafted: true,
      plugHashes: const [101],
      socketPlugs: [
        {
          'columnKind': 'barrel',
          'columnLabel': 'Barrel',
          'equippedPlugHash': 101,
          'reusablePlugHashes': [101, 102],
        },
      ],
      plugCards: const [
        ResolvedPlugCard(hash: 101, displayName: 'Fluted Barrel'),
      ],
      syncedAt: '2026-07-26T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemRichnessPanel(
              definition: def,
              instance: inst,
              kindLabel: 'Weapon',
              plugNameByHash: const {101: 'Fluted Barrel', 102: 'Smallbore'},
              initialOpen: const {ItemRichnessSection.perks},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('item_richness_identity')), findsOneWidget);
    expect(find.textContaining('Midnight Coup'), findsWidgets);
    expect(find.byKey(const Key('item_richness_perk_grid')), findsOneWidget);
    expect(find.text('Fluted Barrel'), findsWidgets);
    expect(find.text('Smallbore'), findsOneWidget);

    // Collapse perks
    await tester.tap(find.byKey(const Key('item_richness_toggle_perks')));
    await tester.pump();
    expect(find.byKey(const Key('item_richness_perk_grid')), findsNothing);

    // Expand definition
    await tester.tap(find.byKey(const Key('item_richness_toggle_definition')));
    await tester.pump();
    expect(find.byKey(const Key('item_richness_description')), findsOneWidget);
  });
}
