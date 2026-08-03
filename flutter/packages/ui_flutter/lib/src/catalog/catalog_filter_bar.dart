import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'neon_facet_chip.dart';

/// One facet group for the filter bar (primary or secondary / More).
class CatalogFacetGroup {
  const CatalogFacetGroup({
    required this.id,
    required this.values,
    required this.facet,
    required this.onCycle,
    this.labelOf,
  });

  final String id;
  final List<String> values;
  final FacetFilter facet;
  final void Function(String value) onCycle;
  final String Function(String value)? labelOf;
}

/// Free-text + primary facets + More secondary + RESET.
///
/// Presentation only — host owns facet state and refilter.
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.queryController,
    required this.onQueryChanged,
    required this.primaryGroups,
    this.secondaryGroups = const [],
    this.moreExpanded = false,
    this.onToggleMore,
    this.onReset,
    this.activeFilterCount = 0,
    this.leading,
    this.trailing,
    this.exotic,
    this.onCycleExotic,
    this.showResetAlways = false,
  });

  final TextEditingController queryController;
  final ValueChanged<String> onQueryChanged;
  final List<CatalogFacetGroup> primaryGroups;
  final List<CatalogFacetGroup> secondaryGroups;
  final bool moreExpanded;
  final VoidCallback? onToggleMore;
  final VoidCallback? onReset;
  final int activeFilterCount;
  final Widget? leading;
  final Widget? trailing;
  final bool? exotic;
  final VoidCallback? onCycleExotic;

  /// When true, RESET is always visible (even with 0 active).
  final bool showResetAlways;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final showReset =
        onReset != null && (showResetAlways || activeFilterCount > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('catalog_query'),
          controller: queryController,
          decoration: InputDecoration(
            labelText: 'Search nodes',
            hintText: 'Name, type, element…',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            labelStyle: neonMono(
              color: palette.muted,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          onChanged: onQueryChanged,
        ),
        if (leading != null) ...[
          const SizedBox(height: kSpace12),
          leading!,
        ],
        const SizedBox(height: kSpace12),
        Row(
          children: [
            if (trailing != null) Expanded(child: trailing!),
            if (trailing == null) const Spacer(),
            if (showReset)
              TextButton(
                key: const Key('catalog_clear_filters'),
                onPressed: onReset,
                child: Text(
                  'RESET',
                  style: neonMono(
                    color: palette.accent,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: kSpace8),
        for (final group in primaryGroups) ...[
          _FacetRow(group: group),
          const SizedBox(height: 4),
        ],
        if (onCycleExotic != null)
          Align(
            alignment: Alignment.centerLeft,
            child: NeonExoticChip(exotic: exotic, onCycle: onCycleExotic!),
          ),
        if (secondaryGroups.isNotEmpty && onToggleMore != null)
          ListTile(
            key: const Key('catalog_more_filters_toggle'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              moreExpanded
                  ? 'Less filters'
                  : 'More filters (ammo, type, group…)',
              style: neonMono(
                color: palette.muted,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
            trailing: Icon(
              moreExpanded ? Icons.expand_less : Icons.expand_more,
              color: palette.muted,
            ),
            onTap: onToggleMore,
          ),
        if (moreExpanded)
          for (final group in secondaryGroups) ...[
            _FacetRow(group: group),
            const SizedBox(height: 4),
          ],
      ],
    );
  }
}

class _FacetRow extends StatelessWidget {
  const _FacetRow({required this.group});

  final CatalogFacetGroup group;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in group.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: NeonFacetChip(
                key: Key('${group.id}_chip_$value'),
                label: group.labelOf?.call(value) ?? value,
                state: facetChipState(group.facet, value),
                onCycle: () => group.onCycle(value),
              ),
            ),
        ],
      ),
    );
  }
}
