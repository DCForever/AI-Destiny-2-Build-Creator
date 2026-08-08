import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Horizontal indent per nested depth (desktop residual ~14px).
const double kCatalogGroupDepthIndent = 14;

/// Outline rail width (005 mock ~148px; was 132 flat).
const double kCatalogGroupOutlineWidth = 148;

/// One JUMP outline row (hierarchical; full tree, not only visible leaves).
class CatalogGroupOutlineEntry {
  const CatalogGroupOutlineEntry({
    required this.key,
    required this.label,
    required this.count,
    this.depth = 0,
    this.dimension,
    this.collapsedHint = false,
  });

  final String key;
  final String label;
  final int count;
  final int depth;
  final CatalogGroupDimension? dimension;
  final bool collapsedHint;
}

/// Leading icon for a group segment when the dimension has official art.
///
/// Returns null when unmapped (text-only). Never invents art.
Widget? catalogGroupDimensionIcon(
  BuildContext context, {
  required CatalogGroupDimension? dimension,
  required String label,
  double size = 16,
}) {
  if (dimension == null) return null;
  final palette = FlapPalette.of(context);

  switch (dimension) {
    case CatalogGroupDimension.element:
      final v = officialElementVisual(label);
      if (v == null) return null;
      return BungieContentIcon(
        pathOrUrl: v.iconPath,
        size: size,
        fallback: Icon(Icons.circle, size: size * 0.7, color: v.color),
      );
    case CatalogGroupDimension.ammo:
      final v = officialAmmoVisual(label);
      if (v == null) return null;
      return BungieContentIcon(
        pathOrUrl: v.iconPath,
        size: size,
        fallback: Icon(Icons.circle, size: size * 0.7, color: v.color),
      );
    case CatalogGroupDimension.frame:
      final v = officialWeaponFrameVisual(label);
      if (v == null) return null;
      return BungieContentIcon(
        pathOrUrl: v.iconPath,
        size: size,
        fallback: Icon(Icons.tune, size: size * 0.75, color: palette.muted),
      );
    case CatalogGroupDimension.archetype:
      final v = officialWeaponTypeVisual(label);
      if (v == null) return null;
      return DestinyWeaponTypeIcon(
        visual: v,
        size: size,
        fallbackMark: weaponTypeLetterMark(label),
      );
    case CatalogGroupDimension.slot:
      final letter = _slotLetter(label);
      if (letter == null) return null;
      return Text(
        letter,
        style: neonMono(
          color: _slotColor(label, palette),
          fontSize: size * 0.72,
          fontWeight: FontWeight.w600,
        ),
      );
    case CatalogGroupDimension.classType:
      return null;
  }
}

String? _slotLetter(String label) {
  switch (label.trim().toLowerCase()) {
    case 'kinetic':
      return 'K';
    case 'energy':
      return 'E';
    case 'power':
    case 'heavy':
      return 'P';
    default:
      return null;
  }
}

Color _slotColor(String label, FlapPalette palette) {
  switch (label.trim().toLowerCase()) {
    case 'kinetic':
      return palette.foreground;
    case 'energy':
      return officialElementColor('solar') ?? palette.accent;
    case 'power':
    case 'heavy':
      return const Color(0xFFD4B06A);
    default:
      return palette.muted;
  }
}

/// Collapsible group section header (view-only — never rewrites filters).
///
/// BR-CAT-007: collapse toggles visibility only. Default expanded.
/// Nested: [depth] indent + optional [dimension] icon; [label] is segment only.
class CatalogGroupHeader extends StatelessWidget {
  const CatalogGroupHeader({
    super.key,
    required this.groupKey,
    required this.label,
    required this.count,
    required this.expanded,
    required this.onToggle,
    this.depth = 0,
    this.dimension,
    this.leading,
  });

  final String groupKey;
  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  /// Nesting depth (0 = top-level). Indent = depth × [kCatalogGroupDepthIndent].
  final int depth;

  /// When set, resolves an official dim icon when mapped.
  final CatalogGroupDimension? dimension;

