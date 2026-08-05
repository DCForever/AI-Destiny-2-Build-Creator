import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_detail.dart';
import 'catalog_weapon_meta_strip.dart';

// ---------------------------------------------------------------------------
// Presentation models (host supplies data; widgets never invent pools)
// ---------------------------------------------------------------------------

/// One plug cell in the weapons perk grid.
///
/// Tiers (owned): ① [selected] · ② unselected instance · ③ [fromCanRollPool].
/// Enhanced is orthogonal to any tier.
class CatalogPerkCell {
  const CatalogPerkCell({
    required this.hash,
    required this.displayName,
    this.icon,
    this.selected = false,
    this.fromCanRollPool = false,
    this.fromCraftPool = false,
    this.unknown = false,
    this.enhanced = false,
  });

  final int hash;
  final String displayName;

  /// Bungie relative icon path (`/common/destiny2_content/icons/…`), when known.
  final String? icon;

  /// ① Selected on this owned instance.
  final bool selected;

  /// ③ Definition possible-roll pool (only when Possible rolls is ON for owned).
  final bool fromCanRollPool;
  final bool fromCraftPool;
  final bool unknown;

  /// Enhanced plug (gold/E) — name heuristic and/or host flag.
  final bool enhanced;

  /// ② Unselected instance plug (owned): not selected and not pool/craft.
  bool get isInstanceUnselected =>
      !selected && !fromCanRollPool && !fromCraftPool;
}

/// One column in the weapons perk grid.
class CatalogPerkColumn {
  const CatalogPerkColumn({
    required this.label,
    required this.cells,
    this.kind,
    this.canBeEnhanced = false,
  });

  final String label;
  final String? kind;
  final List<CatalogPerkCell> cells;

  /// Pool/unowned/craft supports Enhanced variants — note only, no E cells.
  final bool canBeEnhanced;
}

