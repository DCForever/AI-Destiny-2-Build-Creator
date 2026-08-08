import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'catalog_roll_targets.dart';
import 'entity_info_hotspot.dart';

// ---------------------------------------------------------------------------
// Presentation models (host supplies data; widgets never invent pools)
// ---------------------------------------------------------------------------

/// One plug cell in the weapons perk grid.
///
/// Tiers (owned): selected · unselected instance · possible-roll pool.
/// Enhanced is orthogonal to any tier (gold border only; never a label).
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

  /// Selected on this owned instance.
  final bool selected;

  /// Definition possible-roll pool (only when Possible rolls is ON for owned).
  final bool fromCanRollPool;
  final bool fromCraftPool;
  final bool unknown;

  /// Enhanced plug — gold border on instance cells only (never pool).
  final bool enhanced;

  /// Unselected instance plug (owned): not selected and not pool/craft.
  bool get isInstanceUnselected =>
      !selected && !fromCanRollPool && !fromCraftPool;

  /// True when a Bungie icon path is present (caption may still be forced).
  bool get hasIcon => icon != null && icon!.isNotEmpty;

  /// Caption / tooltip name without "Enhanced" wording.
  String get captionName => stripEnhancedPerkDisplay(displayName);
}

/// One column in the weapons perk grid.
class CatalogPerkColumn {
  const CatalogPerkColumn({
    required this.label,
    required this.cells,
    this.kind,
    this.columnKey,
    this.canBeEnhanced = false,
  });

  final String label;
  final String? kind;

  /// Stable key for roll-target preferred/avoid (defaults to [label]).
  final String? columnKey;
  final List<CatalogPerkCell> cells;

  /// Pool/unowned/craft supports Enhanced variants — note only, no E cells.
  final bool canBeEnhanced;

  /// Key used by roll-target editor / score wash.
  String get rollColumnKey =>
      (columnKey != null && columnKey!.isNotEmpty) ? columnKey! : label;
}

