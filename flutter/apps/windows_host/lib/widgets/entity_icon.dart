import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/material.dart';

/// Compact Destiny entity icon from relative path or absolute URL (DART-068).
///
/// **Windows AX:** [Image.network] always publishes an image semantics node
/// unless [Image.excludeFromSemantics] is true. Load/error/frame swaps then
/// thrash `accessibility_bridge` ("will not be in the tree…"). Keep the image
/// subtree non-semantic; optional [semanticLabel] is a single stable wrapper.
class EntityIcon extends StatelessWidget {
  const EntityIcon({
    super.key,
    this.icon,
    this.size = 36,
    this.fallback = Icons.inventory_2_outlined,
    this.semanticLabel,
  });

  /// Relative Bungie path or absolute URL.
  final String? icon;
  final double size;
  final IconData fallback;

  /// When set, one stable image label. Prefer parent [Tooltip]/card semantics
  /// and omit this in dense grids.
  final String? semanticLabel;

  static String? resolveUrl(String? icon) {
    if (icon == null || icon.trim().isEmpty) return null;
    final t = icon.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return bungieContentUrl(t);
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveUrl(icon);
    final fallbackChild = Icon(fallback, size: size * 0.65);

    Widget content;
    if (url == null) {
      content = fallbackChild;
    } else {
      content = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        // Critical: default Image semantics thrash Windows AX on load/error.
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
      excludeSemantics: true,
      child: boxed,
    );
  }
}