/// Build columns from instance sockets and/or definition perk columns.
///
/// - **Owned instance:** ① selected + ② instance reusables always; ③ definition
///   possible rolls only when [showCanRoll] (never invent plugs).
/// - **Unowned / definition-only:** full **possible rolls** (curated ∪ randomized
///   from [definitionSocketPlugs]) — always shown as pool cells (no fake selected
///   roll). Does not invent plugs.
/// - **Origin:** only when a column has origin kind/data with plugs; never invent.
/// - Craft pool only when [showCraft] and craft cells provided (never invent).
/// - **Enhanced gold/E only on ①/②** instance plugs when [plugEnhancedByHash]
///   or name heuristic says so. ③ / unowned / craft = one cell per identity +
///   [CatalogPerkColumn.canBeEnhanced] note (never base+enhanced pair; no E).
/// - Unknown names → label "Unknown perk" + hash tracked for footer.
List<CatalogPerkColumn> buildCatalogPerkColumns({
  List<Map<String, Object?>>? socketPlugs,
  List<Map<String, Object?>>? definitionSocketPlugs,
  List<ResolvedPlugCard> plugCards = const [],
  Map<int, String> plugNameByHash = const {},
  Map<int, String> plugIconByHash = const {},
  Map<int, bool> plugEnhancedByHash = const {},
  bool showCanRoll = false,
  bool showCraft = false,
  List<CatalogPerkColumn> craftColumns = const [],
}) {
  final out = <CatalogPerkColumn>[];

  // Prefer instance sockets; fall back to definition (unowned / missing capture).
  // Do not pre-merge definition into instance reusables — ② vs ③ must stay distinct.
  List<Map<String, Object?>>? effectiveSockets;
  var usingDefinitionOnly = false;
  if (socketPlugs != null && socketPlugs.isNotEmpty) {
    effectiveSockets = socketPlugs;
  } else if (definitionSocketPlugs != null &&
      definitionSocketPlugs.isNotEmpty) {
    effectiveSockets = definitionSocketPlugs;
    usingDefinitionOnly = true;
  }

  // Definition pool hashes by non-meta column order (for owned ③ expansion).
  final defPoolByNonMetaIndex = <int, Set<int>>{};
  if (!usingDefinitionOnly &&
      showCanRoll &&
      definitionSocketPlugs != null &&
      definitionSocketPlugs.isNotEmpty) {
    var defIdx = 0;
    for (final def in definitionSocketPlugs) {
      final kind = (def['columnKind'] as String?)?.toLowerCase() ?? '';
      if (_isMetaColumnKind(kind)) continue;
      defPoolByNonMetaIndex[defIdx++] = _hashesFromSocketMap(def);
    }
  }

  if (effectiveSockets != null && effectiveSockets.isNotEmpty) {
    var nonMetaIdx = 0;
    for (final raw in effectiveSockets) {
      final kind = raw['columnKind'] as String?;
      final kindLower = kind?.toLowerCase() ?? '';
      final label = (raw['columnLabel'] as String?)?.trim();
      final equipped = _parseHash(raw['equippedPlugHash']);
      final instanceReusable = _parseHashList(raw['reusablePlugHashes']);

      final cells = <CatalogPerkCell>[];
      var colCanBeEnhanced = false;

      void addCell(int h, {required bool selected, required bool pool}) {
        if (h == 0) return;
        if (cells.any((c) => c.hash == h)) return;
        final name = plugNameByHash[h] ?? _cardName(plugCards, h);
        final unknown = _isUnknownPerkName(name, h);
        final rawDisplay = unknown ? 'Unknown perk' : (name ?? 'Unknown perk');
        final looksEnh = !unknown &&
            (plugEnhancedByHash[h] == true || _looksEnhanced(rawDisplay));

        // ③ / unowned pool: no E chrome; one cell per perk identity.
        if (pool || usingDefinitionOnly) {
          if (looksEnh) colCanBeEnhanced = true;
          final identity = _perkIdentityKey(rawDisplay);
          final existingIdx = cells.indexWhere(
            (c) => _perkIdentityKey(c.displayName) == identity,
          );
          if (existingIdx >= 0) {
            // Already have this family (①/② or earlier pool). Note only.
            if (looksEnh || _looksEnhanced(cells[existingIdx].displayName)) {
              colCanBeEnhanced = true;
            }
            // Prefer base display name on pool-only cells when both present.
            final prev = cells[existingIdx];
            if (prev.fromCanRollPool &&
                _looksEnhanced(prev.displayName) &&
                !looksEnh) {
              cells[existingIdx] = CatalogPerkCell(
                hash: h,
                displayName: rawDisplay,
                icon: plugIconByHash[h] ?? prev.icon,
                selected: false,
                fromCanRollPool: true,
                unknown: unknown,
                enhanced: false,
              );
            }
            return;
          }
          final display =
              looksEnh ? _stripEnhancedDisplay(rawDisplay) : rawDisplay;
          cells.add(
            CatalogPerkCell(
              hash: h,
              displayName: display,
              icon: plugIconByHash[h] ??
                  (unknown ? null : _frameIconFallback(display)),
              selected: false,
              fromCanRollPool: true,
              unknown: unknown,
              enhanced: false,
            ),
          );
          return;
        }

        // ① / ② instance plugs — gold/E when this copy’s plug is enhanced.
        cells.add(
          CatalogPerkCell(
            hash: h,
            displayName: rawDisplay,
            icon: plugIconByHash[h] ??
                (unknown ? null : _frameIconFallback(rawDisplay)),
            selected: selected,
            fromCanRollPool: false,
            unknown: unknown,
            enhanced: looksEnh,
          ),
        );
      }

      if (usingDefinitionOnly) {
        // ③ Possible rolls only: full definition pool, no owned selected highlight.
        final pool = <int>{
          if (equipped != null && equipped != 0) equipped,
          ...instanceReusable,
        };
        for (final h in pool) {
          addCell(h, selected: false, pool: true);
        }
      } else {
        // ① Selected on this copy.
        if (equipped != null) addCell(equipped, selected: true, pool: false);
        // ② Unselected instance plugs (always for owned).
        for (final h in instanceReusable) {
          if (h != equipped) addCell(h, selected: false, pool: false);
        }
        // ③ Definition possible rolls when Possible rolls toggle is ON.
        if (showCanRoll && !_isMetaColumnKind(kindLower)) {
          final defPool = defPoolByNonMetaIndex[nonMetaIdx] ?? const <int>{};
          for (final h in defPool) {
            addCell(h, selected: false, pool: true);
          }
          nonMetaIdx++;
        } else if (!_isMetaColumnKind(kindLower)) {
          nonMetaIdx++;
        }
      }

      // Origin (and any column) with no plugs is omitted — never invent Origin.
      if (cells.isEmpty) continue;
      final colLabel = (label != null && label.isNotEmpty)
          ? label
          : (kind != null && kind.isNotEmpty)
              ? kind
              : 'Plug';
      out.add(
        CatalogPerkColumn(
          label: colLabel,
          kind: kind,
          cells: cells,
          canBeEnhanced: colCanBeEnhanced,
        ),
      );
    }
  } else if (plugCards.isNotEmpty) {
    // Selected-only flat cards when no socket structure (owned instance path).
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
                enhanced: plugEnhancedByHash[c.hash] == true ||
                    _looksEnhanced(c.displayName),
              ),
          ],
        ),
      );
    }
  }

  // Craft: same column/cell format as ③ (dashed pool, no E cells); note only.
  if (showCraft && craftColumns.isNotEmpty) {
    for (final craftCol in craftColumns) {
      final craftCells = <CatalogPerkCell>[];
      var craftCanEnhance = craftCol.canBeEnhanced;
      for (final cell in craftCol.cells) {
        final looksEnh =
            cell.enhanced || _looksEnhanced(cell.displayName);
        if (looksEnh) craftCanEnhance = true;
        final identity = _perkIdentityKey(cell.displayName);
        if (craftCells.any((c) => _perkIdentityKey(c.displayName) == identity)) {
          continue;
        }
        craftCells.add(
          CatalogPerkCell(
            hash: cell.hash,
            displayName: looksEnh
                ? _stripEnhancedDisplay(cell.displayName)
                : cell.displayName,
            icon: cell.icon,
            selected: false,
            fromCraftPool: true,
            unknown: cell.unknown,
            enhanced: false,
          ),
        );
      }

      final existing = out.indexWhere(
        (c) =>
            c.label == craftCol.label ||
            (c.kind != null && c.kind == craftCol.kind),
      );
      if (existing >= 0) {
        final merged = [...out[existing].cells];
        var mergedCan = out[existing].canBeEnhanced || craftCanEnhance;
        for (final cell in craftCells) {
          final identity = _perkIdentityKey(cell.displayName);
          if (merged.any((m) => m.hash == cell.hash)) continue;
          if (merged.any((m) => _perkIdentityKey(m.displayName) == identity)) {
            mergedCan = true;
            continue;
          }
          merged.add(cell);
        }
        out[existing] = CatalogPerkColumn(
          label: out[existing].label,
          kind: out[existing].kind,
          cells: merged,
          canBeEnhanced: mergedCan,
        );
      } else {
        out.add(
          CatalogPerkColumn(
            label: craftCol.label,
            kind: craftCol.kind,
            cells: craftCells,
            canBeEnhanced: craftCanEnhance,
          ),
        );
      }
    }
  }

  return List.unmodifiable(out);
}

