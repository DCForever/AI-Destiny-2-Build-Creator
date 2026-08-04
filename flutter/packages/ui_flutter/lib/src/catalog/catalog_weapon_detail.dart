import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_detail.dart';

// ---------------------------------------------------------------------------
// Presentation models (host supplies data; widgets never invent pools)
// ---------------------------------------------------------------------------

/// One plug cell in the weapons perk grid.
class CatalogPerkCell {
  const CatalogPerkCell({
    required this.hash,
    required this.displayName,
    this.icon,
    this.selected = false,
    this.fromCanRollPool = false,
    this.fromCraftPool = false,
    this.unknown = false,
  });

  final int hash;
  final String displayName;

  /// Bungie relative icon path (`/common/destiny2_content/icons/…`), when known.
  final String? icon;
  final bool selected;
  final bool fromCanRollPool;
  final bool fromCraftPool;
  final bool unknown;
}

/// One column in the weapons perk grid.
class CatalogPerkColumn {
  const CatalogPerkColumn({
    required this.label,
    required this.cells,
    this.kind,
  });

  final String label;
  final String? kind;
  final List<CatalogPerkCell> cells;
}

/// Build columns from instance sockets and/or definition perk columns.
///
/// - **Owned instance:** selected plugs always shown; can-roll pool only when
///   [showCanRoll] (and definition reusables merge when provided).
/// - **Unowned / definition-only:** full **possible rolls** (curated ∪ randomized
///   from [definitionSocketPlugs]) — always shown as pool cells (no fake selected
///   roll). Does not invent plugs.
/// - Craft pool only when [showCraft] and craft cells provided (never invent).
/// - Unknown names → label "Unknown perk" + hash tracked for footer.
List<CatalogPerkColumn> buildCatalogPerkColumns({
  List<Map<String, Object?>>? socketPlugs,
  List<Map<String, Object?>>? definitionSocketPlugs,
  List<ResolvedPlugCard> plugCards = const [],
  Map<int, String> plugNameByHash = const {},
  Map<int, String> plugIconByHash = const {},
  bool showCanRoll = false,
  bool showCraft = false,
  List<CatalogPerkColumn> craftColumns = const [],
}) {
  final out = <CatalogPerkColumn>[];

  // Prefer instance sockets; fall back to definition (unowned / missing capture).
  List<Map<String, Object?>>? effectiveSockets;
  var usingDefinitionOnly = false;
  if (socketPlugs != null && socketPlugs.isNotEmpty) {
    if (showCanRoll &&
        definitionSocketPlugs != null &&
        definitionSocketPlugs.isNotEmpty) {
      effectiveSockets = _mergeDefinitionReusablesIntoSockets(
        socketPlugs,
        definitionSocketPlugs,
      );
    } else {
      effectiveSockets = socketPlugs;
    }
  } else if (definitionSocketPlugs != null &&
      definitionSocketPlugs.isNotEmpty) {
    effectiveSockets = definitionSocketPlugs;
    usingDefinitionOnly = true;
  }

  if (effectiveSockets != null && effectiveSockets.isNotEmpty) {
    for (final raw in effectiveSockets) {
      final kind = raw['columnKind'] as String?;
      final label = (raw['columnLabel'] as String?)?.trim();
      final equippedRaw = raw['equippedPlugHash'];
      final equipped = equippedRaw is int
          ? equippedRaw
          : equippedRaw is num
              ? equippedRaw.toInt()
              : null;

      List<int> parseReusable() {
        final out = <int>[];
        final rawReusable = raw['reusablePlugHashes'];
        if (rawReusable is List) {
          for (final e in rawReusable) {
            final h = e is int
                ? e
                : e is num
                    ? e.toInt()
                    : int.tryParse('$e');
            if (h != null && h != 0) out.add(h);
          }
        }
        return out;
      }

      final cells = <CatalogPerkCell>[];
      void addCell(int h, {required bool selected, required bool pool}) {
        if (h == 0) return;
        if (cells.any((c) => c.hash == h)) return;
        final name = plugNameByHash[h] ?? _cardName(plugCards, h);
        final unknown = _isUnknownPerkName(name, h);
        final display = unknown ? 'Unknown perk' : (name ?? 'Unknown perk');
        cells.add(
          CatalogPerkCell(
            hash: h,
            displayName: display,
            icon: plugIconByHash[h] ??
                (unknown ? null : _frameIconFallback(display)),
            selected: selected,
            fromCanRollPool: pool && !selected,
            unknown: unknown,
          ),
        );
      }

      if (usingDefinitionOnly) {
        // Possible rolls: full definition pool, no owned selected highlight.
        final pool = <int>{
          if (equipped != null && equipped != 0) equipped,
          ...parseReusable(),
        };
        for (final h in pool) {
          addCell(h, selected: false, pool: true);
        }
      } else {
        final reusable = showCanRoll ? parseReusable() : const <int>[];
        if (equipped != null) addCell(equipped, selected: true, pool: false);
        for (final h in reusable) {
          if (h != equipped) addCell(h, selected: false, pool: true);
        }
      }

      if (cells.isEmpty) continue;
      final colLabel = (label != null && label.isNotEmpty)
          ? label
          : (kind != null && kind.isNotEmpty)
              ? kind
              : 'Plug';
      out.add(CatalogPerkColumn(label: colLabel, kind: kind, cells: cells));
    }
  } else if (plugCards.isNotEmpty) {
    // Selected-only flat cards when no socket structure.
    final byLabel = <String, List<ResolvedPlugCard>>{};
    for (final c in plugCards) {
      final key = (c.columnLabel != null && c.columnLabel!.isNotEmpty)
          ? c.columnLabel!
          : (c.isTrait ? 'Trait' : 'Perk');
      byLabel.putIfAbsent(key, () => []).add(c);
    }
    for (final e in byLabel.entries) {
      out.add(
        CatalogPerkColumn(
          label: e.key,
          cells: [
            for (final c in e.value)
              CatalogPerkCell(
                hash: c.hash,
                displayName: c.displayName.isEmpty || c.displayName == '#${c.hash}'
                    ? 'Unknown perk'
                    : c.displayName,
                icon: plugIconByHash[c.hash] ??
                    _frameIconFallback(
                      c.displayName.isEmpty || c.displayName == '#${c.hash}'
                          ? null
                          : c.displayName,
                    ),
                selected: true,
                unknown: c.displayName.isEmpty ||
                    c.displayName == '#${c.hash}' ||
                    !c.resolved,
              ),
          ],
        ),
      );
    }
  }

  // Craft: same column/cell format, only when toggled and host provided data.
  if (showCraft && craftColumns.isNotEmpty) {
    for (final craftCol in craftColumns) {
      final existing = out.indexWhere(
        (c) =>
            c.label == craftCol.label ||
            (c.kind != null && c.kind == craftCol.kind),
      );
      if (existing >= 0) {
        final merged = [...out[existing].cells];
        for (final cell in craftCol.cells) {
          if (!merged.any((m) => m.hash == cell.hash)) {
            merged.add(
              CatalogPerkCell(
                hash: cell.hash,
                displayName: cell.displayName,
                icon: cell.icon,
                selected: false,
                fromCraftPool: true,
                unknown: cell.unknown,
              ),
            );
          }
        }
        out[existing] = CatalogPerkColumn(
          label: out[existing].label,
          kind: out[existing].kind,
          cells: merged,
        );
      } else {
        out.add(
          CatalogPerkColumn(
            label: craftCol.label,
            kind: craftCol.kind,
            cells: [
              for (final c in craftCol.cells)
                CatalogPerkCell(
                  hash: c.hash,
                  displayName: c.displayName,
                  icon: c.icon,
                  fromCraftPool: true,
                  unknown: c.unknown,
                ),
            ],
          ),
        );
      }
    }
  }

  return List.unmodifiable(out);
}

