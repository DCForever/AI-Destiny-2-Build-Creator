import 'dart:io';
import 'dart:ui' as ui;

import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMock(
    WidgetTester tester, {
    BuildsMockController? controller,
    Size size = const Size(1440, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: RepaintBoundary(
          key: const Key('builds_mock_shot_root'),
          child: Scaffold(
            body: BuildsMockPage(
              // Synthetic fixture for widget previews / existing mock tests.
              controller: controller ?? BuildsMockController(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('default view is grid with count and no page tabs', (
    tester,
  ) async {
    await pumpMock(tester);

    expect(find.byKey(const Key('builds_mock_banner')), findsOneWidget);
    expect(find.text('MOCK-UP — example data'), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_list')), findsNothing);
    expect(find.byKey(const Key('builds_mock_tabs')), findsNothing);
    expect(find.text('Detail'), findsNothing);
    expect(find.text('Armor pool'), findsNothing);
    expect(find.text('Re-optimize'), findsNothing);
    expect(find.text('New build'), findsNothing);
    expect(
      find.byKey(const Key('builds_mock_count')),
      findsOneWidget,
    );
    expect(find.text('Showing 15 of 15 builds'), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_b01')), findsWidgets);
  });

  testWidgets('grid/list toggle switches layout', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);

    await tester.tap(find.text('List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('builds_mock_card_list')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_list')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsNothing);
    expect(controller.cardLayout, BuildsMockCardLayout.list);

    await tester.tap(find.text('Grid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
    expect(controller.cardLayout, BuildsMockCardLayout.grid);
  });

  testWidgets('card tap opens detail and Back returns', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_detail_back')), findsOneWidget);
    expect(find.byKey(const Key('dim_loadout_details_panel')), findsOneWidget);
    expect(find.text('Armor pool'), findsOneWidget);
    expect(find.text('Re-optimize'), findsOneWidget);
    expect(find.text('Fill In'), findsOneWidget);
    expect(find.text('Optimize'), findsOneWidget);
    expect(find.text('Apply to character'), findsOneWidget);

    final fillIn = tester.widget<FilledButton>(
      find.byKey(const Key('builds_mock_fill_in_b01')),
    );
    final optimize = tester.widget<OutlinedButton>(
      find.byKey(const Key('builds_mock_optimize_b01')),
    );
    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('builds_mock_apply_character_b01')),
    );
    // Fill In + Apply to character enabled; Optimize stays disabled.
    expect(fillIn.onPressed, isNotNull);
    expect(optimize.onPressed, isNull);
    expect(apply.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('builds_mock_fill_in_b01')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('fill_in_dialog_b01')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_cache_error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fill_in_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fill_in_dialog_b01')), findsNothing);

    await tester.tap(find.byKey(const Key('builds_mock_detail_back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsNothing);
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
    expect(controller.showingBuildDetail, isFalse);
  });

  testWidgets('count text updates on search filter', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    expect(find.text('Showing 15 of 15 builds'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('builds_mock_search')),
      'Solipsism',
    );
    await tester.pump();

    expect(find.text('Showing 2 of 15 builds'), findsOneWidget);
    expect(find.text('Solipsism Strand mismatch'), findsWidgets);
    expect(find.text('Starfire Solar battery'), findsNothing);
  });

  testWidgets('grid uses 3 columns wide and 2 when narrow', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller, size: const Size(1440, 900));
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);

    await pumpMock(tester, controller: controller, size: const Size(900, 900));
    // Pane width after library chrome is under ~900 → 2 columns.
    expect(find.byKey(const Key('builds_mock_card_grid_2')), findsOneWidget);
  });

  testWidgets('filters render two per row without overflow', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('OVERFLOWED')) {
        errors.add(details);
      }
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await pumpMock(tester, size: const Size(1280, 900));

    expect(find.byKey(const Key('builds_mock_filter_row_0')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_filter_row_1')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_filter_row_2')), findsOneWidget);

    final row0 = tester.getSize(
      find.byKey(const Key('builds_mock_filter_row_0')),
    );
    // Two Expanded children + 6px gap must fit inside the ~296px rail content.
    expect(row0.width, lessThanOrEqualTo(320));
    expect(errors, isEmpty);
  });

  testWidgets('detail pool shows More than X held flags with Cap', (
    tester,
  ) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('More than 2 held'), findsWidgets);

    await tester.tap(find.byKey(const Key('builds_mock_cap')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('More than 2 held'), findsNothing);
    expect(find.text('More than 4 held'), findsNothing);
  });

  testWidgets('detail readiness shows Ready for Techsec', (tester) async {
    await pumpMock(tester);

    await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_ready_set_techsec')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_mock_ready_badge_set_techsec')),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsWidgets);
  });

  testWidgets('Accept/Reject swap buttons stay disabled on detail', (
    tester,
  ) async {
    await pumpMock(tester);
    await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('builds_mock_swap_accept_swap1')),
    );
    final reject = tester.widget<OutlinedButton>(
      find.byKey(const Key('builds_mock_swap_reject_swap1')),
    );
    expect(accept.onPressed, isNull);
    expect(reject.onPressed, isNull);
  });

  testWidgets('Solipsism non-Prismatic shows review flag on grid card', (
    tester,
  ) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    await tester.enterText(
      find.byKey(const Key('builds_mock_search')),
      'Solipsism Strand',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Solipsism only works with Prismatic'),
      findsWidgets,
    );
  });

  testWidgets('optional desktop screenshots when env dir is set', (
    tester,
  ) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    final configured =
        Platform.environment['BUILDS_MOCK_SCREENSHOT_DIR']?.trim();
    if (configured == null || configured.isEmpty) {
      expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
      controller.setCardLayout(BuildsMockCardLayout.list);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('builds_mock_card_list')), findsOneWidget);
      await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
      expect(find.byKey(const Key('builds_mock_pool')), findsOneWidget);
      expect(find.byKey(const Key('builds_mock_reoptimize')), findsOneWidget);
      return;
    }

    final outDir = Directory(configured)..createSync(recursive: true);

    Future<void> shot(String name) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('builds_mock_shot_root')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes, isNotNull);
        File('${outDir.path}/$name.png').writeAsBytesSync(
          bytes!.buffer.asUint8List(),
        );
      });
    }

    controller.setCardLayout(BuildsMockCardLayout.grid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await shot('builds_mock_card_grid');

    controller.setCardLayout(BuildsMockCardLayout.list);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await shot('builds_mock_card_list');

    await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await shot('builds_mock_build_detail');

    expect(File('${outDir.path}/builds_mock_card_grid.png').existsSync(), isTrue);
    expect(File('${outDir.path}/builds_mock_card_list.png').existsSync(), isTrue);
    expect(
      File('${outDir.path}/builds_mock_build_detail.png').existsSync(),
      isTrue,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
