// Dual-truth Capture PNGs for EntityInfoHotspot (004).
//
// Uses system fonts only (google_fonts network hang avoided). Visual is
// ship-structure evidence: EntityInfoCard chrome via FlapPalette + plain
// TextStyle; residual perk grid omitted from capture frames.
//
// ```text
// flutter test test/entity_info_capture_shots_test.dart
// ```

import 'dart:io';
import 'dart:ui' as ui;

import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Directory _shotsDir() {
  final root = Directory.current.uri.resolve('../../../').toFilePath();
  final dir = Directory(
    '${root}docs${Platform.pathSeparator}ux-redesign'
    '${Platform.pathSeparator}catalog${Platform.pathSeparator}'
    'implementation-shots${Platform.pathSeparator}004-entity-info-hotspot',
  );
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

Future<void> _writePng(WidgetTester tester, Finder finder, String id) async {
  await tester.pump();
  final element = finder.evaluate().single;
  final boundary = element.renderObject! as RenderRepaintBoundary;
  final pngBytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  });
  expect(pngBytes, isNotNull, reason: 'PNG bytes for $id');
  final file = File('${_shotsDir().path}${Platform.pathSeparator}$id.png');
  await file.writeAsBytes(pngBytes!);
  expect(file.lengthSync(), greaterThan(800), reason: id);
}

