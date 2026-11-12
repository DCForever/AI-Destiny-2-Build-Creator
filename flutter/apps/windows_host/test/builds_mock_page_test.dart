import 'dart:io';
import 'dart:ui' as ui;

import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Prefer bundled assets/google_fonts/*.ttf over network (blocked in tests).
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpMock(
    WidgetTester tester, {
    BuildsMockController? controller,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.dark),
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

  testWidgets('renders mock banner, list, and detail', (tester) async {
    await pumpMock(tester);

    expect(find.byKey(const Key('builds_mock_banner')), findsOneWidget);
    expect(find.text('MOCK-UP — example data'), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_list')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_detail')), findsOneWidget);
    expect(find.text('Techsec Prismatic core'), findsWidgets);
    expect(find.byKey(const Key('builds_mock_open_dim')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_propose_swap')), findsOneWidget);
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

  testWidgets('writes desktop screenshots for list/detail, pool, reoptimize', (
    tester,
  ) async {
    final controller = BuildsMockController();
    await pumpMock(tester, controller: controller);

    final outDir = Directory('/opt/cursor/artifacts');
    outDir.createSync(recursive: true);

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

    await shot('builds_mock_list_detail');

    await tester.tap(find.text('Armor pool'));
    await tester.pumpAndSettle();
    await shot('builds_mock_pool_grid');

    await tester.tap(find.text('Re-optimize'));
    await tester.pumpAndSettle();
    await shot('builds_mock_reoptimize');

    expect(
      File('${outDir.path}/builds_mock_list_detail.png').existsSync(),
      isTrue,
    );
    expect(
      File('${outDir.path}/builds_mock_pool_grid.png').existsSync(),
      isTrue,
    );
    expect(
      File('${outDir.path}/builds_mock_reoptimize.png').existsSync(),
      isTrue,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
