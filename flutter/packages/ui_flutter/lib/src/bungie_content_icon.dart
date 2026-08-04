/// Network image for Bungie CDN content paths (entity / damage / ammo icons).
library;

import 'package:flutter/material.dart';

import 'destiny_official_icons.dart';

/// Renders a relative Bungie path or absolute URL as a compact icon.
///
/// On failure (offline tests, 404), shows [fallback] or a neutral box.
///
/// **Accessibility:** [Image.network] load/error swaps thrash the Windows AX
/// tree if each phase is a semantic node. The image subtree is always
/// [ExcludeSemantics]; optional [semanticLabel] is a single stable wrapper.
class BungieContentIcon extends StatelessWidget {
  const BungieContentIcon({
    super.key,
    required this.pathOrUrl,
    this.size = 16,
    this.color,
    this.fallback,
    this.semanticLabel,
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
    if (url == null) {
      content = fallbackChild;
    } else {
      content = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
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
      if (color != null) {
        content = ColorFiltered(
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
          child: content,
        );
      }
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
