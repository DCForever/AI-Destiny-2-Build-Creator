import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_detail.dart';
import 'catalog_weapon_detail.dart' show CatalogOutboundStubs;

// ---------------------------------------------------------------------------
// Presentation DTOs (host maps system/db types — never import domain SetBonus)
// ---------------------------------------------------------------------------

/// EoF six armor stat keys (display order).
const kArmorDetailStatKeys = <String>[
  'Health',
  'Melee',
  'Grenade',
  'Super',
  'Class',
  'Weapons',
];

/// One labeled stat board (Base or Live).
class ArmorStatBoardData {
  const ArmorStatBoardData({
    required this.stats,
    this.total,
    this.incomplete = false,
  });

  final Map<String, int> stats;
  final int? total;
  final bool incomplete;

  bool get hasAny => stats.isNotEmpty;
}

/// Owned copy strip row + rebind payload.
class ArmorInstanceStripItem {
  const ArmorInstanceStripItem({
    required this.instanceId,
    required this.power,
    this.baseTotal,
    this.gearTier,
    this.location,
    this.baseBoard,
    this.liveBoard,
    this.liveUnavailable = false,
    this.mods = const [],
    this.energy,
  });

  final String instanceId;
  final int power;
  final int? baseTotal;
  final int? gearTier;
  final String? location;

  /// Plug-derived base roll for this copy (rebinds Base board).
  final ArmorStatBoardData? baseBoard;

  /// Live ItemStats for this copy (null → live unavailable for this copy).
  final ArmorStatBoardData? liveBoard;

  /// True when live stats are null for this copy (not "unpinned").
  final bool liveUnavailable;

  final List<ArmorModPlugData> mods;
  final ArmorEnergyData? energy;
}

/// Read-only mod plug for DIM-lite energy/mod block.
class ArmorModPlugData {
  const ArmorModPlugData({
    required this.hash,
    required this.displayName,
    this.energyCost,
  });

  final int hash;
  final String displayName;
  final int? energyCost;
}

/// Energy used/capacity when known (never invent capacity).
class ArmorEnergyData {
  const ArmorEnergyData({
    required this.used,
    required this.capacity,
  });

  final int used;
  final int capacity;
}

/// Definition set-bonus callout (2pc/4pc or explicit none).
class ArmorSetBonusData {
  const ArmorSetBonusData({
    this.setName,
    this.twoPiece,
    this.fourPiece,
    this.explicitNone = false,
  });

  final String? setName;
  final String? twoPiece;
  final String? fourPiece;

  /// True when host knows there is no set bonus (not "unknown").
  final bool explicitNone;

  bool get hasDefinition =>
      (setName != null && setName!.trim().isNotEmpty) ||
      (twoPiece != null && twoPiece!.trim().isNotEmpty) ||
      (fourPiece != null && fourPiece!.trim().isNotEmpty);
}

