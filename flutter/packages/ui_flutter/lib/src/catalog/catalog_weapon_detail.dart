import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_detail.dart';
import 'catalog_perk_grid.dart';
import 'catalog_roll_targets.dart';
import 'catalog_weapon_meta_strip.dart';

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

/// Possible-rolls and possible-crafted toggles (both OFF by default at host).
///
/// Mock residual chrome: pill + knob view-toggle (not Material FilterChip).
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
    return Wrap(
      key: const Key('catalog_detail_toggles'),
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CatalogViewToggle(
          key: const Key('catalog_toggle_can_roll'),
          label: 'Possible rolls',
          pressed: showCanRoll,
          onChanged: onCanRollChanged,
        ),
        if (craftAvailable)
          _CatalogViewToggle(
            key: const Key('catalog_toggle_craft'),
            label: 'Possible crafted',
            pressed: showCraft,
            onChanged: onCraftChanged,
          ),
      ],
    );
  }
}

/// Mock residual view-toggle: pill border + track knob + [Semantics] toggled.
///
/// Matches `view-toggle` / `aria-pressed` in residual polish mockups.
class _CatalogViewToggle extends StatelessWidget {
  const _CatalogViewToggle({
    super.key,
    required this.label,
    required this.pressed,
    required this.onChanged,
  });

  final String label;
  final bool pressed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = pressed
        ? palette.accent.withValues(alpha: 0.45)
        : palette.line;
    final fg = pressed ? palette.foreground : palette.muted;
    final bg = pressed
        ? palette.accent.withValues(alpha: 0.12)
        : palette.background;

    // excludeSemantics: Text + knob would publish nested nodes; Windows AX
    // reparent failures when toggled rebuilds the subtree.
    return Semantics(
      button: true,
      toggled: pressed,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!pressed),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: kFlapRuleThickness),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: neonMono(
                    color: fg,
                    fontSize: 8,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                _ToggleKnob(pressed: pressed, palette: palette),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleKnob extends StatelessWidget {
  const _ToggleKnob({required this.pressed, required this.palette});

  final bool pressed;
  final FlapPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 26,
      height: 12,
      decoration: BoxDecoration(
        color: pressed
            ? palette.accent.withValues(alpha: 0.2)
            : palette.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pressed
              ? palette.accent.withValues(alpha: 0.45)
              : palette.line,
          width: kFlapRuleThickness,
        ),
      ),
      child: Align(
        alignment: pressed ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? palette.accent : palette.muted,
            ),
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
    // One AX node for deferred stubs — Material disabled buttons nest label
    // nodes that thrash when the detail panel mounts (Windows AX).
    return Semantics(
      label: 'Outbound create deferred',
      excludeSemantics: true,
      child: Wrap(
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
      ),
    );
  }
}

/// Multi-instance power-desc strip; default selection is highest power.
///
/// Dual-truth (002-weapon-instance-strip): Flap pressable chips — not
/// Material [ChoiceChip]. Label `{power} T{tier} {special?}`; multi-row wrap;
/// no MW/Craft marks.
///
/// 003 roll targets: optional dual trailing score segs (`N/M` + `Av k`) and
/// [preserveCallerOrder] when host already ranked via rankOwnedForRollTarget.
class WeaponInstanceStrip extends StatelessWidget {
  const WeaponInstanceStrip({
    super.key,
    required this.instances,
    required this.selectedInstanceId,
    required this.onSelect,
    this.scoresByInstanceId = const {},
    this.preserveCallerOrder = false,
    this.rankedByRollTarget = false,
    this.activeTargetName,
  });

  final List<CatalogInstanceProjection> instances;
  final String? selectedInstanceId;
  final ValueChanged<CatalogInstanceProjection> onSelect;

  /// Host-mapped dual scores; segs hidden when missing or !hasAnyScoreDimension.
  final Map<String, CatalogInstanceRollScore> scoresByInstanceId;

  /// When true, do not re-sort by power (host ranked list).
  final bool preserveCallerOrder;

  /// Shows micro-note under INSTANCES when ranking is active.
  final bool rankedByRollTarget;

  /// Named active target for chip Semantics (optional).
  final String? activeTargetName;

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

    final List<CatalogInstanceProjection> ordered;
    if (preserveCallerOrder) {
      ordered = List<CatalogInstanceProjection>.from(instances);
    } else {
      ordered = List<CatalogInstanceProjection>.from(instances)
        ..sort((a, b) => b.power.compareTo(a.power));
    }

