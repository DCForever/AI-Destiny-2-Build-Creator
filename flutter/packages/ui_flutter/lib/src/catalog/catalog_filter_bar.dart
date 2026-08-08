import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../destiny_official_icons.dart';
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
    this.iconOnly = false,
  });

  final String id;
  final List<String> values;
  final FacetFilter facet;
  final void Function(String value) onCycle;
  final String Function(String value)? labelOf;

  /// Prefer official icon-only chips when values map to Destiny icons
  /// (element / ammo / slot letters). Layout density from mockups.
  final bool iconOnly;
}

/// Single primary filter band: [prefix] · scope · search · chips · exotic · More · RESET.
///
/// Secondary facets expand under **More** only. Presentation only — host owns state.
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
    this.prefix,
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

  /// Optional mode tabs (Weapons / Armor / Universal) on the same primary line.
  final Widget? prefix;

  /// Scope control (All / Owned) on the primary line.
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
        // --- Single primary band (wraps only when width is tight) ---
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final primary = _PrimaryBand(
              wide: wide,
              palette: palette,
              queryController: queryController,
              onQueryChanged: onQueryChanged,
              primaryGroups: primaryGroups,
              prefix: prefix,
              leading: leading,
              trailing: trailing,
              exotic: exotic,
              onCycleExotic: onCycleExotic,
              moreExpanded: moreExpanded,
              onToggleMore: secondaryGroups.isNotEmpty ? onToggleMore : null,
              showReset: showReset,
              onReset: onReset,
            );
            return primary;
          },
        ),
        // --- Secondary under More (horizontal scroll — long archetype lists) ---
        if (moreExpanded && secondaryGroups.isNotEmpty) ...[
          const SizedBox(height: kSpace6),
          for (final group in secondaryGroups) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _FacetGroupInline(group: group),
            ),
            const SizedBox(height: 4),
          ],
          if (trailing != null) trailing!,
        ],
      ],
    );
  }
}

class _PrimaryBand extends StatelessWidget {
  const _PrimaryBand({
    required this.wide,
    required this.palette,
    required this.queryController,
    required this.onQueryChanged,
    required this.primaryGroups,
    required this.prefix,
    required this.leading,
    required this.trailing,
    required this.exotic,
    required this.onCycleExotic,
    required this.moreExpanded,
    required this.onToggleMore,
    required this.showReset,
    required this.onReset,
  });

  final bool wide;
  final FlapPalette palette;
  final TextEditingController queryController;
  final ValueChanged<String> onQueryChanged;
  final List<CatalogFacetGroup> primaryGroups;
  final Widget? prefix;
  final Widget? leading;
  final Widget? trailing;
  final bool? exotic;
  final VoidCallback? onCycleExotic;
  final bool moreExpanded;
  final VoidCallback? onToggleMore;
  final bool showReset;
  final VoidCallback? onReset;

  Widget _searchField() {
    return SizedBox(
      height: 36,
      child: TextField(
        key: const Key('catalog_query'),
        controller: queryController,
        style: neonMono(color: palette.foreground, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search…',
          isDense: true,
          filled: true,
          fillColor: palette.surface.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          // Exclude decorative search glyph (Windows AX thrash with TextField).
          prefixIcon: ExcludeSemantics(
            child: Icon(Icons.search, size: 18, color: palette.muted),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMax),
            borderSide: BorderSide(
              color: palette.line.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMax),
            borderSide: BorderSide(
              color: palette.line.withValues(alpha: 0.45),
              width: kFlapRuleThickness,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMax),
            borderSide: BorderSide(
              color: palette.accent.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
          ),
        ),
        onChanged: onQueryChanged,
      ),
    );
  }

  List<Widget> _chipCluster() {
    final out = <Widget>[];
    for (var i = 0; i < primaryGroups.length; i++) {
      if (i > 0) {
        out.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 1,
              height: 22,
              color: palette.line.withValues(alpha: 0.45),
            ),
          ),
        );
      }
      out.add(_FacetGroupInline(group: primaryGroups[i], compact: true));
    }
    if (onCycleExotic != null) {
      out.add(const SizedBox(width: 6));
      out.add(
        NeonExoticChip(
          exotic: exotic,
          onCycle: onCycleExotic!,
          compact: true,
        ),
      );
    }
    return out;
  }

  Widget _moreButton() {
    return TextButton(
      key: const Key('catalog_more_filters_toggle'),
      onPressed: onToggleMore,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        moreExpanded ? 'LESS' : 'MORE',
        style: neonMono(
          color: palette.muted,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _resetButton() {
    return TextButton(
      key: const Key('catalog_clear_filters'),
      onPressed: onReset,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'RESET',
        style: neonMono(
          color: palette.accent,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = _chipCluster();
    final actions = <Widget>[
      if (onToggleMore != null) _moreButton(),
      if (showReset) _resetButton(),
    ];

    if (wide) {
      // One line: prefix | scope | search | chips… | more | reset
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            Flexible(flex: 0, child: prefix!),
            const SizedBox(width: kSpace8),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: kSpace8),
          ],
          Expanded(flex: 2, child: _searchField()),
          const SizedBox(width: kSpace8),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips,
              ),
            ),
          ),
          ...actions.map((w) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: w,
              )),
        ],
      );
    }

    // Narrow: two compact rows (mode+scope+search+actions) then chip strip.
    // Leading (scope) is Flexible so phone viewports do not overflow ~26px.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (prefix != null) ...[
              Flexible(flex: 0, child: prefix!),
              const SizedBox(width: kSpace6),
            ],
            if (leading != null) ...[
              Flexible(flex: 0, child: leading!),
              const SizedBox(width: kSpace6),
            ],
            Expanded(child: _searchField()),
            ...actions,
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: kSpace6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ],
      ],
    );
  }
}

class _FacetGroupInline extends StatelessWidget {
  const _FacetGroupInline({
    required this.group,
    this.compact = false,
  });

  final CatalogFacetGroup group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final value in group.values)
          Padding(
            padding: EdgeInsets.only(right: compact ? 3 : 4),
            child: NeonFacetChip(
              key: Key('${group.id}_chip_$value'),
              label: group.labelOf?.call(value) ?? value,
              value: value,
              state: facetChipState(group.facet, value),
              onCycle: () => group.onCycle(value),
              iconOnly: group.iconOnly,
              color: officialElementVisual(value)?.color ??
                  officialAmmoVisual(value)?.color,
            ),
          ),
      ],
    );
  }
}
