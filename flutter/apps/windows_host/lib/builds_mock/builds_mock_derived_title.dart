import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'builds_mock_derived_name.dart';

/// Title row: Class / Element / Super as icons, exotic names as text.
class BuildsMockDerivedTitle extends StatelessWidget {
  const BuildsMockDerivedTitle({
    super.key,
    required this.name,
    this.iconSize = 15,
    this.fontSize = 13,
    this.superIconPath,
  });

  final BuildsMockDerivedName name;
  final double iconSize;
  final double fontSize;
  final String? superIconPath;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final children = <Widget>[];

    void addJoiner() {
      if (children.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            '·',
            style: TextStyle(
              color: palette.muted,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }

    if (name.classLabel != null) {
      addJoiner();
      children.add(
        DestinyClassIcon(
          className: name.classLabel!,
          size: iconSize,
          color: palette.foreground,
        ),
      );
    }
    if (name.elementLabel != null) {
      addJoiner();
      final visual = officialElementVisual(name.elementLabel!);
      children.add(
        Tooltip(
          message: name.elementLabel!,
          child: visual == null
              ? Text(
                  name.elementLabel!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    color: palette.foreground,
                  ),
                )
              : DestinyOfficialIcon(
                  visual: visual,
                  size: iconSize,
                  semanticLabel: name.elementLabel,
                ),
        ),
      );
    }
    if (name.superLabel != null) {
      addJoiner();
      final path = superIconPath?.trim();
      final local = path == null || path.isEmpty
          ? null
          : bungieContentPackageAsset(path);
      if (local != null) {
        children.add(
          Tooltip(
            message: name.superLabel!,
            child: BungieContentIcon(
              pathOrUrl: path,
              size: iconSize,
              semanticLabel: name.superLabel,
              fallback: DestinySuperGlyph(
                size: iconSize,
                label: name.superLabel!,
                color: palette.foreground,
              ),
            ),
          ),
        );
      } else {
        children.add(
          DestinySuperGlyph(
            size: iconSize,
            label: name.superLabel!,
            color: palette.foreground,
          ),
        );
      }
    }
    if (name.exoticArmor != null) {
      addJoiner();
      children.add(_textSeg(name.exoticArmor!, fontSize, palette));
    }
    if (name.exoticWeapon != null) {
      addJoiner();
      children.add(_textSeg(name.exoticWeapon!, fontSize, palette));
    }
    if (name.synergy != null) {
      addJoiner();
      children.add(_textSeg(name.synergy!, fontSize, palette));
    }
    if (name.duplicateSuffix != null) {
      addJoiner();
      children.add(_textSeg('${name.duplicateSuffix}', fontSize, palette));
    }

    if (children.isEmpty) {
      return Text(
        name.sourceName,
        key: const Key('builds_mock_derived_title_fallback'),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Wrap(
      key: const Key('builds_mock_derived_title'),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _textSeg(String text, double fontSize, FlapPalette palette) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: palette.foreground,
      ),
    );
  }
}
