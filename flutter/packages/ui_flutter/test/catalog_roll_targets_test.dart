import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: SizedBox(width: 400, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('catalog roll target pure helpers', () {
    test('columnKey is socketIndex (manifest socket), not labels', () {
      expect(
        catalogRollColumnKey({'socketIndex': 3, 'columnLabel': 'Trait 1'}),
        'socket_3',
      );
      expect(
        catalogRollColumnKey({'columnKind': 'barrel'}, index: 1),
        'barrel_1',
      );
      expect(catalogRollColumnKey({}, index: 2), 'col_2');
      // Labels alone never become keys (would collide Trait/Trait).
      expect(
        catalogRollColumnKey({'columnLabel': 'Trait'}, index: 4),
        isNot(catalogRollColumnKey({'columnLabel': 'Trait'}, index: 5)),
      );
    });

    test('plugsByColumnFromSockets maps by socketIndex', () {
      final map = catalogRollPlugsByColumnFromSockets(const [
        {
          'socketIndex': 0,
          'columnLabel': 'Barrel',
          'equippedPlugHash': 10,
        },
        {
          'socketIndex': 1,
          'columnLabel': 'Trait',
          'equippedPlugHash': 30,
        },
        {
          'socketIndex': 2,
          'columnLabel': 'Trait',
          'equippedPlugHash': 40,
        },
      ]);
      expect(map['socket_0'], 10);
      expect(map['socket_1'], 30);
      expect(map['socket_2'], 40);
    });

    test('allPlugsByColumn includes reusables for plug-level score', () {
      final map = catalogRollAllPlugsByColumnFromSockets(const [
        {
          'socketIndex': 1,
          'columnLabel': 'Trait',
          'equippedPlugHash': 30,
          'reusablePlugHashes': [30, 31, 32],
        },
      ]);
      expect(map['socket_1'], {30, 31, 32});
    });

    test('Want|Avoid|Off cycle and apply', () {
      expect(
        nextCatalogRollPlugMode(CatalogRollPlugTargetMode.off),
        CatalogRollPlugTargetMode.want,
      );
      expect(
        nextCatalogRollPlugMode(CatalogRollPlugTargetMode.want),
        CatalogRollPlugTargetMode.avoid,
      );
      expect(
        nextCatalogRollPlugMode(CatalogRollPlugTargetMode.avoid),
        CatalogRollPlugTargetMode.off,
      );

      var pref = <String, Set<int>>{};
      var avoid = <String, Set<int>>{};
      var r = applyCatalogRollPlugMode(
        columnKey: 'Trait',
        plugHash: 30,
        mode: CatalogRollPlugTargetMode.want,
        preferredByColumn: pref,
        avoidByColumn: avoid,
      );
      expect(r.preferredByColumn['Trait'], {30});
      r = applyCatalogRollPlugMode(
        columnKey: 'Trait',
        plugHash: 30,
        mode: CatalogRollPlugTargetMode.avoid,
        preferredByColumn: r.preferredByColumn,
        avoidByColumn: r.avoidByColumn,
      );
      expect(r.preferredByColumn['Trait'], isNull);
      expect(r.avoidByColumn['Trait'], {30});
    });

    test('overlap detection', () {
      expect(
        catalogRollTargetHasOverlap(
          preferredByColumn: {
            't': {1, 2},
          },
          avoidByColumn: {
            't': {2, 9},
          },
        ),
        isTrue,
      );
      expect(
        catalogRollTargetHasOverlap(
          preferredByColumn: {
            't': {1},
          },
          avoidByColumn: {
            't': {9},
          },
        ),
        isFalse,
      );
    });

    test('CatalogInstanceRollScore labels', () {
      const s = CatalogInstanceRollScore(
        preferredMatched: 2,
        preferredScored: 3,
        avoidHits: 1,
        avoidScored: 2,
      );
      expect(s.hasAnyScoreDimension, isTrue);
      expect(s.preferredSegLabel, '2/3');
      expect(s.avoidSegLabel, 'Av 1');
      expect(s.semanticsScoreLabel, '2 of 3 preferred, 1 avoid hit');
      // Without host flag, N!=M is not perfect.
      expect(s.isPerfectPreferred, isFalse);
      // Host may mark column-level perfect even when N!=M (3/6 plug quality).
      const withColumns = CatalogInstanceRollScore(
        preferredMatched: 3,
        preferredScored: 6,
        avoidHits: 0,
        avoidScored: 1,
        allPreferredColumnsMatched: true,
      );
      expect(withColumns.isPerfectPreferred, isTrue);
      expect(withColumns.preferredSegLabel, '3/6');
      expect(
        const CatalogInstanceRollScore(
          preferredMatched: 0,
          preferredScored: 0,
          avoidHits: 0,
          avoidScored: 0,
        ).hasAnyScoreDimension,
        isFalse,
      );
    });
  });

  group('CatalogRollTargets chrome', () {
    testWidgets('switcher shows Off + names; no bare hash primary labels',
        (tester) async {
      String? active;
      await tester.pumpWidget(
        _wrap(
          CatalogRollTargets(
            targets: const [
              CatalogRollTargetOption(id: 'rt-pve', name: 'PvE'),
              CatalogRollTargetOption(id: 'rt-pvp', name: 'PvP'),
            ],
            activeTargetId: active,
            onActiveChanged: (id) => active = id,
            onEdit: () {},
            onNew: () {},
            onDelete: () {},
            canDelete: false,
          ),
        ),
      );

      expect(find.byKey(const Key('catalog_roll_targets')), findsOneWidget);
      expect(find.byKey(const Key('roll_target_opt_off')), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);
      expect(find.text('PVE'), findsOneWidget);
      expect(find.text('PVP'), findsOneWidget);
      // No bare id/hash as primary label.
      expect(find.textContaining('rt-pve'), findsNothing);
      expect(find.textContaining('#'), findsNothing);
      expect(find.byKey(const Key('roll_target_new')), findsOneWidget);
      expect(find.byKey(const Key('roll_target_edit')), findsOneWidget);
      expect(find.byKey(const Key('roll_target_delete')), findsOneWidget);

      await tester.tap(find.byKey(const Key('roll_target_opt_rt-pve')));
      await tester.pump();
      expect(active, 'rt-pve');

      await tester.tap(find.byKey(const Key('roll_target_opt_off')));
      await tester.pump();
      expect(active, isNull);
    });

    testWidgets('editor Want cycle chrome; overlap soft error disables Save',
        (tester) async {
      var draftName = 'PvE';
      var saved = false;
      var cancelled = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogRollTargets(
                targets: const [
                  CatalogRollTargetOption(id: 'rt1', name: 'PvE'),
                ],
                activeTargetId: 'rt1',
                activeTargetName: 'PvE',
                onActiveChanged: (_) {},
                editing: true,
                draftName: draftName,
                onDraftNameChanged: (v) => setState(() => draftName = v),
                hasOverlap: true,
                canSave: false,
                onSave: () => saved = true,
                onCancel: () => cancelled = true,
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('catalog_roll_target_editor')), findsOneWidget);
      expect(find.byKey(const Key('roll_target_overlap_error')), findsOneWidget);
      expect(find.textContaining('Save disabled'), findsOneWidget);
      expect(find.textContaining('equip/export still open'), findsOneWidget);

      // Save button present but disabled (onTap null via canSave).
      final saveInk = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('roll_target_save')),
          matching: find.byType(InkWell),
        ),
      );
      expect(saveInk.onTap, isNull);
      expect(saved, isFalse);

      await tester.tap(find.byKey(const Key('roll_target_cancel')));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('save enabled when named + no overlap', (tester) async {
      var saved = false;
      await tester.pumpWidget(
        _wrap(
          CatalogRollTargets(
            targets: const [
              CatalogRollTargetOption(id: 'rt1', name: 'PvE'),
            ],
            activeTargetId: 'rt1',
            activeTargetName: 'PvE',
            onActiveChanged: (_) {},
            editing: true,
            draftName: 'PvE',
            hasOverlap: false,
            canSave: true,
            onSave: () => saved = true,
            onCancel: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('roll_target_overlap_error')), findsNothing);
      await tester.tap(find.byKey(const Key('roll_target_save')));
      await tester.pump();
      expect(saved, isTrue);
    });
  });
}