/// True when any column reports pool/craft can-be-enhanced (note-only path).
bool catalogColumnsCanBeEnhanced(List<CatalogPerkColumn> columns) =>
    columns.any((c) => c.canBeEnhanced);

bool _isMetaColumnKind(String kindLower) {
  return kindLower == 'intrinsic' ||
      kindLower == 'masterwork' ||
      kindLower == 'catalyst' ||
      kindLower == 'origin';
}

int? _parseHash(Object? raw) {
  if (raw is int) return raw == 0 ? null : raw;
  if (raw is num) {
    final v = raw.toInt();
    return v == 0 ? null : v;
  }
  return int.tryParse('$raw');
}

List<int> _parseHashList(Object? raw) {
  final out = <int>[];
  if (raw is! List) return out;
  for (final e in raw) {
    final h = _parseHash(e);
    if (h != null) out.add(h);
  }
  return out;
}

Set<int> _hashesFromSocketMap(Map<String, Object?> raw) {
  final out = <int>{};
  final equipped = _parseHash(raw['equippedPlugHash']);
  if (equipped != null) out.add(equipped);
  out.addAll(_parseHashList(raw['reusablePlugHashes']));
  return out;
}

/// Name-heuristic enhanced detection when plug category is unavailable.
bool _looksEnhanced(String? name) {
  if (name == null || name.isEmpty) return false;
  return RegExp(r'enhanced', caseSensitive: false).hasMatch(name);
}

