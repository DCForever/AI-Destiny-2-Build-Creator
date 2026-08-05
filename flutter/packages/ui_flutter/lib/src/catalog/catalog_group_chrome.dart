import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Collapsible group section header (view-only — never rewrites filters).
///
/// BR-CAT-007: collapse toggles visibility only. Default expanded.
class CatalogGroupHeader extends StatelessWidget {
  const CatalogGroupHeader({
    super.key,
    required this.groupKey,
    required this.label,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final String groupKey;
  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final text = '${label.toUpperCase()} ($count)';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('catalog_group_header_$groupKey'),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                key: Key('catalog_group_chevron_$groupKey'),
                size: 18,
                color: palette.muted,
              ),
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
    );
  }
}

/// Outline jump rail for group-by (≥2 groups). Scroll/expand only — never filters.
class CatalogGroupOutlineRail extends StatelessWidget {
  const CatalogGroupOutlineRail({
    super.key,
    required this.groups,
    required this.onJump,
    this.activeKey,
  });

  final List<({String key, String label, int count})> groups;
  final ValueChanged<String> onJump;
  final String? activeKey;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Material(
      key: const Key('catalog_group_outline_rail'),
      color: palette.surface.withValues(alpha: 0.55),
      child: SizedBox(
        width: 132,
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
                  return InkWell(
                    key: Key('catalog_outline_jump_${g.key}'),
                    onTap: () => onJump(g.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
