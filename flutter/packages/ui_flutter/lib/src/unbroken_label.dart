import 'package:flutter/material.dart';

/// Word joiner (U+2060) — keeps a token from wrapping mid-word in [Text].
const String kWordJoiner = '\u2060';

/// Inserts word joiners between letters of each whitespace-delimited token so
/// [Text] wraps only at spaces / hyphens, never inside a single word.
///
/// Prefer [UnbrokenLabel] for UI — tracked display fonts often ignore joiners.
String preventIntraWordWrap(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(
    RegExp(r'\S+'),
    (m) {
      final token = m[0]!;
      if (token.length < 2) return token;
      return token.split('').join(kWordJoiner);
    },
  );
}

/// Strip joiners inserted by [preventIntraWordWrap] (tests / finders).
String stripIntraWordJoiners(String text) => text.replaceAll(kWordJoiner, '');

/// Pack [text] into at most [maxLines] lines, wrapping only at whitespace.
///
/// A token that cannot fit a full line is ellipsized (never split onto the
/// next line). Remaining words on the last line are ellipsized as a unit.
String packWholeWordLines(
  String text, {
  required double maxWidth,
  required TextStyle style,
  int maxLines = 2,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  if (text.isEmpty || maxWidth <= 0 || maxLines < 1) return text;
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return text;

  final painter = TextPainter(textDirection: TextDirection.ltr);
  double widthOf(String s) {
    painter
      ..text = TextSpan(text: s, style: style)
      ..textScaler = textScaler
      ..layout();
    return painter.width;
  }

  String ellipsize(String s) {
    if (widthOf(s) <= maxWidth) return s;
    var cut = s;
    while (cut.isNotEmpty && widthOf('$cut…') > maxWidth) {
      cut = cut.substring(0, cut.length - 1);
    }
    return cut.isEmpty ? '…' : '$cut…';
  }

  final lines = <String>[];
  var i = 0;
  while (i < words.length && lines.length < maxLines) {
    final lastLine = lines.length == maxLines - 1;
    var line = words[i];
    i++;
    while (i < words.length) {
      final trial = '$line ${words[i]}';
      if (widthOf(trial) <= maxWidth) {
        line = trial;
        i++;
      } else {
        break;
      }
    }
    if (lastLine && i < words.length) {
      line = ellipsize('$line ${words.sublist(i).join(' ')}');
      i = words.length;
    } else if (widthOf(line) > maxWidth) {
      line = ellipsize(line);
    }
    lines.add(line);
  }
  return lines.join('\n');
}

/// Label that never wraps inside a word.
///
/// [maxLines] `1` (default): no wrap, ellipsis. Greater than 1: wrap only at
/// whitespace; overflow still ellipsizes.
class UnbrokenLabel extends StatelessWidget {
  const UnbrokenLabel(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.fit = false,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;

  /// Scale the token down to fit instead of ellipsizing (headers).
  final bool fit;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DefaultTextStyle.of(context).style;
    final Widget label;
    if (maxLines > 1) {
      label = LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 400.0;
          final packed = packWholeWordLines(
            text,
            maxWidth: maxW,
            style: resolved,
            maxLines: maxLines,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return Text(
            packed,
            style: resolved,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
            semanticsLabel: text,
          );
        },
      );
    } else {
      label = Text(
        text,
        style: resolved,
        maxLines: 1,
        overflow: overflow,
        softWrap: false,
        textAlign: textAlign,
        semanticsLabel: text,
      );
    }
    if (!fit) return label;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: label,
    );
  }
}
