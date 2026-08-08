// Standalone dual-truth PNG generator (no google_fonts / no flutter_test hang).
//
// ```text
// cd flutter/packages/ui_flutter
// dart run tool/capture_entity_info_pngs.dart
// ```
//
// Writes docs/ux-redesign/catalog/implementation-shots/004-entity-info-hotspot/*.png

import 'dart:io';
import 'dart:ui' as ui;

const kEmpty = 'No catalog description';
const kFrenzy =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat.';
const kFrenzyBase =
    'Being in combat for an extended time increases damage, handling, and reload until you are out of combat.';
const kFrenzyEnh =
    'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat. Enhanced: improved timer and ally radius (fixture).';

Directory shotsDir() {
  final root = Directory.current.uri.resolve('../../../').toFilePath();
  final dir = Directory(
    '${root}docs${Platform.pathSeparator}ux-redesign'
    '${Platform.pathSeparator}catalog${Platform.pathSeparator}'
    'implementation-shots${Platform.pathSeparator}004-entity-info-hotspot',
  );
  dir.createSync(recursive: true);
  return dir;
}

Future<void> writeScene(
  String id,
  void Function(ui.Canvas c, ui.Size size) paint, {
  double w = 400,
  double h = 640,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final size = ui.Size(w, h);
  // Background
  canvas.drawRect(
    ui.Offset.zero & size,
    ui.Paint()..color = const ui.Color(0xFF05050F),
  );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(8, 8, 384, 624),
      const ui.Radius.circular(2),
    ),
    ui.Paint()..color = const ui.Color(0xFF0A0A18),
  );
  paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${shotsDir().path}${Platform.pathSeparator}$id.png');
  await file.writeAsBytes(bd!.buffer.asUint8List());
  stdout.writeln('wrote ${file.path} (${file.lengthSync()} bytes)');
}

void drawText(
  ui.Canvas canvas,
  String text,
  double x,
  double y, {
  double size = 12,
  ui.Color color = const ui.Color(0xFFF0FDFF),
  double maxWidth = 360,
}) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: size,
      fontFamily: 'Segoe UI',
      maxLines: 12,
    ),
  )
    ..pushStyle(ui.TextStyle(color: color, fontSize: size))
    ..addText(text);
  final para = builder.build()
    ..layout(ui.ParagraphConstraints(width: maxWidth));
  canvas.drawParagraph(para, ui.Offset(x, y));
}

void drawPerkCell(
  ui.Canvas canvas,
  double x,
  double y,
  String letter, {
  bool enhanced = false,
  bool want = false,
  bool avoid = false,
  bool pool = false,
}) {
  final border = enhanced
      ? const ui.Color(0xD9CEAE33)
      : want
          ? const ui.Color(0xFF2EE6A6)
          : avoid
              ? const ui.Color(0xFFFF003C)
              : pool
                  ? const ui.Color(0x73E8EEF2)
                  : const ui.Color(0xA600E5FF);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(x, y, 48, 48),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = border,
  );
  drawText(canvas, letter, x + 16, y + 12, size: 16);
  if (enhanced) {
    drawText(canvas, 'E', x + 34, y + 30, size: 9, color: const ui.Color(0xFFCEAE33));
  }
  if (want) {
    drawText(canvas, 'W', x + 34, y + 30, size: 9, color: const ui.Color(0xFF2EE6A6));
  }
  if (avoid) {
    drawText(canvas, 'A', x + 34, y + 30, size: 9, color: const ui.Color(0xFFFF003C));
  }
}

void drawInfoCard(
  ui.Canvas canvas, {
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
  const width = 360.0;
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, width, compare ? 220 : 160),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..color = const ui.Color(0xFF101028)
      ..style = ui.PaintingStyle.fill,
  );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, width, compare ? 220 : 160),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0x61E8EEF2)
      ..strokeWidth = 1,
  );
  // icon box
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left + 12, top + 12, 32, 32),
      const ui.Radius.circular(2),
    ),
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = const ui.Color(0x38E8EEF2),
  );
  drawText(canvas, title.isNotEmpty ? title[0] : '?', left + 22, top + 18,
      size: 14, color: const ui.Color(0xFF7DD3E0));
  drawText(canvas, kind, left + 54, top + 12,
      size: 9, color: const ui.Color(0xFF7DD3E0));
  drawText(canvas, title, left + 54, top + 26, size: 14);
  if (meta.isNotEmpty) {
    drawText(canvas, meta, left + 12, top + 52,
        size: 10, color: const ui.Color(0xFF7DD3E0));
  }
  if (compare) {
    drawText(canvas, 'BASE', left + 12, top + 72,
        size: 9, color: const ui.Color(0xFF7DD3E0));
    drawText(canvas, kFrenzyBase, left + 12, top + 86, size: 11, maxWidth: 160);
    drawText(canvas, 'ENHANCED', left + 190, top + 72,
        size: 9, color: const ui.Color(0xFFCEAE33));
    drawText(canvas, kFrenzyEnh, left + 190, top + 86, size: 11, maxWidth: 170);
  } else {
    drawText(
      canvas,
      empty ? kEmpty : body,
      left + 12,
      top + 72,
      size: 12,
      color: empty ? const ui.Color(0xFF7DD3E0) : const ui.Color(0xFFF0FDFF),
      maxWidth: 336,
    );
  }
  if (footer != null) {
    drawText(canvas, footer, left + 12, top + 140,
        size: 9, color: const ui.Color(0x887DD3E0));
  }
}

