import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_card.dart';
import '../unbroken_label.dart';

// ---------------------------------------------------------------------------
// Glyph helpers (residual until official class/slot maps ship)
// ---------------------------------------------------------------------------

/// Class letter mark (official icons preferred when mapped; residual glyphs OK).
String armorClassGlyphMark(String? classType) {
  switch ((classType ?? '').trim().toLowerCase()) {
    case 'titan':
      return 'T';
    case 'hunter':
      return 'H';
    case 'warlock':
      return 'W';
    default:
      final s = (classType ?? '').trim();
      return s.isEmpty ? '?' : s[0].toUpperCase();
  }
}

/// Armor slot letter mark (Helmet/Gauntlets/Chest/Legs/ClassItem).
String armorSlotGlyphMark(String? slot) {
  switch ((slot ?? '').trim().toLowerCase()) {
    case 'helmet':
    case 'head':
      return 'H';
    case 'gauntlets':
    case 'arms':
      return 'G';
    case 'chest':
    case 'chest armor':
      return 'C';
    case 'legs':
    case 'leg armor':
      return 'L';
    case 'classitem':
    case 'class item':
    case 'class_item':
      return 'I';
    default:
      final s = (slot ?? '').trim();
      return s.isEmpty ? '?' : s[0].toUpperCase();
  }
}

Color _classColor(FlapPalette palette, String? classType) {
  switch ((classType ?? '').trim().toLowerCase()) {
    case 'titan':
      return const Color(0xFFE35A3D);
    case 'hunter':
      return const Color(0xFF5AA8E0);
    case 'warlock':
      return const Color(0xFFC9A24D);
    default:
      return palette.muted;
  }
}

// ---------------------------------------------------------------------------
// Icon plate
// ---------------------------------------------------------------------------

/// Top-left armor plate: CDN [CatalogItem.icon], else class/slot mark.
class CatalogArmorIconPlate extends StatelessWidget {
  const CatalogArmorIconPlate({
    super.key,
    required this.item,
    this.size = 36,
  });

  final CatalogItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final exotic = item.isExotic;
    final mark = armorSlotGlyphMark(item.slot);

