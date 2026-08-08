import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(800, 600)}) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  tearDown(() {
    EntityInfoPortal.close();
  });

  testWidgets('EntityInfoData honest empty uses fixed string', (tester) async {
    const data = EntityInfoData(
      id: '1',
      name: 'Frenzy',
      description: '',
    );
    expect(data.hasDescription, isFalse);
    expect(data.displayBody, kEntityInfoNoDescription);

    await tester.pumpWidget(
      _wrap(const EntityInfoCard(data: data)),
    );
    expect(find.byKey(const Key('entity_info_body_empty')), findsOneWidget);
    expect(find.text(kEntityInfoNoDescription), findsOneWidget);
    expect(find.text('Frenzy'), findsOneWidget);
  });

  testWidgets('EntityInfoCard shows description body when present',
      (tester) async {
    const data = EntityInfoData(
      id: '2',
      name: 'Overflow',
      description: 'Loads ammo beyond capacity.',
      kind: 'Trait',
    );
    await tester.pumpWidget(_wrap(const EntityInfoCard(data: data)));
    expect(find.byKey(const Key('entity_info_body')), findsOneWidget);
    expect(find.text('Loads ammo beyond capacity.'), findsOneWidget);
    expect(find.textContaining('TRAIT'), findsOneWidget);
  });

  testWidgets('hover opens popover; tap invokes primary only', (tester) async {
    var primary = 0;
    const data = EntityInfoData(
      id: 'hover1',
      name: 'Frenzy',
      description: 'Combat extended buff.',
    );

    await tester.pumpWidget(
      _wrap(
        EntityInfoHotspot(
          data: data,
          forceSheet: false,
          onPrimary: () => primary++,
          child: const SizedBox(
            key: Key('trigger'),
            width: 48,
            height: 48,
            child: ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('trigger'))));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('entity_info_popover_hover1')), findsOneWidget);
    expect(find.text('Combat extended buff.'), findsOneWidget);
    expect(primary, 0);

    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pump();
    expect(primary, 1);
    // Click must not dismiss requirement of primary; info may still be open.
  });

  testWidgets('long-press opens sheet on narrow layout; tap does not',
      (tester) async {
    var primary = 0;
    const data = EntityInfoData(
      id: 'sheet1',
      name: 'Incandescent',
      description: 'Spreads scorch.',
    );

    await tester.pumpWidget(
      _wrap(
        size: const Size(390, 800),
        EntityInfoHotspot(
          data: data,
          forceSheet: true,
          onPrimary: () => primary++,
          child: const SizedBox(
            key: Key('m_trigger'),
            width: 48,
            height: 48,
            child: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('m_trigger')));
    await tester.pumpAndSettle();
    expect(primary, 1);
    expect(find.byKey(const Key('entity_info_sheet_sheet1')), findsNothing);

    // Long-press via timer arm on pointer down.
    final center = tester.getCenter(find.byKey(const Key('m_trigger')));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('entity_info_sheet_sheet1')), findsOneWidget);
    expect(find.text('Spreads scorch.'), findsOneWidget);
    // Primary not fired again after long-press (suppressed).
    expect(primary, 1);
  });

  testWidgets('unknown name is not bare hash; optional footer', (tester) async {
    const data = EntityInfoData(
      id: '99',
      name: 'Unknown perk',
      description: '',
      nameUnknown: true,
      hashFooter: '#3913600132',
    );
    await tester.pumpWidget(_wrap(const EntityInfoCard(data: data)));
    expect(find.text('Unknown perk'), findsOneWidget);
    expect(find.text('3913600132'), findsNothing);
    expect(find.byKey(const Key('entity_info_hash_footer')), findsOneWidget);
  });

  testWidgets('single-open: second hover replaces first popover', (tester) async {
    const a = EntityInfoData(id: 'a', name: 'A', description: 'Desc A');
    const b = EntityInfoData(id: 'b', name: 'B', description: 'Desc B');

    await tester.pumpWidget(
      _wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EntityInfoHotspot(
              data: a,
              forceSheet: false,
              child: const SizedBox(
                key: Key('t_a'),
                width: 40,
                height: 40,
                child: ColoredBox(color: Colors.green),
              ),
            ),
            const SizedBox(width: 80),
            EntityInfoHotspot(
              data: b,
              forceSheet: false,
              child: const SizedBox(
                key: Key('t_b'),
                width: 40,
                height: 40,
                child: ColoredBox(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byKey(const Key('t_a'))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('entity_info_popover_a')), findsOneWidget);

    await gesture.moveTo(tester.getCenter(find.byKey(const Key('t_b'))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('entity_info_popover_a')), findsNothing);
    expect(find.byKey(const Key('entity_info_popover_b')), findsOneWidget);
    expect(find.text('Desc B'), findsOneWidget);
  });

  testWidgets('perk grid wires entityInfoByHash into hotspot', (tester) async {
    final cols = [
      CatalogPerkColumn(
        label: 'Trait',
        cells: [
          const CatalogPerkCell(
            hash: 100,
            displayName: 'Frenzy',
            selected: true,
          ),
        ],
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 400,
          child: CatalogPerkGrid(
            columns: cols,
            entityInfoByHash: {
              100: const EntityInfoData(
                id: '100',
                name: 'Frenzy',
                description: 'Fixture frenzy body.',
              ),
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('entity_info_hotspot_100')), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('entity_info_hotspot_100'))),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Fixture frenzy body.'), findsOneWidget);
  });
}
