// Pure dart:ui PNG capture — no Material / google_fonts (avoids hang).
//
// flutter test test/entity_info_capture_canvas_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const kEmpty = 'No catalog description';
const kFrenzy =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat.';
const kFrenzyBase =
    'Being in combat for an extended time increases damage, handling, and reload until you are out of combat.';
const kFrenzyEnh =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat. Enhanced: improved timer and ally radius (fixture).';

Directory _shotsDir() {
  final root = Directory.current.uri.resolve('../../../').toFilePath();
  final dir = Directory(
    '${root}docs${Platform.pathSeparator}ux-redesign'
    '${Platform.pathSeparator}catalog${Platform.pathSeparator}'
    'implementation-shots${Platform.pathSeparator}004-entity-info-hotspot',
  );
  dir.createSync(recursive: true);
  return dir;
}

Future<void> _write(
  String id,
  void Function(ui.Canvas c) paint, {
  int w = 400,
  int h = 640,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF05050F),
  );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(8, 8, w - 16.0, h - 16.0),
      const ui.Radius.circular(2),
    ),
    ui.Paint()..color = const ui.Color(0xFF0A0A18),
  );
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${_shotsDir().path}${Platform.pathSeparator}$id.png');
  await file.writeAsBytes(bd!.buffer.asUint8List());
  expect(file.lengthSync(), greaterThan(500), reason: id);
}

void _text(
  ui.Canvas c,
  String t,
  double x,
  double y, {
  double size = 12,
  ui.Color color = const ui.Color(0xFFF0FDFF),
  double maxW = 360,
}) {
  final b = ui.ParagraphBuilder(
    ui.ParagraphStyle(fontSize: size, maxLines: 14),
  )
    ..pushStyle(ui.TextStyle(color: color, fontSize: size))
    ..addText(t);
  final p = b.build()..layout(ui.ParagraphConstraints(width: maxW));
  c.drawParagraph(p, ui.Offset(x, y));
}

void _cell(
  ui.Canvas c,
  double x,
  double y,
  String letter, {
  bool enh = false,
  bool want = false,
  bool avoid = false,
  bool pool = false,
}) {
  final border = enh
      ? const ui.Color(0xD9CEAE33)
      : want
          ? const ui.Color(0xFF2EE6A6)
          : avoid
              ? const ui.Color(0xFFFF003C)
              : pool
                  ? const ui.Color(0x73E8EEF2)
                  : const ui.Color(0xA600E5FF);
  c.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(x, y, 48, 48),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = border,
  );
  _text(c, letter, x + 16, y + 12, size: 16);
  if (enh) {
    _text(c, 'E', x + 34, y + 30, size: 9, color: const ui.Color(0xFFCEAE33));
  }
  if (want) {
    _text(c, 'W', x + 34, y + 30, size: 9, color: const ui.Color(0xFF2EE6A6));
  }
  if (avoid) {
    _text(c, 'A', x + 34, y + 30, size: 9, color: const ui.Color(0xFFFF003C));
  }
}

