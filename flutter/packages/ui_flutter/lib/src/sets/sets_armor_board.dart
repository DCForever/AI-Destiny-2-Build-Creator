import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../catalog/entity_info_hotspot.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_coverage_band.dart';
import 'sets_models.dart';
import 'sets_neon_chrome.dart';
import 'sets_save_gate_banner.dart';

/// Board layout A: totals row above five piece slots; base-roll only.
class SetsArmorBoard extends StatelessWidget {
  const SetsArmorBoard({
    super.key,
    required this.slots,
    this.totals,
    this.coverage,
    this.saveGateMessage,
    this.canSave = true,
    this.onOptimize,
    this.onPickSlot,
    this.onClearSlot,
    this.tagsSlot,
    this.showEnergyMods = true,
  });

  final List<SetsArmorSlotData> slots;
  final SetsArmorBoardTotals? totals;
  final SetsCoverageBandData? coverage;
  final String? saveGateMessage;
  final bool canSave;
  final VoidCallback? onOptimize;
  final ValueChanged<String>? onPickSlot;
  final ValueChanged<String>? onClearSlot;
  final Widget? tagsSlot;

  /// When false, never show energy/mods chrome (unknown).
  final bool showEnergyMods;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final resolvedTotals =
        totals ?? SetsArmorBoardTotals.fromSlots(slots);
    const statLabels = kArmorBoardEofStatLabels;

