import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_column_flex.dart';
import 'flap_element.dart';
import 'flap_palette.dart';

/// Uppercase board header strip driven by [FlapColumnTemplate].
class FlapBoardHeader extends StatelessWidget {
  const FlapBoardHeader({
    super.key,
    required this.template,
    this.padding,
  });

  final FlapColumnTemplate template;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final flex = flapColumnFlexFactors(template);
    final labels = template.headerLabels;
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: kSpace12, vertical: kFlapRowY),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: i < flex.length ? flex[i] : 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  labels[i].toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One continuous ruled flap row (Board Not Cards — no elevated card).
class FlapBoardRow extends StatelessWidget {
  const FlapBoardRow({
    super.key,
    required this.template,
    required this.cells,
    this.selected = false,
    this.onTap,
    this.padding,
  });

  final FlapColumnTemplate template;
  final List<Widget> cells;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final flex = flapColumnFlexFactors(template);
    final count = cells.length;

    final row = Container(
      decoration: BoxDecoration(
        color: selected
            ? palette.accent.withValues(alpha: kFlapBadgeWashAlpha)
            : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: kSpace12, vertical: kSpace10),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              flex: i < flex.length ? flex[i] : 1,
              child: cells[i],
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Standard flap cell text (name vs secondary body).
class FlapTextCell extends StatelessWidget {
  const FlapTextCell({
    super.key,
    required this.text,
    this.primary = false,
    this.color,
    this.textKey,
  });

  final String text;
  final bool primary;
  final Color? color;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodySmall;
    return Text(
      text,
      key: textKey,
      style: color != null ? style?.copyWith(color: color) : style,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Compact seal / channel-wash box for exotics or identity ink.
class FlapSeal extends StatelessWidget {
  const FlapSeal({
    super.key,
    required this.child,
    this.channel,
    this.size = kFlapSealSize,
  });

  final Widget child;
  final Color? channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wash = channel != null ? flapChannelWash(context, channel!) : null;
    return Container(
      constraints: BoxConstraints(minHeight: size, minWidth: size),
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace2),
      decoration: BoxDecoration(
        color: wash,
        border: Border.all(
          color: channel ?? FlapPalette.of(context).line,
          width: kFlapRuleThickness,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

/// Identity / exotics cell with optional element ink + channel wash.
class FlapInkCell extends StatelessWidget {
  const FlapInkCell({
    super.key,
    required this.text,
    this.elementHint,
    this.asSeal = false,
    this.textKey,
  });

  final String text;
  final String? elementHint;
  final bool asSeal;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final ink = flapElementColor(context, elementHint) ??
        flapElementColorFromText(context, elementHint ?? text);
    final label = FlapTextCell(
      text: text,
      textKey: textKey,
      color: ink,
    );
    if (!asSeal || text.trim().isEmpty || text.trim() == '—') {
      return label;
    }
    return FlapSeal(channel: ink ?? FlapPalette.of(context).accent, child: label);
  }
}
