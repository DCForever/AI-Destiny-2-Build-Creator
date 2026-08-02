/// Neon Network shell atmosphere — void blooms, horizon floor, soft zones.
///
/// Layout preference (DESIGN.md): gap → tonal step → gradient fade → hairline →
/// outline (exception). Cyan is signal only; structure is white/grey hairline.
library;

import 'dart:ui' show ImageFilter;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';

// ---------------------------------------------------------------------------
// Decoration (pure helpers)
// ---------------------------------------------------------------------------

/// Soft zone fill matching Neon `--grad-zone` (surface → void with faint cyan).
BoxDecoration neonZoneDecoration(FlapPalette palette) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(kFlapRadius),
    gradient: LinearGradient(
      begin: const Alignment(-0.2, -1),
      end: const Alignment(0.35, 1),
      colors: [
        Color.lerp(palette.surface, palette.accent, 0.03) ?? palette.surface,
        Color.lerp(palette.surface, palette.background, 0.28) ??
            palette.surfaceRaised,
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

/// Optional glass-ish panel with hairline structure (not a cyan cage).
BoxDecoration neonPanelDecoration(
  FlapPalette palette, {
  bool hairline = true,
}) {
  return BoxDecoration(
    color: palette.surface.withValues(alpha: 0.88),
    borderRadius: BorderRadius.circular(kFlapRadius),
    border: hairline
        ? Border.all(color: palette.line, width: kFlapRuleThickness)
        : null,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 24,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Shell background
// ---------------------------------------------------------------------------

/// Full-viewport Neon void: radial shell blooms + optional Tron horizon floor.
///
/// Place as the [Scaffold] body wrapper (scaffold background transparent or void).
/// Content sits above the atmosphere (`Stack` with [child] last).
class NeonShellBackground extends StatelessWidget {
  const NeonShellBackground({
    super.key,
    required this.child,
    this.showHorizon = true,
    this.showBlooms = true,
  });

  final Widget child;
  final bool showHorizon;
  final bool showBlooms;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showBlooms)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ShellBloomPainter(
                    accent: palette.accent,
                    secondary: Color(
                      (Theme.of(context).brightness == Brightness.dark
                              ? FlapColorTokens.dark
                              : FlapColorTokens.light)
                          .accentSecondary,
                    ),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          if (showHorizon)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeonHorizonGridPainter(
                    lineColor: palette.accent.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.14
                          : 0.10,
                    ),
                    horizonGlow: palette.accent.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Soft content zone — gradient surface, optional padding, no cyan outline.
class NeonZone extends StatelessWidget {
  const NeonZone({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: neonZoneDecoration(palette),
      child: child,
    );
  }
}

/// Hairline-bordered elevated panel (modals / critical surfaces).
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hairline = true,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hairline;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    Widget body = Container(
      margin: margin,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: kSpace16,
            vertical: kSpace12,
          ),
      decoration: neonPanelDecoration(palette, hairline: hairline),
      child: child,
    );
    if (!blur) return body;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: body,
      ),
    );
  }
}

/// Live status pulse (signal-fade envelope). Respects [MediaQuery.disableAnimations]
/// / reduced motion — freezes at dim opacity, never full neon rest.
class NeonLivePulse extends StatefulWidget {
  const NeonLivePulse({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 2000),
    this.peakOpacity = 1,
    this.restOpacity = 0.28,
  });

  final Widget child;
  final Duration period;
  final double peakOpacity;
  final double restOpacity;

  @override
  State<NeonLivePulse> createState() => _NeonLivePulseState();
}

class _NeonLivePulseState extends State<NeonLivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reduce) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return Opacity(opacity: widget.restOpacity, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Signal-fade: off ~18% → fade in → hold → fade out.
        final t = _c.value;
        double o;
        if (t < 0.18) {
          o = 0;
        } else if (t < 0.30) {
          o = (t - 0.18) / 0.12;
        } else if (t < 0.70) {
          o = 1;
        } else if (t < 0.95) {
          o = 1 - (t - 0.70) / 0.25;
        } else {
          o = 0;
        }
        final opacity = widget.restOpacity +
            (widget.peakOpacity - widget.restOpacity) * o.clamp(0.0, 1.0);
        return Opacity(opacity: opacity, child: child);
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Perspective Tron floor — never a flat full-canvas wallpaper tile.
class NeonHorizonGridPainter extends CustomPainter {
  NeonHorizonGridPainter({
    required this.lineColor,
    required this.horizonGlow,
  });

  final Color lineColor;
  final Color horizonGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final gridH = size.height * 0.55;
    final top = size.height - gridH;
    final vanishing = Offset(size.width / 2, top + gridH * 0.08);

    // Fade mask toward top of grid.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor;

    // Horizontal lines (denser near bottom).
    const rows = 14;
    for (var i = 0; i <= rows; i++) {
      final t = i / rows;
      final y = top + gridH * (0.15 + 0.85 * (t * t));
      final alpha = (0.15 + 0.85 * t).clamp(0.0, 1.0);
      paint.color = lineColor.withValues(alpha: lineColor.a * alpha);
      // Perspective width grows toward bottom.
      final halfW = size.width * (0.15 + 0.95 * t);
      canvas.drawLine(
        Offset(vanishing.dx - halfW, y),
        Offset(vanishing.dx + halfW, y),
        paint,
      );
    }

    // Vertical radials from vanishing point.
    const cols = 16;
    for (var i = 0; i <= cols; i++) {
      final u = (i / cols) * 2 - 1;
      final bottomX = vanishing.dx + u * size.width * 1.15;
      final alpha = 0.25 + 0.55 * (1 - u.abs()).clamp(0.0, 1.0);
      paint.color = lineColor.withValues(alpha: lineColor.a * alpha);
      canvas.drawLine(
        vanishing,
        Offset(bottomX, size.height + 8),
        paint,
      );
    }

    // Horizon glow bar.
    final glowY = top + gridH * 0.18;
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          horizonGlow.withValues(alpha: 0),
          horizonGlow,
          horizonGlow.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, glowY - 1, size.width, 2));
    canvas.drawRect(Rect.fromLTWH(0, glowY - 0.5, size.width, 1.5), glowPaint);
  }

  @override
  bool shouldRepaint(covariant NeonHorizonGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.horizonGlow != horizonGlow;
  }
}

class _ShellBloomPainter extends CustomPainter {
  _ShellBloomPainter({
    required this.accent,
    required this.secondary,
    required this.isDark,
  });

  final Color accent;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final intensity = isDark ? 1.0 : 0.35;
    void bloom(Offset c, double rx, double ry, Color color, double a) {
      final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a * intensity),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawRect(Offset.zero & size, paint);
    }

    bloom(
      Offset(size.width * 0.18, size.height * 0.72),
      size.width * 0.42,
      size.height * 0.36,
      accent,
      0.14,
    );
    bloom(
      Offset(size.width * 0.82, size.height * 0.28),
      size.width * 0.36,
      size.height * 0.32,
      secondary,
      0.10,
    );
    bloom(
      Offset(size.width * 0.55, size.height * 1.0),
      size.width * 0.50,
      size.height * 0.40,
      const Color(0xFF3D7EFF),
      0.10,
    );
  }

  @override
  bool shouldRepaint(covariant _ShellBloomPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.isDark != isDark;
  }
}

/// Convenience: focus glow shadow for interactive chrome.
List<BoxShadow> neonFocusGlow(Color accent) {
  return [
    BoxShadow(
      color: accent.withValues(alpha: 0.55),
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.35),
      blurRadius: 18,
    ),
  ];
}
