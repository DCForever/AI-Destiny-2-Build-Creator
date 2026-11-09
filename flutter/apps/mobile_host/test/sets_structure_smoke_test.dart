import 'package:destiny2_mobile_host/sets/sets_structure_pages.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('structure sheets mount stepped create chrome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapThemeBase(),
        home: const SetsStructurePage(),
      ),
    );
    expect(find.byKey(const Key('sets_mobile_structure')), findsOneWidget);
    expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);

    await tester.tap(find.byKey(const Key('sets_library_new')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sets_mobile_create_sheet')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_step_dots')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_continue')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_footer')), findsOneWidget);
    expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);

    // Advance Type → Class structure.
    await tester.tap(find.byKey(const Key('sets_create_continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sets_create_class')), findsOneWidget);
    expect(find.byKey(const Key('sets_create_back')), findsOneWidget);

    // Dismiss sheet via barrier tap (structure-only; not Windows Capture gate).
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });
}
