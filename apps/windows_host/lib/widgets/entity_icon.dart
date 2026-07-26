import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/material.dart';

/// Compact Destiny entity icon from relative path or absolute URL (DART-068).
class EntityIcon extends StatelessWidget {
  const EntityIcon({
    super.key,
    this.icon,
    this.size = 36,
    this.fallback = Icons.inventory_2_outlined,
  });

  /// Relative Bungie path or absolute URL.
  final String? icon;
  final double size;
  final IconData fallback;

  static String? resolveUrl(String? icon) {
    if (icon == null || icon.trim().isEmpty) return null;
    final t = icon.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return bungieContentUrl(t);
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveUrl(icon);
    final box = SizedBox(
      width: size,
      height: size,
      child: url == null
          ? Icon(fallback, size: size * 0.65)
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(fallback, size: size * 0.65),
            ),
    );
    return box;
  }
}
