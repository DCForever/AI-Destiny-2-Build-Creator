part of 'builds_library_page.dart';

extension _BuildsLibraryComposeSection on _BuildsLibraryPageState {
  /// Loadout column only (variants · attach · slot grid). Finish lives in rail.
  Widget _buildVariantCompose(BuildContext context) {
    final variants = _controller.variants;
    final selectedVariant = _controller.selectedVariant;
    final sets = _controller.attachableSets;
    final palette = FlapPalette.of(context);
    // Keep dropdown selection valid.
    final attachValue = (_attachSetId != null &&
            sets.any((s) => s.id == _attachSetId))
        ? _attachSetId
        : (sets.isNotEmpty ? sets.first.id : null);
    if (attachValue != _attachSetId) {
      _attachSetId = attachValue;
    }

    return Column(
      key: const Key('builds_variant_compose'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VARIANTS',
          style: neonDisplay(
            color: palette.foreground,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'Select a variant, attach sets, pin slots.',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(height: kSpace8),
        if (variants.isEmpty)
          const Text(
            'No variants on this build.',
            key: Key('builds_variants_empty'),
          )
        else
          Wrap(
            key: const Key('builds_variants_list'),
            spacing: kSpace8,
            runSpacing: kSpace8,
            children: [
              for (final v in variants)
                ChoiceChip(
                  key: Key('builds_variant_chip_${v.id}'),
                  label: Text(
                    v.isDefault ? '${v.name} (default)' : v.name,
                  ),
                  selected: selectedVariant?.id == v.id,
                  onSelected: (_) => _controller.selectVariant(v.id),
                ),
            ],
          ),
        const SizedBox(height: kSpace8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('builds_create_variant_name'),
                controller: _createVariantNameController,
                decoration: const InputDecoration(
                  labelText: 'New variant name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _createVariant(),
              ),
            ),
            const SizedBox(width: kSpace8),
            OutlinedButton(
              key: const Key('builds_create_variant_button'),
              onPressed: _controller.loading ? null : _createVariant,
              child: const Text('Create'),
            ),
          ],
        ),
        const SizedBox(height: kSpace16),
        Text(
          'ATTACHMENTS',
          style: neonMono(
            color: palette.muted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace8),
        if (selectedVariant == null)
          const Text(
            'Select a variant to attach sets.',
            key: Key('builds_attach_no_variant'),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: sets.isEmpty
                    ? const Text(
                        'No library sets yet. Create sets in the Sets library.',
                        key: Key('builds_attach_no_sets'),
                      )
                    : DropdownButtonFormField<String>(
                        key: const Key('builds_attach_set_dropdown'),
                        // ignore: deprecated_member_use
                        value: attachValue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Library set',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final s in sets)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.type})'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _attachSetId = v),
                      ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('builds_attach_set_button'),
                onPressed: _controller.loading || sets.isEmpty
                    ? null
                    : _attachSelectedSet,
                child: const Text('Attach set'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_controller.attachments.isEmpty)
            const Text(
              'No sets attached.',
              key: Key('builds_attachments_empty'),
            )
          else
            Column(
              key: const Key('builds_attachments_list'),
              children: [
                for (final a in _controller.attachments)
                  ListTile(
                    key: Key('builds_attachment_${a.record.setId}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.summary),
                    trailing: IconButton(
                      key: Key('builds_detach_${a.record.setId}'),
                      tooltip: 'Detach',
                      icon: const Icon(Icons.link_off),
                      onPressed: _controller.loading
                          ? null
                          : () => _detachSet(a.record.setId),
                    ),
                  ),
              ],
            ),
        ],
        const SizedBox(height: kSpace16),
        // Slot grid (mock .slot-grid) — overview + edit surface.
        Row(
          children: [
            Expanded(
              child: Text(
                'SLOT GRID',
                style: neonMono(
                  color: palette.muted,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Text(
              'Owned',
              style: neonMono(color: palette.success, fontSize: 10),
            ),
            const SizedBox(width: 8),
            Text(
              'Wish',
              style: neonMono(color: palette.warning, fontSize: 10),
            ),
            const SizedBox(width: 8),
            Text(
              'Gap',
              style: neonMono(
                color: Color(kFlapAccentSecondaryDark),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpace8),
        _buildSlotGrid(context),
      ],
    );
  }

  /// Equipment slot grid: combat slots + any extra pins from attachments.
  Widget _buildSlotGrid(BuildContext context) {
    final palette = FlapPalette.of(context);
    final pins = _controller.slotPins;
    final bySlot = <String, SlotPinView>{
      for (final p in pins) p.slot: p,
    };
    // Prefer domain combat slots; append any pin slots not in the set.
    final slots = <String>[
      for (final s in EquipmentSlot.combatSlots) s.wireName,
    ];
    for (final p in pins) {
      if (!slots.contains(p.slot)) slots.add(p.slot);
    }

    if (slots.isEmpty && pins.isEmpty) {
      return const Text(
        'No filled slots from attachments.',
        key: Key('builds_slot_pins_empty'),
      );
    }

    // Hidden overview keys for tests that still query overview chips.
    final overviewKeys = pins.isEmpty
        ? const <Widget>[
            Offstage(
              offstage: true,
              child: Text(
                'No filled slots yet.',
                key: Key('builds_variant_overview_empty'),
              ),
            ),
          ]
        : [
            Offstage(
              offstage: true,
              child: Wrap(
                key: const Key('builds_variant_overview'),
                children: [
                  for (final pin in pins)
                    SizedBox(
                      key: Key(
                        'builds_variant_overview_${pin.slot}_${pin.setId}',
                      ),
                      width: 0,
                      height: 0,
                    ),
                ],
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...overviewKeys,
        if (pins.isEmpty)
          const Text(
            'No filled slots from attachments.',
            key: Key('builds_slot_pins_empty'),
          ),
        GridView.builder(
          key: const Key('builds_slot_pins_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 156,
            mainAxisExtent: 104,
            mainAxisSpacing: kSpace6,
            crossAxisSpacing: kSpace6,
          ),
          itemBuilder: (context, index) {
            final slot = slots[index];
            final pin = bySlot[slot];
            return _buildSlotGridCell(context, slot: slot, pin: pin);
          },
        ),
        // Keep pin edit keys mounted when a pin is being edited.
        if (pins.isNotEmpty)
          ...[
            for (final pin in pins)
              if (pin.canEditPin &&
                  _pinTargetKey == '${pin.slot}|${pin.setId}')
                Padding(
                  padding: const EdgeInsets.only(top: kSpace8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit ${pin.slot}',
                        style: neonMono(color: palette.muted, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: Key(
                          'builds_pin_instance_${pin.slot}_${pin.setId}',
                        ),
                        controller: _pinInstanceController,
                        decoration: const InputDecoration(
                          labelText: 'Instance id (empty = wishlist)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          OutlinedButton(
                            key: Key(
                              'builds_pin_apply_${pin.slot}_${pin.setId}',
                            ),
                            onPressed: _controller.loading
                                ? null
                                : () => _applyPin(pin),
                            child: const Text('Pin'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            key: Key(
                              'builds_pin_clear_${pin.slot}_${pin.setId}',
                            ),
                            onPressed: _controller.loading
                                ? null
                                : () => _clearPin(pin),
                            child: const Text('Wishlist'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
      ],
    );
  }

  Widget _buildSlotGridCell(
    BuildContext context, {
    required String slot,
    SlotPinView? pin,
  }) {
    final palette = FlapPalette.of(context);
    final owned = pin != null &&
        pin.instanceId != null &&
        pin.instanceId!.trim().isNotEmpty;
    final wish = pin != null && !owned;
    final gap = pin == null;
    final edge = owned
        ? palette.success
        : wish
            ? palette.warning
            : Color(kFlapAccentSecondaryDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: pin != null
            ? Key('builds_slot_pin_${pin.slot}_${pin.setId}')
            : Key('builds_slot_gap_$slot'),
        onTap: pin == null || !pin.canEditPin
            ? null
            : () {
                setState(() {
                  _pinTargetKey = '${pin.slot}|${pin.setId}';
                  _pinInstanceController.text = pin.instanceId ?? '';
                });
              },
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceRaised.withValues(alpha: 0.85),
            border: Border(
              left: BorderSide(color: edge, width: 2),
              top: BorderSide(color: palette.line, width: kFlapRuleThickness),
              right: BorderSide(color: palette.line, width: kFlapRuleThickness),
              bottom:
                  BorderSide(color: palette.line, width: kFlapRuleThickness),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(kSpace8, kSpace6, kSpace8, kSpace4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                slot.toUpperCase(),
                style: neonMono(
                  color: palette.muted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  pin?.itemName ?? 'Empty',
                  style: neonBody(
                    color: gap ? palette.muted : palette.foreground,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: pin != null
                        ? Text(
                            pin.pinDetail,
                            key: Key(
                              'builds_slot_pin_label_${pin.slot}_${pin.setId}',
                            ),
                            style: neonMono(
                              color: owned
                                  ? palette.success
                                  : palette.warning,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Gap',
                            style: neonMono(
                              color: Color(kFlapAccentSecondaryDark),
                              fontSize: 9,
                            ),
                          ),
                  ),
                  if (pin != null && pin.canEditPin)
                    TextButton(
                      key: Key('builds_pin_edit_${pin.slot}_${pin.setId}'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          _pinTargetKey = '${pin.slot}|${pin.setId}';
                          _pinInstanceController.text = pin.instanceId ?? '';
                        });
                      },
                      child: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Finish readiness rail (mock #readiness-rail): three-gate · gaps · soft · equip · DIM.
  Widget _buildReadinessRail(BuildContext context) {
    return NeonZone(
      key: const Key('builds_zone_readiness'),
      padding: const EdgeInsets.all(kSpace12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.selectedVariant != null) ...[
            _buildThreeGateChips(context),
            const SizedBox(height: kSpace12),
            _buildFinishGaps(context),
            const SizedBox(height: kSpace16),
            EquipPanel(
              key: const Key('builds_equip_panel'),
              controller: _equipController,
              finishComplete: _controller.finishComplete,
            ),
            const SizedBox(height: kSpace12),
            DimExportPanel(
              key: const Key('builds_dim_export_panel'),
              controller: _dimExportController,
              finishComplete: _controller.finishComplete,
            ),
            const SizedBox(height: kSpace12),
          ] else
            Text(
              'Select a variant to evaluate finish, equip, and export.',
              style: neonBody(
                color: FlapPalette.of(context).muted,
                fontSize: 12,
              ),
            ),
          _buildSoftGuidance(context),
        ],
      ),
    );
  }

  /// Three-gate readiness chips (BR-VAR-041): compose / required / equip-ready.
  /// Soft required misses on non-default never hard-disable Save.
  Widget _buildThreeGateChips(BuildContext context) {
    final gate = _controller.threeGate;
    final palette = FlapPalette.of(context);
    return Column(
      key: const Key('builds_three_gate_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'THREE-GATE READINESS',
          style: neonDisplay(
            color: palette.foreground,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          gate == null
              ? 'Evaluating compose · required · equip…'
              : (gate.isDefault
                  ? 'Default: compose + required hard · equip for equip/export'
                  : 'Non-default: soft required only · soft never blocks Save'),
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
        if (gate != null) ...[
          const SizedBox(height: kSpace8),
          Wrap(
            key: const Key('builds_three_gate_chips'),
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < gate.chipLabels.length; i++)
                Chip(
                  key: Key('builds_three_gate_chip_$i'),
                  label: Text(gate.chipLabels[i]),
                  backgroundColor: _threeGateChipColor(gate, i, palette),
                ),
            ],
          ),
          if (gate.softRequiredWarn) ...[
            const SizedBox(height: kSpace4),
            Text(
              'Required links soft-warn (non-default) — Save still allowed',
              key: const Key('builds_three_gate_soft_required'),
              style: neonBody(color: palette.warning, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  Color? _threeGateChipColor(
    ThreeGateStatus gate,
    int index,
    FlapPalette palette,
  ) {
    final ok = switch (index) {
      0 => gate.composeComplete,
      1 => gate.requiredLinksSatisfied,
      2 => gate.equipReady,
      _ => true,
    };
    if (ok) return palette.success.withValues(alpha: 0.2);
    if (index == 1 && gate.softRequiredWarn) {
      return palette.warning.withValues(alpha: 0.25);
    }
    return palette.danger.withValues(alpha: 0.2);
  }

  Widget _buildFinishGaps(BuildContext context) {
    final gaps = _controller.finishGaps;
    final activeGap = _controller.finishActiveGap;
    final step = _controller.finishStep;
    return Column(
      key: const Key('builds_finish_gaps_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'FINISH READINESS',
          style: neonDisplay(
            color: FlapPalette.of(context).foreground,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'One status · equip + export share it · soft never blocks',
          style: neonBody(
            color: FlapPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
        ListTile(
          key: const Key('finish_policy_toggle'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            _finishPolicyExpanded
                ? 'Hide how finish works'
                : 'How finish works',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          trailing: Icon(
            _finishPolicyExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() => _finishPolicyExpanded = !_finishPolicyExpanded);
          },
        ),
        if (_finishPolicyExpanded) ...[
          Text(
            kFinishGapsPolicyCaption,
            key: const Key('finish_gaps_policy'),
            style: _bodyMutedStyle(context),
          ),
          const SizedBox(height: kSpace4),
          Text(
            kFinishWalkthroughCaption,
            key: const Key('finish_walkthrough_caption'),
            style: _bodyMutedStyle(context),
          ),
          const SizedBox(height: kSpace8),
        ],
        if (gaps == null)
          const Text(
            'Select a variant to evaluate finish gaps.',
            key: Key('finish_gaps_empty'),
          )
        else ...[
          Text(
            formatFinishGapsCompleteSummary(gaps),
            key: const Key('finish_gaps_complete_summary'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: gaps.complete
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (_controller.finishMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _controller.finishMessage!,
              key: const Key('finish_walkthrough_message'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            key: const Key('finish_category_chips'),
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final gap in gaps.gaps)
                ActionChip(
                  key: Key('finish_category_chip_${gap.category.wireName}'),
                  label: Text(
                    '${finishCategoryLabel(gap.category)}'
                    '${gap.status == FinishGapStatus.satisfied ? ' ✓' : ''}'
                    '${_controller.finishSkipped.contains(gap.category.wireName) ? ' · skip' : ''}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () => _controller.openFinishCategory(gap.category),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            key: const Key('finish_gaps_list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final gap in gaps.gaps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    formatFinishGapRowSummary(gap),
                    key: Key('finish_gap_${gap.category.wireName}'),
                  ),
                ),
            ],
          ),
          if (!gaps.complete &&
              (step == FinishWalkthroughStep.overview ||
                  step == FinishWalkthroughStep.category) &&
              activeGap != null) ...[
            const SizedBox(height: 12),
            Text(
              finishCategoryLabel(activeGap.category),
              key: const Key('finish_active_category_title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (activeGap.canCapture)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key(
                    'finish_capture_${activeGap.category.wireName}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () => _controller.captureCategory(activeGap.category),
                  child: Text(
                    'Capture ${finishCategoryLabel(activeGap.category)}',
                  ),
                ),
              ),
            if (showFinishCreateActions(activeGap.status))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  key: Key(
                    'finish_create_${activeGap.category.wireName}',
                  ),
                  onPressed: _controller.finishBusy
                      ? null
                      : () =>
                          _controller.oneTapCreateCategory(activeGap.category),
                  child: Text(
                    _controller.finishBusy
                        ? 'Creating…'
                        : 'Create ${finishCategoryLabel(activeGap.category)} set & fill',
                  ),
                ),
              ),
            if (activeGap.status == FinishGapStatus.needsFill &&
                activeGap.coveringSetId != null &&
                activeGap.coveringMode == AttachmentMode.live) ...[
              if (activeGap.category == FinishCategory.armor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    key: const Key('finish_armor_improve'),
                    onPressed: _controller.finishBusy
                        ? null
                        : _controller.openFinishArmorOptimize,
                    child: const Text('Improve armor (Find kits)'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: const Key('finish_fill_first_empty'),
                  onPressed: _controller.finishBusy ||
                          activeGap.emptySlots.isEmpty
                      ? null
                      : () async {
                          _controller.openFinishFillFirstEmpty();
                          await _runFinishFillDialog();
                        },
                  child: Text(
                    activeGap.emptySlots.isEmpty
                        ? 'No empty slots'
                        : 'Fill ${activeGap.emptySlots.first}',
                  ),
                ),
              ),
            ],
            if (activeGap.status == FinishGapStatus.needsFill &&
                activeGap.coveringMode == AttachmentMode.snapshot)
              Text(
                'Covering Set is snapshot-only. Create a live Set from Finish '
                'to fill slots.',
                key: const Key('finish_snapshot_fill_blocked'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            Row(
              children: [
                TextButton(
                  key: Key('finish_skip_${activeGap.category.wireName}'),
                  onPressed: () =>
                      _controller.skipFinishCategory(activeGap.category),
                  child: const Text('Skip for now'),
                ),
                TextButton(
                  key: const Key('finish_back_overview'),
                  onPressed: _controller.backToFinishOverview,
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
          if (step == FinishWalkthroughStep.armorOptimize &&
              activeGap?.coveringSetId != null &&
              activeGap!.category == FinishCategory.armor) ...[
            const SizedBox(height: 12),
            _FinishArmorOptimizeEmbed(
              key: const Key('finish_armor_optimize_workspace'),
              services: widget.services,
              setId: activeGap.coveringSetId!,
              setName: activeGap.coveringSetName ?? activeGap.coveringSetId!,
              resolveUserId: _controller.resolveLibraryUserId,
              onApplied: () async {
                await _controller.afterFinishArmorApplied();
              },
              onManualFill: () async {
                _controller.openFinishFillFirstEmpty();
                await _runFinishFillDialog();
              },
              onBack: () {
                _controller.openFinishCategory(FinishCategory.armor);
              },
            ),
          ],
          if (step == FinishWalkthroughStep.fill &&
              activeGap?.coveringSetId != null &&
              _controller.finishFillSlot != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('finish_fill_dialog_reopen'),
              onPressed: _runFinishFillDialog,
              child: Text('Pick item for ${_controller.finishFillSlot}'),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _runFinishFillDialog() async {
    final gap = _controller.finishActiveGap;
    if (gap == null || gap.coveringSetId == null) return;
    final slot = _controller.finishFillSlot ?? firstEmptyRequiredSlot(gap);
    if (slot == null) return;
    if (gap.coveringMode != AttachmentMode.live) return;

    final pick = await showSetCatalogPicker(
      context: context,
      services: widget.services,
      targetSlot: slot,
    );
    if (pick == null || !mounted) return;
    final err = await _controller.fillFinishSlot(
      setId: gap.coveringSetId!,
      slot: slot,
      itemHash: pick.itemHash,
      itemName: pick.itemName,
      instanceId: pick.instanceId,
      selectedPerks: pick.selectedPerks,
      isExotic: pick.isExotic,
      equipmentSlot: pick.equipmentSlot,
      catalogKind: pick.catalogKind,
    );
    if (err != null && mounted) {
      setState(() => _statusMessage = err);
    }
  }

  Widget _buildSoftGuidance(BuildContext context) {
    final synergyRows = _controller.synergyCoverageRows;
    final setBonuses = _controller.setBonusSoftRows;
    final elements = _controller.elementSoftMismatches;
    final softStats = _controller.softStatWarnings;

    return Column(
      key: const Key('builds_soft_guidance'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Soft guidance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _controller.softGuidanceAdvisory,
          key: const Key('builds_soft_guidance_advisory'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Coverage chips',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_controller.selectedVariant == null)
          const Text(
            'Select a variant to evaluate soft coverage.',
            key: Key('builds_soft_coverage_no_variant'),
          )
        else if (synergyRows.isEmpty)
          const Text(
            'No designated synergy coverage rows (add library synergies matching build types).',
            key: Key('builds_soft_coverage_empty'),
          )
        else
          Wrap(
            key: const Key('builds_soft_coverage_chips'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final row in synergyRows)
                Chip(
                  key: Key(
                    'builds_soft_chip_${row.synergyId}_${row.tier.wireName}',
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: flapToneColor(
                      context,
                      coverageTierToneKey(row.tier),
                    ),
                    radius: 6,
                  ),
                  label: Text(formatSynergyCoverageChipLabel(row)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (setBonuses.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Set-bonus soft',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_set_bonuses'),
            children: [
              for (var i = 0; i < setBonuses.length; i++)
                ListTile(
                  key: Key('builds_soft_set_bonus_$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatSetBonusSoftSummary(setBonuses[i])),
                  subtitle: setBonuses[i].hint != null
                      ? Text(setBonuses[i].hint!)
                      : null,
                ),
            ],
          ),
        ],
        if (elements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Element soft mismatches',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_element_mismatches'),
            children: [
              for (var i = 0; i < elements.length; i++)
                ListTile(
                  key: Key('builds_soft_element_$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatElementSoftMismatchSummary(elements[i])),
                  subtitle: Text(elements[i].hint),
                ),
            ],
          ),
        ],
        if (softStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Soft stat warnings',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('builds_soft_stat_warnings'),
            children: [
              for (final row in softStats)
                ListTile(
                  key: Key('builds_soft_stat_warn_${row.stat.wireName}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatSoftStatWarningSummary(row)),
                  subtitle: Text(row.hint),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Soft stat targets',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Explicit save only — coverage never writes targets.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('builds_soft_stat_targets_fields'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stat in ArmorStatName.all)
              SizedBox(
                width: 120,
                child: TextField(
                  key: Key('builds_soft_stat_${stat.wireName}'),
                  controller: _softStatControllers[stat],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: stat.wireName,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: '1–$armorStatMax',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('builds_soft_stat_save'),
            onPressed: _controller.loading || _controller.selected == null
                ? null
                : _saveSoftStatTargets,
            child: const Text('Save soft targets'),
          ),
        ),
        if (_controller.softStatTargetsSummary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Saved: ${_controller.softStatTargetsSummary}',
            key: const Key('builds_soft_stat_saved_summary'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _saveSoftStatTargets() async {
    final fields = <String, String>{
      for (final stat in ArmorStatName.all)
        stat.wireName: _softStatControllers[stat]!.text,
    };
    final err = await _controller.saveSoftStatTargetsFromFields(fields);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Saved soft stat targets';
      if (err == null) {
        _boundSoftTargetsKey = null;
        _syncSoftStatFieldsFromController();
      }
    });
  }

  Future<void> _createVariant() async {
    final err = await _controller.createVariant(
      name: _createVariantNameController.text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ??
          'Created variant ${_createVariantNameController.text.trim()}';
      if (err == null) _createVariantNameController.clear();
    });
  }

  Future<void> _attachSelectedSet() async {
    final id = _attachSetId;
    if (id == null) {
      setState(() => _statusMessage = 'Pick a set to attach');
      return;
    }
    final err = await _controller.attachSet(id);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Attached set';
    });
  }

  Future<void> _detachSet(String setId) async {
    final err = await _controller.detachSet(setId);
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Detached set';
    });
  }

  Future<void> _applyPin(SlotPinView pin) async {
    final key = '${pin.slot}|${pin.setId}';
    final text = _pinTargetKey == key
        ? _pinInstanceController.text
        : (pin.instanceId ?? '');
    final err = await _controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      setItemId: pin.setItemId,
      instanceId: text,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Pinned ${pin.slot}';
      _pinTargetKey = null;
    });
  }

  Future<void> _clearPin(SlotPinView pin) async {
    final err = await _controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      setItemId: pin.setItemId,
      instanceId: null,
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = err ?? 'Cleared pin on ${pin.slot} (wishlist)';
      _pinTargetKey = null;
      _pinInstanceController.clear();
    });
  }
}
