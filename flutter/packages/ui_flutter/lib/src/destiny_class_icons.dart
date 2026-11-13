/// Vendored CC0 Destiny class glyphs (copied from Next public/destiny-icons).
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'bungie_content_assets.dart';

/// Package asset paths for class silhouettes under `assets/destiny-icons/general/`.
const Map<String, String> kClassIconAssetPaths = {
  'titan': 'assets/destiny-icons/general/class_titan.svg',
  'hunter': 'assets/destiny-icons/general/class_hunter.svg',
  'warlock': 'assets/destiny-icons/general/class_warlock.svg',
};

/// Resolve a class SVG asset path for a guardian class label or DIM classType.
String? classIconAssetPath(String? classNameOrWire) {
  final key = (classNameOrWire ?? '').trim().toLowerCase();
  if (key.isEmpty) return null;
  return kClassIconAssetPaths[key];
}

/// Resolve a class SVG from a DIM `classType` integer (0 Titan / 1 Hunter / 2 Warlock).
String? classIconAssetPathForClassType(int? classType) {
  switch (classType) {
    case 0:
      return kClassIconAssetPaths['titan'];
    case 1:
      return kClassIconAssetPaths['hunter'];
    case 2:
      return kClassIconAssetPaths['warlock'];
    default:
      return null;
  }
}

/// Display label for a DIM `classType` integer.
String? guardianClassLabelForClassType(int? classType) {
  switch (classType) {
    case 0:
      return 'Titan';
    case 1:
      return 'Hunter';
    case 2:
      return 'Warlock';
    default:
      return null;
  }
}

/// Compact class silhouette with tooltip.
class DestinyClassIcon extends StatelessWidget {
  const DestinyClassIcon({
    super.key,
    required this.className,
    this.size = 16,
    this.color,
  });

  final String className;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final path = classIconAssetPath(className);
    final label = className.trim().isEmpty ? 'Class' : className.trim();
    final child = path == null
        ? SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.person_outline, size: size * 0.9, color: color),
          )
        : SvgPicture.asset(
            path,
            package: kDestiny2UiFlutterPackage,
            width: size,
            height: size,
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color!, BlendMode.srcIn),
            excludeFromSemantics: true,
          );
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        image: true,
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

/// Generic Super glyph (stand-in when no local Super icon ships).
class DestinySuperGlyph extends StatelessWidget {
  const DestinySuperGlyph({
    super.key,
    this.size = 16,
    this.color,
    this.label = 'Super',
  });

  final double size;
  final Color? color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black87;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        image: true,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SuperStarPainter(color: c),
          ),
        ),
      ),
    );
  }
}

class _SuperStarPainter extends CustomPainter {
  _SuperStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;
    const points = <Offset>[
      Offset(0, -1),
      Offset(0.22, -0.25),
      Offset(1, -0.2),
      Offset(0.35, 0.25),
      Offset(0.55, 1),
      Offset(0, 0.55),
      Offset(-0.55, 1),
      Offset(-0.35, 0.25),
      Offset(-1, -0.2),
      Offset(-0.22, -0.25),
    ];
    for (var i = 0; i < points.length; i++) {
      final p = Offset(cx + points[i].dx * r, cy + points[i].dy * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SuperStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