/// Family key for base ↔ enhanced collapse (pool / unowned / craft only).
String _perkIdentityKey(String name) {
  return _stripEnhancedDisplay(name)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Strip common Enhanced prefixes/suffixes for identity collapse display.
String _stripEnhancedDisplay(String name) {
  var s = name.trim();
  s = s.replaceAll(RegExp(r'\s*\(enhanced\)\s*$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\s+enhanced\s*$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'^enhanced\s+', caseSensitive: false), '');
  return s.trim().isEmpty ? name.trim() : s.trim();
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

/// Possible-rolls and possible-crafted toggles (both OFF by default at host).
///
/// Finder keys stay stable (`catalog_toggle_can_roll` / `catalog_toggle_craft`).
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
            'Possible rolls',
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

/// Equal-width perk columns — no horizontal scroll at [kCatalogWeaponsDetailWidth].
///
/// Icon-first cells with ellipsis captions; compress under multi-column ③ pools.
/// Headers: ellipsis + Tooltip + Semantics (no pane widen / no H-scroll).
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

    // Equal-width Expanded columns; never SingleChildScrollView Axis.horizontal.
    return Row(
      key: const Key('catalog_perk_grid'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == columns.length - 1 ? 0 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PerkColumnHeader(
                    key: Key('perk_column_header_$i'),
                    label: columns[i].label,
                  ),
                  const SizedBox(height: 3),
                  for (final cell in columns[i].cells)
                    _PerkCellTile(cell: cell),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// ③ ON density: ellipsis + Tooltip + Semantics; full name in tooltip.
class _PerkColumnHeader extends StatelessWidget {
  const _PerkColumnHeader({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final upper = label.toUpperCase();
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        header: true,
        child: Text(
          upper,
          style: neonMono(
            color: palette.muted,
            fontSize: 8,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Soft “Can be enhanced” note for ③ / unowned / craft pools (no E cells).
class CatalogEnhanceNote extends StatelessWidget {
  const CatalogEnhanceNote({
    super.key,
    this.contextLabel = 'Possible rolls',
  });

  /// Short context for the note (e.g. "Possible rolls", "Definition pool").
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Padding(
      key: const Key('catalog_enhance_note'),
      padding: const EdgeInsets.only(bottom: kSpace8),
      child: Semantics(
        label: 'Can be enhanced. $contextLabel perks that support Enhanced '
            'show once; no second cell.',
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Can be enhanced',
                style: neonMono(
                  color: _kEnhancedGold,
                  fontSize: 10,
                ),
              ),
              TextSpan(
                text: ' — $contextLabel perks that support Enhanced show once '
                    '(no second cell).',
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold enhanced accent (game-language legendary enhance chrome).
const Color _kEnhancedGold = Color(0xFFF5C542);

class _PerkCellTile extends StatelessWidget {
  const _PerkCellTile({required this.cell});

  final CatalogPerkCell cell;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final selected = cell.selected;
    final pool = cell.fromCanRollPool || cell.fromCraftPool;
    final enhanced = cell.enhanced;
    final border = enhanced
        ? _kEnhancedGold.withValues(alpha: 0.85)
        : selected
            ? palette.accent.withValues(alpha: 0.55)
            : pool
                ? palette.line.withValues(alpha: 0.55)
                : palette.line.withValues(alpha: 0.7);
    final bg = selected
        ? palette.accent.withValues(alpha: 0.12)
        : palette.surfaceRaised.withValues(alpha: 0.5);
    final iconPath = cell.icon;
    final accent = enhanced
        ? _kEnhancedGold
        : selected
            ? palette.accent
            : palette.muted;
    final tip = StringBuffer(cell.displayName);
    if (selected) {
      tip.write(' · ① on this copy');
    } else if (cell.isInstanceUnselected) {
      tip.write(' · ② unselected (instance)');
    } else if (pool) {
      tip.write(' · ③ possible roll');
    }
    if (enhanced) tip.write(' · Enhanced');

    return Tooltip(
      message: tip.toString(),
      child: Container(
        key: Key('perk_cell_${cell.hash}'),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: kFlapRuleThickness),
          borderRadius: BorderRadius.circular(kRadiusMax),
          boxShadow: enhanced
              ? [
                  BoxShadow(
                    color: _kEnhancedGold.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconPath != null && iconPath.isNotEmpty)
                  BungieContentIcon(
                    key: selected ? Key('perk_selected_${cell.hash}') : null,
                    pathOrUrl: iconPath,
                    size: 28,
                    // Parent Tooltip names the cell — avoid AX thrash on image load.
                    fallback: _PerkIconFallback(
                      label: cell.displayName,
                      color: accent,
                      size: 28,
                    ),
                  )
                else
                  _PerkIconFallback(
                    key: selected ? Key('perk_selected_${cell.hash}') : null,
                    label: cell.displayName,
                    color: accent,
                    size: 28,
                  ),
                const SizedBox(height: 1),
                Text(
                  // Caption under icon — never bare-hash primary (DBR-UI-006).
                  cell.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(
                    color: enhanced
                        ? _kEnhancedGold
                        : selected
                            ? palette.foreground
                            : pool
                                ? palette.muted
                                : palette.foreground,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            if (enhanced)
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  key: Key('perk_enhanced_mark_${cell.hash}'),
                  'E',
                  style: neonMono(
                    color: _kEnhancedGold,
                    fontSize: 8,
                  ),
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
    this.size = 28,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Text(
            mark,
            style: neonMono(color: color, fontSize: size * 0.4),
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
                color: const Color(kRarityExotic),
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
        const FilledButton.tonal(
          key: Key('catalog_stub_set'),
          onPressed: null,
          child: Text('Set'),
        ),
        const FilledButton.tonal(
          key: Key('catalog_stub_synergy'),
          onPressed: null,
          child: Text('Synergy'),
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
    this.plugEnhancedByHash = const {},
    this.intrinsicName,
    this.intrinsicDescription,
    this.catalystName,
    this.catalystDescription,
    this.catalystComplete,
    this.headerTrailing,
    this.showOwnedMetaMark = true,
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

  /// Host-supplied enhanced flags (optional; name heuristic also applies).
  final Map<int, bool> plugEnhancedByHash;
  final String? intrinsicName;
  final String? intrinsicDescription;
  final String? catalystName;
  final String? catalystDescription;
  final bool? catalystComplete;
  final Widget? headerTrailing;

  /// When false, meta strip omits ×N (signed-out honesty).
  final bool showOwnedMetaMark;

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
    // Instance sockets drive ①+②. Unowned → definition ③ possible rolls.
    final columns = buildCatalogPerkColumns(
      socketPlugs: inst?.socketPlugs,
      definitionSocketPlugs:
          definitionSocketPlugs.isEmpty ? null : definitionSocketPlugs,
      plugCards: inst?.plugCards ?? const [],
      plugNameByHash: plugNameByHash,
      plugIconByHash: plugIconByHash,
      plugEnhancedByHash: plugEnhancedByHash,
      showCanRoll: showCanRoll,
      showCraft: showCraft,
      craftColumns: craftColumns,
    );
    final unknowns = unknownPerkHashes(columns);
    final perkSectionLabel = hasOwnedCopy ? 'PERKS' : 'POSSIBLE ROLLS';
    final showEnhanceNote = catalogColumnsCanBeEnhanced(columns);
    final enhanceContext = !hasOwnedCopy
        ? 'Definition pool'
        : showCraft && showCanRoll
            ? 'Possible rolls / crafted'
            : showCraft
                ? 'Possible crafted'
                : 'Possible rolls';

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonDetailHeader(
            title: item.name,
            kicker: item.isExotic ? 'Weapon · Exotic' : 'Weapon',
            kickerKey: const Key('detail_kind_label'),
            // Icon-only meta strip replaces text subtitle + KINETIC/OWNED pills.
            subtitle: null,
            pills: const [],
            actions: headerTrailing,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace12, 0, kSpace12, kSpace8),
            child: CatalogWeaponMetaStrip(
              itemTypeName: item.itemTypeName,
              frame: item.frame,
              element: item.element,
              slot: item.slot,
              ammo: item.ammo,
              owned: item.owned,
              ownedCount: item.ownedCount,
              showOwnedMark: showOwnedMetaMark,
            ),
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
          // Possible-rolls / craft toggles only for owned copies.
          // Unowned always shows ③ possible rolls below (no toggle).
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
                if (showEnhanceNote)
                  CatalogEnhanceNote(contextLabel: enhanceContext),
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
