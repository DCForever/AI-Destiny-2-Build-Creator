import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_coverage_band.dart';
import 'sets_models.dart';
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
    final statLabels = kArmorBoardEofStatLabels;

    return Column(
      key: const Key('sets_armor_board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary fill CTA
        FilledButton.icon(
          key: const Key('sets_optimize_primary'),
          onPressed: onOptimize,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Optimize…'),
        ),
        const SizedBox(height: kSpace12),
        if (coverage != null) ...[
          SetsCoverageBand(data: coverage!),
          const SizedBox(height: kSpace12),
        ],
        // Totals above pieces
        Container(
          key: const Key('sets_board_totals_row'),
          padding: const EdgeInsets.all(kSpace8),
          decoration: BoxDecoration(
            border: Border.all(color: palette.line, width: kFlapRuleThickness),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Totals (base roll)',
                style: neonBody(color: palette.muted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    'Σ ${resolvedTotals.sigma}',
                    key: const Key('sets_board_sigma'),
                    style: neonMono(
                      color: palette.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final label in statLabels)
                    Text(
                      '$label ${resolvedTotals.stats[label] ?? 0}',
                      key: Key('sets_board_total_$label'),
                      style: neonMono(color: palette.muted, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpace8),
        // Five slots
        for (final slot in slots) ...[
          _SlotRow(
            slot: slot,
            statLabels: statLabels,
            showEnergyMods: showEnergyMods,
            onPick: onPickSlot == null ? null : () => onPickSlot!(slot.slotWire),
            onClear: onClearSlot == null || !slot.isFilled
                ? null
                : () => onClearSlot!(slot.slotWire),
          ),
          const SizedBox(height: kSpace4),
        ],
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
    this.onPick,
    this.onClear,
  });

  final SetsArmorSlotData slot;
  final List<String> statLabels;
  final bool showEnergyMods;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      key: Key('sets_board_slot_${slot.slotWire}'),
      padding: const EdgeInsets.all(kSpace8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  slot.slotLabel,
                  style: neonBody(
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  slot.isFilled
                      ? '${slot.isExotic ? '★ ' : ''}${slot.itemName}'
                      : 'Empty',
                  key: Key('sets_board_slot_name_${slot.slotWire}'),
                  style: neonBody(
                    color: slot.isFilled
                        ? palette.foreground
                        : palette.muted,
                    fontSize: 13,
                  ),
                ),
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
              OutlinedButton(
                key: Key('sets_board_pick_${slot.slotWire}'),
                onPressed: onPick,
                child: Text(slot.isFilled ? 'Replace' : 'Pick'),
              ),
              if (onClear != null)
                IconButton(
                  key: Key('sets_board_clear_${slot.slotWire}'),
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
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
}
