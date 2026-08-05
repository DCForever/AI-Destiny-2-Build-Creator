import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/filter_bar_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/group_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/mobile_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/sort_group_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/neon/board_atmosphere_use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 use-case smoke', () {
    testWidgets('sort group default builds without throw', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: sortGroupDefault)));
      await tester.pump();
      expect(find.byKey(const Key('catalog_sort_group_sheet')), findsOneWidget);
      expect(find.byKey(const Key('catalog_sort_keys_list')), findsOneWidget);
    });

    testWidgets('sort group with dims builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: sortGroupWithDims)));
      await tester.pump();
      expect(find.byKey(const Key('group_dim_slot')), findsOneWidget);
    });

    testWidgets('filter bar type icons builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: filterBarTypeIcons)));
      await tester.pump();
      expect(find.byType(CatalogFilterBar), findsOneWidget);
      expect(find.byType(CatalogScopeControl), findsOneWidget);
    });

    testWidgets('filter bar more expanded builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: filterBarMoreExpanded)));
      await tester.pump();
      expect(find.byType(CatalogFilterBar), findsOneWidget);
    });

    testWidgets('outline jump expand demo builds', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 900,
            height: 560,
            child: Builder(builder: groupOutlineJumpExpand),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('wb_outline_jump_demo')), findsOneWidget);
      expect(find.byKey(const Key('catalog_group_outline_rail')), findsOneWidget);
    });

    testWidgets('outline jump expands collapsed group without error', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 900,
            height: 560,
            child: Builder(builder: groupOutlineJumpExpand),
          ),
        ),
      );
      await tester.pump();
      final jumpKeys = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>)
                .value
                .startsWith('catalog_outline_jump_'),
      );
      expect(jumpKeys, findsWidgets);
      await tester.tap(jumpKeys.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile list push frame builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: mobileListPushDetail)));
      await tester.pump();
      expect(find.text('Catalog'), findsWidgets);
      expect(find.byType(CatalogWeaponsGrid), findsOneWidget);
    });

    testWidgets('mobile detail full builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: mobileDetailFull)));
      await tester.pump();
      expect(find.byType(CatalogWeaponDetail), findsOneWidget);
    });

    testWidgets('neon shell builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: neonShellFull)));
      await tester.pump();
      expect(find.byType(NeonShellBackground), findsOneWidget);
      expect(find.byType(NeonZone), findsOneWidget);
    });

    testWidgets('flap board sets builds', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: flapBoardSets)));
      await tester.pump();
      expect(find.byType(FlapBoardHeader), findsOneWidget);
      expect(find.byType(FlapBoardRow), findsWidgets);
    });
  });
}
