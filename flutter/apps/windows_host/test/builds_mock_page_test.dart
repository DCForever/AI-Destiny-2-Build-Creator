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
  }) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: RepaintBoundary(
          key: const Key('builds_mock_shot_root'),
          child: Scaffold(
            body: BuildsMockPage(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders mock banner, list, and hybrid card', (tester) async {
    await pumpMock(tester);

    expect(find.byKey(const Key('builds_mock_banner')), findsOneWidget);
    expect(find.text('MOCK-UP — example data'), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_list')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_detail')), findsOneWidget);
    expect(find.text('Techsec Prismatic core'), findsWidgets);

    // Default layout is detail hybrid card for the selected build.
    expect(find.byKey(const Key('builds_mock_card_b01')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_fill_in_b01')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_optimize_b01')), findsOneWidget);
    expect(find.text('Fill In'), findsOneWidget);
    expect(find.text('Optimize'), findsOneWidget);

    final fillIn = tester.widget<FilledButton>(
      find.byKey(const Key('builds_mock_fill_in_b01')),
    );
    final optimize = tester.widget<OutlinedButton>(
      find.byKey(const Key('builds_mock_optimize_b01')),
    );
    expect(fillIn.onPressed, isNull);
    expect(optimize.onPressed, isNull);

    // Hybrid card content from B + E.
    expect(find.text('EXOTIC ARMOR'), findsOneWidget);
    expect(find.text('EXOTIC WEAPON'), findsOneWidget);
    expect(find.text('Osmiomancy Gloves'), findsWidgets);
    expect(find.text('Osteo Striga'), findsWidgets);
    expect(find.textContaining('Osmiomancy grenade regen'), findsOneWidget);
    expect(find.textContaining('2pc Techsec'), findsWidgets);
    expect(find.text('Heretical Path'), findsOneWidget);
    expect(find.text('ARMOR'), findsOneWidget);
    expect(find.text('STATS'), findsOneWidget);
    expect(find.text('DIM link details not loaded'), findsOneWidget);
  });

  testWidgets('grid and list layouts show cards with disabled actions', (
    tester,
  ) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('builds_mock_card_grid')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_b01')), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('builds_mock_fill_in_b01')).first,
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('builds_mock_optimize_b01')).first,
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('builds_mock_card_list')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_card_b01')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('builds_mock_fill_in_b01')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('builds_mock_optimize_b01')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('search filter narrows the list', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    await tester.enterText(
      find.byKey(const Key('builds_mock_search')),
      'Solipsism',
    );
    await tester.pump();

    expect(find.text('Solipsism Strand mismatch'), findsWidgets);
    expect(find.text('Starfire Solar battery'), findsNothing);
  });

  testWidgets('cap setting toggles More than X held flags', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    // Default cap 2: Techsec helmet held=4 → over.
    await tester.tap(find.text('Armor pool'));
    await tester.pumpAndSettle();
    expect(find.text('More than 2 held'), findsWidgets);

    await tester.tap(find.byKey(const Key('builds_mock_cap')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();

    expect(find.text('More than 2 held'), findsNothing);
    expect(find.text('More than 4 held'), findsNothing);
  });

  testWidgets('readiness shows Ready for Techsec (10 builds / 3 uses)', (
    tester,
  ) async {
    await pumpMock(tester);

    await tester.tap(find.text('Re-optimize'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('builds_mock_ready_set_techsec')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_mock_ready_badge_set_techsec')),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsWidgets);
    expect(
      find.byKey(const Key('builds_mock_ready_badge_set_walk')),
      findsOneWidget,
    );
  });

  testWidgets('Accept/Reject swaps only change local UI state', (tester) async {
    await pumpMock(tester);
    await tester.tap(find.text('Re-optimize'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('builds_mock_swap_accept_swap1')));
    await tester.pump();
    expect(find.text('Accepted (mock)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('builds_mock_swap_reject_swap2')));
    await tester.pump();
    expect(find.text('Rejected (mock)'), findsOneWidget);
  });

  testWidgets('Solipsism non-Prismatic shows review flag', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    controller.selectBuild('b11');
    await tester.pump();

    expect(
      find.text('Solipsism only works with Prismatic'),
      findsWidgets,
    );
  });

  testWidgets('optional desktop screenshots when env dir is set', (tester) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    final configured = Platform.environment['BUILDS_MOCK_SCREENSHOT_DIR']?.trim();
    if (configured == null || configured.isEmpty) {
      // Off by default: no filesystem writes. Still visit each main state.
      expect(find.byKey(const Key('builds_mock_detail')), findsOneWidget);
      controller.setCardLayout(BuildsMockCardLayout.grid);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('builds_mock_card_grid')), findsOneWidget);
      controller.setCardLayout(BuildsMockCardLayout.list);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('builds_mock_card_list')), findsOneWidget);
      await tester.tap(find.text('Armor pool'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('builds_mock_pool')), findsOneWidget);
      await tester.tap(find.text('Re-optimize'));
      await tester.pumpAndSettle();
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

    controller.setCardLayout(BuildsMockCardLayout.detail);
    await tester.pumpAndSettle();
    await shot('builds_mock_list_detail');

    controller.setCardLayout(BuildsMockCardLayout.grid);
    await tester.pumpAndSettle();
    await shot('builds_mock_card_grid');

    controller.setCardLayout(BuildsMockCardLayout.list);
    await tester.pumpAndSettle();
    await shot('builds_mock_card_list');

    await tester.tap(find.text('Armor pool'));
    await tester.pumpAndSettle();
    await shot('builds_mock_pool_grid');

    await tester.tap(find.text('Re-optimize'));
    await tester.pumpAndSettle();
    await shot('builds_mock_reoptimize');

    expect(File('${outDir.path}/builds_mock_list_detail.png').existsSync(), isTrue);
    expect(File('${outDir.path}/builds_mock_card_grid.png').existsSync(), isTrue);
    expect(File('${outDir.path}/builds_mock_card_list.png').existsSync(), isTrue);
    expect(File('${outDir.path}/builds_mock_pool_grid.png').existsSync(), isTrue);
    expect(File('${outDir.path}/builds_mock_reoptimize.png').existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
