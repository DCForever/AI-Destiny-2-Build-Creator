/// Local package assets for Bungie CDN icon paths (offline / Widgetbook).
library;

import 'bungie_content_local_assets.g.dart';

/// Package name for [Image.asset] / [SvgPicture.asset].
const String kDestiny2UiFlutterPackage = 'destiny2_ui_flutter';

/// Asset directory (relative to package root) for cached Bungie PNGs.
const String kBungieContentAssetDir = 'assets/bungie-content/icons';

/// Resolve a package asset key for a Bungie relative path or absolute URL.
///
/// Returns `null` when the basename is not in the shipped set (caller may
/// fall back to network). Paths keep their CDN basenames so
/// [DestinyOfficialVisual.iconPath] and fixture maps resolve without remapping.
String? bungieContentPackageAsset(String? pathOrUrl) {
  final base = bungieContentBasename(pathOrUrl);
  if (base == null) return null;
  if (!kBungieContentLocalBasenames.contains(base)) return null;
  return '$kBungieContentAssetDir/$base';
}

/// Last path segment of a Bungie path/URL, or null if empty.
String? bungieContentBasename(String? pathOrUrl) {
  if (pathOrUrl == null) return null;
  final t = pathOrUrl.trim();
  if (t.isEmpty) return null;
  // Strip query / fragment.
  final noQuery = t.split('?').first.split('#').first;
  final slash = noQuery.replaceAll('\\', '/');
  final base = slash.contains('/') ? slash.split('/').last : slash;
  if (base.isEmpty || !base.contains('.')) return null;
  return base;
}
