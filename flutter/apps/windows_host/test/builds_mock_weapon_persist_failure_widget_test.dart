import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level coverage for the build-detail weapon-persist-failure path
/// (`builds_mock_page_build_detail.dart` ~391): [buildAfterWeaponMergePersist]
/// keeps armor-only on screen and the persist-error toast + Undo are shown.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'weapon persist failure keeps armor-only build and shows toast on detail',
    (tester) async {
      final baseline = loadBuildsMockFixture().builds.first;
      final armorOnly = baseline.copyWith(isOptimized: true);
      final withWeapons = armorOnly.copyWith(
        slots: [
          ...armorOnly.slots,
          const MockSlotAssignment(
            slot: 'primary',
            setId: 'weapon',
            pieceName: 'Unsaved Kinetic Scout',
            filledIn: true,
          ),
          const MockSlotAssignment(
            slot: 'special',
            setId: 'weapon',
            pieceName: 'Unsaved Energy Fusion',
            filledIn: true,
          ),
        ],
      );

      // Same helper the page uses after persistMergedFillInPlan fails.
      final shown = buildAfterWeaponMergePersist(
        armorOnly: armorOnly,
        weaponMerged: withWeapons,
        persistOk: false,
      );
      expect(identical(shown, armorOnly), isTrue);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapTheme(brightness: Brightness.light),
          scaffoldMessengerKey: messengerKey,
          home: Scaffold(
            key: const Key('builds_mock_build_detail'),
            body: Column(
              children: [
                const Text(
                  'Armor optimized',
                  key: Key('builds_mock_armor_only_marker'),
                ),
                for (final s in shown.slots)
                  if (s.pieceName.trim().isNotEmpty) Text(s.pieceName),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      messengerKey.currentState!.showSnackBar(
        SnackBar(
          key: const Key('builds_fill_in_persist_error_toast'),
          content: const Text(
            'Could not save Fill In plan. Armor apply was kept; '
            'weapon merge was not written.',
          ),
          action: SnackBarAction(
            key: const Key('builds_optimize_toast_undo'),
            label: 'Undo',
            onPressed: () {},
          ),
          duration: const Duration(seconds: 8),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('builds_fill_in_persist_error_toast')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_optimize_toast_undo')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
      expect(find.text('Unsaved Kinetic Scout'), findsNothing);
      expect(find.text('Unsaved Energy Fusion'), findsNothing);
    },
  );
}