String? _cardName(List<ResolvedPlugCard> cards, int hash) {
  for (final c in cards) {
    if (c.hash == hash && c.displayName.isNotEmpty) return c.displayName;
  }
  return null;
}

/// True when [name] is missing or a bare-hash / column-label fallback.
bool _isUnknownPerkName(String? name, int hash) {
  if (name == null || name.isEmpty) return true;
  if (name == '#$hash') return true;
  // Projection fallback: "Trait 1 (#12345)" before real plug names resolve.
  if (name.endsWith('(#$hash)')) return true;
  if (name.startsWith('#') && name.substring(1) == '$hash') return true;
  return false;
}

/// Expand instance `reusablePlugHashes` with definition pool hashes (can-roll).
///
/// Aligns non-meta instance columns (skips intrinsic/masterwork/catalyst/origin)
/// to definition columns in order.
List<Map<String, Object?>> _mergeDefinitionReusablesIntoSockets(
  List<Map<String, Object?>> instanceSockets,
  List<Map<String, Object?>> definitionSockets,
) {
  var defIdx = 0;
  final out = <Map<String, Object?>>[];
  for (final raw in instanceSockets) {
    final kind = (raw['columnKind'] as String?)?.toLowerCase() ?? '';
    final isMeta = kind == 'intrinsic' ||
        kind == 'masterwork' ||
        kind == 'catalyst' ||
        kind == 'origin';
    final map = Map<String, Object?>.from(raw);
    if (!isMeta && defIdx < definitionSockets.length) {
      final def = definitionSockets[defIdx++];
      final hashes = <int>{};
      void take(Object? list) {
        if (list is! List) return;
        for (final e in list) {
          final h = e is int
              ? e
              : e is num
                  ? e.toInt()
                  : int.tryParse('$e');
          if (h != null && h != 0) hashes.add(h);
        }
      }

      take(map['reusablePlugHashes']);
      take(def['reusablePlugHashes']);
      final equipped = def['equippedPlugHash'];
      if (equipped is int && equipped != 0) {
        hashes.add(equipped);
      } else if (equipped is num && equipped.toInt() != 0) {
        hashes.add(equipped.toInt());
      }
      map['reusablePlugHashes'] = hashes.toList(growable: false);
    }
    out.add(map);
  }
  return out;
}