  /// Optional override for the dim icon slot.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final text = '${label.toUpperCase()} ($count)';
    final indent = 12.0 + depth * kCatalogGroupDepthIndent;
    final icon = leading ??
        catalogGroupDimensionIcon(
          context,
          dimension: dimension,
          label: label,
          size: 16,
        );
    // Single owner (Windows AX): InkWell + Icon + Text otherwise publish
    // nested nodes that reparent on expand/collapse.
    return Semantics(
      button: true,
      expanded: expanded,
      label: expanded
          ? 'Collapse $label, $count items'
          : 'Expand $label, $count items',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('catalog_group_header_$groupKey'),
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  key: Key('catalog_group_chevron_$groupKey'),
                  size: 18,
                  color: palette.accent,
                ),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  KeyedSubtree(
                    key: Key('catalog_group_icon_$groupKey'),
                    child: icon,
                  ),
                ],
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    text,
                    key: Key('catalog_group_$groupKey'),
                    style: Theme.of(context).textTheme.labelSmall,
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

/// Outline jump rail for group-by (≥2 top-level groups).
///
/// Scroll / expand / toggle-collapse only — never filters (BR-CAT-007).
class CatalogGroupOutlineRail extends StatelessWidget {
  const CatalogGroupOutlineRail({
    super.key,
    required this.groups,
    required this.onJump,
    this.activeKey,
    this.width = kCatalogGroupOutlineWidth,
  });

  /// Prefer [CatalogGroupOutlineEntry] rows; plain records still work via adapter.
  final List<CatalogGroupOutlineEntry> groups;
  final ValueChanged<String> onJump;
  final String? activeKey;
  final double width;

  /// Convenience: build entries from flat key/label/count tuples (1-dim / legacy).
  static List<CatalogGroupOutlineEntry> flatEntries(
    List<({String key, String label, int count})> groups,
  ) {
    return [
      for (final g in groups)
        CatalogGroupOutlineEntry(
          key: g.key,
          label: g.label,
          count: g.count,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      key: const Key('catalog_group_outline_rail'),
      color: palette.surface.withValues(alpha: 0.55),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                'JUMP',
                style: neonMono(
                  color: palette.muted,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  final active = activeKey == g.key;
                  final padL = 8.0 + g.depth * kCatalogGroupDepthIndent;
                  final icon = catalogGroupDimensionIcon(
                    context,
                    dimension: g.dimension,
                    label: g.label,
                    size: 14,
                  );
                  return Opacity(
                    opacity: g.collapsedHint ? 0.72 : 1,
                    child: Semantics(
                      button: true,
                      selected: active,
                      label: 'Jump to ${g.label}, ${g.count} items',
                      excludeSemantics: true,
                      child: InkWell(
                        key: Key('catalog_outline_jump_${g.key}'),
                        onTap: () => onJump(g.key),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(padL, 6, 8, 6),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: active
                                    ? palette.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            color: active
                                ? palette.accent.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: Row(
                            children: [
                              if (icon != null) ...[
                                icon,
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(
                                  g.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: neonMono(
                                    color: active
                                        ? palette.accent
                                        : palette.foreground,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                '${g.count}',
                                style: neonMono(
                                  color: palette.muted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile sticky horizontal JUMP strip (structure-only parity).
class CatalogGroupOutlineStrip extends StatelessWidget {
  const CatalogGroupOutlineStrip({
    super.key,
    required this.groups,
    required this.onJump,
    this.activeKey,
  });

  final List<CatalogGroupOutlineEntry> groups;
  final ValueChanged<String> onJump;
  final String? activeKey;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      key: const Key('catalog_group_outline_strip'),
      color: palette.surface.withValues(alpha: 0.9),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final g = groups[index];
            final active = activeKey == g.key;
            final icon = catalogGroupDimensionIcon(
              context,
              dimension: g.dimension,
              label: g.label,
              size: 12,
            );
            final depthPrefix = g.depth <= 0 ? '' : '${'·' * g.depth} ';
            return Opacity(
              opacity: g.collapsedHint ? 0.72 : 1,
              child: Semantics(
                button: true,
                selected: active,
                label: 'Jump to ${g.label}, ${g.count} items',
                excludeSemantics: true,
                child: Material(
                  color: active
                      ? palette.accent.withValues(alpha: 0.12)
                      : palette.background,
                  child: InkWell(
                    key: Key('catalog_outline_strip_jump_${g.key}'),
                    onTap: () => onJump(g.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: active
                              ? palette.accent.withValues(alpha: 0.35)
                              : palette.line,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (depthPrefix.isNotEmpty)
                            Text(
                              depthPrefix,
                              style: neonMono(
                                color: palette.muted,
                                fontSize: 9,
                              ),
                            ),
                          if (icon != null) ...[
                            icon,
                            const SizedBox(width: 4),
                          ],
                          Text(
                            g.label,
                            style: neonMono(
                              color: active
                                  ? palette.accent
                                  : palette.foreground,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${g.count}',
                            style: neonMono(
                              color: palette.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
