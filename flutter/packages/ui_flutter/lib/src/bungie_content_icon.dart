/// Network / package-asset image for Bungie CDN content paths.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'bungie_content_assets.dart';
import 'destiny_official_icons.dart';

/// Renders a relative Bungie path or absolute URL as a compact icon.
///
/// Resolution order:
/// 1. Package asset when the CDN basename ships under [kBungieContentAssetDir]
///    (offline Widgetbook / hosts without network)
/// 2. [Image.network] against bungie.net
/// 3. [fallback] or a neutral box
///
/// **Accessibility:** image load/error swaps thrash the Windows AX tree if
/// each phase is a semantic node. The image subtree is always
/// [ExcludeSemantics]; optional [semanticLabel] is a single stable wrapper.
class BungieContentIcon extends StatelessWidget {
  const BungieContentIcon({
    super.key,
    required this.pathOrUrl,
    this.size = 16,
    this.color,
    this.fallback,
    this.semanticLabel,
    this.preferNetwork = false,
  });

  /// Relative `/common/…` path or absolute `https://www.bungie.net/…` URL.
  final String? pathOrUrl;
  final double size;

  /// Optional ColorFilter tint (use sparingly — most Destiny icons are pre-colored).
  final Color? color;
  final Widget? fallback;

  /// When set, exposes one stable semantic label. Prefer parent [Tooltip] for
  /// dense grids and omit this to avoid duplicate AX nodes.
  final String? semanticLabel;

  /// When true, skip package assets and load CDN only (debug / refresh check).
  final bool preferNetwork;

  static String? resolveUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
    final t = pathOrUrl.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final p = t.startsWith('/') ? t : '/$t';
    return 'https://www.bungie.net$p';
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveUrl(pathOrUrl);
    final packageAsset =
        preferNetwork ? null : bungieContentPackageAsset(pathOrUrl);
    final fallbackChild = fallback ??
        SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (color ?? Colors.white24).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    Widget content;
    if (packageAsset != null) {
      content = Image.asset(
        packageAsset,
        package: kDestiny2UiFlutterPackage,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) {
          // Asset listed but missing at runtime — try network, then fallback.
          if (url == null) return fallbackChild;
          return _networkImage(url, fallbackChild);
        },
      );
    } else if (url != null) {
      content = _networkImage(url, fallbackChild);
    } else {
      content = fallbackChild;
    }

    if (color != null) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: content,
      );
    }

    // Exclude image load/error child swaps from the AX tree (Windows bridge).
    final boxed = SizedBox(
      width: size,
      height: size,
      child: ExcludeSemantics(child: content),
    );

    final label = semanticLabel?.trim();
    if (label == null || label.isEmpty) return boxed;

    return Semantics(
      label: label,
      image: true,
      child: boxed,
    );
  }

  Widget _networkImage(String url, Widget fallbackChild) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => fallbackChild,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: fallbackChild,
        );
      },
    );
  }
}

/// Compact official catalog meta icon from a [DestinyOfficialVisual].
class DestinyOfficialIcon extends StatelessWidget {
  const DestinyOfficialIcon({
    super.key,
    required this.visual,
    this.size = 16,
    this.semanticLabel,
    this.fallbackMark,
  });

  final DestinyOfficialVisual visual;
  final double size;

  /// Prefer omitting when a parent [Tooltip] already names the control.
  final String? semanticLabel;

  /// Unicode/text fallback when CDN fails (tests / offline). Prefer short.
  final String? fallbackMark;

  @override
  Widget build(BuildContext context) {
    return BungieContentIcon(
      pathOrUrl: visual.iconPath,
      size: size,
      semanticLabel: semanticLabel,
      fallback: fallbackMark == null
          ? null
          : Center(
              child: Text(
                fallbackMark!,
                style: TextStyle(
                  fontSize: size * 0.7,
                  height: 1,
                  color: visual.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

/// Weapon-type silhouette from package destiny-icons SVG assets.
///
/// On asset miss / test without flutter assets, shows [fallbackMark] letter.
class DestinyWeaponTypeIcon extends StatelessWidget {
  const DestinyWeaponTypeIcon({
    super.key,
    required this.visual,
    this.size = 15,
    this.semanticLabel,
    this.fallbackMark,
  });

  final DestinyWeaponTypeVisual visual;
  final double size;
  final String? semanticLabel;
  final String? fallbackMark;

  @override
  Widget build(BuildContext context) {
    final mark = fallbackMark;
    final fallbackChild = mark == null
        ? SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        : Center(
            child: Text(
              mark,
              style: TextStyle(
                fontSize: size * 0.65,
                height: 1,
                color: visual.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

    Widget content = SvgPicture.asset(
      visual.assetPath,
      package: 'destiny2_ui_flutter',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(visual.color, BlendMode.srcIn),
      // Asset miss must not throw in widget tests.
      placeholderBuilder: (_) => fallbackChild,
      errorBuilder: (_, __, ___) => fallbackChild,
    );

    final boxed = SizedBox(
      width: size,
      height: size,
      child: ExcludeSemantics(child: content),
    );

    final label = semanticLabel?.trim();
    if (label == null || label.isEmpty) return boxed;

    return Semantics(
      label: label,
      image: true,
      child: boxed,
    );
  }
}
