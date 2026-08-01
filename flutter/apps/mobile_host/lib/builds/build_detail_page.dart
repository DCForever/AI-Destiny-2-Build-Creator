import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'attach_set_sheet.dart';
import 'builds_controller.dart';
import 'finish_gaps_format.dart';
import 'soft_guidance_format.dart';
import 'variant_compose_format.dart';

/// Linear finish compose detail (Focus Swap). Create → attach → soft guidance.
///
/// Soft guidance never auto-applies; hard DBR blocks stay hard.
class BuildDetailPage extends StatefulWidget {
  const BuildDetailPage({
    super.key,
    required this.controller,
    required this.buildId,
  });

  final BuildsController controller;
  final String buildId;

  @override
  State<BuildDetailPage> createState() => _BuildDetailPageState();
}

class _BuildDetailPageState extends State<BuildDetailPage> {
  final _variantNameCtrl = TextEditingController();
  final Map<ArmorStatName, TextEditingController> _softStatControllers = {
    for (final s in ArmorStatName.all) s: TextEditingController(),
  };
  String? _statusMessage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    final selected = widget.controller.selected;
    if (selected == null || selected.build.id != widget.buildId) {
      // ignore: discarded_futures
      widget.controller.openBuild(widget.buildId);
    } else {
      _syncSoftFields();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _variantNameCtrl.dispose();
    for (final c in _softStatControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    _syncSoftFields();
    setState(() {});
  }

  void _syncSoftFields() {
    final targets = widget.controller.softStatTargets;
    for (final stat in ArmorStatName.all) {
      final v = targets[stat];
      final text = v?.toString() ?? '';
      if (_softStatControllers[stat]!.text != text) {
        _softStatControllers[stat]!.text = text;
      }
    }
  }

  Future<void> _run(Future<String?> Function() op) async {
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    final err = await op();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusMessage = err;
    });
  }

  Future<void> _createVariant() async {
    final name = _variantNameCtrl.text;
    await _run(() => widget.controller.createVariant(name: name));
    if (widget.controller.error == null) {
      _variantNameCtrl.clear();
    }
  }

  Future<void> _openAttachSheet() async {
    final setId = await showAttachSetSheet(
      context,
      controller: widget.controller,
    );
    if (setId == null || !mounted) return;
    await _run(() => widget.controller.attachSet(setId));
  }

  Future<void> _pinOrClear(SlotPinView pin, {required bool clear}) async {
    await _run(
      () => widget.controller.pinSlot(
        setId: pin.setId,
        slot: pin.slot,
        instanceId: clear ? null : 'inst-mobile-1',
        setItemId: pin.setItemId,
      ),
    );
  }

  Future<void> _saveSoftTargets() async {
    final fields = <String, String>{
      for (final stat in ArmorStatName.all)
        stat.wireName: _softStatControllers[stat]!.text,
    };
    await _run(() => widget.controller.saveSoftStatTargetsFromFields(fields));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final detail = c.selected;
    final build = detail?.build;
    final title = build != null ? c.titleOf(build) : 'Build';
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('build_detail_page'),
      appBar: AppBar(
        title: Text(title, key: const Key('build_detail_title')),
      ),
      body: build == null
          ? const Center(
              child: CircularProgressIndicator(key: Key('build_detail_loading')),
            )
          : SingleChildScrollView(
              key: const Key('build_detail_body'),
              padding: const EdgeInsets.all(16),
              // Column (not lazy ListView) so linear sections are always in tree
              // for reduced-density compose + widget tests.
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Identity ---
                Text(
                  'Identity',
                  key: const Key('compose_section_identity'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _row('Name', c.titleOf(build), 'detail_name'),
                _inkRow(
                  'Class',
                  c.identitySummaryOf(build),
                  'detail_identity',
                  elementHint: c.synergySummaryOf(build),
                ),
                _inkRow(
                  'Synergies',
                  c.synergySummaryOf(build).isEmpty
                      ? '—'
                      : c.synergySummaryOf(build),
                  'detail_synergies',
                  elementHint: c.synergySummaryOf(build),
                ),
                _inkRow(
                  'Exotics',
                  c.exoticsSummaryOf(build),
                  'detail_exotics',
                  elementHint: c.synergySummaryOf(build),
                  asSeal: true,
                ),
                const SizedBox(height: 20),

                // --- Variants ---
                Text(
                  'Variants',
                  key: const Key('compose_section_variants'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (c.variants.isEmpty)
                  const Text('No variants', key: Key('variants_empty'))
                else
                  Wrap(
                    key: const Key('variant_chips'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in c.variants)
                        ChoiceChip(
                          key: Key('variant_chip_${v.id}'),
                          label: Text(
                            v.isDefault ? '${v.name} (default)' : v.name,
                          ),
                          selected: c.selectedVariant?.id == v.id,
                          onSelected: _busy
                              ? null
                              : (_) {
                                  // ignore: discarded_futures
                                  c.selectVariant(v.id);
                                },
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('variant_name_field'),
                        controller: _variantNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'New variant name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        enabled: !_busy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: const Key('variant_create_btn'),
                      onPressed: _busy ? null : _createVariant,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Attachments / pins ---
                Text(
                  'Attachments',
                  key: const Key('compose_section_attachments'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: const Key('attach_set_open'),
                  onPressed: _busy || c.selectedVariant == null
                      ? null
                      : _openAttachSheet,
                  child: const Text('Attach set…'),
                ),
                const SizedBox(height: 8),
                if (c.attachments.isEmpty)
                  const Text(
                    'No sets attached',
                    key: Key('attachments_empty'),
                  )
                else
                  Column(
                    key: const Key('builds_attachments_list'),
                    children: [
                      for (final a in c.attachments)
                        ListTile(
                          key: Key('attachment_row_${a.record.setId}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(a.summary),
                          trailing: IconButton(
                            key: Key('detach_${a.record.setId}'),
                            icon: const Icon(Icons.link_off),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => c.detachSet(a.record.setId),
                                    ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text('Slot pins', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                if (c.slotPins.isEmpty)
                  const Text(
                    'No pins yet',
                    key: Key('slot_pins_empty'),
                  )
                else
                  Column(
                    key: const Key('builds_slot_pins'),
                    children: [
                      for (final pin in c.slotPins)
                        ListTile(
                          key: Key('slot_pin_${pin.slot}_${pin.setId}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${pin.slot}: ${pin.itemName.isEmpty ? pin.itemHash : pin.itemName}',
                          ),
                          subtitle: Text(
                            pin.pinDetail,
                            key: Key('pin_label_${pin.slot}'),
                          ),
                          trailing: pin.canEditPin
                              ? TextButton(
                                  key: Key('pin_toggle_${pin.slot}'),
                                  onPressed: _busy
                                      ? null
                                      : () => _pinOrClear(
                                            pin,
                                            clear: pin.instanceId != null &&
                                                pin.instanceId!
                                                    .trim()
                                                    .isNotEmpty,
                                          ),
                                  child: Text(
                                    pin.pinLabel == 'wishlist'
                                        ? 'Pin'
                                        : 'Clear',
                                  ),
                                )
                              : null,
                        ),
                    ],
                  ),
                const SizedBox(height: 20),

                // --- Soft guidance ---
                Text(
                  'Soft guidance',
                  key: const Key('builds_soft_guidance'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  c.softGuidanceAdvisory,
                  key: const Key('builds_soft_guidance_advisory'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (c.synergyCoverageRows.isEmpty)
                  const Text(
                    'No synergy coverage rows',
                    key: Key('soft_coverage_empty'),
                  )
                else
                  Wrap(
                    key: const Key('builds_soft_coverage_chips'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final row in c.synergyCoverageRows)
                        Chip(
                          key: Key(
                            'soft_chip_${row.synergyId}_${row.tier.wireName}',
                          ),
                          label: Text(formatSynergyCoverageChipLabel(row)),
                          // One Lamp: success/warning/danger — never amber primary.
                          backgroundColor: flapToneWash(
                            context,
                            coverageTierToneKey(row.tier),
                          ),
                          side: BorderSide(
                            color: flapToneColor(
                              context,
                              coverageTierToneKey(row.tier),
                            ).withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                if (c.setBonusSoftRows.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final row in c.setBonusSoftRows)
                    Text(formatSetBonusSoftSummary(row)),
                ],
                if (c.elementSoftMismatches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final row in c.elementSoftMismatches)
                    Text(formatElementSoftMismatchSummary(row)),
                ],
                const SizedBox(height: 12),
                Text('Soft stat targets', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final stat in ArmorStatName.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      key: Key('soft_stat_${stat.wireName}'),
                      controller: _softStatControllers[stat],
                      decoration: InputDecoration(
                        labelText: stat.wireName,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_busy,
                    ),
                  ),
                OutlinedButton(
                  key: const Key('soft_stat_save'),
                  onPressed: _busy ? null : _saveSoftTargets,
                  child: const Text('Save soft targets'),
                ),
                if (c.softStatTargetsSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Saved: ${c.softStatTargetsSummary}',
                    key: const Key('soft_stat_saved_summary'),
                  ),
                ],
                if (c.softStatWarnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final w in c.softStatWarnings)
                    Text(formatSoftStatWarningSummary(w)),
                ],
                const SizedBox(height: 20),

                // --- Finish gaps (display; equip/DIM N/A on mobile) ---
                Text(
                  'Finish readiness',
                  key: const Key('compose_section_finish_gaps'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  kFinishGapsPolicyCaption,
                  key: const Key('finish_gaps_policy'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (c.finishGaps == null)
                  const Text(
                    'Select a variant to evaluate finish gaps.',
                    key: Key('finish_gaps_empty'),
                  )
                else ...[
                  Text(
                    formatFinishGapsCompleteSummary(c.finishGaps!),
                    key: const Key('finish_gaps_complete_summary'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.finishGaps!.complete
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    key: const Key('finish_gaps_list'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final gap in c.finishGaps!.gaps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            formatFinishGapRowSummary(gap),
                            key: Key(
                              'finish_gap_${gap.category.wireName}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    key: const Key('compose_status_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                if (c.error != null && _statusMessage == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    formatComposeError(c.error),
                    key: const Key('compose_controller_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Linear finish · soft never auto-applies · hard limits still block. '
                  'Equip/DIM on phone: N/A (Windows/Jaspr).',
                  key: const Key('detail_compose_note'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, String keyName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, key: Key(keyName)),
          ),
        ],
      ),
    );
  }

  Widget _inkRow(
    String label,
    String value,
    String keyName, {
    String? elementHint,
    bool asSeal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: FlapInkCell(
              text: value,
              elementHint: elementHint,
              asSeal: asSeal,
              textKey: Key(keyName),
            ),
          ),
        ],
      ),
    );
  }
}
