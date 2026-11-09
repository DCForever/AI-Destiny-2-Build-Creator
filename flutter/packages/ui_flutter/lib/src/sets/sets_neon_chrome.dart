import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Orbitron uppercase field label (mockup `.field label`).
class SetsFieldLabel extends StatelessWidget {
  const SetsFieldLabel(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Text(
      text.toUpperCase(),
      style: neonDisplay(
        color: palette.muted,
        fontSize: 9,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// One cell in a [SetsChoiceGrid] (mockup `.choice`).
class SetsChoiceOption {
  const SetsChoiceOption({
    required this.id,
    required this.label,
    this.key,
    this.leading,
    this.enabled = true,
  });

  final String id;
  final String label;
  final Key? key;
  final Widget? leading;
  final bool enabled;
}

/// Neon choice-grid: square cells, Orbitron caps, cyan wash when pressed.
///
/// Mockup dual-truth for create Type / Class (and similar single-select grids).
class SetsChoiceGrid extends StatelessWidget {
  const SetsChoiceGrid({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.minCellWidth = 100,
    this.cellHeight = 40,
  });

  final List<SetsChoiceOption> options;
  final String? selectedId;
  final ValueChanged<String>? onSelected;
  final double minCellWidth;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minCellWidth * 3;
        final cols = (maxW / (minCellWidth + 6)).floor().clamp(2, 5);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in options)
              SizedBox(
                width: (maxW - (cols - 1) * 6) / cols,
                height: cellHeight,
                child: _SetsChoiceCell(
                  option: o,
                  selected: o.id == selectedId,
                  onTap: o.enabled && onSelected != null
                      ? () => onSelected!(o.id)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SetsChoiceCell extends StatelessWidget {
  const _SetsChoiceCell({
    required this.option,
    required this.selected,
    this.onTap,
  });

  final SetsChoiceOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final enabled = onTap != null;
    final borderColor = selected
        ? palette.accent.withValues(alpha: 0.45)
        : palette.line;
    final bg = selected
        ? palette.accent.withValues(alpha: kFlapChannelWashAlpha)
        : palette.background;
    final fg = selected
        ? palette.foreground
        : enabled
            ? palette.muted
            : palette.muted.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: option.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: option.key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(kFlapRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: kFlapRuleThickness),
              borderRadius: BorderRadius.circular(kFlapRadius),
            ),
            // Inset bottom accent bar when selected (mockup inset box-shadow).
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (selected)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 1,
                      color: palette.accent,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (option.leading != null) ...[
                        option.leading!,
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          option.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: neonDisplay(
                            color: fg,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Class accent dot for Titan / Hunter / Warlock choice cells.
class SetsClassDot extends StatelessWidget {
  const SetsClassDot(this.className, {super.key});

  final String className;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final c = switch (className.toLowerCase()) {
      'titan' => const Color(0xFFE85D3C),
      'hunter' => const Color(0xFF4A9FE8),
      'warlock' => const Color(0xFFB07AE8),
      _ => palette.muted,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 4),
        ],
      ),
    );
  }
}

/// Orbitron uppercase CTA label style (mockup `.btn`).
TextStyle setsNeonBtnLabel(Color color, {double fontSize = 9}) {
  return neonDisplay(
    color: color,
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
  );
}

/// Primary neon button style: accent wash + cyan type (mockup `.btn-primary`).
ButtonStyle setsNeonPrimaryStyle(
  FlapPalette palette, {
  double height = 30,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  double fontSize = 9,
}) {
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    padding: WidgetStatePropertyAll(padding),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return palette.accent.withValues(alpha: 0.06);
      }
      return palette.accent.withValues(alpha: kFlapChannelWashAlpha);
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return palette.accent.withValues(alpha: 0.35);
      }
      if (states.contains(WidgetState.hovered)) {
        return palette.foreground;
      }
      return palette.accent;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      final a = states.contains(WidgetState.disabled) ? 0.2 : 0.45;
      return BorderSide(
        color: palette.accent.withValues(alpha: a),
        width: kFlapRuleThickness,
      );
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
    ),
    textStyle: WidgetStatePropertyAll(setsNeonBtnLabel(palette.accent, fontSize: fontSize)),
    overlayColor: WidgetStatePropertyAll(
      palette.accent.withValues(alpha: 0.08),
    ),
  );
}

/// Ghost / secondary neon button (mockup `.btn`).
ButtonStyle setsNeonGhostStyle(
  FlapPalette palette, {
  double height = 30,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  double fontSize = 9,
}) {
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    padding: WidgetStatePropertyAll(padding),
    backgroundColor: WidgetStatePropertyAll(palette.background),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return palette.muted.withValues(alpha: 0.35);
      }
      if (states.contains(WidgetState.hovered)) {
        return palette.foreground;
      }
      return palette.muted;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return BorderSide(color: palette.lineStrong, width: kFlapRuleThickness);
      }
      return BorderSide(color: palette.line, width: kFlapRuleThickness);
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
    ),
    textStyle: WidgetStatePropertyAll(setsNeonBtnLabel(palette.muted, fontSize: fontSize)),
    overlayColor: WidgetStatePropertyAll(
      palette.foreground.withValues(alpha: 0.04),
    ),
  );
}

/// Large hero primary (mockup `.btn-primary.btn-lg.hero`).
ButtonStyle setsNeonHeroStyle(FlapPalette palette) {
  return setsNeonPrimaryStyle(
    palette,
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    fontSize: 10,
  );
}

/// Auto-name preview strip (mockup `.auto-name-preview`).
class SetsAutoNamePreview extends StatelessWidget {
  const SetsAutoNamePreview(this.preview, {super.key});

  final String preview;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
      child: Text.rich(
        TextSpan(
          style: neonMono(color: palette.muted.withValues(alpha: 0.85), fontSize: 11),
          children: [
            TextSpan(
              text: 'Preview · ',
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
            TextSpan(text: preview),
          ],
        ),
      ),
    );
  }
}
