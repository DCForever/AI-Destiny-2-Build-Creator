import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_widgetbook/use_cases/sets/armor_use_cases.dart';
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

  group('Sets Optimize Widgetbook use-cases', () {
    testWidgets('default: slim chrome, header sort, replace-all', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: setsOptimizeConfirm)));
      await tester.pump();

      expect(find.byKey(const Key('sets_optimize_confirm_shell')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_seed_class')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_seed_exotic')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_sort')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_th_total')), findsOneWidget);
      expect(
        find.byKey(const Key('sets_optimize_replace_all_warning')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sets_optimize_include_current')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_optimize_th_Health')));
      await tester.pump();
    });

    testWidgets('mins active: Melee highlight + readout', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: setsOptimizeMins)));
      await tester.pump();

      expect(find.textContaining('≥82'), findsWidgets);
      expect(
        find.byKey(const Key('sets_optimize_stat_highlight_Melee')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sets_optimize_col_highlight_Melee')),
        findsOneWidget,
      );
    });

    testWidgets('empty board: no replace-all warning', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: setsOptimizeEmptyBoard)));
      await tester.pump();

      expect(find.byKey(const Key('sets_optimize_confirm_shell')), findsOneWidget);
      expect(
        find.byKey(const Key('sets_optimize_replace_all_warning')),
        findsNothing,
      );
      expect(find.byKey(const Key('sets_optimize_include_current')), findsNothing);
    });
  });
}