/// Build columns from instance sockets and/or definition perk columns.
///
/// - **Owned instance:** selected + instance reusables always; definition
///   possible rolls only when [showCanRoll] (never invent plugs).
/// - **Unowned / definition-only:** full **possible rolls** (curated ∪ randomized
///   from [definitionSocketPlugs]) — always shown as pool cells (no fake selected
///   roll). Does not invent plugs.
/// - **Origin:** only when a column has origin kind/data with plugs; never invent.
/// - Craft pool only when [showCraft] and craft cells provided (never invent).
/// - **Enhanced gold only on instance plugs** when [plugEnhancedByHash]
///   or name heuristic says so. Pool / unowned / craft = one cell per identity +
///   [CatalogPerkColumn.canBeEnhanced] note (never base+enhanced pair).
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
  /// Exotic / fixed perks: no can-roll expansion; definition plugs are not
  /// "possible rolls" pool chrome (BUG-20260807-002).
  bool fixedPerks = false,
}) {
  final out = <CatalogPerkColumn>[];
  final allowCanRoll = showCanRoll && !fixedPerks;

  // Prefer instance sockets; fall back to definition (unowned / missing capture).
  // Do not pre-merge definition into instance reusables — instance vs pool must stay distinct.
  List<Map<String, Object?>>? effectiveSockets;
  var usingDefinitionOnly = false;
  if (socketPlugs != null && socketPlugs.isNotEmpty) {
    effectiveSockets = socketPlugs;
  } else if (definitionSocketPlugs != null &&
      definitionSocketPlugs.isNotEmpty) {
    effectiveSockets = definitionSocketPlugs;
    usingDefinitionOnly = true;
  }

  // Definition pool hashes by non-meta column order (for owned pool expansion).
  final defPoolByNonMetaIndex = <int, Set<int>>{};
  if (!usingDefinitionOnly &&
      allowCanRoll &&
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
    var socketIdx = 0;
    for (final raw in effectiveSockets) {
      final kind = raw['columnKind'] as String?;
      final kindLower = kind?.toLowerCase() ?? '';
      final label = (raw['columnLabel'] as String?)?.trim();
      final colKey = catalogRollColumnKey(raw, index: socketIdx);
      socketIdx++;
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
            (plugEnhancedByHash[h] == true || looksEnhancedPerkName(rawDisplay));

        // Pool / unowned definition: one cell per perk identity.
        // Fixed perks (exotic): treat as solid cells, not dashed can-roll pool.
        if (pool || usingDefinitionOnly) {
          if (looksEnh) colCanBeEnhanced = true;
          final asPool = !fixedPerks;
          final identity = perkIdentityKey(rawDisplay);
          final existingIdx = cells.indexWhere(
            (c) => perkIdentityKey(c.displayName) == identity,
          );
          if (existingIdx >= 0) {
            if (looksEnh || looksEnhancedPerkName(cells[existingIdx].displayName)) {
              colCanBeEnhanced = true;
            }
            final prev = cells[existingIdx];
            if (prev.fromCanRollPool &&
                looksEnhancedPerkName(prev.displayName) &&
                !looksEnh) {
              cells[existingIdx] = CatalogPerkCell(
                hash: h,
                displayName: rawDisplay,
                icon: plugIconByHash[h] ?? prev.icon,
                selected: fixedPerks && selected,
                fromCanRollPool: asPool,
                unknown: unknown,
                enhanced: false,
              );
            }
            return;
          }
          final display =
              looksEnh ? stripEnhancedPerkDisplay(rawDisplay) : rawDisplay;
          cells.add(
            CatalogPerkCell(
              hash: h,
              displayName: display,
              icon: plugIconByHash[h] ??
                  (unknown ? null : _frameIconFallback(display)),
              selected: fixedPerks && selected,
              fromCanRollPool: asPool,
              unknown: unknown,
              enhanced: false,
            ),
          );
          return;
        }

        // Instance plugs — gold border when this copy’s plug is enhanced.
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
        final pool = <int>{
          if (equipped != null && equipped != 0) equipped,
          ...instanceReusable,
        };
        // Fixed exotic: first equipped as selected; rest unselected instance-like.
        if (fixedPerks) {
          var first = true;
          for (final h in pool) {
            addCell(h, selected: first && equipped == h, pool: true);
            if (h == equipped) first = false;
          }
        } else {
          for (final h in pool) {
            addCell(h, selected: false, pool: true);
          }
        }
      } else {
        if (equipped != null) addCell(equipped, selected: true, pool: false);
        for (final h in instanceReusable) {
          if (h != equipped) addCell(h, selected: false, pool: false);
        }
        if (allowCanRoll && !_isMetaColumnKind(kindLower)) {
          final defPool = defPoolByNonMetaIndex[nonMetaIdx] ?? const <int>{};
          for (final h in defPool) {
            addCell(h, selected: false, pool: true);
          }
          nonMetaIdx++;
        } else if (!_isMetaColumnKind(kindLower)) {
          nonMetaIdx++;
        }
      }

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
          columnKey: colKey,
          cells: cells,
          canBeEnhanced: colCanBeEnhanced,
        ),
      );
    }
  } else if (plugCards.isNotEmpty) {
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
          columnKey: e.key,
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
                    looksEnhancedPerkName(c.displayName),
              ),
          ],
        ),
      );
    }
  }

  if (showCraft && craftColumns.isNotEmpty) {
    for (final craftCol in craftColumns) {
      final craftCells = <CatalogPerkCell>[];
      var craftCanEnhance = craftCol.canBeEnhanced;
      for (final cell in craftCol.cells) {
        final looksEnh =
            cell.enhanced || looksEnhancedPerkName(cell.displayName);
        if (looksEnh) craftCanEnhance = true;
        final identity = perkIdentityKey(cell.displayName);
        if (craftCells.any((c) => perkIdentityKey(c.displayName) == identity)) {
          continue;
        }
        craftCells.add(
          CatalogPerkCell(
            hash: cell.hash,
            displayName: looksEnh
                ? stripEnhancedPerkDisplay(cell.displayName)
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
          final identity = perkIdentityKey(cell.displayName);
          if (merged.any((m) => m.hash == cell.hash)) continue;
          if (merged.any((m) => perkIdentityKey(m.displayName) == identity)) {
            mergedCan = true;
            continue;
          }
          merged.add(cell);
        }
        out[existing] = CatalogPerkColumn(
          label: out[existing].label,
          kind: out[existing].kind,
          columnKey: out[existing].columnKey,
          cells: merged,
          canBeEnhanced: mergedCan,
        );
      } else {
        out.add(
          CatalogPerkColumn(
            label: craftCol.label,
            kind: craftCol.kind,
            columnKey: craftCol.columnKey ?? craftCol.label,
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

List<int> unknownPerkHashes(List<CatalogPerkColumn> columns) {
  final out = <int>[];
  for (final col in columns) {
    for (final cell in col.cells) {
      if (cell.unknown && !out.contains(cell.hash)) out.add(cell.hash);
    }
  }
  return out;
}

/// Name-heuristic enhanced detection when plug category is unavailable.
bool looksEnhancedPerkName(String? name) {
  if (name == null || name.isEmpty) return false;
  return RegExp(r'enhanced', caseSensitive: false).hasMatch(name);
}

/// Family key for base ↔ enhanced collapse (pool / unowned / craft only).
String perkIdentityKey(String name) {
  return stripEnhancedPerkDisplay(name)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Strip common Enhanced prefixes/suffixes for identity + caption display.
String stripEnhancedPerkDisplay(String name) {
  var s = name.trim();
  s = s.replaceAll(RegExp(r'\s*\(enhanced\)\s*$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\s+enhanced\s*$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'^enhanced\s+', caseSensitive: false), '');
  return s.trim().isEmpty ? name.trim() : s.trim();
}

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

String? _cardName(List<ResolvedPlugCard> cards, int hash) {
  for (final c in cards) {
    if (c.hash == hash && c.displayName.isNotEmpty) return c.displayName;
  }
  return null;
}

bool _isUnknownPerkName(String? name, int hash) {
  if (name == null || name.isEmpty) return true;
  if (name == '#$hash') return true;
  if (name.endsWith('(#$hash)')) return true;
  if (name.startsWith('#') && name.substring(1) == '$hash') return true;
  return false;
}

String? _frameIconFallback(String? displayName) {
  if (displayName == null || displayName.isEmpty) return null;
  return officialWeaponFrameVisual(displayName)?.iconPath;
}

// ---------------------------------------------------------------------------
// Grid chrome
// ---------------------------------------------------------------------------

/// Perk icon size inside each cell.
const double kCatalogPerkIconSize = 32;

/// Fixed square cell size — slightly larger than [kCatalogPerkIconSize].
const double kCatalogPerkCellSize = 40;

/// Legacy alias (cell is a fixed square).
const double kCatalogPerkCellMinHeight = kCatalogPerkCellSize;

/// Gold enhanced accent (border/glow only — never a text label).
const Color kCatalogPerkEnhancedGold = Color(0xFFF5C542);

/// Equal-width perk columns — no horizontal scroll at detail width.
///
/// Icon-first fixed tiles. Captions: auto when icon missing / unknown (option B);
/// force on/off via [showLabels]. Headers ellipsis + tooltip.
/// Chrome: selected fill, accent corner mark for unselected, dashed pool,
/// gold border for enhanced (no E glyph, no Enhanced caption text).
///
/// 003 roll targets: view diagonal wash (preferred green / avoid red) behind
/// icon; edit mode W/A badges only (no wash); cycle instance + can-roll cells.
class CatalogPerkGrid extends StatelessWidget {
  const CatalogPerkGrid({
    super.key,
    required this.columns,
    this.showLabels,
    this.preferredByColumn = const {},
    this.avoidByColumn = const {},
    this.editingRollTarget = false,
    this.onCycleRollPlug,
    this.fixedPerks = false,
    this.entityInfoByHash = const {},
    this.enableEntityInfo = true,
  });

  final List<CatalogPerkColumn> columns;

  /// Caption policy:
  /// - `null` (default): **auto** — show under tiles with no icon or [CatalogPerkCell.unknown]
  /// - `true`: always show captions
  /// - `false`: never show captions
  final bool? showLabels;

  /// Active (view) or draft (edit) preferred plugs by columnKey.
  final Map<String, Set<int>> preferredByColumn;

  /// Active (view) or draft (edit) avoid plugs by columnKey.
  final Map<String, Set<int>> avoidByColumn;

  /// When true: W/A badges, no diagonal wash; instance + pool cells cycle.
  final bool editingRollTarget;

  /// Called with columnKey + plug hash when a cycleable cell is tapped in edit.
  final void Function(String columnKey, int plugHash)? onCycleRollPlug;

  /// Exotic / fixed-perk weapons: no Selected / On this copy / Possible rolls
  /// legend (BUG-20260807-003).
  final bool fixedPerks;

  /// Host-resolved entity info by plug hash (DART-071 maps → chrome DTO).
  /// Missing hash still opens info with cell name + honest empty description.
  final Map<int, EntityInfoData> entityInfoByHash;

  /// When false, cells keep residual chrome without info hotspot (tests).
  final bool enableEntityInfo;

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

    final hasInstanceTiers = columns.any(
      (c) => c.cells.any((x) => x.selected || x.isInstanceUnselected),
    );
    final hasPool = columns.any(
      (c) => c.cells.any((x) => x.fromCanRollPool || x.fromCraftPool),
    );
    final hasCraft = columns.any(
      (c) => c.cells.any((x) => x.fromCraftPool),
    );
    final hasTargetMarks = preferredByColumn.isNotEmpty ||
        avoidByColumn.isNotEmpty ||
        editingRollTarget;

    // View mode: one AX node for the whole grid. Per-cell Semantics + tooltip
    // label thrash (preferred/avoid wash updates on every active-target switch)
    // was breaking Windows accessibility_bridge ("will not be in the tree").
    // Edit mode: let cycleable cell buttons own a11y.
    final body = Column(
      key: const Key('catalog_perk_grid_shell'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed perks (exotics): omit Selected / On this copy / Possible rolls.
        if (!fixedPerks && (hasInstanceTiers || hasPool))
          _PerkTierLegend(
            owned: hasInstanceTiers,
            showPossible: hasPool && !hasCraft,
            craftMode: hasCraft && !hasInstanceTiers,
          ),
        if (editingRollTarget)
          Padding(
            key: const Key('catalog_roll_edit_legend'),
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _targetLegendSwatch(palette, 'Want', want: true),
                _targetLegendSwatch(palette, 'Avoid', avoid: true),
                _targetLegendSwatch(palette, 'Off', off: true),
              ],
            ),
          )
        else if (hasTargetMarks)
          Padding(
            key: const Key('catalog_roll_view_legend'),
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                if (preferredByColumn.isNotEmpty)
                  _targetLegendSwatch(palette, 'Preferred', want: true),
                if (avoidByColumn.isNotEmpty)
                  _targetLegendSwatch(palette, 'Avoid', avoid: true),
              ],
            ),
          ),
        Row(
          key: Key(
            editingRollTarget
                ? 'catalog_perk_grid_editing'
                : 'catalog_perk_grid',
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i == columns.length - 1 ? 0 : 4),
                  child: _PerkColumnBody(
                    columnIndex: i,
                    column: columns[i],
                    showLabels: showLabels,
                    preferredHashes:
                        preferredByColumn[columns[i].rollColumnKey] ??
                            const <int>{},
                    avoidHashes:
                        avoidByColumn[columns[i].rollColumnKey] ?? const <int>{},
                    editingRollTarget: editingRollTarget,
                    onCycleRollPlug: onCycleRollPlug == null
                        ? null
                        : (hash) => onCycleRollPlug!(
                              columns[i].rollColumnKey,
                              hash,
                            ),
                    entityInfoByHash: entityInfoByHash,
                    enableEntityInfo: enableEntityInfo,
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return Semantics(
      label: editingRollTarget ? 'Edit roll target perks' : 'Weapon perks',
      // View: collapse N cells under one node. Edit: publish cycle buttons.
      excludeSemantics: !editingRollTarget,
      child: body,
    );
  }

  Widget _targetLegendSwatch(
    FlapPalette palette,
    String label, {
    bool want = false,
    bool avoid = false,
    bool off = false,
  }) {
    final Color border;
    final Color fill;
    if (want) {
      border = palette.success.withValues(alpha: 0.55);
      fill = palette.success.withValues(alpha: 0.25);
    } else if (avoid) {
      border = palette.danger.withValues(alpha: 0.5);
      fill = palette.danger.withValues(alpha: 0.2);
    } else {
      border = palette.line.withValues(alpha: 0.7);
      fill = Colors.transparent;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(
              color: border,
              width: kFlapRuleThickness,
              style: off ? BorderStyle.none : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(1),
          ),
          foregroundDecoration: off
              ? _DashedBorderDecoration(
                  color: border,
                  strokeWidth: kFlapRuleThickness,
                  radius: 1,
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: neonMono(color: palette.muted, fontSize: 9)),
      ],
    );
  }
}

/// Compact legend — swatch + plain words (no ①②③ digits, no Enhanced text).
class _PerkTierLegend extends StatelessWidget {
  const _PerkTierLegend({
    required this.owned,
    required this.showPossible,
    required this.craftMode,
  });

  final bool owned;
  final bool showPossible;
  final bool craftMode;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final swatches = <Widget>[];
    if (craftMode) {
      swatches.add(_legendSwatch(palette, 'Possible crafted', dashed: true));
    } else if (owned) {
      swatches.add(_legendSwatch(palette, 'Selected', solid: true));
      swatches.add(_legendSwatch(palette, 'On this copy'));
      if (showPossible) {
        swatches.add(_legendSwatch(palette, 'Possible rolls', dashed: true));
      }
    } else {
      swatches.add(_legendSwatch(palette, 'Possible rolls', dashed: true));
    }

    return Padding(
      key: const Key('catalog_perk_legend'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        label: 'Perk legend',
        excludeSemantics: true,
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          children: swatches,
        ),
      ),
    );
  }

  Widget _legendSwatch(
    FlapPalette palette,
    String label, {
    bool solid = false,
    bool dashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: solid
                ? palette.accent.withValues(alpha: 0.55)
                : Colors.transparent,
            border: Border.all(
              color: dashed
                  ? palette.line.withValues(alpha: 0.7)
                  : solid
                      ? palette.accent.withValues(alpha: 0.9)
                      : palette.lineStrong,
              width: kFlapRuleThickness,
              style: dashed ? BorderStyle.none : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(1),
          ),
          foregroundDecoration: dashed
              ? _DashedBorderDecoration(
                  color: palette.line.withValues(alpha: 0.7),
                  strokeWidth: kFlapRuleThickness,
                  radius: 1,
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: neonMono(color: palette.muted, fontSize: 9),
        ),
      ],
    );
  }
}

class _PerkColumnBody extends StatelessWidget {
  const _PerkColumnBody({
    required this.columnIndex,
    required this.column,
    required this.showLabels,
    this.preferredHashes = const {},
    this.avoidHashes = const {},
    this.editingRollTarget = false,
    this.onCycleRollPlug,
    this.entityInfoByHash = const {},
    this.enableEntityInfo = true,
  });

  final int columnIndex;
  final CatalogPerkColumn column;
  final bool? showLabels;
  final Set<int> preferredHashes;
  final Set<int> avoidHashes;
  final bool editingRollTarget;
  final ValueChanged<int>? onCycleRollPlug;
  final Map<int, EntityInfoData> entityInfoByHash;
  final bool enableEntityInfo;

  List<String> _tierMeta(CatalogPerkCell cell, CatalogRollPlugTargetMode mode) {
    final meta = <String>[];
    if (cell.selected) {
      meta.add('① on this copy');
    } else if (cell.isInstanceUnselected) {
      meta.add('② unselected (this instance)');
    } else if (cell.fromCraftPool) {
      meta.add('③ possible crafted (definition)');
    } else if (cell.fromCanRollPool) {
      meta.add('③ possible roll (definition)');
    }
    if (cell.enhanced &&
        (cell.selected || cell.isInstanceUnselected) &&
        !cell.fromCanRollPool &&
        !cell.fromCraftPool) {
      meta.add('Enhanced (this copy)');
    }
    if (editingRollTarget) {
      switch (mode) {
        case CatalogRollPlugTargetMode.want:
          meta.add('roll-target want');
        case CatalogRollPlugTargetMode.avoid:
          meta.add('roll-target avoid');
        case CatalogRollPlugTargetMode.off:
          break;
      }
    } else {
      if (mode == CatalogRollPlugTargetMode.want) meta.add('preferred');
      if (mode == CatalogRollPlugTargetMode.avoid) meta.add('avoid target');
    }
    return meta;
  }

  @override
  Widget build(BuildContext context) {
    final hasOverlap = preferredHashes.intersection(avoidHashes).isNotEmpty;
    final children = <Widget>[
      _PerkColumnHeader(
        key: Key('perk_column_header_$columnIndex'),
        label: column.label,
        danger: editingRollTarget && hasOverlap,
      ),
      const SizedBox(height: 3),
    ];

    for (final cell in column.cells) {
      final mode = catalogRollPlugModeFor(
        columnKey: column.rollColumnKey,
        plugHash: cell.hash,
        preferredByColumn: {
          column.rollColumnKey: preferredHashes,
        },
        avoidByColumn: {
          column.rollColumnKey: avoidHashes,
        },
      );
      // BUG-20260807-009: cycle Want|Avoid|Off on owned instance ①/② plugs
      // and can-roll ③ pool (not pool-only). Craft pool stays non-cycle.
      final canCycle = editingRollTarget &&
          onCycleRollPlug != null &&
          !cell.fromCraftPool &&
          (cell.fromCanRollPool ||
              cell.selected ||
              cell.isInstanceUnselected);
      final info = enableEntityInfo
          ? entityInfoFromPerkCell(
              hash: cell.hash,
              displayName: cell.captionName,
              iconPath: cell.icon,
              unknown: cell.unknown,
              host: entityInfoByHash[cell.hash],
              tierMeta: _tierMeta(cell, mode),
              kind: column.kind ?? column.label,
            )
          : null;
      children.add(
        _PerkCellTile(
          cell: cell,
          showLabels: showLabels,
          targetMode: mode,
          editingRollTarget: editingRollTarget,
          overlap: editingRollTarget &&
              preferredHashes.contains(cell.hash) &&
              avoidHashes.contains(cell.hash),
          onCycle: canCycle ? () => onCycleRollPlug!(cell.hash) : null,
          entityInfo: info,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _PerkColumnHeader extends StatelessWidget {
  const _PerkColumnHeader({
    super.key,
    required this.label,
    this.danger = false,
  });

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final upper = label.toUpperCase();
    return Semantics(
      label: label,
      header: true,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Text(
          upper,
          style: neonMono(
            color: danger ? palette.danger : palette.muted,
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

/// Soft “Can be enhanced” note for pool / unowned / craft (no E cells).
class CatalogEnhanceNote extends StatelessWidget {
  const CatalogEnhanceNote({
    super.key,
    this.contextLabel = 'Possible rolls',
  });

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
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Can be enhanced',
                style: neonMono(
                  color: kCatalogPerkEnhancedGold,
                  fontSize: 10,
                ),
              ),
              TextSpan(
                text: ' — one cell per perk; no separate Enhanced tile.',
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed square perk tile: centered icon, optional caption, accent corner for
/// unselected, dashed pool, gold border when enhanced.
///
/// 003: view diagonal wash (behind icon); edit W/A badges only (no wash).
class _PerkCellTile extends StatelessWidget {
  const _PerkCellTile({
    required this.cell,
    this.showLabels,
    this.targetMode = CatalogRollPlugTargetMode.off,
    this.editingRollTarget = false,
    this.overlap = false,
    this.onCycle,
    this.entityInfo,
  });

  final CatalogPerkCell cell;
  final bool? showLabels;
  final CatalogRollPlugTargetMode targetMode;
  final bool editingRollTarget;
  final bool overlap;
  final VoidCallback? onCycle;

  /// When set, hover/long-press shows entity info; tap stays primary ([onCycle]).
  final EntityInfoData? entityInfo;

  /// Option B: caption when forced, or when no icon / unknown.
  bool get _showCaption {
    if (showLabels == true) return true;
    if (showLabels == false) return false;
    return !cell.hasIcon || cell.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final selected = cell.selected;
    final unselected = cell.isInstanceUnselected;
    final pool = cell.fromCanRollPool || cell.fromCraftPool;
    final enhanced = cell.enhanced && !pool;
    final want = targetMode == CatalogRollPlugTargetMode.want;
    final avoid = targetMode == CatalogRollPlugTargetMode.avoid;

    // Preferred/avoid chrome wins over selected cyan so ideal green stays
    // readable on equipped plugs (user report: selected ideal not visible).
    Color borderColor;
    Color bg;
    if (want) {
      borderColor = palette.success;
      bg = selected
          ? palette.success.withValues(alpha: 0.28)
          : palette.success.withValues(alpha: editingRollTarget ? 0.18 : 0.14);
    } else if (avoid) {
      borderColor = palette.danger.withValues(alpha: 0.85);
      bg = selected
          ? palette.danger.withValues(alpha: 0.2)
          : palette.danger.withValues(alpha: editingRollTarget ? 0.14 : 0.1);
    } else if (enhanced) {
      borderColor = kCatalogPerkEnhancedGold.withValues(alpha: 0.85);
      bg = selected
          ? palette.accent.withValues(alpha: 0.14)
          : pool
              ? Colors.transparent
              : palette.surfaceRaised.withValues(alpha: 0.5);
    } else {
      borderColor = selected
          ? palette.accent.withValues(alpha: 0.65)
          : pool
              ? palette.line.withValues(alpha: 0.45)
              : palette.lineStrong;
      bg = selected
          ? palette.accent.withValues(alpha: 0.14)
          : pool
              ? Colors.transparent
              : palette.surfaceRaised.withValues(alpha: 0.5);
    }

    final useSolidBorder = want || avoid;
    final useDashed = pool && !useSolidBorder;

    final iconPath = cell.icon;
    final accent = want
        ? palette.success
        : avoid
            ? palette.danger
            : selected
                ? palette.accent
                : pool
                    ? palette.muted.withValues(alpha: 0.55)
                    : palette.muted;
    // Tooltip / a11y: plain words, no Enhanced wording, no circled digits.
    final tip = StringBuffer(cell.captionName);
    if (editingRollTarget) {
      tip.write(
        want
            ? ' · want'
            : avoid
                ? ' · avoid'
                : ' · off',
      );
    } else {
      if (selected) {
        tip.write(' · selected');
      } else if (unselected) {
        tip.write(' · on this copy');
      } else if (pool) {
        tip.write(
          cell.fromCraftPool ? ' · possible crafted' : ' · possible roll',
        );
      }
      if (want) tip.write(' · preferred');
      if (avoid) tip.write(' · avoid target');
    }

    final iconOpacity = pool && !(editingRollTarget && (want || avoid))
        ? 0.45
        : 1.0;
    final icon = Opacity(
      opacity: iconOpacity,
      child: iconPath != null && iconPath.isNotEmpty
          ? BungieContentIcon(
              key: selected ? Key('perk_selected_${cell.hash}') : null,
              pathOrUrl: iconPath,
              size: kCatalogPerkIconSize,
              fallback: _PerkIconFallback(
                label: cell.captionName,
                color: accent,
                size: kCatalogPerkIconSize,
              ),
            )
          : _PerkIconFallback(
              key: selected ? Key('perk_selected_${cell.hash}') : null,
              label: cell.captionName,
              color: accent,
              size: kCatalogPerkIconSize,
            ),
    );

    // View wash only (not edit): soft diagonal LR→UL behind icon.
    final showWash = !editingRollTarget && (want || avoid);

    final box = Container(
      key: Key('perk_cell_${cell.hash}'),
      width: kCatalogPerkCellSize,
      height: kCatalogPerkCellSize,
      decoration: BoxDecoration(
        color: bg,
        border: useDashed
            ? null
            : Border.all(
                color: borderColor,
                width: want || avoid
                    ? 2.0
                    : selected || enhanced || useSolidBorder
                        ? 1.5
                        : kFlapRuleThickness,
              ),
        borderRadius: BorderRadius.circular(kRadiusMax),
        boxShadow: [
          if (want)
            BoxShadow(
              color: palette.success.withValues(alpha: selected ? 0.45 : 0.28),
              blurRadius: selected ? 8 : 5,
              spreadRadius: 0,
            ),
          if (enhanced && !want)
            BoxShadow(
              color: kCatalogPerkEnhancedGold.withValues(alpha: 0.22),
              blurRadius: 6,
            ),
          if (overlap)
            BoxShadow(
              color: palette.danger.withValues(alpha: 0.55),
              blurRadius: 0,
              spreadRadius: 1,
            ),
        ],
      ),
      foregroundDecoration: useDashed
          ? _DashedBorderDecoration(
              color: borderColor,
              strokeWidth: kFlapRuleThickness,
              radius: kRadiusMax.toDouble(),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          if (showWash)
            Positioned.fill(
              child: CustomPaint(
                key: Key(
                  want
                      ? 'perk_wash_want_${cell.hash}'
                      : 'perk_wash_avoid_${cell.hash}',
                ),
                painter: _DiagonalTargetWashPainter(
                  color: want
                      ? palette.success.withValues(
                          alpha: selected ? 0.42 : 0.32,
                        )
                      : palette.danger.withValues(
                          alpha: selected ? 0.36 : 0.28,
                        ),
                ),
              ),
            ),
          Center(child: icon),
          // Accent corner mark (② unselected) — not gold (gold = enhanced only).
          // Hidden while editing (W/A badges take the corner).
          if (unselected && !editingRollTarget)
            Positioned(
              top: 1,
              left: 1,
              child: CustomPaint(
                key: Key('perk_chevron_${cell.hash}'),
                size: const Size(7, 7),
                painter: _CornerChevronPainter(
                  color: palette.accent.withValues(alpha: 0.9),
                ),
              ),
            ),
          // Edit mode: W / A badges only (no wash).
          if (editingRollTarget)
            Positioned(
              top: 1,
              right: 1,
              child: _EditModeBadge(
                key: Key(
                  want
                      ? 'perk_badge_want_${cell.hash}'
                      : avoid
                          ? 'perk_badge_avoid_${cell.hash}'
                          : 'perk_badge_off_${cell.hash}',
                ),
                mode: targetMode,
                palette: palette,
              ),
            ),
        ],
      ),
    );

    final captionColor = editingRollTarget && want
        ? palette.success
        : editingRollTarget && avoid
            ? const Color(0xFFFFB3C0)
            : selected
                ? palette.foreground
                : pool
                    ? palette.muted.withValues(alpha: 0.65)
                    : palette.foreground;

    final body = _showCaption
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              box,
              const SizedBox(height: 2),
              SizedBox(
                width: kCatalogPerkCellSize + 12,
                child: Text(
                  key: Key('perk_label_${cell.hash}'),
                  cell.captionName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(
                    color: captionColor,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          )
        : box;

    // Single semantic owner (Windows AX): never wrap Semantics in InkWell.
    // View mode: no per-cell AX node (parent CatalogPerkGrid excludes).
    // Edit mode: one button node per cycleable pool cell only.
    final padded = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.topCenter,
        child: body,
      ),
    );

    final tipMsg = tip.toString();

    // EntityInfoHotspot: hover/focus = info; tap = primary (onCycle when edit).
    // Residual name-only Tooltip only when info chrome is off.
    Widget interactive = padded;
    if (entityInfo != null) {
      interactive = EntityInfoHotspot(
        key: Key('entity_info_hotspot_${cell.hash}'),
        data: entityInfo!,
        onPrimary: onCycle,
        child: Material(
          color: Colors.transparent,
          child: padded,
        ),
      );
    } else if (onCycle != null) {
      interactive = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCycle,
          borderRadius: BorderRadius.circular(kRadiusMax),
          child: padded,
        ),
      );
    }

    final withTip = entityInfo != null
        ? interactive
        : Tooltip(
            message: tipMsg,
            excludeFromSemantics: true,
            child: interactive,
          );

    if (onCycle == null && entityInfo == null) {
      // Parent grid ExcludeSemantics owns view a11y; avoid N× label thrash.
      return ExcludeSemantics(child: withTip);
    }

    if (onCycle == null && entityInfo != null) {
      // Info-capable view cells: still collapse under grid Semantics.
      return ExcludeSemantics(child: withTip);
    }

    return Semantics(
      key: Key('perk_cell_a11y_${cell.hash}'),
      label: tipMsg,
      button: true,
      excludeSemantics: true,
      child: withTip,
    );
  }
}

class _EditModeBadge extends StatelessWidget {
  const _EditModeBadge({
    super.key,
    required this.mode,
    required this.palette,
  });

  final CatalogRollPlugTargetMode mode;
  final FlapPalette palette;

  @override
  Widget build(BuildContext context) {
    final String mark;
    final Color fg;
    final Color bg;
    switch (mode) {
      case CatalogRollPlugTargetMode.want:
        mark = 'W';
        fg = const Color(0xFF0A1A14);
        bg = palette.success;
        break;
      case CatalogRollPlugTargetMode.avoid:
        mark = 'A';
        fg = const Color(0xFF1A0508);
        bg = palette.danger;
        break;
      case CatalogRollPlugTargetMode.off:
        mark = '·';
        fg = palette.muted.withValues(alpha: 0.7);
        bg = Colors.transparent;
        break;
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(1),
        border: mode == CatalogRollPlugTargetMode.off
            ? Border.all(
                color: palette.line,
                width: kFlapRuleThickness,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: neonMono(color: fg, fontSize: 8),
      ),
    );
  }
}

/// Soft diagonal wash LR→UL (lower-right dense → upper-left fade).
class _DiagonalTargetWashPainter extends CustomPainter {
  _DiagonalTargetWashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseA = color.a;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          color,
          color.withValues(alpha: baseA * 0.46),
          color.withValues(alpha: baseA * 0.19),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.28, 0.52, 0.78],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(kRadiusMax)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalTargetWashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Corner chevron for unselected instance plugs (accent — never enhanced gold).
class _CornerChevronPainter extends CustomPainter {
  _CornerChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerChevronPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedBorderDecoration extends Decoration {
  const _DashedBorderDecoration({
    required this.color,
    this.strokeWidth = 1,
    this.radius = 2,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DashedBorderPainter(
      color: color,
      strokeWidth: strokeWidth,
      radius: radius,
    );
  }
}

class _DashedBorderPainter extends BoxPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  static const double _dash = 3;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }
}

/// Letter mark when no Bungie icon — no nested border (cell already has chrome).
class _PerkIconFallback extends StatelessWidget {
  const _PerkIconFallback({
    super.key,
    required this.label,
    required this.color,
    this.size = kCatalogPerkIconSize,
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
      child: Center(
        child: Text(
          mark,
          style: neonMono(color: color, fontSize: size * 0.42),
        ),
      ),
    );
  }
}