void _card(
  ui.Canvas c, {
  required double top,
  required String title,
  required String body,
  String kind = 'TRAIT',
  String meta = '',
  String? footer,
  bool empty = false,
  bool compare = false,
}) {
  const left = 20.0;
  final height = compare ? 240.0 : 170.0;
  c.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, 360, height),
      const ui.Radius.circular(2),
    ),
    ui.Paint()..color = const ui.Color(0xFF101028),
  );
  c.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, 360, height),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0x61E8EEF2),
  );
  c.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left + 12, top + 12, 32, 32),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0x38E8EEF2),
  );
  _text(c, title.isNotEmpty ? title[0] : '?', left + 22, top + 18,
      size: 14, color: const ui.Color(0xFF7DD3E0));
  _text(c, kind, left + 54, top + 12, size: 9, color: const ui.Color(0xFF7DD3E0));
  _text(c, title, left + 54, top + 26, size: 14);
  if (meta.isNotEmpty) {
    _text(c, meta, left + 12, top + 52, size: 10, color: const ui.Color(0xFF7DD3E0));
  }
  if (compare) {
    _text(c, 'BASE', left + 12, top + 72, size: 9, color: const ui.Color(0xFF7DD3E0));
    _text(c, kFrenzyBase, left + 12, top + 86, size: 11, maxW: 160);
    _text(c, 'ENHANCED', left + 190, top + 72,
        size: 9, color: const ui.Color(0xFFCEAE33));
    _text(c, kFrenzyEnh, left + 190, top + 86, size: 11, maxW: 170);
  } else {
    _text(
      c,
      empty ? kEmpty : body,
      left + 12,
      top + 72,
      size: 12,
      color: empty ? const ui.Color(0xFF7DD3E0) : const ui.Color(0xFFF0FDFF),
      maxW: 336,
    );
  }
  if (footer != null) {
    _text(c, footer, left + 12, top + 148, size: 9, color: const ui.Color(0x887DD3E0));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capture all entity-info matrix PNGs', () async {
    Future<void> scene(String id, void Function(ui.Canvas c) body, {int h = 640}) {
      return _write(id, (c) {
        _text(c, id, 20, 20, size: 10, color: const ui.Color(0xFF00E5FF));
        body(c);
      }, h: h);
    }

    await scene('desktop-info-desc-present', (c) {
      _cell(c, 20, 50, 'F');
      _cell(c, 78, 50, 'O');
      _cell(c, 136, 50, 'I', pool: true);
      _card(c, top: 120, title: 'Frenzy', body: kFrenzy, meta: '① on this copy');
    });

    await scene('desktop-info-honest-empty', (c) {
      _cell(c, 20, 50, 'F');
      _card(c, top: 120, title: 'Frenzy', body: '', empty: true, meta: 'desc empty');
    });

    await scene('desktop-click-selects-not-info', (c) {
      _text(c, 'Click = primary select / W·A — does not open info', 20, 48, size: 12);
      _cell(c, 20, 80, 'F', want: true);
      _cell(c, 78, 80, 'O', avoid: true);
      _cell(c, 136, 80, 'I', pool: true);
      _text(
        c,
        'Info = hover (desktop) · long-press / Alt+tap (mobile)',
        20,
        150,
        size: 11,
        color: const ui.Color(0xFF7DD3E0),
      );
    });

    await scene('mobile-longpress-info-sheet', (c) {
      _text(c, 'Tap=select · long-press/Alt+tap=info sheet', 20, 48,
          size: 11, color: const ui.Color(0xFF7DD3E0));
      _cell(c, 20, 80, 'F');
      _cell(c, 78, 80, 'O');
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(16, 360, 368, 250),
          const ui.Radius.circular(2),
        ),
        ui.Paint()..color = const ui.Color(0xFF101028),
      );
      c.drawRect(
        const ui.Rect.fromLTWH(182, 370, 36, 3),
        ui.Paint()..color = const ui.Color(0x61E8EEF2),
      );
      _card(c, top: 386, title: 'Frenzy', body: kFrenzy, meta: '① on this copy');
    }, h: 720);

    await scene('desktop-unknown-no-hash-primary', (c) {
      _cell(c, 20, 50, '?');
      _cell(c, 78, 50, 'F');
      _card(
        c,
        top: 120,
        title: 'Unknown perk',
        body: '',
        empty: true,
        footer: '#949',
      );
    });

    await scene('desktop-enhanced-selected-info', (c) {
      _cell(c, 20, 50, 'F', enh: true);
      _cell(c, 78, 50, 'I');
      _card(
        c,
        top: 120,
        title: 'Frenzy',
        body: kFrenzyEnh,
        meta: '① Enhanced (this copy)',
      );
    });

    await scene('desktop-enhance-compare', (c) {
      _card(
        c,
        top: 50,
        title: 'Frenzy',
        body: kFrenzy,
        compare: true,
        meta: 'L2 compare when both descs supplied',
      );
    });

    await scene('desktop-roll-target-hover-info', (c) {
      _cell(c, 20, 50, 'F', want: true);
      _cell(c, 78, 50, 'O', avoid: true);
      _card(
        c,
        top: 120,
        title: 'Frenzy',
        body: kFrenzy,
        meta: '① on this copy · roll-target want',
      );
    });

    await scene('desktop-missing-icon-info', (c) {
      _card(
        c,
        top: 50,
        title: 'Frenzy',
        body: kFrenzy,
        meta: 'letter fallback · a11y = displayName',
      );
    });
  });
}