/// Card that mirrors EntityInfoCard layout without google_fonts.
Widget _infoPanel({
  required String title,
  required String body,
  String? kind,
  List<String> meta = const [],
  String? hashFooter,
  bool empty = false,
  bool compare = false,
  String? baseDesc,
  String? enhDesc,
}) {
  const fg = Color(0xFFF0FDFF);
  const muted = Color(0xFF7DD3E0);
  const line = Color(0x38E8EEF2);
  const raised = Color(0xFF101028);
  const emptyC = Color(0xFF7DD3E0);

  Widget bodyW;
  if (compare && baseDesc != null && enhDesc != null) {
    bodyW = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BASE',
                    style: TextStyle(color: muted, fontSize: 9)),
                const SizedBox(height: 4),
                Text(baseDesc,
                    style: const TextStyle(color: fg, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0x73CEAE33)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ENHANCED',
                    style: TextStyle(color: Color(0xFFCEAE33), fontSize: 9)),
                const SizedBox(height: 4),
                Text(enhDesc,
                    style: const TextStyle(color: fg, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  } else {
    bodyW = Text(
      empty ? kEntityInfoNoDescription : body,
      style: TextStyle(
        color: empty ? emptyC : fg,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }

  return Container(
    key: const Key('entity_info_card'),
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
    decoration: BoxDecoration(
      color: raised,
      border: Border.all(color: const Color(0x61E8EEF2)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                title.isNotEmpty ? title[0] : '?',
                style: const TextStyle(color: muted, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind != null)
                    Text(
                      kind.toUpperCase(),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  Text(
                    title,
                    key: const Key('entity_info_title'),
                    style: const TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(meta.join(' · '),
              style: const TextStyle(color: muted, fontSize: 10)),
        ],
        const SizedBox(height: 8),
        bodyW,
        if (hashFooter != null) ...[
          const SizedBox(height: 8),
          Text(
            hashFooter,
            key: const Key('entity_info_hash_footer'),
            style: TextStyle(
              color: muted.withValues(alpha: 0.55),
              fontSize: 9,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _perkRow({
  required List<({String name, String tier, bool enh})> cells,
  bool edit = false,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final c in cells)
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x80101028),
            border: Border.all(
              color: c.enh
                  ? const Color(0xD9CEAE33)
                  : c.tier == 'pool'
                      ? const Color(0x73E8EEF2)
                      : c.tier == 'want'
                          ? const Color(0xFF2EE6A6)
                          : const Color(0xA600E5FF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.name.isNotEmpty ? c.name[0] : '?',
                style: const TextStyle(color: Color(0xFFF0FDFF), fontSize: 14),
              ),
              if (c.enh)
                const Text('E',
                    style: TextStyle(color: Color(0xFFCEAE33), fontSize: 9)),
              if (edit && c.tier == 'want')
                const Text('W',
                    style: TextStyle(color: Color(0xFF2EE6A6), fontSize: 9)),
              if (edit && c.tier == 'avoid')
                const Text('A',
                    style: TextStyle(color: Color(0xFFFF003C), fontSize: 9)),
            ],
          ),
        ),
    ],
  );
}

Widget _scene({
  required String id,
  required Widget child,
  Size size = const Size(400, 640),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF05050F),
      fontFamily: 'Roboto',
      extensions: [FlapPalette.forBrightness(Brightness.dark)],
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RepaintBoundary(
            key: Key('shot_root'),
            child: ColoredBox(
              color: const Color(0xFF0A0A18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _frenzy =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat.';
const _frenzyBase =
    'Being in combat for an extended time increases damage, handling, and reload until you are out of combat.';
const _frenzyEnh =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat. Enhanced: improved timer and ally radius (fixture).';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> capture(
    WidgetTester tester,
    String id,
    Widget body, {
    Size size = const Size(400, 640),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_scene(id: id, child: body, size: size));
    await tester.pump();
    await _writePng(tester, find.byKey(const Key('shot_root')), id);
  }

  testWidgets('desktop-info-desc-present', (tester) async {
    await capture(
      tester,
      'desktop-info-desc-present',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _perkRow(cells: [
            (name: 'Frenzy', tier: 'sel', enh: false),
            (name: 'Overflow', tier: 'un', enh: false),
            (name: 'Incandescent', tier: 'pool', enh: false),
          ]),
          const SizedBox(height: 12),
          _infoPanel(
            title: 'Frenzy',
            kind: 'Trait',
            meta: const ['① on this copy'],
            body: _frenzy,
          ),
        ],
      ),
    );
  });

  testWidgets('desktop-info-honest-empty', (tester) async {
    await capture(
      tester,
      'desktop-info-honest-empty',
      Column(
        children: [
          _perkRow(cells: [
            (name: 'Frenzy', tier: 'sel', enh: false),
          ]),
          const SizedBox(height: 12),
          _infoPanel(
            title: 'Frenzy',
            kind: 'Trait',
            body: '',
            empty: true,
          ),
        ],
      ),
    );
    expect(find.text(kEntityInfoNoDescription), findsOneWidget);
  });

  testWidgets('desktop-click-selects-not-info', (tester) async {
    await capture(
      tester,
      'desktop-click-selects-not-info',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Click = primary select / W·A cycle — does not open info',
            style: TextStyle(color: Color(0xFFF0FDFF), fontSize: 12),
          ),
          const SizedBox(height: 12),
          _perkRow(
            edit: true,
            cells: [
              (name: 'Frenzy', tier: 'want', enh: false),
              (name: 'Overflow', tier: 'avoid', enh: false),
              (name: 'Incandescent', tier: 'pool', enh: false),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Info stays hover / long-press only',
            style: TextStyle(color: Color(0xFF7DD3E0), fontSize: 11),
          ),
        ],
      ),
    );
  });

  testWidgets('mobile-longpress-info-sheet', (tester) async {
    await capture(
      tester,
      'mobile-longpress-info-sheet',
      size: const Size(390, 720),
      Column(
        children: [
          const Text(
            'Tap = select · long-press / Alt+tap = info sheet',
            style: TextStyle(color: Color(0xFF7DD3E0), fontSize: 11),
          ),
          const SizedBox(height: 12),
          _perkRow(cells: [
            (name: 'Frenzy', tier: 'sel', enh: false),
            (name: 'Overflow', tier: 'un', enh: false),
          ]),
          const Spacer(),
          // Sheet-like panel at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF101028),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0x61E8EEF2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 3,
                  color: const Color(0x61E8EEF2),
                ),
                const SizedBox(height: 10),
                _infoPanel(
                  title: 'Frenzy',
                  kind: 'Trait',
                  body: _frenzy,
                  meta: const ['① on this copy'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('desktop-unknown-no-hash-primary', (tester) async {
    await capture(
      tester,
      'desktop-unknown-no-hash-primary',
      Column(
        children: [
          _perkRow(cells: [
            (name: '?', tier: 'sel', enh: false),
            (name: 'Frenzy', tier: 'un', enh: false),
          ]),
          const SizedBox(height: 12),
          _infoPanel(
            title: 'Unknown perk',
            kind: 'Trait',
            body: '',
            empty: true,
            hashFooter: '#949',
          ),
        ],
      ),
    );
    expect(find.text('Unknown perk'), findsOneWidget);
    expect(find.text('949'), findsNothing);
  });

  testWidgets('desktop-enhanced-selected-info', (tester) async {
    await capture(
      tester,
      'desktop-enhanced-selected-info',
      Column(
        children: [
          _perkRow(cells: [
            (name: 'Frenzy', tier: 'sel', enh: true),
            (name: 'Incandescent', tier: 'un', enh: false),
          ]),
          const SizedBox(height: 12),
          _infoPanel(
            title: 'Frenzy',
            kind: 'Trait',
            body: _frenzyEnh,
            meta: const ['① Enhanced (this copy)'],
          ),
        ],
      ),
    );
  });

  testWidgets('desktop-enhance-compare', (tester) async {
    await capture(
      tester,
      'desktop-enhance-compare',
      _infoPanel(
        title: 'Frenzy',
        kind: 'Trait',
        body: _frenzy,
        compare: true,
        baseDesc: _frenzyBase,
        enhDesc: _frenzyEnh,
        meta: const ['L2 compare when both descs supplied'],
      ),
    );
  });

  testWidgets('desktop-roll-target-hover-info', (tester) async {
    await capture(
      tester,
      'desktop-roll-target-hover-info',
      Column(
        children: [
          _perkRow(
            edit: true,
            cells: [
              (name: 'Frenzy', tier: 'want', enh: false),
              (name: 'Overflow', tier: 'avoid', enh: false),
            ],
          ),
          const SizedBox(height: 12),
          _infoPanel(
            title: 'Frenzy',
            kind: 'Trait',
            body: _frenzy,
            meta: const ['① on this copy', 'roll-target want'],
          ),
        ],
      ),
    );
  });

  testWidgets('desktop-missing-icon-info', (tester) async {
    await capture(
      tester,
      'desktop-missing-icon-info',
      _infoPanel(
        title: 'Frenzy',
        kind: 'Trait',
        body: _frenzy,
        meta: const ['letter fallback · a11y = displayName'],
      ),
    );
  });
}
