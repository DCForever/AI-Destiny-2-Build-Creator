import 'package:flutter/material.dart';

import '../builds/finish_gaps_format.dart';
import 'equip_controller.dart';
import 'equip_format.dart';

/// Character pick + equip CTA + gaps confirm + step report (DART-038 / DART-057).
class EquipPanel extends StatefulWidget {
  const EquipPanel({
    super.key,
    required this.controller,
    this.finishComplete = true,
  });

  final EquipController controller;

  /// Finish-gaps complete (DART-057). CTAs require finish-complete AND equip-ready.
  final bool finishComplete;

  @override
  State<EquipPanel> createState() => _EquipPanelState();
}

class _EquipPanelState extends State<EquipPanel> {
  EquipController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant EquipPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    final pending = _c.pendingGaps;
    if (pending != null) {
      // Open confirm dialog once per pending.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _c.pendingGaps != null) {
          _showGapsConfirm(pending);
        }
      });
    }
    setState(() {});
  }

  Future<void> _showGapsConfirm(PendingEquipAction pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('equip_gaps_confirm_dialog'),
        title: const Text('Empty combat slots'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(kEquipGapsConfirmCaption),
            const SizedBox(height: 8),
            Text(
              formatEmptyCombatGapsSummary(pending.emptyCombatSlots),
              key: const Key('equip_gaps_confirm_summary'),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('equip_gaps_confirm_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('equip_gaps_confirm_ok'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply anyway'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      await _c.confirmGapsAndEquip();
    } else {
      _c.cancelGapsConfirm();
    }
  }

  Future<void> _onApply() async {
    await _c.requestEquip();
  }

  @override
  Widget build(BuildContext context) {
    final matching = _c.matchingCharacters;
    final status = _c.lastStatus;

    return Column(
      key: const Key('equip_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Apply / equip',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          kEquipSoftAdvisoryCaption,
          key: const Key('equip_soft_advisory'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (!_c.isSignedIn)
          const Text(
            'Sign in from Settings to load characters and equip.',
            key: Key('equip_sign_in_hint'),
          )
        else ...[
          if (_c.loadingCharacters)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(key: Key('equip_characters_loading')),
            ),
          InputDecorator(
            key: const Key('equip_character_field'),
            decoration: const InputDecoration(
              labelText: 'Character',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('equip_character_dropdown'),
                isExpanded: true,
                value: matching.any((c) => c.characterId == _c.selectedCharacterId)
                    ? _c.selectedCharacterId
                    : null,
                hint: const Text('Select…'),
                items: [
                  for (final c in matching)
                    DropdownMenuItem(
                      key: Key('equip_character_option_${c.characterId}'),
                      value: c.characterId,
                      child: Text(formatCharacterOptionLabel(c)),
                    ),
                ],
                onChanged: _c.equipping
                    ? null
                    : (id) => _c.selectCharacter(id),
              ),
            ),
          ),
          if (matching.isEmpty && _c.characters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formatNoMatchingClassMessage(_c.buildClass),
              key: const Key('equip_no_matching_class'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        const SizedBox(height: 12),
        Text(
          'Equip-ready',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          _c.readinessSummary,
          key: const Key('equip_ready_summary'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _c.equipReady
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
        ),
        if (_c.pinStatuses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            key: const Key('equip_pin_gaps'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _c.pinStatuses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    formatPinStatusLabel(_c.pinStatuses[i]),
                    key: Key(
                      'equip_pin_status_${_c.pinStatuses[i].slot.wireName}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ],
        if (_c.emptyCombatSlots.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            formatEmptyCombatGapsSummary(_c.emptyCombatSlots),
            key: const Key('equip_empty_combat_gaps'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!widget.finishComplete) ...[
          const SizedBox(height: 8),
          Text(
            kFinishIncompleteCtaCaption,
            key: const Key('equip_finish_incomplete_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('equip_apply_button'),
          onPressed: canEnableEquipCta(
                    signedIn: _c.isSignedIn,
                    equipReady: _c.equipReady,
                    characterId: _c.selectedCharacterId,
                    equipping: _c.equipping,
                    loading: _c.loadingCharacters || _c.loadingReadiness,
                    finishComplete: widget.finishComplete,
                  )
              ? _onApply
              : null,
          child: Text(_c.equipping ? 'Applying…' : 'Apply to character'),
        ),
        if (_c.error != null) ...[
          const SizedBox(height: 8),
          Text(
            _c.error!,
            key: const Key('equip_error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_c.statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _c.statusMessage!,
            key: const Key('equip_status_message'),
          ),
        ],
        if (status != null) ...[
          const SizedBox(height: 12),
          Text(
            'Step report',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            formatEquipStatusSummary(status),
            key: const Key('equip_step_report_summary'),
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('equip_step_report_list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < status.steps.length; i++)
                Text(
                  formatEquipStepReportLine(status.steps[i]),
                  key: Key('equip_step_report_line_$i'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