    final plate = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: exotic
              ? const Color(kRarityExotic).withValues(alpha: 0.55)
              : palette.line.withValues(alpha: 0.65),
          width: kFlapRuleThickness,
        ),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            mark,
            style: neonMono(
              color: exotic ? const Color(kRarityExotic) : palette.muted,
              fontSize: size * 0.36,
            ),
          ),
        ),
      ),
    );

    final path = item.icon?.trim();
    if (path == null || path.isEmpty) {
      return KeyedSubtree(
        key: Key('catalog_item_icon_${item.hash}'),
        child: plate,
      );
    }

    return BungieContentIcon(
      key: Key('catalog_item_icon_${item.hash}'),
      pathOrUrl: path,
      size: size,
      fallback: plate,
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

/// Identity-primary armor card — **no list-row stats or mod icons**.
///
/// Chrome: icon + rarity + class/slot glyphs + exotic badge + owned ×N.
/// Owned badge only when [showOwned] and item.owned — never fakes ownership.
class CatalogArmorCard extends StatelessWidget {
  const CatalogArmorCard({
    super.key,
    required this.item,
    this.selected = false,
    this.showOwned = true,
    this.leading,
    this.onTap,
  });

  final CatalogItem item;
  final bool selected;

  /// When false (signed-out), never render owned badge even if data present.
  final bool showOwned;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final count = item.ownedCount;
    final owned = showOwned && (item.owned || count > 0);
    final ownedLabel = owned && count > 0 ? '×$count' : null;
    final rarity = item.isExotic
        ? NeonItemRarity.exotic
        : NeonItemRarity.legendary;

    final classMark = armorClassGlyphMark(item.classType);
    final slotMark = armorSlotGlyphMark(item.slot);
    final classColor = _classColor(palette, item.classType);

    final typeLine = [
      if (item.classType != null && item.classType!.isNotEmpty) item.classType!,
      if (item.slot != null && item.slot!.isNotEmpty) item.slot!,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('catalog_item_${item.hash}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusMax),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 112,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusMax),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.45)
                  : palette.line.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
            color: selected
                ? Color.lerp(
                      palette.surfaceRaised,
                      palette.accent,
                      0.08,
                    ) ??
                    palette.surfaceRaised
                : palette.surface.withValues(alpha: 0.88),
            gradient: item.isExotic
                ? LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    stops: const [0.0, 0.30, 0.62],
                    colors: [
                      const Color(kRarityExotic)
                          .withValues(alpha: selected ? 0.30 : 0.22),
                      const Color(kRarityExotic).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    stops: const [0.0, 0.28, 0.58],
                    colors: [
                      const Color(kRarityLegendaryEdge)
                          .withValues(alpha: selected ? 0.28 : 0.22),
                      const Color(kRarityLegendary).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.18),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading ?? CatalogArmorIconPlate(item: item),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: item.name,
                          waitDuration: const Duration(milliseconds: 400),
                          child: UnbrokenLabel(
                            item.name,
                            key: Key('catalog_item_name_${item.hash}'),
                            maxLines: 2,
                            style: neonDisplay(
                              color: item.isExotic
                                  ? const Color(kRarityExotic)
                                  : palette.foreground,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (typeLine.isNotEmpty)
                              Expanded(
                                child: Text(
                                  typeLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: neonBody(
                                    color: palette.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            _RarityMark(rarity: rarity),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Meta foot: class · slot glyphs + owned ×N — **no stats**.
              Container(
                key: Key('catalog_item_meta_${item.hash}'),
                padding: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: palette.line.withValues(alpha: 0.35),
                      width: kFlapRuleThickness,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _MetaGlyph(
                      key: Key('armor_class_glyph_${item.hash}'),
                      mark: classMark,
                      tooltip: item.classType ?? 'Class',
                      color: classColor,
                    ),
                    const SizedBox(width: 3),
                    _MetaGlyph(
                      key: Key('armor_slot_glyph_${item.hash}'),
                      mark: slotMark,
                      tooltip: item.slot ?? 'Slot',
                      color: palette.foreground,
                    ),
                    if (item.isExotic) ...[
                      const SizedBox(width: 3),
                      _MetaGlyph(
                        key: Key('armor_exotic_badge_${item.hash}'),
                        mark: '✦',
                        tooltip: 'Exotic',
                        color: const Color(kRarityExotic),
                      ),
                    ],
                    const Spacer(),
                    if (ownedLabel != null)
                      Text(
                        ownedLabel,
                        key: Key('owned_badge_${item.hash}'),
                        style: neonMono(
                          color: palette.accent,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RarityMark extends StatelessWidget {
  const _RarityMark({required this.rarity});

  final NeonItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final exotic = rarity == NeonItemRarity.exotic;
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: exotic
              ? const Color(kRarityExotic).withValues(alpha: 0.55)
              : palette.line,
          width: kFlapRuleThickness,
        ),
      ),
      child: Text(
        neonRarityMark(rarity),
        style: neonMono(
          color: exotic ? const Color(kRarityExotic) : palette.muted,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _MetaGlyph extends StatelessWidget {
  const _MetaGlyph({
    super.key,
    required this.mark,
    required this.tooltip,
    required this.color,
  });

  final String mark;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: kFlapRuleThickness,
          ),
          color: palette.background,
        ),
        child: Text(
          mark,
          style: neonMono(color: color, fontSize: 9),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

/// Identity icon grid for armor browse — one card per definition hash.
///
/// No list-row stats; selection + owned honesty via [showOwned].
class CatalogArmorGrid extends StatelessWidget {
  const CatalogArmorGrid({
    super.key,
    required this.items,
    this.selectedHash,
    this.showOwned = true,
    this.onSelect,
    this.leadingBuilder,
    this.headerLabel = 'ARMOR · IDENTITY GRID',
  });

  final List<CatalogItem> items;
  final int? selectedHash;
  final bool showOwned;
  final ValueChanged<CatalogItem>? onSelect;
  final Widget Function(CatalogItem item)? leadingBuilder;
  final String headerLabel;

  static const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 180,
    mainAxisExtent: 112,
    mainAxisSpacing: kSpace8,
    crossAxisSpacing: kSpace8,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('catalog_list'),
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW < 1) {
          return const SizedBox.shrink();
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                key: const Key('catalog_board_header'),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Text(
                  headerLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return CatalogArmorCard(
                      item: item,
                      selected: selectedHash == item.hash,
                      showOwned: showOwned,
                      leading: leadingBuilder?.call(item),
                      onTap: onSelect == null
                          ? null
                          : () => onSelect!(item),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