    // No parent Semantics(container) — chips own button a11y. A labeled
    // container + dynamic chip list reparents when rank/score updates and
    // thrashs Windows accessibility_bridge (AXTree "not in the tree" errors).
    return Column(
      key: const Key('weapon_instance_strip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: rankedByRollTarget
              ? 'Owned instances, ranked by roll target'
              : 'Owned instances',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'INSTANCES',
                style: neonMono(
                  color: palette.muted.withValues(alpha: 0.7),
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
              if (rankedByRollTarget) ...[
                const SizedBox(height: 2),
                Text(
                  key: const Key('weapon_instance_rank_note'),
                  'Ranked by roll target',
                  style: neonMono(
                    color: palette.muted.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Wrap chips only — each chip is content-sized (not full rail width).
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final inst in ordered)
              _InstanceChip(
                key: Key('instance_chip_${inst.instanceId}'),
                instance: inst,
                selected: selectedInstanceId == inst.instanceId,
                score: scoresByInstanceId[inst.instanceId],
                activeTargetName: activeTargetName,
                onTap: () => onSelect(inst),
              ),
          ],
        ),
      ],
    );
  }
}

/// Canonical chip text: `{power} T{tier} {special?}` e.g. `335 T3 Adept`.
String catalogInstanceChipLabel(CatalogInstanceProjection inst) {
  final parts = <String>['${inst.power}'];
  final tier = inst.gearTier;
  if (tier != null && tier >= 1 && tier <= 5) {
    parts.add('T$tier');
  }
  final special = inst.specialLabel?.trim();
  if (special != null && special.isNotEmpty) {
    parts.add(special);
  }
  return parts.join(' ');
}

/// Flap instance chip — segmented power | tier plate | special color.
/// Dual score segs are additive trailing only (never replace base).
class _InstanceChip extends StatelessWidget {
  const _InstanceChip({
    super.key,
    required this.instance,
    required this.selected,
    required this.onTap,
    this.score,
    this.activeTargetName,
  });

  final CatalogInstanceProjection instance;
  final bool selected;
  final VoidCallback onTap;
  final CatalogInstanceRollScore? score;
  final String? activeTargetName;

  static const Color _adeptGold = Color(0xFFF0D78C);
  static const Color _holofoilViolet = Color(0xFFE0B8F0);

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected
        ? palette.accent.withValues(alpha: 0.5)
        : palette.lineStrong;
    final bg = selected
        ? palette.accent.withValues(alpha: 0.14)
        : palette.surfaceRaised;
    final tip = catalogInstanceChipLabel(instance);
    final tier = instance.gearTier;
    final special = instance.specialLabel?.trim();
    final hasTier = tier != null && tier >= 1 && tier <= 5;
    final hasSpecial = special != null && special.isNotEmpty;
    final showScore = score != null && score!.hasAnyScoreDimension;