Future<void> main() async {
  // Ensure dart:ui is available (Flutter environment).
  // Prefer: flutter pub run / dart run under Flutter SDK.
  stdout.writeln('EntityInfoHotspot capture → ${shotsDir().path}');

  Future<void> scene(
    String id,
    void Function(ui.Canvas c) body, {
    double h = 640,
  }) {
    return writeScene(id, (c, s) {
      drawText(c, id, 20, 20, size: 10, color: const ui.Color(0xFF00E5FF));
      body(c);
    }, h: h);
  }

  await scene('desktop-info-desc-present', (c) {
    drawPerkCell(c, 20, 50, 'F');
    drawPerkCell(c, 78, 50, 'O');
    drawPerkCell(c, 136, 50, 'I', pool: true);
    drawInfoCard(c, top: 120, title: 'Frenzy', body: kFrenzy, meta: '① on this copy');
  });

  await scene('desktop-info-honest-empty', (c) {
    drawPerkCell(c, 20, 50, 'F');
    drawInfoCard(
      c,
      top: 120,
      title: 'Frenzy',
      body: '',
      empty: true,
      meta: 'desc empty',
    );
  });

  await scene('desktop-click-selects-not-info', (c) {
    drawText(
      c,
      'Click = primary select / W·A — does not open info',
      20,
      48,
      size: 12,
    );
    drawPerkCell(c, 20, 80, 'F', want: true);
    drawPerkCell(c, 78, 80, 'O', avoid: true);
    drawPerkCell(c, 136, 80, 'I', pool: true);
    drawText(
      c,
      'Info = hover (desktop) · long-press / Alt+tap (mobile)',
      20,
      150,
      size: 11,
      color: const ui.Color(0xFF7DD3E0),
    );
  });

  await scene('mobile-longpress-info-sheet', (c) {
    drawText(c, 'Tap=select · long-press/Alt+tap=info sheet', 20, 48,
        size: 11, color: const ui.Color(0xFF7DD3E0));
    drawPerkCell(c, 20, 80, 'F');
    drawPerkCell(c, 78, 80, 'O');
    // sheet panel
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(16, 360, 368, 240),
        const ui.Radius.circular(2),
      ),
      ui.Paint()..color = const ui.Color(0xFF101028),
    );
    c.drawRect(
      const ui.Rect.fromLTWH(182, 370, 36, 3),
      ui.Paint()..color = const ui.Color(0x61E8EEF2),
    );
    drawInfoCard(c, top: 386, title: 'Frenzy', body: kFrenzy, meta: '① on this copy');
  }, h: 720);

  await scene('desktop-unknown-no-hash-primary', (c) {
    drawPerkCell(c, 20, 50, '?');
    drawPerkCell(c, 78, 50, 'F');
    drawInfoCard(
      c,
      top: 120,
      title: 'Unknown perk',
      body: '',
      empty: true,
      footer: '#949',
    );
  });

  await scene('desktop-enhanced-selected-info', (c) {
    drawPerkCell(c, 20, 50, 'F', enhanced: true);
    drawPerkCell(c, 78, 50, 'I');
    drawInfoCard(
      c,
      top: 120,
      title: 'Frenzy',
      body: kFrenzyEnh,
      meta: '① Enhanced (this copy)',
    );
  });

  await scene('desktop-enhance-compare', (c) {
    drawInfoCard(
      c,
      top: 50,
      title: 'Frenzy',
      body: kFrenzy,
      compare: true,
      meta: 'L2 compare when both descs supplied',
    );
  });

  await scene('desktop-roll-target-hover-info', (c) {
    drawPerkCell(c, 20, 50, 'F', want: true);
    drawPerkCell(c, 78, 50, 'O', avoid: true);
    drawInfoCard(
      c,
      top: 120,
      title: 'Frenzy',
      body: kFrenzy,
      meta: '① on this copy · roll-target want',
    );
  });

  await scene('desktop-missing-icon-info', (c) {
    drawInfoCard(
      c,
      top: 50,
      title: 'Frenzy',
      body: kFrenzy,
      meta: 'letter fallback · a11y = displayName',
    );
  });

  stdout.writeln('done');
}