/// Exotic perk definition callout (never invent pools).
class ArmorExoticPerkData {
  const ArmorExoticPerkData({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

// ---------------------------------------------------------------------------
// Base | Live stat board
// ---------------------------------------------------------------------------

/// Simultaneous **labeled** Base | Live EoF six boards (DBR-UI-008).
///
/// Modes:
/// - both present → dual columns with Base / Live labels
/// - base only → single labeled Base column
/// - neither / unknown unowned → "Stats unknown" (no invent)
/// - live null with owned copy → "Live unavailable for this copy"
class ArmorBaseLiveStatBoard extends StatelessWidget {
  const ArmorBaseLiveStatBoard({
    super.key,
    this.baseBoard,
    this.liveBoard,
    this.liveUnavailable = false,
    this.ownedCopy = false,
  });

  final ArmorStatBoardData? baseBoard;
  final ArmorStatBoardData? liveBoard;

  /// Owned copy selected but live stats null.
  final bool liveUnavailable;
  final bool ownedCopy;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final hasBase = baseBoard != null && baseBoard!.hasAny;
    final hasLive = liveBoard != null && liveBoard!.hasAny;

    if (!hasBase && !hasLive) {
      return Column(
        key: const Key('armor_stat_board_unknown'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'STATS',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            key: const Key('armor_stats_unknown'),
            ownedCopy && liveUnavailable
                ? 'Live unavailable for this copy'
                : 'Stats unknown',
            style: neonBody(color: palette.muted, fontSize: 12),
          ),
          if (ownedCopy && liveUnavailable)
            Text(
              key: const Key('armor_live_unavailable'),
              'Live stats unavailable for this copy',
              style: neonMono(color: palette.muted, fontSize: 10),
            ),
        ],
      );
    }

    // Dual labeled columns when live present (even if base missing).
    if (hasLive && hasBase) {
      return Column(
        key: const Key('armor_base_live_stat_board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'STATS',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SingleBoard(
                  key: const Key('armor_base_board'),
                  label: 'Base',
                  board: baseBoard!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SingleBoard(
                  key: const Key('armor_live_board'),
                  label: 'Live',
                  board: liveBoard!,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (hasBase && !hasLive) {
      return Column(
        key: const Key('armor_base_live_stat_board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'STATS',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          _SingleBoard(
            key: const Key('armor_base_board'),
            label: 'Base',
            board: baseBoard!,
          ),
          if (ownedCopy && liveUnavailable) ...[
            const SizedBox(height: 6),
            Text(
              key: const Key('armor_live_unavailable'),
              'Live unavailable for this copy',
              style: neonMono(color: palette.muted, fontSize: 10),
            ),
          ],
        ],
      );
    }

    // Live only (no base) — still label Live; do not mix unlabeled.
    return Column(
      key: const Key('armor_base_live_stat_board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'STATS',
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        _SingleBoard(
          key: const Key('armor_live_board'),
          label: 'Live',
          board: liveBoard!,
        ),
      ],
    );
  }
}

class _SingleBoard extends StatelessWidget {
  const _SingleBoard({
    super.key,
    required this.label,
    required this.board,
  });

  final String label;
  final ArmorStatBoardData board;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          key: Key('armor_stat_label_${label.toLowerCase()}'),
          style: neonMono(
            color: palette.accent.withValues(alpha: 0.85),
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        for (final key in kArmorDetailStatKeys)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    key,
                    style: neonMono(color: palette.muted, fontSize: 9),
                  ),
                ),
                Text(
                  key: Key(
                    'armor_stat_${label.toLowerCase()}_${key.toLowerCase()}',
                  ),
                  '${board.stats[key] ?? '—'}',
                  style: neonMono(
                    color: palette.foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        if (board.total != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Σ',
                    style: neonMono(color: palette.muted, fontSize: 9),
                  ),
                ),
                Text(
                  key: Key('armor_stat_${label.toLowerCase()}_total'),
                  '${board.total}',
                  style: neonMono(
                    color: palette.accent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Instance strip
// ---------------------------------------------------------------------------

/// Compact multi-copy strip sorted by **base total desc** (then power).
///
/// Select rebinds Base and Live boards via host [onSelect].
class ArmorInstanceStrip extends StatelessWidget {
  const ArmorInstanceStrip({
    super.key,
    required this.instances,
    required this.selectedInstanceId,
    required this.onSelect,
  });

  final List<ArmorInstanceStripItem> instances;
  final String? selectedInstanceId;
  final ValueChanged<ArmorInstanceStripItem> onSelect;

  /// Sort by base total desc, then power desc, stable id.
  static List<ArmorInstanceStripItem> sortByBaseTotal(
    List<ArmorInstanceStripItem> items,
  ) {
    final list = List<ArmorInstanceStripItem>.from(items);
    list.sort((a, b) {
      final ta = a.baseTotal ?? a.baseBoard?.total;
      final tb = b.baseTotal ?? b.baseBoard?.total;
      if (ta != null && tb != null && ta != tb) return tb.compareTo(ta);
      if (ta != null && tb == null) return -1;
      if (ta == null && tb != null) return 1;
      final p = b.power.compareTo(a.power);
      if (p != 0) return p;
      return a.instanceId.compareTo(b.instanceId);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (instances.isEmpty) {
      return Text(
        key: const Key('armor_instance_strip_empty'),
        'No local copies',
        style: neonBody(color: palette.muted, fontSize: 12),
      );
    }

    final ordered = sortByBaseTotal(instances);

    return Column(
      key: const Key('armor_instance_strip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COPIES',
          style: neonMono(
            color: palette.muted.withValues(alpha: 0.7),
            fontSize: 8,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final inst in ordered)
              _InstanceChip(
                item: inst,
                selected: inst.instanceId == selectedInstanceId,
                onTap: () => onSelect(inst),
              ),
          ],
        ),
      ],
    );
  }
}

class _InstanceChip extends StatelessWidget {
  const _InstanceChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ArmorInstanceStripItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final base = item.baseTotal ?? item.baseBoard?.total;
    final label = [
      if (base != null) 'Σ$base',
      'PL ${item.power}',
      if (item.gearTier != null) 'T${item.gearTier}',
    ].join(' · ');

    return Semantics(
      button: true,
      selected: selected,
      label: 'Copy $label',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('armor_instance_${item.instanceId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: selected
                    ? palette.accent.withValues(alpha: 0.55)
                    : palette.line,
                width: kFlapRuleThickness,
              ),
              color: selected
                  ? palette.accent.withValues(alpha: 0.12)
                  : palette.surfaceRaised.withValues(alpha: 0.5),
            ),
            child: Text(
              label,
              style: neonMono(
                color: selected ? palette.accent : palette.foreground,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mods + energy (hide when empty)
// ---------------------------------------------------------------------------

/// Read-only mods + energy block — **hidden entirely** when no plugs/energy.
class ArmorModsEnergyBlock extends StatelessWidget {
  const ArmorModsEnergyBlock({
    super.key,
    this.mods = const [],
    this.energy,
  });

  final List<ArmorModPlugData> mods;
  final ArmorEnergyData? energy;

  bool get _visible => mods.isNotEmpty || energy != null;

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink(key: Key('armor_mods_energy_hidden'));
    }

    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('armor_mods_energy_block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MODS & ENERGY',
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        if (energy != null) ...[
          const SizedBox(height: 4),
          Text(
            key: const Key('armor_energy_bar'),
            'Energy ${energy!.used} / ${energy!.capacity}',
            style: neonMono(color: palette.foreground, fontSize: 11),
          ),
        ],
        if (mods.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final m in mods)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                key: Key('armor_mod_${m.hash}'),
                children: [
                  Expanded(
                    child: Text(
                      m.displayName,
                      style: neonBody(color: palette.foreground, fontSize: 12),
                    ),
                  ),
                  if (m.energyCost != null)
                    Text(
                      '${m.energyCost}',
                      style: neonMono(color: palette.muted, fontSize: 10),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Set bonus / exotic callouts
// ---------------------------------------------------------------------------

/// Definition 2pc/4pc or explicit "no set bonus" — no vault progress meters.
class ArmorSetBonusCallout extends StatelessWidget {
  const ArmorSetBonusCallout({
    super.key,
    this.data,
  });

  final ArmorSetBonusData? data;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (data == null) {
      return const SizedBox.shrink(key: Key('armor_set_bonus_omitted'));
    }
    if (data!.explicitNone && !data!.hasDefinition) {
      return Column(
        key: const Key('armor_set_bonus_none'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SET BONUS',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No set bonus',
            style: neonBody(color: palette.muted, fontSize: 12),
          ),
        ],
      );
    }
    if (!data!.hasDefinition) {
      return const SizedBox.shrink(key: Key('armor_set_bonus_omitted'));
    }

    return Column(
      key: const Key('armor_set_bonus_callout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SET BONUS',
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        if (data!.setName != null && data!.setName!.trim().isNotEmpty)
          Text(
            data!.setName!,
            key: const Key('armor_set_bonus_name'),
            style: neonDisplay(color: palette.foreground, fontSize: 12),
          ),
        if (data!.twoPiece != null && data!.twoPiece!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              key: const Key('armor_set_bonus_2pc'),
              '2pc · ${data!.twoPiece}',
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          ),
        if (data!.fourPiece != null && data!.fourPiece!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              key: const Key('armor_set_bonus_4pc'),
              '4pc · ${data!.fourPiece}',
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Exotic perk callout from definition only — no invent pools.
class ArmorExoticPerkCallout extends StatelessWidget {
  const ArmorExoticPerkCallout({
    super.key,
    this.data,
  });

  final ArmorExoticPerkData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.name.trim().isEmpty) {
      return const SizedBox.shrink(key: Key('armor_exotic_callout_omitted'));
    }
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('armor_exotic_perk_callout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'EXOTIC PERK',
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          data!.name,
          key: const Key('armor_exotic_perk_name'),
          style: neonDisplay(
            color: const Color(kRarityExotic),
            fontSize: 13,
          ),
        ),
        if (data!.description != null &&
            data!.description!.trim().isNotEmpty)
          Text(
            data!.description!,
            key: const Key('armor_exotic_perk_desc'),
            style: neonBody(color: palette.muted, fontSize: 12),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full armor detail dossier
// ---------------------------------------------------------------------------

/// Armor detail sidebar (~400 workspace rail) — composition aid only.
///
/// Honesty:
/// - Unowned: no invented rolls; omit live/mods/energy; set/exotic def only when data
/// - Owned: multi-copy strip; Base rebinds per instance; labeled Base|Live
/// - Mods/energy hidden when none
/// - Outbound Set/Synergy stubs disabled only
class CatalogArmorDetail extends StatelessWidget {
  const CatalogArmorDetail({
    super.key,
    required this.item,
    this.instances = const [],
    this.selectedInstanceId,
    this.onSelectInstance,
    this.setBonus,
    this.exoticPerk,
    this.definitionBaseBoard,
    this.headerTrailing,
    this.showOwnedMeta = true,
  });

  final CatalogItem item;
  final List<ArmorInstanceStripItem> instances;
  final String? selectedInstanceId;
  final ValueChanged<ArmorInstanceStripItem>? onSelectInstance;

  /// Definition set-bonus (when data exists).
  final ArmorSetBonusData? setBonus;

  /// Exotic intrinsic definition (when data exists).
  final ArmorExoticPerkData? exoticPerk;

  /// Optional definition-backed base six for unowned (never invent).
  final ArmorStatBoardData? definitionBaseBoard;

  final Widget? headerTrailing;

  /// When false, omit owned ×N chrome (signed-out honesty).
  final bool showOwnedMeta;

  ArmorInstanceStripItem? get _selected {
    if (instances.isEmpty) return null;
    final id = selectedInstanceId;
    if (id != null) {
      for (final i in instances) {
        if (i.instanceId == id) return i;
      }
    }
    final ordered = ArmorInstanceStrip.sortByBaseTotal(instances);
    return ordered.isEmpty ? null : ordered.first;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final owned = instances.isNotEmpty;
    final sel = _selected;

    final ArmorStatBoardData? baseBoard =
        owned ? sel?.baseBoard : definitionBaseBoard;
    final ArmorStatBoardData? liveBoard = owned ? sel?.liveBoard : null;
    final liveUnavailable =
        owned && (sel?.liveUnavailable == true || sel?.liveBoard == null);
    final mods = owned ? (sel?.mods ?? const <ArmorModPlugData>[]) : const <ArmorModPlugData>[];
    final energy = owned ? sel?.energy : null;

    final kickerParts = <String>[
      'Armor',
      if (item.isExotic) 'Exotic' else 'Legendary',
      if (item.classType != null && item.classType!.isNotEmpty) item.classType!,
      if (item.slot != null && item.slot!.isNotEmpty) item.slot!,
    ];

    final material = Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonDetailHeader(
            title: item.name,
            kicker: kickerParts.join(' · '),
            kickerKey: const Key('detail_kind_label'),
            subtitle: null,
            pills: [
              if (showOwnedMeta && item.owned && item.ownedCount > 0)
                NeonMetaPill(
                  'Owned ×${item.ownedCount}',
                  tone: NeonPillTone.ok,
                ),
            ],
            actions: headerTrailing,
          ),
          Divider(height: 1, color: palette.line),
          Expanded(
            child: ListView(
              key: const Key('armor_detail_scroll'),
              padding: const EdgeInsets.fromLTRB(
                kSpace12,
                kSpace8,
                kSpace12,
                kSpace12,
              ),
              children: [
                if (owned) ...[
                  ArmorInstanceStrip(
                    instances: instances,
                    selectedInstanceId:
                        sel?.instanceId ?? selectedInstanceId,
                    onSelect: onSelectInstance ?? (_) {},
                  ),
                  const SizedBox(height: kSpace12),
                ],
                ArmorBaseLiveStatBoard(
                  baseBoard: baseBoard,
                  liveBoard: liveBoard,
                  liveUnavailable: liveUnavailable,
                  ownedCopy: owned,
                ),
                // Mods/energy only when owned + plugs known (hide empty).
                if (owned) ...[
                  const SizedBox(height: kSpace12),
                  ArmorModsEnergyBlock(mods: mods, energy: energy),
                ],
                if (setBonus != null) ...[
                  const SizedBox(height: kSpace12),
                  ArmorSetBonusCallout(data: setBonus),
                ],
                if (item.isExotic && exoticPerk != null) ...[
                  const SizedBox(height: kSpace12),
                  ArmorExoticPerkCallout(data: exoticPerk),
                ],
                const SizedBox(height: kSpace16),
                const CatalogOutboundStubs(),
              ],
            ),
          ),
        ],
      ),
    );

    return KeyedSubtree(
      key: Key('catalog_armor_detail_${item.hash}'),
      child: material,
    );
  }
}
