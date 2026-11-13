import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'builds_mock_derived_name.dart';

/// Title row: Class / Element / Super / Exotics as icons (015 identity).
///
/// Convention for the name line: **icon with name as tooltip** for Class,
/// Element/Subclass, Super, Exotic Armor, and Exotic Weapon. Synergy and
/// duplicate suffix stay text. Missing Super (no resolvable icon path) omits
/// the segment — never a star placeholder.
class BuildsMockDerivedTitle extends StatelessWidget {
  const BuildsMockDerivedTitle({
    super.key,
    required this.name,
    this.iconSize = 18,
    this.fontSize = 13,
    this.superIconPath,
    this.exoticArmorIconPath,
    this.exoticWeaponIconPath,
  });

  final BuildsMockDerivedName name;
  final double iconSize;
  final double fontSize;
  final String? superIconPath;
  final String? exoticArmorIconPath;
  final String? exoticWeaponIconPath;

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
      final label = name.elementLabel!;
      final visual = officialElementVisual(label);
      children.add(
        Tooltip(
          message: label,
          child: visual == null
              ? Text(
                  label,
                  key: const Key('builds_mock_title_element_text'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    color: palette.foreground,
                  ),
                )
              : DestinyOfficialIcon(
                  key: const Key('builds_mock_title_element_icon'),
                  visual: visual,
                  size: iconSize,
                  semanticLabel: label,
                ),
        ),
      );
    }
    final superPath = superIconPath?.trim();
    if (name.superLabel != null &&
        superPath != null &&
        superPath.isNotEmpty) {
      addJoiner();
      children.add(
        Tooltip(
          message: name.superLabel!,
          child: BungieContentIcon(
            key: const Key('builds_mock_title_super_icon'),
            pathOrUrl: superPath,
            size: iconSize,
            semanticLabel: name.superLabel,
          ),
        ),
      );
    }
    if (name.exoticArmor != null) {
      addJoiner();
      children.add(
        _exoticSeg(
          label: name.exoticArmor!,
          iconPath: exoticArmorIconPath,
          fontSize: fontSize,
          iconSize: iconSize,
          palette: palette,
          keySuffix: 'armor',
        ),
      );
    }
    if (name.exoticWeapon != null) {
      addJoiner();
      children.add(
        _exoticSeg(
          label: name.exoticWeapon!,
          iconPath: exoticWeaponIconPath,
          fontSize: fontSize,
          iconSize: iconSize,
          palette: palette,
          keySuffix: 'weapon',
        ),
      );
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

  Widget _exoticSeg({
    required String label,
    required String? iconPath,
    required double fontSize,
    required double iconSize,
    required FlapPalette palette,
    required String keySuffix,
  }) {
    final path = iconPath?.trim();
    if (path != null && path.isNotEmpty) {
      return Tooltip(
        message: label,
        child: BungieContentIcon(
          key: Key('builds_mock_title_exotic_${keySuffix}_icon'),
          pathOrUrl: path,
          size: iconSize,
          semanticLabel: label,
        ),
      );
    }
    return _textSeg(label, fontSize, palette);
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