    return Column(
      key: const Key('sets_armor_board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // board-header-actions — hero Optimize (mockup .btn-primary.btn-lg.hero)
        // Omitted when [onOptimize] is null (detail preview / structure-only).
        if (onOptimize != null) ...[
          Row(
            children: [
              FilledButton.icon(
                key: const Key('sets_optimize_primary'),
                style: setsNeonHeroStyle(palette),
                onPressed: onOptimize,
                icon: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: palette.accent,
                ),
                label: Text(
                  'Optimize…'.toUpperCase(),
                  style: setsNeonBtnLabel(palette.accent, fontSize: 10),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (coverage != null) ...[
          SetsCoverageBand(data: coverage!),
          const SizedBox(height: kSpace12),
        ],
        // Totals above pieces — table chrome
        Container(
          key: const Key('sets_board_totals_row'),
          decoration: BoxDecoration(
            color: palette.background,
            border: Border.all(color: palette.line, width: kFlapRuleThickness),
            borderRadius: BorderRadius.circular(kFlapRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                color: palette.surfaceRaised,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Totals (base roll)'.toUpperCase(),
                        style: neonDisplay(
                          color: palette.muted.withValues(alpha: 0.85),
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      'Σ ${resolvedTotals.sigma}',
                      key: const Key('sets_board_sigma'),
                      style: neonMono(
                        color: palette.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final label in statLabels)
                      Text(
                        '$label ${resolvedTotals.stats[label] ?? 0}',
                        key: Key('sets_board_total_$label'),
                        style: neonMono(color: palette.muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpace8),
        // Five slots — table rows
        Container(
          decoration: BoxDecoration(
            color: palette.background,
            border: Border.all(color: palette.line, width: kFlapRuleThickness),
            borderRadius: BorderRadius.circular(kFlapRadius),
          ),
          child: Column(
            children: [
              for (var i = 0; i < slots.length; i++)
                _SlotRow(
                  slot: slots[i],
                  statLabels: statLabels,
                  showEnergyMods: showEnergyMods,
                  isLast: i == slots.length - 1,
                  onPick: onPickSlot == null
                      ? null
                      : () => onPickSlot!(slots[i].slotWire),
                  onClear: onClearSlot == null || !slots[i].isFilled
                      ? null
                      : () => onClearSlot!(slots[i].slotWire),
                ),
            ],
          ),
        ),
        if (tagsSlot != null) ...[
          const SizedBox(height: kSpace12),
          tagsSlot!,
        ],
        if (saveGateMessage != null || !canSave) ...[
          const SizedBox(height: kSpace12),
          SetsSaveGateBanner(
            message: saveGateMessage ?? 'Save disabled',
            canSave: canSave,
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.statLabels,
    required this.showEnergyMods,
    required this.isLast,
    this.onPick,
    this.onClear,
  });

  final SetsArmorSlotData slot;
  final List<String> statLabels;
  final bool showEnergyMods;
  final bool isLast;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      key: Key('sets_board_slot_${slot.slotWire}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: palette.line.withValues(alpha: 0.55),
                  width: kFlapRuleThickness,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  slot.slotLabel.toUpperCase(),
                  style: neonDisplay(
                    color: palette.muted,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (slot.isFilled) ...[
                _slotIcon(slot, palette),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _slotName(slot, palette),
              ),
              if (slot.instanceId != null && slot.instanceId!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    slot.instanceId!,
                    key: Key('sets_board_slot_instance_${slot.slotWire}'),
                    style: neonMono(color: palette.muted, fontSize: 10),
                  ),
                ),
              if (onPick != null)
                OutlinedButton(
                  key: Key('sets_board_pick_${slot.slotWire}'),
                  style: setsNeonGhostStyle(
                    palette,
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    fontSize: 8,
                  ),
                  onPressed: onPick,
                  child: Text(
                    (slot.isFilled ? 'Replace' : 'Pick').toUpperCase(),
                    style: setsNeonBtnLabel(palette.muted, fontSize: 8),
                  ),
                ),
              if (onClear != null)
                IconButton(
                  key: Key('sets_board_clear_${slot.slotWire}'),
                  onPressed: onClear,
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  color: palette.muted,
                  icon: const Icon(Icons.clear, size: 16),
                ),
            ],
          ),
          if (slot.isFilled) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final label in statLabels)
                  Text(
                    '$label ${slot.stats[label] ?? 0}',
                    key: Key('sets_board_slot_stat_${slot.slotWire}_$label'),
                    style: neonMono(color: palette.muted, fontSize: 11),
                  ),
              ],
            ),
            if (showEnergyMods &&
                slot.energyLabel != null &&
                slot.energyLabel!.isNotEmpty)
              Text(
                'Energy ${slot.energyLabel}',
                key: Key('sets_board_energy_${slot.slotWire}'),
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
            if (showEnergyMods &&
                slot.modsLabel != null &&
                slot.modsLabel!.isNotEmpty)
              Text(
                'Mods ${slot.modsLabel}',
                key: Key('sets_board_mods_${slot.slotWire}'),
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }

  Widget _slotIcon(SetsArmorSlotData slot, FlapPalette palette) {
    final icon = Container(
      key: Key('sets_board_slot_icon_${slot.slotWire}'),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(
          color: slot.isExotic
              ? const Color(0xFFE5C35A).withValues(alpha: 0.7)
              : palette.line,
          width: kFlapRuleThickness,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: slot.iconPath != null && slot.iconPath!.trim().isNotEmpty
          ? BungieContentIcon(
              pathOrUrl: slot.iconPath,
              size: 32,
              fallback: Icon(
                Icons.shield_outlined,
                size: 18,
                color: palette.muted,
              ),
            )
          : Icon(Icons.shield_outlined, size: 18, color: palette.muted),
    );
    final info = slot.entityInfo;
    if (info == null) return icon;
    return EntityInfoHotspot(
      key: Key('sets_board_slot_info_${slot.slotWire}'),
      data: info,
      child: icon,
    );
  }

  Widget _slotName(SetsArmorSlotData slot, FlapPalette palette) {
    final label = Text(
      slot.isFilled
          ? '${slot.isExotic ? '★ ' : ''}${slot.itemName}'
          : 'Empty',
      key: Key('sets_board_slot_name_${slot.slotWire}'),
      style: neonBody(
        color: slot.isFilled
            ? (slot.isExotic
                ? const Color(0xFFE5C35A)
                : palette.foreground)
            : palette.muted,
        fontSize: 13,
      ),
    );
    final info = slot.entityInfo;
    if (!slot.isFilled || info == null) return label;
    return EntityInfoHotspot(
      key: Key('sets_board_slot_name_info_${slot.slotWire}'),
      data: info,
      child: label,
    );
  }
}