    final children = <Widget>[
      Text(
        '${instance.power}',
        style: neonMono(
          color: palette.foreground,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    ];
    if (hasTier) {
      children.add(_chipSep(selected, palette));
      children.add(
        Container(
          key: Key('instance_tier_${instance.instanceId}'),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: 0.16)
                : palette.muted.withValues(alpha: 0.12),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.4)
                  : palette.muted.withValues(alpha: 0.28),
              width: kFlapRuleThickness,
            ),
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(
            'T$tier',
            style: neonMono(
              color: palette.foreground,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
    }
    if (hasSpecial) {
      children.add(_chipSep(selected, palette));
      final kind = special.toLowerCase();
      final Color specialFg;
      final Color specialBg;
      final Color specialBorder;
      if (kind == 'adept') {
        specialFg = _adeptGold;
        specialBg = const Color(0xFFF5C542).withValues(alpha: 0.12);
        specialBorder = const Color(0xFFF5C542).withValues(alpha: 0.4);
      } else if (kind == 'holofoil') {
        specialFg = _holofoilViolet;
        specialBg = const Color(0xFFC49AD4).withValues(alpha: 0.14);
        specialBorder = const Color(0xFFC49AD4).withValues(alpha: 0.45);
      } else {
        specialFg = palette.muted;
        specialBg = palette.muted.withValues(alpha: 0.1);
        specialBorder = palette.muted.withValues(alpha: 0.28);
      }
      children.add(
        Container(
          key: Key('instance_special_${instance.instanceId}'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: specialBg,
            border: Border.all(color: specialBorder, width: kFlapRuleThickness),
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(
            special.toUpperCase(),
            style: neonMono(
              color: specialFg,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    // Additive dual score segments (003) — trailing only when scored.
    if (showScore) {
      final s = score!;
      if (s.preferredScored > 0) {
        children.add(_chipSep(selected, palette));
        final Color prefColor;
        if (s.isPerfectPreferred) {
          prefColor = palette.success;
        } else if (s.preferredMatched > 0) {
          prefColor = palette.foreground;
        } else {
          prefColor = palette.muted.withValues(alpha: 0.55);
        }
        children.add(
          Text(
            key: Key('instance_score_pref_${instance.instanceId}'),
            s.preferredSegLabel,
            style: neonMono(
              color: prefColor,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        );
      }
      if (s.avoidScored > 0) {
        children.add(_chipSep(selected, palette));
        final hit = s.avoidHits > 0;
        final Color avFg;
        final Color avBg;
        final Color avBorder;
        if (hit) {
          avFg = const Color(0xFFFFB3C0);
          avBg = palette.danger.withValues(alpha: 0.12);
          avBorder = palette.danger.withValues(alpha: 0.4);
        } else {
          avFg = palette.muted.withValues(alpha: 0.55);
          avBg = Colors.transparent;
          avBorder = palette.muted.withValues(alpha: 0.15);
        }
        children.add(
          Container(
            key: Key('instance_score_avoid_${instance.instanceId}'),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: avBg,
              border: Border.all(color: avBorder, width: kFlapRuleThickness),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              s.avoidSegLabel,
              style: neonMono(
                color: avFg,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      }
    }

    final semanticsParts = <String>[tip];
    final tName = activeTargetName?.trim();
    if (tName != null && tName.isNotEmpty && showScore) {
      semanticsParts.add(tName);
    }
    if (showScore) {
      semanticsParts.add(score!.semanticsScoreLabel);
    }
    final semanticsLabel = semanticsParts.join(', ');

    // IntrinsicWidth: Wrap gives max cross-axis extent; Container would expand.
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMax),
          child: IntrinsicWidth(
            child: Container(
              height: 30,
              padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: borderColor, width: kFlapRuleThickness),
                borderRadius: BorderRadius.circular(kRadiusMax),
              ),
              foregroundDecoration: selected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusMax),
                      border: Border(
                        left: BorderSide(color: palette.accent, width: 3),
                      ),
                    )
                  : null,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipSep(bool selected, FlapPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        width: 1,
        height: 14,
        color: selected
            ? palette.accent.withValues(alpha: 0.35)
            : palette.line.withValues(alpha: 0.9),
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
    this.familyMembers = const [],
    this.onSelectFamilyMember,
    // 003 CatalogRollTargets
    this.rollTargets = const [],
    this.activeRollTargetId,
    this.activeRollTargetName,
    this.onActiveRollTargetChanged,
    this.instanceRollScores = const {},
    this.preserveInstanceOrder = false,
    this.rankedByRollTarget = false,
    this.editingRollTarget = false,
    this.onEditRollTarget,
    this.onNewRollTarget,
    this.onDeleteRollTarget,
    this.canDeleteRollTarget = false,
    this.rollTargetDraftName = '',
    this.onRollTargetDraftNameChanged,
    this.rollTargetHasOverlap = false,
    this.onSaveRollTarget,
    this.onCancelRollTarget,
    this.canSaveRollTarget = false,
    this.preferredByColumn = const {},
    this.avoidByColumn = const {},
    this.onCycleRollPlug,
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

  /// All family versions for detail switch (GAP-CAT-BROWSE-001). Unowned listable.
  final List<WeaponFamilyMember> familyMembers;
  final ValueChanged<WeaponFamilyMember>? onSelectFamilyMember;

  // --- 003 CatalogRollTargets props (host-wired) ---

  final List<CatalogRollTargetOption> rollTargets;
  final String? activeRollTargetId;
  final String? activeRollTargetName;
  final ValueChanged<String?>? onActiveRollTargetChanged;

  /// Dual scores by instance id (host maps domain match → presentation).
  final Map<String, CatalogInstanceRollScore> instanceRollScores;

  /// When true, strip keeps host order (rankOwnedForRollTarget).
  final bool preserveInstanceOrder;
  final bool rankedByRollTarget;

  final bool editingRollTarget;
  final VoidCallback? onEditRollTarget;
  final VoidCallback? onNewRollTarget;
  final VoidCallback? onDeleteRollTarget;
  final bool canDeleteRollTarget;
  final String rollTargetDraftName;
  final ValueChanged<String>? onRollTargetDraftNameChanged;
  final bool rollTargetHasOverlap;
  final VoidCallback? onSaveRollTarget;
  final VoidCallback? onCancelRollTarget;
  final bool canSaveRollTarget;

  /// Active (view) or draft (edit) preferred/avoid plug sets by columnKey.
  final Map<String, Set<int>> preferredByColumn;
  final Map<String, Set<int>> avoidByColumn;

  /// Editor: cycle Want|Avoid|Off on can-roll ③ cells only.
  final void Function(String columnKey, int plugHash)? onCycleRollPlug;

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
    // Exotics: no possible-roll pool (BUG-20260807-002). Instance or
    // definition plugs only — fixed columns, never invent can-roll expansion.
    final effectiveShowCanRoll = item.isExotic ? false : showCanRoll;
    final effectiveShowCraft = item.isExotic ? false : showCraft;
    // Instance sockets drive ①+②. Unowned legendary → definition ③ possible rolls.
    // Unowned exotic still uses definition plugs as fixed layout (not "possible").
    final columns = buildCatalogPerkColumns(
      socketPlugs: inst?.socketPlugs,
      definitionSocketPlugs:
          definitionSocketPlugs.isEmpty ? null : definitionSocketPlugs,
      plugCards: inst?.plugCards ?? const [],
      plugNameByHash: plugNameByHash,
      plugIconByHash: plugIconByHash,
      plugEnhancedByHash: plugEnhancedByHash,
      showCanRoll: effectiveShowCanRoll,
      showCraft: effectiveShowCraft,
      craftColumns: item.isExotic ? const [] : craftColumns,
      fixedPerks: item.isExotic,
    );
    final unknowns = unknownPerkHashes(columns);
    final perkSectionLabel = item.isExotic
        ? 'PERKS'
        : hasOwnedCopy
            ? 'PERKS'
            : 'POSSIBLE ROLLS';
    final showEnhanceNote =
        !item.isExotic && catalogColumnsCanBeEnhanced(columns);
    final enhanceContext = !hasOwnedCopy
        ? 'Definition pool'
        : effectiveShowCraft && effectiveShowCanRoll
            ? 'Possible rolls / crafted'
            : effectiveShowCraft
                ? 'Possible crafted'
                : 'Possible rolls';

    // Sticky title only. All chrome below scrolls — fixed header+roll-target+
    // instances+toggles used to exceed the 400px rail height and overflow
    // the Column, which thrashs layout + Windows accessibility_bridge.
    final material = Material(
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
          Divider(height: 1, color: palette.line),
          Expanded(
            child: ListView(
              key: const Key('instance_list'),
              padding: const EdgeInsets.fromLTRB(
                kSpace12,
                kSpace8,
                kSpace12,
                kSpace12,
              ),
              children: [
                CatalogWeaponMetaStrip(
                  itemTypeName: item.itemTypeName,
                  frame: item.frame,
                  element: item.element,
                  slot: item.slot,
                  ammo: item.ammo,
                  owned: item.owned,
                  ownedCount: item.ownedCount,
                  showOwnedMark: showOwnedMetaMark,
                ),
                const SizedBox(height: kSpace8),
                // Roll targets: legendary only (DBR-IDL-009 — exotic perks fixed).
                if (!item.isExotic && onActiveRollTargetChanged != null) ...[
                  CatalogRollTargets(
                    targets: rollTargets,
                    activeTargetId: activeRollTargetId,
                    activeTargetName: activeRollTargetName,
                    onActiveChanged: onActiveRollTargetChanged!,
                    editing: editingRollTarget,
                    onEdit: onEditRollTarget,
                    onNew: onNewRollTarget,
                    onDelete: onDeleteRollTarget,
                    canDelete: canDeleteRollTarget,
                    draftName: rollTargetDraftName,
                    onDraftNameChanged: onRollTargetDraftNameChanged,
                    hasOverlap: rollTargetHasOverlap,
                    onSave: onSaveRollTarget,
                    onCancel: onCancelRollTarget,
                    canSave: canSaveRollTarget,
                  ),
                  const SizedBox(height: kSpace8),
                ],
                // Owned: instances strip only (power · tier · special). No parallel
                // VERSIONS rail — specialness lives on instance chips; grid/family
                // openVersion already chose the definition. Unowned: version switch
                // when family has multiple members (no instance chips to select).
                if (hasOwnedCopy) ...[
                  WeaponInstanceStrip(
                    instances: instances,
                    selectedInstanceId: selectedInstanceId ??
                        defaultHighestPowerInstanceId(instances),
                    onSelect: onSelectInstance ?? (_) {},
                    scoresByInstanceId: instanceRollScores,
                    preserveCallerOrder: preserveInstanceOrder,
                    rankedByRollTarget: rankedByRollTarget,
                    activeTargetName: activeRollTargetName,
                  ),
                  const SizedBox(height: kSpace8),
                ] else ...[
                  if (familyMembers.length > 1 &&
                      onSelectFamilyMember != null) ...[
                    _FamilyVersionSwitch(
                      members: familyMembers,
                      selectedHash: item.hash,
                      onSelect: onSelectFamilyMember!,
                    ),
                    const SizedBox(height: kSpace8),
                  ],
                  Text(
                    key: const Key('instance_panel_empty'),
                    item.isExotic
                        ? 'No local copies — showing fixed exotic perks'
                        : 'No local copies — showing possible rolls from definition',
                    style: neonBody(color: palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: kSpace8),
                ],
                // Possible-rolls / craft toggles: owned legendaries only.
                // Exotics never get Possible rolls (BUG-20260807-002).
                // Hide toggles while editing roll target (editor forces pool).
                if (hasOwnedCopy &&
                    !item.isExotic &&
                    !editingRollTarget &&
                    onCanRollChanged != null &&
                    onCraftChanged != null) ...[
                  CatalogDetailToggles(
                    showCanRoll: effectiveShowCanRoll,
                    showCraft: effectiveShowCraft,
                    onCanRollChanged: onCanRollChanged!,
                    onCraftChanged: onCraftChanged!,
                    craftAvailable: craftAvailable,
                  ),
                  const SizedBox(height: kSpace8),
                ],
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
                    item.isExotic || hasOwnedCopy
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
                CatalogPerkGrid(
                  columns: columns,
                  preferredByColumn: preferredByColumn,
                  avoidByColumn: avoidByColumn,
                  editingRollTarget: editingRollTarget,
                  onCycleRollPlug: onCycleRollPlug,
                  fixedPerks: item.isExotic,
                ),
                CatalogHashFooter(unknownHashes: unknowns),
                const SizedBox(height: kSpace16),
                const CatalogOutboundStubs(),
              ],
            ),
          ),
        ],
      ),
    );

    // Windows accessibility_bridge: large detail subtrees reparent on weapon
    // switch / edit and spam "will not be in the tree". When no screen reader
    // is active, collapse the rail to one node; keep full tree for AT users.
    final accessible = MediaQuery.accessibleNavigationOf(context);
    if (accessible) return material;
    return Semantics(
      label: '${item.name} detail',
      excludeSemantics: true,
      child: material,
    );
  }
}

/// Family version switcher — full hash rebind on select (detail only).
class _FamilyVersionSwitch extends StatelessWidget {
  const _FamilyVersionSwitch({
    required this.members,
    required this.selectedHash,
    required this.onSelect,
  });

  final List<WeaponFamilyMember> members;
  final int selectedHash;
  final ValueChanged<WeaponFamilyMember> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('catalog_family_version_switch'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VERSIONS',
          style: neonMono(
            color: palette.muted,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final m in members)
              // Single semantic owner (Windows AX) — raw ChoiceChip nests
              // label/selection nodes that thrash on version rebind.
              Semantics(
                button: true,
                selected: m.hash == selectedHash,
                label: 'Version ${weaponVersionSwitchLabel(m, members)}',
                excludeSemantics: true,
                child: ChoiceChip(
                  key: Key('family_version_select_${m.hash}'),
                  label: Text(
                    // Disambiguate multi-hash same-kind (e.g. five Ribbontail Base defs).
                    weaponVersionSwitchLabel(m, members),
                    style: neonMono(fontSize: 10),
                  ),
                  selected: m.hash == selectedHash,
                  onSelected: (_) => onSelect(m),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