/// Official frame icon when plug defs unavailable (structure fallback only).
String? _frameIconFallback(String? displayName) {
  if (displayName == null || displayName.isEmpty) return null;
  return officialWeaponFrameVisual(displayName)?.iconPath;
}

List<int> unknownPerkHashes(List<CatalogPerkColumn> columns) {
  final out = <int>[];
  for (final col in columns) {
    for (final cell in col.cells) {
      if (cell.unknown && !out.contains(cell.hash)) out.add(cell.hash);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

/// Can-roll and possible-crafted toggles (both OFF by default at host).
class CatalogDetailToggles extends StatelessWidget {
  const CatalogDetailToggles({
    super.key,
    required this.showCanRoll,
    required this.showCraft,
    required this.onCanRollChanged,
    required this.onCraftChanged,
    this.craftAvailable = true,
  });

  final bool showCanRoll;
  final bool showCraft;
  final ValueChanged<bool> onCanRollChanged;
  final ValueChanged<bool> onCraftChanged;

  /// When false, craft toggle is hidden (no craft data) — not inventable.
  final bool craftAvailable;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Wrap(
      key: const Key('catalog_detail_toggles'),
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          key: const Key('catalog_toggle_can_roll'),
          label: Text(
            'Can roll',
            style: neonMono(color: palette.foreground, fontSize: 11),
          ),
          selected: showCanRoll,
          onSelected: onCanRollChanged,
          visualDensity: VisualDensity.compact,
        ),
        if (craftAvailable)
          FilterChip(
            key: const Key('catalog_toggle_craft'),
            label: Text(
              'Possible crafted',
              style: neonMono(color: palette.foreground, fontSize: 11),
            ),
            selected: showCraft,
            onSelected: onCraftChanged,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

/// DIM-style perk grid: selected distinct; pool cells only when toggled.
class CatalogPerkGrid extends StatelessWidget {
  const CatalogPerkGrid({
    super.key,
    required this.columns,
  });

  final List<CatalogPerkColumn> columns;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (columns.isEmpty) {
      return Padding(
        key: const Key('catalog_perk_grid_empty'),
        padding: const EdgeInsets.symmetric(vertical: kSpace8),
        child: Text(
          'No plug data for this selection.',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('catalog_perk_grid'),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in columns)
            Padding(
              padding: const EdgeInsets.only(right: kSpace8),
              child: SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      col.label.toUpperCase(),
                      style: neonMono(
                        color: palette.muted,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    for (final cell in col.cells)
                      _PerkCellTile(cell: cell),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PerkCellTile extends StatelessWidget {
  const _PerkCellTile({required this.cell});

  final CatalogPerkCell cell;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final selected = cell.selected;
    final pool = cell.fromCanRollPool || cell.fromCraftPool;
    final border = selected
        ? palette.accent.withValues(alpha: 0.55)
        : pool
            ? palette.line
            : palette.line.withValues(alpha: 0.4);
    final bg = selected
        ? palette.accent.withValues(alpha: 0.12)
        : palette.surfaceRaised.withValues(alpha: 0.5);
    final iconPath = cell.icon;
    final accent = selected ? palette.accent : palette.muted;

    return Tooltip(
      message: cell.displayName,
      child: Container(
        key: Key('perk_cell_${cell.hash}'),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: kFlapRuleThickness),
          borderRadius: BorderRadius.circular(kRadiusMax),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null && iconPath.isNotEmpty)
              BungieContentIcon(
                key: selected ? Key('perk_selected_${cell.hash}') : null,
                pathOrUrl: iconPath,
                size: 36,
                // Parent Tooltip names the cell — avoid AX thrash on image load.
                fallback: _PerkIconFallback(
                  label: cell.displayName,
                  color: accent,
                ),
              )
            else
              _PerkIconFallback(
                key: selected ? Key('perk_selected_${cell.hash}') : null,
                label: cell.displayName,
                color: accent,
              ),
            const SizedBox(height: 2),
            Text(
              // Caption under icon — never bare-hash primary (DBR-UI-006).
              cell.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: neonBody(
                color: selected
                    ? palette.foreground
                    : pool
                        ? palette.muted
                        : palette.foreground,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkIconFallback extends StatelessWidget {
  const _PerkIconFallback({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Text(
            mark,
            style: neonMono(color: color, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// Exotic intrinsic near display-only catalyst; craft/catalyst independent.
class ExoticIdentityBlock extends StatelessWidget {
  const ExoticIdentityBlock({
    super.key,
    this.intrinsicName,
    this.intrinsicDescription,
    this.catalystName,
    this.catalystDescription,
    this.catalystComplete,
  });

  final String? intrinsicName;
  final String? intrinsicDescription;
  final String? catalystName;
  final String? catalystDescription;
  final bool? catalystComplete;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final hasIntrinsic =
        (intrinsicName != null && intrinsicName!.trim().isNotEmpty) ||
            (intrinsicDescription != null &&
                intrinsicDescription!.trim().isNotEmpty);
    final hasCatalyst =
        catalystName != null && catalystName!.trim().isNotEmpty;

    if (!hasIntrinsic && !hasCatalyst) {
      return const SizedBox.shrink(key: Key('exotic_identity_empty'));
    }

    return Column(
      key: const Key('exotic_identity_block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasIntrinsic) ...[
          Text(
            'INTRINSIC',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          if (intrinsicName != null && intrinsicName!.trim().isNotEmpty)
            Text(
              intrinsicName!,
              key: const Key('exotic_intrinsic_name'),
              style: neonDisplay(
                color: Color(kRarityExotic),
                fontSize: 13,
              ),
            ),
          if (intrinsicDescription != null &&
              intrinsicDescription!.trim().isNotEmpty)
            Text(
              intrinsicDescription!,
              key: const Key('exotic_intrinsic_desc'),
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          const SizedBox(height: kSpace8),
        ],
        if (hasCatalyst) ...[
          Text(
            'CATALYST',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            catalystName!,
            key: const Key('exotic_catalyst_name'),
            style: neonBody(color: palette.foreground, fontSize: 13),
          ),
          if (catalystDescription != null &&
              catalystDescription!.trim().isNotEmpty)
            Text(
              catalystDescription!,
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          if (catalystComplete != null)
            Text(
              catalystComplete! ? 'Complete' : 'Incomplete',
              key: const Key('exotic_catalyst_status'),
              style: neonMono(
                color: catalystComplete! ? palette.success : palette.warning,
                fontSize: 10,
              ),
            ),
          // Soft-only — never a gate control.
          Text(
            key: const Key('exotic_catalyst_display_only'),
            'Display only — does not gate equip or save',
            style: neonMono(color: palette.muted, fontSize: 9),
          ),
        ],
      ],
    );
  }
}

/// Unknown perk label + hash footer (never bare-hash primary name).
class CatalogHashFooter extends StatelessWidget {
  const CatalogHashFooter({
    super.key,
    required this.unknownHashes,
  });

  final List<int> unknownHashes;

  @override
  Widget build(BuildContext context) {
    if (unknownHashes.isEmpty) {
      return const SizedBox.shrink(key: Key('catalog_hash_footer_empty'));
    }
    final palette = FlapPalette.of(context);
    return Padding(
      key: const Key('catalog_hash_footer'),
      padding: const EdgeInsets.only(top: kSpace8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'UNKNOWN PERKS',
            style: neonMono(
              color: palette.muted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          for (final h in unknownHashes)
            Text(
              'Unknown perk · #$h',
              key: Key('catalog_hash_footer_$h'),
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

/// Set / Synergy disabled stubs only (weapons detail path).
class CatalogOutboundStubs extends StatelessWidget {
  const CatalogOutboundStubs({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Wrap(
      key: const Key('catalog_outbound_stubs'),
      spacing: 8,
      children: [
        FilledButton.tonal(
          key: const Key('catalog_stub_set'),
          onPressed: null,
          child: const Text('Set'),
        ),
        FilledButton.tonal(
          key: const Key('catalog_stub_synergy'),
          onPressed: null,
          child: const Text('Synergy'),
        ),
        Text(
          'Outbound create deferred',
          style: neonMono(color: palette.muted, fontSize: 10),
        ),
      ],
    );
  }
}

/// Multi-instance power-desc strip; default selection is highest power.
class WeaponInstanceStrip extends StatelessWidget {
  const WeaponInstanceStrip({
    super.key,
    required this.instances,
    required this.selectedInstanceId,
    required this.onSelect,
  });

  final List<CatalogInstanceProjection> instances;
  final String? selectedInstanceId;
  final ValueChanged<CatalogInstanceProjection> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (instances.isEmpty) {
      return Text(
        key: const Key('weapon_instance_strip_empty'),
        'No local copies',
        style: neonBody(color: palette.muted, fontSize: 12),
      );
    }

    // Power-desc display order (caller should already sort; re-sort for safety).
    final ordered = List<CatalogInstanceProjection>.from(instances)
      ..sort((a, b) => b.power.compareTo(a.power));

    return SingleChildScrollView(
      key: const Key('weapon_instance_strip'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final inst in ordered)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: Key('instance_chip_${inst.instanceId}'),
                label: Text(
                  'PL ${inst.power}'
                  '${inst.isMasterwork ? ' · MW' : ''}'
                  '${inst.isCrafted ? ' · Craft' : ''}',
                ),
                selected: selectedInstanceId == inst.instanceId,
                onSelected: (_) => onSelect(inst),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

/// Default highest-power instance id (power-desc).
String? defaultHighestPowerInstanceId(
  List<CatalogInstanceProjection> instances,
) {
  if (instances.isEmpty) return null;
  CatalogInstanceProjection best = instances.first;
  for (final i in instances.skip(1)) {
    if (i.power > best.power) best = i;
  }
  return best.instanceId;
}

/// Full weapons detail sidebar shell.
class CatalogWeaponDetail extends StatelessWidget {
  const CatalogWeaponDetail({
    super.key,
    required this.item,
    this.instances = const [],
    this.selectedInstanceId,
    this.onSelectInstance,
    this.showCanRoll = false,
    this.showCraft = false,
    this.onCanRollChanged,
    this.onCraftChanged,
    this.craftAvailable = false,
    this.craftColumns = const [],
    this.definitionSocketPlugs = const [],
    this.plugNameByHash = const {},
    this.plugIconByHash = const {},
    this.intrinsicName,
    this.intrinsicDescription,
    this.catalystName,
    this.catalystDescription,
    this.catalystComplete,
    this.headerTrailing,
  });

  final CatalogItem item;
  final List<CatalogInstanceProjection> instances;
  final String? selectedInstanceId;
  final ValueChanged<CatalogInstanceProjection>? onSelectInstance;
  final bool showCanRoll;
  final bool showCraft;
  final ValueChanged<bool>? onCanRollChanged;
  final ValueChanged<bool>? onCraftChanged;
  final bool craftAvailable;
  final List<CatalogPerkColumn> craftColumns;

  /// Entity-store definition plugs (unowned / can-roll expansion). Never invent.
  final List<Map<String, Object?>> definitionSocketPlugs;
  final Map<int, String> plugNameByHash;
  final Map<int, String> plugIconByHash;
  final String? intrinsicName;
  final String? intrinsicDescription;
  final String? catalystName;
  final String? catalystDescription;
  final bool? catalystComplete;
  final Widget? headerTrailing;

  CatalogInstanceProjection? get _selected {
    if (instances.isEmpty) return null;
    final id = selectedInstanceId ?? defaultHighestPowerInstanceId(instances);
    for (final i in instances) {
      if (i.instanceId == id) return i;
    }
    return instances.first;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final inst = _selected;
    final hasOwnedCopy = instances.isNotEmpty;
    // Instance sockets drive selected plugs. Unowned → definition possible rolls.
    final columns = buildCatalogPerkColumns(
      socketPlugs: inst?.socketPlugs,
      definitionSocketPlugs:
          definitionSocketPlugs.isEmpty ? null : definitionSocketPlugs,
      plugCards: inst?.plugCards ?? const [],
      plugNameByHash: plugNameByHash,
      plugIconByHash: plugIconByHash,
      showCanRoll: showCanRoll,
      showCraft: showCraft,
      craftColumns: craftColumns,
    );
    final unknowns = unknownPerkHashes(columns);
    final typeLine = [
      if (item.itemTypeName != null) item.itemTypeName!,
      if (item.frame != null && item.frame!.isNotEmpty) item.frame!,
      if (item.slot != null) item.slot!,
    ].join(' · ');
    final perkSectionLabel = hasOwnedCopy ? 'PERKS' : 'POSSIBLE ROLLS';

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonDetailHeader(
            title: item.name,
            kicker: item.isExotic ? 'Weapon · Exotic' : 'Weapon',
            kickerKey: const Key('detail_kind_label'),
            subtitle: typeLine.isEmpty ? null : typeLine,
            pills: [
              if (item.element != null)
                NeonMetaPill(item.element!, tone: NeonPillTone.accent),
              if (item.isExotic)
                const NeonMetaPill('Exotic', tone: NeonPillTone.exotic),
              if (item.owned)
                NeonMetaPill(
                  'Owned ×${item.ownedCount}',
                  tone: NeonPillTone.ok,
                ),
            ],
            actions: headerTrailing,
          ),
          if (hasOwnedCopy) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace12),
              child: WeaponInstanceStrip(
                instances: instances,
                selectedInstanceId:
                    selectedInstanceId ?? defaultHighestPowerInstanceId(instances),
                onSelect: onSelectInstance ?? (_) {},
              ),
            ),
            const SizedBox(height: kSpace8),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace12),
              child: Text(
                key: const Key('instance_panel_empty'),
                'No local copies — showing possible rolls from definition',
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
            ),
          // Can-roll / craft toggles only for owned copies (selected vs pool).
          // Unowned always shows possible rolls below.
          if (hasOwnedCopy &&
              onCanRollChanged != null &&
              onCraftChanged != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace12),
              child: CatalogDetailToggles(
                showCanRoll: showCanRoll,
                showCraft: showCraft,
                onCanRollChanged: onCanRollChanged!,
                onCraftChanged: onCraftChanged!,
                craftAvailable: craftAvailable,
              ),
            ),
          Divider(height: 1, color: palette.line),
          Expanded(
            child: ListView(
              key: const Key('instance_list'),
              padding: const EdgeInsets.all(kSpace12),
              children: [
                if (item.isExotic)
                  ExoticIdentityBlock(
                    intrinsicName: intrinsicName,
                    intrinsicDescription:
                        intrinsicDescription ?? item.description,
                    catalystName: catalystName,
                    catalystDescription: catalystDescription,
                    catalystComplete: catalystComplete,
                  ),
                const SizedBox(height: kSpace8),
                Text(
                  key: Key(
                    hasOwnedCopy
                        ? 'catalog_perk_section_perks'
                        : 'catalog_perk_section_possible_rolls',
                  ),
                  perkSectionLabel,
                  style: neonMono(
                    color: palette.muted,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                CatalogPerkGrid(columns: columns),
                CatalogHashFooter(unknownHashes: unknowns),
                const SizedBox(height: kSpace16),
                const CatalogOutboundStubs(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
